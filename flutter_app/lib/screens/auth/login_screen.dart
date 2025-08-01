import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/auth_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/social_login_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  bool _isLogin = true;
  bool _isLoading = false;
  
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  
  @override
  void initState() {
    super.initState();
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));
    
    _fadeController.forward();
  }
  
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 60),
                  
                  // Logo and Title
                  _buildHeader(),
                  
                  const SizedBox(height: 48),
                  
                  // Toggle between Login/Register
                  _buildToggle(),
                  
                  const SizedBox(height: 32),
                  
                  // Email Field
                  _buildEmailField(),
                  
                  const SizedBox(height: 16),
                  
                  // Password Field
                  _buildPasswordField(),
                  
                  const SizedBox(height: 24),
                  
                  // Login/Register Button
                  _buildSubmitButton(),
                  
                  const SizedBox(height: 32),
                  
                  // Divider
                  _buildDivider(),
                  
                  const SizedBox(height: 32),
                  
                  // Social Login Buttons
                  _buildSocialLogins(),
                  
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildHeader() {
    return Column(
      children: [
        // Logo
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppTheme.primaryColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryColor.withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(
            Icons.queue_outlined,
            size: 40,
            color: Colors.white,
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Title
        Text(
          _isLogin ? 'Добро пожаловать!' : 'Создать аккаунт',
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        
        const SizedBox(height: 8),
        
        // Subtitle
        Text(
          _isLogin 
            ? 'Войдите в свой аккаунт' 
            : 'Зарегистрируйтесь, чтобы начать',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppTheme.textSecondaryColor,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
  
  Widget _buildToggle() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _isLogin = true),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: _isLogin ? AppTheme.primaryColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Вход',
                  style: TextStyle(
                    color: _isLogin ? Colors.white : AppTheme.textSecondaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _isLogin = false),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: !_isLogin ? AppTheme.primaryColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Регистрация',
                  style: TextStyle(
                    color: !_isLogin ? Colors.white : AppTheme.textSecondaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildEmailField() {
    return CustomTextField(
      controller: _emailController,
      label: 'Email',
      keyboardType: TextInputType.emailAddress,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Введите email';
        }
        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
          return 'Введите корректный email';
        }
        return null;
      },
    );
  }
  
  Widget _buildPasswordField() {
    return CustomTextField(
      controller: _passwordController,
      label: 'Пароль',
      isPassword: true,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Введите пароль';
        }
        if (!_isLogin && value.length < 8) {
          return 'Пароль должен содержать минимум 8 символов';
        }
        return null;
      },
    );
  }
  
  Widget _buildSubmitButton() {
    return CustomButton(
      text: _isLogin ? 'Войти' : 'Зарегистрироваться',
      isLoading: _isLoading,
      onPressed: _handleSubmit,
    );
  }
  
  Widget _buildDivider() {
    return Row(
      children: [
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'или',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        const Expanded(child: Divider()),
      ],
    );
  }
  
  Widget _buildSocialLogins() {
    return Column(
      children: [
        SocialLoginButton(
          text: 'Продолжить с Google',
          icon: Icons.g_mobiledata, // Placeholder icon
          color: Colors.white,
          textColor: Colors.black87,
          borderColor: AppTheme.textTertiaryColor,
          onPressed: _handleGoogleLogin,
        ),
        
        const SizedBox(height: 12),
        
        SocialLoginButton(
          text: 'Продолжить с Facebook',
          icon: Icons.facebook,
          color: const Color(0xFF1877F2),
          textColor: Colors.white,
          onPressed: _handleFacebookLogin,
        ),
      ],
    );
  }
  
  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      bool success;
      
      if (_isLogin) {
        success = await authService.loginWithEmail(
          _emailController.text.trim(),
          _passwordController.text,
        );
      } else {
        success = await authService.registerWithEmail(
          _emailController.text.trim(),
          _passwordController.text,
          '', // Full name can be added later
        );
      }
      
      if (success && mounted) {
        Navigator.of(context).pushReplacementNamed('/home');
      } else if (mounted) {
        _showErrorSnackBar(_isLogin ? 'Ошибка входа' : 'Ошибка регистрации');
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Произошла ошибка: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  
  Future<void> _handleGoogleLogin() async {
    setState(() => _isLoading = true);
    
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final success = await authService.loginWithGoogle();
      
      if (success && mounted) {
        Navigator.of(context).pushReplacementNamed('/home');
      } else if (mounted) {
        _showErrorSnackBar('Ошибка входа через Google');
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Произошла ошибка: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  
  Future<void> _handleFacebookLogin() async {
    setState(() => _isLoading = true);
    
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final success = await authService.loginWithFacebook();
      
      if (success && mounted) {
        Navigator.of(context).pushReplacementNamed('/home');
      } else if (mounted) {
        _showErrorSnackBar('Ошибка входа через Facebook');
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Произошла ошибка: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.errorColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}

// Placeholder widgets - these would be in separate files
class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool isPassword;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  
  const CustomTextField({
    super.key,
    required this.controller,
    required this.label,
    this.isPassword = false,
    this.keyboardType,
    this.validator,
  });
  
  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
      ),
    );
  }
}

class CustomButton extends StatelessWidget {
  final String text;
  final bool isLoading;
  final VoidCallback? onPressed;
  
  const CustomButton({
    super.key,
    required this.text,
    this.isLoading = false,
    this.onPressed,
  });
  
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      child: isLoading
        ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          )
        : Text(text),
    );
  }
}

class SocialLoginButton extends StatelessWidget {
  final String text;
  final IconData icon;
  final Color color;
  final Color textColor;
  final Color? borderColor;
  final VoidCallback? onPressed;
  
  const SocialLoginButton({
    super.key,
    required this.text,
    required this.icon,
    required this.color,
    required this.textColor,
    this.borderColor,
    this.onPressed,
  });
  
  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, color: textColor),
      label: Text(text, style: TextStyle(color: textColor)),
      style: OutlinedButton.styleFrom(
        backgroundColor: color,
        side: BorderSide(color: borderColor ?? color),
      ),
    );
  }
}