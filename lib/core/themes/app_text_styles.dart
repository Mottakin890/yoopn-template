import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:yoopn_templates/core/themes/app_colors.dart';

class AppTextStyles {
  AppTextStyles._();

  static final TextStyle brandWordmark = TextStyle(
    fontSize: 60.sp,
    fontWeight: FontWeight.w800,
    letterSpacing: 2,
    color: AppColors.primary,
  );

  static final TextStyle brandDisplay = TextStyle(
    fontSize: 40.sp,
    fontWeight: FontWeight.w800,
    color: AppColors.primary,
  );

  static final TextStyle displayLarge = TextStyle(
    fontSize: 26.sp,
    height: 1.15,
    fontWeight: FontWeight.w800,
    color: AppColors.textPrimary,
  );

  static final TextStyle displayLargeTight = TextStyle(
    fontSize: 26.sp,
    fontWeight: FontWeight.w800,
    color: AppColors.textPrimary,
  );

  static final TextStyle screenTitleLarge = TextStyle(
    fontSize: 22.sp,
    fontWeight: FontWeight.w800,
    color: AppColors.textPrimary,
  );

  static final TextStyle screenTitleMedium = TextStyle(
    fontSize: 18.sp,
    fontWeight: FontWeight.w800,
    color: AppColors.textPrimary,
  );

  static final TextStyle titleLarge = TextStyle(
    fontSize: 16.sp,
    fontWeight: FontWeight.w800,
    color: AppColors.textPrimary,
  );

  static final TextStyle titleMedium = TextStyle(
    fontSize: 15.sp,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  static final TextStyle buttonOnPrimary = TextStyle(
    fontSize: 16.sp,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  static final TextStyle bodyEmphasis = TextStyle(
    fontSize: 14.sp,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static final TextStyle bodyStrong = TextStyle(
    fontSize: 14.sp,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  static final TextStyle errorAction = TextStyle(
    fontSize: 14.sp,
    fontWeight: FontWeight.w700,
    color: AppColors.error,
  );

  static final TextStyle bodyMedium = TextStyle(
    fontSize: 13.5.sp,
    height: 1.5,
    color: AppColors.textSecondary,
  );

  static final TextStyle bodySmall = TextStyle(
    fontSize: 13.sp,
    color: AppColors.textSecondary,
  );

  static final TextStyle labelEmphasis = TextStyle(
    fontSize: 13.sp,
    fontWeight: FontWeight.w600,
    color: AppColors.textSecondary,
  );

  static final TextStyle labelSecondary = TextStyle(
    fontSize: 12.sp,
    color: AppColors.textSecondary,
  );

  static final TextStyle labelPrimary = TextStyle(
    fontSize: 12.sp,
    fontWeight: FontWeight.w700,
    color: AppColors.primary,
  );

  static final TextStyle labelHint = TextStyle(
    fontSize: 12.sp,
    color: AppColors.textHint,
  );

  static final TextStyle overline = TextStyle(
    fontSize: 11.sp,
    fontWeight: FontWeight.w800,
    color: AppColors.textSecondary,
  );

  static final TextStyle overlinePlain = TextStyle(
    fontSize: 11.sp,
    color: AppColors.textSecondary,
  );

  static final TextStyle sectionLabel = TextStyle(
    fontSize: 11.sp,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.2,
    color: AppColors.textSecondary,
  );

  static final TextStyle caption = TextStyle(
    fontSize: 10.sp,
    color: AppColors.textHint,
  );

  static final TextStyle buttonPrimary = TextStyle(
    fontSize: 16.sp,
    fontWeight: FontWeight.w800,
    color: AppColors.primary,
  );

  static final TextStyle dialogTitle = TextStyle(
    color: AppColors.textPrimary,
    fontWeight: FontWeight.bold,
  );

  static final TextStyle emphasisStrong = TextStyle(
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static final TextStyle strong = TextStyle(color: AppColors.textPrimary);

  static final TextStyle secondary = TextStyle(color: AppColors.textSecondary);

  static final TextStyle serverFlag = TextStyle(fontSize: 24.sp);

  static final TextStyle switchLabel = TextStyle(
    fontSize: 12.sp,
    fontWeight: FontWeight.w800,
  );
}
