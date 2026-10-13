import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:yoopn_templates/core/dimentions/spacings.dart';
import 'package:yoopn_templates/core/routes/app_pages.dart';
import 'package:yoopn_templates/core/themes/app_colors.dart';
import 'package:yoopn_templates/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:yoopn_templates/features/dashboard/presentation/bloc/vpn_bloc.dart';
import 'package:yoopn_templates/features/dashboard/presentation/bloc/vpn_state.dart';
import 'package:yoopn_templates/features/dashboard/presentation/helper/sign_out_action.dart';
import 'package:yoopn_templates/features/dashboard/presentation/widgets/menu_item.dart';
import 'package:yoopn_templates/core/themes/app_text_styles.dart';

class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final email = context.select<AuthBloc, String>(
      (bloc) => bloc.state.user?.email ?? bloc.state.email,
    );
    final local = email.split('@').first;
    final initial = local.isEmpty ? 'U' : local[0].toUpperCase();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(8.w, 12.h, 20.w, 0),
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Back',
                    onPressed: () => context.pop(),
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Spacing.horizontal(4),
                  Text('Menu', style: AppTextStyles.screenTitleLarge),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 4.h),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 22.r,
                    backgroundColor: AppColors.primaryContainer,
                    child: Text(initial, style: AppTextStyles.buttonPrimary),
                  ),
                  Spacing.horizontal(12),
                  Expanded(
                    child: Text(
                      email.isEmpty ? 'User profile' : email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodyEmphasis,
                    ),
                  ),
                ],
              ),
            ),
            Spacing.vertical(8),
            Expanded(
              child: ListView(
                padding: EdgeInsets.symmetric(horizontal: 12.w),
                children: [
                  MenuItem(
                    icon: Icons.dns_rounded,
                    label: 'Servers',
                    trailing: BlocSelector<VpnBloc, VpnState, int>(
                      selector: (s) => s.servers.length,
                      builder: (_, count) =>
                          Text('$count', style: AppTextStyles.labelPrimary),
                    ),
                    onTap: () => context.push(AppPages.servers),
                  ),
                  MenuItem(
                    icon: Icons.manage_accounts_rounded,
                    label: 'Account setup',
                    onTap: () => context.push(AppPages.profile),
                  ),
                  const Divider(),
                  MenuItem(
                    icon: Icons.description_rounded,
                    label: 'Terms & Conditions',
                    onTap: () => context.push(AppPages.terms),
                  ),
                  MenuItem(
                    icon: Icons.shield_rounded,
                    label: 'Safety',
                    onTap: () => context.push(AppPages.safety),
                  ),
                  MenuItem(
                    icon: Icons.info_rounded,
                    label: 'Disclaimer',
                    onTap: () => context.push(AppPages.disclaimer),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 8.h),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => confirmAndSignOut(context),
                  icon: const Icon(
                    Icons.logout_rounded,
                    color: AppColors.error,
                  ),
                  label: Text('Log out', style: AppTextStyles.errorAction),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                    side: BorderSide(
                      color: AppColors.error.withValues(alpha: 0.4),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                  ),
                ),
              ),
            ),
            Center(
              child: Padding(
                padding: EdgeInsets.only(bottom: 16.h),
                child: Text('by VIS Softs', style: AppTextStyles.labelHint),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
