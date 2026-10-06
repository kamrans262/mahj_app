import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/storage/token_store.dart';
import '../../profile/domain/profile_data.dart';
import '../domain/auth_flow_args.dart';
import '../domain/auth_user.dart';

class AuthRepository {
  factory AuthRepository({
    required ApiClient apiClient,
    required TokenStore tokenStore,
  }) {
    return AuthRepository._(apiClient, tokenStore);
  }

  AuthRepository._(this._apiClient, this._tokenStore);

  final ApiClient _apiClient;
  final TokenStore _tokenStore;

  AuthUser? currentUser;

  Future<void> requestRegistrationOtp({
    required String name,
    required String email,
    required String password,
  }) async {
    await _apiClient.post(
      '/auth/register/request-otp',
      authenticated: false,
      body: {
        'name': name,
        'email': email,
        'password': password,
        'password_confirmation': password,
      },
    );
  }

  Future<AuthUser> verifyRegistrationOtp({
    required String email,
    required String otp,
  }) async {
    final payload = await _apiClient.post(
      '/auth/register/verify-otp',
      authenticated: false,
      body: {'email': email, 'otp': otp},
    );

    return _storeSession(payload);
  }

  Future<AuthUser> login({
    required String email,
    required String password,
  }) async {
    final payload = await _apiClient.post(
      '/auth/login',
      authenticated: false,
      body: {'email': email, 'password': password},
    );

    return _storeSession(payload);
  }

  Future<AuthUser> loginWithGoogle({
    required String idToken,
  }) async {
    final payload = await _apiClient.post(
      '/auth/google',
      authenticated: false,
      body: {'id_token': idToken},
    );

    return _storeSession(payload);
  }

  Future<void> requestPasswordResetOtp(String email) async {
    await _apiClient.post(
      '/auth/forgot-password/request-otp',
      authenticated: false,
      body: {'email': email},
    );
  }

  Future<String> verifyPasswordResetOtp({
    required String email,
    required String otp,
  }) async {
    final payload = await _apiClient.post(
      '/auth/forgot-password/verify-otp',
      authenticated: false,
      body: {'email': email, 'otp': otp},
    );

    final token = payload['reset_token']?.toString();
    if (token == null || token.isEmpty) {
      throw const ApiException(
        message: 'The password reset session could not be created.',
        statusCode: 500,
      );
    }

    return token;
  }

  Future<void> resetPassword({
    required String email,
    required String resetToken,
    required String password,
  }) async {
    await _apiClient.post(
      '/auth/forgot-password/reset',
      authenticated: false,
      body: {
        'email': email,
        'reset_token': resetToken,
        'password': password,
        'password_confirmation': password,
      },
    );
  }

  Future<void> resendOtp({
    required String email,
    required OtpPurpose purpose,
  }) async {
    await _apiClient.post(
      '/auth/otp/resend',
      authenticated: false,
      body: {'email': email, 'purpose': purpose.apiValue},
    );
  }

  Future<bool> restoreSession() async {
    final token = await _tokenStore.read();
    if (token == null || token.isEmpty) {
      currentUser = null;
      return false;
    }

    try {
      final payload = await _apiClient.get('/user');
      currentUser = AuthUser.fromJson(_readMap(payload, 'data'));
      return true;
    } on ApiException catch (error) {
      if (error.statusCode == 401) {
        await _tokenStore.clear();
        currentUser = null;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<void> logout() async {
    try {
      await _apiClient.post('/auth/logout');
    } finally {
      await _tokenStore.clear();
      currentUser = null;
    }
  }

  Future<ProfileData> updateProfile(ProfileData draft) async {
    final payload = await _apiClient.put(
      '/profile',
      body: {
        'name': draft.name,
        'phone': draft.phone,
        'zip_code': draft.postCode,
        'city': draft.city,
        'state': draft.state,
        'bio': draft.bio,
      },
    );

    final user = AuthUser.fromJson(_readMap(payload, 'data'));
    currentUser = user;
    return user.toProfileData();
  }

  Future<AuthUser> changeEmail(String email) async {
    final payload = await _apiClient.put(
      '/account/email',
      body: {'email': email},
    );
    final user = AuthUser.fromJson(_readMap(payload, 'data'));
    currentUser = user;
    return user;
  }

  Future<void> changePassword(String password) async {
    await _apiClient.put(
      '/account/password',
      body: {'password': password, 'password_confirmation': password},
    );
  }

  Future<void> deleteAccount() async {
    await _apiClient.delete('/account');
    await _tokenStore.clear();
    currentUser = null;
  }

  Future<AuthUser> _storeSession(Map<String, dynamic> payload) async {
    final token = payload['token']?.toString();
    if (token == null || token.isEmpty) {
      throw const ApiException(
        message: 'Authentication token was not returned by the server.',
        statusCode: 500,
      );
    }

    final user = AuthUser.fromJson(_readMap(payload, 'user'));
    await _tokenStore.write(token);
    currentUser = user;
    return user;
  }

  Map<String, dynamic> _readMap(Map<String, dynamic> payload, String key) {
    final value = payload[key];
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map(
        (entryKey, entryValue) => MapEntry(entryKey.toString(), entryValue),
      );
    }

    throw ApiException(
      message: 'The server returned an invalid $key response.',
      statusCode: 500,
    );
  }
}
