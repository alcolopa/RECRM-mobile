import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';

class ApiClient {
  late Dio dio;
  final FlutterSecureStorage storage = const FlutterSecureStorage();

  // Use 10.0.2.2 for Android Emulator, localhost for iOS/Web
  static String get baseUrl {
    final apiEnv = kIsWeb
        ? 'API_URL'
        : (Platform.isAndroid ? 'API_URL_ANDROID' : 'API_URL');
    return dotenv.env[apiEnv] ?? 'http://localhost:3000';
  }

  static String get workspaceSuffix {
    return dotenv.env['WORKSPACE_SUFFIX'] ?? '.estatehub.com';
  }

  ApiClient() {
    dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await storage.read(key: 'auth_token');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException e, handler) {
          if (e.response?.statusCode == 401) {
            // Handle unauthorized (e.g., clear token and redirect to login)
            storage.delete(key: 'auth_token');
          }
          return handler.next(e);
        },
      ),
    );
  }

  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      return await dio.post(path, data: data, queryParameters: queryParameters);
    } on DioException {
      rethrow;
    }
  }

  Future<Response> patch(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      return await dio.patch(
        path,
        data: data,
        queryParameters: queryParameters,
      );
    } on DioException {
      rethrow;
    }
  }

  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      return await dio.get(path, queryParameters: queryParameters);
    } on DioException {
      rethrow;
    }
  }

  Future<Response> delete(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      return await dio.delete(path, queryParameters: queryParameters);
    } on DioException {
      rethrow;
    }
  }
}
