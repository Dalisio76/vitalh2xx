// ===== ESTILOS COMPACTOS PARA A APLICAÇÃO =====
// Baseado no sistema de produtos - interface mais eficiente

import 'package:flutter/material.dart';

class AppStyles {
  // ===== CORES =====
  static const Color primaryColor = Color(0xFF2196F3);
  static const Color secondaryColor = Color(0xFF4CAF50);
  static const Color errorColor = Color(0xFFE53935);
  static const Color warningColor = Color(0xFFFF9800);
  static const Color backgroundColor = Color(0xFFF5F5F5);

  // ===== ESPAÇAMENTOS ULTRA COMPACTOS =====
  static const double paddingTiny = 2.0;
  static const double paddingSmall = 4.0;
  static const double paddingMedium = 6.0;
  static const double paddingLarge = 8.0;
  static const double paddingXLarge = 12.0;

  // ===== TAMANHOS DE BOTÕES ULTRA COMPACTOS =====
  static const double buttonHeightTiny = 24.0;
  static const double buttonHeightSmall = 28.0;
  static const double buttonHeightMedium = 32.0;
  static const double buttonHeightLarge = 36.0;

  // ===== TAMANHOS DE TEXTO ULTRA COMPACTOS =====
  static const double fontSizeTiny = 9.0;
  static const double fontSizeSmall = 10.0;
  static const double fontSizeMedium = 12.0;
  static const double fontSizeLarge = 14.0;
  static const double fontSizeTitle = 16.0;

  // ===== ESTILOS DE BOTÕES COMPACTOS =====
  static ButtonStyle compactButtonStyle({
    Color? backgroundColor,
    Color? foregroundColor,
    double? fontSize,
  }) {
    return ElevatedButton.styleFrom(
      backgroundColor: backgroundColor ?? primaryColor,
      foregroundColor: foregroundColor ?? Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: paddingLarge, vertical: paddingSmall),
      minimumSize: const Size(60, buttonHeightSmall),
      textStyle: TextStyle(
        fontSize: fontSize ?? fontSizeSmall,
        fontWeight: FontWeight.w500,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  static ButtonStyle tinyButtonStyle({
    Color? backgroundColor,
    Color? foregroundColor,
  }) {
    return ElevatedButton.styleFrom(
      backgroundColor: backgroundColor ?? primaryColor,
      foregroundColor: foregroundColor ?? Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: paddingMedium, vertical: paddingTiny),
      minimumSize: const Size(50, buttonHeightTiny),
      textStyle: const TextStyle(
        fontSize: fontSizeTiny,
        fontWeight: FontWeight.w500,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  static ButtonStyle compactIconButtonStyle({
    Color? backgroundColor,
    Color? foregroundColor,
  }) {
    return ElevatedButton.styleFrom(
      backgroundColor: backgroundColor ?? primaryColor,
      foregroundColor: foregroundColor ?? Colors.white,
      padding: const EdgeInsets.all(8),
      minimumSize: const Size(buttonHeightMedium, buttonHeightMedium),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  // ===== ESTILOS DE TEXTO COMPACTOS =====
  static const TextStyle compactTitle = TextStyle(
    fontSize: fontSizeTitle,
    fontWeight: FontWeight.bold,
    color: Colors.black87,
  );

  static const TextStyle compactSubtitle = TextStyle(
    fontSize: fontSizeMedium,
    fontWeight: FontWeight.w500,
    color: Colors.black87,
  );

  static const TextStyle compactBody = TextStyle(
    fontSize: fontSizeMedium,
    color: Colors.black87,
  );

  static const TextStyle compactCaption = TextStyle(
    fontSize: fontSizeSmall,
    color: Colors.black54,
  );

  // ===== ESTILOS DE CAMPO DE TEXTO COMPACTOS =====
  static InputDecoration compactInputDecoration({
    String? labelText,
    String? hintText,
    IconData? prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      prefixIcon: prefixIcon != null ? Icon(prefixIcon, size: 18) : null,
      suffixIcon: suffixIcon,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: BorderSide(color: primaryColor, width: 2),
      ),
      filled: true,
      fillColor: Colors.white,
      labelStyle: const TextStyle(fontSize: fontSizeMedium),
      hintStyle: TextStyle(fontSize: fontSizeMedium, color: Colors.grey[500]),
    );
  }

  // ===== ESTILOS DE CARTÕES COMPACTOS =====
  static BoxDecoration compactCardDecoration({
    Color? color,
    bool isSelected = false,
  }) {
    return BoxDecoration(
      color: isSelected ? primaryColor.withOpacity(0.1) : (color ?? Colors.white),
      border: Border.all(
        color: isSelected ? primaryColor : Colors.grey[300]!,
        width: isSelected ? 2 : 1,
      ),
      borderRadius: BorderRadius.circular(4),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 2,
          offset: const Offset(0, 1),
        ),
      ],
    );
  }

  // ===== ESTILOS DE LISTA COMPACTA =====
  static Widget compactListTile({
    required Widget leading,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
    bool isSelected = false,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: compactCardDecoration(isSelected: isSelected),
      child: ListTile(
        leading: leading,
        title: Text(
          title,
          style: compactSubtitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle,
                style: compactCaption,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              )
            : null,
        trailing: trailing,
        onTap: onTap,
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        minVerticalPadding: 0,
      ),
    );
  }

  // ===== ESTILOS DE CHECKBOX COMPACTO =====
  static Widget compactCheckbox({
    required bool value,
    required ValueChanged<bool?> onChanged,
    double size = 18,
  }) {
    return SizedBox(
      width: size,
      height: size,
      child: Checkbox(
        value: value,
        onChanged: onChanged,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
      ),
    );
  }

  // ===== ESTILOS DE TABELA ESTILO EXCEL =====
  static Widget dataTable({
    required List<String> headers,
    required List<List<String>> rows,
    List<double>? columnWidths,
    Function(int)? onRowTap,
    List<int> selectedRows = const [],
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!, width: 1),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Column(
        children: [
          // Header
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[100],
              border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
            ),
            child: Row(
              children: headers.asMap().entries.map((entry) {
                int index = entry.key;
                String header = entry.value;
                double width = columnWidths != null && index < columnWidths.length 
                    ? columnWidths[index] 
                    : 100.0;
                return Container(
                  width: width,
                  height: 28,
                  padding: const EdgeInsets.symmetric(horizontal: paddingMedium, vertical: paddingTiny),
                  decoration: BoxDecoration(
                    border: Border(
                      right: index < headers.length - 1 
                          ? BorderSide(color: Colors.grey[300]!) 
                          : BorderSide.none,
                    ),
                  ),
                  child: Text(
                    header,
                    style: const TextStyle(
                      fontSize: fontSizeTiny,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
            ),
          ),
          // Rows
          Expanded(
            child: ListView.builder(
              itemCount: rows.length,
              itemBuilder: (context, rowIndex) {
                List<String> row = rows[rowIndex];
                bool isSelected = selectedRows.contains(rowIndex);
                return InkWell(
                  onTap: onRowTap != null ? () => onRowTap(rowIndex) : null,
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected ? primaryColor.withOpacity(0.1) : 
                             (rowIndex % 2 == 0 ? Colors.white : Colors.grey[50]),
                      border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
                    ),
                    child: Row(
                      children: row.asMap().entries.map((entry) {
                        int cellIndex = entry.key;
                        String cell = entry.value;
                        double width = columnWidths != null && cellIndex < columnWidths.length 
                            ? columnWidths[cellIndex] 
                            : 100.0;
                        return Container(
                          width: width,
                          height: 24,
                          padding: const EdgeInsets.symmetric(horizontal: paddingMedium, vertical: paddingTiny),
                          decoration: BoxDecoration(
                            border: Border(
                              right: cellIndex < row.length - 1 
                                  ? BorderSide(color: Colors.grey[200]!) 
                                  : BorderSide.none,
                            ),
                          ),
                          child: Text(
                            cell,
                            style: const TextStyle(
                              fontSize: fontSizeTiny,
                              color: Colors.black87,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ===== LISTA COMPACTA ESTILO EXCEL =====
  static Widget excelListTile({
    required String title,
    required List<String> details,
    Widget? leading,
    Widget? trailing,
    VoidCallback? onTap,
    bool isSelected = false,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 26,
        decoration: BoxDecoration(
          color: isSelected ? primaryColor.withOpacity(0.1) : Colors.white,
          border: Border(bottom: BorderSide(color: Colors.grey[200]!, width: 0.5)),
        ),
        child: Row(
          children: [
            if (leading != null) ...[
              SizedBox(width: 32, child: leading),
              Container(width: 1, color: Colors.grey[200]),
            ],
            Expanded(
              flex: 3,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: paddingMedium),
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: fontSizeTiny,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            ...details.asMap().entries.map((entry) {
              return Expanded(
                flex: 2,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: paddingMedium),
                  decoration: BoxDecoration(
                    border: Border(left: BorderSide(color: Colors.grey[200]!, width: 0.5)),
                  ),
                  child: Text(
                    entry.value,
                    style: const TextStyle(fontSize: fontSizeTiny),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              );
            }).toList(),
            if (trailing != null) ...[
              Container(width: 1, color: Colors.grey[200]),
              SizedBox(width: 40, child: trailing),
            ],
          ],
        ),
      ),
    );
  }

  // ===== TEMA GLOBAL COMPACTO =====
  static ThemeData get compactTheme {
    return ThemeData(
      primarySwatch: Colors.blue,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundColor,
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 2,
        titleTextStyle: TextStyle(
          fontSize: fontSizeTitle,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        toolbarHeight: 48,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: compactButtonStyle(),
      ),
      inputDecorationTheme: InputDecorationTheme(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
      listTileTheme: const ListTileThemeData(
        dense: true,
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        minVerticalPadding: 0,
      ),
      cardTheme: CardTheme(
        elevation: 1,
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
      ),
      visualDensity: VisualDensity.compact,
    );
  }
}