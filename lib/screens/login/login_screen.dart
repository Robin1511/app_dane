import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:rive/rive.dart' hide Image;
import 'components/sign_in_dialog.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool isShowSignInDialog = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onVerticalDragUpdate: (details) {
          if (details.delta.dy < -8 && !isShowSignInDialog) {
            setState(() {
              isShowSignInDialog = true;
            });
            if (!context.mounted) return;
            showCustomDialog(
              context,
              onValue: (_) {
                if (mounted) {
                  setState(() {
                    isShowSignInDialog = false;
                  });
                }
              },
            );
          }
        },
        onVerticalDragEnd: (details) {
          if (details.primaryVelocity != null && details.primaryVelocity! < -300 && !isShowSignInDialog) {
            setState(() {
              isShowSignInDialog = true;
            });
            if (!context.mounted) return;
            showCustomDialog(
              context,
              onValue: (_) {
                if (mounted) {
                  setState(() {
                    isShowSignInDialog = false;
                  });
                }
              },
            );
          }
        },
        child: Stack(
          children: [
            Positioned(
              width: MediaQuery.of(context).size.width * 1.7,
              left: 100,
              bottom: 100,
              child: Image.asset(
                "assets/Backgrounds/Spline.png",
              ),
            ),
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: const SizedBox(),
              ),
            ),
            const RiveAnimation.asset(
              "assets/RiveAssets/shapes.riv",
            ),
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                child: const SizedBox(),
              ),
            ),
            AnimatedPositioned(
              top: isShowSignInDialog ? -50 : 0,
              height: MediaQuery.of(context).size.height,
              width: MediaQuery.of(context).size.width,
              duration: const Duration(milliseconds: 260),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Spacer(),
                      SizedBox(
                        width: 260,
                        child: Column(
                          children: [
                            Image.asset("assets/logo_app_noir.png"),
                          ],
                        ),
                      ),
                      const Spacer(flex: 2),
                      const SizedBox(height: 72),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: IgnorePointer(
                child: SizedBox(
                  height: 250,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Spacer(),
                      Icon(
                        Icons.keyboard_arrow_up,
                        size: 40,
                        color: Colors.black.withOpacity(0.9),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Swipe up',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.black.withOpacity(0.9),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
