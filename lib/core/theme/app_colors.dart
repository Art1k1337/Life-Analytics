import 'package:flutter/material.dart';

class AppColors {
  const AppColors._();

  static const Color ink = Color(0xFF1A1D26);
  static const Color paper = Color(0xFFF2F4F8);
  static const Color night = Color(0xFF0B0E14);
  static const Color nightElevated = Color(0xFF161A24);
  static const Color nightCard = Color(0xFF1C2030);

  static const Color blue = Color(0xFF5B8DEF);
  static const Color blueLight = Color(0xFF8AB4FF);
  static const Color mint = Color(0xFF34D399);
  static const Color coral = Color(0xFFFF6B81);
  static const Color amber = Color(0xFFFFBE30);
  static const Color violet = Color(0xFF9B8AFF);
  static const Color cyan = Color(0xFF38BDF8);
  static const Color pink = Color(0xFFF472B6);

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [blue, violet],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient successGradient = LinearGradient(
    colors: [mint, cyan],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient warmGradient = LinearGradient(
    colors: [amber, coral],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
