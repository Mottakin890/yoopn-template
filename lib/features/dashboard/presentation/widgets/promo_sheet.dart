import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:yoopn_templates/core/dimentions/spacings.dart';
import 'package:go_router/go_router.dart';
import 'package:yoopn_templates/core/ads/ad_carousel_widget.dart';
import 'package:yoopn_templates/core/routes/app_pages.dart';
import 'package:yoopn_templates/core/themes/app_colors.dart';
import 'package:yoopn_templates/features/dashboard/domain/entities/vpn_server.dart';
import 'package:yoopn_templates/features/dashboard/presentation/bloc/vpn_bloc.dart';
import 'package:yoopn_templates/features/dashboard/presentation/bloc/vpn_state.dart';
import 'package:yoopn_templates/features/dashboard/presentation/widgets/promo_option.dart';
import 'package:yoopn_templates/features/dashboard/presentation/widgets/promo_section_label.dart';

class PromoSheet extends StatelessWidget {
  const PromoSheet({super.key});

  VpnServer _selected(List<VpnServer> servers, String id) {
    for (final s in servers) {
      if (s.matchesId(id)) return s;
    }
    return servers.isNotEmpty
        ? servers.first
        : const VpnServer(name: 'United States', flag: '🇺🇸');
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 20.h),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const PromoSectionLabel(text: 'Servers'),
            Spacing.vertical(4),
            BlocBuilder<VpnBloc, VpnState>(
              buildWhen: (prev, curr) =>
                  prev.server != curr.server || prev.servers != curr.servers,
              builder: (context, state) {
                final selected = _selected(state.servers, state.server);
                return PromoOption(
                  icon: Icons.dns_rounded,
                  iconColor: AppColors.primary,
                  iconBackground: AppColors.primaryContainer,
                  title: '${selected.flag} ${selected.name}',
                  subtitle: selected.isVpnGate
                      ? '${selected.hostName} • ${selected.speedText} — tap to change'
                      : 'Tap to choose a server',
                  onTap: () => context.push(AppPages.servers),
                );
              },
            ),
            Divider(height: 24.h, color: AppColors.divider),
            const PromoSectionLabel(text: 'Advertisement'),
            Spacing.vertical(8),
            const AdCarouselWidget(),
            Spacing.vertical(12),
            const PromoSectionLabel(text: 'Advertisement'),
            Spacing.vertical(8),
            const AdCarouselWidget(),
            Spacing.vertical(8),
          ],
        ),
      ),
    );
  }
}
