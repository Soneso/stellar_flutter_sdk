import 'dart:async';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/src/eventsource/event.dart';
import 'package:stellar_flutter_sdk/src/eventsource/encoder.dart';
import 'package:stellar_flutter_sdk/src/eventsource/decoder.dart';

void main() {
  group('Event Tests', () {
    test('should create event with all fields', () {
      var event = Event(
        id: "123",
        event: "message",
        data: "test data",
      );

      expect(event.id, equals("123"));
      expect(event.event, equals("message"));
      expect(event.data, equals("test data"));
    });

    test('should create event with null fields', () {
      var event = Event();

      expect(event.id, isNull);
      expect(event.event, isNull);
      expect(event.data, isNull);
    });

    test('should create message event', () {
      var event = Event.message(id: "456", data: "message data");

      expect(event.id, equals("456"));
      expect(event.event, equals("message"));
      expect(event.data, equals("message data"));
    });

    test('should compare events by id', () {
      var event1 = Event(id: "100");
      var event2 = Event(id: "200");
      var event3 = Event(id: "100");

      expect(event1.compareTo(event2), lessThan(0));
      expect(event2.compareTo(event1), greaterThan(0));
      expect(event1.compareTo(event3), equals(0));
    });

    test('should allow sorting events', () {
      var events = [
        Event(id: "3"),
        Event(id: "1"),
        Event(id: "2"),
      ];

      events.sort();

      expect(events[0].id, equals("1"));
      expect(events[1].id, equals("2"));
      expect(events[2].id, equals("3"));
    });
  });

  group('EventSourceEncoder Tests', () {
    late EventSourceEncoder encoder;

    setUp(() {
      encoder = EventSourceEncoder(compressed: false);
    });

    test('should encode event with all fields', () {
      var event = Event(
        id: "123",
        event: "message",
        data: "test data",
      );

      var encoded = encoder.convertToString(event);

      expect(encoded, contains("id: 123"));
      expect(encoded, contains("event: message"));
      expect(encoded, contains("data: test data"));
    });

    test('should terminate event with double newline', () {
      var event = Event(id: "1", event: "test", data: "data");
      var encoded = encoder.convertToString(event);

      expect(encoded, endsWith("\n\n"));
    });

    test('should skip null fields', () {
      var event = Event(data: "only data");
      var encoded = encoder.convertToString(event);

      expect(encoded, contains("data: only data"));
      expect(encoded, isNot(contains("id:")));
      expect(encoded, isNot(contains("event:")));
    });

    test('should skip empty fields', () {
      var event = Event(id: "", event: "", data: "data");
      var encoded = encoder.convertToString(event);

      expect(encoded, contains("data: data"));
      expect(encoded, isNot(contains("id: ")));
      expect(encoded, isNot(contains("event: ")));
    });

    test('should handle multi-line data', () {
      var event = Event(data: "line1\nline2\nline3");
      var encoded = encoder.convertToString(event);

      expect(encoded, contains("data: line1\ndata: line2\ndata: line3"));
    });

    test('should convert to bytes', () {
      var event = Event(data: "test");
      var bytes = encoder.convert(event);

      expect(bytes, isA<List<int>>());
      expect(bytes.isNotEmpty, isTrue);
    });

    test('should produce valid UTF-8', () {
      var event = Event(data: "test data");
      var bytes = encoder.convert(event);
      var decoded = utf8.decode(bytes);

      expect(decoded, contains("data: test data"));
    });

    test('should throw on chunked compression', () {
      var compressedEncoder = EventSourceEncoder(compressed: true);
      var sink = StreamController<List<int>>();

      expect(
        () => compressedEncoder.startChunkedConversion(sink.sink),
        throwsA(isA<UnsupportedError>()),
      );

      sink.close();
    });

    test('should handle empty event', () {
      var event = Event();
      var encoded = encoder.convertToString(event);

      expect(encoded, equals("\n"));
    });

    test('should preserve special characters in data', () {
      var event = Event(data: "special: chars & symbols!");
      var encoded = encoder.convertToString(event);

      expect(encoded, contains("special: chars & symbols!"));
    });
  });

  group('EventSourceDecoder Tests', () {
    test('should create decoder instance', () {
      var decoder = EventSourceDecoder();
      expect(decoder, isA<EventSourceDecoder>());
    });

    test('should create decoder with retry indicator', () {
      Duration? capturedRetry;
      var decoder = EventSourceDecoder(
        retryIndicator: (retry) => capturedRetry = retry,
      );
      expect(decoder, isA<EventSourceDecoder>());
      expect(decoder.retryIndicator, isNotNull);
    });

    test('should implement StreamTransformer interface', () {
      var decoder = EventSourceDecoder();
      expect(decoder, isA<StreamTransformer<List<int>, Event>>());
    });

    test('should support cast operation', () {
      var decoder = EventSourceDecoder();
      var casted = decoder.cast<List<int>, Event>();
      expect(casted, isA<StreamTransformer>());
    });
  });

  group('EventSource Format Validation', () {
    test('encoder should produce valid SSE format', () {
      var encoder = EventSourceEncoder(compressed: false);
      var event = Event(id: "123", event: "message", data: "test");
      var encoded = encoder.convertToString(event);

      expect(encoded, contains("id: 123\n"));
      expect(encoded, contains("event: message\n"));
      expect(encoded, contains("data: test\n"));
      expect(encoded, endsWith("\n\n"));
    });

    test('encoder should handle multi-line data correctly', () {
      var encoder = EventSourceEncoder(compressed: false);
      var event = Event(data: "line1\nline2");
      var encoded = encoder.convertToString(event);

      expect(encoded, contains("data: line1\ndata: line2\n"));
    });

    test('encoder should skip empty fields', () {
      var encoder = EventSourceEncoder(compressed: false);
      var event = Event(data: "only data");
      var encoded = encoder.convertToString(event);

      expect(encoded.split('\n').where((line) => line.startsWith('id:')).length, equals(0));
      expect(encoded.split('\n').where((line) => line.startsWith('event:')).length, equals(0));
    });

    test('encoder output should be UTF-8 encodable', () {
      var encoder = EventSourceEncoder(compressed: false);
      var event = Event(data: "test");
      var bytes = encoder.convert(event);

      expect(() => utf8.decode(bytes), returnsNormally);
    });

    test('decoder should handle retry indicator callback', () {
      Duration? capturedRetry;
      var decoder = EventSourceDecoder(
        retryIndicator: (retry) => capturedRetry = retry,
      );

      expect(decoder.retryIndicator, isNotNull);
    });
  });
}
