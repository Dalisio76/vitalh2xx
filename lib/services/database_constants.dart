class DatabaseConstants {
  // Nomes das tabelas
  static const String usersTable = 'users';
  static const String clientsTable = 'clients';
  static const String readingsTable = 'readings';
  static const String paymentsTable = 'payments';

  // Colunas comuns
  static const String id = 'id';
  static const String createdAt = 'created_at';
  static const String updatedAt = 'updated_at';
  static const String isSynced = 'is_synced';

  // Colunas da tabela users
  static const String userName = 'name';
  static const String userEmail = 'email';
  static const String userPhone = 'phone';
  static const String userRole = 'role';
  static const String userPasswordHash = 'password_hash';
  static const String userLastLogin = 'last_login';
  static const String userIsActive = 'is_active';

  // Colunas da tabela clients
  static const String clientName = 'name';
  static const String clientContact = 'contact';
  static const String clientReference = 'reference';
  static const String clientCounterNumber = 'counter_number';
  static const String clientIsActive = 'is_active';
  static const String clientLastReading = 'last_reading';
  static const String clientTotalDebt = 'total_debt';

  // Colunas da tabela readings
  static const String readingClientId = 'client_id';
  static const String readingMonth = 'month';
  static const String readingYear = 'year';
  static const String readingPrevious = 'previous_reading';
  static const String readingCurrent = 'current_reading';
  static const String readingConsumption = 'consumption';
  static const String readingBillAmount = 'bill_amount';
  static const String readingDate = 'reading_date';
  static const String readingPaymentStatus = 'payment_status';
  static const String readingPaymentDate = 'payment_date';
  static const String readingNotes = 'notes';

  // Colunas da tabela payments
  static const String paymentClientId = 'client_id';
  static const String paymentReadingId = 'reading_id';
  static const String paymentAmount = 'amount_paid';
  static const String paymentMethod = 'payment_method';
  static const String paymentDate = 'payment_date';
  static const String paymentReceiptNumber = 'receipt_number';
  static const String paymentTransactionRef = 'transaction_reference';
  static const String paymentNotes = 'notes';
  static const String paymentUserId = 'user_id';
}
