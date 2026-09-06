import 'models.dart';

class RecommendedRoom {
  const RecommendedRoom({required this.room, required this.adultDifference});

  final Room room;
  final int adultDifference;

  bool get exactAdultMatch => adultDifference == 0;
  bool get oneAdultAbove => adultDifference == 1;

  String? label(bool isArabic) {
    if (exactAdultMatch) return isArabic ? 'أنسب اختيار' : 'Best match';
    if (oneAdultAbove) return isArabic ? 'موصى بها' : 'Recommended';
    if (adultDifference > 1) {
      return isArabic ? 'تتسع لعدد أكبر' : 'Fits more guests';
    }
    return null;
  }

  String? childrenNote(SearchCriteria criteria, bool isArabic) {
    final maxChildren = room.maxChildren;
    if (criteria.children == 0 ||
        maxChildren == null ||
        maxChildren >= criteria.children) {
      return null;
    }
    return isArabic
        ? 'يرجى مراجعة سياسة الفندق للأطفال'
        : 'Please review the hotel\'s child policy';
  }
}

List<RecommendedRoom> recommendRooms(
    Iterable<Room> rooms, SearchCriteria criteria) {
  final recommendations = rooms
      .where((room) => room.maxAdults >= criteria.adults)
      .map((room) => RecommendedRoom(
          room: room, adultDifference: room.maxAdults - criteria.adults))
      .toList();

  recommendations.sort((a, b) {
    final adultDifference = a.adultDifference.compareTo(b.adultDifference);
    if (adultDifference != 0) return adultDifference;

    final aMaxChildren = a.room.maxChildren;
    final bMaxChildren = b.room.maxChildren;
    if (aMaxChildren != null && bMaxChildren != null) {
      final aFitsChildren = aMaxChildren >= criteria.children;
      final bFitsChildren = bMaxChildren >= criteria.children;
      if (aFitsChildren != bFitsChildren) {
        return aFitsChildren ? -1 : 1;
      }
      final childCapacity = bMaxChildren.compareTo(aMaxChildren);
      if (childCapacity != 0) return childCapacity;
    }

    final price = a.room.price.compareTo(b.room.price);
    if (price != 0) return price;
    return a.room.nameEn.compareTo(b.room.nameEn);
  });

  return recommendations;
}
