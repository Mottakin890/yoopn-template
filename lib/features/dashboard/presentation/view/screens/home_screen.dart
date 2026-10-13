import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:yoopn_templates/core/dimentions/spacings.dart';
import 'package:yoopn_templates/core/ads/ad_carousel_widget.dart';
import 'package:yoopn_templates/core/utils/app_logger.dart';
import 'package:yoopn_templates/features/dashboard/presentation/widgets/connect_button.dart';
import 'package:yoopn_templates/features/dashboard/presentation/widgets/free_title.dart';
import 'package:yoopn_templates/features/dashboard/presentation/widgets/home_header.dart';
import 'package:yoopn_templates/features/dashboard/presentation/widgets/status_panel.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    AppLogger.d('UI', 'HomeScreen build');
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 32.h),
        child: CustomScrollView(
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: Column(
                children: [
                  const HomeHeader(),
                  Spacing.vertical(12),
                  const Center(child: AdCarouselWidget()),
                  Spacing.vertical(12),
                  const FreeTitle(),
                  Spacing.vertical(20),
                  const ConnectButton(),
                  Spacing.vertical(12),
                  const StatusPanel(),
                  const Spacer(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
