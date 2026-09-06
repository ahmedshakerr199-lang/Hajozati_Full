# ARCHITECTURE.md — حجوزاتي (Hajozati)

## 1. Architecture Style
Feature-based Clean Architecture مبسّطة، بثلاث طبقات واضحة داخل كل Feature:

```
Presentation  →  Domain  →  Data
```

- **Presentation**: الشاشات (Screens)، الودجات (Widgets)، الـ State/ViewModel.
- **Domain**: Entities، Use Cases، عقود الـ Repository (Abstract).
- **Data**: تنفيذ الـ Repository، Data Sources (Remote/Local)، Models/DTOs، تحويلها إلى Entities.

الهدف: كل Feature (auth, home, search, hotel, booking, bookings, favorites, nearby, explore, profile) تحتوي مجلداتها الثلاث الخاصة، مع إمكانية تطويرها أو استبدال مصدر بياناتها دون التأثير على بقية النظام.

## 2. Layers & Responsibilities

| الطبقة | المسؤولية | لا تعرف عن |
|---|---|---|
| Presentation | عرض الحالة، التقاط تفاعل المستخدم، استدعاء Use Cases عبر الـ State | Data Sources أو API مباشرة |
| Domain | منطق العمل الصافي (Business Rules)، تعريف العقود | Flutter widgets أو تفاصيل الشبكة |
| Data | تنفيذ الجلب/التخزين، تحويل JSON إلى Entities | تفاصيل الـ UI |

## 3. Dependency Direction
الاعتماد يتجه دائمًا من الخارج إلى الداخل:

```
Presentation → Domain ← Data
```

- Domain لا يعتمد على أي طبقة أخرى (طبقة مستقلة تمامًا، بدون Flutter imports).
- Presentation و Data يعتمدان على Domain (عبر الواجهات/العقود Interfaces).
- لا يجوز أن يستدعي Domain أي شيء من Data أو Presentation مباشرة.

## 4. State Management
**الاختيار: Riverpod (flutter_riverpod)**

**سبب الاختيار:**
- Type-safe وقابل للاختبار بمعزل عن الـ Widget Tree.
- يدعم Async State (Loading/Data/Error) بشكل مدمج، مناسب لتدفقات مثل البحث والحجز.
- يسمح بحقن الاعتمادات (Dependency Injection) عبر Providers بدون الحاجة لمكتبة DI منفصلة.
- قابل للتوسع لمشروع متوسط–كبير مع تعدد الأدوار (User / Hotel Manager / Admin) لاحقًا.
- انتشار واسع في مجتمع Flutter وتوثيق ناضج.

يُستخدم لكل Feature Provider خاص بحالته (مثل `searchProvider`, `bookingDraftProvider`) بحيث يمثل `BookingDraft` حالة مركزية واحدة (Single Source of Truth) تُقرأ وتُعدَّل عبر عدة شاشات متتالية في تدفق الحجز.

## 5. Navigation
**الاختيار: go_router**

**سبب الاختيار:**
- Routing تصريحي (Declarative) مركزي مناسب لعدد الشاشات الكبير في المشروع.
- دعم مدمج لـ Deep Links وNested Navigation.
- تكامل جيد مع Riverpod لإعادة التوجيه الشرطي (مثل حماية شاشات تتطلب تسجيل دخول).
- سهولة تمرير المعاملات (Path/Query/Extra) بين الشاشات، وهو ما يحتاجه تدفق البحث والحجز.

راجع NAVIGATION_FLOW.md للخريطة الكاملة والمعاملات بين الشاشات.

## 6. Dependency Injection
عبر Riverpod Providers نفسها (`Provider`, `FutureProvider`, `NotifierProvider`) بدل مكتبة DI منفصلة — تبسيطًا للمشروع وتجنبًا لطبقة إضافية غير ضرورية. كل Repository يُعرَّف كـ Provider يمكن استبداله بسهولة في الاختبارات (Override في `ProviderScope`).

## 7. Repositories
- تُعرَّف كـ Abstract Classes داخل `domain/repositories/` لكل Feature.
- التنفيذ الفعلي في `data/repositories_impl/` يعتمد على Data Source (Remote الآن وهمي/Mock، لاحقًا API حقيقي).
- الهدف: يمكن استبدال مصدر البيانات (Mock → REST API) دون تعديل Domain أو Presentation.

## 8. Use Cases
- كل عملية عمل واضحة (مثل `SearchHotelsUseCase`, `ConfirmBookingUseCase`, `ToggleFavoriteUseCase`) تكون Class منفصلة بدالة `call()` واحدة.
- تُستدعى فقط من الـ State/ViewModel في Presentation، ولا تُستدعى مباشرة من الـ Widgets.

## 9. Models / Entities
- **Entities** (Domain): تمثل الكائنات النظيفة المستخدمة في منطق العمل (بدون تفاصيل JSON).
- **Models/DTOs** (Data): تمثيل البيانات القادمة من المصدر (API/Local) مع دوال `fromJson/toJson`، وتُحوَّل إلى Entities عبر Mapper.
- راجع DATA_MODELS.md للتفصيل الكامل.

## 10. Services
طبقة `core/services/` تحتوي خدمات مشتركة عابرة للـ Features مثل:
- `LocationService` (لميزة Nearby Hotels).
- `QrCodeService` (توليد QR عند التأكيد).
- `LocalizationService`.
- `NotificationService` (لاحقًا).

## 11. Data Sources
- **Remote Data Source**: مسؤول عن الاتصال بـ API (لاحقًا)، حاليًا يمكن أن يكون Mock Data Source يعيد بيانات ثابتة تحاكي شكل الاستجابة الحقيقية.
- **Local Data Source**: للتخزين المحلي (تفضيلات، مسودة حجز غير مكتملة، مفضلة محلية cache) عبر `core/storage/`.

## 12. API Layer
- طبقة `core/network/` تحتوي `ApiClient` عام (Wrapper حول Dio أو http) لإدارة الطلبات، الأخطاء، والـ Interceptors (توكن، لغة، إلخ) — تُبنى لاحقًا عند ربط Backend حقيقي (Phase 19).
- راجع API_CONTRACT.md للعقد المبدئي.

## 13. Local Storage
- تخزين خفيف (مثل `shared_preferences` أو `hive`) لـ: اللغة المختارة، حالة تسجيل الدخول، Booking Draft المؤقت، قائمة مفضلة (قبل ربط Backend).

## 14. Error Handling
- نمط موحّد: كل Use Case/Repository يعيد نتيجة إما نجاح (Entity) أو فشل (Failure) عبر نوع نتيجة موحّد (مثل `Result<T>` أو `Either`).
- Presentation يترجم الـ Failure إلى حالة UI مناسبة (Error State مع رسالة ونص إعادة المحاولة).
- تصنيف الأخطاء: NetworkFailure, ValidationFailure, PermissionFailure (للموقع الجغرافي)، UnknownFailure.

## 15. Localization
- `flutter_localizations` + ملفات ARB (`app_ar.arb`, `app_en.arb`, وبنية جاهزة لـ `app_fa.arb` مستقبلًا).
- لا نصوص Hard-coded داخل أي Widget.
- دعم RTL/LTR عبر `Directionality` التلقائي المرتبط بلغة التطبيق.

## 16. Security (معماريًا)
- فصل الأدوار (User / Hotel Manager / Admin) عبر طبقة Auth قابلة للتوسع (Role field في نموذج المستخدم) دون بناء الأدوار فعليًا الآن.
- عدم تخزين بيانات حساسة في Local Storage بنص صريح.
- طبقة API جاهزة لإرفاق التوكن عبر Interceptor عند ربط Backend.

## 17. Testing
- Domain: اختبارات Unit للـ Use Cases (بمعزل عن أي شيء خارجي، باستخدام Mock Repositories).
- Data: اختبارات Unit للـ Repository Implementations وMappers.
- Presentation: Widget Tests للشاشات الأساسية + اختبارات لحالة الـ Provider/State.
- راجع TESTING_STRATEGY.md للتفصيل الكامل.
