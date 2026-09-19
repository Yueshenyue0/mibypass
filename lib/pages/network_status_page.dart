import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_miuix/miuix.dart';

/// 联网状态页（InstallerX 风格）：
/// 顶部一张横向状态卡片（大图标 + 状态文字），
/// 下方「机型」「系统」各自独立卡片。
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
    final statusColor =
        _checking ? theme.colors.onSurfaceVariantSummary
        : _online ? theme.colors.primary
        : theme.colors.error;
    final statusIcon =
        _checking ? Icons.hourglass_top_rounded
        : _online ? Icons.check_circle
        : Icons.error_rounded;
    final statusText =
        _checking ? '检测中...'
        : _online ? '已联网'
        : '未联网';

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      children: [
        // 顶部横向状态卡片：大图标 + 状态文字并排（胶囊）
        MiuixCard(
          cornerRadius: 28,
          insideMargin: const EdgeInsets.all(20),
          child: Row(
            children: [
              Icon(statusIcon, size: 48, color: statusColor),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    MiuixText(
                      '网络状态',
                      fontSize: 14,
                      color: theme.colors.onSurfaceVariantSummary,
                    ),
                    const SizedBox(height: 2),
                    MiuixText(
                      statusText,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // 机型卡片（胶囊）
        MiuixCard(
          cornerRadius: 28,
          insideMargin: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(
                Icons.smartphone_rounded,
                size: 22,
                color: theme.colors.onSurfaceVariantSummary,
              ),
              const SizedBox(width: 12),
              MiuixText(
                '机型',
                fontSize: 15,
                color: theme.colors.onSurfaceVariantSummary,
              ),
              const Spacer(),
              Flexible(
                child: MiuixText(
                  _deviceModel,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // 系统卡片（胶囊）
        MiuixCard(
          cornerRadius: 28,
          insideMargin: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(
                Icons.android_rounded,
                size: 22,
                color: theme.colors.onSurfaceVariantSummary,
              ),
              const SizedBox(width: 12),
              MiuixText(
                '系统',
                fontSize: 15,
                color: theme.colors.onSurfaceVariantSummary,
              ),
              const Spacer(),
              Flexible(
                child: MiuixText(
                  _system,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}