import "dart:async";
import "dart:convert";
import "event.dart";

/// Callback function type for retry delay notifications.
///
/// Called when the SSE stream receives a retry field, indicating
/// the client should wait the specified duration before reconnecting.
typedef RetryIndicator = void Function(Duration retry);

/// Transforms a byte stream into Server-Sent Events.
///
/// EventSourceDecoder implements the SSE parsing specification, converting
/// raw HTTP response bytes into structured [Event] objects. It handles:
/// - UTF-8 decoding of the byte stream
/// - Line-by-line parsing of SSE fields
/// - Event assembly from multiple field lines
/// - Retry delay notifications
///
/// SSE field types:
/// - "event": Sets the event type name
/// - "data": Appends to the event data (multiple lines supported)
/// - "id": Sets the event identifier
/// - "retry": Specifies reconnection delay in milliseconds
/// - Lines starting with ":" are comments (ignored)
///
/// Events are completed and emitted when an empty line is encountered.
///
/// Example:
/// ```dart
/// // Typically used internally by EventSource
/// var decoder = EventSourceDecoder(
///   retryIndicator: (duration) => print("Retry in $duration")
/// );
/// var eventStream = byteStream.transform(decoder);
/// ```
///
/// See also:
/// - [EventSource] which uses this decoder internally
/// - [EventSourceEncoder] for encoding events
class EventSourceDecoder implements StreamTransformer<List<int>, Event> {
  /// Optional callback invoked when retry delay is received.
  RetryIndicator? retryIndicator;

  /// Creates a new EventSourceDecoder.
  ///
  /// Parameters:
  /// - [retryIndicator]: Optional callback for retry notifications
  EventSourceDecoder({this.retryIndicator});

  /// Transforms a byte stream into an event stream.
  ///
  /// Binds this decoder to the input [stream] and returns a stream
  /// of parsed [Event] objects.
  ///
  /// Parameters:
  /// - [stream]: Input stream of UTF-8 encoded SSE data
  ///
  /// Returns: Stream of parsed events
  Stream<Event> bind(Stream<List<int>> stream) {
    late StreamController<Event> controller;
    controller = new StreamController(onListen: () {
      // the event we are currently building
      Event currentEvent = new Event();
      // the regexes we will use later
      RegExp lineRegex = new RegExp(r"^([^:]*)(?::)?(?: )?(.*)?$");
      RegExp removeEndingNewlineRegex = new RegExp(r"^((?:.|\n)*)\n$");
      // This stream will receive chunks of data that is not necessarily a
      // single event. So we build events on the fly and broadcast the event as
      // soon as we encounter a double newline, then we start a new one.
      stream
          .transform(new Utf8Decoder())
          .transform(new LineSplitter())
          .listen((String line) {
        if (line.isEmpty) {
          // event is done
          // strip ending newline from data
          if (currentEvent.data != null) {
            var match = removeEndingNewlineRegex.firstMatch(currentEvent.data!);
            currentEvent.data = match?.group(1);
          }
          controller.add(currentEvent);
          currentEvent = new Event();
          return;
        }
        // match the line prefix and the value using the regex
        Match? match = lineRegex.firstMatch(line);
        String? field = match?.group(1);
        String? value = match?.group(2) ?? "";
        if (field?.isEmpty == true) {
          // lines starting with a colon are to be ignored
          return;
        }
        switch (field) {
          case "event":
            currentEvent.event = value;
            break;
          case "data":
            currentEvent.data = (currentEvent.data ?? "") + value + "\n";
            break;
          case "id":
            currentEvent.id = value;
            break;
          case "retry":
            retryIndicator?.call(new Duration(milliseconds: int.parse(value)));
            break;
        }
      });
    });
    return controller.stream;
  }

  StreamTransformer<RS, RT> cast<RS, RT>() =>
      StreamTransformer.castFrom<List<int>, Event, RS, RT>(this);
}
