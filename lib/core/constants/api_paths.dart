class ApiPaths {
  const ApiPaths._();

  static const login = '/auth/login';
  static const signup = '/auth/signup';
  static const forgotPassword = '/auth/forgot-password';
  static const resetPassword = '/auth/reset-password';
  static const verifyEmail = '/auth/verify-email';
  static const resendVerification = '/auth/resend-verification';
  static const me = '/me';
  static const changePassword = '/me/change-password';
  static const preferences = '/me/preferences';
  static const avatar = '/me/avatar';
  static const parentShare = '/me/parent-share';
  static const referralApply = '/me/referral/apply';
  static const referralCode = '/me/referral/code';
  static const bulkLicenseRedeem = '/me/bulk-license/redeem';
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
  static const jambSyllabus = '/jamb/syllabus';
  static const postUtmePacks = '/post-utme/packs';

  static String examTypeDetail(String slug) => '/exam-types/$slug';
  static String examDetail(String slug) => '/exams/$slug';
  static String startExam(String slug) => '/exams/$slug/start';
  static String submitAttempt(String attemptId) => '/attempts/$attemptId/submit';
  static String attemptProgress(String attemptId) => '/attempts/$attemptId/progress';
  static String attemptDetail(String attemptId) => '/my/attempts/$attemptId';
  static String attemptChallenge(String attemptId) => '/my/attempts/$attemptId/challenge';
  static String packageCheckout(String slug) => '/packages/$slug/checkout';
  static String communityMessages(String roomId) => '/community/rooms/$roomId/messages';
  static String communityJoin(String roomId) => '/community/rooms/$roomId/join';
  static String communityRead(String roomId) => '/community/rooms/$roomId/read';
  static String communityReport(String messageId) => '/community/messages/$messageId/report';
  static String publicChallenge(String token) => '/public/challenges/$token';
  static String publicParentView(String token) => '/public/parent/$token';
  static String postUtmePackDetail(String slug) => '/post-utme/packs/$slug';
}
