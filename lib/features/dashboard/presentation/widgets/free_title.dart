import 'package:flutter/material.dart';
import 'package:yoopn_templates/core/themes/app_text_styles.dart';

class FreeTitle extends StatelessWidget {
  const FreeTitle({super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      'YooPN+',
      textAlign: TextAlign.center,
      style: AppTextStyles.brandWordmark,
    );
  }
}
