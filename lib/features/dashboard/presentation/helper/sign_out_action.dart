import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:yoopn_templates/core/routes/app_pages.dart';
import 'package:yoopn_templates/core/themes/app_colors.dart';
import 'package:yoopn_templates/core/utils/app_logger.dart';
import 'package:yoopn_templates/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:yoopn_templates/features/dashboard/presentation/bloc/vpn_bloc.dart';
import 'package:yoopn_templates/features/dashboard/presentation/bloc/vpn_event.dart';
import 'package:yoopn_templates/features/dashboard/presentation/helper/vpn_status.dart';
import 'package:yoopn_templates/core/themes/app_text_styles.dart';

Future<void> confirmAndSignOut(BuildContext context) async {
  AppLogger.i('UI', 'sign-out tapped');
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: AppColors.surface,
      title: Text('Sign out?', style: AppTextStyles.dialogTitle),
      content: Text(
        'The VPN tunnel will disconnect and you will return to the '
        'login screen.',
        style: AppTextStyles.secondary,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text('Cancel', style: AppTextStyles.secondary),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: const Text('Sign out'),
        ),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) return;

  final vpnBloc = context.read<VpnBloc>();
  if (vpnBloc.state.status != VpnStatus.disconnected) {
    AppLogger.i('UI', 'sign-out: disconnecting tunnel first');
    vpnBloc.add(const VpnToggled());

    try {
      await vpnBloc.stream
          .firstWhere((s) => s.status == VpnStatus.disconnected)
          .timeout(const Duration(seconds: 10));
    } catch (_) {
      AppLogger.w('UI', 'sign-out: disconnect wait timed out, leaving anyway');
    }
  }
  if (!context.mounted) return;
  context.read<AuthBloc>().add(const AuthSignOutSubmitted());
  AppLogger.i('ROUTE', 'sign-out → auth');
  context.go(AppPages.auth);
}
