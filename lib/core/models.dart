class Hotel {
  const Hotel({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.governorateAr,
    required this.governorateEn,
    required this.addressAr,
    required this.addressEn,
    required this.rating,
    required this.descriptionAr,
    required this.descriptionEn,
    required this.amenitiesAr,
    required this.amenitiesEn,
    required this.rooms,
    required this.latitude,
    required this.longitude,
  });

  final String id;
  final String nameAr;
  final String nameEn;
  final String governorateAr;
  final String governorateEn;
  final String addressAr;
  final String addressEn;
  final double rating;
  final String descriptionAr;
  final String descriptionEn;
  final List<String> amenitiesAr;
  final List<String> amenitiesEn;
  final List<Room> rooms;
  final double latitude;
  final double longitude;

  double get minPrice =>
      rooms.map((e) => e.price).reduce((a, b) => a < b ? a : b);
}

class Room {
  const Room({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.capacity,
    int? maxAdults,
    this.maxChildren,
    required this.bedsAr,
    required this.bedsEn,
    required this.price,
    required this.available,
  }) : maxAdults = maxAdults ?? capacity;

  final String id;
  final String nameAr;
  final String nameEn;
  final int capacity;
  final int maxAdults;
  final int? maxChildren;
  final String bedsAr;
  final String bedsEn;
  final double price;
  final bool available;
}

class SearchCriteria {
  const SearchCriteria({
    required this.governorate,
    required this.checkIn,
    required this.checkOut,
    required this.adults,
    required this.children,
  });

  final String governorate;
  final DateTime checkIn;
  final DateTime checkOut;
  final int adults;
  final int children;

  int get nights {
    final diff = checkOut.difference(checkIn).inDays;
    return diff <= 0 ? 1 : diff;
  }
}

class UserProfile {
  const UserProfile({
    this.id = '',
    required this.fullName,
    required this.phone,
    this.phoneVerified = true,
    this.email = '',
    this.governorateId = '',
    this.dateOfBirth,
    this.preferredLanguage = 'ar',
    this.role = 'user',
    this.createdAt,
  });

  final String id;
  final String fullName;
  final String phone;
  final bool phoneVerified;
  final String email;
  final String governorateId;
  final DateTime? dateOfBirth;
  final String preferredLanguage;
  final String role;
  final DateTime? createdAt;
}

String normalizePhone(String value) {
  final digits = value.replaceAll(RegExp(r'[^0-9+]'), '');
  if (digits.startsWith('+964')) return '0${digits.substring(4)}';
  if (digits.startsWith('964')) return '0${digits.substring(3)}';
  return digits;
}

bool isValidIraqiPhone(String value) {
  return RegExp(r'^07[3-9][0-9]{8}$').hasMatch(normalizePhone(value));
}

String normalizeFullName(String value) =>
    value.trim().replaceAll(RegExp(r'\s+'), ' ');

bool hasValidFullNameCharacters(String value) {
  final normalized = normalizeFullName(value);
  if (normalized.isEmpty) return false;
  return RegExp(
    r'^[A-Za-z\u0621-\u063A\u0641-\u064A\u0671-\u06D3\u064B-\u065F\u0670]+(?: [A-Za-z\u0621-\u063A\u0641-\u064A\u0671-\u06D3\u064B-\u065F\u0670]+)*$',
  ).hasMatch(normalized);
}

bool hasTripleName(String value) {
  final normalized = normalizeFullName(value);
  return hasValidFullNameCharacters(normalized) &&
      normalized.split(' ').length >= 3;
}

String? fullNameValidationError(String? value, {required bool isArabic}) {
  final normalized = normalizeFullName(value ?? '');
  if (normalized.isEmpty) {
    return isArabic ? 'يرجى إدخال الاسم الثلاثي' : 'Enter your full name';
  }
  if (!hasValidFullNameCharacters(normalized)) {
    return isArabic
        ? 'الاسم يجب أن يحتوي على حروف فقط'
        : 'Name must contain letters only';
  }
  if (normalized.split(' ').length < 3) {
    return isArabic ? 'يرجى إدخال الاسم الثلاثي' : 'Enter your full name';
  }
  return null;
}

int ageAt(DateTime birthDate, DateTime today) {
  var age = today.year - birthDate.year;
  final birthdayPassed = today.month > birthDate.month ||
      (today.month == birthDate.month && today.day >= birthDate.day);
  if (!birthdayPassed) age--;
  return age;
}

bool isOlderThanTwelve(DateTime birthDate, [DateTime? today]) =>
    ageAt(birthDate, today ?? DateTime.now()) > 12;

enum AuthStatus { unauthenticated, guest, authenticated }

enum BookingStatus {
  pendingHotelApproval,
  confirmed,
  rejected,
  cancelledByUser,
  completed,
}

extension BookingStatusLabels on BookingStatus {
  String label(bool isArabic) {
    if (isArabic) {
      return switch (this) {
        BookingStatus.pendingHotelApproval => 'بانتظار قبول الطلب',
        BookingStatus.confirmed => 'تم الحجز',
        BookingStatus.rejected => 'مرفوض',
        BookingStatus.cancelledByUser => 'ملغي',
        BookingStatus.completed => 'مغلق',
      };
    }
    return switch (this) {
      BookingStatus.pendingHotelApproval => 'Pending hotel approval',
      BookingStatus.confirmed => 'Confirmed',
      BookingStatus.rejected => 'Rejected',
      BookingStatus.cancelledByUser => 'Cancelled',
      BookingStatus.completed => 'Closed',
    };
  }
}

class PendingBookingIntent {
  const PendingBookingIntent({
    required this.hotelId,
    required this.roomId,
    required this.criteria,
  });

  final String hotelId;
  final String roomId;
  final SearchCriteria criteria;
}

class BookingDraft {
  const BookingDraft({
    this.hotel,
    this.room,
    this.criteria,
    this.guestName = '',
    this.phone = '',
    this.email = '',
    this.notes,
  });

  final Hotel? hotel;
  final Room? room;
  final SearchCriteria? criteria;
  final String guestName;
  final String phone;
  final String email;
  final String? notes;

  double get total => (room?.price ?? 0) * (criteria?.nights ?? 1);

  BookingDraft copyWith({
    Hotel? hotel,
    Room? room,
    SearchCriteria? criteria,
    String? guestName,
    String? phone,
    String? email,
    String? notes,
  }) {
    return BookingDraft(
      hotel: hotel ?? this.hotel,
      room: room ?? this.room,
      criteria: criteria ?? this.criteria,
      guestName: guestName ?? this.guestName,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      notes: notes ?? this.notes,
    );
  }
}

class BookingRecord {
  const BookingRecord(
      {required this.reference,
      required this.userId,
      required this.draft,
      required this.createdAt,
      required this.status,
      required this.qrVerificationToken,
      this.hotelDecisionAt,
      this.cancelledAt,
      this.completedAt,
      this.cancellationReason,
      this.rejectionReason});
  final String reference;
  final String userId;
  final BookingDraft draft;
  final DateTime createdAt;
  final BookingStatus status;
  final String qrVerificationToken;
  final DateTime? hotelDecisionAt;
  final DateTime? cancelledAt;
  final DateTime? completedAt;
  final String? cancellationReason;
  final String? rejectionReason;

  BookingRecord copyWith({
    BookingStatus? status,
    DateTime? hotelDecisionAt,
    DateTime? cancelledAt,
    DateTime? completedAt,
    String? cancellationReason,
    String? rejectionReason,
  }) {
    return BookingRecord(
      reference: reference,
      userId: userId,
      draft: draft,
      createdAt: createdAt,
      status: status ?? this.status,
      qrVerificationToken: qrVerificationToken,
      hotelDecisionAt: hotelDecisionAt ?? this.hotelDecisionAt,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      completedAt: completedAt ?? this.completedAt,
      cancellationReason: cancellationReason ?? this.cancellationReason,
      rejectionReason: rejectionReason ?? this.rejectionReason,
    );
  }
}

bool isAllowedBookingTransition(BookingStatus from, BookingStatus to) {
  return switch ((from, to)) {
    (BookingStatus.pendingHotelApproval, BookingStatus.confirmed) ||
    (BookingStatus.pendingHotelApproval, BookingStatus.rejected) ||
    (BookingStatus.pendingHotelApproval, BookingStatus.cancelledByUser) ||
    (BookingStatus.confirmed, BookingStatus.completed) =>
      true,
    _ => false,
  };
}

class Destination {
  const Destination(
      {required this.nameAr,
      required this.nameEn,
      required this.governorateAr,
      required this.governorateEn,
      required this.descriptionAr,
      required this.descriptionEn});
  final String nameAr;
  final String nameEn;
  final String governorateAr;
  final String governorateEn;
  final String descriptionAr;
  final String descriptionEn;
}
