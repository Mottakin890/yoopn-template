import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:yoopn_templates/core/routes/app_pages.dart';
import 'package:yoopn_templates/core/themes/app_colors.dart';
import 'package:yoopn_templates/core/themes/app_text_styles.dart';

class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text('YooPN', style: AppTextStyles.screenTitleMedium),
        const Spacer(),
        IconButton(
          tooltip: 'Menu',
          onPressed: () => context.push(AppPages.menu),
          visualDensity: VisualDensity.compact,
          icon: const Icon(
            Icons.menu_rounded,
            size: 24,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
