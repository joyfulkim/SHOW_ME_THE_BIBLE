import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  static const _splashImage = 'assets/images/splash_bg.png';

  @override
  void initState() {
    super.initState();
    _navigateToNext();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    precacheImage(const AssetImage(_splashImage), context);
  }

  Future<void> _navigateToNext() async {
    // 포스터가 충분히 보인 후 다음 화면으로 이동
    await Future.delayed(const Duration(seconds: 4));
    if (mounted) {
      context.go('/mode-selection');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            _splashImage,
            fit: BoxFit.cover,
            alignment: Alignment.center,
            color: Colors.black.withOpacity(0.55),
            colorBlendMode: BlendMode.darken,
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Center(
                child: Image.asset(
                  _splashImage,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
