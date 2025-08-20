// ===== APP ROUTES =====
// lib/app/routes/app_routes.dart

abstract class Routes {
  // Auth Routes
  static const SPLASH = '/splash';
  static const LOGIN = '/login';

  // Main Routes
  static const HOME = '/home';
  static const DASHBOARD = '/dashboard';

  // Client Routes
  static const CLIENTS = '/clients';
  static const CLIENT_FORM = '/clients/form';
  static const CLIENT_DETAIL = '/clients/detail';
  static const CLIENT_HISTORY = '/clients/history';

  // Reading Routes
  static const READINGS = '/readings';
  static const READINGS_ONLY = '/readings/only';
  static const READING_FORM = '/readings/form';
  static const MONTHLY_READINGS = '/readings/monthly';
  static const READING_DETAIL = '/readings/detail';
  
  // Debt Management Routes
  static const DEBTS_MANAGEMENT = '/debts/management';

  // Payment Routes
  static const PAYMENTS = '/payments';
  static const PAYMENT_FORM = '/payments/form';
  static const PAYMENT_HISTORY = '/payments/history';
  static const PAYMENT_RECEIPT = '/payments/receipt';

  // Report Routes
  static const REPORTS = '/reports';
  static const MONTHLY_REPORT = '/reports/monthly';
  static const DEBT_REPORT = '/reports/debt';
  static const CONSUMPTION_REPORT = '/reports/consumption';
  static const PAYMENT_METHOD_REPORT = '/reports/payment-methods';
  static const REVENUE_REPORT = '/reports/revenue';
  static const MISSING_READINGS_REPORT = '/reports/missing-readings';

  // User Management Routes
  static const USERS = '/users';
  static const USER_FORM = '/users/form';
  static const USER_DETAIL = '/users/detail';
  
  // Settings Routes
  static const SETTINGS = '/settings';
  static const USER_PROFILE = '/settings/profile';
  static const SYSTEM_SETTINGS = '/settings/system';
  static const PRINTER_SETTINGS = '/settings/printer';
  static const PRINT_SETTINGS = '/settings/print';
  static const BILLING_SETTINGS = '/settings/billing';

  // Print Routes
  static const PRINT_BILL = '/print/bill';
  static const PRINT_RECEIPT = '/print/receipt';
  static const PRINT_REPORT = '/print/report';

  // Help Routes
  static const HELP = '/help';
  static const ABOUT = '/about';
}
