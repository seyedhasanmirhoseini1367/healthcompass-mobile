import 'package:flutter_test/flutter_test.dart';
import 'package:healthcompass_mobile/models/chat_event.dart';

void main() {
  group('ChatEvent.parseSseLine', () {
    test('parses a token event', () {
      final e = ChatEvent.parseSseLine('data: {"type": "token", "content": "Hello"}');
      expect(e, isNotNull);
      expect(e!.type, ChatEventType.token);
      expect(e.content, 'Hello');
    });

    test('parses an empty sources list', () {
      final e = ChatEvent.parseSseLine('data: {"type": "sources", "sources": []}');
      expect(e!.type, ChatEventType.sources);
      expect(e.sources, isEmpty);
    });

    test('parses a personal-record source', () {
      final e = ChatEvent.parseSseLine(
          'data: {"type": "sources", "sources": [{"title": "Lab Results Jan 2024", "document_type": "lab_result", "record_date": "2024-01-15", "document_id": "abc", "record_id": "rec-1"}]}');
      final src = e!.sources!.single;
      expect(src.recordId, 'rec-1');
      expect(src.isGeneral, isFalse);
      expect(src.documentType, 'lab_result');
    });

    test('parses a general/article source', () {
      final e = ChatEvent.parseSseLine(
          'data: {"type": "sources", "sources": [{"title": "Diabetes Overview", "source_name": "Mayo Clinic", "source_url": "https://example.com", "topic": "diabetes", "is_general": true}]}');
      final src = e!.sources!.single;
      expect(src.isGeneral, isTrue);
      expect(src.sourceName, 'Mayo Clinic');
    });

    test('parses meta fields', () {
      final e = ChatEvent.parseSseLine(
          'data: {"type": "meta", "provider": "groq", "chunks": 2, "mode": "trajectory", "safety_routed": false, "triggered_rules": []}');
      expect(e!.provider, 'groq');
      expect(e.chunks, 2);
      expect(e.mode, 'trajectory');
    });

    test('parses a chart event, including null reference_low', () {
      // Real payload captured from a live /assistant/stream/ response.
      final e = ChatEvent.parseSseLine(
          'data: {"type": "chart", "chart": {"biomarker": "hba1c", "display_name": "Hba1C", "unit": "%", "labels": ["Jan 2024", "Jun 2024"], "values": [7.8, 6.9], "trend_direction": "DECREASING", "pct_change": -11.5, "slope_per_month": -0.184, "delta_score": -0.57, "reference_low": null, "reference_high": 6.5}}');
      final chart = e!.chart!;
      expect(chart.displayName, 'Hba1C');
      expect(chart.labels, ['Jan 2024', 'Jun 2024']);
      expect(chart.values, [7.8, 6.9]);
      expect(chart.referenceLow, isNull);
      expect(chart.referenceHigh, 6.5);
      expect(chart.trendDirection, 'DECREASING');
    });

    test('parses a done event', () {
      final e = ChatEvent.parseSseLine('data: {"type": "done"}');
      expect(e!.type, ChatEventType.done);
    });

    test('parses an error event', () {
      final e = ChatEvent.parseSseLine('data: {"type": "error", "message": "boom"}');
      expect(e!.type, ChatEventType.error);
      expect(e.errorMessage, 'boom');
    });

    test('ignores keep-alive comments and blank lines', () {
      expect(ChatEvent.parseSseLine(': keep-alive'), isNull);
      expect(ChatEvent.parseSseLine(''), isNull);
      expect(ChatEvent.parseSseLine('data: '), isNull);
    });

    test('ignores malformed JSON rather than throwing', () {
      expect(ChatEvent.parseSseLine('data: {not json'), isNull);
    });
  });
}
