class ApiPaths {
  const ApiPaths._();

  static const login = '/auth/login';
  static const signup = '/auth/signup';
  static const me = '/me';
  static const examTypes = '/exam-types';
  static const exams = '/exams';
  static const examFeed = '/my/exam-feed';
  static const attempts = '/my/attempts';
  static const studyInsights = '/my/study-insights';
  static const leaderboard = '/leaderboard';
  static const engagement = '/me/engagement';
  static const packages = '/packages';
  static const myPurchases = '/my/purchases';
  static const verifyPayment = '/payments/verify';
  static const communityRooms = '/community/rooms';
  static const communityDisplayName = '/community/me/display-name';
  static const fcmRegister = '/me/push/fcm/register';

  static String examDetail(String slug) => '/exams/$slug';
  static String startExam(String slug) => '/exams/$slug/start';
  static String submitAttempt(String attemptId) => '/attempts/$attemptId/submit';
  static String attemptProgress(String attemptId) => '/attempts/$attemptId/progress';
  static String attemptDetail(String attemptId) => '/my/attempts/$attemptId';
  static String packageCheckout(String slug) => '/packages/$slug/checkout';
  static String communityMessages(String roomId) => '/community/rooms/$roomId/messages';
  static String communityJoin(String roomId) => '/community/rooms/$roomId/join';
  static String communityRead(String roomId) => '/community/rooms/$roomId/read';
  static String communityReport(String messageId) => '/community/messages/$messageId/report';
}
