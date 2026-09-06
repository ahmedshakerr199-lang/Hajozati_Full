import 'models.dart';

class BookingRepository {
  BookingRecord acceptBookingByHotel(BookingRecord booking) {
    _assertTransition(booking, BookingStatus.confirmed);
    return booking.copyWith(
      status: BookingStatus.confirmed,
      hotelDecisionAt: DateTime.now(),
    );
  }

  BookingRecord rejectBookingByHotel(BookingRecord booking, {String? reason}) {
    _assertTransition(booking, BookingStatus.rejected);
    return booking.copyWith(
      status: BookingStatus.rejected,
      hotelDecisionAt: DateTime.now(),
      rejectionReason: reason,
    );
  }

  BookingRecord cancelBookingByUser(BookingRecord booking, {String? reason}) {
    _assertTransition(booking, BookingStatus.cancelledByUser);
    return booking.copyWith(
      status: BookingStatus.cancelledByUser,
      cancelledAt: DateTime.now(),
      cancellationReason: reason,
    );
  }

  BookingRecord verifyBookingQr(
      BookingRecord booking, String verificationToken) {
    if (booking.status != BookingStatus.confirmed ||
        booking.qrVerificationToken != verificationToken) {
      throw StateError('Invalid booking QR');
    }
    _assertTransition(booking, BookingStatus.completed);
    return booking.copyWith(
      status: BookingStatus.completed,
      completedAt: DateTime.now(),
    );
  }

  void _assertTransition(BookingRecord booking, BookingStatus nextStatus) {
    if (!isAllowedBookingTransition(booking.status, nextStatus)) {
      throw StateError(
          'Invalid booking transition: ${booking.status} -> $nextStatus');
    }
  }
}
