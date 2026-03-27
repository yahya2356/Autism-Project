import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:country_code_picker/country_code_picker.dart';
import '../../core/constants/app_constants.dart';
import '../../shared/widgets/c_text.dart';
import '../../shared/widgets/custom_buttons.dart';
import '../../shared/widgets/custom_textfield.dart';
import '../../routes/app_pages.dart';
import 'auth_controller.dart';

class SignInView extends GetView<AuthController> {
  const SignInView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 60.h),
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
                  text: AppStrings.signInTitle,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 48.h),
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
                hintText: "Enter your password",
                preffixIcon: const Icon(Icons.lock_outline, color: AppColors.grey500),
               isPassword: true,
  hasPreffix: true,
  hasSuffix: true,
                controller: controller.passwordController,
                textcolor: AppColors.textPrimary,
              ),
              // Row(
              //   mainAxisAlignment: MainAxisAlignment.center,
              //   children: [
              //     Obx(() => Checkbox(
              //       value: controller.isRememberMe.value,
              //       onChanged: controller.toggleRememberMe,
              //       activeColor: AppColors.primary,
              //       shape: RoundedRectangleBorder(
              //         borderRadius: BorderRadius.circular(4.r),
              //       ),
              //     )),
              //     CText(
              //       text: "Remember me",
              //       fontSize: 14,
              //       fontWeight: FontWeight.w600,
              //       color: AppColors.textPrimary,
              //     ),
              //   ],
              // ),
           
              SizedBox(height: 50.h),
 Obx(
  () => PrimaryIconButton(
    text: controller.isLoading.value ? "Signing in..." : "Sign In",
    icon: Icons.arrow_forward,
    iconEnable: !controller.isLoading.value,
    width: double.infinity,
    isLoading: controller.isLoading.value,
    onTap: controller.signIn,
  ),
),
              SizedBox(height: 12.h),
              Row(
                children: [
                  Expanded(child: Divider(color: AppColors.grey300)),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    child: CText(text: "Parent Login with PHONE", fontSize: 12, color: AppColors.grey500),
                  ),
                  Expanded(child: Divider(color: AppColors.grey300)),
                ],
              ),
              SizedBox(height: 16.h),
              Align(
                alignment: Alignment.centerLeft,
                child: CText(
                  text: "Phone Number",
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              CustomTextField(
                hintText: "3012345678",
                preffixIcon: SizedBox(
                  width: 120.w,
                  child: CountryCodePicker(
                    onChanged: (countryCode) =>
                        controller.setCountryDialCode(countryCode.dialCode),
                    initialSelection: 'PK',
                    favorite: const ['PK', 'IN', 'AE', 'SA', 'GB', 'US', 'CA'],
                    showCountryOnly: false,
                    showOnlyCountryWhenClosed: false,
                    hideMainText: true,
                    alignLeft: false,
                    padding: EdgeInsets.symmetric(horizontal: 6.w),
                    textStyle: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14.sp,
                      fontFamily: 'Poppins',
                    ),
                    searchStyle: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14.sp,
                      fontFamily: 'Poppins',
                    ),
                    dialogTextStyle: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14.sp,
                      fontFamily: 'Poppins',
                    ),
                    boxDecoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                ),
                controller: controller.phoneController,
                keyboardType: TextInputType.phone,
                hasPreffix: true,
                textcolor: AppColors.textPrimary,
              ),
              SizedBox(height: 12.h),
              Obx(
                () => PrimaryIconButton(
                  text: controller.isPhoneSignInLoading.value ? "Sending OTP..." : "Login with OTP",
                  icon: Icons.sms_outlined,
                  iconEnable: !controller.isPhoneSignInLoading.value,
                  width: double.infinity,
                  isLoading: controller.isPhoneSignInLoading.value,
                  onTap: controller.startPhoneSignInVerification,
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
              CText(
                text: "Parent Login with Google",
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.grey500,
              ),
              SizedBox(height: 12.h),
              Obx(() => GoogleSignInButton(
                isGLoading: controller.isGLoading.value,
                onTap: controller.signInWithGoogle,
              )),
              SizedBox(height: 20.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CText(
                    text: "Don't have an account? ",
                    fontSize: 14,
                    color: AppColors.grey500,
                  ),
                  GestureDetector(
                    onTap: () => Get.toNamed(Routes.SIGN_UP),
                    child: CText(
                      text: "Sign up",
                      fontSize: 14,
                      textDecoration: TextDecoration.underline,
        
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
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
