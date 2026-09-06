# AI_INSTRUCTIONS.md — تعليمات دائمة لأي AI Agent يعمل على مشروع حجوزاتي

هذا الملف إلزامي لأي Claude أو Codex أو AI Agent آخر يعمل على هذا المشروع لاحقًا (بعد أمر "ابدأ Phase 00" أو ما يليه).

## قبل أي Coding — اقرأ بالترتيب
1. `PRODUCT_VISION.md`
2. `REQUIREMENTS.md`
3. `ARCHITECTURE.md`
4. `PROJECT_STRUCTURE.md`
5. `DATA_MODELS.md`
6. `NAVIGATION_FLOW.md`
7. `DESIGN_SYSTEM.md`
8. `DEVELOPMENT_ROADMAP.md`
9. `PROJECT_PROGRESS.md` ← الأهم لمعرفة أين توقف العمل بالضبط.

## قاعدة التنفيذ
- نفّذ **Phase واحدة فقط** في كل مرة، بالضبط كما هي معرَّفة في `DEVELOPMENT_ROADMAP.md`، ولا تتجاوزها للـ Phase التالية دون أمر صريح جديد.
- لا تُعِد ترتيب أو تدمج Phases إلا إذا طلب صاحب المشروع ذلك صراحة.
- التزم ببنية `PROJECT_STRUCTURE.md` حرفيًا؛ لا تُنشئ مجلدات أو أنماط تنظيم بديلة.
- التزم بأسماء الـ Models والـ Features كما وردت في `DATA_MODELS.md` و`PROJECT_STRUCTURE.md` دون تغيير تسميات.

## NO FAKE INTERACTIONS POLICY (قاعدة إلزامية)
لا يوجد Button أو Search أو Filter أو Form أو Navigation أو Booking Action يُعتبر مكتملًا إذا لم يكن يعمل فعليًا.
- صفحة جميلة لا تعمل **ليست** Feature مكتملة.
- زر بدون Action حقيقي **لا يعتبر** تنفيذًا.
- Placeholder Page **لا تعتبر** تنفيذًا.
- كل عنصر تفاعلي يجب أن يكون متصلًا فعليًا بمنطقه (State → Use Case → Repository) قبل اعتبار المهمة منتهية.

## بعد تنفيذ أي Phase — الترتيب الإلزامي
1. `dart format .`
2. `flutter analyze` — يجب أن تكون النتيجة بدون أخطاء.
3. `flutter test` — يجب أن تنجح كل الاختبارات.
4. إصلاح أي مشكلة تظهر في الخطوات أعلاه (Fix).
5. تحديث `PROJECT_PROGRESS.md`: تحريك الـ Phase المكتملة إلى Completed Phases، تحديث Current Phase وNext Phase، تسجيل أي قرار أو مشكلة جديدة.
6. **التوقف** — لا تبدأ الـ Phase التالية تلقائيًا؛ انتظر أمرًا صريحًا جديدًا من صاحب المشروع.

## قواعد عامة إضافية
- لا نصوص Hard-coded في الواجهات؛ كل نص عبر نظام الترجمة (`app_ar.arb` / `app_en.arb`).
- لا بيانات محافظات أو وجهات Hard-coded داخل الـ UI؛ يجب أن تأتي من `assets/data/` أو Repository.
- الالتزام الكامل بـ Design System (الألوان، الخطوط، المسافات، الأنصاف الدائرية) كما في `DESIGN_SYSTEM.md` — بدون قيم عشوائية جديدة.
- أي قرار معماري أو تقني جديد أثناء التنفيذ يجب تسجيله في `DECISIONS.md` مع السبب.
- عند وجود أي تعارض بين ملفات التخطيط، التزم بالأحدث المسجَّل في `PROJECT_PROGRESS.md` أو اطلب توضيحًا من صاحب المشروع بدل الافتراض.
