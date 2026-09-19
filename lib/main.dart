import 'package:flutter/material.dart';
import 'package:flutter_miuix/miuix.dart';

import 'pages/network_status_page.dart';
import 'pages/bypass_page.dart';

void main() {
  runApp(const MiApp());
}

/// 页面背景：浅灰色（InstallerX 风格，让白色卡片浮起来）
const Color kPageBackground = Color(0xFFF2F2F7);

class MiApp extends StatelessWidget {
  const MiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MiuixSystemTheme(
      child: Builder(
        builder: (context) {
          final theme = MiuixTheme.of(context);
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Delta Tool',
            theme: ThemeData(
              useMaterial3: true,
              brightness: theme.brightness,
              colorScheme: ColorScheme.fromSeed(
                seedColor: theme.colors.primary,
                brightness: theme.brightness,
              ),
              scaffoldBackgroundColor: kPageBackground,
            ),
            home: const HomeTabRoot(),
          );
        },
      ),
    );
  }
}

class HomeTabRoot extends StatefulWidget {
  const HomeTabRoot({super.key});

  @override
  State<HomeTabRoot> createState() => _HomeTabRootState();
}

class _HomeTabRootState extends State<HomeTabRoot> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final theme = MiuixTheme.of(context);
    // 底部悬浮导航栏高度（含底部系统区留白）
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    final navHeight = 76.0 + bottomInset;

    return Scaffold(
      backgroundColor: kPageBackground,
      body: Stack(
        children: [
          // 内容区：铺满全屏，避开状态栏 + 底部导航栏
          Positioned.fill(
            child: Padding(
              padding: EdgeInsets.only(
                top: MediaQuery.paddingOf(context).top,
                bottom: navHeight,
              ),
              child: IndexedStack(
                index: _tab,
                children: const [
                  NetworkStatusPage(),
                  BypassPage(),
                ],
              ),
            ),
          ),
          // 底部悬浮导航栏：自绘 + 黑块滑动动效
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: EdgeInsets.only(bottom: 12 + bottomInset),
              child: _FloatingNavBar(
                selectedIndex: _tab,
                onSelect: (i) => setState(() => _tab = i),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 自绘悬浮导航栏：白色药丸容器 + 半透明黑块指示器（AnimatedAlign 平滑滑动）
class _FloatingNavBar extends StatefulWidget {
  const _FloatingNavBar({
    required this.selectedIndex,
    required this.onSelect,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelect;

  @override
  State<_FloatingNavBar> createState() => _FloatingNavBarState();
}

class _FloatingNavBarState extends State<_FloatingNavBar> {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 62,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      // LayoutBuilder 拿到内容区精确宽度，黑块按坐标滑动，与导航项绝对对齐
      child: LayoutBuilder(
        builder: (context, c) {
          final half = c.maxWidth / 2;
          const pad = 6.0; // 黑块左右留白，让选中项两侧露出白边
          return Stack(
            children: [
              // 滑动黑块指示器
              AnimatedPositioned(
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeOutCubic,
                left: widget.selectedIndex * half + pad,
                top: 0,
                bottom: 0,
                width: half - pad * 2,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              // 两个导航项：均分宽度，黑块正好落在选中项上
              Row(
                children: [
                  Expanded(child: _navItem(0, Icons.home_rounded, '联网')),
                  Expanded(child: _navItem(1, Icons.link_rounded, 'Bypass')),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _navItem(int index, IconData icon, String label) {
    final selected = widget.selectedIndex == index;
    final color = selected ? Colors.black87 : Colors.black38;
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: () => widget.onSelect(index),
      child: SizedBox(
        height: 50,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 24, color: color),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}