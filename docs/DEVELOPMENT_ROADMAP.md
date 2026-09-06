# DEVELOPMENT_ROADMAP.md — حجوزاتي (Hajozati)

> كل Phase تُنفَّذ بشكل منفصل ومتسلسل. لا تبدأ Phase جديدة قبل اكتمال التي تسبقها وفق Definition of Done العام (راجع أسفل الملف) وتحديث PROJECT_PROGRESS.md.

## Phase 00 — Project Setup
- **Goal**: تهيئة مشروع Flutter فارغ نظيف بالبنية المعتمدة في PROJECT_STRUCTURE.md.
- **Tasks**: إنشاء المشروع، إعداد `analysis_options.yaml`، إضافة الحزم الأساسية (riverpod, go_router, intl)، إعداد مجلدات app/core/shared/features فارغة، إعداد Git.
- **Dependencies**: لا يوجد.
- **Acceptance Criteria**: المشروع يعمل ويعرض شاشة فارغة، `flutter analyze` بدون أخطاء.
- **Tests**: لا يوجد اختبارات منطق بعد (Smoke test تشغيل فقط).

## Phase 01 — Foundation
- **Goal**: بناء طبقة core/ الأساسية (error, network skeleton, storage skeleton, utils).
- **Tasks**: `Failure` types، `ApiClient` هيكلي، خدمات تخزين محلي أساسية، أدوات تحقق (validators) وتنسيق تواريخ.
- **Dependencies**: Phase 00.
- **Acceptance Criteria**: الطبقات موجودة وقابلة للاستيراد، بدون منطق Feature بعد.
- **Tests**: Unit tests لـ validators و date utils.

## Phase 02 — Design System
- **Goal**: تنفيذ Design System كاملًا (Colors, Typography, Spacing, Radius, Theme).
- **Tasks**: بناء `app_colors.dart`, `app_typography.dart`, `app_spacing.dart`, `app_theme.dart`، ومكونات UI أساسية مشتركة (Buttons, Inputs, Cards هيكليًا فارغة من المحتوى الحقيقي).
- **Dependencies**: Phase 00.
- **Acceptance Criteria**: تطبيق Theme موحّد على شاشة تجريبية، مطابقة الألوان لما هو محدد في DESIGN_SYSTEM.md.
- **Tests**: Widget tests أساسية للأزرار والحقول.

## Phase 03 — Localization
- **Goal**: تفعيل دعم عربي/إنجليزي كامل مع RTL/LTR.
- **Tasks**: ملفات ARB (ar/en)، `LocaleProvider`، تبديل اللغة، اختبار الاتجاه على شاشة تجريبية.
- **Dependencies**: Phase 00, 02.
- **Acceptance Criteria**: تبديل اللغة يعمل فعليًا ويغيّر الاتجاه بدون إعادة تشغيل التطبيق.
- **Tests**: Localization test للتحقق من عدم وجود مفاتيح ناقصة بين ar/en.

## Phase 04 — Authentication
- **Goal**: تدفق تسجيل الدخول/إنشاء حساب كامل التفاعل (مقابل Mock Data Source).
- **Tasks**: شاشات Login/Register، Use Cases، Repository (Mock)، إدارة حالة الجلسة، Route Guard.
- **Dependencies**: Phase 01, 02, 03.
- **Acceptance Criteria**: تسجيل دخول ناجح ينقل إلى Home، خطأ يعرض رسالة حقيقية، لا Placeholder.
- **Tests**: Unit (Use Cases)، Widget (شاشة تسجيل الدخول)، Repository test.

## Phase 05 — Home
- **Goal**: الصفحة الرئيسية مع Search Card تفاعلية بالكامل.
- **Tasks**: بناء Search Card (محافظة، تواريخ، بالغين/أطفال)، Bottom Nav الرئيسي، ربط زر البحث بالتنقل الفعلي.
- **Dependencies**: Phase 02, 03, 04.
- **Acceptance Criteria**: كل حقل يعمل فعليًا (Picker حقيقي)، زر البحث يُفعَّل فقط عند اكتمال الحقول، يفتح Search Results بمعايير صحيحة.
- **Tests**: Widget + State tests لـ Search Card.

## Phase 06 — Search
- **Goal**: منطق البحث الكامل (SearchCriteria → Use Case → Repository Mock).
- **Tasks**: `SearchHotelsUseCase`، `SearchRepository` (Mock Data Source يحاكي نتائج واقعية)، ربط بحالة Search Results.
- **Dependencies**: Phase 05.
- **Acceptance Criteria**: البحث يعيد نتائج فعلية مطابقة للمعايير، حالة تحميل حقيقية.
- **Tests**: Unit للـ Use Case والـ Repository.

## Phase 07 — Search Results
- **Goal**: شاشة نتائج البحث بحالاتها الكاملة.
- **Tasks**: قائمة Hotel Cards، حالات Loading/Empty/Error/Retry فعلية، فتح تفاصيل الفندق عند الضغط.
- **Dependencies**: Phase 06.
- **Acceptance Criteria**: كل حالة (تحميل/فراغ/خطأ) تظهر فعليًا حسب نتيجة الاستدعاء، لا بيانات وهمية ثابتة على الشاشة.
- **Tests**: Widget tests لكل حالة عرض.

## Phase 08 — Hotel Details
- **Goal**: شاشة تفاصيل الفندق الكاملة.
- **Tasks**: عرض الصور/الوصف/الخدمات/السياسات/الموقع (Placeholder خريطة حتى Phase 17)، قائمة الغرف المتاحة، الانتقال لاختيار غرفة.
- **Dependencies**: Phase 07.
- **Acceptance Criteria**: البيانات تُجلب فعليًا عبر `hotelId`، لا نصوص أو صور ثابتة Hard-coded.
- **Tests**: Widget + Repository tests.

## Phase 09 — Rooms
- **Goal**: منطق وعرض الغرف المتاحة وتفاصيلها.
- **Tasks**: `RoomRepository` (Mock)، شاشة/قسم اختيار الغرفة مع كل الحقول (سعة، سعر، خصم، سياسة إلغاء)، اختيار غرفة يبدأ Booking Draft فعليًا.
- **Dependencies**: Phase 08.
- **Acceptance Criteria**: اختيار غرفة يملأ `BookingDraft` Provider ببيانات صحيحة وينقل لشاشة بيانات الحجز.
- **Tests**: Unit لـ BookingDraft state، Widget لبطاقة الغرفة.

## Phase 10 — Booking Flow
- **Goal**: تدفق الحجز الكامل (بيانات النزيل → مراجعة).
- **Tasks**: شاشة إدخال بيانات النزيل مع Validation فعلي، شاشة مراجعة تعرض كل تفاصيل `BookingDraft` والسعر الإجمالي.
- **Dependencies**: Phase 09.
- **Acceptance Criteria**: البيانات لا تُفقد عند الرجوع بين الشاشات، الـ Validation يمنع المتابعة ببيانات ناقصة/خاطئة فعليًا.
- **Tests**: Unit (Validators)، Widget (نموذج بيانات النزيل)، State test لاستمرارية Booking Draft.

## Phase 11 — Booking Confirmation + QR
- **Goal**: تأكيد الحجز فعليًا وتوليد رقم حجز و QR Code حقيقيين.
- **Tasks**: `ConfirmBookingUseCase`، توليد `Booking Reference` فريد، `QrCodeService`، شاشة تأكيد نهائية، شاشة QR.
- **Dependencies**: Phase 10.
- **Acceptance Criteria**: الضغط على "تأكيد" ينشئ حجزًا فعليًا (حتى لو في مصدر بيانات Mock) برقم و QR حقيقيين قابلين للعرض.
- **Tests**: Unit لتوليد الرقم/QR، Widget لشاشة التأكيد.

## Phase 12 — My Bookings
- **Goal**: صفحة "حجوزاتي" بحالاتها الثلاث فعليًا.
- **Tasks**: جلب حجوزات المستخدم، تصنيفها Upcoming/Completed/Cancelled بمنطق تواريخ حقيقي، فتح تفاصيل أي حجز.
- **Dependencies**: Phase 11.
- **Acceptance Criteria**: الحجز الذي تم تأكيده في Phase 11 يظهر فعليًا ضمن Upcoming.
- **Tests**: Unit لمنطق التصنيف، Widget للتبويبات.

## Phase 13 — Favorites
- **Goal**: تفعيل المفضلة بالكامل.
- **Tasks**: إضافة/إزالة من المفضلة من بطاقة الفندق وشاشة التفاصيل، شاشة عرض المفضلة، تخزين محلي أو عبر Repository.
- **Dependencies**: Phase 08.
- **Acceptance Criteria**: تبديل حالة القلب يُحدَّث فعليًا في القائمة وشاشة المفضلة فورًا.
- **Tests**: Unit + Widget.

## Phase 14 — Nearby Hotels
- **Goal**: تفعيل ميزة الفنادق القريبة بكل حالات الصلاحية.
- **Tasks**: `LocationService` فعلي، طلب صلاحية، معالجة كل الحالات (منح/رفض/رفض دائم/تعطيل/تحميل/خطأ/إعادة محاولة/فارغ)، عرض قائمة مرتبة بالمسافة.
- **Dependencies**: Phase 01, 08.
- **Acceptance Criteria**: كل حالة صلاحية لها شاشة/رسالة فعلية مختلفة، لا حالة "صامتة" غير معالجة.
- **Tests**: Unit لمنطق الصلاحيات (بمحاكاة كل حالة)، Widget لكل حالة عرض.

## Phase 15 — Explore Iraq
- **Goal**: قسم اكتشف العراق فعليًا.
- **Tasks**: قائمة الوجهات، شاشة تفاصيل وجهة، ربط الفنادق القريبة من الوجهة.
- **Dependencies**: Phase 08, 14.
- **Acceptance Criteria**: فتح وجهة يعرض فنادق فعلية مرتبطة بها.
- **Tests**: Widget + Repository tests.

## Phase 16 — Profile
- **Goal**: صفحة الملف الشخصي الكاملة.
- **Tasks**: عرض/تعديل بيانات المستخدم، روابط لحجوزاتي/المفضلة/اللغة/الإعدادات، تسجيل خروج فعلي.
- **Dependencies**: Phase 04, 12, 13.
- **Acceptance Criteria**: تسجيل الخروج يُنهي الجلسة فعليًا ويعيد لشاشة الدخول.
- **Tests**: Widget + State tests.

## Phase 17 — Maps
- **Goal**: عرض خرائط فعلية بدل Placeholder.
- **Tasks**: دمج مكتبة خرائط، عرض موقع الفندق فعليًا، استخدام الإحداثيات في Nearby Hotels لحساب مسافات حقيقية.
- **Dependencies**: Phase 08, 14.
- **Acceptance Criteria**: الخريطة تعرض الموقع الصحيح فعليًا وليست صورة ثابتة.
- **Tests**: Widget test للتحقق من عرض المكوّن (باستخدام Mock للخدمة).

## Phase 18 — Notifications
- **Goal**: تفعيل نظام إشعارات أساسي.
- **Tasks**: `NotificationService`، إشعار تأكيد حجز فعلي، مركز إشعارات بسيط داخل التطبيق.
- **Dependencies**: Phase 11.
- **Acceptance Criteria**: تأكيد حجز يُطلق إشعارًا فعليًا قابلًا للعرض.
- **Tests**: Unit للخدمة.

## Phase 19 — Backend Integration
- **Goal**: استبدال كل Mock Data Sources بربط API حقيقي وفق API_CONTRACT.md.
- **Tasks**: بناء `ApiClient` فعلي، تحديث كل Repository لاستدعاء API حقيقي، معالجة أخطاء الشبكة الحقيقية.
- **Dependencies**: كل الـ Phases من 04 إلى 18.
- **Acceptance Criteria**: التطبيق يعمل بالكامل على بيانات حقيقية من Backend بدون كسر أي Feature سابقة.
- **Tests**: Integration tests شاملة لكل تدفق رئيسي.

## Phase 20 — Hotel Partner
- **Goal**: بناء لوحة إدارة الفندق (Hotel Manager) فعليًا.
- **Tasks**: دخول مخصص، إدارة الغرف/الأسعار/التوفر/الصور/الحجوزات/العروض.
- **Dependencies**: Phase 19.
- **Acceptance Criteria**: مدير الفندق يستطيع تعديل بيانات فعلية تنعكس على تطبيق المستخدم.
- **Tests**: Unit + Widget + Integration.

## Phase 21 — Admin Dashboard
- **Goal**: بناء لوحة الإدارة العامة فعليًا.
- **Tasks**: إدارة المستخدمين، قبول/رفض الفنادق، إدارة الحجوزات/الوجهات/المحتوى/الإشعارات، تقارير وإحصائيات.
- **Dependencies**: Phase 19, 20.
- **Acceptance Criteria**: قرارات الأدمن (مثل قبول فندق) تنعكس فعليًا على ظهوره للمستخدمين.
- **Tests**: Unit + Widget + Integration.

## Phase 22 — Security Hardening
- **Goal**: تدقيق ومعالجة الثغرات الأمنية المحتملة.
- **Tasks**: مراجعة تخزين التوكن، صلاحيات الأدوار، حماية المسارات الحساسة، فحص Dependencies.
- **Dependencies**: Phase 19, 20, 21.
- **Acceptance Criteria**: لا صلاحيات زائدة، لا بيانات حساسة مكشوفة.
- **Tests**: اختبارات أمان مستهدفة (Auth guards، role checks).

## Phase 23 — Performance
- **Goal**: تحسين الأداء العام.
- **Tasks**: تحسين إعادة البناء غير الضرورية (rebuilds)، تحميل كسول للصور، تحسين حجم القوائم الطويلة.
- **Dependencies**: كل الـ Phases السابقة.
- **Acceptance Criteria**: لا تهنّج ملحوظ في القوائم الطويلة والانتقالات.
- **Tests**: قياسات أداء يدوية/آلية أساسية.

## Phase 24 — Testing (شامل)
- **Goal**: رفع تغطية الاختبار لكل الطبقات وفق TESTING_STRATEGY.md.
- **Tasks**: سد أي فجوات اختبار متبقية من الـ Phases السابقة.
- **Dependencies**: كل الـ Phases السابقة.
- **Acceptance Criteria**: `flutter test` ناجح بالكامل بتغطية مقبولة للمنطق الحرج (Booking Flow خصوصًا).
- **Tests**: —

## Phase 25 — Final QA
- **Goal**: مراجعة شاملة يدوية لكل التدفقات قبل الإصدار.
- **Tasks**: اختبار يدوي كامل (عربي/إنجليزي، RTL/LTR)، مراجعة Design System، مراجعة كل حالات الخطأ/الفراغ/التحميل.
- **Dependencies**: Phase 24.
- **Acceptance Criteria**: لا Bugs حرجة معروفة، كل Feature يطابق Definition of Done.
- **Tests**: —

## Phase 26 — Android Release
- **Goal**: تجهيز ونشر إصدار أندرويد.
- **Tasks**: إعداد التوقيع، الأيقونات، Store Listing، بناء AAB، رفع للمتجر.
- **Dependencies**: Phase 25.
- **Acceptance Criteria**: بناء إصدار (Release Build) ناجح وقابل للتثبيت.
- **Tests**: اختبار تثبيت يدوي على جهاز حقيقي.

## Phase 27 — iOS Release
- **Goal**: تجهيز ونشر إصدار iOS.
- **Tasks**: إعداد الشهادات، الأيقونات، App Store Listing، بناء الإصدار، رفع للمتجر.
- **Dependencies**: Phase 25.
- **Acceptance Criteria**: بناء إصدار ناجح وقابل للتثبيت عبر TestFlight على الأقل.
- **Tests**: اختبار تثبيت يدوي على جهاز حقيقي.

---

## Definition of Done العام (يُطبَّق على كل Phase/Feature)
1. UI مكتملة.
2. التفاعل يعمل فعليًا (وفق NO FAKE INTERACTIONS POLICY في AI_INSTRUCTIONS.md).
3. Navigation يعمل.
4. State يعمل.
5. Business Logic متصل فعليًا (Use Cases → Repository).
6. Repository متصل (Mock مقبول قبل Phase 19، حقيقي بعدها).
7. Loading State موجود.
8. Empty State موجود (حيث ينطبق).
9. Error State موجود.
10. Validation موجود (حيث ينطبق).
11. Tests موجودة.
12. `flutter analyze` ناجح بدون أخطاء.
13. `flutter test` ناجح بالكامل.

## Quality Gate بعد كل Phase
```
dart format .
flutter analyze
flutter test
```
لا تُعتبر أي Phase مكتملة إذا احتوت النتائج على أخطاء.
