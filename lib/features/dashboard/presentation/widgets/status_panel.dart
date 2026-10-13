import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:yoopn_templates/core/dimentions/spacings.dart';
import 'package:yoopn_templates/core/themes/app_colors.dart';
import 'package:yoopn_templates/core/utils/app_logger.dart';
import 'package:yoopn_templates/features/dashboard/presentation/bloc/vpn_bloc.dart';
import 'package:yoopn_templates/features/dashboard/presentation/bloc/vpn_state.dart';
import 'package:yoopn_templates/features/dashboard/presentation/helper/vpn_status.dart';
import 'package:yoopn_templates/features/dashboard/presentation/widgets/cancel_link.dart';
import 'package:yoopn_templates/features/dashboard/presentation/widgets/connected_timer_title.dart';
import 'package:yoopn_templates/features/dashboard/presentation/widgets/status_dot.dart';
import 'package:yoopn_templates/core/themes/app_text_styles.dart';

class StatusPanel extends StatelessWidget {
  const StatusPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocSelector<VpnBloc, VpnState, (VpnStatus, String, DateTime?)>(
      selector: (state) =>
          (state.status, state.connectionDetail, state.connectedSince),
      builder: (context, selected) {
        final (status, detail, since) = selected;
        AppLogger.d('UI', 'StatusPanel status=$status detail=$detail');

        final connected = status == VpnStatus.connected;
        final connecting = status == VpnStatus.connecting;

        final supporting = connecting && detail.isNotEmpty
            ? detail
            : status.subtitle;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                StatusDot(
                  color: connected
                      ? AppColors.success
                      : connecting
                      ? AppColors.warning
                      : AppColors.disconnected,
                ),
                Spacing.horizontal(8),
                Text(
                  connected
                      ? 'Protected'
                      : connecting
                      ? 'Connecting'
                      : 'Standby',
                  style: AppTextStyles.labelEmphasis,
                ),
              ],
            ),
            Spacing.vertical(10),
            SizedBox(
              height: 34.h * 2,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (connected && since != null)
                    ConnectedTimerTitle(since: since)
                  else
                    Text(
                      status.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.displayLarge,
                    ),
                  Spacing.vertical(4),
                  Text(
                    supporting,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodySmall,
                  ),
                ],
              ),
            ),
            if (connecting) ...[Spacing.vertical(4), const CancelLink()],
          ],
        );
      },
    );
  }
}
