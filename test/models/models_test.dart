import 'package:flutter_test/flutter_test.dart';
import 'package:healthcompass_mobile/models/ai_model.dart';
import 'package:healthcompass_mobile/models/appointment.dart';
import 'package:healthcompass_mobile/models/chat_session.dart';
import 'package:healthcompass_mobile/models/medical_record.dart';
import 'package:healthcompass_mobile/models/notification_item.dart';
import 'package:healthcompass_mobile/models/prediction.dart';
import 'package:healthcompass_mobile/models/user_profile.dart';

// Payloads below were captured live from a local Django instance running
// the real DRF serializers (apps/api/serializers.py), not hand-guessed --
// see the record/prediction/ai-model seeding + /auth/me//emergency-card/
// appointment fetches performed during manual verification.

void main() {
  group('MedicalRecord.fromJson', () {
    test('parses a detail response with nested lab/wearable data', () {
      final rec = MedicalRecord.fromJson({
        'id': '51a04d48-2990-48d0-9b6d-d62452dda29e',
        'title': 'Full Blood Panel',
        'record_type': 'lab_result',
        'record_type_display': 'Lab Result',
        'record_date': '2024-03-01',
        'uploaded_at': '2026-07-17T13:54:11.017494+03:00',
        'is_flagged': false,
        'notes': 'Fasting sample',
        'parsed_data': {'lab': 'CityLab'},
        'raw_text': '',
        'lab_values': [
          {
            'parameter_name': 'Glucose',
            'value': '105',
            'unit': 'mg/dL',
            'reference_range': '70-100',
            'is_abnormal': true,
            'is_critical': false,
            'measured_at': '2024-03-01T08:00:00+02:00',
          },
        ],
        'wearable_points': [
          {
            'metric': 'heart_rate',
            'metric_display': 'Heart Rate (bpm)',
            'value': 72.0,
            'unit': 'bpm',
            'recorded_at': '2024-03-01T08:00:00+02:00',
          },
        ],
      });

      expect(rec.title, 'Full Blood Panel');
      expect(rec.labValues, hasLength(1));
      expect(rec.labValues.single.parameterName, 'Glucose');
      expect(rec.labValues.single.isAbnormal, isTrue);
      expect(rec.wearablePoints.single.value, 72.0);
      expect(rec.parsedData['lab'], 'CityLab');
      expect(rec.rawText, ''); // empty string, not null
    });

    test('defaults missing optional fields safely', () {
      final rec = MedicalRecord.fromJson({'id': 'x', 'title': 'Bare', 'record_type': 'other'});
      expect(rec.labValues, isEmpty);
      expect(rec.wearablePoints, isEmpty);
      expect(rec.parsedData, isEmpty);
      expect(rec.isFlagged, isFalse);
    });
  });

  group('Prediction.fromJson', () {
    test('parses risk score, result, and input data', () {
      final pred = Prediction.fromJson({
        'id': '0e0b44f2-2349-4a86-bb67-9fdf48f6fc9b',
        'model_name': 'QA Test Model',
        'model_category': 'general',
        'model_slug': 'qa-test-model',
        'risk_score': 0.32,
        'risk_pct': 32.0,
        'result_label': 'Low Risk',
        'interpretation': 'Low risk based on inputs.',
        'result': {'label': 'Low Risk'},
        'input_data': {'age': '40'},
        'created_at': '2026-07-17T13:54:11.038707+03:00',
      });

      expect(pred.modelName, 'QA Test Model');
      expect(pred.riskPct, 32.0);
      expect(pred.result['label'], 'Low Risk');
      expect(pred.inputData['age'], '40');
    });
  });

  group('AIModel.fromJson', () {
    test('parses list-shape response', () {
      final model = AIModel.fromJson({
        'id': 'be27f6cc-2c7d-4f81-9408-5cdfa9fde9ac',
        'name': 'QA Test Model',
        'slug': 'qa-test-model',
        'description': '',
        'category': 'general',
        'category_display': 'General Health',
        'input_type': 'tabular',
        'input_type_display': 'Tabular (manual form)',
        'run_count': 0,
      });
      expect(model.categoryDisplay, 'General Health');
      expect(model.inputSchema, isNull);
    });

    test('parses detail-shape response with input_schema', () {
      final model = AIModel.fromJson({
        'id': 'be27f6cc-2c7d-4f81-9408-5cdfa9fde9ac',
        'name': 'QA Test Model',
        'slug': 'qa-test-model',
        'category': 'general',
        'input_type': 'tabular',
        'run_count': 0,
        'input_schema': {'age': {'label': 'Age'}},
      });
      expect(model.inputSchema!['age']['label'], 'Age');
    });
  });

  group('UserProfile.fromJson', () {
    test('parses /auth/me/ response, including null profile_picture', () {
      final user = UserProfile.fromJson({
        'id': 8,
        'username': '',
        'email': 'mobile-qa-throwaway@example.com',
        'first_name': 'QA',
        'last_name': 'Throwaway',
        'full_name': 'QA Throwaway',
        'role': 'patient',
        'role_display': 'Patient',
        'is_approved': true,
        'profile_picture': null,
        'phone_number': '',
        'date_of_birth': null,
      });
      expect(user.fullName, 'QA Throwaway');
      expect(user.isApproved, isTrue);
      expect(user.profilePicture, isNull);
    });
  });

  group('EmergencyCard.fromJson', () {
    test('parses the merged user+profile shape', () {
      final card = EmergencyCard.fromJson({
        'full_name': 'QA Throwaway',
        'email': 'mobile-qa-throwaway@example.com',
        'date_of_birth': null,
        'phone_number': '',
        'blood_type': '',
        'allergies': '',
        'emergency_contact_name': '',
        'emergency_contact_phone': '',
        'token': 'bebcf63a-c8e0-49d6-8b8f-86e328dc88a6',
      });
      expect(card.fullName, 'QA Throwaway');
      expect(card.token, isNotEmpty);
      expect(card.dateOfBirth, isNull);
    });
  });

  group('Appointment.fromJson / toJson', () {
    test('round-trips the create/update payload fields', () {
      final appt = Appointment.fromJson({
        'id': 'f42e8df6-b137-4e22-8f72-e600fbe5666d',
        'title': 'Cardiology check-up',
        'doctor_name': 'Dr. Test',
        'location': 'Test Clinic',
        'appointment_datetime': '2026-08-01T12:00:00+03:00',
        'notes': 'Bring prior results',
        'remind_24h': true,
        'remind_3h': false,
        'remind_2h': false,
        'remind_1h': true,
        'is_completed': false,
        'is_cancelled': false,
        'created_at': '2026-07-17T13:53:26.574130+03:00',
      });
      expect(appt.title, 'Cardiology check-up');
      expect(appt.remind24h, isTrue);
      expect(appt.remind3h, isFalse);

      final json = appt.toJson();
      expect(json['title'], 'Cardiology check-up');
      expect(json['remind_1h'], true);
      expect(json.containsKey('id'), isFalse); // request body, not a response echo
    });
  });

  group('NotificationItem', () {
    test('fromJson parses and copyWith flips isRead', () {
      final n = NotificationItem.fromJson({
        'id': '1',
        'type': 'system',
        'type_display': 'System',
        'title': 'Welcome',
        'message': 'Hi there',
        'is_read': false,
        'link': null,
        'created_at': '2026-01-01T00:00:00Z',
      });
      expect(n.isRead, isFalse);
      final read = n.copyWith(isRead: true);
      expect(read.isRead, isTrue);
      expect(read.id, n.id);
      expect(read.title, n.title);
    });
  });

  group('ChatSession / ChatHistoryMessage', () {
    test('ChatSession.fromJson and copyWith(title:)', () {
      final s = ChatSession.fromJson({
        'id': 'sess-1',
        'title': 'Old title',
        'created_at': '2026-01-01T00:00:00Z',
        'updated_at': '2026-01-02T00:00:00Z',
        'message_count': 4,
      });
      expect(s.messageCount, 4);
      final renamed = s.copyWith(title: 'New title');
      expect(renamed.title, 'New title');
      expect(renamed.id, s.id);
    });

    test('ChatHistoryMessage.fromJson', () {
      final m = ChatHistoryMessage.fromJson({
        'id': 'msg-1',
        'query': 'How is my HbA1c?',
        'response': 'It has improved.',
        'created_at': '2026-01-01T00:00:00Z',
      });
      expect(m.query, 'How is my HbA1c?');
      expect(m.response, 'It has improved.');
    });
  });
}
