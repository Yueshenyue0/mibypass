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

    return Scaffold(
      backgroundColor: theme.colors.background,
      body: SafeArea(
        child: Stack(
          children: [
            // 内容区：铺满全屏，绝不空白
            Positioned.fill(
              child: IndexedStack(
                index: _tab,
                children: const [
                  NetworkStatusPage(),
                  BypassPage(),
                ],
              ),
            ),
            // 底部悬浮 tab（InstallerX 风格药丸）
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 16),
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
      ),
    );
  }
}