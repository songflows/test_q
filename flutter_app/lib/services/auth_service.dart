import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'dart:convert';

import '../models/user.dart';
import '../models/auth_token.dart';
import 'api_service.dart';

class AuthService extends ChangeNotifier {
  User? _currentUser;
  AuthToken? _token;
  bool _isLoading = true;
  bool _isAuthenticated = false;

  // Getters
  User? get currentUser => _currentUser;
  AuthToken? get token => _token;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isAuthenticated;

  // Google Sign In
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  AuthService() {
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    try {
      await _loadTokenFromStorage();
      if (_token != null && !_token!.isExpired) {
        await _loadUserProfile();
        _isAuthenticated = true;
      } else {
        await _clearAuthData();
      }
    } catch (e) {
      debugPrint('Error initializing auth: $e');
      await _clearAuthData();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadTokenFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final tokenData = prefs.getString('auth_token');
    
    if (tokenData != null) {
      try {
        _token = AuthToken.fromJson(jsonDecode(tokenData));
      } catch (e) {
        debugPrint('Error parsing token: $e');
      }
    }
  }

  Future<void> _saveTokenToStorage() async {
    final prefs = await SharedPreferences.getInstance();
    if (_token != null) {
      await prefs.setString('auth_token', jsonEncode(_token!.toJson()));
    } else {
      await prefs.remove('auth_token');
    }
  }

  Future<void> _loadUserProfile() async {
    if (_token == null) return;
    
    try {
      final apiService = ApiService();
      apiService.setAuthToken(_token!.accessToken);
      
      final userResponse = await apiService.getUserProfile();
      if (userResponse['success']) {
        _currentUser = User.fromJson(userResponse['data']);
      }
    } catch (e) {
      debugPrint('Error loading user profile: $e');
    }
  }

  Future<bool> loginWithEmail(String email, String password) async {
    try {
      _isLoading = true;
      notifyListeners();

      final apiService = ApiService();
      final response = await apiService.loginWithEmail(email, password);

      if (response['success']) {
        _token = AuthToken.fromJson(response['data']);
        _currentUser = User.fromJson(response['data']['user']);
        
        await _saveTokenToStorage();
        _isAuthenticated = true;
        
        return true;
      } else {
        return false;
      }
    } catch (e) {
      debugPrint('Error logging in: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> registerWithEmail(String email, String password, String fullName) async {
    try {
      _isLoading = true;
      notifyListeners();

      final apiService = ApiService();
      final response = await apiService.registerWithEmail(email, password, fullName);

      if (response['success']) {
        _token = AuthToken.fromJson(response['data']);
        _currentUser = User.fromJson(response['data']['user']);
        
        await _saveTokenToStorage();
        _isAuthenticated = true;
        
        return true;
      } else {
        return false;
      }
    } catch (e) {
      debugPrint('Error registering: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> loginWithGoogle() async {
    try {
      _isLoading = true;
      notifyListeners();

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return false;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final String? accessToken = googleAuth.accessToken;

      if (accessToken == null) return false;

      final apiService = ApiService();
      final response = await apiService.loginWithOAuth('google', accessToken);

      if (response['success']) {
        _token = AuthToken.fromJson(response['data']);
        _currentUser = User.fromJson(response['data']['user']);
        
        await _saveTokenToStorage();
        _isAuthenticated = true;
        
        return true;
      } else {
        await _googleSignIn.signOut();
        return false;
      }
    } catch (e) {
      debugPrint('Error logging in with Google: $e');
      await _googleSignIn.signOut();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> loginWithFacebook() async {
    try {
      _isLoading = true;
      notifyListeners();

      final LoginResult result = await FacebookAuth.instance.login();
      
      if (result.status == LoginStatus.success && result.accessToken != null) {
        final String accessToken = result.accessToken!.token;

        final apiService = ApiService();
        final response = await apiService.loginWithOAuth('facebook', accessToken);

        if (response['success']) {
          _token = AuthToken.fromJson(response['data']);
          _currentUser = User.fromJson(response['data']['user']);
          
          await _saveTokenToStorage();
          _isAuthenticated = true;
          
          return true;
        } else {
          await FacebookAuth.instance.logOut();
          return false;
        }
      }
      
      return false;
    } catch (e) {
      debugPrint('Error logging in with Facebook: $e');
      await FacebookAuth.instance.logOut();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    try {
      // Sign out from OAuth providers
      await _googleSignIn.signOut();
      await FacebookAuth.instance.logOut();
      
      await _clearAuthData();
    } catch (e) {
      debugPrint('Error logging out: $e');
    }
  }

  Future<void> _clearAuthData() async {
    _token = null;
    _currentUser = null;
    _isAuthenticated = false;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    
    notifyListeners();
  }

  String? getAuthToken() {
    return _token?.accessToken;
  }

  bool isTokenValid() {
    return _token != null && !_token!.isExpired;
  }
}