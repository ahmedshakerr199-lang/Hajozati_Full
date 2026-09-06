import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:hajozati/app/app.dart';
import 'package:hajozati/app/state.dart';
import 'package:hajozati/core/mock_data.dart';
import 'package:hajozati/core/models.dart';
import 'package:hajozati/core/room_recommendation.dart';
import 'package:hajozati/core/auth_repository.dart';
import 'package:hajozati/features/screens.dart';

void main() {
  testWidgets('Auth entry loads first', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: HajozatiApp()));
    await tester.pumpAndSettle();
    expect(find.text('حجوزاتي'), findsOneWidget);
    expect(find.text('الدخول كضيف'), findsOneWidget);
  });

  testWidgets('sign in back returns to auth entry without changing auth state',
      (tester) async {
    final container = ProviderContainer(overrides: [
      authSessionRepositoryProvider.overrideWithValue(_MemorySession())
    ]);
    addTearDown(container.dispose);

    await tester.pumpWidget(UncontrolledProviderScope(
        container: container, child: const HajozatiApp()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('تسجيل الدخول').first);
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    expect(find.text('الدخول كضيف'), findsOneWidget);
    expect(container.read(appControllerProvider).authStatus,
        AuthStatus.unauthenticated);
    expect(find.text('استكشف'), findsNothing);
  });

  testWidgets('create account back stays in authentication flow',
      (tester) async {
    final container = ProviderContainer(overrides: [
      authSessionRepositoryProvider.overrideWithValue(_MemorySession())
    ]);
    addTearDown(container.dispose);

    await tester.pumpWidget(UncontrolledProviderScope(
        container: container, child: const HajozatiApp()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('إنشاء حساب جديد'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    expect(find.text('الدخول كضيف'), findsOneWidget);
    expect(container.read(appControllerProvider).authStatus,
        AuthStatus.unauthenticated);
  });

  testWidgets('continue as guest is the only auth entry action to enter home',
      (tester) async {
    final container = ProviderContainer(overrides: [
      authSessionRepositoryProvider.overrideWithValue(_MemorySession())
    ]);
    addTearDown(container.dispose);

    await tester.pumpWidget(UncontrolledProviderScope(
        container: container, child: const HajozatiApp()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('الدخول كضيف'));
    await tester.pumpAndSettle();

    expect(container.read(appControllerProvider).authStatus, AuthStatus.guest);
    expect(find.text('استكشف'), findsOneWidget);
  });

  testWidgets('cancellation followed by language changes leaves no stale route',
      (tester) async {
    final container = ProviderContainer(overrides: [
      authSessionRepositoryProvider.overrideWithValue(_MemorySession())
    ]);
    addTearDown(container.dispose);
    final controller = container.read(appControllerProvider.notifier);
    controller.signIn(user: container.read(currentUserProvider));
    _prepareBooking(controller);
    final booking = controller.createBookingRequest();

    await tester.pumpWidget(UncontrolledProviderScope(
        container: container, child: const HajozatiApp()));
    await _pumpFrames(tester);
    await tester.tap(find.text('حجوزاتي').first);
    await _pumpFrames(tester);
    await tester.tap(find.textContaining(booking.reference));
    await _pumpFrames(tester);
    await tester.tap(find.text('إلغاء طلب الحجز'));
    await tester.pump();
    await tester.tap(find.text('إلغاء الطلب').last);
    await _pumpFrames(tester);

    expect(tester.takeException(), isNull);
    expect(find.text('استكشف'), findsOneWidget);
    expect(container.read(appControllerProvider).bookings.single.status,
        BookingStatus.cancelledByUser);

    await tester.tap(find.text('EN'));
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.text('Explore'), findsOneWidget);
    expect(
        tester
            .widget<Directionality>(find.byType(Directionality).last)
            .textDirection,
        TextDirection.ltr);

    await tester.tap(find.text('عربي'));
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.text('استكشف'), findsOneWidget);
    expect(
        tester
            .widget<Directionality>(find.byType(Directionality).last)
            .textDirection,
        TextDirection.rtl);

    await tester.tap(find.text('EN'));
    await tester.pump();
    await tester.tap(find.text('عربي'));
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(container.read(appControllerProvider).authStatus,
        AuthStatus.authenticated);
    expect(container.read(appControllerProvider).bookings.single.status,
        BookingStatus.cancelledByUser);
  });

  testWidgets('selected governorate survives language changes', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(appControllerProvider.notifier).continueAsGuest();

    await tester.pumpWidget(UncontrolledProviderScope(
        container: container, child: const MaterialApp(home: HomeScreen())));
    await tester.pump();
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pump();
    await tester.tap(find.text('البصرة').last);
    await tester.pump();
    await tester.tap(find.text('EN'));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('Basra'), findsOneWidget);
    expect(find.text('Explore'), findsOneWidget);

    await tester.tap(find.text('عربي'));
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.text('البصرة'), findsOneWidget);
  });

  test('guest choice is not overridden by persisted session restoration',
      () async {
    const user = UserProfile(
      fullName: 'Ahmed Ali',
      phone: '07701234567',
      email: 'ahmed@example.com',
    );
    final container = ProviderContainer(overrides: [
      authSessionRepositoryProvider.overrideWithValue(_SessionWithUser(user)),
    ]);
    addTearDown(container.dispose);
    final controller = container.read(appControllerProvider.notifier);

    final restoration = controller.restorePersistedSession();
    controller.continueAsGuest();
    await restoration;

    expect(container.read(appControllerProvider).authStatus, AuthStatus.guest);
    expect(container.read(appControllerProvider).currentUser, isNull);
  });

  test('confirming a booking twice keeps one booking', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final controller = container.read(appControllerProvider.notifier);
    controller.signIn(user: container.read(currentUserProvider));
    final checkIn = DateTime(2026, 9, 10);
    final hotel = hotels.first;
    controller.startSearch(SearchCriteria(
      governorate: hotel.governorateAr,
      checkIn: checkIn,
      checkOut: checkIn.add(const Duration(days: 2)),
      adults: 2,
      children: 0,
    ));
    controller.selectHotel(hotel);
    controller.selectRoom(hotel.rooms.first);
    controller.setGuest(
        name: 'اختبار الحجز', phone: '07701234567', email: 'test@example.com');

    final firstRecord = controller.createBookingRequest();
    final secondRecord = controller.createBookingRequest();

    expect(secondRecord.reference, firstRecord.reference);
    expect(container.read(appControllerProvider).bookings, hasLength(1));
    expect(container.read(appControllerProvider).bookings.first.reference,
        firstRecord.reference);
    expect(firstRecord.userId, container.read(currentUserProvider).email);
  });

  testWidgets('my bookings are isolated per authenticated user',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final controller = container.read(appControllerProvider.notifier);
    const firstUser = UserProfile(
      fullName: 'First User',
      phone: '07701234567',
      email: 'first@example.com',
    );
    const secondUser = UserProfile(
      fullName: 'Second User',
      phone: '07801234567',
      email: 'second@example.com',
    );
    final hotel = hotels.first;
    controller.signIn(user: firstUser);
    controller.startSearch(_criteria(adults: 2, children: 0));
    controller.selectHotel(hotel);
    controller.selectRoom(hotel.rooms.first);
    final firstBooking = controller.createBookingRequest();

    controller.signIn(user: secondUser);
    final secondBooking = controller.createBookingRequest();

    expect(secondBooking.userId, secondUser.email);
    expect(container.read(appControllerProvider).bookings, hasLength(2));
    await tester.pumpWidget(UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: MyBookingsScreen())));
    await tester.pump();

    expect(find.textContaining(secondBooking.reference), findsOneWidget);
    expect(find.textContaining(firstBooking.reference), findsNothing);
  });

  testWidgets('pending booking returns home and keeps submitted request',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final controller = container.read(appControllerProvider.notifier);
    controller.signIn(user: container.read(currentUserProvider));
    final hotel = hotels.first;
    final checkIn = DateTime(2026, 9, 10);
    controller.startSearch(SearchCriteria(
      governorate: hotel.governorateAr,
      checkIn: checkIn,
      checkOut: checkIn.add(const Duration(days: 2)),
      adults: 2,
      children: 0,
    ));
    controller.selectHotel(hotel);
    controller.selectRoom(hotel.rooms.first);
    controller.setGuest(
        name: 'اختبار الحجز', phone: '07701234567', email: 'test@example.com');
    final confirmed = controller.createBookingRequest();
    final router = GoRouter(initialLocation: '/confirmation', routes: [
      GoRoute(path: '/', builder: (_, __) => const HomeScreen()),
      GoRoute(
          path: '/summary', builder: (_, __) => const BookingSummaryScreen()),
      GoRoute(
          path: '/confirmation',
          builder: (_, __) => const BookingConfirmationScreen()),
    ]);

    await tester.pumpWidget(UncontrolledProviderScope(
        container: container, child: MaterialApp.router(routerConfig: router)));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('عرض حجوزاتي'), findsNothing);
    expect(find.text('العودة إلى الرئيسية'), findsOneWidget);
    expect(find.text('بانتظار قبول الطلب'), findsOneWidget);
    expect(find.text('حجوزاتي'), findsNothing);
    await tester.tap(find.text('العودة إلى الرئيسية'));
    await tester.pumpAndSettle();

    expect(find.text('استكشف'), findsOneWidget);
    expect(find.text('ملخص الحجز'), findsNothing);
    expect(container.read(appControllerProvider).draft, const BookingDraft());
    expect(container.read(appControllerProvider).bookings, hasLength(1));
    expect(container.read(appControllerProvider).bookings.single.reference,
        confirmed.reference);
    router.dispose();
  });

  test('booking submission creates one pending request, not a confirmation',
      () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final controller = container.read(appControllerProvider.notifier);
    controller.signIn(user: container.read(currentUserProvider));
    _prepareBooking(controller);

    final first = controller.createBookingRequest();
    final second = controller.createBookingRequest();

    expect(first.status, BookingStatus.pendingHotelApproval);
    expect(first.userId, 'ahmed@example.com');
    expect(first.draft.criteria!.adults, 2);
    expect(first.draft.criteria!.children, 1);
    expect(second.reference, first.reference);
    expect(container.read(appControllerProvider).bookings, hasLength(1));
  });

  testWidgets('waiting screen shows pending status without QR', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final controller = container.read(appControllerProvider.notifier);
    controller.signIn(user: container.read(currentUserProvider));
    _prepareBooking(controller);
    final booking = controller.createBookingRequest();

    await tester.pumpWidget(UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
            home: BookingWaitingScreen(bookingId: booking.reference))));
    await tester.pump();

    expect(find.text('بانتظار قبول الطلب'), findsOneWidget);
    expect(find.text('تم الحجز'), findsNothing);
    expect(find.byType(QrImageView), findsNothing);
    expect(find.text('إلغاء طلب الحجز'), findsOneWidget);
  });

  testWidgets('cancelling pending request without reason returns home',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final controller = container.read(appControllerProvider.notifier);
    controller.signIn(user: container.read(currentUserProvider));
    _prepareBooking(controller);
    final booking = controller.createBookingRequest();
    final router = _waitingTestRouter(booking.reference);
    addTearDown(router.dispose);

    await tester.pumpWidget(UncontrolledProviderScope(
        container: container, child: MaterialApp.router(routerConfig: router)));
    await tester.pump();
    await tester.tap(find.text('إلغاء طلب الحجز').first);
    await tester.pump();
    await tester.tap(find.text('إلغاء الطلب').last);
    await tester.pumpAndSettle();

    expect(find.text('استكشف'), findsOneWidget);
    expect(find.text('حالة الحجز'), findsNothing);
    final cancelled = container.read(appControllerProvider).bookings.single;
    expect(cancelled.status, BookingStatus.cancelledByUser);
    expect(cancelled.cancellationReason, isNull);
    expect(find.textContaining(booking.reference), findsNothing);
  });

  testWidgets('cancelling pending request stores an optional reason',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final controller = container.read(appControllerProvider.notifier);
    controller.signIn(user: container.read(currentUserProvider));
    _prepareBooking(controller);
    final booking = controller.createBookingRequest();
    final router = _waitingTestRouter(booking.reference);
    addTearDown(router.dispose);

    await tester.pumpWidget(UncontrolledProviderScope(
        container: container, child: MaterialApp.router(routerConfig: router)));
    await tester.pump();
    await tester.tap(find.text('إلغاء طلب الحجز').first);
    await tester.pump();
    await tester.enterText(find.byType(TextField), 'Changed plans');
    await tester.tap(find.text('إلغاء الطلب').last);
    await tester.pumpAndSettle();

    expect(find.text('استكشف'), findsOneWidget);
    final cancelled = container.read(appControllerProvider).bookings.single;
    expect(cancelled.status, BookingStatus.cancelledByUser);
    expect(cancelled.cancellationReason, 'Changed plans');
  });

  test('pending request can be cancelled with or without a reason', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final controller = container.read(appControllerProvider.notifier);
    controller.signIn(user: container.read(currentUserProvider));
    _prepareBooking(controller);
    final first = controller.createBookingRequest();
    final cancelled = controller.cancelBookingByUser(first.reference);

    expect(cancelled.status, BookingStatus.cancelledByUser);
    expect(cancelled.cancellationReason, isNull);
    expect(container.read(appControllerProvider).bookings, hasLength(1));

    controller.startSearch(_criteria(adults: 2, children: 0));
    controller.selectHotel(hotels.first);
    controller.selectRoom(hotels.first.rooms.first);
    final second = controller.createBookingRequest();
    final cancelledWithReason = controller.cancelBookingByUser(second.reference,
        reason: 'Changed plans');
    expect(cancelledWithReason.cancellationReason, 'Changed plans');
  });

  testWidgets('pending booking remains visible in My Bookings', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final controller = container.read(appControllerProvider.notifier);
    controller.signIn(user: container.read(currentUserProvider));
    _prepareBooking(controller);
    final booking = controller.createBookingRequest();

    await tester.pumpWidget(UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: MyBookingsScreen())));
    await tester.pump();

    expect(find.textContaining(booking.reference), findsOneWidget);
    expect(find.text('بانتظار قبول الطلب'), findsOneWidget);
  });

  testWidgets('hotel acceptance reveals QR and QR verification completes once',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final controller = container.read(appControllerProvider.notifier);
    controller.signIn(user: container.read(currentUserProvider));
    _prepareBooking(controller);
    final booking = controller.createBookingRequest();
    final confirmed = controller.acceptBookingByHotel(booking.reference);

    expect(confirmed.status, BookingStatus.confirmed);
    expect(confirmed.hotelDecisionAt, isNotNull);
    await tester.pumpWidget(UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
            home: BookingWaitingScreen(bookingId: booking.reference))));
    await tester.pump();
    expect(find.byType(QrImageView), findsOneWidget);
    expect(find.text('تم الحجز'), findsOneWidget);

    final completed = controller.verifyBookingQr(
        booking.reference, confirmed.qrVerificationToken);
    expect(completed.status, BookingStatus.completed);
    expect(completed.completedAt, isNotNull);
    expect(
        () => controller.verifyBookingQr(
            booking.reference, confirmed.qrVerificationToken),
        throwsStateError);
  });

  test(
      'reject, invalid QR, other booking QR, and illegal transitions are blocked',
      () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final controller = container.read(appControllerProvider.notifier);
    controller.signIn(user: container.read(currentUserProvider));
    _prepareBooking(controller);
    final rejected = controller.createBookingRequest();
    final rejectedRecord = controller.rejectBookingByHotel(rejected.reference,
        reason: 'Room unavailable');
    expect(rejectedRecord.status, BookingStatus.rejected);
    expect(rejectedRecord.rejectionReason, 'Room unavailable');
    expect(() => controller.acceptBookingByHotel(rejected.reference),
        throwsStateError);
    expect(
        () => controller.verifyBookingQr(
            rejected.reference, rejected.qrVerificationToken),
        throwsStateError);

    _prepareBooking(controller);
    final first = controller.createBookingRequest();
    _prepareBooking(controller);
    final second = controller.createBookingRequest();
    expect(() => controller.verifyBookingQr(first.reference, 'wrong-token'),
        throwsStateError);
    final confirmed = controller.acceptBookingByHotel(first.reference);
    expect(
        () => controller.verifyBookingQr(
            second.reference, confirmed.qrVerificationToken),
        throwsStateError);
    final completed = controller.verifyBookingQr(
        first.reference, confirmed.qrVerificationToken);
    expect(completed.status, BookingStatus.completed);
    expect(() => controller.cancelBookingByUser(first.reference),
        throwsStateError);
    expect(() => controller.acceptBookingByHotel(first.reference),
        throwsStateError);
  });

  test('guest prefill preserves edited draft values', () {
    const user = UserProfile(
        fullName: 'Ahmed Ali',
        phone: '07701234567',
        email: 'ahmed@example.com');
    final container = ProviderContainer(
        overrides: [currentUserProvider.overrideWithValue(user)]);
    addTearDown(container.dispose);
    final controller = container.read(appControllerProvider.notifier);

    controller.prefillGuestFromUser(user);
    expect(container.read(appControllerProvider).draft.guestName, isEmpty);
    expect(container.read(appControllerProvider).draft.phone, user.phone);
    expect(container.read(appControllerProvider).draft.email, isEmpty);

    controller.setGuest(
        name: 'Ali Ahmed', phone: '07800000000', email: 'ali@example.com');
    controller.prefillGuestFromUser(user);
    final draft = container.read(appControllerProvider).draft;
    expect(draft.guestName, 'Ali Ahmed');
    expect(draft.phone, '07800000000');
    expect(draft.email, 'ali@example.com');
  });

  testWidgets('booking details prefills only editable phone data',
      (tester) async {
    final container = ProviderContainer(overrides: [
      currentUserProvider.overrideWithValue(const UserProfile(
          fullName: 'Ahmed Ali',
          phone: '07701234567',
          email: 'ahmed@example.com')),
    ]);
    addTearDown(container.dispose);

    await tester.pumpWidget(UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: BookingDetailsScreen())));
    await tester.pump();

    final fields = find.byType(TextFormField);
    expect(fields, findsNWidgets(4));
    expect(
        tester.widget<TextFormField>(fields.at(0)).controller!.text, isEmpty);
    expect(tester.widget<TextFormField>(fields.at(1)).controller!.text,
        '07701234567');
    expect(
        tester.widget<TextFormField>(fields.at(2)).controller!.text, isEmpty);
    expect(
        tester.widget<TextFormField>(fields.at(3)).controller!.text, isEmpty);
    await tester.enterText(fields.at(0), 'Ali Ahmed');
    expect(tester.widget<TextFormField>(fields.at(0)).controller!.text,
        'Ali Ahmed');
  });

  test('mock WhatsApp OTP verifies the normalized Iraqi phone', () async {
    final provider = MockWhatsAppOtpProvider();
    await provider.sendRegistrationOtp('+9647701234567');
    expect(await provider.verifyOtp('07701234567', '000000'), isFalse);
    expect(
        await provider.verifyOtp(
            '07701234567', MockWhatsAppOtpProvider.testCode),
        isTrue);
  });

  test('room recommendations prioritize adult capacity', () {
    final criteria = _criteria(adults: 3, children: 0);
    final rooms = [
      _room('two', maxAdults: 2, price: 10),
      _room('five', maxAdults: 5, price: 10),
      _room('three', maxAdults: 3, price: 10),
      _room('four', maxAdults: 4, price: 10),
    ];

    final result = recommendRooms(rooms, criteria);

    expect(result.map((item) => item.room.id), ['three', 'four', 'five']);
  });

  test('children do not reject an adult-capable room', () {
    final criteria = _criteria(adults: 3, children: 2);
    final result = recommendRooms([
      _room('too-small', maxAdults: 2, maxChildren: 5),
      _room('adult-match', maxAdults: 3, maxChildren: 0),
      _room('family', maxAdults: 4, maxChildren: 1),
    ], criteria);

    expect(result.map((item) => item.room.id), ['adult-match', 'family']);
    expect(
        result.first.childrenNote(criteria, false), contains('child policy'));
  });

  test('same adult capacity prefers children fit then lower price', () {
    final criteria = _criteria(adults: 3, children: 2);
    final result = recommendRooms([
      _room('expensive-family', maxAdults: 3, maxChildren: 2, price: 20),
      _room('cheap-no-child', maxAdults: 3, maxChildren: 0, price: 5),
      _room('cheap-family', maxAdults: 3, maxChildren: 2, price: 10),
    ], criteria);

    expect(result.map((item) => item.room.id),
        ['cheap-family', 'expensive-family', 'cheap-no-child']);
  });

  test('guest cannot confirm and resumes the pending room after login', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final controller = container.read(appControllerProvider.notifier);
    final hotel = hotels.first;
    final checkIn = DateTime(2026, 9, 10);
    controller.startSearch(SearchCriteria(
      governorate: hotel.governorateAr,
      checkIn: checkIn,
      checkOut: checkIn.add(const Duration(days: 2)),
      adults: 2,
      children: 1,
    ));
    controller.selectHotel(hotel);
    controller.savePendingBookingIntent(hotel.rooms.first);

    expect(() => controller.createBookingRequest(), throwsStateError);
    expect(container.read(appControllerProvider).pendingBookingIntent!.roomId,
        hotel.rooms.first.id);

    controller.signIn(user: container.read(currentUserProvider));
    controller.resumePendingBooking();
    expect(container.read(appControllerProvider).draft.room!.id,
        hotel.rooms.first.id);
    expect(container.read(appControllerProvider).draft.criteria!.children, 1);
    expect(container.read(appControllerProvider).pendingBookingIntent, isNull);
    expect(controller.createBookingRequest().userId,
        container.read(currentUserProvider).email);
  });

  testWidgets('guest room action shows authentication gate', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final controller = container.read(appControllerProvider.notifier);
    controller.continueAsGuest();
    final hotel = hotels.first;
    final checkIn = DateTime(2026, 9, 10);
    controller.startSearch(SearchCriteria(
      governorate: hotel.governorateAr,
      checkIn: checkIn,
      checkOut: checkIn.add(const Duration(days: 1)),
      adults: 2,
      children: 0,
    ));
    controller.selectHotel(hotel);

    await tester.pumpWidget(UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: RoomSelectionScreen())));
    await tester.pump();
    await tester.tap(find.text('اختيار هذه الغرفة').first);
    await tester.pumpAndSettle();

    expect(find.text('يجب تسجيل الدخول لإتمام الحجز'), findsOneWidget);
    expect(
        container.read(appControllerProvider).pendingBookingIntent, isNotNull);
  });

  test('age validation uses the exact birthday', () {
    final today = DateTime(2026, 9, 5);
    expect(ageAt(DateTime(2014, 9, 5), today), 12);
    expect(isOlderThanTwelve(DateTime(2014, 9, 5), today), isFalse);
    expect(isOlderThanTwelve(DateTime(2013, 9, 6), today), isFalse);
    expect(isOlderThanTwelve(DateTime(2013, 9, 5), today), isTrue);
  });

  test('phone normalization supports Iraqi formats', () {
    expect(normalizePhone('+964 770 123 4567'), '07701234567');
    expect(isValidIraqiPhone('07701234567'), isTrue);
    expect(isValidIraqiPhone('12345'), isFalse);
  });

  test('full name validation accepts Arabic and English names', () {
    expect(hasTripleName('أحمد علي حسن'), isTrue);
    expect(hasTripleName('محمد عبد الله كريم'), isTrue);
    expect(hasTripleName('Ahmed Ali Hassan'), isTrue);
    expect(normalizeFullName('   أحمد    علي    حسن   '), 'أحمد علي حسن');
    expect(hasTripleName('   أحمد    علي    حسن   '), isTrue);
  });

  test('full name validation rejects symbols, digits, short and empty names',
      () {
    for (final value in [
      'أحمد، علي حسن',
      'أحمد, علي حسن',
      'أحمد@علي حسن',
      'أحمد123 علي حسن',
      'Ahmed_Ali Hassan',
      '123 456 789',
    ]) {
      expect(hasTripleName(value), isFalse, reason: value);
    }
    expect(hasTripleName('أحمد علي'), isFalse);
    expect(hasTripleName(''), isFalse);
    expect(fullNameValidationError('أحمد123 علي حسن', isArabic: true),
        'الاسم يجب أن يحتوي على حروف فقط');
    expect(fullNameValidationError('أحمد علي', isArabic: true),
        'يرجى إدخال الاسم الثلاثي');
    expect(
        fullNameValidationError('', isArabic: false), 'Enter your full name');
  });

  test('registration validates and stores a normalized full name', () async {
    final repository = MockAuthRepository();
    final suffix = DateTime.now().millisecondsSinceEpoch % 100000000;
    final user = await repository.register(
      fullName: '   أحمد    علي    حسن   ',
      phone: '079${suffix.toString().padLeft(8, '0')}',
      governorateId: 'baghdad',
      dateOfBirth: DateTime(1990, 1, 1),
    );
    expect(user.fullName, 'أحمد علي حسن');
    await expectLater(
      repository.register(
        fullName: 'أحمد علي',
        phone: '078${suffix.toString().padLeft(8, '0')}',
        governorateId: 'baghdad',
        dateOfBirth: DateTime(1990, 1, 1),
      ),
      throwsA(isA<AuthException>()),
    );
  });

  test('name input formatter removes digits and symbols while typing', () {
    const formatter = NameTextInputFormatter();
    final result = formatter.formatEditUpdate(
      const TextEditingValue(),
      const TextEditingValue(text: 'Ahmed_123 Ali'),
    );
    expect(result.text, 'Ahmed Ali');
  });

  test('registration rejects duplicate phone and accepts a valid user',
      () async {
    final repository = MockAuthRepository();
    final suffix = DateTime.now().millisecondsSinceEpoch % 100000000;
    final testPhone = '079${suffix.toString().padLeft(8, '0')}';
    final duplicate = await repository.register(
      fullName: 'Ahmed Ali Hassan',
      phone: testPhone,
      governorateId: 'baghdad',
      dateOfBirth: DateTime(1990, 1, 1),
    );
    expect(duplicate.phone, testPhone);
    await expectLater(
        repository.register(
          fullName: 'Other User Name',
          phone:
              '+964 ${testPhone.substring(1, 4)} ${testPhone.substring(4, 7)} ${testPhone.substring(7)}',
          governorateId: 'baghdad',
          dateOfBirth: DateTime(1990, 1, 1),
        ),
        throwsA(isA<AuthException>()));
  });

  test('registered user becomes authenticated and logout returns to auth flow',
      () async {
    final container = ProviderContainer(overrides: [
      authSessionRepositoryProvider.overrideWithValue(_MemorySession()),
    ]);
    addTearDown(container.dispose);
    final controller = container.read(appControllerProvider.notifier);
    final suffix = DateTime.now().millisecondsSinceEpoch % 100000000;
    final message = await controller.registerUser(
      fullName: 'Test Registered User',
      phone: '078${suffix.toString().padLeft(8, '0')}',
      governorateId: 'baghdad',
      dateOfBirth: DateTime(1990, 1, 1),
    );

    expect(message, isNull);
    expect(container.read(appControllerProvider).authStatus,
        AuthStatus.authenticated);
    expect(container.read(appControllerProvider).currentUser!.fullName,
        'Test Registered User');
    controller.signOut();
    expect(container.read(appControllerProvider).authStatus,
        AuthStatus.unauthenticated);
    expect(container.read(appControllerProvider).currentUser, isNull);
  });
}

class _MemorySession extends AuthSessionRepository {
  @override
  Future<UserProfile?> read() async => null;

  @override
  Future<void> write(UserProfile user) async {}

  @override
  Future<void> clear() async {}
}

class _SessionWithUser extends AuthSessionRepository {
  _SessionWithUser(this.user);

  final UserProfile user;

  @override
  Future<UserProfile?> read() async => user;
}

void _prepareBooking(AppController controller) {
  final hotel = hotels.first;
  controller.startSearch(_criteria(adults: 2, children: 1));
  controller.selectHotel(hotel);
  controller.selectRoom(hotel.rooms.first);
  controller.setGuest(
      name: 'اختبار الحجز', phone: '07701234567', email: 'test@example.com');
}

GoRouter _waitingTestRouter(String bookingId) {
  return GoRouter(initialLocation: '/waiting', routes: [
    GoRoute(path: '/', builder: (_, __) => const HomeScreen()),
    GoRoute(
        path: '/waiting',
        builder: (_, __) => BookingWaitingScreen(bookingId: bookingId)),
  ]);
}

Future<void> _pumpFrames(WidgetTester tester) async {
  for (var index = 0; index < 10; index++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

SearchCriteria _criteria({required int adults, required int children}) {
  final checkIn = DateTime(2026, 9, 10);
  return SearchCriteria(
    governorate: 'Baghdad',
    checkIn: checkIn,
    checkOut: checkIn.add(const Duration(days: 1)),
    adults: adults,
    children: children,
  );
}

Room _room(String id,
    {required int maxAdults, int? maxChildren, double price = 10}) {
  return Room(
    id: id,
    nameAr: id,
    nameEn: id,
    capacity: maxAdults,
    maxAdults: maxAdults,
    maxChildren: maxChildren,
    bedsAr: 'سرير',
    bedsEn: 'bed',
    price: price,
    available: true,
  );
}
