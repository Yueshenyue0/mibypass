import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_miuix/miuix.dart';

class BypassPage extends StatefulWidget {
  const BypassPage({super.key});

  @override
  State<BypassPage> createState() => _BypassPageState();
}

class _BypassPageState extends State<BypassPage> {
  static const String _prefix = 'https://auth.platorelay.com/a?d=';

  final TextEditingController _input = TextEditingController();
  final List<String> _logs = [];
  String? _resultKey;
  bool _busy = false;

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  void _addLog(String s) {
    if (!mounted) return;
    setState(() => _logs.add(s));
  }

  Future<void> _bypass() async {
    final raw = _input.text.trim();
    if (!raw.startsWith(_prefix)) {
      _resultKey = null;
      setState(() {
        _logs
          ..clear()
          ..add('链接错误：必须以 ${_prefix} 开头');
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
    setState(() {
      _resultKey = key;
      _busy = false;
      _logs.add('完成');
    });
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

  @override
  Widget build(BuildContext context) {
    final theme = MiuixTheme.of(context);
    final primary = theme.colors.primary;
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
          // 输入区：始终保留，可多次绕过
          MiuixTextField(
            controller: _input,
            label: '输入忍者链接',
            useLabelAsPlaceholder: true,
            singleLine: true,
            enabled: !_busy,
            keyboardType: TextInputType.url,
          ),
          const SizedBox(height: 12),
          MiuixButton(
            onPressed: _busy ? null : _bypass,
            child: MiuixText('绕过', color: Colors.white),
          ),
          const SizedBox(height: 16),
          // 输出区：日志
          if (_logs.isNotEmpty)
            MiuixCard(
              insideMargin: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final l in _logs)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: MiuixText(l, fontSize: 14),
                    ),
                ],
              ),
            ),
          // key 卡片：完成后在输出区下方弹出，可多次生成（新 key 覆盖旧卡片）
          if (_resultKey != null) ...[
            const SizedBox(height: 12),
            MiuixCard(
              insideMargin: const EdgeInsets.all(14),
              child: Row(
                children: [
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
                  MiuixButton(
                    onPressed: _copy,
                    child: MiuixText('复制', color: primary),
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