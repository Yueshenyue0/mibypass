import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_miuix/miuix.dart';

class NetworkStatusPage extends StatefulWidget {
  const NetworkStatusPage({super.key});

  @override
  State<NetworkStatusPage> createState() => _NetworkStatusPageState();
}

class _NetworkStatusPageState extends State<NetworkStatusPage> {
  late bool _online;
  late String _deviceModel;
  late String _system;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _loadDevice();
    _check();
    _timer = Timer.periodic(const Duration(seconds: 3), (_) => _check());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _loadDevice() {
    final p = Platform;
    String model = '';
    String android = '';
    try {
      model = p.environment['ro.product.model'] ?? '';
    } catch (_) {}
    if (model.isEmpty) model = 'Android 设备';
    try {
      android = p.environment['ro.build.version.release'] ?? '';
    } catch (_) {}
    _deviceModel = model;
    _system = android.isNotEmpty ? 'Android $android' : 'Android';
  }

  Future<void> _check() async {
    final before = _online;
    final ok = await _hasNetwork();
    if (!mounted) return;
    if (ok != before) {
      setState(() => _online = ok);
    }
  }

  Future<bool> _hasNetwork() async {
    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 2));
      return result.isNotEmpty && result.first.address.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = MiuixTheme.of(context);
    final color = _online ? theme.colors.primary : theme.colors.error;
    return Center(
      child: MiuixCard(
        insideMargin: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _online ? Icons.check_circle : Icons.warning_rounded,
              size: 84,
              color: color,
            ),
            const SizedBox(height: 14),
            MiuixText(
              _online ? '已联网' : '未联网',
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                MiuixText(_deviceModel, fontSize: 14, color: color),
                const SizedBox(width: 14),
                MiuixText(_system, fontSize: 14, color: color),
              ],
            ),
          ],
        ),
      ),
    );
  }
}