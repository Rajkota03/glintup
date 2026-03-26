class AppConstants {
  AppConstants._();

  static const String appName = 'Glintup';
  static const String appTagline = 'Your daily dose. Then you\'re done.';

  // Supabase
  static const String supabaseUrl = 'https://rghybidicpnlofzzufru.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJnaHliaWRpY3BubG9menp1ZnJ1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQzNzMxNDUsImV4cCI6MjA4OTk0OTE0NX0.NImgok7SGi4LWiSlIPECGtYPBMg_wiG-Lye3yikZYlg';

  // Edition config
  static const int freeEditionCardCount = 10;
  static const int proEditionCardCount = 10;
  static const int maxReadMinutesFree = 15;
  static const int maxReadMinutesPro = 15;

  // Onboarding
  static const int minTopicsToSelect = 3;
  static const int maxTopicsToSelect = 7;

  // Streaks
  static const int xpPerCard = 10;
  static const int xpStreakBonus = 25;

  // Explore
  static const int explorePageSize = 20;

  // OTP
  static const int otpLength = 6;
  static const int otpExpiryMinutes = 10;
}
