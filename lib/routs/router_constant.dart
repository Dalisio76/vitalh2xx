// ===== ROUTE CONSTANTS =====
// lib/app/routes/route_constants.dart

class RouteConstants {
  // Route parameters
  static const String CLIENT_ID = 'clientId';
  static const String READING_ID = 'readingId';
  static const String PAYMENT_ID = 'paymentId';
  static const String MONTH = 'month';
  static const String YEAR = 'year';

  // Route arguments
  static const String CLIENT_DATA = 'clientData';
  static const String READING_DATA = 'readingData';
  static const String PAYMENT_DATA = 'paymentData';
  static const String EDIT_MODE = 'editMode';
  static const String RETURN_ROUTE = 'returnRoute';

  // Default routes by role
  static const Map<String, String> DEFAULT_ROUTES = {
    'admin': '/dashboard',
    'cashier': '/home',
    'fieldOperator': '/readings',
  };
}
