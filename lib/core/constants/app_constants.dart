class AppConstants {
  AppConstants._();

  static const String appName = 'Glintup';
  static const String appTagline = 'Your daily dose. Then you\'re done.';

  // Supabase
  static const String supabaseUrl = 'https://pbpmtqcffhqwzboviqfw.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBicG10cWNmZmhxd3pib3ZpcWZ3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDYyNzg0NDIsImV4cCI6MjA2MTg1NDQ0Mn0.SFMRxHpU_ei3MUhYOB2Bz4Gn3-JI0kVSsRRJN2xZ_hw';

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
