import 'package:flutter_test/flutter_test.dart';
import 'package:task_track/core/utils/validators.dart';

String _text(int length) => List.filled(length, 'a').join();

void main() {
  test('title valid & kosong', () {
    expect(Validators.validateTitle('Tugas A'), isNull);
    expect(Validators.validateTitle('  '), 'error_title_empty');
    expect(Validators.validateTitle(null), 'error_title_empty');
  });

  test('subject', () {
    expect(Validators.validateSubject('Matkul'), isNull);
    expect(Validators.validateSubject(''), 'error_subject_empty');
  });

  test('task fields enforce Firestore maximum lengths', () {
    expect(
      Validators.validateTitle(_text(Validators.taskTitleMaxLength)),
      isNull,
    );
    expect(
      Validators.validateTitle(_text(Validators.taskTitleMaxLength + 1)),
      'error_title_too_long',
    );
    expect(
      Validators.validateSubject(_text(Validators.taskSubjectMaxLength)),
      isNull,
    );
    expect(
      Validators.validateSubject(_text(Validators.taskSubjectMaxLength + 1)),
      'error_subject_too_long',
    );
    expect(
      Validators.validateDescription(
        _text(Validators.taskDescriptionMaxLength),
      ),
      isNull,
    );
    expect(
      Validators.validateDescription(
        _text(Validators.taskDescriptionMaxLength + 1),
      ),
      'error_description_too_long',
    );
  });

  test('deadline must be present and in the future', () {
    final now = DateTime(2026, 1, 1, 12);
    expect(Validators.validateDeadline(null, now: now), 'deadline_required');
    expect(
      Validators.validateDeadline(now, now: now),
      'error_deadline_not_future',
    );
    expect(
      Validators.validateDeadline(
        now.subtract(const Duration(seconds: 1)),
        now: now,
      ),
      'error_deadline_not_future',
    );
    expect(
      Validators.validateDeadline(
        now.add(const Duration(seconds: 1)),
        now: now,
      ),
      isNull,
    );
    final pastDeadline = now.subtract(const Duration(days: 1));
    expect(
      Validators.validateDeadline(
        pastDeadline,
        now: now,
        originalValue: pastDeadline,
      ),
      isNull,
    );
  });

  test('profile fields enforce Firestore maximum lengths', () {
    expect(
      Validators.validateFullName(
        _text(Validators.profileDisplayNameMaxLength),
      ),
      isNull,
    );
    expect(
      Validators.validateFullName(
        _text(Validators.profileDisplayNameMaxLength + 1),
      ),
      'error_display_name_too_long',
    );
    expect(
      Validators.validateInstitution(
        _text(Validators.profileInstitutionMaxLength + 1),
      ),
      'error_institution_too_long',
    );
    expect(
      Validators.validateMajor(_text(Validators.profileMajorMaxLength + 1)),
      'error_major_too_long',
    );
  });

  test('email valid & invalid', () {
    expect(Validators.validateEmail('user@mail.com'), isNull);
    expect(Validators.validateEmail('student+takumi@example.com'), isNull);
    expect(Validators.validateEmail(''), 'error_email_empty');
    expect(Validators.validateEmail('not-an-email'), 'error_email_invalid');
  });

  test('password minimum 6', () {
    expect(Validators.validatePassword('123456'), isNull);
    expect(Validators.validatePassword('12345'), 'error_password_short');
    expect(Validators.validatePassword(''), 'error_password_empty');
  });

  test('confirm password cocok', () {
    expect(Validators.validateConfirmPassword('abc', 'abc'), isNull);
    expect(
      Validators.validateConfirmPassword('ab', 'abc'),
      'error_password_mismatch',
    );
    expect(
      Validators.validateConfirmPassword('', 'abc'),
      'error_confirm_empty',
    );
  });

  test('nama lengkap', () {
    expect(Validators.validateFullName('Budi'), isNull);
    expect(Validators.validateFullName(' '), 'error_name_empty');
    expect(
      Validators.validateFullName(
        _text(Validators.profileDisplayNameMaxLength + 1),
      ),
      'error_display_name_too_long',
    );
  });
}
