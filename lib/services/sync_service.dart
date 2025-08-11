import 'dart:async';
import 'dart:convert';
import 'package:get/get.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vitalh2x/models/cliente_model.dart';
import 'package:vitalh2x/models/leitura_model.dart';
import 'package:vitalh2x/models/pagamento_model.dart';
import 'package:vitalh2x/services/app_config.dart';
import 'package:vitalh2x/services/http_service.dart';
import 'package:vitalh2x/services/database_providers.dart';

class SyncService extends GetxController {
  static const String _lastSyncKey = 'last_sync_timestamp';
  static const String _pendingSyncKey = 'pending_sync_items';

  // Estado da sincronização
  final RxBool isSyncing = false.obs;
  final RxBool isOnline = false.obs;
  final RxString lastSyncTime = ''.obs;
  final RxInt pendingItems = 0.obs;
  final RxString syncStatus = 'Desconectado'.obs;

  // Providers de dados
  late final SQLiteDatabaseProvider _localDb;
  
  // Timer para sync automática
  Timer? _syncTimer;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  @override
  void onInit() {
    super.onInit();
    _initializeSync();
  }

  @override
  void onClose() {
    _syncTimer?.cancel();
    _connectivitySubscription?.cancel();
    super.onClose();
  }

  // Inicializar serviço de sincronização
  Future<void> _initializeSync() async {
    _localDb = SQLiteDatabaseProvider();
    await _localDb.initialize();
    
    await _loadSyncStatus();
    await _checkConnectivity();
    
    _setupConnectivityListener();
    _setupAutoSync();
  }

  // Configurar listener de conectividade
  void _setupConnectivityListener() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
      // Pega o primeiro resultado da lista
      final result = results.isNotEmpty ? results.first : ConnectivityResult.none;
      _onConnectivityChanged(result);
    });
  }

  // Configurar sync automática
  void _setupAutoSync() {
    _syncTimer = Timer.periodic(
      Duration(milliseconds: AppConfig.syncInterval),
      (_) => _autoSync(),
    );
  }

  // Verificar conectividade inicial
  Future<void> _checkConnectivity() async {
    try {
      final connectivityList = await Connectivity().checkConnectivity();
      // Pega o primeiro resultado da lista
      final connectivity = connectivityList.isNotEmpty ? connectivityList.first : ConnectivityResult.none;
      _onConnectivityChanged(connectivity);
    } catch (e) {
      print('Erro ao verificar conectividade: $e');
      _onConnectivityChanged(ConnectivityResult.none);
    }
  }

  // Handler para mudança de conectividade
  void _onConnectivityChanged(ConnectivityResult result) {
    final wasOnline = isOnline.value;
    isOnline.value = result != ConnectivityResult.none;
    
    syncStatus.value = isOnline.value ? 'Online' : 'Offline';
    
    // Se ficou online, tentar sync automática
    if (!wasOnline && isOnline.value) {
      _autoSync();
    }
  }

  // Sincronização automática (silenciosa)
  Future<void> _autoSync() async {
    if (!isOnline.value || isSyncing.value) return;
    
    try {
      await syncAll(showProgress: false);
    } catch (e) {
      print('Erro na sincronização automática: $e');
    }
  }

  // Sincronização completa (manual)
  Future<SyncResult> syncAll({bool showProgress = true}) async {
    if (isSyncing.value) {
      return SyncResult.error('Sincronização já em andamento');
    }

    if (!isOnline.value) {
      return SyncResult.error('Sem conexão com internet');
    }

    isSyncing.value = true;
    if (showProgress) syncStatus.value = 'Sincronizando...';

    try {
      int totalSynced = 0;
      int totalErrors = 0;
      List<String> errorMessages = [];

      // 1. Sincronizar dados locais → servidor (upload)
      final uploadResult = await _syncToServer();
      totalSynced += uploadResult.synced;
      totalErrors += uploadResult.errors;
      if (uploadResult.errorMessage != null) {
        errorMessages.add(uploadResult.errorMessage!);
      }

      // 2. Sincronizar dados servidor → local (download)
      final downloadResult = await _syncFromServer();
      totalSynced += downloadResult.synced;
      totalErrors += downloadResult.errors;
      if (downloadResult.errorMessage != null) {
        errorMessages.add(downloadResult.errorMessage!);
      }

      // Atualizar status
      await _updateSyncStatus();
      
      if (totalErrors == 0) {
        syncStatus.value = 'Sincronizado';
        return SyncResult.success(
          'Sincronização completa: $totalSynced itens',
          totalSynced,
        );
      } else {
        syncStatus.value = 'Erro na sincronização';
        return SyncResult.error(
          'Sincronização parcial: $totalSynced ok, $totalErrors erros\n${errorMessages.join('\n')}',
        );
      }
    } catch (e) {
      syncStatus.value = 'Erro na sincronização';
      return SyncResult.error('Erro geral na sincronização: $e');
    } finally {
      isSyncing.value = false;
    }
  }

  // Sincronizar dados locais para servidor
  Future<_SyncOperationResult> _syncToServer() async {
    int synced = 0;
    int errors = 0;
    List<String> errorMessages = [];

    try {
      // Buscar todos os registros não sincronizados
      final unsyncedData = await _getUnsyncedLocalData();
      
      if (unsyncedData.isEmpty) {
        return _SyncOperationResult(synced: 0, errors: 0);
      }

      // Enviar em lote para o servidor
      final response = await HttpService.syncBulk(unsyncedData);
      
      if (response.success && response.data != null) {
        // Processar resultados da sincronização
        final results = response.data!;
        
        for (final result in results) {
          final table = result['table'] as String;
          final recordId = result['record_id'] as String;
          final success = result['success'] as bool;
          
          if (success) {
            // Marcar como sincronizado localmente
            await _markAsSynced(table, recordId);
            synced++;
          } else {
            errors++;
            errorMessages.add('Erro em $table/$recordId: ${result['error']}');
          }
        }
      } else {
        errors++;
        errorMessages.add('Erro na comunicação com servidor: ${response.message}');
      }
    } catch (e) {
      errors++;
      errorMessages.add('Erro ao sincronizar para servidor: $e');
    }

    return _SyncOperationResult(
      synced: synced,
      errors: errors,
      errorMessage: errorMessages.isNotEmpty ? errorMessages.join('; ') : null,
    );
  }

  // Sincronizar dados do servidor para local
  Future<_SyncOperationResult> _syncFromServer() async {
    int synced = 0;
    int errors = 0;
    String? errorMessage;

    try {
      final lastSync = await _getLastSyncTimestamp();
      
      // Buscar dados atualizados no servidor
      final response = await HttpService.get<Map<String, dynamic>>(
        '${AppConfig.syncEndpoint}/changes?since=$lastSync',
      );

      if (response.success && response.data != null) {
        final changes = response.data!;
        
        // Processar clientes
        if (changes['clients'] != null) {
          for (final clientData in changes['clients']) {
            try {
              await _syncClientFromServer(clientData);
              synced++;
            } catch (e) {
              errors++;
            }
          }
        }

        // Processar leituras
        if (changes['readings'] != null) {
          for (final readingData in changes['readings']) {
            try {
              await _syncReadingFromServer(readingData);
              synced++;
            } catch (e) {
              errors++;
            }
          }
        }

        // Processar pagamentos
        if (changes['payments'] != null) {
          for (final paymentData in changes['payments']) {
            try {
              await _syncPaymentFromServer(paymentData);
              synced++;
            } catch (e) {
              errors++;
            }
          }
        }
      }
    } catch (e) {
      errors++;
      errorMessage = 'Erro ao sincronizar do servidor: $e';
    }

    return _SyncOperationResult(
      synced: synced,
      errors: errors,
      errorMessage: errorMessage,
    );
  }

  // Buscar dados não sincronizados localmente
  Future<Map<String, List<Map<String, dynamic>>>> _getUnsyncedLocalData() async {
    final result = <String, List<Map<String, dynamic>>>{};

    // Clientes não sincronizados
    final unsyncedClients = await _localDb.query(
      'clients',
      where: 'is_synced = ?',
      whereArgs: [0],
    );
    if (unsyncedClients.isNotEmpty) {
      result['clients'] = unsyncedClients;
    }

    // Leituras não sincronizadas
    final unsyncedReadings = await _localDb.query(
      'readings',
      where: 'is_synced = ?',
      whereArgs: [0],
    );
    if (unsyncedReadings.isNotEmpty) {
      result['readings'] = unsyncedReadings;
    }

    // Pagamentos não sincronizados
    final unsyncedPayments = await _localDb.query(
      'payments',
      where: 'is_synced = ?',
      whereArgs: [0],
    );
    if (unsyncedPayments.isNotEmpty) {
      result['payments'] = unsyncedPayments;
    }

    return result;
  }

  // Marcar registro como sincronizado
  Future<void> _markAsSynced(String table, String recordId) async {
    await _localDb.update(
      table,
      {'is_synced': 1},
      where: 'id = ?',
      whereArgs: [recordId],
    );
  }

  // Sincronizar cliente específico do servidor
  Future<void> _syncClientFromServer(Map<String, dynamic> data) async {
    final client = ClientModel.fromJson(data);
    
    // Verificar se já existe localmente
    final existing = await _localDb.query(
      'clients',
      where: 'id = ?',
      whereArgs: [client.id],
    );

    if (existing.isNotEmpty) {
      // Atualizar existente
      await _localDb.update(
        'clients',
        client.toMap(),
        where: 'id = ?',
        whereArgs: [client.id],
      );
    } else {
      // Inserir novo
      await _localDb.insert('clients', client.toMap());
    }
  }

  // Sincronizar leitura específica do servidor
  Future<void> _syncReadingFromServer(Map<String, dynamic> data) async {
    final reading = ReadingModel.fromJson(data);
    
    final existing = await _localDb.query(
      'readings',
      where: 'id = ?',
      whereArgs: [reading.id],
    );

    if (existing.isNotEmpty) {
      await _localDb.update(
        'readings',
        reading.toMap(),
        where: 'id = ?',
        whereArgs: [reading.id],
      );
    } else {
      await _localDb.insert('readings', reading.toMap());
    }
  }

  // Sincronizar pagamento específico do servidor
  Future<void> _syncPaymentFromServer(Map<String, dynamic> data) async {
    final payment = PaymentModel.fromJson(data);
    
    final existing = await _localDb.query(
      'payments',
      where: 'id = ?',
      whereArgs: [payment.id],
    );

    if (existing.isNotEmpty) {
      await _localDb.update(
        'payments',
        payment.toMap(),
        where: 'id = ?',
        whereArgs: [payment.id],
      );
    } else {
      await _localDb.insert('payments', payment.toMap());
    }
  }

  // Carregar status da sincronização
  Future<void> _loadSyncStatus() async {
    final prefs = await SharedPreferences.getInstance();
    
    final lastSyncTimestamp = prefs.getString(_lastSyncKey);
    if (lastSyncTimestamp != null) {
      lastSyncTime.value = _formatSyncTime(DateTime.parse(lastSyncTimestamp));
    }

    await _updatePendingItemsCount();
  }

  // Atualizar status da sincronização
  Future<void> _updateSyncStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    
    await prefs.setString(_lastSyncKey, now.toIso8601String());
    lastSyncTime.value = _formatSyncTime(now);
    
    await _updatePendingItemsCount();
  }

  // Atualizar contador de itens pendentes
  Future<void> _updatePendingItemsCount() async {
    final unsyncedClients = await _localDb.query(
      'clients',
      where: 'is_synced = ?',
      whereArgs: [0],
    );

    final unsyncedReadings = await _localDb.query(
      'readings',
      where: 'is_synced = ?',
      whereArgs: [0],
    );

    final unsyncedPayments = await _localDb.query(
      'payments',
      where: 'is_synced = ?',
      whereArgs: [0],
    );

    pendingItems.value = unsyncedClients.length + 
                         unsyncedReadings.length + 
                         unsyncedPayments.length;
  }

  // Obter timestamp da última sincronização
  Future<String> _getLastSyncTimestamp() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_lastSyncKey) ?? '1970-01-01T00:00:00Z';
  }

  // Formatar tempo da sincronização
  String _formatSyncTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Agora';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} min atrás';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h atrás';
    } else {
      return '${difference.inDays}d atrás';
    }
  }

  // Método público para forçar sincronização
  Future<SyncResult> forcSync() async {
    return await syncAll(showProgress: true);
  }

  // Método para sincronizar entidade específica
  Future<SyncResult> syncEntity(String entityType, String entityId) async {
    if (!isOnline.value) {
      return SyncResult.error('Sem conexão com internet');
    }

    try {
      final response = await HttpService.post<Map<String, dynamic>>(
        '${AppConfig.syncEndpoint}/$entityType/$entityId',
        {},
      );

      if (response.success) {
        await _updateSyncStatus();
        return SyncResult.success('Sincronizado com sucesso');
      } else {
        return SyncResult.error(response.message);
      }
    } catch (e) {
      return SyncResult.error('Erro na sincronização: $e');
    }
  }
}

// Classes auxiliares
class _SyncOperationResult {
  final int synced;
  final int errors;
  final String? errorMessage;

  _SyncOperationResult({
    required this.synced,
    required this.errors,
    this.errorMessage,
  });
}

class SyncResult {
  final bool success;
  final String message;
  final int? itemCount;

  SyncResult._({
    required this.success,
    required this.message,
    this.itemCount,
  });

  factory SyncResult.success(String message, [int? itemCount]) {
    return SyncResult._(success: true, message: message, itemCount: itemCount);
  }

  factory SyncResult.error(String message) {
    return SyncResult._(success: false, message: message);
  }

  bool get isSuccess => success;
  bool get isError => !success;
}