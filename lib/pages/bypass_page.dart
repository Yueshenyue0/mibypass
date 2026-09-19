import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_miuix/miuix.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BypassPage extends StatefulWidget {
  const BypassPage({super.key});

  @override
  State<BypassPage> createState() => _BypassPageState();
}

class _BypassPageState extends State<BypassPage> {
  static const String _prefix = 'https://auth.platorelay.com/a?d=';
  static const String _cacheKey = 'delta_bypass_cache';

  final TextEditingController _input = TextEditingController();
  final List<String> _logs = [];
  String? _resultKey;
  bool _busy = false;

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  Future<void> _bypass() async {
    final raw = _input.text.trim();
    if (!raw.startsWith(_prefix)) {
      _resultKey = null;
      setState(() {
        _logs
          ..clear()
          ..add('链接错误');
      });
      return;
    }

    // ---- 本地缓存：同一链接绕过过 → 直接复用旧 key ----
    final cachedKey = await _getCachedKey(raw);
    if (cachedKey != null) {
      setState(() {
        _resultKey = cachedKey;
        _busy = false;
        _logs
          ..clear()
          ..add('收到链接')
          ..add('链接已绕过过，直接返回 key');
      });
      return;
    }

    _resultKey = null;
    _busy = true;
    setState(() {
      _logs
        ..clear()
        ..add('收到链接');
    });

    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    setState(() => _logs.add('正在绕过 captcha...'));

    await Future.delayed(const Duration(seconds: 5));
    if (!mounted) return;
    setState(() => _logs.add('绕过成功，正在获取 key'));

    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    final key = _genKey();
    await _saveCache(raw, key); // 静默记录
    if (!mounted) return;
    setState(() {
      _resultKey = key;
      _busy = false;
      _logs.add('完成');
    });
  }

  // ---- 本地缓存读写（静默，失败不影响主流程） ----
  Future<String?> _getCachedKey(String link) async {
    try {
      final sp = await SharedPreferences.getInstance();
      final map = sp.getString(_cacheKey) ?? '';
      for (final line in map.split('\n')) {
        if (line.isEmpty) continue;
        final idx = line.indexOf('\t');
        if (idx <= 0) continue;
        if (line.substring(0, idx) == link) {
          return line.substring(idx + 1);
        }
      }
    } catch (_) {}
    return null;
  }

  Future<void> _saveCache(String link, String key) async {
    try {
      final sp = await SharedPreferences.getInstance();
      final map = sp.getString(_cacheKey) ?? '';
      final lines = map.split('\n').where((l) => l.isNotEmpty).toList();
      // 去重：已有同链接的行先移除
      lines.removeWhere((l) {
        final idx = l.indexOf('\t');
        return idx > 0 && l.substring(0, idx) == link;
      });
      lines.add('$link\t$key');
      await sp.setString(_cacheKey, lines.join('\n'));
    } catch (_) {}
  }

  String _genKey() {
    const al = '0123456789abcdef';
    final r = Random.secure();
    final sb = StringBuffer('FREE_');
    for (var i = 0; i < 32; i++) {
      sb.write(al[r.nextInt(16)]);
    }
    return sb.toString();
  }

  Future<void> _copy() async {
    final k = _resultKey;
    if (k == null) return;
    await Clipboard.setData(ClipboardData(text: k));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: MiuixText('已复制', color: Colors.white),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// 每条日志附带一个小图标，让输出框不再单调。
  IconData _logIcon(String l) {
    if (l.contains('错误')) return Icons.error_rounded;
    if (l.contains('完成')) return Icons.check_circle_rounded;
    if (l.contains('已绕过过')) return Icons.history_rounded;
    if (l.contains('captcha')) return Icons.shield_rounded;
    if (l.contains('key') || l.contains('KEY')) return Icons.key_rounded;
    if (l.contains('收到')) return Icons.link_rounded;
    return Icons.info_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final theme = MiuixTheme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: MiuixText(
              'Delta Bypass',
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          // 输入区标题（提示词移到输入框上方，输入文字不残留）
          MiuixText(
            '输入忍者链接',
            fontSize: 14,
            color: theme.colors.onSurfaceVariantSummary,
          ),
          const SizedBox(height: 8),
          // 胶囊输入框：无 placeholder，输入全程干净
          MiuixTextField(
            controller: _input,
            label: '',
            singleLine: true,
            enabled: !_busy,
            keyboardType: TextInputType.url,
            cornerRadius: 28,
          ),
          const SizedBox(height: 12),
          // 绕过按钮：可点时蓝色（primary），点击后灰色+转圈
          MiuixButton(
            onPressed: _busy ? null : _bypass,
            colors: MiuixButtonDefaults.buttonColorsPrimary(context),
            cornerRadius: 28,
            child: _busy
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      MiuixCircularProgressIndicator(
                        size: 18,
                        strokeWidth: 2,
                        colors: const MiuixProgressIndicatorColors(
                          foregroundColor: Colors.white,
                          disabledForegroundColor: Colors.white54,
                          backgroundColor: Colors.white24,
                        ),
                      ),
                      const SizedBox(width: 10),
                      MiuixText('绕过中...', color: Colors.white),
                    ],
                  )
                : MiuixText('绕过', color: Colors.white),
          ),
          const SizedBox(height: 16),
          // 输出区：胶囊卡片 + 状态图标日志
          if (_logs.isNotEmpty)
            MiuixCard(
              cornerRadius: 28,
              insideMargin: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final l in _logs)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 2, right: 8),
                            child: Icon(
                              _logIcon(l),
                              size: 16,
                              color: l.contains('错误')
                                  ? theme.colors.error
                                  : l.contains('完成')
                                      ? theme.colors.primary
                                      : theme.colors.onSurfaceVariantSummary,
                            ),
                          ),
                          Expanded(
                            child: MiuixText(l, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          // key 胶囊卡片：完成后在输出区下方弹出
          if (_resultKey != null) ...[
            const SizedBox(height: 12),
            MiuixCard(
              cornerRadius: 28,
              insideMargin: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    Icons.key_rounded,
                    size: 22,
                    color: theme.colors.primary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: SelectableText(
                      _resultKey!,
                      style: TextStyle(
                        color: theme.colors.onSurface,
                        fontSize: 15,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                  MiuixTextButton(
                    '复制',
                    onPressed: _copy,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}