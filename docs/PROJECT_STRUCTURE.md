# PROJECT_STRUCTURE.md — حجوزاتي (Hajozati)

```
hajozati/
├── lib/
│   ├── main.dart                      # نقطة الدخول، تهيئة ProviderScope
│   │
│   ├── app/                           # إعداد التطبيق العام
│   │   ├── app.dart                   # MaterialApp.router + Theme + Localization delegate
│   │   ├── router/
│   │   │   ├── app_router.dart        # تعريف go_router وكل الـ Routes
│   │   │   └── route_names.dart       # ثوابت أسماء المسارات
│   │   ├── theme/
│   │   │   ├── app_colors.dart        # ألوان حجوزاتي (راجع DESIGN_SYSTEM.md)
│   │   │   ├── app_typography.dart
│   │   │   ├── app_spacing.dart
│   │   │   └── app_theme.dart         # ThemeData الموحّد (Light أساسًا)
│   │   └── localization/
│   │       ├── app_ar.arb
│   │       ├── app_en.arb
│   │       └── locale_provider.dart   # إدارة اللغة الحالية (Riverpod)
│   │
│   ├── core/                          # كود مشترك تقني، لا يخص Feature معينة
│   │   ├── error/
│   │   │   ├── failure.dart           # أنواع الأخطاء الموحدة (Result/Failure)
│   │   │   └── exceptions.dart
│   │   ├── network/
│   │   │   ├── api_client.dart        # Wrapper حول Dio/http (لاحقًا)
│   │   │   └── api_endpoints.dart
│   │   ├── storage/
│   │   │   ├── local_storage_service.dart
│   │   │   └── secure_storage_service.dart
│   │   ├── utils/
│   │   │   ├── date_utils.dart
│   │   │   ├── validators.dart
│   │   │   └── formatters.dart
│   │   └── services/
│   │       ├── location_service.dart
│   │       ├── qr_code_service.dart
│   │       └── notification_service.dart (لاحقًا)
│   │
│   ├── shared/                        # عناصر UI ونماذج مشتركة بين أكثر من Feature
│   │   ├── widgets/
│   │   │   ├── buttons/
│   │   │   ├── inputs/
│   │   │   ├── cards/
│   │   │   │   ├── hotel_card.dart
│   │   │   │   └── room_card.dart
│   │   │   ├── loading/
│   │   │   │   └── skeleton_loader.dart
│   │   │   ├── states/
│   │   │   │   ├── empty_state.dart
│   │   │   │   └── error_state.dart
│   │   │   └── bottom_sheets_dialogs/
│   │   └── models/
│   │       └── governorate.dart       # بيانات المحافظات (منفصلة عن الـ UI)
│   │
│   └── features/
│       ├── auth/
│       │   ├── presentation/{screens,widgets,state}/
│       │   ├── domain/{entities,usecases,repositories}/
│       │   └── data/{models,datasources,repositories_impl}/
│       │
│       ├── home/
│       │   └── presentation/{screens,widgets,state}/
│       │
│       ├── search/                    # بطاقة البحث + نتائج البحث
│       │   ├── presentation/{screens,widgets,state}/
│       │   ├── domain/{entities,usecases,repositories}/
│       │   └── data/{models,datasources,repositories_impl}/
│       │
│       ├── hotel/                     # تفاصيل الفندق + الغرف
│       │   ├── presentation/{screens,widgets,state}/
│       │   ├── domain/{entities,usecases,repositories}/
│       │   └── data/{models,datasources,repositories_impl}/
│       │
│       ├── booking/                   # Booking Draft + تدفق الحجز الكامل + QR
│       │   ├── presentation/{screens,widgets,state}/
│       │   ├── domain/{entities,usecases,repositories}/
│       │   └── data/{models,datasources,repositories_impl}/
│       │
│       ├── bookings/                  # صفحة "حجوزاتي" (Upcoming/Completed/Cancelled)
│       │   ├── presentation/{screens,widgets,state}/
│       │   ├── domain/{entities,usecases,repositories}/
│       │   └── data/{models,datasources,repositories_impl}/
│       │
│       ├── favorites/
│       │   ├── presentation/{screens,widgets,state}/
│       │   ├── domain/{entities,usecases,repositories}/
│       │   └── data/{models,datasources,repositories_impl}/
│       │
│       ├── nearby/                    # Nearby Hotels
│       │   ├── presentation/{screens,widgets,state}/
│       │   ├── domain/{entities,usecases,repositories}/
│       │   └── data/{models,datasources,repositories_impl}/
│       │
│       ├── explore/                   # اكتشف العراق
│       │   ├── presentation/{screens,widgets,state}/
│       │   ├── domain/{entities,usecases,repositories}/
│       │   └── data/{models,datasources,repositories_impl}/
│       │
│       ├── profile/
│       │   ├── presentation/{screens,widgets,state}/
│       │   ├── domain/{entities,usecases,repositories}/
│       │   └── data/{models,datasources,repositories_impl}/
│       │
│       ├── hotel_partner/  (مستقبلي - Phase 20، مجلد فارغ محجوز الآن)
│       └── admin/          (مستقبلي - Phase 21، مجلد فارغ محجوز الآن)
│
├── test/
│   ├── features/<feature>/domain/...
│   ├── features/<feature>/data/...
│   └── features/<feature>/presentation/...
│
├── assets/
│   ├── images/
│   ├── icons/
│   └── data/                          # بيانات ثابتة مبدئية (governorates.json, destinations.json)
│
└── docs/                              # ملفات هذا التخطيط (المرجع الدائم للمشروع)
```

## مسؤولية كل مجلد رئيسي

| المجلد | المسؤولية |
|---|---|
| `app/` | تركيب التطبيق: Router، Theme، Localization — لا منطق عمل هنا |
| `core/` | كود تقني عابر (شبكة، تخزين، أخطاء، أدوات، خدمات) لا يعرف شيئًا عن أي Feature |
| `shared/` | Widgets ونماذج بيانات عامة يعاد استخدامها في أكثر من Feature (مثل بطاقة الفندق، حالات التحميل/الفراغ/الخطأ) |
| `features/<name>/presentation` | الشاشات والودجات والحالة (State/ViewModel) الخاصة بالـ Feature |
| `features/<name>/domain` | Entities، Use Cases، عقود Repository — بدون أي اعتماد على Flutter |
| `features/<name>/data` | Models/DTOs، مصادر البيانات (Remote/Local)، تنفيذ الـ Repository |
| `test/` | يعكس بنية `lib/` تمامًا لسهولة إيجاد اختبار أي ملف |
| `assets/data/` | بيانات شبه ثابتة (محافظات، وجهات) بصيغة JSON منفصلة عن الكود، قابلة للنقل لاحقًا إلى Backend |
