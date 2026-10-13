import 'dart:async';

import 'package:flutter/material.dart';
import 'package:yoopn_templates/core/themes/app_text_styles.dart';

class ConnectedTimerTitle extends StatefulWidget {
  const ConnectedTimerTitle({super.key, required this.since});

  final DateTime since;

  @override
  State<ConnectedTimerTitle> createState() => _ConnectedTimerTitleState();
}

class _ConnectedTimerTitleState extends State<ConnectedTimerTitle> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final elapsed = DateTime.now().difference(widget.since);
    final h = elapsed.inHours.toString().padLeft(2, '0');
    final m = (elapsed.inMinutes % 60).toString().padLeft(2, '0');
    final s = (elapsed.inSeconds % 60).toString().padLeft(2, '0');
    return Text(
      'Connected for $h:$m:$s',
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: AppTextStyles.displayLarge,
    );
  }
}
