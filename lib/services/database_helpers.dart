import 'package:uuid/uuid.dart';

class DatabaseHelper {
  static const Uuid _uuid = Uuid();

  // Gerar ID único
  static String generateId() => _uuid.v4();

  // Converter DateTime para string SQLite
  static String dateTimeToString(DateTime dateTime) {
    return dateTime.toIso8601String();
  }

  // Converter string SQLite para DateTime
  static DateTime stringToDateTime(String dateString) {
    return DateTime.parse(dateString);
  }

  // Converter bool para int (SQLite)
  static int boolToInt(bool value) => value ? 1 : 0;

  // Converter int para bool (SQLite)
  static bool intToBool(int value) => value == 1;

  // Escapar string para SQL
  static String escapeString(String input) {
    return input.replaceAll("'", "''");
  }

  // Verificar se string é um UUID válido
  static bool isValidUuid(String uuid) {
    try {
      Uuid.parse(uuid);
      return true;
    } catch (e) {
      return false;
    }
  }

  // Formatar query com parâmetros
  static String formatQuery(String query, List<dynamic> params) {
    String formattedQuery = query;
    for (int i = 0; i < params.length; i++) {
      formattedQuery = formattedQuery.replaceFirst('?', "'${params[i]}'");
    }
    return formattedQuery;
  }
}
