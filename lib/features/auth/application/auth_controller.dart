import 'dart:async';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/firebase_service.dart';
import '../../../core/services/user_profile_repository.dart';
import '../../../models/app_user.dart';

class AuthState {
  const AuthState({
    this.loading = false,
    this.isAuthenticated = false,
    this.onboardingCompleted = false,
    this.user,
    this.errorMessage,
  });

  final bool loading;
  final bool isAuthenticated;
  final bool onboardingCompleted;
  final AppUser? user;
  final String? errorMessage;

  AuthState copyWith({
    bool? loading,
    bool? isAuthenticated,
    bool? onboardingCompleted,
    AppUser? user,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AuthState(
      loading: loading ?? this.loading,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      user: user ?? this.user,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class AuthController extends StateNotifier<AuthState> {
  AuthController(
    Ref ref, {
    FirebaseAuth? auth,
    UserProfileRepository? profiles,
    FirebaseFunctions? functions,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _profiles = profiles ?? UserProfileRepository(),
       _functions = functions ?? FirebaseService.functions,
       super(const AuthState()) {
    _authSubscription = _auth.authStateChanges().listen(_onAuthUserChanged);
  }

  final FirebaseAuth _auth;
  final UserProfileRepository _profiles;
  final FirebaseFunctions _functions;
  late final StreamSubscription<User?> _authSubscription;
  StreamSubscription<AppUser>? _profileSubscription;
  bool _seedAttempted = false;

  Future<void> completeOnboarding() async {
    state = state.copyWith(onboardingCompleted: true);
  }

  Future<void> loginWithEmail({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(
        loading: false,
        errorMessage: _messageForAuthError(e),
      );
      rethrow;
    }
  }

  Future<void> registerWithEmail({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(
        loading: false,
        errorMessage: _messageForAuthError(e),
      );
      rethrow;
    }
  }

  void updateUser(AppUser user) {
    state = state.copyWith(user: user);
    unawaited(_profiles.saveUser(user));
  }

  Future<void> logout() async {
    await _profileSubscription?.cancel();
    _profileSubscription = null;
    await _auth.signOut();
    state = AuthState(onboardingCompleted: state.onboardingCompleted);
  }

  static AppUser _fromFirebaseUser(User? user) {
    if (user == null) {
      return const AppUser(id: 'guest', name: 'Convidado');
    }

    final fallbackName = (user.email?.split('@').first ?? 'Discípulo').trim();
    return AppUser(
      id: user.uid,
      name: (user.displayName?.isNotEmpty ?? false)
          ? user.displayName!
          : fallbackName,
      avatarUrl: user.photoURL,
    );
  }

  Future<void> _onAuthUserChanged(User? firebaseUser) async {
    if (firebaseUser == null) {
      await _profileSubscription?.cancel();
      _profileSubscription = null;
      state = AuthState(onboardingCompleted: state.onboardingCompleted);
      return;
    }

    state = state.copyWith(
      loading: true,
      isAuthenticated: true,
      user: _fromFirebaseUser(firebaseUser),
      clearError: true,
    );

    final user = await _profiles.ensureUser(firebaseUser);
    await _profileSubscription?.cancel();
    _profileSubscription = _profiles
        .watchUser(firebaseUser.uid)
        .listen(
          (profile) {
            state = state.copyWith(
              loading: false,
              isAuthenticated: true,
              user: profile,
              clearError: true,
            );
          },
          onError: (_) {
            state = state.copyWith(loading: false, user: user);
          },
        );

    if (!_seedAttempted) {
      _seedAttempted = true;
      unawaited(_seedGlobalContent());
    }
  }

  Future<void> _seedGlobalContent() async {
    try {
      final callable = _functions.httpsCallable('seedInitialContent');
      await callable.call();
    } catch (_) {
      // Seed é best-effort para evitar bloquear login em ambientes sem deploy.
    }
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    _profileSubscription?.cancel();
    super.dispose();
  }

  String _messageForAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'Usuário não encontrado. Crie uma conta.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'E-mail ou senha inválidos.';
      case 'email-already-in-use':
        return 'Este e-mail já está em uso.';
      case 'weak-password':
        return 'Senha fraca. Use ao menos 6 caracteres.';
      case 'invalid-email':
        return 'E-mail inválido.';
      default:
        return e.message ?? 'Falha de autenticação.';
    }
  }
}

final authControllerProvider = StateNotifierProvider<AuthController, AuthState>(
  (ref) {
    return AuthController(ref);
  },
);

final currentUserProvider = Provider<AppUser?>((ref) {
  return ref.watch(authControllerProvider).user;
});
