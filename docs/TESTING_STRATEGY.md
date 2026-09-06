# TESTING_STRATEGY.md — حجوزاتي (Hajozati)

## مبدأ عام
كل Feature يجب أن يمتلك اختبارات على الأقل في الطبقتين Domain وPresentation قبل اعتباره مكتملًا (وفق Definition of Done في DEVELOPMENT_ROADMAP.md). بنية `test/` تعكس بنية `lib/features/` تمامًا.

## Unit Tests
- **الهدف**: التحقق من منطق العمل الصافي بمعزل عن Flutter وواجهات المستخدم.
- **النطاق**: Use Cases، Validators، Formatters، منطق حساب السعر (BookingPrice)، منطق تصنيف الحجوزات (Upcoming/Completed/Cancelled).
- **أدوات**: `flutter_test` أو `test` package + Mocks للـ Repositories (عبر `mocktail` أو ما يعادلها).

## Widget Tests
- **الهدف**: التحقق من أن الشاشات تعرض الحالة الصحيحة وتستجيب للتفاعل فعليًا.
- **النطاق**: Search Card، Search Results (Loading/Empty/Error/Data)، Hotel Details، Room Selection، نموذج بيانات الحجز، شاشة QR، My Bookings tabs.
- **قاعدة**: كل Widget Test يجب أن يتحقق من نتيجة تفاعل حقيقي (ضغط زر → تغيّر حالة/تنقل)، وليس فقط أن العنصر "مرسوم" على الشاشة — التزامًا بـ NO FAKE INTERACTIONS POLICY.

## Integration Tests
- **الهدف**: التحقق من تدفقات كاملة تمرّ بعدة شاشات وطبقات معًا.
- **النطاق**: تدفق الحجز الكامل من البحث حتى QR، تدفق تسجيل الدخول، تدفق Nearby Hotels بحالات الصلاحية المختلفة.
- **يُفعَّل بشكل موسّع بعد Phase 19** عند وجود Backend حقيقي، لكن يبدأ جزئيًا (ضد Mock) من Phase 10–11.

## Repository Tests
- **الهدف**: التأكد أن تنفيذ الـ Repository يحوّل بيانات الـ Data Source (Mock أو API) إلى Entities صحيحة، ويتعامل مع الأخطاء بشكل صحيح (يُعيد Failure مناسب).
- **النطاق**: كل Repository في كل Feature (Search, Hotel, Room, Booking, Favorites, Nearby, Explore, Profile).

## Use Case Tests
- **الهدف**: كل Use Case يُختبر بمعزل تام عبر Repository وهمي (Mock)، للتحقق من المنطق فقط (مثل: `ConfirmBookingUseCase` يرفض الحجز إذا كانت الغرفة غير متاحة).

## State Tests
- **الهدف**: التحقق من أن الـ Providers/State (خصوصًا `bookingDraftProvider`) تُحدَّث بشكل صحيح عبر سلسلة الشاشات ولا تفقد البيانات، وأن حالات Loading/Data/Error تنتقل بشكل صحيح.

## Navigation Tests
- **الهدف**: التأكد أن كل Route يستقبل المعاملات الصحيحة (مثل `hotelId`, `SearchCriteria`) وأن Route Guards تعمل (مثل منع الوصول لـ `/booking-details` بدون `BookingDraft` صالح، أو لـ `/profile` بدون تسجيل دخول).

## Booking Flow Tests
- **الهدف**: تغطية خاصة ومشدّدة لتدفق الحجز الكامل كونه القلب التجاري للتطبيق: من اختيار الغرفة → بيانات النزيل → المراجعة → التأكيد → توليد الرقم والـ QR → ظهوره في My Bookings.
- يشمل حالات الفشل: بيانات نزيل غير صالحة، الغرفة أصبحت غير متاحة أثناء المراجعة، فشل الشبكة عند التأكيد.

## Search Tests
- **الهدف**: التحقق من أن معايير البحث (SearchCriteria) تُترجم بشكل صحيح إلى نتائج، وأن الفلاتر المستقبلية (عند إضافتها) لا تكسر النتائج الأساسية.

## Validation Tests
- **الهدف**: تغطية شاملة لكل قواعد التحقق (تواريخ الوصول/المغادرة، عدد الضيوف الأدنى، صحة بيانات النزيل: اسم، هاتف).

## Localization Tests
- **الهدف**: التأكد من عدم وجود مفاتيح ترجمة ناقصة بين `app_ar.arb` و`app_en.arb`، والتحقق البصري (يدويًا ضمن Final QA) من سلامة RTL في كل شاشة جديدة.

## Quality Gate الإلزامي بعد كل Phase
```
dart format .
flutter analyze
flutter test
```
لا تُقبل Phase مكتملة ما لم تنجح الأوامر الثلاثة بدون أخطاء.
