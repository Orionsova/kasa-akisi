import 'package:flutter/material.dart';

abstract class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF1E3A8A);
  static const Color primaryVariant = Color(0xFF162C6F);
  static const Color secondary = Color(0xFF3B82F6);
  static const Color secondaryVariant = Color(0xFF2563EB);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color background = Color(0xFFF8FAFC);
  static const Color error = Color(0xFFEF4444);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color onSurface = Color(0xFF1E293B);
  static const Color onBackground = Color(0xFF1E293B);
  static const Color onError = Color(0xFFFFFFFF);

  static const Color accent = Color(0xFF22C55E);
  static const Color accentVariant = Color(0xFF16A34A);

  static const Color neutral100 = Color(0xFFF8FAFC);
  static const Color neutral200 = Color(0xFFE2E8F0);
  static const Color neutral300 = Color(0xFFCBD5E1);
  static const Color neutral400 = Color(0xFF94A3B8);
  static const Color neutral500 = Color(0xFF64748B);
  static const Color neutral600 = Color(0xFF475569);
  static const Color neutral700 = Color(0xFF334155);
  static const Color neutral800 = Color(0xFF1E293B);
  static const Color neutral900 = Color(0xFF0F172A);

  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF38BDF8);
  static const Color danger = Color(0xFFEF4444);

  // Dark Mode Colors - Premium Palette
  static const Color darkPrimary = Color(0xFF6366F1); // Indigo
  static const Color darkPrimaryVariant = Color(0xFF4F46E5);
  static const Color darkSecondary = Color(0xFF8B5CF6); // Purple
  static const Color darkSecondaryVariant = Color(0xFF7C3AED);
  static const Color darkAccent = Color(0xFF06B6D4); // Cyan
  static const Color darkAccentVariant = Color(0xFF0891B2);

  static const Color darkSurface = Color(0xFF0F172A); // Rich dark blue-gray
  static const Color darkSurfaceVariant = Color(0xFF1E293B);
  static const Color darkBackground = Color(0xFF020617); // Deep navy
  static const Color darkCard = Color(0xFF1E293B); // Elevated surface

  static const Color darkOnPrimary = Color(0xFFFFFFFF);
  static const Color darkOnSecondary = Color(0xFFFFFFFF);
  static const Color darkOnSurface = Color(0xFFF1F5F9);
  static const Color darkOnBackground = Color(0xFFE2E8F0);

  // Dark Mode Neutrals - Premium grays
  static const Color darkNeutral50 = Color(0xFFF8FAFC);
  static const Color darkNeutral100 = Color(0xFFF1F5F9);
  static const Color darkNeutral200 = Color(0xFFE2E8F0);
  static const Color darkNeutral300 = Color(0xFFCBD5E1);
  static const Color darkNeutral400 = Color(0xFF94A3B8);
  static const Color darkNeutral500 = Color(0xFF64748B);
  static const Color darkNeutral600 = Color(0xFF475569);
  static const Color darkNeutral700 = Color(0xFF334155);
  static const Color darkNeutral800 = Color(0xFF1E293B);
  static const Color darkNeutral900 = Color(0xFF0F172A);

  // Dark Mode Semantic Colors
  static const Color darkSuccess = Color(0xFF10B981); // Emerald
  static const Color darkWarning = Color(0xFFF59E0B); // Amber
  static const Color darkError = Color(0xFFEF4444); // Red
  static const Color darkInfo = Color(0xFF06B6D4); // Cyan

  // Gradient Colors for Premium Feel
  static const Color gradientStart = Color(0xFF6366F1);
  static const Color gradientMiddle = Color(0xFF8B5CF6);
  static const Color gradientEnd = Color(0xFF06B6D4);
}
