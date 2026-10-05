import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiClient {
  static const baseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'https://syncup-api-production.up.railway.app/api/v1',
  );
  final storage = const FlutterSecureStorage();
  late final Dio dio;
  Future<String?>? _refreshInFlight;
  ApiClient() {
    dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 20),
      ),
    );
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (o, h) async {
          final token = await storage.read(key: 'accessToken');
          if (token != null) o.headers['Authorization'] = 'Bearer $token';
          h.next(o);
        },
        onError: (e, h) async {
          if (e.response?.statusCode == 401 &&
              !e.requestOptions.path.startsWith('/auth/')) {
            final token = await _refreshAccessToken();
            if (token != null) {
              e.requestOptions.headers['Authorization'] = 'Bearer $token';
              return h.resolve(await dio.fetch(e.requestOptions));
            }
          }
          h.next(e);
        },
      ),
    );
  }

  Future<String?> _refreshAccessToken() {
    return _refreshInFlight ??= _performRefresh().whenComplete(
      () => _refreshInFlight = null,
    );
  }

  Future<String?> _performRefresh() async {
    final refreshToken = await storage.read(key: 'refreshToken');
    if (refreshToken == null) return null;
    try {
      final refreshClient = Dio(BaseOptions(baseUrl: baseUrl));
      final response = await refreshClient.post(
        '/auth/refresh',
        data: {'refreshToken': refreshToken},
      );
      await saveTokens(Map<String, dynamic>.from(response.data));
      return response.data['accessToken'];
    } catch (_) {
      await clear();
      return null;
    }
  }

  Future<void> saveTokens(Map<String, dynamic> data) async {
    await storage.write(key: 'accessToken', value: data['accessToken']);
    if (data['refreshToken'] != null) {
      await storage.write(key: 'refreshToken', value: data['refreshToken']);
    }
  }

  Future<void> clear() => storage.deleteAll();
}
