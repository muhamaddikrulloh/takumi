class Validators {
  Validators._();

  static const taskTitleMaxLength = 300;
  static const taskSubjectMaxLength = 120;
  static const taskDescriptionMaxLength = 5000;
  static const profileDisplayNameMaxLength = 120;
  static const profileInstitutionMaxLength = 150;
  static const profileMajorMaxLength = 150;

  static final _emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

  static String? validateTitle(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'error_title_empty';
    }
    if (value.trim().length > taskTitleMaxLength) {
      return 'error_title_too_long';
    }
    return null;
  }

  static String? validateSubject(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'error_subject_empty';
    }
    if (value.trim().length > taskSubjectMaxLength) {
      return 'error_subject_too_long';
    }
    return null;
  }

  static String? validateDescription(String? value) {
    if (value != null && value.trim().length > taskDescriptionMaxLength) {
      return 'error_description_too_long';
    }
    return null;
  }

  static String? validateDeadline(
    DateTime? value, {
    DateTime? now,
    DateTime? originalValue,
  }) {
    if (value == null) {
      return 'deadline_required';
    }
    if (originalValue != null && value == originalValue) return null;
    if (!value.isAfter(now ?? DateTime.now())) {
      return 'error_deadline_not_future';
    }
    return null;
  }

  static String? validateInstitution(String? value) {
    return _validateMaxLength(
      value,
      profileInstitutionMaxLength,
      'error_institution_too_long',
    );
  }

  static String? validateMajor(String? value) {
    return _validateMaxLength(
      value,
      profileMajorMaxLength,
      'error_major_too_long',
    );
  }

  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'error_email_empty';
    }
    if (!_emailRegex.hasMatch(value.trim())) {
      return 'error_email_invalid';
    }
    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'error_password_empty';
    }
    if (value.length < 6) {
      return 'error_password_short';
    }
    return null;
  }

  static String? validateConfirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'error_confirm_empty';
    }
    if (value != password) {
      return 'error_password_mismatch';
    }
    return null;
  }

  static String? validateFullName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'error_name_empty';
    }
    if (value.trim().length > profileDisplayNameMaxLength) {
      return 'error_display_name_too_long';
    }
    return null;
  }

  static String? _validateMaxLength(
    String? value,
    int maxLength,
    String errorKey,
  ) {
    return value != null && value.trim().length > maxLength ? errorKey : null;
  }
}
