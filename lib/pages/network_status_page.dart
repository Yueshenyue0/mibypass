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
  bool _online = false;
  String _deviceModel = '';
  String _system = '';
  Timer? _timer;
  bool _checking = true;

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

  Future<void> _loadDevice() async {
    try {
      final model = await _getProp('ro.product.model');
      final release = await _getProp('ro.build.version.release');
      if (!mounted) return;
      setState(() {
        _deviceModel = model.isNotEmpty ? model : 'Android 设备';
        _system = release.isNotEmpty ? 'Android $release' : 'Android';
      });
    } catch (_) {}
  }

  /// 读 Android 系统属性（getprop 是公开命令，普通 App 也能执行）
  Future<String> _getProp(String key) async {
    try {
      final r = await Process.run('getprop', [key]);
      return (r.stdout as String).trim();
    } catch (_) {
      return '';
    }
  }

  Future<void> _check() async {
    final ok = await _hasNetwork();
    if (!mounted) return;
    setState(() {
      _online = ok;
      _checking = false;
    });
  }

  /// 轻量 HTTP 探活：连得通任意 HTTPS 服务即视为在线
  Future<bool> _hasNetwork() async {
    try {
      final client = HttpClient()..connectionTimeout = const Duration(seconds: 3);
      final req = await client.getUrl(Uri.parse('https://api.github.com'));
      final resp = await req.close().timeout(const Duration(seconds: 4));
      await resp.drain<void>();
      client.close();
      return true;
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
              _checking
                  ? Icons.hourglass_empty
                  : (_online ? Icons.check_circle : Icons.warning_rounded),
              size: 84,
              color: _checking ? theme.colors.primaryVariant : color,
            ),
            const SizedBox(height: 14),
            MiuixText(
              _checking ? '检测中...' : (_online ? '已联网' : '未联网'),
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                MiuixText(
                  _deviceModel,
                  fontSize: 14,
                  color: theme.colors.onSurfaceVariantSummary,
                ),
                const SizedBox(width: 14),
                MiuixText(
                  _system,
                  fontSize: 14,
                  color: theme.colors.onSurfaceVariantSummary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}