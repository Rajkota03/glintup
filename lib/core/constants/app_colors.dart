import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Brand
  static const Color primary = Color(0xFFC8A951);        // Warm gold
  static const Color primaryLight = Color(0xFFE8D5A0);    // Light gold
  static const Color primaryDark = Color(0xFFA88B3D);     // Deep gold

  // Backgrounds
  static const Color background = Color(0xFFFAF9F6);      // Warm cream/ivory
  static const Color surface = Color(0xFFFFFFFF);          // Pure white cards
  static const Color surfaceAlt = Color(0xFFF5F3EE);       // Slightly darker cream

  // Text
  static const Color textPrimary = Color(0xFF1A1A1A);      // Deep charcoal
  static const Color textSecondary = Color(0xFF6B6B6B);    // Warm gray
  static const Color textTertiary = Color(0xFF9B9B9B);     // Light gray
  static const Color textOnPrimary = Color(0xFFFFFFFF);    // White on gold

  // Borders & Dividers
  static const Color divider = Color(0xFFE8E5E0);          // Warm divider
  static const Color border = Color(0xFFE0DDD7);           // Card border

  // Status
  static const Color success = Color(0xFF2D5016);          // Deep forest green
  static const Color successLight = Color(0xFFE8F5E1);     // Light green bg
  static const Color error = Color(0xFFC44545);            // Muted red
  static const Color errorLight = Color(0xFFFDE8E8);       // Light red bg

  // Card type accents (muted, sophisticated versions)
  static const Color quickFact = Color(0xFF5B8A72);        // Sage green
  static const Color insight = Color(0xFF6B7DB3);          // Dusty blue
  static const Color visual = Color(0xFFD4A053);           // Warm amber
  static const Color story = Color(0xFF8B6B99);            // Muted purple
  static const Color deepRead = Color(0xFF3D7A68);         // Deep teal
  static const Color question = Color(0xFFC47A5A);         // Terracotta
  static const Color quote = Color(0xFFC8A951);            // Gold (matches primary)

  // Topic colors (muted, elegant)
  static const Color science = Color(0xFF5B8A72);          // Sage
  static const Color history = Color(0xFFD4A053);          // Amber
  static const Color psychology = Color(0xFF8B6B99);       // Lavender
  static const Color technology = Color(0xFF6B7DB3);       // Steel blue
  static const Color arts = Color(0xFFC47A5A);             // Terracotta
  static const Color business = Color(0xFF7A8B6B);         // Olive
  static const Color nature = Color(0xFF3D7A68);           // Teal
  static const Color space = Color(0xFF5B6B99);            // Slate blue

  // Streak colors
  static const Color streakActive = Color(0xFFC8A951);     // Gold
  static const Color streakInactive = Color(0xFFE8E5E0);   // Light gray

  // Gradients
  static const List<Color> goldGradient = [Color(0xFFC8A951), Color(0xFFE8D5A0)];
  static const List<Color> warmGradient = [Color(0xFFFAF9F6), Color(0xFFF0EDE5)];
  static const List<Color> streakGradient = [Color(0xFFC8A951), Color(0xFFD4A053), Color(0xFFE8D5A0)];

  // Card type background tints (very subtle, for card backgrounds)
  static const Color quickFactBg = Color(0xFFF2F7F4);     // Faint sage
  static const Color insightBg = Color(0xFFF2F4F9);       // Faint blue
  static const Color visualBg = Color(0xFFFAF6EF);        // Faint amber
  static const Color storyBg = Color(0xFFF6F2F8);         // Faint purple
  static const Color deepReadBg = Color(0xFFF0F6F4);      // Faint teal
  static const Color questionBg = Color(0xFFFAF3EF);      // Faint terracotta
  static const Color quoteBg = Color(0xFFFAF8F2);         // Faint gold

  // Dark mode (for future night mode)
  static const Color darkBackground = Color(0xFF1A1A1A);
  static const Color darkSurface = Color(0xFF242424);
  static const Color darkTextPrimary = Color(0xFFFAF9F6);
  static const Color darkTextSecondary = Color(0xFF9B9B9B);

  // ── Legacy aliases (keep existing code compiling) ──
  static const Color accent = primary;
  static const Color accentLight = primaryLight;
  static const Color textMuted = textTertiary;
  static const Color cardBackground = surface;
  static const Color warning = Color(0xFFD4A053);
  static const Color streakFire = streakActive;
  static const Color streakGold = primary;
}
