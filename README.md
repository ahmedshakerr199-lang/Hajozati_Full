# حجوزاتي — Hajozati

مشروع Flutter جاهز كنموذج Mock متكامل لتجربة تطبيق حجز الفنادق في العراق.

## الموجود حاليًا
- العربية / الإنجليزية مع RTL/LTR داخل الواجهات الأساسية.
- الرئيسية ومحرك البحث (المحافظة، الوصول، المغادرة، بالغون، أطفال).
- نتائج البحث ببيانات Mock.
- تفاصيل الفندق والخدمات والموقع.
- اختيار الغرفة.
- بيانات النزيل والتحقق من الإدخال.
- ملخص الحجز.
- تأكيد الحجز + Booking Reference + QR.
- صفحة حجوزاتي.
- المفضلة.
- Nearby Hotels (واجهة Mock؛ GPS الحقيقي غير مربوط بعد).
- اكتشف العراق.
- الملف الشخصي وتبديل اللغة.
- جميع ملفات Blueprint الأصلية داخل `docs/`.

> البيانات الحالية Mock للتجربة. الـBackend الحقيقي، الخرائط الفعلية، GPS، Auth الحقيقي والإشعارات لم تُربط بعد.

## تشغيل المشروع في VS Code
1. ثبّت Flutter Stable وتأكد أن `flutter doctor` يعمل.
2. افتح مجلد `Hajozati_Full` نفسه في VS Code.
3. من Terminal:

```bash
flutter pub get
flutter run
```

للتشغيل على Chrome:

```bash
flutter run -d chrome
```

## إذا ظهرت مشكلة في ملفات Android/iOS
لأن هذا المشروع تم تجهيزه في بيئة لا تحتوي Flutter SDK، ملفات المنصات لم يمكن التحقق منها ببناء فعلي هنا. أعد توليد ملفات المنصات بواسطة Flutter بدون المساس بكود `lib/` و`docs/`:

```bash
flutter create --platforms=android,ios,web .
flutter pub get
```

ثم تأكد من Android package المطلوب `com.hjozaty.app` في:
- `android/app/build.gradle.kts`
- `android/app/src/main/kotlin/com/hjozaty/app/MainActivity.kt`

## الحالة
نسخة تشغيل وتجربة Mock للـFrontend وBooking Flow. لا تعتبر Backend Production.
