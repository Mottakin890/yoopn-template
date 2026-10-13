import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:yoopn_templates/core/utils/app_logger.dart';
import 'package:yoopn_templates/features/dashboard/presentation/bloc/vpn_bloc.dart';
import 'package:yoopn_templates/features/dashboard/presentation/bloc/vpn_event.dart';
import 'package:yoopn_templates/core/themes/app_text_styles.dart';

class CancelLink extends StatelessWidget {
  const CancelLink({super.key});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () {
        AppLogger.i('UI', 'StatusPanel cancel tapped');
        context.read<VpnBloc>().add(const VpnToggled());
      },
      style: TextButton.styleFrom(
        minimumSize: Size.zero,
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text('Cancel', style: AppTextStyles.labelEmphasis),
    );
  }
}
