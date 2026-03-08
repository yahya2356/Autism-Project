import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../core/constants/app_constants.dart';
import '../../shared/widgets/c_text.dart';
import '../../shared/widgets/custom_buttons.dart';
import '../../shared/widgets/custom_textfield.dart';

import 'auth_controller.dart';

class SignUpView extends GetView<AuthController> {
  const SignUpView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: const CustomAppBar(text: "",leadingIcon: false,),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 20.h),
              Container(
                width: 80.w,
                height: 80.w,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.secondary,
                    width: 4.w,
                  ),
                ),
                child: Icon(
                  Icons.radio_button_unchecked,
                  size: 40.sp,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 32.h),
              Align(
                alignment: Alignment.center,
                child: CText(
                  text: AppStrings.signUpTitle,
                  fontSize: 28.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              Align(
                alignment: Alignment.center,
                child: CText(
                  text: 'Quickly make your account in 1 minute',
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w400,
                  color: AppColors.textSecondary,
                ),
              ),

              SizedBox(height: 32.h),
              
              Align(
                alignment: Alignment.centerLeft,
                child: CText(
                  text: "Full Name",
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),

              CustomTextField(
                  hintText: "Enter your full name",
                  preffixIcon: const Icon(Icons.person_outline, color: AppColors.grey500),
                  controller: controller.nameController,
                  hasPreffix: true,
                  
                  textcolor: AppColors.textPrimary,
              ),

            

              Align(
                alignment: Alignment.centerLeft,
                child: CText(
                  text: "Email Address",
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),

              CustomTextField(
                hintText: "Enter your email",
                preffixIcon: const Icon(Icons.email_outlined, color: AppColors.grey500),
                controller: controller.emailController,
                keyboardType: TextInputType.emailAddress,
                hasPreffix: true,
                textcolor: AppColors.textPrimary,
              ),

              
              Align(
                alignment: Alignment.centerLeft,
                child: CText(
                  text: "Password",
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),

          CustomTextField(
                hintText: "Create a password",
                preffixIcon: const Icon(Icons.lock_outline, color: AppColors.grey500),
                 isPassword: true,
  hasPreffix: true,
  hasSuffix: true,
                controller: controller.passwordController,
                textcolor: AppColors.textPrimary,
              ),
               Align(
                alignment: Alignment.centerLeft,
                child: CText(
                  text: "Confirm Password",
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
             CustomTextField(
                hintText: "Confirm  password",
                preffixIcon: const Icon(Icons.lock_outline, color: AppColors.grey500),
                isPassword: true,
  hasPreffix: true,
  hasSuffix: true,
                controller: controller.confirmPasswordController,
                textcolor: AppColors.textPrimary,
              ),
              SizedBox(height: 40.h),
              Obx(
  () => PrimaryIconButton(
    text: "Sign Up",
    icon: Icons.arrow_forward,
    iconEnable: true,
    width: double.infinity,
    isLoading: controller.isLoading.value,
    onTap: controller.signUp,
  ),
),
              SizedBox(height: 16.h),
              Row(
                children: [
                  Expanded(child: Divider(color: AppColors.grey300)),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    child: CText(text: "OR", fontSize: 14, color: AppColors.grey500),
                  ),
                  Expanded(child: Divider(color: AppColors.grey300)),
                ],
              ),
              SizedBox(height: 16.h),
              // Obx(() => PrimaryButton(
              //   text: "Continue with Google",
              //   width: double.infinity,
              //   isLoading: controller.isLoading.value,
              //   onTap: controller.signInWithGoogle,
              // )),

              SizedBox(height: 20.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CText(
                    text: "Already have an account? ",
                    fontSize: 14,
                    color: AppColors.grey500,
                  ),
                  GestureDetector(
                    onTap: () => Get.back(),
                    child: CText(
                      text: "Sign in",
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                      textDecoration: TextDecoration.underline,
                      decorationColor: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
