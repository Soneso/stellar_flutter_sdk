import "dart:convert";
import 'package:archive/archive.dart' as archive;
import "event.dart";

/// Encodes [Event] objects into SSE-formatted byte streams.
///
/// EventSourceEncoder converts structured [Event] objects into the
/// Server-Sent Events wire format. It handles:
/// - Encoding event fields (id, event, data)
/// - Multi-line data field handling
/// - Optional gzip compression
/// - UTF-8 encoding
///
/// The encoder produces SSE-formatted output like:
/// ```
/// id: 123
/// event: message
/// data: {"key": "value"}
///
/// ```
///
/// Each field is encoded as "field: value\n", and events are terminated
/// with an extra newline.
///
/// Example:
/// ```dart
/// var encoder = EventSourceEncoder(compressed: false);
/// Event event = Event(
///   id: "123",
///   event: "message",
///   data: '{"type":"payment"}'
/// );
/// List<int> bytes = encoder.convert(event);
/// ```
///
/// See also:
/// - [EventSourceDecoder] for decoding SSE streams
/// - [Event] for event structure
class EventSourceEncoder extends Converter<Event, List<int>> {
  /// Whether to apply gzip compression to the output.
  final bool compressed;

  /// Creates a new EventSourceEncoder.
  ///
  /// Parameters:
  /// - [compressed]: Enable gzip compression (default: false)
  const EventSourceEncoder({this.compressed = false});

  static Map<String, Function> _fields = {
    "id: ": (e) => e.id,
    "event: ": (e) => e.event,
    "data: ": (e) => e.data,
  };

  /// Converts an [Event] to SSE-formatted bytes.
  ///
  /// Encodes the event into SSE format and optionally compresses
  /// the result with gzip.
  ///
  /// Parameters:
  /// - [event]: The event to encode
  ///
  /// Returns: UTF-8 encoded bytes (optionally compressed)
  @override
  List<int> convert(Event event) {
    String payload = convertToString(event);
    List<int> bytes = utf8.encode(payload);
    if (compressed) {
      bytes = archive.GZipEncoder().encode(bytes) ?? bytes;
    }
    return bytes;
  }

  /// Converts an [Event] to SSE-formatted string.
  ///
  /// Generates the SSE wire format string with proper field prefixes
  /// and newline handling for multi-line data fields.
  ///
  /// Parameters:
  /// - [event]: The event to convert
  ///
  /// Returns: SSE-formatted string
  String convertToString(Event event) {
    String payload = "";
    for (String prefix in _fields.keys) {
      String? value = _fields[prefix]?.call(event);
      if (value == null || value.isEmpty) {
        continue;
      }
      // multi-line values need the field prefix on every line
      value = value.replaceAll("\n", "\n$prefix");
      payload += prefix + value + "\n";
    }
    payload += "\n";
    return payload;
  }

  /// Creates a chunked conversion sink for encoding events.
  ///
  /// Chains together the event-to-string conversion with UTF-8 encoding.
  ///
  /// **Note**: Chunked gzip compression is not supported because the
  /// cross-platform archive package does not provide streaming compression.
  /// For compressed output, use the [convert] method instead which compresses
  /// complete events.
  ///
  /// Returns: Sink that accepts Event objects and outputs encoded bytes.
  ///
  /// Throws: [UnsupportedError] if [compressed] is true.
  @override
  Sink<Event> startChunkedConversion(Sink<List<int>> sink) {
    if (compressed) {
      throw UnsupportedError(
          'Chunked gzip compression not supported. '
          'The cross-platform archive package does not support streaming compression. '
          'Options: (1) Use EventSourceEncoder(compressed: false) for chunked conversion, '
          'or (2) Use convert() method for compressed single events.');
    }
    Sink<dynamic> inputSink = sink;
    inputSink =
        utf8.encoder.startChunkedConversion(inputSink as Sink<List<int>>);
    return ProxySink(
        onAdd: (Event event) => inputSink.add(convertToString(event)),
        onClose: () => inputSink.close());
  }
}

/// Proxy sink that delegates to callback functions.
///
/// Used internally by [EventSourceEncoder] to create a chunked
/// conversion sink that transforms events to strings before
/// passing them to the underlying UTF-8 and gzip encoders.
class ProxySink<T> implements Sink<T> {
  /// Callback invoked when data is added to the sink.
  void Function(T) onAdd;

  /// Callback invoked when the sink is closed.
  void Function() onClose;

  /// Creates a new proxy sink with the given callbacks.
  ProxySink({required this.onAdd, required this.onClose});

  /// Adds data to the sink by invoking the onAdd callback.
  @override
  void add(t) => onAdd(t);

  /// Closes the sink by invoking the onClose callback.
  @override
  void close() => onClose();
}
