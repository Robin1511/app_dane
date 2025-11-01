import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:rive/rive.dart' as rive;
import 'package:app_dane/screens/entry_point.dart';

class SignInForm extends StatefulWidget {
  const SignInForm({
    super.key,
    this.useLightColors = false,
  });

  final bool useLightColors;

  @override
  State<SignInForm> createState() => _SignInFormState();
}

class _SignInFormState extends State<SignInForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool isShowLoading = false;
  
  late rive.SMITrigger error;
  late rive.SMITrigger success;
  late rive.SMITrigger reset;
  

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  void _onCheckRiveInit(rive.Artboard artboard) {
    rive.StateMachineController? controller =
        rive.StateMachineController.fromArtboard(artboard, 'State Machine 1');

    artboard.addController(controller!);
    error = controller.findInput<bool>('Error') as rive.SMITrigger;
    success = controller.findInput<bool>('Check') as rive.SMITrigger;
    reset = controller.findInput<bool>('Reset') as rive.SMITrigger;
  }

  

  void singIn(BuildContext context) {
    setState(() {
      isShowLoading = true;
    });
    Future.delayed(
      const Duration(seconds: 1),
      () {
        if (_formKey.currentState!.validate() &&
            _emailController.text.trim().toLowerCase() == 'dane.debastos' &&
            _passwordController.text == 'azer') {
          success.fire();
          Future.delayed(
            const Duration(seconds: 2),
            () {
              setState(() {
                isShowLoading = false;
              });
              if (!context.mounted) return;
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const EntryPoint(),
                ),
              );
            },
          );
        } else {
          error.fire();
          Future.delayed(
            const Duration(seconds: 2),
            () {
              setState(() {
                isShowLoading = false;
              });
              reset.fire();
            },
          );
        }
      },
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool light = widget.useLightColors;
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withOpacity(light ? 0.14 : 0.18),
                    Colors.white.withOpacity(light ? 0.06 : 0.08),
                  ],
                ),
                border: Border.all(
                  color: Colors.white.withOpacity(light ? 0.28 : 0.22),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: light ? Colors.white.withOpacity(0.12) : Colors.black.withOpacity(0.12),
                    blurRadius: 24,
                    offset: const Offset(0, 16),
                  ),
                ],
              ),
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    
                    const SizedBox(height: 16),
                    _GlassField(
                      label: "Email",
                      hint: "email@example.com",
                      icon: CupertinoIcons.envelope,
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) => (value == null || value.isEmpty) ? "Entrez votre email" : null,
                      textInputAction: TextInputAction.next,
                      light: light,
                      controller: _emailController,
                    ),
                    const SizedBox(height: 12),
                    _GlassField(
                      label: "Mot de passe",
                      hint: "••••••••",
                      icon: CupertinoIcons.lock,
                      obscureText: true,
                      validator: (value) => (value == null || value.isEmpty) ? "Entrez votre mot de passe" : null,
                      onSubmitted: (_) => singIn(context),
                      light: light,
                      controller: _passwordController,
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 56,
                      child: AbsorbPointer(
                        absorbing: isShowLoading,
                        child: CupertinoButton(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          borderRadius: BorderRadius.circular(28),
                          color: const Color(0xFF007AFF),
                          pressedOpacity: 1.0,
                          onPressed: () => singIn(context),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (!isShowLoading)
                                const Icon(CupertinoIcons.arrow_right, color: Colors.white)
                              else
                                SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: rive.RiveAnimation.asset(
                                    'assets/RiveAssets/check.riv',
                                    fit: BoxFit.contain,
                                    onInit: _onCheckRiveInit,
                                  ),
                                ),
                              const SizedBox(width: 8),
                              const Text(
                                "Continuer",
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        // L'animation de check/erreur est désormais ancrée au bouton.
      ],
    );
  }
}

// Supprimé: CustomPositioned n'est plus utilisé

class _GlassField extends StatelessWidget {
  const _GlassField({
    required this.label,
    required this.hint,
    required this.icon,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.onSubmitted,
    this.validator,
    this.light = false,
    this.controller,
  });

  final String label;
  final String hint;
  final IconData icon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final void Function(String)? onSubmitted;
  final String? Function(String?)? validator;
  final bool light;
  final TextEditingController? controller;

  @override
  Widget build(BuildContext context) {
    final baseBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(22),
      borderSide: BorderSide(color: (light ? Colors.white : Colors.black).withOpacity(0.12), width: 1),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: light ? Colors.white.withOpacity(0.9) : Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          validator: validator,
          obscureText: obscureText,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          onFieldSubmitted: onSubmitted,
          controller: controller,
          style: TextStyle(color: light ? Colors.white : Colors.black),
          decoration: InputDecoration(
            filled: true,
            fillColor: light ? Colors.white.withOpacity(0.16) : Colors.white.withOpacity(0.55),
            hintText: hint,
            hintStyle: TextStyle(color: (light ? Colors.white : Colors.black).withOpacity(0.55)),
            prefixIcon: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Icon(icon, color: light ? Colors.white : Colors.black),
            ),
            prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            enabledBorder: baseBorder,
            focusedBorder: baseBorder.copyWith(
              borderSide: BorderSide(color: (light ? Colors.white : Colors.black), width: 1.2),
            ),
            errorBorder: baseBorder.copyWith(
              borderSide: const BorderSide(color: Colors.redAccent),
            ),
            focusedErrorBorder: baseBorder.copyWith(
              borderSide: const BorderSide(color: Colors.redAccent, width: 1.2),
            ),
          ),
        ),
      ],
    );
  }
}
