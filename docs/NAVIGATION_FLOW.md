# NAVIGATION_FLOW.md — حجوزاتي (Hajozati)

مبني على `go_router`. كل مسار له اسم ثابت في `route_names.dart`.

## الخريطة الرئيسية (Core Flow)
```
Splash
  ↓
Login / Language Selection   (اختياري: Guest Mode → Home مباشرة)
  ↓
Home
  ↓ (Search Card → Search)
Search Results
  ↓ (اختيار فندق)
Hotel Details
  ↓ (اختيار غرفة)
Room Selection
  ↓
Booking Details        (بيانات النزيل)
  ↓
Booking Summary         (مراجعة)
  ↓
Booking Confirmation
  ↓
QR Screen
```

## الشاشات الإضافية (Tabs / Secondary)
- My Bookings (حجوزاتي) — تبويب رئيسي، مستقل عن تدفق الحجز، يفتح Booking Details (وضع القراءة) عند اختيار حجز.
- Favorites — تبويب رئيسي، يفتح Hotel Details عند اختيار فندق.
- Nearby Hotels — يُفتح من Home أو Explore، يفتح Hotel Details.
- Explore Iraq — تبويب رئيسي، يفتح Destination Details، ومنها Nearby Hotels الخاصة بالوجهة أو Hotel Details مباشرة.
- Profile — تبويب رئيسي، يفتح Settings، My Bookings، Favorites، Language.
- Settings — يُفتح من Profile.

## Route Table والمعاملات (Parameters)

| Route | يفتح من | المعاملات الممرَّرة |
|---|---|---|
| `/splash` | تشغيل التطبيق | — |
| `/login` | Splash | — |
| `/home` | Login أو Guest Mode | — |
| `/search-results` | Home (Search Card) | `SearchCriteria` (governorateId, checkIn, checkOut, adults, children) |
| `/hotel-details/:hotelId` | Search Results, Favorites, Nearby, Explore | `hotelId`, و`SearchCriteria` (extra) لتمرير التواريخ لعرض الغرف المتاحة |
| `/room-selection/:hotelId` | Hotel Details | `hotelId`, `SearchCriteria` (extra) |
| `/booking-details` | Room Selection | `BookingDraft` (extra، عبر Provider وليس عبر الرابط) |
| `/booking-summary` | Booking Details | يقرأ من `BookingDraft` Provider مباشرة |
| `/booking-confirmation` | Booking Summary | يقرأ من `BookingDraft` Provider، ثم يُنشئ `Booking` نهائي |
| `/booking-qr/:bookingId` | Booking Confirmation | `bookingId` |
| `/my-bookings` | Bottom Nav / Profile | تبويب افتراضي: Upcoming |
| `/booking-detail-view/:bookingId` | My Bookings | `bookingId` (وضع قراءة فقط) |
| `/favorites` | Bottom Nav / Profile | — |
| `/nearby-hotels` | Home / Explore | `governorateId?` (اختياري لتصفية أولية) |
| `/explore-iraq` | Bottom Nav | — |
| `/destination-details/:destinationId` | Explore Iraq | `destinationId` |
| `/profile` | Bottom Nav | — |
| `/settings` | Profile | — |

## ملاحظات معمارية
- **Booking Draft** لا يُمرَّر عبر URL params بل يُحفظ في Provider مركزي (`bookingDraftProvider`) يبقى حيًا طوال تدفق الحجز، ويُفرَّغ فقط بعد التأكيد الناجح أو عند إلغاء التدفق يدويًا. هذا يمنع فقدان بيانات المستخدم عند التنقل بين الشاشات (كما طُلب صراحة).
- **Deep Links**: بنية go_router تدعم إضافة Deep Link لاحقًا (مثل فتح `hajozati://booking/:bookingId` مباشرة من إشعار) دون تعديل هيكلي.
- **Route Guards**: شاشات مثل `/booking-details` وما بعدها تتطلب وجود `BookingDraft` غير فارغ؛ وشاشات مثل `/my-bookings`, `/favorites`, `/profile` تتطلب مستخدمًا مسجلًا (ما لم يُقرَّر لاحقًا السماح بوضع ضيف كامل).
- **Bottom Navigation** الرئيسي يضم: Home, My Bookings, Favorites, Explore Iraq, Profile — باستخدام `StatefulShellRoute` في go_router للحفاظ على حالة كل تبويب.
