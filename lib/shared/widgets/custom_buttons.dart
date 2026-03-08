import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/constants/app_constants.dart';
import 'c_text.dart';

class PrimaryButton extends StatelessWidget {
  
  final String text;
  final double? height;
  final double? width;
  final double? textSize;
  final double? radius;
  final Color? color;
  final Color? bcolor;
  final Color? tcolor;
  final Function() onTap;
  final bool iconEnable;
  final bool isLoading;

  const PrimaryButton({

    super.key,
    required this.text,
    this.height,
    this.isLoading = false,
    this.width,
    this.color,
    this.tcolor,
    this.radius,
    this.bcolor,
    this.textSize,
    required this.onTap,
    this.iconEnable = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width ?? 327.w,
        height: height ?? 52.h,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          boxShadow: const [],
          color: color ?? AppColors.kprimaryColor,
          border: Border.all(color: bcolor ?? AppColors.kprimaryColor),
          borderRadius: BorderRadius.circular(radius ?? 20.r),
        ),
      child: isLoading
    ? const SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(
              AppColors.primarywhiteColor),
        ),
      )
    : Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (iconEnable) ...[
            const SizedBox(width: 5),
            const Icon(
              Icons.arrow_back_outlined,
              color: AppColors.primarywhiteColor,
              size: 18,
            ),
            const SizedBox(width: 5),
          ],
          CText(
            text: text,
            fontSize: textSize ?? 16,
            fontWeight: FontWeight.w700,
            color: tcolor ?? AppColors.primarywhiteColor,
          ),
        ],
      ),
      ),
    );
  }
}


class GoogleSignInButton extends StatelessWidget {
  final bool isGLoading;
  final Function() onTap;

  const GoogleSignInButton({
    super.key,
    required this.isGLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isGLoading ? null : onTap,
      child: Container(
        width: double.infinity,
        height: 52.h,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(color: AppColors.grey300, width: 1.5),
        ),
        child: isGLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor:
                      AlwaysStoppedAnimation<Color>(AppColors.kprimaryColor),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    height: 24.h,
                    width: 24.w,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                    child: Image.asset(
                      'assets/app_images/google_icon.png',
                    ),
                  ),
                  SizedBox(width: 12.w),
                  CText(
                    text: "Continue with Google",
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ],
              ),
      ),
    );
  }
}


class PrimaryIconButton extends StatelessWidget {
  final String text;
  final Function()? onTap;
  final IconData? icon;
  final bool iconEnable;
  final bool isLoading; 
  final double? height;
  final double? width;
  final double? textSize;
  final double? radius;
  final Color? color;
  final Color? tcolor;
  final Color? iconColor;

  const PrimaryIconButton({
    super.key,
    required this.text,
    required this.onTap,
    this.icon,
    this.iconEnable = false,
    this.isLoading = false,
    this.height,
    this.width,
    this.color,
    this.tcolor,
    this.radius,
    this.textSize,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        width: width ?? double.infinity,
        height: height ?? 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color ?? Colors.blue,
          border: Border.all(color: color ?? Colors.blue),
          borderRadius: BorderRadius.circular(radius ?? 8),
        ),
        child: isLoading
            ? SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  color: tcolor ?? Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    text,
                    style: TextStyle(
                      color: tcolor ?? Colors.white,
                      fontSize: textSize ?? 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (iconEnable && icon != null) ...[
                    const SizedBox(width: 5),
                    Icon(icon, color: iconColor ?? Colors.white, size: 20),
                  ],
                ],
              ),
      ),
    );
  }
}



class PrimaryButton3 extends StatelessWidget {
  final String text;
  final Function() onTap;
  final bool iconEnable;

  const PrimaryButton3({
    super.key,
    required this.text,
    required this.onTap,
    this.iconEnable = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 190.w,
        height: 46.h,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border.all(style: BorderStyle.solid, width: 1.19),
          // color: AppColors.primarybackColor,
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CText(
              text: text,
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: AppColors.headingcolor,
            ),
            if (iconEnable) ...[
              const SizedBox(width: 5),
              const Icon(
                Icons.arrow_forward_ios,
                color: AppColors.primarywhiteColor,
                size: 18,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class IntroButton extends StatelessWidget {
  final Function() onPressed;

  const IntroButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: 100.w, top: 35.h),
      child: TextButton(
        onPressed: onPressed,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CText(
              text: 'Next',
              fontSize: 16,
              color: AppColors.primarywhiteColor,
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.arrow_forward,
              color: AppColors.primarywhiteColor,
            )
          ],
        ),
      ),
    );
  }
}

class PrimaryButtonOutlined extends StatelessWidget {
  final String text;
  final double? height;
  final double? width;
  final double? textSize;
  final double? radius;
  final Color? color;
  final Color? tcolor;
  final Function() onTap;
  final bool iconEnable;

  const PrimaryButtonOutlined({
    super.key,
    required this.text,
    this.height,
    this.width,
    this.color,
    this.radius,
    this.tcolor,
    this.textSize,
    required this.onTap,
    this.iconEnable = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width ?? 327.w,
        height: height ?? 52.h,
        alignment: Alignment.center,
        decoration: BoxDecoration(
            boxShadow: [
              // BoxShadow(
              //     color: AppColors.greyColor.withValues(alpha: 0.5),
              //     // blurRadius: 2,
              //     spreadRadius: 1,
              //     offset: const Offset(0, 2))
            ],
            color: color ?? AppColors.backgroundColor,
            borderRadius: BorderRadius.circular(radius ?? 6),
            border: Border.all(color:AppColors.grey400)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
               if (iconEnable) ...[
                 Icon(
                  Icons.arrow_back,
                  color:tcolor ??AppColors.primarywhiteColor,
                  size: 18,
                ),
             ],
                 SizedBox(width: 8.w),
          
          
            CText(
              text: text,
              fontSize: textSize ?? 17,
              fontWeight: FontWeight.w700,
              color: tcolor ?? AppColors.primarywhiteColor,
            ),
          
          ],
        ),
      ),
    );
  }
}
