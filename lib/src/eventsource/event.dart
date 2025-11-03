/// Represents a Server-Sent Event received from an EventSource stream.
///
/// Server-Sent Events (SSE) provide a standard way to push real-time
/// updates from a server to a client over HTTP. Each event can contain
/// an ID, event type, and data payload.
///
/// Properties:
/// - [id]: Unique identifier for event replay (Last-Event-ID)
/// - [event]: Event type name (defaults to "message")
/// - [data]: Event payload data as a string
///
/// Common event types in Stellar:
/// - "open": Connection established
/// - "message": Data update received
/// - "error": Error occurred
///
/// Example:
/// ```dart
/// // Listen for events from Horizon
/// eventSource.listen((Event event) {
///   if (event.event == "message") {
///     // Parse the event data
///     var json = jsonDecode(event.data!);
///     print("Received: $json");
///   }
/// });
/// ```
///
/// See also:
/// - [EventSource] for creating SSE connections
/// - [EventSourceDecoder] for parsing SSE streams
class Event implements Comparable<Event> {
  /// Event identifier for replay functionality.
  ///
  /// An identifier that can be used to allow a client to replay
  /// missed events by returning the Last-Event-Id header.
  /// Set to null or empty string if not required.
  String? id;

  /// The event type name.
  ///
  /// Identifies the type of event being sent. Common values include
  /// "message" for data updates, "open" for connection establishment,
  /// and "error" for error conditions. Set to null or empty string
  /// if not required.
  String? event;

  /// The event payload data.
  ///
  /// Contains the actual data payload of the event, typically as
  /// JSON or plain text. Set to null or empty string if no data
  /// is included.
  String? data;

  /// Creates a new Event with optional id, event type, and data.
  Event({this.id, this.event, this.data});

  /// Creates a new message event with optional id and data.
  ///
  /// Convenience constructor for the most common event type.
  ///
  /// Example:
  /// ```dart
  /// Event event = Event.message(id: "123", data: '{"type":"payment"}');
  /// ```
  Event.message({this.id, this.data}) : event = "message";

  /// Compares events by their ID for ordering.
  ///
  /// Allows events to be sorted or compared based on their
  /// identifier values.
  @override
  int compareTo(Event other) => id!.compareTo(other.id!);
}
