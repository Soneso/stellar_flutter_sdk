import "dart:async";
import "dart:convert";

import 'package:http/http.dart' as http;
import "package:http_parser/http_parser.dart" show MediaType;

import "decoder.dart";
import "event.dart";

export "event.dart";

/// Represents the connection state of an EventSource.
///
/// The EventSource can be in one of three states:
/// - [CONNECTING]: Attempting to establish or re-establish connection
/// - [OPEN]: Connection is active and receiving events
/// - [CLOSED]: Connection is permanently closed
enum EventSourceReadyState {
  /// Connection is being established or re-established.
  CONNECTING,

  /// Connection is open and receiving events.
  OPEN,

  /// Connection is closed and will not reconnect.
  CLOSED,
}

/// Exception thrown when EventSource subscription fails.
///
/// Contains the HTTP status code and error message from the server.
/// This exception is emitted as an error event when the initial
/// connection to the server fails.
class EventSourceSubscriptionException extends Event implements Exception {
  /// HTTP status code from the failed request.
  int statusCode;

  /// Error message describing the failure.
  String message;

  /// Returns the error data as a formatted string.
  @override
  String get data => "$statusCode: $message";

  /// Creates a new subscription exception.
  ///
  /// Parameters:
  /// - [statusCode]: HTTP status code from the server
  /// - [message]: Error message or response body
  EventSourceSubscriptionException(this.statusCode, this.message)
      : super(event: "error");
}

/// Client for consuming Server-Sent Events (SSE) streams.
///
/// EventSource provides a stream-based interface for receiving real-time
/// updates from a server using the SSE protocol. It handles connection
/// management, automatic reconnection with exponential backoff, and
/// event parsing.
///
/// Key features:
/// - Automatic reconnection on connection loss
/// - Configurable retry delays via server retry events
/// - Event ID tracking for resuming from last received event
/// - Support for custom headers and request methods
/// - Filtered event streams (onOpen, onMessage, onError)
///
/// Usage with Stellar Horizon:
/// ```dart
/// // Stream payment events for an account
/// var es = await EventSource.connect(
///   "https://horizon.stellar.org/accounts/GXXX.../payments",
///   headers: {"Accept": "text/event-stream"}
/// );
///
/// es.listen((Event event) {
///   if (event.event == "message") {
///     var payment = jsonDecode(event.data!);
///     print("Payment received: ${payment['amount']}");
///   }
/// });
///
/// // Close when done
/// es.close();
/// ```
///
/// Connection lifecycle:
/// 1. Call [connect] to establish the connection
/// 2. Listen to the stream to receive events
/// 3. Connection automatically reconnects on errors
/// 4. Call [close] to permanently close the connection
///
/// See also:
/// - [Event] for event structure
/// - [EventSourceDecoder] for SSE parsing
/// - [Stellar developer docs](https://developers.stellar.org)
class EventSource extends Stream<Event> {
  // interface attributes

  /// The URL of the SSE endpoint.
  final Uri url;

  /// Custom HTTP headers to send with the request.
  final Map<String, String>? headers;

  /// Current connection state.
  ///
  /// Can be CONNECTING, OPEN, or CLOSED.
  EventSourceReadyState get readyState => _readyState;

  /// Stream of connection open events.
  ///
  /// Emits an event when the connection is successfully established.
  Stream<Event> get onOpen => this.where((e) => e.event == "open");

  /// Stream of message events containing data updates.
  ///
  /// This is the primary stream for receiving data from the server.
  Stream<Event> get onMessage => this.where((e) => e.event == "message");

  /// Stream of error events.
  ///
  /// Emits events when connection errors or subscription failures occur.
  Stream<Event> get onError => this.where((e) => e.event == "error");

  // internal attributes

  StreamController<Event> _streamController =
      new StreamController<Event>.broadcast();

  EventSourceReadyState _readyState = EventSourceReadyState.CLOSED;

  http.Client client;
  Duration _retryDelay = const Duration(milliseconds: 3000);
  String? _lastEventId;
  late EventSourceDecoder _decoder;
  String _body;
  String _method;

  StreamSubscription? _responseStreamSubscription;

  /// Creates and connects to a new EventSource.
  ///
  /// Establishes a connection to the specified SSE endpoint and returns
  /// an EventSource that will automatically reconnect on connection loss.
  ///
  /// Parameters:
  /// - [url]: The SSE endpoint URL (String or Uri)
  /// - [client]: Optional custom HTTP client
  /// - [lastEventId]: Resume from this event ID if reconnecting
  /// - [headers]: Custom HTTP headers to include in the request
  /// - [body]: Request body for POST requests
  /// - [method]: HTTP method to use (default: "GET")
  ///
  /// Returns: Connected EventSource ready to receive events
  ///
  /// Throws:
  /// - [EventSourceSubscriptionException]: If initial connection fails
  ///
  /// Example:
  /// ```dart
  /// // Connect to Horizon payments stream
  /// var es = await EventSource.connect(
  ///   "https://horizon.stellar.org/accounts/GXXX.../payments",
  ///   headers: {"Accept": "text/event-stream"},
  ///   lastEventId: "123456" // Resume from last event
  /// );
  ///
  /// es.onMessage.listen((event) {
  ///   print("Payment: ${event.data}");
  /// });
  /// ```
  ///
  /// See also:
  /// - [close] to close the connection
  /// - [readyState] to check connection status
  static Future<EventSource> connect(
    url, {
    http.Client? client,
    String? lastEventId,
    Map<String, String>? headers,
    String? body,
    String? method,
  }) async {
    // parameter initialization
    url = url is Uri ? url : Uri.parse(url);
    client = client ?? new http.Client();
    body = body ?? "";
    method = method ?? "GET";
    EventSource es = new EventSource._internal(
        url, client, lastEventId, headers, body, method);
    await es._start();
    return es;
  }

  EventSource._internal(this.url, this.client, this._lastEventId, this.headers,
      this._body, this._method) {
    _decoder = new EventSourceDecoder(retryIndicator: _updateRetryDelay);
  }

  // proxy the listen call to the controller's listen call
  @override
  StreamSubscription<Event> listen(void onData(Event event)?,
          {Function? onError, void onDone()?, bool? cancelOnError}) =>
      _streamController.stream.listen(onData,
          onError: onError, onDone: onDone, cancelOnError: cancelOnError);

  /// Attempt to start a new connection.
  Future _start() async {
    _readyState = EventSourceReadyState.CONNECTING;
    var request = new http.Request(_method, url);
    request.headers["Cache-Control"] = "no-cache";
    request.headers["Accept"] = "text/event-stream";
    if (_lastEventId?.isNotEmpty == true) {
      request.headers["Last-Event-ID"] = _lastEventId!;
    }
    headers?.forEach((k, v) {
      request.headers[k] = v;
    });
    request.body = _body;

    var response = await client.send(request);
    if (response.statusCode != 200) {
      // server returned an error
      var bodyBytes = await response.stream.toBytes();
      String body = _encodingForHeaders(response.headers).decode(bodyBytes);
      throw new EventSourceSubscriptionException(response.statusCode, body);
    }
    _readyState = EventSourceReadyState.OPEN;
    // start streaming the data
    _responseStreamSubscription = response.stream.transform(_decoder).listen(
        (Event event) {
      if (_readyState == EventSourceReadyState.CLOSED) {
        return;
      }
      _streamController.add(event);
      _lastEventId = event.id;
    },
        cancelOnError: true,
        onError: _retry,
        onDone: () => _readyState = EventSourceReadyState.CLOSED);
  }

  /// Retries until a new connection is established. Uses exponential backoff.
  Future _retry(dynamic e) async {
    _readyState = EventSourceReadyState.CONNECTING;
    // try reopening with exponential backoff
    Duration backoff = _retryDelay;
    while (true) {
      await new Future.delayed(backoff);
      try {
        await _start();
        break;
      } catch (error) {
        _streamController.addError(error);
        backoff *= 2;
      }
    }
  }

  void _updateRetryDelay(Duration retry) {
    _retryDelay = retry;
  }

  /// Closes the EventSource connection.
  ///
  /// Cancels the active stream subscription, sets the state to CLOSED,
  /// and closes the stream controller. After calling this method, the
  /// EventSource will not reconnect and should not be reused.
  ///
  /// Example:
  /// ```dart
  /// EventSource es = await EventSource.connect(url);
  /// // Use the stream...
  /// es.close(); // Clean up when done
  /// ```
  void close() {
    _responseStreamSubscription?.cancel();
    _readyState = EventSourceReadyState.CLOSED;
    _streamController.close();
  }
}

/// Helper function to replicate encodingForCharset behavior
Encoding _encodingForCharset(String? charset, [Encoding defaultTo = latin1]) {
  if (charset == null) return defaultTo;
  return Encoding.getByName(charset) ?? defaultTo;
}

/// Returns the encoding to use for a response with the given headers. This
/// defaults to [LATIN1] if the headers don't specify a charset or
/// if that charset is unknown.
Encoding _encodingForHeaders(Map<String, String> headers) =>
    _encodingForCharset(_contentTypeForHeaders(headers).parameters['charset']);

/// Returns the [MediaType] object for the given headers's content-type.
///
/// Defaults to `application/octet-stream`.
MediaType _contentTypeForHeaders(Map<String, String> headers) {
  var contentType = headers['content-type'];
  if (contentType != null) return new MediaType.parse(contentType);
  return new MediaType("application", "octet-stream");
}
