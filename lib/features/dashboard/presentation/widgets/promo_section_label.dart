import 'package:flutter/material.dart';
import 'package:yoopn_templates/core/themes/app_text_styles.dart';

class PromoSectionLabel extends StatelessWidget {
  const PromoSectionLabel({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text.toUpperCase(), style: AppTextStyles.sectionLabel);
  }
}
