import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/domain/entities.dart';
import '../../../core/error/app_failure.dart';
import '../../../features/settings/application/settings_controller.dart';
import '../data/auth_repository.dart';

class AuthState {
  final bool isLoading;
  final UserEntity? user;
  final AppFailure? error;

  const AuthState({
    this.isLoading = false,
    this.user,
    this.error,
  });

  AuthState copyWith({bool? isLoading, UserEntity? user, AppFailure? error, bool clearError = false, bool clearUser = false}) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      user: clearUser ? null : (user ?? this.user),
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class AuthController extends Notifier<AuthState> {
  @override
  AuthState build() {
    _bootstrap();
    return const AuthState(isLoading: true);
  }

  Future<void> _bootstrap() async {
    final auth = ref.read(authRepositoryProvider);
    final user = await auth.currentUser();
    state = AuthState(user: user);
    if (user != null) {
      unawaited(_pushAndPull());
    }
  }

  Future<void> login({required String email, required String password}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final user = await ref.read(authRepositoryProvider).login(
            email: email,
            password: password,
          );
      state = AuthState(user: user);
      unawaited(_pushAndPull());
    } on AppFailure catch (e) {
      state = state.copyWith(isLoading: false, error: e);
    }
  }

  Future<void> signup({
    required String email,
    required String password,
    required String timezone,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final user = await ref.read(authRepositoryProvider).signup(
            email: email,
            password: password,
            timezone: timezone,
          );
      state = AuthState(user: user);
      unawaited(_pushAndPull());
    } on AppFailure catch (e) {
      state = state.copyWith(isLoading: false, error: e);
    }
  }

  Future<void> logout() async {
    await ref.read(authRepositoryProvider).logout();
    state = const AuthState();
  }

  /// Push local outbox, then pull server changes since last pull.
  Future<void> _pushAndPull() async {
    final sync = ref.read(syncServiceProvider);
    final settings = ref.read(settingsControllerProvider);
    final lastPulled = settings.value?.lastPulledAt;
    await sync.drainOutbox();
    final serverTime = await sync.pull(since: lastPulled);
    await ref.read(settingsControllerProvider.notifier).setLastPulledAt(serverTime);
  }
}

final authControllerProvider =
    NotifierProvider<AuthController, AuthState>(AuthController.new);