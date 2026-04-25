import 'package:flutter/material.dart';

class PsyCareLogo extends StatelessWidget {
  final double size;

  // showText is kept for API compatibility but has no effect —
  // the logo image already contains the "PSYCARE" wordmark.
  // ignore: avoid_unused_constructor_parameters
  const PsyCareLogo({
    super.key,
    this.size = 80,
    bool showText = false,
  });

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/logo.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
    );
  }
}
