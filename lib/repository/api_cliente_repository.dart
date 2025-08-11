import 'package:vitalh2x/models/cliente_model.dart';
import 'package:vitalh2x/services/app_config.dart';
import 'package:vitalh2x/services/http_service.dart';
import 'package:vitalh2x/services/database_providers.dart';
import 'base_repository.dart';

class ApiClientRepository extends BaseRepository<ClientModel> {
  ApiClientRepository(DatabaseProvider databaseProvider)
      : super(databaseProvider, 'clients');

  @override
  ClientModel fromMap(Map<String, dynamic> map) {
    return ClientModel.fromMap(map);
  }

  @override
  Map<String, dynamic> toMap(ClientModel model) {
    return model.toMap();
  }

  // ===== OPERAÇÕES HÍBRIDAS (LOCAL + API) =====

  // Criar cliente (local + API)
  @override
  Future<String> create(ClientModel model) async {
    // 1. Salvar localmente primeiro
    final localId = await super.create(model.copyWith(isSynced: false));
    
    // 2. Tentar enviar para API se online
    try {
      if (await HttpService.hasConnection()) {
        final response = await HttpService.post<Map<String, dynamic>>(
          AppConfig.clientsEndpoint,
          model.toJson(),
        );

        if (response.success && response.data != null) {
          // Atualizar registro local como sincronizado
          final serverData = ClientModel.fromJson(response.data!);
          await super.update(localId, serverData.copyWith(isSynced: true));
          return serverData.id ?? localId;
        }
      }
    } catch (e) {
      print('Erro ao criar cliente na API: $e');
      // Continua funcionando offline
    }

    return localId;
  }

  // Atualizar cliente (local + API)
  @override
  Future<bool> update(String id, ClientModel model) async {
    // 1. Atualizar localmente
    final updated = await super.update(id, model.copyWith(isSynced: false));
    
    // 2. Tentar sincronizar com API
    try {
      if (await HttpService.hasConnection()) {
        final response = await HttpService.put<Map<String, dynamic>>(
          AppConfig.buildClientUrl(id),
          model.toJson(),
        );

        if (response.success) {
          // Marcar como sincronizado
          await _markAsSynced(id);
        }
      }
    } catch (e) {
      print('Erro ao atualizar cliente na API: $e');
    }

    return updated;
  }

  // Buscar cliente por ID (local primeiro, depois API)
  @override
  Future<ClientModel?> findById(String id) async {
    // 1. Buscar localmente primeiro
    ClientModel? client = await super.findById(id);
    
    // 2. Se não encontrar localmente e estiver online, buscar na API
    if (client == null && await HttpService.hasConnection()) {
      try {
        final response = await HttpService.get<Map<String, dynamic>>(
          AppConfig.buildClientUrl(id),
        );

        if (response.success && response.data != null) {
          client = ClientModel.fromJson(response.data!);
          // Salvar localmente para próxima vez
          await _saveToLocal(client);
        }
      } catch (e) {
        print('Erro ao buscar cliente na API: $e');
      }
    }

    return client;
  }

  // ===== MÉTODOS ESPECÍFICOS DO CLIENTE =====

  // Buscar cliente por referência
  Future<ClientModel?> findByReference(String reference) async {
    // 1. Buscar localmente
    final results = await databaseProvider.query(
      tableName,
      where: 'reference = ?',
      whereArgs: [reference],
      limit: 1,
    );

    if (results.isNotEmpty) {
      return fromMap(results.first);
    }

    // 2. Se não encontrar e estiver online, buscar na API
    if (await HttpService.hasConnection()) {
      try {
        final response = await HttpService.get<Map<String, dynamic>>(
          '${AppConfig.clientsEndpoint}/reference/$reference',
        );

        if (response.success && response.data != null) {
          final client = ClientModel.fromJson(response.data!);
          await _saveToLocal(client);
          return client;
        }
      } catch (e) {
        print('Erro ao buscar cliente por referência na API: $e');
      }
    }

    return null;
  }

  // Buscar cliente por número do contador
  Future<ClientModel?> findByCounterNumber(String counterNumber) async {
    // 1. Buscar localmente
    final results = await databaseProvider.query(
      tableName,
      where: 'counter_number = ?',
      whereArgs: [counterNumber],
      limit: 1,
    );

    if (results.isNotEmpty) {
      return fromMap(results.first);
    }

    // 2. Se não encontrar e estiver online, buscar na API
    if (await HttpService.hasConnection()) {
      try {
        final response = await HttpService.get<Map<String, dynamic>>(
          '${AppConfig.clientsEndpoint}/counter/$counterNumber',
        );

        if (response.success && response.data != null) {
          final client = ClientModel.fromJson(response.data!);
          await _saveToLocal(client);
          return client;
        }
      } catch (e) {
        print('Erro ao buscar cliente por contador na API: $e');
      }
    }

    return null;
  }

  // Buscar clientes ativos com suporte à paginação e busca
  Future<List<ClientModel>> findActiveClients({
    String? searchTerm,
    int? limit,
    int? offset,
  }) async {
    // Construir query local
    String where = 'is_active = 1';
    List<dynamic> whereArgs = [];

    if (searchTerm != null && searchTerm.isNotEmpty) {
      where += ' AND (name LIKE ? OR reference LIKE ? OR counter_number LIKE ?)';
      final searchPattern = '%$searchTerm%';
      whereArgs.addAll([searchPattern, searchPattern, searchPattern]);
    }

    // 1. Buscar dados locais
    final localResults = await databaseProvider.query(
      tableName,
      where: where,
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: 'name ASC',
      limit: limit,
      offset: offset,
    );

    List<ClientModel> clients = localResults.map((map) => fromMap(map)).toList();

    // 2. Se estiver online e for primeira página, sincronizar dados mais recentes
    if (await HttpService.hasConnection() && (offset ?? 0) == 0) {
      try {
        final queryParams = <String, String>{};
        if (searchTerm != null) queryParams['search'] = searchTerm;
        if (limit != null) queryParams['limit'] = limit.toString();
        if (offset != null) queryParams['offset'] = offset.toString();

        final response = await HttpService.get<List<dynamic>>(
          AppConfig.clientsEndpoint + _buildQueryString(queryParams),
        );

        if (response.success && response.data != null) {
          final apiClients = response.data!
              .map((data) => ClientModel.fromJson(data))
              .toList();

          // Salvar/atualizar dados locais
          for (final client in apiClients) {
            await _saveOrUpdateLocal(client);
          }

          // Se trouxe dados da API, refazer busca local para incluir updates
          if (apiClients.isNotEmpty) {
            final updatedResults = await databaseProvider.query(
              tableName,
              where: where,
              whereArgs: whereArgs.isEmpty ? null : whereArgs,
              orderBy: 'name ASC',
              limit: limit,
              offset: offset,
            );
            clients = updatedResults.map((map) => fromMap(map)).toList();
          }
        }
      } catch (e) {
        print('Erro ao sincronizar clientes da API: $e');
      }
    }

    return clients;
  }

  // Verificar se referência já existe
  Future<bool> referenceExists(String reference, {String? excludeId}) async {
    String where = 'reference = ?';
    List<dynamic> whereArgs = [reference];

    if (excludeId != null) {
      where += ' AND id != ?';
      whereArgs.add(excludeId);
    }

    // 1. Verificar localmente
    final localCount = await super.count(where: where, whereArgs: whereArgs);
    if (localCount > 0) return true;

    // 2. Verificar na API se online
    if (await HttpService.hasConnection()) {
      try {
        final endpoint = '${AppConfig.clientsEndpoint}/check-reference';
        final response = await HttpService.post<Map<String, dynamic>>(
          endpoint,
          {'reference': reference, 'exclude_id': excludeId},
        );

        if (response.success && response.data != null) {
          return response.data!['exists'] == true;
        }
      } catch (e) {
        print('Erro ao verificar referência na API: $e');
      }
    }

    return false;
  }

  // Verificar se número do contador já existe
  Future<bool> counterNumberExists(
    String counterNumber, {
    String? excludeId,
  }) async {
    String where = 'counter_number = ?';
    List<dynamic> whereArgs = [counterNumber];

    if (excludeId != null) {
      where += ' AND id != ?';
      whereArgs.add(excludeId);
    }

    // 1. Verificar localmente
    final localCount = await super.count(where: where, whereArgs: whereArgs);
    if (localCount > 0) return true;

    // 2. Verificar na API se online
    if (await HttpService.hasConnection()) {
      try {
        final endpoint = '${AppConfig.clientsEndpoint}/check-counter';
        final response = await HttpService.post<Map<String, dynamic>>(
          endpoint,
          {'counter_number': counterNumber, 'exclude_id': excludeId},
        );

        if (response.success && response.data != null) {
          return response.data!['exists'] == true;
        }
      } catch (e) {
        print('Erro ao verificar contador na API: $e');
      }
    }

    return false;
  }

  // Buscar clientes com dívidas
  Future<List<ClientModel>> findClientsWithDebt() async {
    // Buscar localmente
    final results = await databaseProvider.query(
      tableName,
      where: 'total_debt > 0 AND is_active = 1',
      orderBy: 'total_debt DESC',
    );

    List<ClientModel> clients = results.map((map) => fromMap(map)).toList();

    // Sincronizar com API se online
    if (await HttpService.hasConnection()) {
      try {
        final response = await HttpService.get<List<dynamic>>(
          '${AppConfig.clientsEndpoint}/with-debt',
        );

        if (response.success && response.data != null) {
          final apiClients = response.data!
              .map((data) => ClientModel.fromJson(data))
              .toList();

          // Atualizar dados locais
          for (final client in apiClients) {
            await _saveOrUpdateLocal(client);
          }
        }
      } catch (e) {
        print('Erro ao buscar clientes com dívida na API: $e');
      }
    }

    return clients;
  }

  // Obter estatísticas dos clientes
  Future<Map<String, int>> getClientStats() async {
    // Buscar estatísticas locais
    final stats = <String, int>{};
    stats['total'] = await count();
    stats['active'] = await count(where: 'is_active = 1');
    stats['inactive'] = await count(where: 'is_active = 0');
    stats['with_debt'] = await count(where: 'total_debt > 0 AND is_active = 1');

    // Sincronizar com API se online
    if (await HttpService.hasConnection()) {
      try {
        final response = await HttpService.get<Map<String, dynamic>>(
          '${AppConfig.clientsEndpoint}/stats',
        );

        if (response.success && response.data != null) {
          // Mesclar estatísticas da API (prioridade para dados do servidor)
          stats.addAll(Map<String, int>.from(response.data!));
        }
      } catch (e) {
        print('Erro ao buscar estatísticas na API: $e');
      }
    }

    return stats;
  }

  // Atualizar última leitura do cliente
  Future<bool> updateLastReading(String clientId, double lastReading) async {
    final success = await databaseProvider.update(
      tableName,
      {
        'last_reading': lastReading,
        'updated_at': DateTime.now().toIso8601String(),
        'is_synced': 0, // Marcar para sincronização
      },
      where: 'id = ?',
      whereArgs: [clientId],
    );

    return success > 0;
  }

  // Atualizar dívida total do cliente
  Future<bool> updateTotalDebt(String clientId, double totalDebt) async {
    final success = await databaseProvider.update(
      tableName,
      {
        'total_debt': totalDebt,
        'updated_at': DateTime.now().toIso8601String(),
        'is_synced': 0, // Marcar para sincronização
      },
      where: 'id = ?',
      whereArgs: [clientId],
    );

    return success > 0;
  }

  // Desativar cliente
  Future<bool> deactivateClient(String clientId) async {
    return await update(
      clientId,
      (await findById(clientId))!.copyWith(
        isActive: false,
        updatedAt: DateTime.now(),
      ),
    );
  }

  // ===== MÉTODOS AUXILIARES PRIVADOS =====

  Future<void> _saveToLocal(ClientModel client) async {
    await _saveOrUpdateLocal(client.copyWith(isSynced: true));
  }

  Future<void> _saveOrUpdateLocal(ClientModel client) async {
    final existing = await databaseProvider.query(
      tableName,
      where: 'id = ?',
      whereArgs: [client.id],
    );

    if (existing.isNotEmpty) {
      await databaseProvider.update(
        tableName,
        client.toMap(),
        where: 'id = ?',
        whereArgs: [client.id],
      );
    } else {
      await databaseProvider.insert(tableName, client.toMap());
    }
  }

  Future<void> _markAsSynced(String id) async {
    await databaseProvider.update(
      tableName,
      {'is_synced': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  String _buildQueryString(Map<String, String> params) {
    if (params.isEmpty) return '';
    final pairs = params.entries.map((e) => '${e.key}=${e.value}');
    return '?${pairs.join('&')}';
  }

  // Método para forçar sincronização de um cliente específico
  Future<bool> syncClient(String clientId) async {
    if (!await HttpService.hasConnection()) return false;

    try {
      final response = await HttpService.post<Map<String, dynamic>>(
        '${AppConfig.syncEndpoint}/client/$clientId',
        {},
      );

      if (response.success && response.data != null) {
        final client = ClientModel.fromJson(response.data!);
        await _saveOrUpdateLocal(client.copyWith(isSynced: true));
        return true;
      }
    } catch (e) {
      print('Erro ao sincronizar cliente: $e');
    }

    return false;
  }
}