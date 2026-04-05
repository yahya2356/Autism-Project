import 'dart:async';
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
import 'otp_flow_args.dart';

class AuthController extends GetxController {
  final AuthRepository _authRepository = Get.find<AuthRepository>();
  final UserRepository _userRepository = Get.find<UserRepository>();
  // ignore: unused_field
  final RoleAuthService _roleAuthService = Get.find<RoleAuthService>();

  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController otpController = TextEditingController();
  
  final RxBool isPasswordVisible = false.obs;
  final RxBool isRememberMe = false.obs;
  final RxBool isLoading = false.obs;
  final RxBool isGLoading = false.obs;
  final RxBool isPhoneSignInLoading = false.obs;
  final RxBool isOtpSending = false.obs;
  final RxBool isOtpVerifying = false.obs;
  final RxString selectedCountryDialCode = '+971'.obs;


  @override
  void onInit() {
    super.onInit();
    dev.log('AuthController Initialized', name: 'AUTH_DEBUG');
  }

  @override
  void onClose() {
    dev.log('AuthController Closed', name: 'AUTH_DEBUG');
    emailController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    nameController.dispose();
    otpController.dispose();
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

String _sanitizePhoneNumber(String value) {
  return value.replaceAll(RegExp(r'[\s()-]'), '');
}

void setCountryDialCode(String? dialCode) {
  if (dialCode != null && dialCode.isNotEmpty) {
    selectedCountryDialCode.value = dialCode;
  }
}

String getFormattedPhoneNumber() {
  final rawPhone = _sanitizePhoneNumber(phoneController.text.trim());
  if (rawPhone.isEmpty) {
    return rawPhone;
  }

  if (rawPhone.startsWith('+')) {
    return rawPhone;
  }

  final localPhone = rawPhone.replaceFirst(RegExp(r'^0+'), '');
  return '${selectedCountryDialCode.value}$localPhone';
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
  await startSignUpPhoneVerification();
}

Future<void> startSignUpPhoneVerification() async {
  final email = emailController.text.trim();
  final password = passwordController.text.trim();
  final confirmPassword = confirmPasswordController.text.trim();
  final name = nameController.text.trim();
  final phone = getFormattedPhoneNumber();

  final nameError = Validator.validateName(name);
  final emailError = Validator.validateEmail(email);
  final phoneError = Validator.validatePhoneNumber(phone);
  final passError = Validator.validatePassword(password);
  final confirmPassError = Validator.validateConfirmPassword(password, confirmPassword);

  if (nameError != null) return ErrorHandler.showErrorSnackBar(nameError);
  if (emailError != null) return ErrorHandler.showErrorSnackBar(emailError);
  if (phoneError != null) return ErrorHandler.showErrorSnackBar(phoneError);
  if (passError != null) return ErrorHandler.showErrorSnackBar(passError);
  if (confirmPassError != null) return ErrorHandler.showErrorSnackBar(confirmPassError);

  try {
    isLoading.value = true;
    final args = await _sendOtp(
      flowType: OtpFlowType.signUp,
      phoneNumber: phone,
      name: name,
      email: email,
      password: password,
    );

    otpController.clear();
    ErrorHandler.showSuccessSnackBar("OTP Sent", "Enter the code sent to $phone");
    Get.toNamed(Routes.OTP_VERIFICATION, arguments: args);
  } on FirebaseAuthException catch (e) {
    ErrorHandler.showErrorSnackBar(e);
  } catch (e) {
    ErrorHandler.showErrorSnackBar(e.toString());
  } finally {
    isLoading.value = false;
  }
}

Future<void> startPhoneSignInVerification() async {
  final phone = getFormattedPhoneNumber();
  final phoneError = Validator.validatePhoneNumber(phone);

  if (phoneError != null) return ErrorHandler.showErrorSnackBar(phoneError);

  try {
    isPhoneSignInLoading.value = true;
    final args = await _sendOtp(
      flowType: OtpFlowType.signIn,
      phoneNumber: phone,
    );

    otpController.clear();
    ErrorHandler.showSuccessSnackBar("OTP Sent", "Enter the code sent to $phone");
    Get.toNamed(Routes.OTP_VERIFICATION, arguments: args);
  } on FirebaseAuthException catch (e) {
    ErrorHandler.showErrorSnackBar(e);
  } catch (e) {
    ErrorHandler.showErrorSnackBar(e.toString());
  } finally {
    isPhoneSignInLoading.value = false;
  }
}

Future<OtpFlowArgs?> resendOtp(OtpFlowArgs args) async {
  try {
    isOtpSending.value = true;
    final updatedArgs = await _sendOtp(
      flowType: args.flowType,
      phoneNumber: args.phoneNumber,
      name: args.name,
      email: args.email,
      password: args.password,
      resendToken: args.resendToken,
    );
    ErrorHandler.showSuccessSnackBar("OTP Sent", "A new code has been sent");
    return updatedArgs;
  } on FirebaseAuthException catch (e) {
    ErrorHandler.showErrorSnackBar(e);
  } catch (e) {
    ErrorHandler.showErrorSnackBar(e.toString());
  } finally {
    isOtpSending.value = false;
  }

  return null;
}

Future<void> verifyOtp(OtpFlowArgs args) async {
  final smsCode = otpController.text.trim();
  final otpError = Validator.validateOtpCode(smsCode);
  if (otpError != null) return ErrorHandler.showErrorSnackBar(otpError);

  try {
    isOtpVerifying.value = true;
    final credential = _authRepository.buildPhoneAuthCredential(
      verificationId: args.verificationId,
      smsCode: smsCode,
    );

    if (args.isSignUp) {
      final userCredential = await _authRepository.signUp(args.email!, args.password!);

      try {
        await _authRepository.linkPhoneCredential(credential);
      } on FirebaseAuthException {
        await userCredential.user?.delete();
        await _authRepository.signOut();
        rethrow;
      }

      final newUser = UserModel(
        id: userCredential.user!.uid,
        name: args.name!,
        email: args.email!,
        phone: args.phoneNumber,
        role: 'parent',
        createdAt: DateTime.now(),
      );

      await _userRepository.createUser(newUser);
      await _roleAuthService.refreshUserData();
      _clearAuthInputs(clearOtp: true);
      ErrorHandler.showSuccessSnackBar("Account Created", "Your parent account is verified");
      Get.offAllNamed(Routes.DASHBOARD);
      return;
    }

    await _authRepository.signInWithPhoneCredential(credential);
    await _roleAuthService.refreshUserData();
    _clearAuthInputs(clearOtp: true, clearPassword: false);

    final role = _roleAuthService.currentRole.value;
    ErrorHandler.showSuccessSnackBar("Welcome Back", "Phone login successful");

    if (role == UserRole.child) {
      Get.offAllNamed(Routes.CHILD_DASHBOARD);
    } else {
      Get.offAllNamed(Routes.DASHBOARD);
    }
  } on FirebaseAuthException catch (e) {
    ErrorHandler.showErrorSnackBar(e);
  } catch (e) {
    ErrorHandler.showErrorSnackBar(e.toString());
  } finally {
    isOtpVerifying.value = false;
  }
}

Future<OtpFlowArgs> _sendOtp({
  required OtpFlowType flowType,
  required String phoneNumber,
  String? name,
  String? email,
  String? password,
  int? resendToken,
}) async {
  final completer = Completer<OtpFlowArgs>();

  await _authRepository.verifyPhoneNumber(
    phoneNumber: phoneNumber,
    forceResendingToken: resendToken,
    verificationCompleted: (credential) {
      dev.log("Phone verification auto-completed for $phoneNumber", name: "AUTH_CONTROLLER");
    },
    verificationFailed: (error) {
      if (!completer.isCompleted) {
        completer.completeError(error);
      }
    },
    codeSent: (verificationId, newResendToken) {
      if (!completer.isCompleted) {
        completer.complete(
          OtpFlowArgs(
            flowType: flowType,
            phoneNumber: phoneNumber,
            verificationId: verificationId,
            resendToken: newResendToken,
            name: name,
            email: email,
            password: password,
          ),
        );
      }
    },
    codeAutoRetrievalTimeout: (verificationId) {
      dev.log("OTP auto retrieval timed out for $phoneNumber", name: "AUTH_CONTROLLER");
    },
  );

  return completer.future;
}

void _clearAuthInputs({
  bool clearPassword = true,
  bool clearOtp = false,
}) {
  nameController.clear();
  emailController.clear();
  phoneController.clear();
  confirmPasswordController.clear();

  if (clearPassword) {
    passwordController.clear();
  }

  if (clearOtp) {
    otpController.clear();
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
