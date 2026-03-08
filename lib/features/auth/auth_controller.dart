import 'dart:developer' as dev;
import 'package:bluecircle/core/utils/validator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../routes/app_pages.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/user_repository.dart';
import '../../data/models/user_model.dart';
import '../../core/utils/error_handler.dart';
import '../../core/services/role_auth_service.dart';

class AuthController extends GetxController {
  final AuthRepository _authRepository = Get.find<AuthRepository>();
  final UserRepository _userRepository = Get.find<UserRepository>();
  // ignore: unused_field
  final RoleAuthService _roleAuthService = Get.find<RoleAuthService>();

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  final TextEditingController nameController = TextEditingController();
  
  final RxBool isPasswordVisible = false.obs;
  final RxBool isRememberMe = false.obs;
  final RxBool isLoading = false.obs;
  final RxBool isGLoading = false.obs;


  @override
  void onInit() {
    super.onInit();
    dev.log('AuthController Initialized', name: 'AUTH_DEBUG');
  }

  @override
  void onClose() {
    dev.log('AuthController Closed', name: 'AUTH_DEBUG');
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    nameController.dispose();
    super.onClose();
  }

  void togglePasswordVisibility() {
    isPasswordVisible.value = !isPasswordVisible.value;
  }

  void toggleRememberMe(bool? value) {
    if (value != null) {
      isRememberMe.value = value;
    }
  }
Future<void> signIn() async {
  final email = emailController.text.trim();
  final password = passwordController.text.trim();

  final emailError = Validator.validateEmail(email);
  final passError = Validator.validateSignInPassword(password);

  if (emailError != null) return ErrorHandler.showErrorSnackBar(emailError);
  if (passError != null) return ErrorHandler.showErrorSnackBar(passError);

  try {
    isLoading.value = true;
    dev.log("SignIn started for: $email", name: "AUTH_CONTROLLER");

    await _authRepository.signIn(email, password);

    
    final user = _authRepository.currentUser;
    if (user != null) {
      await _roleAuthService.refreshUserData();
      
      final role = _roleAuthService.currentRole.value;
      
      dev.log("User role detected: $role", name: "AUTH_CONTROLLER");
      
      ErrorHandler.showSuccessSnackBar("Welcome Back", "Login successful");
      
      if (role == UserRole.child) {
        Get.offAllNamed(Routes.CHILD_DASHBOARD);
      } else {
        Get.offAllNamed(Routes.DASHBOARD);
      }
    } else {
      ErrorHandler.showErrorSnackBar("Failed to get user data");
    }
  } on FirebaseAuthException catch (e) {
    String message;
    switch (e.code) {
      case 'user-not-found':
        message = "No user found for this email";
        break;
      case 'wrong-password':
        message = "Incorrect password";
        break;
      case 'invalid-email':
        message = "Invalid email address";
        break;
      case 'user-disabled':
        message = "This user account has been disabled";
        break;
      default:
        message = e.message ?? "Sign in failed. Try again";
    }
    ErrorHandler.showErrorSnackBar(message);
  } catch (e) {
    dev.log("SignIn Failed: $e", name: "AUTH_CONTROLLER", error: e);
    ErrorHandler.showErrorSnackBar(e.toString());
  } finally {
    isLoading.value = false;
  }
}

Future<void> signUp() async {
  final email = emailController.text.trim();
  final password = passwordController.text.trim();
  final confirmPassword = confirmPasswordController.text.trim();
  final name = nameController.text.trim();

  final nameError = Validator.validateName(name);
  final emailError = Validator.validateEmail(email);
  final passError = Validator.validatePassword(password);
  final confirmPassError = Validator.validateConfirmPassword(password, confirmPassword);

  if (nameError != null) return ErrorHandler.showErrorSnackBar(nameError);
  if (emailError != null) return ErrorHandler.showErrorSnackBar(emailError);
  if (passError != null) return ErrorHandler.showErrorSnackBar(passError);
  if (confirmPassError != null) return ErrorHandler.showErrorSnackBar(confirmPassError);

  try {
    isLoading.value = true;
    final userCredential = await _authRepository.signUp(email, password);

    final newUser = UserModel(
      id: userCredential.user!.uid,
      name: name,
      email: email,
      role: 'parent', 
      createdAt: DateTime.now(),
    );

    await _userRepository.createUser(newUser);
    ErrorHandler.showSuccessSnackBar("Account Created", "Welcome to bluecircle");
    Get.offAllNamed(Routes.DASHBOARD);
  } catch (e) {
    ErrorHandler.showErrorSnackBar(e.toString());
  } finally {
    isLoading.value = false;
  }
}

Future<void> signInWithGoogle() async {
  try {
    isGLoading.value = true;
    dev.log("Google SignIn started", name: "AUTH_CONTROLLER");

    final userCredential = await _authRepository.signInWithGoogle();
    if (userCredential == null) {
      isGLoading.value = false;
      return;
    }

    final user = userCredential.user;
    if (user != null) {
      final existingUser = await _userRepository.getUser(user.uid);
      if (existingUser == null) {
        final newUser = UserModel(
          id: user.uid,
          name: user.displayName ?? "Parent",
          email: user.email ?? "",
          role: 'parent',
          profileImage: user.photoURL,
          profileImageUrl: user.photoURL,
          createdAt: DateTime.now(),
        );
        await _userRepository.createUser(newUser);
      }

      await _roleAuthService.refreshUserData();
      final role = _roleAuthService.currentRole.value;
      
      ErrorHandler.showSuccessSnackBar("Welcome", "Google Login successful");
      
      if (role == UserRole.child) {
        Get.offAllNamed(Routes.CHILD_DASHBOARD);
      } else {
        Get.offAllNamed(Routes.DASHBOARD);
      }
    }
  } catch (e) {
    dev.log("Google SignIn Failed: $e", name: "AUTH_CONTROLLER", error: e);
    ErrorHandler.showErrorSnackBar(e.toString());
  } finally {
    isGLoading.value = false;
  }
}



  Future<void> logout() async {
    dev.log('User Logging Out', name: 'AUTH_DEBUG');
    try {
      await _authRepository.signOut();
      Get.offAllNamed(Routes.SIGN_IN);
    } catch (e) {
      dev.log('Logout Failed: $e', name: 'AUTH_DEBUG', error: e);
      ErrorHandler.showErrorSnackBar(e);
    }
  }

  Future<void> forgotPassword() async {
    final email = emailController.text.trim();
    if (email.isEmpty) {
      Get.snackbar('Error', 'Please enter your email address to reset password');
      return;
    }

    if (!GetUtils.isEmail(email)) {
      Get.snackbar('Error', 'Please enter a valid email address');
      return;
    }

    try {
      isLoading.value = true;
      dev.log('Sending Password Reset Email to: $email', name: 'AUTH_DEBUG');
      await _authRepository.sendPasswordResetEmail(email);
      ErrorHandler.showSuccessSnackBar(
        'Email Sent', 
        'Password reset link has been sent to your email.'
      );
    } catch (e) {
      dev.log('Password Reset Failed: $e', name: 'AUTH_DEBUG', error: e);
      ErrorHandler.showErrorSnackBar(e);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deleteAccount() async {
    try {
      isLoading.value = true;
      dev.log('Attempting Account Deletion', name: 'AUTH_DEBUG');
      await _authRepository.deleteAccount();
      dev.log('Account Deleted Successfully', name: 'AUTH_DEBUG');
      Get.offAllNamed(Routes.SIGN_IN);
      ErrorHandler.showSuccessSnackBar('Account Deleted', 'Your account has been permanently removed.');
    } catch (e) {
      dev.log('Account Deletion Failed: $e', name: 'AUTH_DEBUG', error: e);
      ErrorHandler.showErrorSnackBar(e);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> sendEmailVerification() async {
    try {
      dev.log('Sending Email Verification', name: 'AUTH_DEBUG');
      await _authRepository.sendEmailVerification();
      ErrorHandler.showSuccessSnackBar(
        'Verification Sent', 
        'A verification email has been sent to your inbox.'
      );
    } catch (e) {
      dev.log('Email Verification Failed: $e', name: 'AUTH_DEBUG', error: e);
      ErrorHandler.showErrorSnackBar(e);
    }
  }

  bool get isEmailVerified => _authRepository.currentUser?.emailVerified ?? false;
}


