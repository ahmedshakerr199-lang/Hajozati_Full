import 'models.dart';

class AuthException implements Exception {
  const AuthException(this.message);
  final String message;
}

abstract interface class WhatsAppOtpProvider {
  Future<void> sendRegistrationOtp(String phone);
  Future<bool> verifyOtp(String phone, String code);
}

class MockWhatsAppOtpProvider implements WhatsAppOtpProvider {
  static const testCode = '123456';
  final Map<String, String> _codes = {};

  String? getCodeForTesting(String phone) => _codes[normalizePhone(phone)];

  @override
  Future<void> sendRegistrationOtp(String phone) async {
    _codes[normalizePhone(phone)] = testCode;
  }

  @override
  Future<bool> verifyOtp(String phone, String code) async =>
      _codes[normalizePhone(phone)] == code.trim();
}

class MockAuthRepository {
  static const _seedPhone = '07701234567';
  static final List<UserProfile> _memoryUsers = [
    const UserProfile(
      id: 'seed-ahmed',
      fullName: 'Ahmed Ali Hassan',
      phone: _seedPhone,
      email: 'ahmed@example.com',
      governorateId: 'baghdad',
    ),
  ];
  final WhatsAppOtpProvider otpProvider;

  MockAuthRepository({WhatsAppOtpProvider? otpProvider})
      : otpProvider = otpProvider ?? MockWhatsAppOtpProvider();

  Future<List<UserProfile>> _users() async => List.unmodifiable(_memoryUsers);

  Future<UserProfile> login(String phone) async {
    final normalized = normalizePhone(phone);
    if (!isValidIraqiPhone(normalized)) {
      throw const AuthException('رقم الهاتف غير صالح');
    }
    final user = (await _users()).cast<UserProfile?>().firstWhere(
          (item) => item!.phone == normalized,
          orElse: () => null,
        );
    if (user == null) {
      throw const AuthException('لا يوجد حساب مرتبط بهذا الرقم');
    }
    return user;
  }

  Future<UserProfile> register({
    required String fullName,
    required String phone,
    required String governorateId,
    required DateTime dateOfBirth,
    String email = '',
    bool phoneVerified = true,
  }) async {
    final normalized = normalizePhone(phone);
    final normalizedName = normalizeFullName(fullName);
    final nameError = fullNameValidationError(normalizedName, isArabic: true);
    if (nameError != null) {
      throw AuthException(nameError);
    }
    if (!isValidIraqiPhone(normalized)) {
      throw const AuthException('رقم الهاتف غير صالح');
    }
    if (!phoneVerified) {
      throw const AuthException('يجب تأكيد رقم الهاتف أولًا');
    }
    if (governorateId.isEmpty) {
      throw const AuthException('اختر محافظة السكن');
    }
    if (!isOlderThanTwelve(dateOfBirth)) {
      throw const AuthException(
          'يجب أن يكون عمر المستخدم أكبر من 12 سنة لإنشاء حساب.');
    }
    final users = await _users();
    if (users.any((user) => user.phone == normalized)) {
      throw const AuthException('رقم الهاتف مسجل مسبقًا');
    }
    final user = UserProfile(
      id: 'user-${DateTime.now().millisecondsSinceEpoch}',
      fullName: normalizedName,
      phone: normalized,
      phoneVerified: true,
      email: email.trim(),
      governorateId: governorateId,
      dateOfBirth: dateOfBirth,
      createdAt: DateTime.now(),
    );
    _memoryUsers.add(user);
    return user;
  }
}
