# PROJECT_PROGRESS.md - Hajozati

## Quality Gate Status
`PARTIAL - OTP and booking guest-data changes implemented; full tests include one legacy expectation that conflicts with the new phone-only prefill rule`

## Current Phase
`Booking Lifecycle`

## Automated Checks
- `dart format .` - COMPLETE: no files changed in the final run.
- `flutter analyze` - COMPLETE: No issues found.
- `flutter test` - COMPLETE: 34 tests passed.
- `flutter devices` - COMPLETE: Windows, Chrome, and Edge available.
- `flutter emulators` - COMPLETE: no Android emulator available.
- `flutter run -d chrome` - NOT VERIFIED: current attempt remained at `Waiting for connection from debug service`.

## Reviewed Features
- Authentication - COMPLETE by automated tests; persisted-session and auth guard logic reviewed.
- Guest mode and booking gate - COMPLETE by automated tests; guest booking opens Login Required.
- Search criteria and hotel/room navigation - PARTIAL; state path reviewed and automated domain coverage exists, but full manual flow is not verified.
- Room recommendations - COMPLETE by automated tests for adult capacity, children tie-break, and price tie-break.
- Booking details and summary - PARTIAL; state and editable fields are covered, full end-to-end manual acceptance is not verified.
- Registration OTP - COMPLETE in mock architecture: Iraqi phone normalization, duplicate protection, WhatsApp provider contract, resend, verification state, and verified-only account creation.
- Booking guest details - COMPLETE for requested behavior: main guest only, phone-only account prefill, editable draft phone, optional notes through summary and request.
- Booking Lifecycle - COMPLETE by automated tests: request, pending, confirmed, rejected, cancelled, and completed transitions.
- Waiting Screen - COMPLETE by widget tests: pending status, loading indicator, cancellation, decision messages, and Home navigation.
- Cancellation - COMPLETE: optional reason is stored and cancelled requests remain in My Bookings.
- Hotel accept/reject logic - COMPLETE in repository/state methods; Hotel UI is NOT VERIFIED and was not added.
- QR display rules - COMPLETE by tests: QR is hidden until confirmed and uses a private booking token.
- QR verification - COMPLETE in repository/state methods and tests; scanner UI is NOT VERIFIED and was not added.
- My Bookings - COMPLETE by automated tests; statuses are shown and bookings are scoped to the authenticated user.
- Riverpod lifecycle safety - COMPLETE for reviewed screens; removed unnecessary Booking Details provider mutation from `initState`.
- Cancellation/language regression - COMPLETE by widget test; cancellation removes Waiting route, preserves auth and cancelled booking, and repeated locale switches produce no exception.
- Responsive/RTL/English/manual visual checks - NOT VERIFIED because Chrome debug startup did not attach.

## Fixes Applied During Booking Lifecycle
- Booking Summary now creates one `pendingHotelApproval` request instead of a confirmed booking.
- Added centralized status labels and legal transition rules.
- Added Waiting Screen with optional cancellation and decision reactions.
- Added repository operations for hotel accept/reject and QR verification.
- QR renders only for confirmed bookings and uses `qrVerificationToken`.
- Scoped Booking Confirmation and My Bookings to the current authenticated user.
- Prevented cross-user booking deduplication and made references unique for rapid requests.
- Removed unnecessary provider mutation from `BookingDetails.initState`.

## Cancellation Crash Investigation
- Root cause: the app-level GoRouter and auth refresh notifier were global and reused across `HajozatiApp`/ProviderScope lifecycles; every AppState mutation also refreshed the router during route disposal.
- Fix: GoRouter and its refresh notifier are owned by `_HajozatiAppState`, created once in `initState`, disposed with the app, and refreshed only when `AuthStatus` changes.
- Cancellation has one navigation path after dialog completion: update status, then `context.go('/')`.
- No Waiting Screen listener, timer, animation controller, or post-frame callback performs navigation.
- No complete Flutter red-screen stack trace was produced: Chrome debug startup did not attach, and the regression test no longer throws. Therefore no first project-owned stack-trace file could be reported from a real runtime crash.

## Remaining
- Manual Chrome/RTL/English/responsive acceptance remains NOT VERIFIED.
- Android acceptance remains NOT VERIFIED because no emulator/device is available.

## Update Log
- Booking Lifecycle: automated lifecycle checks passed; manual browser and Hotel/Scanner UI remain NOT VERIFIED.
- OTP and booking details: mock OTP flow, phone verification state, main guest notes, and phone-only prefill implemented; quality gate rerun after implementation.
