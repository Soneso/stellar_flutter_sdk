import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/src/eventsource/event.dart';
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

  group('EventSourceDecoder Tests', () {
    test('should create decoder instance', () {
      var decoder = EventSourceDecoder();
      expect(decoder, isA<EventSourceDecoder>());
    });

    test('should create decoder with retry indicator', () {
      var decoder = EventSourceDecoder(
        retryIndicator: (retry) {},
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
}
