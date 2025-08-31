import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:swornim/pages/widgets/common/custom_text_field.dart';


class SignupForm extends StatefulWidget {
  final TextEditingController usernameController;
  final TextEditingController emailController;
  final TextEditingController phoneController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;

  const SignupForm({
    super.key,
    required this.usernameController,
    required this.emailController,
    required this.phoneController,
    required this.passwordController,
    required this.confirmPasswordController,
  });

  @override
  State<SignupForm> createState() => _SignupFormState();
}

class _SignupFormState extends State<SignupForm> {
  final FocusNode _usernameFocus = FocusNode();
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _phoneFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();
  final FocusNode _confirmPasswordFocus = FocusNode();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_usernameFocus);
    });
  }

  @override
  void dispose() {
    _usernameFocus.dispose();
    _emailFocus.dispose();
    _phoneFocus.dispose();
    _passwordFocus.dispose();
    _confirmPasswordFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Username field
        CustomTextField(
          label: 'Username',
          controller: widget.usernameController,
          focusNode: _usernameFocus,
          prefixIcon: Icons.person_outline,
          hintText: 'Choose a username',
          textInputAction: TextInputAction.next,
          validator: _validateUsername,
          onFieldSubmitted: (_) => FocusScope.of(context).requestFocus(_emailFocus),
        ),
        
        const SizedBox(height: 20),
        
        // Email field
        CustomTextField(
          label: 'Email Address',
          controller: widget.emailController,
          focusNode: _emailFocus,
          prefixIcon: Icons.email_outlined,
          hintText: 'Enter your email',
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          validator: _validateEmail,
          onFieldSubmitted: (_) => FocusScope.of(context).requestFocus(_phoneFocus),
        ),
        
        const SizedBox(height: 20),
        
        // Phone field
        CustomTextField(
          label: 'Phone Number',
          controller: widget.phoneController,
          focusNode: _phoneFocus,
          prefixIcon: Icons.phone_outlined,
          hintText: 'Enter your phone number',
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.next,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(10),
          ],
          validator: _validatePhone,
          onFieldSubmitted: (_) => FocusScope.of(context).requestFocus(_passwordFocus),
        ),
        
        const SizedBox(height: 20),
        
        // Password field
        CustomTextField(
          label: 'Password',
          controller: widget.passwordController,
          focusNode: _passwordFocus,
          prefixIcon: Icons.lock_outline,
          hintText: 'Create a strong password',
          obscureText: _obscurePassword,
          textInputAction: TextInputAction.next,
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              color: const Color(0xFF6B7280),
            ),
            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
          ),
          validator: _validatePassword,
          onFieldSubmitted: (_) => FocusScope.of(context).requestFocus(_confirmPasswordFocus),
        ),
        
        const SizedBox(height: 20),
        
        // Confirm Password field
        CustomTextField(
          label: 'Confirm Password',
          controller: widget.confirmPasswordController,
          focusNode: _confirmPasswordFocus,
          prefixIcon: Icons.lock_outline,
          hintText: 'Confirm your password',
          obscureText: _obscureConfirmPassword,
          textInputAction: TextInputAction.done,
          suffixIcon: IconButton(
            icon: Icon(
              _obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              color: const Color(0xFF6B7280),
            ),
            onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
          ),
          validator: _validateConfirmPassword,
        ),
      ],
    );
  }

  String? _validateUsername(String? val) {
    if (val == null || val.isEmpty) {
      return 'Username is required';
    }
    if (val.trim().length < 3) {
      return 'Username must be at least 3 characters';
    }
    if (val.trim().length > 20) {
      return 'Username must be less than 20 characters';
    }
    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(val)) {
      return 'Username can only contain letters, numbers, and underscores';
    }
    return null;
  }

  String? _validateEmail(String? val) {
    if (val == null || val.isEmpty) {
      return 'Email is required';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(val)) {
      return 'Please enter a valid email';
    }
    return null;
  }

  String? _validatePhone(String? val) {
    if (val == null || val.isEmpty) {
      return 'Phone number is required';
    }
    if (val.length < 10) {
      return 'Phone number must be at least 10 digits';
    }
    if (!RegExp(r'^\d+$').hasMatch(val)) {
      return 'Phone number can only contain digits';
    }
    return null;
  }

  String? _validatePassword(String? val) {
    if (val == null || val.isEmpty) {
      return 'Password is required';
    }
    if (val.length < 8) {
      return 'Password must be at least 8 characters';
    }
    if (!RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[\W_])').hasMatch(val)) {
      return 'Password must contain uppercase, lowercase, numbers, and special characters';
    }
    return null;
  }

  String? _validateConfirmPassword(String? val) {
    if (val == null || val.isEmpty) {
      return 'Please confirm your password';
    }
    if (val != widget.passwordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }
}