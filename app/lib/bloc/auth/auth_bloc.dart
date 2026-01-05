import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/auth_service.dart';
import '../../models/user.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthService authService;

  AuthBloc({required this.authService}) : super(AuthInitial()) {
    on<AuthLoginRequested>(_onLoginRequested);
    on<AuthRegisterRequested>(_onRegisterRequested);
    on<AuthLogoutRequested>(_onLogoutRequested);
    on<AuthCheckRequested>(_onCheckRequested);
    on<AuthTokenLoaded>(_onTokenLoaded);
  }

  Future<void> _onLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    final result = await authService.login(
      email: event.email,
      password: event.password,
      fcmToken: event.fcmToken,
    );

    if (result['success']) {
      final user = User(email: event.email, token: result['token']);
      emit(AuthAuthenticated(user));
    } else {
      emit(AuthError(result['message'] ?? 'Đăng nhập thất bại'));
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onRegisterRequested(
    AuthRegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    final result = await authService.register(
      email: event.email,
      password: event.password,
      fullName: event.fullName,
    );

    if (result['success']) {
      emit(AuthRegistrationSuccess(result['message'] ?? 'Đăng ký thành công'));
      emit(AuthUnauthenticated());
    } else {
      emit(AuthError(result['message'] ?? 'Đăng ký thất bại'));
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    await authService.logout();
    emit(AuthUnauthenticated());
  }

  Future<void> _onCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    final token = await authService.getToken();
    if (token != null && token.isNotEmpty) {
      add(AuthTokenLoaded(token));
    } else {
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onTokenLoaded(
    AuthTokenLoaded event,
    Emitter<AuthState> emit,
  ) async {
    // Có thể gọi API để lấy thông tin user từ token
    final user = User(
      email: '', // TODO: Lấy từ API
      token: event.token,
    );
    emit(AuthAuthenticated(user));
  }
}
