import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/screens.dart';
import '../core/models.dart';
import 'state.dart';
import 'theme.dart';

Widget _protectedRoute(BuildContext context, Widget child) {
  final appState =
      ProviderScope.containerOf(context).read(appControllerProvider);
  return appState.authStatus == AuthStatus.authenticated
      ? child
      : const AuthRequiredScreen();
}

Widget _homeOrAuth(BuildContext context) {
  final state = ProviderScope.containerOf(context).read(appControllerProvider);
  return state.authStatus != AuthStatus.unauthenticated
      ? const HomeScreen()
      : const AuthEntryScreen();
}

GoRouter _createRouter(ValueNotifier<int> authRouterRefresh) {
  return GoRouter(
    initialLocation: '/',
    refreshListenable: authRouterRefresh,
    redirect: (context, state) {
      final appState =
          ProviderScope.containerOf(context).read(appControllerProvider);
      final authLocation = state.matchedLocation == '/auth' ||
          state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';
      if (appState.authStatus == AuthStatus.unauthenticated && !authLocation) {
        return '/auth';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (context, __) => _homeOrAuth(context)),
      GoRoute(path: '/auth', builder: (_, __) => const AuthEntryScreen()),
      GoRoute(
          path: '/results', builder: (_, __) => const SearchResultsScreen()),
      GoRoute(
          path: '/hotel/:id',
          builder: (_, s) =>
              HotelDetailsScreen(hotelId: s.pathParameters['id']!)),
      GoRoute(path: '/rooms', builder: (_, __) => const RoomSelectionScreen()),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
      GoRoute(
          path: '/booking/details',
          builder: (context, __) =>
              _protectedRoute(context, const BookingDetailsScreen())),
      GoRoute(
          path: '/booking/summary',
          builder: (context, __) =>
              _protectedRoute(context, const BookingSummaryScreen())),
      GoRoute(
          path: '/booking/confirmation',
          builder: (context, __) =>
              _protectedRoute(context, const BookingConfirmationScreen())),
      GoRoute(
          path: '/booking/waiting/:bookingId',
          builder: (_, state) => BookingWaitingScreen(
              bookingId: state.pathParameters['bookingId']!)),
      GoRoute(
          path: '/bookings',
          builder: (context, __) =>
              _protectedRoute(context, const MyBookingsScreen())),
      GoRoute(path: '/favorites', builder: (_, __) => const FavoritesScreen()),
      GoRoute(path: '/nearby', builder: (_, __) => const NearbyScreen()),
      GoRoute(path: '/explore', builder: (_, __) => const ExploreScreen()),
      GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
    ],
  );
}

class HajozatiApp extends ConsumerStatefulWidget {
  const HajozatiApp({super.key});

  @override
  ConsumerState<HajozatiApp> createState() => _HajozatiAppState();
}

class _HajozatiAppState extends ConsumerState<HajozatiApp> {
  late final ValueNotifier<int> _authRouterRefresh;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _authRouterRefresh = ValueNotifier<int>(0);
    _router = _createRouter(_authRouterRefresh);
    ref.listenManual<AppState>(appControllerProvider, (previous, next) {
      if (previous?.authStatus != next.authStatus) {
        _authRouterRefresh.value++;
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(appControllerProvider.notifier).restorePersistedSession();
      }
    });
  }

  @override
  void dispose() {
    _router.dispose();
    _authRouterRefresh.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Hajozati',
      theme: buildTheme(),
      routerConfig: _router,
    );
  }
}
