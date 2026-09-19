import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_miuix/miuix.dart';

/// 联网状态页（InstallerX 风格）：
/// 一张大卡片，顶部大图标（勾=联网 / 感叹号=未联网），
/// 下面是「机型」「系统」两行信息。
class NetworkStatusPage extends StatefulWidget {
  const NetworkStatusPage({super.key});

  @override
  State<NetworkStatusPage> createState() => _NetworkStatusPageState();
}

class _NetworkStatusPageState extends State<NetworkStatusPage> {
  bool _online = false;
  bool _checking = true;
  String _deviceModel = '读取中...';
  String _system = '读取中...';
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

  Future<void> _loadDevice() async {
    final model = await _getProp('ro.product.model');
    final brand = await _getProp('ro.product.brand');
    final release = await _getProp('ro.build.version.release');
    final sdk = await _getProp('ro.build.version.sdk');
    if (!mounted) return;
    setState(() {
      _deviceModel = model.isNotEmpty ? model : 'Android 设备';
      final sys = release.isNotEmpty ? 'Android $release' : 'Android';
      _system = sdk.isNotEmpty ? '$sys (API $sdk)' : sys;
      if (brand.isNotEmpty && brand.toLowerCase() != model.toLowerCase()) {
        _deviceModel = '$brand $model';
      }
    });
  }

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

  Future<bool> _hasNetwork() async {
    try {
      final client = HttpClient()
        ..connectionTimeout = const Duration(seconds: 3);
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
    final ok = _checking || _online;
    final color = _online ? theme.colors.primary : theme.colors.error;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
      child: MiuixCard(
        insideMargin: const EdgeInsets.all(20),
        child: Column(
          children: [
            // 顶部大图标
            Icon(
              _checking
                  ? Icons.hourglass_top_rounded
                  : (_online ? Icons.check_circle : Icons.warning_rounded),
              size: 96,
              color: _checking ? theme.colors.onSurfaceVariantSummary : color,
            ),
            const SizedBox(height: 12),
            MiuixText(
              _checking
                  ? '检测中...'
                  : (_online ? '已联网' : '未联网'),
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
            const SizedBox(height: 24),
            MiuixHorizontalDivider(),
            const SizedBox(height: 4),
            // 信息行：机型
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  MiuixText(
                    '机型',
                    fontSize: 15,
                    color: theme.colors.onSurfaceVariantSummary,
                  ),
                  MiuixText(
                    _deviceModel,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  MiuixText(
                    '系统',
                    fontSize: 15,
                    color: theme.colors.onSurfaceVariantSummary,
                  ),
                  MiuixText(
                    _system,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}