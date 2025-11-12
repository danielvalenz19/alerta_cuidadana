import 'package:flutter/material.dart';

import 'tokens.dart';

class BrandDecorations extends ThemeExtension<BrandDecorations> {
  final Gradient screenGradient;
  final Gradient actionGradient;
  final Gradient cardGradient;
  final List<BoxShadow> floatingShadow;

  const BrandDecorations({
    required this.screenGradient,
    required this.actionGradient,
    required this.cardGradient,
    required this.floatingShadow,
  });

  factory BrandDecorations.light() => BrandDecorations(
    screenGradient: const LinearGradient(
      colors: [Tokens.lightBackground, Colors.white],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
    actionGradient: LinearGradient(
      colors: [Tokens.brand700, Tokens.accentCyan],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    cardGradient: LinearGradient(
      colors: [Tokens.lightSurface, Tokens.lightSurfaceMut],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    floatingShadow: const [
      BoxShadow(
        color: Color(0x332F5F8F),
        blurRadius: 26,
        offset: Offset(0, 18),
      ),
    ],
  );

  factory BrandDecorations.dark() => BrandDecorations(
    screenGradient: const LinearGradient(
      colors: [Tokens.midnight, Tokens.darkBackground],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
    actionGradient: LinearGradient(
      colors: [Tokens.accentPurple, Tokens.accentCyan],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    cardGradient: LinearGradient(
      colors: [Tokens.darkSurface, Tokens.darkSurfaceMut],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    floatingShadow: const [
      BoxShadow(color: Tokens.darkGlow, blurRadius: 30, offset: Offset(0, 18)),
    ],
  );

  @override
  BrandDecorations copyWith({
    Gradient? screenGradient,
    Gradient? actionGradient,
    Gradient? cardGradient,
    List<BoxShadow>? floatingShadow,
  }) {
    return BrandDecorations(
      screenGradient: screenGradient ?? this.screenGradient,
      actionGradient: actionGradient ?? this.actionGradient,
      cardGradient: cardGradient ?? this.cardGradient,
      floatingShadow: floatingShadow ?? this.floatingShadow,
    );
  }

  @override
  BrandDecorations lerp(ThemeExtension<BrandDecorations>? other, double t) {
    if (other is! BrandDecorations) return this;
    return BrandDecorations(
      screenGradient: Gradient.lerp(screenGradient, other.screenGradient, t)!,
      actionGradient: Gradient.lerp(actionGradient, other.actionGradient, t)!,
      cardGradient: Gradient.lerp(cardGradient, other.cardGradient, t)!,
      floatingShadow: List.generate(
        floatingShadow.length,
        (index) => BoxShadow.lerp(
          floatingShadow[index],
          other.floatingShadow[index],
          t,
        )!,
      ),
    );
  }
}
