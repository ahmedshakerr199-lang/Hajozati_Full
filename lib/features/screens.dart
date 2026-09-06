import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../app/state.dart';
import '../app/theme.dart';
import '../core/mock_data.dart';
import '../core/models.dart';
import '../core/room_recommendation.dart';

String _date(DateTime d) =>
    '${d.year}/${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}';
String _money(double value, bool ar) =>
    '${value.toStringAsFixed(0)} ${ar ? 'د.ع' : 'IQD'}';

class _PageShell extends StatelessWidget {
  const _PageShell({required this.title, required this.child, this.actions});
  final String title;
  final Widget child;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
            title: Text(title,
                style: const TextStyle(fontWeight: FontWeight.w800)),
            actions: actions),
        body: SafeArea(child: child),
      );
}

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String? governorate;
  DateTime? checkIn;
  DateTime? checkOut;
  int adults = 2;
  int children = 0;

  String? localizedGovernorate(bool arabic) {
    if (governorate == null) return null;
    final current =
        (arabic ? governoratesAr : governoratesEn).indexOf(governorate!);
    if (current >= 0) return governorate;
    final other =
        (arabic ? governoratesEn : governoratesAr).indexOf(governorate!);
    return other >= 0
        ? (arabic ? governoratesAr : governoratesEn)[other]
        : null;
  }

  Future<void> pickDate(bool isCheckIn) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
        context: context,
        firstDate: now,
        lastDate: DateTime(now.year + 2),
        initialDate: isCheckIn
            ? (checkIn ?? now)
            : (checkOut ?? now.add(const Duration(days: 1))));
    if (picked == null) return;
    setState(() {
      if (isCheckIn) {
        checkIn = picked;
        checkOut ??= picked.add(const Duration(days: 1));
      } else {
        checkOut = picked;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appControllerProvider);
    final ar = state.isArabic;
    final items = ar ? governoratesAr : governoratesEn;
    final canSearch = governorate != null &&
        checkIn != null &&
        checkOut != null &&
        checkOut!.isAfter(checkIn!);
    return Directionality(
      textDirection: ar ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(title: Text(ar ? 'حجوزاتي' : 'Hajozati'), actions: [
          TextButton(
              onPressed: () =>
                  ref.read(appControllerProvider.notifier).toggleLanguage(),
              child: Text(ar ? 'EN' : 'عربي'))
        ]),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(ar ? 'احجز إقامتك بسهولة' : 'Book your stay easily'),
            DropdownButtonFormField<String>(
                initialValue: localizedGovernorate(ar),
                decoration:
                    InputDecoration(labelText: ar ? 'المحافظة' : 'Governorate'),
                items: items
                    .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                    .toList(),
                onChanged: (value) => setState(() => governorate = value)),
            Row(children: [
              Expanded(
                  child: _TapField(
                      label: ar ? 'الوصول' : 'Check-in',
                      value: checkIn == null ? '' : _date(checkIn!),
                      icon: Icons.calendar_month,
                      onTap: () => pickDate(true))),
              const SizedBox(width: 8),
              Expanded(
                  child: _TapField(
                      label: ar ? 'المغادرة' : 'Check-out',
                      value: checkOut == null ? '' : _date(checkOut!),
                      icon: Icons.event_available,
                      onTap: () => pickDate(false))),
            ]),
            Row(children: [
              Expanded(
                  child: _Counter(
                      label: ar ? 'البالغون' : 'Adults',
                      value: adults,
                      min: 1,
                      onChanged: (value) => setState(() => adults = value))),
              const SizedBox(width: 8),
              Expanded(
                  child: _Counter(
                      label: ar ? 'الأطفال' : 'Children',
                      value: children,
                      min: 0,
                      onChanged: (value) => setState(() => children = value))),
            ]),
            const SizedBox(height: 16),
            FilledButton(
                onPressed: canSearch
                    ? () {
                        ref
                            .read(appControllerProvider.notifier)
                            .startSearch(SearchCriteria(
                              governorate: governorate!,
                              checkIn: checkIn!,
                              checkOut: checkOut!,
                              adults: adults,
                              children: children,
                            ));
                        context.push('/results');
                      }
                    : null,
                child: Text(ar ? 'بحث عن الفنادق' : 'Search hotels')),
            const SizedBox(height: 16),
            Text(ar ? 'استكشف' : 'Explore'),
            Wrap(children: [
              _Shortcut(
                  icon: Icons.book_online_outlined,
                  label: ar ? 'حجوزاتي' : 'My bookings',
                  onTap: () => context.push('/bookings')),
              _Shortcut(
                  icon: Icons.favorite_border,
                  label: ar ? 'المفضلة' : 'Favorites',
                  onTap: () => context.push('/favorites')),
              _Shortcut(
                  icon: Icons.near_me_outlined,
                  label: ar ? 'فنادق قريبة' : 'Nearby',
                  onTap: () => context.push('/nearby')),
              _Shortcut(
                  icon: Icons.travel_explore,
                  label: ar ? 'اكتشف العراق' : 'Explore Iraq',
                  onTap: () => context.push('/explore')),
              _Shortcut(
                  icon: Icons.person_outline,
                  label: ar ? 'الملف الشخصي' : 'Profile',
                  onTap: () => context.push('/profile')),
            ]),
          ],
        ),
      ),
    );
  }
}

class _TapField extends StatelessWidget {
  const _TapField(
      {required this.label,
      required this.value,
      required this.icon,
      required this.onTap});
  final String label;
  final String value;
  final IconData icon;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: InputDecorator(
            decoration:
                InputDecoration(labelText: label, prefixIcon: Icon(icon)),
            child: Text(value.isEmpty ? '—' : value)),
      );
}

class _Counter extends StatelessWidget {
  const _Counter(
      {required this.label,
      required this.value,
      required this.min,
      required this.onChanged});
  final String label;
  final int value;
  final int min;
  final ValueChanged<int> onChanged;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE4E8E7))),
        child: Row(children: [
          Expanded(child: Text(label)),
          IconButton(
              onPressed: value > min ? () => onChanged(value - 1) : null,
              icon: const Icon(Icons.remove)),
          Text('$value', style: const TextStyle(fontWeight: FontWeight.w800)),
          IconButton(
              onPressed: () => onChanged(value + 1),
              icon: const Icon(Icons.add))
        ]),
      );
}

class _Shortcut extends StatelessWidget {
  const _Shortcut(
      {required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => SizedBox(
        width: 160,
        child: Card(
            child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: onTap,
                child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(icon, color: AppColors.primary),
                          const SizedBox(height: 12),
                          Text(label,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w700))
                        ])))),
      );
}

class SearchResultsScreen extends ConsumerWidget {
  const SearchResultsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appControllerProvider);
    final ar = state.isArabic;
    final criteria = state.draft.criteria;
    if (criteria == null) {
      return _PageShell(
          title: ar ? 'نتائج البحث' : 'Search results',
          child: Center(
              child: Text(ar
                  ? 'ابدأ بحثًا من الصفحة الرئيسية.'
                  : 'Start a search from Home.')));
    }
    final list = hotels
        .where((h) =>
            (ar ? h.governorateAr : h.governorateEn) == criteria.governorate)
        .toList();
    return Directionality(
      textDirection: ar ? TextDirection.rtl : TextDirection.ltr,
      child: _PageShell(
        title: ar ? 'نتائج البحث' : 'Search results',
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
                '${criteria.governorate} • ${_date(criteria.checkIn)} → ${_date(criteria.checkOut)}',
                style: TextStyle(color: Colors.grey.shade700)),
            const SizedBox(height: 16),
            if (list.isEmpty)
              _Empty(
                  message: ar
                      ? 'لا توجد فنادق تجريبية لهذه المحافظة بعد. جرّب بغداد أو البصرة أو النجف أو أربيل.'
                      : 'No mock hotels for this governorate yet. Try Baghdad, Basra, Najaf or Erbil.')
            else
              ...list.map((h) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _HotelCard(
                      hotel: h,
                      ar: ar,
                      favorite: state.favoriteIds.contains(h.id),
                      onFavorite: () => ref
                          .read(appControllerProvider.notifier)
                          .toggleFavorite(h.id),
                      onTap: () {
                        ref.read(appControllerProvider.notifier).selectHotel(h);
                        context.push('/hotel/${h.id}');
                      }))),
          ],
        ),
      ),
    );
  }
}

class _HotelCard extends StatelessWidget {
  const _HotelCard(
      {required this.hotel,
      required this.ar,
      required this.favorite,
      required this.onFavorite,
      required this.onTap});
  final Hotel hotel;
  final bool ar;
  final bool favorite;
  final VoidCallback onFavorite;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Card(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(children: [
              Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: .09),
                      borderRadius: BorderRadius.circular(16)),
                  child: const Icon(Icons.hotel_rounded,
                      size: 42, color: AppColors.primary)),
              const SizedBox(width: 14),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(ar ? hotel.nameAr : hotel.nameEn,
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 17)),
                    const SizedBox(height: 6),
                    Text(ar ? hotel.addressAr : hotel.addressEn),
                    const SizedBox(height: 8),
                    Row(children: [
                      const Icon(Icons.star,
                          size: 18, color: AppColors.warning),
                      Text(' ${hotel.rating}'),
                      const Spacer(),
                      Text(_money(hotel.minPrice, ar),
                          style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              color: AppColors.primary))
                    ])
                  ])),
              IconButton(
                  onPressed: onFavorite,
                  icon: Icon(favorite ? Icons.favorite : Icons.favorite_border,
                      color: favorite ? AppColors.danger : null)),
            ]),
          ),
        ),
      );
}

class HotelDetailsScreen extends ConsumerWidget {
  const HotelDetailsScreen({super.key, required this.hotelId});
  final String hotelId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appControllerProvider);
    final ar = state.isArabic;
    final hotel = ref.read(appControllerProvider.notifier).hotelById(hotelId);
    return Directionality(
      textDirection: ar ? TextDirection.rtl : TextDirection.ltr,
      child: _PageShell(
        title: ar ? 'تفاصيل الفندق' : 'Hotel details',
        actions: [
          IconButton(
              onPressed: () => ref
                  .read(appControllerProvider.notifier)
                  .toggleFavorite(hotel.id),
              icon: Icon(state.favoriteIds.contains(hotel.id)
                  ? Icons.favorite
                  : Icons.favorite_border))
        ],
        child: ListView(padding: const EdgeInsets.all(16), children: [
          Container(
              height: 190,
              decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: .10),
                  borderRadius: BorderRadius.circular(24)),
              child: const Icon(Icons.apartment_rounded,
                  size: 90, color: AppColors.primary)),
          const SizedBox(height: 18),
          Text(ar ? hotel.nameAr : hotel.nameEn,
              style:
                  const TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          Row(children: [
            const Icon(Icons.star, color: AppColors.warning),
            Text(
                ' ${hotel.rating}  •  ${ar ? hotel.addressAr : hotel.addressEn}')
          ]),
          const SizedBox(height: 18),
          Text(ar ? hotel.descriptionAr : hotel.descriptionEn,
              style: const TextStyle(height: 1.6)),
          const SizedBox(height: 18),
          Text(ar ? 'الخدمات' : 'Amenities',
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Wrap(
              spacing: 8,
              runSpacing: 8,
              children: (ar ? hotel.amenitiesAr : hotel.amenitiesEn)
                  .map((a) => Chip(label: Text(a)))
                  .toList()),
          const SizedBox(height: 18),
          Card(
              child: ListTile(
                  leading:
                      const Icon(Icons.map_outlined, color: AppColors.primary),
                  title: Text(ar ? 'الموقع على الخريطة' : 'Map location'),
                  subtitle: Text('${hotel.latitude}, ${hotel.longitude}'),
                  trailing: const Icon(Icons.chevron_right))),
          const SizedBox(height: 18),
          FilledButton(
              onPressed: () {
                ref.read(appControllerProvider.notifier).selectHotel(hotel);
                context.push('/rooms');
              },
              child: Text(ar ? 'اختر الغرفة' : 'Choose room')),
        ]),
      ),
    );
  }
}

class RoomSelectionScreen extends ConsumerWidget {
  const RoomSelectionScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appControllerProvider);
    final ar = state.isArabic;
    final hotel = state.draft.hotel;
    final criteria = state.draft.criteria;
    final recommendedRooms = hotel == null || criteria == null
        ? const <RecommendedRoom>[]
        : recommendRooms(hotel.rooms, criteria);
    return Directionality(
      textDirection: ar ? TextDirection.rtl : TextDirection.ltr,
      child: _PageShell(
        title: ar ? 'اختيار الغرفة' : 'Choose room',
        child: hotel == null
            ? _Empty(message: ar ? 'لم يتم اختيار فندق.' : 'No hotel selected.')
            : criteria == null
                ? _Empty(
                    message: ar
                        ? 'أدخل بيانات البحث أولًا.'
                        : 'Start a search first.')
                : recommendedRooms.isEmpty
                    ? _Empty(
                        message: ar
                            ? 'لا توجد غرف مناسبة لعدد البالغين المطلوب.'
                            : 'No rooms fit the requested number of adults.')
                    : ListView(
                        padding: const EdgeInsets.all(16),
                        children: recommendedRooms.map((recommendation) {
                          final r = recommendation.room;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Card(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(ar ? r.nameAr : r.nameEn,
                                              style: const TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.w800)),
                                        ),
                                        if (recommendation.label(ar) != null)
                                          Chip(
                                              label: Text(
                                                  recommendation.label(ar)!)),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                        '${ar ? 'سعة البالغين' : 'Adults capacity'}: ${r.maxAdults} • ${ar ? r.bedsAr : r.bedsEn}'),
                                    if (recommendation.childrenNote(
                                            criteria, ar) !=
                                        null) ...[
                                      const SizedBox(height: 6),
                                      Text(
                                          recommendation.childrenNote(
                                              criteria, ar)!,
                                          style: TextStyle(
                                              color: Colors.grey.shade700)),
                                    ],
                                    const SizedBox(height: 10),
                                    Text(_money(r.price, ar),
                                        style: const TextStyle(
                                            fontSize: 19,
                                            fontWeight: FontWeight.w900,
                                            color: AppColors.primary)),
                                    const SizedBox(height: 12),
                                    FilledButton(
                                      onPressed: r.available
                                          ? () {
                                              final controller = ref.read(
                                                  appControllerProvider
                                                      .notifier);
                                              if (!state.isAuthenticated) {
                                                controller
                                                    .savePendingBookingIntent(
                                                        r);
                                                showAuthRequiredDialog(
                                                    context, ar);
                                                return;
                                              }
                                              controller.selectRoom(r);
                                              context.push('/booking/details');
                                            }
                                          : null,
                                      child: Text(ar
                                          ? 'اختيار هذه الغرفة'
                                          : 'Select this room'),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
      ),
    );
  }
}

void showAuthRequiredDialog(BuildContext context, bool isArabic) {
  showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(isArabic ? 'تسجيل الدخول مطلوب' : 'Login required'),
      content: Text(isArabic
          ? 'يجب تسجيل الدخول لإتمام الحجز'
          : 'Sign in to complete your booking'),
      actions: [
        TextButton(
            onPressed: () => context.pop(),
            child: Text(isArabic ? 'متابعة التصفح' : 'Continue Browsing')),
        TextButton(
            onPressed: () {
              context.pop();
              context.push('/register');
            },
            child: Text(isArabic ? 'إنشاء حساب' : 'Create Account')),
        FilledButton(
            onPressed: () {
              context.pop();
              context.push('/login');
            },
            child: Text(isArabic ? 'تسجيل الدخول' : 'Sign In')),
      ],
    ),
  );
}

class AuthRequiredScreen extends ConsumerWidget {
  const AuthRequiredScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ar = ref.watch(appControllerProvider).isArabic;
    return _PageShell(
      title: ar ? 'تسجيل الدخول مطلوب' : 'Login required',
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                  ar
                      ? 'يجب تسجيل الدخول لإتمام الحجز'
                      : 'Sign in to complete your booking',
                  textAlign: TextAlign.center),
              const SizedBox(height: 18),
              FilledButton(
                  onPressed: () => context.push('/login'),
                  child: Text(ar ? 'تسجيل الدخول' : 'Sign In')),
              TextButton(
                  onPressed: () => context.push('/register'),
                  child: Text(ar ? 'إنشاء حساب' : 'Create Account')),
              TextButton(
                  onPressed: () => context.go('/'),
                  child: Text(ar ? 'متابعة التصفح' : 'Continue Browsing')),
            ],
          ),
        ),
      ),
    );
  }
}

class AuthEntryScreen extends ConsumerWidget {
  const AuthEntryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ar = ref.watch(appControllerProvider).isArabic;
    return Directionality(
      textDirection: ar ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(ar ? 'حجوزاتي' : 'Hajozati',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.w900,
                            color: AppColors.primary)),
                    const SizedBox(height: 10),
                    Text(
                        ar
                            ? 'احجز إقامتك بسهولة في جميع أنحاء العراق'
                            : 'Book your stay easily across Iraq',
                        textAlign: TextAlign.center),
                    const SizedBox(height: 32),
                    FilledButton(
                        onPressed: () => context.push('/login'),
                        child: Text(ar ? 'تسجيل الدخول' : 'Sign In')),
                    const SizedBox(height: 10),
                    OutlinedButton(
                        onPressed: () => context.push('/register'),
                        child: Text(ar ? 'إنشاء حساب جديد' : 'Create Account')),
                    const Padding(
                        padding: EdgeInsets.symmetric(vertical: 18),
                        child: Divider()),
                    TextButton(
                        onPressed: () {
                          ref
                              .read(appControllerProvider.notifier)
                              .continueAsGuest();
                          context.go('/');
                        },
                        child: Text(ar ? 'الدخول كضيف' : 'Continue as Guest')),
                    TextButton(
                        onPressed: () => ref
                            .read(appControllerProvider.notifier)
                            .toggleLanguage(),
                        child: Text(ar ? 'English' : 'العربية')),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final phone = TextEditingController();
  final formKey = GlobalKey<FormState>();
  String? error;
  bool loading = false;

  @override
  void dispose() {
    phone.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (!formKey.currentState!.validate()) return;
    setState(() {
      loading = true;
      error = null;
    });
    final message =
        await ref.read(appControllerProvider.notifier).loginByPhone(phone.text);
    if (!mounted) return;
    if (message != null) {
      setState(() {
        loading = false;
        error = message;
      });
      return;
    }
    final controller = ref.read(appControllerProvider.notifier);
    final resume = ref.read(appControllerProvider).pendingBookingIntent != null;
    controller.resumePendingBooking();
    context.go(resume ? '/booking/details' : '/');
  }

  @override
  Widget build(BuildContext context) {
    final ar = ref.watch(appControllerProvider).isArabic;
    return _AuthFormShell(
      title: ar ? 'تسجيل الدخول' : 'Sign In',
      child: Form(
        key: formKey,
        child: Column(children: [
          TextFormField(
            controller: phone,
            keyboardType: TextInputType.phone,
            autofillHints: const [AutofillHints.telephoneNumber],
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9+ ]'))
            ],
            decoration: InputDecoration(
                labelText: ar ? 'رقم الهاتف' : 'Phone Number',
                prefixIcon: const Icon(Icons.phone_outlined)),
            validator: (value) => value == null || !isValidIraqiPhone(value)
                ? (ar
                    ? 'أدخل رقم هاتف عراقي صحيح'
                    : 'Enter a valid Iraqi phone')
                : null,
          ),
          if (error != null) ...[
            const SizedBox(height: 10),
            Text(error!, style: const TextStyle(color: AppColors.danger)),
            if (error!.contains('لا يوجد'))
              TextButton(
                  onPressed: () => context.push('/register'),
                  child: Text(ar ? 'إنشاء حساب' : 'Create Account')),
          ],
          const SizedBox(height: 18),
          FilledButton(
              onPressed: loading ? null : submit,
              child: Text(loading
                  ? (ar ? 'جارٍ التحقق...' : 'Checking...')
                  : (ar ? 'تسجيل الدخول' : 'Sign In'))),
        ]),
      ),
    );
  }
}

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});
  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final formKey = GlobalKey<FormState>();
  final name = TextEditingController();
  final phone = TextEditingController();
  final email = TextEditingController();
  final otp = TextEditingController();
  DateTime? birthDate;
  String? governorateId;
  String? error;
  bool loading = false;
  bool otpSent = false;
  bool phoneVerified = false;

  @override
  void dispose() {
    name.dispose();
    phone.dispose();
    email.dispose();
    otp.dispose();
    super.dispose();
  }

  Future<void> pickBirthDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
        context: context,
        firstDate: DateTime(now.year - 100),
        lastDate: DateTime(now.year - 12, now.month, now.day),
        initialDate: birthDate ?? DateTime(now.year - 20, now.month, now.day));
    if (picked != null) setState(() => birthDate = picked);
  }

  Future<void> submit() async {
    if (!phoneVerified) {
      setState(() =>
          error = arText('أكد رقم الهاتف أولًا', 'Verify your phone first'));
      return;
    }
    if (!formKey.currentState!.validate() || birthDate == null) {
      setState(() => error = birthDate == null ? 'اختر تاريخ الميلاد' : null);
      return;
    }
    setState(() {
      loading = true;
      error = null;
    });
    final message = await ref.read(appControllerProvider.notifier).registerUser(
          fullName: name.text,
          phone: phone.text,
          governorateId: governorateId!,
          dateOfBirth: birthDate!,
          email: email.text,
          phoneVerified: phoneVerified,
        );
    if (!mounted) return;
    if (message != null) {
      setState(() {
        loading = false;
        error = message;
      });
      return;
    }
    final controller = ref.read(appControllerProvider.notifier);
    final resume = ref.read(appControllerProvider).pendingBookingIntent != null;
    controller.resumePendingBooking();
    context.go(resume ? '/booking/details' : '/');
  }

  String arText(String arabic, String english) =>
      ref.read(appControllerProvider).isArabic ? arabic : english;

  Future<void> sendOtp() async {
    if (!isValidIraqiPhone(phone.text)) {
      setState(() => error =
          arText('أدخل رقم هاتف عراقي صحيح', 'Enter a valid Iraqi phone'));
      return;
    }
    await ref.read(otpProvider).sendRegistrationOtp(phone.text);
    if (!mounted) return;
    setState(() {
      otpSent = true;
      phoneVerified = false;
      error = null;
    });
  }

  Future<void> verifyOtp() async {
    final verified =
        await ref.read(otpProvider).verifyOtp(phone.text, otp.text);
    if (!mounted) return;
    setState(() {
      phoneVerified = verified;
      error = verified
          ? null
          : arText('رمز التحقق غير صحيح', 'The verification code is incorrect');
    });
  }

  @override
  Widget build(BuildContext context) {
    final ar = ref.watch(appControllerProvider).isArabic;
    final governorates = ar ? governoratesAr : governoratesEn;
    return _AuthFormShell(
      title: ar ? 'إنشاء حساب' : 'Create Account',
      child: Form(
        key: formKey,
        child: Column(children: [
          TextFormField(
              controller: phone,
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9+ ]'))
              ],
              decoration: InputDecoration(
                  labelText: ar ? 'رقم الهاتف' : 'Phone Number'),
              validator: (value) => value == null || !isValidIraqiPhone(value)
                  ? (ar
                      ? 'أدخل رقم هاتف عراقي صحيح'
                      : 'Enter a valid Iraqi phone')
                  : null),
          const SizedBox(height: 12),
          FilledButton.icon(
              onPressed: loading ? null : sendOtp,
              icon: const Icon(Icons.send),
              label: Text(ar ? 'إرسال الرمز' : 'Send OTP')),
          if (otpSent) ...[
            const SizedBox(height: 12),
            Text(ar
                ? 'أدخل رمز التحقق المرسل إلى واتساب'
                : 'Enter the verification code sent to WhatsApp'),
            TextFormField(
                controller: otp,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                    labelText: ar ? 'رمز التحقق' : 'Verification code'),
                enabled: !phoneVerified),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(
                  child: OutlinedButton(
                      onPressed: verifyOtp,
                      child: Text(ar ? 'تأكيد الرمز' : 'Verify code'))),
              const SizedBox(width: 8),
              Expanded(
                  child: TextButton(
                      onPressed: sendOtp,
                      child: Text(ar ? 'إعادة إرسال الرمز' : 'Resend OTP'))),
            ]),
            TextButton(
                onPressed: () => setState(() {
                      otpSent = false;
                      phoneVerified = false;
                      otp.clear();
                    }),
                child: Text(ar ? 'تعديل رقم الهاتف' : 'Edit phone number')),
          ],
          if (phoneVerified) ...[
            TextFormField(
                controller: name,
                autofillHints: const [AutofillHints.name],
                inputFormatters: [NameTextInputFormatter()],
                decoration: InputDecoration(
                    labelText: ar ? 'الاسم الثلاثي' : 'Full Name'),
                validator: (value) =>
                    fullNameValidationError(value, isArabic: ar)),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
                initialValue: governorateId,
                decoration: InputDecoration(
                    labelText: ar ? 'محافظة السكن' : 'Residence Governorate'),
                items: List.generate(
                    governorates.length,
                    (index) => DropdownMenuItem(
                        value: governoratesEn[index]
                            .toLowerCase()
                            .replaceAll(' ', '-'),
                        child: Text(governorates[index]))).toList(),
                onChanged: (value) => setState(() => governorateId = value),
                validator: (value) => value == null
                    ? (ar ? 'اختر محافظة السكن' : 'Select your governorate')
                    : null),
            const SizedBox(height: 12),
            ListTile(
                tileColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                leading: const Icon(Icons.cake_outlined),
                title: Text(birthDate == null
                    ? (ar ? 'تاريخ الميلاد' : 'Date of Birth')
                    : _date(birthDate!)),
                onTap: pickBirthDate),
            const SizedBox(height: 12),
            TextFormField(
                controller: email,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                decoration: InputDecoration(
                    labelText: ar
                        ? 'البريد الإلكتروني (اختياري)'
                        : 'Email (optional)')),
            const SizedBox(height: 18),
            FilledButton(
                onPressed: loading ? null : submit,
                child: Text(loading
                    ? (ar ? 'جارٍ إنشاء الحساب...' : 'Creating...')
                    : (ar ? 'إنشاء الحساب' : 'Create Account'))),
          ],
          if (error != null)
            Text(error!, style: const TextStyle(color: AppColors.danger)),
        ]),
      ),
    );
  }
}

class NameTextInputFormatter extends TextInputFormatter {
  const NameTextInputFormatter();

  static final _allowedCharacter = RegExp(
      r'[A-Za-z\u0621-\u063A\u0641-\u064A\u0671-\u06D3\u064B-\u065F\u0670 ]');

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final filtered = String.fromCharCodes(newValue.text.runes.where(
        (rune) => _allowedCharacter.hasMatch(String.fromCharCode(rune))));
    final selectionOffset =
        newValue.selection.baseOffset.clamp(0, filtered.length);
    return newValue.copyWith(
      text: filtered,
      selection: TextSelection.collapsed(offset: selectionOffset),
      composing: TextRange.empty,
    );
  }
}

class _AuthFormShell extends StatelessWidget {
  const _AuthFormShell({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/auth');
            }
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

class BookingDetailsScreen extends ConsumerStatefulWidget {
  const BookingDetailsScreen({super.key});
  @override
  ConsumerState<BookingDetailsScreen> createState() =>
      _BookingDetailsScreenState();
}

class _BookingDetailsScreenState extends ConsumerState<BookingDetailsScreen> {
  final formKey = GlobalKey<FormState>();
  final name = TextEditingController();
  final phone = TextEditingController();
  final email = TextEditingController();
  final notes = TextEditingController();

  @override
  void initState() {
    super.initState();
    final appState = ref.read(appControllerProvider);
    final draft = appState.draft;
    final UserProfile user =
        appState.currentUser ?? ref.read(currentUserProvider);
    name.text = draft.guestName;
    phone.text = draft.phone.isEmpty ? user.phone : draft.phone;
    email.text = draft.email;
    notes.text = draft.notes ?? '';
  }

  @override
  void dispose() {
    name.dispose();
    phone.dispose();
    email.dispose();
    notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appControllerProvider);
    final ar = state.isArabic;
    return Directionality(
        textDirection: ar ? TextDirection.rtl : TextDirection.ltr,
        child: _PageShell(
            title: ar ? 'بيانات الحجز' : 'Booking details',
            child: Form(
                key: formKey,
                child: ListView(padding: const EdgeInsets.all(16), children: [
                  Text(ar ? 'معلومات الضيف الرئيسي' : 'Main guest information',
                      style: const TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 12),
                  TextFormField(
                      controller: name,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'[a-zA-Z\u0600-\u06FF ]')),
                      ],
                      decoration: InputDecoration(
                          labelText: ar ? 'اسم النزيل' : 'Guest name',
                          prefixIcon: const Icon(Icons.person_outline)),
                      validator: (v) => v == null || v.trim().length < 3
                          ? (ar ? 'أدخل اسمًا صحيحًا' : 'Enter a valid name')
                          : null),
                  const SizedBox(height: 12),
                  TextFormField(
                      controller: phone,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
                      ],
                      decoration: InputDecoration(
                          labelText: ar ? 'رقم الهاتف' : 'Phone',
                          prefixIcon: const Icon(Icons.phone_outlined)),
                      validator: (v) => v == null || v.trim().length < 8
                          ? (ar
                              ? 'أدخل رقم هاتف صحيحًا'
                              : 'Enter a valid phone')
                          : null),
                  const SizedBox(height: 12),
                  TextFormField(
                      controller: email,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                          labelText: ar
                              ? 'البريد الإلكتروني (اختياري)'
                              : 'Email (optional)',
                          prefixIcon: const Icon(Icons.email_outlined)),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) return null;
                        final validEmail = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                            .hasMatch(value.trim());
                        return validEmail
                            ? null
                            : (ar
                                ? 'أدخل بريدًا إلكترونيًا صحيحًا'
                                : 'Enter a valid email');
                      }),
                  const SizedBox(height: 12),
                  TextFormField(
                      controller: notes,
                      minLines: 3,
                      maxLines: 5,
                      decoration: InputDecoration(
                          labelText: ar ? 'ملاحظات' : 'Notes',
                          hintText: ar
                              ? 'إذا كانت لديك أي ملاحظات يمكنك كتابتها هنا'
                              : 'If you have any notes, you can write them here')),
                  const SizedBox(height: 18),
                  FilledButton(
                      onPressed: () {
                        if (formKey.currentState!.validate()) {
                          ref.read(appControllerProvider.notifier).setGuest(
                              name: name.text.trim(),
                              phone: phone.text.trim(),
                              email: email.text.trim(),
                              notes: notes.text.trim().isEmpty
                                  ? null
                                  : notes.text.trim());
                          context.push('/booking/summary');
                        }
                      },
                      child: Text(ar ? 'مراجعة الحجز' : 'Review booking')),
                ]))));
  }
}

class BookingSummaryScreen extends ConsumerWidget {
  const BookingSummaryScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appControllerProvider);
    final ar = state.isArabic;
    final d = state.draft;
    return Directionality(
        textDirection: ar ? TextDirection.rtl : TextDirection.ltr,
        child: _PageShell(
            title: ar ? 'ملخص الحجز' : 'Booking summary',
            child: ListView(padding: const EdgeInsets.all(16), children: [
              _SummaryRow(
                  label: ar ? 'الفندق' : 'Hotel',
                  value: d.hotel == null
                      ? '—'
                      : (ar ? d.hotel!.nameAr : d.hotel!.nameEn)),
              _SummaryRow(
                  label: ar ? 'الغرفة' : 'Room',
                  value: d.room == null
                      ? '—'
                      : (ar ? d.room!.nameAr : d.room!.nameEn)),
              _SummaryRow(label: ar ? 'النزيل' : 'Guest', value: d.guestName),
              if (d.notes?.isNotEmpty == true)
                _SummaryRow(label: ar ? 'ملاحظات' : 'Notes', value: d.notes!),
              if (d.criteria != null)
                _SummaryRow(
                    label: ar ? 'الإقامة' : 'Stay',
                    value:
                        '${_date(d.criteria!.checkIn)} → ${_date(d.criteria!.checkOut)} (${d.criteria!.nights} ${ar ? 'ليلة' : 'nights'})'),
              _SummaryRow(
                  label: ar ? 'الإجمالي' : 'Total',
                  value: _money(d.total, ar),
                  bold: true),
              const SizedBox(height: 18),
              FilledButton(
                  onPressed: d.hotel != null && d.room != null
                      ? () {
                          final booking = ref
                              .read(appControllerProvider.notifier)
                              .createBookingRequest();
                          context.push('/booking/waiting/${booking.reference}');
                        }
                      : null,
                  child: Text(ar ? 'إرسال طلب الحجز' : 'Send booking request')),
            ])));
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow(
      {required this.label, required this.value, this.bold = false});
  final String label;
  final String value;
  final bool bold;
  @override
  Widget build(BuildContext context) => Card(
        child: ListTile(
          title: Text(label),
          trailing: SizedBox(
            width: 180,
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontWeight: bold ? FontWeight.w900 : FontWeight.w600,
                color: bold ? AppColors.primary : null,
              ),
            ),
          ),
        ),
      );
}

class BookingConfirmationScreen extends ConsumerWidget {
  const BookingConfirmationScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appControllerProvider);
    final ar = state.isArabic;
    final userBooking = state.bookings
        .where((booking) => booking.userId == state.currentUser?.email)
        .firstOrNull;
    if (userBooking == null) {
      return Directionality(
        textDirection: ar ? TextDirection.rtl : TextDirection.ltr,
        child: _PageShell(
          title: ar ? 'تم الحجز' : 'Booking confirmed',
          child: _Empty(
              message: ar
                  ? 'لا يوجد حجز مؤكد لعرضه.'
                  : 'There is no confirmed booking to display.'),
        ),
      );
    }
    if (userBooking.status != BookingStatus.confirmed) {
      return BookingWaitingScreen(bookingId: userBooking.reference);
    }
    final r = userBooking;
    return Directionality(
        textDirection: ar ? TextDirection.rtl : TextDirection.ltr,
        child: _PageShell(
            title: ar ? 'تم الحجز' : 'Booking confirmed',
            child: ListView(padding: const EdgeInsets.all(20), children: [
              const Icon(Icons.check_circle,
                  size: 80, color: AppColors.success),
              const SizedBox(height: 12),
              Text(ar ? 'تم تأكيد حجزك بنجاح' : 'Your booking is confirmed',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              Text(r.reference,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary)),
              const SizedBox(height: 20),
              Center(
                  child: Container(
                      padding: const EdgeInsets.all(16),
                      color: Colors.white,
                      child:
                          QrImageView(data: r.qrVerificationToken, size: 190))),
              const SizedBox(height: 20),
              FilledButton(
                  onPressed: () {
                    ref
                        .read(appControllerProvider.notifier)
                        .clearBookingDraft();
                    context.go('/');
                  },
                  child: Text(ar ? 'العودة إلى الرئيسية' : 'Back to Home')),
            ])));
  }
}

class BookingWaitingScreen extends ConsumerWidget {
  const BookingWaitingScreen({super.key, required this.bookingId});
  final String bookingId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appControllerProvider);
    final ar = state.isArabic;
    final booking =
        state.bookings.where((item) => item.reference == bookingId).firstOrNull;
    if (booking == null || booking.userId != state.currentUser?.email) {
      return _PageShell(
          title: ar ? 'الحجز' : 'Booking',
          child:
              _Empty(message: ar ? 'الحجز غير موجود.' : 'Booking not found.'));
    }

    final hotel = booking.draft.hotel;
    final room = booking.draft.room;
    return Directionality(
      textDirection: ar ? TextDirection.rtl : TextDirection.ltr,
      child: _PageShell(
        title: ar ? 'حالة الحجز' : 'Booking status',
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            if (booking.status == BookingStatus.pendingHotelApproval)
              const Center(child: CircularProgressIndicator())
            else
              Icon(
                booking.status == BookingStatus.confirmed
                    ? Icons.check_circle
                    : Icons.info_outline,
                size: 76,
                color: booking.status == BookingStatus.rejected
                    ? AppColors.danger
                    : AppColors.primary,
              ),
            const SizedBox(height: 16),
            Text(
              hotel == null ? '—' : (ar ? hotel.nameAr : hotel.nameEn),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
            ),
            if (room != null) ...[
              const SizedBox(height: 6),
              Text(ar ? room.nameAr : room.nameEn, textAlign: TextAlign.center),
            ],
            const SizedBox(height: 14),
            Text(booking.reference, textAlign: TextAlign.center),
            const SizedBox(height: 18),
            Text(booking.status.label(ar),
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
            const SizedBox(height: 12),
            Text(_bookingStatusMessage(booking.status, ar),
                textAlign: TextAlign.center),
            if (booking.status == BookingStatus.rejected &&
                booking.rejectionReason != null &&
                booking.rejectionReason!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text('${ar ? 'السبب' : 'Reason'}: ${booking.rejectionReason}',
                  textAlign: TextAlign.center),
            ],
            if (booking.status == BookingStatus.confirmed) ...[
              const SizedBox(height: 20),
              Center(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.white,
                  child: QrImageView(
                    data: booking.qrVerificationToken,
                    size: 190,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                ar
                    ? 'اعرض رمز QR لموظف الفندق عند الوصول.'
                    : 'Show the QR code to hotel staff on arrival.',
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 24),
            if (booking.status == BookingStatus.pendingHotelApproval)
              OutlinedButton(
                onPressed: () => _showCancellationDialog(context, ref, booking),
                child: Text(ar ? 'إلغاء طلب الحجز' : 'Cancel booking request'),
              ),
            FilledButton(
              onPressed: () {
                ref.read(appControllerProvider.notifier).clearBookingDraft();
                context.go('/');
              },
              child: Text(ar ? 'العودة إلى الرئيسية' : 'Back to Home'),
            ),
          ],
        ),
      ),
    );
  }
}

String _bookingStatusMessage(BookingStatus status, bool isArabic) {
  if (isArabic) {
    return switch (status) {
      BookingStatus.pendingHotelApproval =>
        'تم إرسال طلبك إلى الفندق، وسيتم تحديث حالة الحجز بعد مراجعته.',
      BookingStatus.confirmed => 'تم قبول طلب الحجز. تم الحجز.',
      BookingStatus.rejected => 'تم رفض طلب الحجز',
      BookingStatus.cancelledByUser => 'تم إلغاء طلب الحجز',
      BookingStatus.completed => 'تم إغلاق الحجز',
    };
  }
  return switch (status) {
    BookingStatus.pendingHotelApproval =>
      'Your request was sent to the hotel and will update after review.',
    BookingStatus.confirmed => 'Your booking request was accepted. Confirmed.',
    BookingStatus.rejected => 'Your booking request was rejected.',
    BookingStatus.cancelledByUser => 'Your booking request was cancelled.',
    BookingStatus.completed => 'Your booking is closed.',
  };
}

Future<void> _showCancellationDialog(
    BuildContext context, WidgetRef ref, BookingRecord booking) async {
  final ar = ref.read(appControllerProvider).isArabic;
  final cancellationReason = await showDialog<String>(
    context: context,
    builder: (_) => _CancellationDialog(isArabic: ar),
  );
  if (!context.mounted || cancellationReason == null) return;

  ref.read(appControllerProvider.notifier).cancelBookingByUser(
        booking.reference,
        reason: cancellationReason.isEmpty ? null : cancellationReason,
      );
  if (context.mounted) context.go('/');
}

class _CancellationDialog extends StatefulWidget {
  const _CancellationDialog({required this.isArabic});
  final bool isArabic;

  @override
  State<_CancellationDialog> createState() => _CancellationDialogState();
}

class _CancellationDialogState extends State<_CancellationDialog> {
  final reason = TextEditingController();

  @override
  void dispose() {
    reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ar = widget.isArabic;
    return AlertDialog(
      title: Text(ar ? 'إلغاء طلب الحجز' : 'Cancel booking request'),
      content: TextField(
        controller: reason,
        maxLines: 3,
        decoration: InputDecoration(
            labelText: ar
                ? 'سبب الإلغاء (اختياري)'
                : 'Cancellation reason (optional)'),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(ar ? 'تراجع' : 'Back')),
        FilledButton(
            onPressed: () => Navigator.of(context).pop(reason.text.trim()),
            child: Text(ar ? 'إلغاء الطلب' : 'Cancel request')),
      ],
    );
  }
}

class MyBookingsScreen extends ConsumerWidget {
  const MyBookingsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appControllerProvider);
    final ar = state.isArabic;
    final userBookings = state.bookings
        .where((booking) => booking.userId == state.currentUser?.email)
        .toList();
    return Directionality(
      textDirection: ar ? TextDirection.rtl : TextDirection.ltr,
      child: _PageShell(
        title: ar ? 'حجوزاتي' : 'My bookings',
        child: userBookings.isEmpty
            ? _Empty(message: ar ? 'لا توجد حجوزات بعد.' : 'No bookings yet.')
            : ListView(
                padding: const EdgeInsets.all(16),
                children: userBookings.map((b) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Card(
                      child: ListTile(
                        leading: const CircleAvatar(child: Icon(Icons.hotel)),
                        title: Text(
                          b.draft.hotel == null
                              ? '—'
                              : (ar
                                  ? b.draft.hotel!.nameAr
                                  : b.draft.hotel!.nameEn),
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        subtitle: Text(
                          '${b.status.label(ar)}\n${b.reference}\n${b.draft.criteria == null ? '' : '${_date(b.draft.criteria!.checkIn)} → ${_date(b.draft.criteria!.checkOut)}'}',
                        ),
                        isThreeLine: true,
                        trailing: Chip(label: Text(b.status.label(ar))),
                        onTap: () =>
                            context.push('/booking/waiting/${b.reference}'),
                      ),
                    ),
                  );
                }).toList(),
              ),
      ),
    );
  }
}

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appControllerProvider);
    final ar = state.isArabic;
    final list = hotels.where((h) => state.favoriteIds.contains(h.id)).toList();
    return Directionality(
        textDirection: ar ? TextDirection.rtl : TextDirection.ltr,
        child: _PageShell(
            title: ar ? 'المفضلة' : 'Favorites',
            child: list.isEmpty
                ? _Empty(
                    message: ar
                        ? 'أضف فنادق إلى المفضلة لتظهر هنا.'
                        : 'Favorite hotels will appear here.')
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: list
                        .map((h) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _HotelCard(
                                hotel: h,
                                ar: ar,
                                favorite: true,
                                onFavorite: () => ref
                                    .read(appControllerProvider.notifier)
                                    .toggleFavorite(h.id),
                                onTap: () {
                                  ref
                                      .read(appControllerProvider.notifier)
                                      .selectHotel(h);
                                  context.push('/hotel/${h.id}');
                                })))
                        .toList())));
  }
}

class NearbyScreen extends ConsumerWidget {
  const NearbyScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appControllerProvider);
    final ar = state.isArabic;
    return Directionality(
        textDirection: ar ? TextDirection.rtl : TextDirection.ltr,
        child: _PageShell(
            title: ar ? 'الفنادق القريبة' : 'Nearby hotels',
            child: ListView(padding: const EdgeInsets.all(16), children: [
              Card(
                  child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(children: [
                        const Icon(Icons.location_on_outlined,
                            color: AppColors.primary),
                        const SizedBox(width: 12),
                        Expanded(
                            child: Text(ar
                                ? 'هذه النسخة التجريبية تعرض فنادق Mock. ربط GPS الحقيقي مخطط له في مرحلة الموقع.'
                                : 'This mock build shows sample hotels. Real GPS integration is planned for the location phase.'))
                      ]))),
              const SizedBox(height: 14),
              ...hotels.take(3).map((h) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _HotelCard(
                      hotel: h,
                      ar: ar,
                      favorite: state.favoriteIds.contains(h.id),
                      onFavorite: () => ref
                          .read(appControllerProvider.notifier)
                          .toggleFavorite(h.id),
                      onTap: () {
                        ref.read(appControllerProvider.notifier).selectHotel(h);
                        context.push('/hotel/${h.id}');
                      }))),
            ])));
  }
}

class ExploreScreen extends ConsumerWidget {
  const ExploreScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ar = ref.watch(appControllerProvider).isArabic;
    return Directionality(
      textDirection: ar ? TextDirection.rtl : TextDirection.ltr,
      child: _PageShell(
        title: ar ? 'اكتشف العراق' : 'Explore Iraq',
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: destinations.map((d) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 110,
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: .08),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Center(
                            child: Icon(Icons.landscape_outlined,
                                size: 54, color: AppColors.accent)),
                      ),
                      const SizedBox(height: 12),
                      Text(ar ? d.nameAr : d.nameEn,
                          style: const TextStyle(
                              fontSize: 19, fontWeight: FontWeight.w900)),
                      Text(ar ? d.governorateAr : d.governorateEn,
                          style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      Text(ar ? d.descriptionAr : d.descriptionEn),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appControllerProvider);
    final ar = state.isArabic;
    return Directionality(
        textDirection: ar ? TextDirection.rtl : TextDirection.ltr,
        child: _PageShell(
            title: ar ? 'الملف الشخصي' : 'Profile',
            child: ListView(padding: const EdgeInsets.all(16), children: [
              const CircleAvatar(
                  radius: 38,
                  backgroundColor: AppColors.primary,
                  child: Icon(Icons.person, color: Colors.white, size: 40)),
              const SizedBox(height: 14),
              Text(ar ? 'مستخدم حجوزاتي' : 'Hajozati User',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.w900)),
              if (state.currentUser != null) ...[
                const SizedBox(height: 8),
                Text(state.currentUser!.fullName,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.w800)),
                Text(state.currentUser!.phone, textAlign: TextAlign.center),
                if (state.currentUser!.email.isNotEmpty)
                  Text(state.currentUser!.email, textAlign: TextAlign.center),
                if (state.currentUser!.dateOfBirth != null)
                  Text(_date(state.currentUser!.dateOfBirth!),
                      textAlign: TextAlign.center),
                if (state.currentUser!.governorateId.isNotEmpty)
                  Text(state.currentUser!.governorateId,
                      textAlign: TextAlign.center),
              ],
              const SizedBox(height: 20),
              Card(
                  child: Column(children: [
                ListTile(
                    leading: const Icon(Icons.book_online_outlined),
                    title: Text(ar ? 'حجوزاتي' : 'My bookings'),
                    onTap: () => context.push('/bookings')),
                ListTile(
                    leading: const Icon(Icons.favorite_border),
                    title: Text(ar ? 'المفضلة' : 'Favorites'),
                    onTap: () => context.push('/favorites')),
                ListTile(
                    leading: const Icon(Icons.language),
                    title: Text(ar ? 'English' : 'العربية'),
                    onTap: () => ref
                        .read(appControllerProvider.notifier)
                        .toggleLanguage()),
                ListTile(
                    leading: const Icon(Icons.notifications_outlined),
                    title: Text(ar ? 'الإشعارات' : 'Notifications'),
                    subtitle: Text(ar
                        ? 'قريبًا عند ربط الخدمة'
                        : 'Planned for service integration')),
                ListTile(
                    leading: Icon(
                        state.isAuthenticated ? Icons.logout : Icons.login),
                    title: Text(state.isAuthenticated
                        ? (ar ? 'تسجيل الخروج' : 'Sign out')
                        : (ar ? 'تسجيل الدخول' : 'Sign in')),
                    onTap: () {
                      if (state.isAuthenticated) {
                        ref
                            .read(appControllerProvider.notifier)
                            .signOutAndClearSession();
                        context.go('/');
                      } else {
                        context.push('/login');
                      }
                    }),
              ])),
            ])));
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.message});
  final String message;
  @override
  Widget build(BuildContext context) => Center(
      child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.inbox_outlined, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center)
          ])));
}
