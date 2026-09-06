import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/mock_data.dart';
import '../core/models.dart';
import '../core/auth_repository.dart';
import '../core/booking_repository.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

final currentUserProvider = Provider<UserProfile>((ref) => const UserProfile(
      fullName: 'Ahmed Ali',
      phone: '07701234567',
      email: 'ahmed@example.com',
    ));

final mockAuthRepositoryProvider = Provider<MockAuthRepository>(
  (ref) => MockAuthRepository(),
);

final otpProvider = Provider<WhatsAppOtpProvider>(
  (ref) => ref.read(mockAuthRepositoryProvider).otpProvider,
);

final bookingRepositoryProvider = Provider<BookingRepository>(
  (ref) => BookingRepository(),
);

class AuthSessionRepository {
  static const _nameKey = 'auth.name';
  static const _phoneKey = 'auth.phone';
  static const _emailKey = 'auth.email';
  static const _idKey = 'auth.id';
  static const _governorateKey = 'auth.governorateId';
  static const _birthDateKey = 'auth.dateOfBirth';

  Future<UserProfile?> read() async {
    final preferences = await SharedPreferences.getInstance();
    final email = preferences.getString(_emailKey);
    if (email == null || email.isEmpty) return null;
    return UserProfile(
      id: preferences.getString(_idKey) ?? '',
      fullName: preferences.getString(_nameKey) ?? '',
      phone: preferences.getString(_phoneKey) ?? '',
      phoneVerified: preferences.getBool('auth.phoneVerified') ?? false,
      email: email,
      governorateId: preferences.getString(_governorateKey) ?? '',
      dateOfBirth: preferences.getString(_birthDateKey) == null
          ? null
          : DateTime.tryParse(preferences.getString(_birthDateKey)!),
    );
  }

  Future<void> write(UserProfile user) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_nameKey, user.fullName);
    await preferences.setString(_phoneKey, user.phone);
    await preferences.setBool('auth.phoneVerified', user.phoneVerified);
    await preferences.setString(_emailKey, user.email);
    await preferences.setString(_idKey, user.id);
    await preferences.setString(_governorateKey, user.governorateId);
    if (user.dateOfBirth != null) {
      await preferences.setString(
          _birthDateKey, user.dateOfBirth!.toIso8601String());
    }
  }

  Future<void> clear() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_nameKey);
    await preferences.remove(_phoneKey);
    await preferences.remove('auth.phoneVerified');
    await preferences.remove(_emailKey);
    await preferences.remove(_idKey);
    await preferences.remove(_governorateKey);
    await preferences.remove(_birthDateKey);
  }
}

final authSessionRepositoryProvider = Provider<AuthSessionRepository>(
  (ref) => AuthSessionRepository(),
);

class AppState {
  const AppState({
    this.isArabic = true,
    this.authStatus = AuthStatus.unauthenticated,
    this.authEntryCompleted = false,
    this.currentUser,
    this.pendingBookingIntent,
    this.draft = const BookingDraft(),
    this.bookings = const [],
    this.favoriteIds = const {},
  });

  final bool isArabic;
  final AuthStatus authStatus;
  final bool authEntryCompleted;
  final UserProfile? currentUser;
  final PendingBookingIntent? pendingBookingIntent;
  final BookingDraft draft;
  final List<BookingRecord> bookings;
  final Set<String> favoriteIds;

  bool get isAuthenticated => authStatus == AuthStatus.authenticated;

  AppState copyWith(
      {bool? isArabic,
      AuthStatus? authStatus,
      bool? authEntryCompleted,
      UserProfile? currentUser,
      PendingBookingIntent? pendingBookingIntent,
      bool clearCurrentUser = false,
      bool clearPendingBookingIntent = false,
      BookingDraft? draft,
      List<BookingRecord>? bookings,
      Set<String>? favoriteIds}) {
    return AppState(
      isArabic: isArabic ?? this.isArabic,
      authStatus: authStatus ?? this.authStatus,
      authEntryCompleted: authEntryCompleted ?? this.authEntryCompleted,
      currentUser: clearCurrentUser ? null : currentUser ?? this.currentUser,
      pendingBookingIntent: clearPendingBookingIntent
          ? null
          : pendingBookingIntent ?? this.pendingBookingIntent,
      draft: draft ?? this.draft,
      bookings: bookings ?? this.bookings,
      favoriteIds: favoriteIds ?? this.favoriteIds,
    );
  }
}

class AppController extends Notifier<AppState> {
  int _bookingSequence = 0;

  @override
  AppState build() => const AppState();

  void toggleLanguage() => state = state.copyWith(isArabic: !state.isArabic);

  bool get isAuthenticated => state.authStatus == AuthStatus.authenticated;

  void continueAsGuest() => state = state.copyWith(
      authStatus: AuthStatus.guest,
      authEntryCompleted: true,
      clearCurrentUser: true,
      clearPendingBookingIntent: true);

  void signIn({required UserProfile user}) => state = state.copyWith(
      authStatus: AuthStatus.authenticated,
      authEntryCompleted: true,
      currentUser: user);

  void signOut() => state = state.copyWith(
      authStatus: AuthStatus.unauthenticated,
      authEntryCompleted: false,
      clearCurrentUser: true,
      clearPendingBookingIntent: true,
      draft: const BookingDraft());

  void savePendingBookingIntent(Room room) {
    final criteria = state.draft.criteria;
    final hotel = state.draft.hotel;
    if (criteria == null || hotel == null) return;
    state = state.copyWith(
      pendingBookingIntent: PendingBookingIntent(
          hotelId: hotel.id, roomId: room.id, criteria: criteria),
    );
  }

  void resumePendingBooking() {
    final intent = state.pendingBookingIntent;
    if (intent == null) return;
    final hotel = hotelById(intent.hotelId);
    final room = hotel.rooms.firstWhere((item) => item.id == intent.roomId);
    state = state.copyWith(
      draft: BookingDraft(criteria: intent.criteria, hotel: hotel, room: room),
      clearPendingBookingIntent: true,
    );
  }

  void startSearch(SearchCriteria criteria) {
    state = state.copyWith(draft: BookingDraft(criteria: criteria));
  }

  void selectHotel(Hotel hotel) {
    state = state.copyWith(draft: state.draft.copyWith(hotel: hotel));
  }

  void selectRoom(Room room) {
    state = state.copyWith(draft: state.draft.copyWith(room: room));
  }

  void clearBookingDraft() {
    state = state.copyWith(draft: const BookingDraft());
  }

  void setGuest(
      {required String name,
      required String phone,
      required String email,
      String? notes}) {
    state = state.copyWith(
        draft: state.draft.copyWith(
            guestName: name, phone: phone, email: email, notes: notes));
  }

  void prefillGuestFromUser(UserProfile user) {
    final draft = state.draft;
    final phone = draft.phone.isEmpty ? user.phone : draft.phone;
    if (phone == draft.phone) {
      return;
    }
    setGuest(
        name: draft.guestName,
        phone: phone,
        email: draft.email,
        notes: draft.notes);
  }

  BookingRecord createBookingRequest() {
    if (!isAuthenticated || state.currentUser == null) {
      throw StateError('Only authenticated users can send booking requests');
    }
    final previous = state.bookings.where((booking) {
      final activeRequest =
          booking.status == BookingStatus.pendingHotelApproval ||
              booking.status == BookingStatus.confirmed;
      return activeRequest &&
          booking.userId == state.currentUser!.email &&
          identical(booking.draft, state.draft);
    }).firstOrNull;
    if (previous != null) {
      return previous;
    }

    final reference =
        'HJZ-${DateTime.now().microsecondsSinceEpoch}-${++_bookingSequence}';
    final record = BookingRecord(
        reference: reference,
        userId: state.currentUser!.email,
        draft: state.draft,
        createdAt: DateTime.now(),
        status: BookingStatus.pendingHotelApproval,
        qrVerificationToken:
            '$reference-${DateTime.now().microsecondsSinceEpoch}');
    state = state.copyWith(bookings: [record, ...state.bookings]);
    return record;
  }

  BookingRecord bookingById(String bookingId) => state.bookings.firstWhere(
        (booking) => booking.reference == bookingId,
        orElse: () => throw StateError('Booking not found'),
      );

  BookingRecord acceptBookingByHotel(String bookingId) {
    return _replaceBooking(ref
        .read(bookingRepositoryProvider)
        .acceptBookingByHotel(bookingById(bookingId)));
  }

  BookingRecord rejectBookingByHotel(String bookingId, {String? reason}) {
    return _replaceBooking(ref
        .read(bookingRepositoryProvider)
        .rejectBookingByHotel(bookingById(bookingId), reason: reason));
  }

  BookingRecord cancelBookingByUser(String bookingId, {String? reason}) {
    return _replaceBooking(ref
        .read(bookingRepositoryProvider)
        .cancelBookingByUser(bookingById(bookingId), reason: reason));
  }

  BookingRecord verifyBookingQr(String bookingId, String verificationToken) {
    return _replaceBooking(ref
        .read(bookingRepositoryProvider)
        .verifyBookingQr(bookingById(bookingId), verificationToken));
  }

  BookingRecord _replaceBooking(BookingRecord replacement) {
    final next = [...state.bookings];
    final index = next
        .indexWhere((booking) => booking.reference == replacement.reference);
    if (index < 0) throw StateError('Booking not found');
    next[index] = replacement;
    state = state.copyWith(bookings: next);
    return replacement;
  }

  void toggleFavorite(String hotelId) {
    final next = {...state.favoriteIds};
    next.contains(hotelId) ? next.remove(hotelId) : next.add(hotelId);
    state = state.copyWith(favoriteIds: next);
  }

  Hotel hotelById(String id) => hotels.firstWhere((h) => h.id == id);

  Future<void> restorePersistedSession() async {
    final user = await ref.read(authSessionRepositoryProvider).read();
    if (user == null ||
        state.authEntryCompleted ||
        state.authStatus == AuthStatus.authenticated) {
      return;
    }
    state = state.copyWith(
        authStatus: AuthStatus.authenticated,
        authEntryCompleted: true,
        currentUser: user);
  }

  Future<String?> loginByPhone(String phone) async {
    try {
      final user = await ref.read(mockAuthRepositoryProvider).login(phone);
      signInAndPersist(user: user);
      return null;
    } on AuthException catch (error) {
      return error.message;
    }
  }

  Future<String?> registerUser({
    required String fullName,
    required String phone,
    required String governorateId,
    required DateTime dateOfBirth,
    String email = '',
    bool phoneVerified = true,
  }) async {
    try {
      final user = await ref.read(mockAuthRepositoryProvider).register(
            fullName: fullName,
            phone: phone,
            governorateId: governorateId,
            dateOfBirth: dateOfBirth,
            email: email,
            phoneVerified: phoneVerified,
          );
      signInAndPersist(user: user);
      return null;
    } on AuthException catch (error) {
      return error.message;
    }
  }

  void signInAndPersist({required UserProfile user}) {
    signIn(user: user);
    unawaited(ref.read(authSessionRepositoryProvider).write(user));
  }

  void signOutAndClearSession() {
    signOut();
    unawaited(ref.read(authSessionRepositoryProvider).clear());
  }
}

final appControllerProvider =
    NotifierProvider<AppController, AppState>(AppController.new);
