import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'dart:convert';

class ApiService extends ChangeNotifier {
  late Dio _dio;
  String? _authToken;
  
  static const String baseUrl = 'http://localhost:8000/api/v1';
  
  ApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
      },
    ));
    
    _setupInterceptors();
  }
  
  void _setupInterceptors() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (_authToken != null) {
            options.headers['Authorization'] = 'Bearer $_authToken';
          }
          debugPrint('REQUEST: ${options.method} ${options.path}');
          handler.next(options);
        },
        onResponse: (response, handler) {
          debugPrint('RESPONSE: ${response.statusCode} ${response.requestOptions.path}');
          handler.next(response);
        },
        onError: (error, handler) {
          debugPrint('ERROR: ${error.response?.statusCode} ${error.requestOptions.path}');
          handler.next(error);
        },
      ),
    );
  }
  
  void setAuthToken(String token) {
    _authToken = token;
    notifyListeners();
  }
  
  void clearAuthToken() {
    _authToken = null;
    notifyListeners();
  }
  
  // Auth endpoints
  Future<Map<String, dynamic>> loginWithEmail(String email, String password) async {
    try {
      final response = await _dio.post('/auth/login', data: {
        'email': email,
        'password': password,
      });
      
      return {
        'success': true,
        'data': response.data,
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data['detail'] ?? 'Login failed',
      };
    }
  }
  
  Future<Map<String, dynamic>> registerWithEmail(String email, String password, String fullName) async {
    try {
      final response = await _dio.post('/auth/register', data: {
        'email': email,
        'password': password,
        'full_name': fullName,
      });
      
      return {
        'success': true,
        'data': response.data,
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data['detail'] ?? 'Registration failed',
      };
    }
  }
  
  Future<Map<String, dynamic>> loginWithOAuth(String provider, String accessToken) async {
    try {
      final response = await _dio.post('/auth/login/oauth', data: {
        'provider': provider,
        'access_token': accessToken,
      });
      
      return {
        'success': true,
        'data': response.data,
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data['detail'] ?? 'OAuth login failed',
      };
    }
  }
  
  Future<Map<String, dynamic>> getUserProfile() async {
    try {
      final response = await _dio.get('/auth/me');
      
      return {
        'success': true,
        'data': response.data,
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data['detail'] ?? 'Failed to get profile',
      };
    }
  }
  
  // Points endpoints
  Future<Map<String, dynamic>> getPoints({
    double? latitude,
    double? longitude,
    double? radius,
    String? query,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (latitude != null) queryParams['latitude'] = latitude;
      if (longitude != null) queryParams['longitude'] = longitude;
      if (radius != null) queryParams['radius_km'] = radius;
      if (query != null) queryParams['query'] = query;
      
      final response = await _dio.get('/points', queryParameters: queryParams);
      
      return {
        'success': true,
        'data': response.data,
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data['detail'] ?? 'Failed to get points',
      };
    }
  }
  
  Future<Map<String, dynamic>> getPointDetails(int pointId) async {
    try {
      final response = await _dio.get('/points/$pointId');
      
      return {
        'success': true,
        'data': response.data,
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data['detail'] ?? 'Failed to get point details',
      };
    }
  }
  
  Future<Map<String, dynamic>> createOrder({
    required int pointId,
    int? cashierId,
    String? description,
    DateTime? scheduledTime,
  }) async {
    try {
      final data = <String, dynamic>{
        'point_id': pointId,
        'order_type': scheduledTime != null ? 'scheduled' : 'immediate',
      };
      
      if (cashierId != null) data['cashier_id'] = cashierId;
      if (description != null) data['description'] = description;
      if (scheduledTime != null) data['scheduled_time'] = scheduledTime.toIso8601String();
      
      final response = await _dio.post('/orders', data: data);
      
      return {
        'success': true,
        'data': response.data,
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data['detail'] ?? 'Failed to create order',
      };
    }
  }
  
  Future<Map<String, dynamic>> getUserOrders() async {
    try {
      final response = await _dio.get('/orders');
      
      return {
        'success': true,
        'data': response.data,
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data['detail'] ?? 'Failed to get orders',
      };
    }
  }
}