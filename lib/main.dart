import 'package:flutter/material.dart';
import 'package:flutter_miuix/miuix.dart';

import 'pages/network_status_page.dart';
import 'pages/bypass_page.dart';

void main() {
  runApp(const MiApp());
}

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
    // MiuixFloatingNavigationBar 内部自带底部系统区留白：
    //   有手势条/虚拟键(inset>0) → 26+inset，药丸高52 → 总高 78+inset
    //   无系统区(inset==0)       → 36，       药丸高52 → 总高 88
    // 外层不用 SafeArea，避免双重 inset；高度动态给，让药丸始终贴底。
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    final barHeight = bottomInset > 0 ? 78.0 + bottomInset : 88.0;

    return Scaffold(
      backgroundColor: theme.colors.background,
      body: Stack(
        children: [
          // 内容区：铺满全屏，顶部避开状态栏，底部预留悬浮栏空间
          Positioned.fill(
            child: Padding(
              padding: EdgeInsets.only(
                top: MediaQuery.paddingOf(context).top,
                bottom: barHeight,
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
          // 底部悬浮tab：必须用固定高度容器限制内部 Align 扩张，
          // 否则 MiuixFloatingNavigationBar 内部的 Align(center) 会铺满全屏
          // 把药丸导航甩到屏幕正中间。
          Align(
            alignment: Alignment.bottomCenter,
            child: SizedBox(
              height: barHeight,
              child: MiuixFloatingNavigationBar(
                children: [
                  MiuixFloatingNavigationBarItem(
                    selected: _tab == 0,
                    icon: MiuixIcon(
                      vector: MiuixIcons.extended.byName('home')!,
                      size: 24,
                    ),
                    label: '联网',
                    onPressed: () => setState(() => _tab = 0),
                  ),
                  MiuixFloatingNavigationBarItem(
                    selected: _tab == 1,
                    icon: MiuixIcon(
                      vector: MiuixIcons.extended.byName('link')!,
                      size: 24,
                    ),
                    label: 'Bypass',
                    onPressed: () => setState(() => _tab = 1),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}