import '../api_client.dart';
import 'group_models.dart';

/// REST API service for group mode operations
class GroupRestApiService {
  final ApiClient _apiClient;

  GroupRestApiService({required ApiClient apiClient}) : _apiClient = apiClient;

  /// POST /api/v1/group/create - Creates a new group party
  Future<ApiResponse<GroupParty>> createGroup() async {
    try {
      final response = await _apiClient.postJson('/api/v1/group/create', body: {}, auth: true);

      if (!response.ok) {
        return ApiResponse.err(
          message: response.message ?? 'Erreur lors de la création de la partie',
          statusCode: response.statusCode,
          raw: response.raw,
        );
      }

      final party = GroupParty.fromJson(response.data as Map<String, dynamic>);
      return ApiResponse.ok(party, statusCode: response.statusCode);
    } catch (e) {
      return ApiResponse.err(message: 'Erreur: $e');
    }
  }

  /// POST /api/v1/group/join - Joins an existing party with a code
  Future<ApiResponse<GroupParty>> joinGroup({required String code}) async {
    try {
      if (code.trim().isEmpty) {
        return ApiResponse.err(message: 'Le code de la partie ne peut pas être vide');
      }

      final request = JoinGroupRequest(code: code);
      final response = await _apiClient.postJson(
        '/api/v1/group/join',
        body: request.toJson(),
        auth: true,
      );

      if (!response.ok) {
        return ApiResponse.err(
          message: response.message ?? 'Erreur lors de la connexion à la partie',
          statusCode: response.statusCode,
          raw: response.raw,
        );
      }

      final party = GroupParty.fromJson(response.data as Map<String, dynamic>);
      return ApiResponse.ok(party, statusCode: response.statusCode);
    } catch (e) {
      return ApiResponse.err(message: 'Erreur: $e');
    }
  }

  /// POST /api/v1/group/leave - Leaves the current party
  Future<ApiResponse<void>> leaveGroup() async {
    try {
      final response = await _apiClient.postJson('/api/v1/group/leave', body: {}, auth: true);

      if (!response.ok) {
        return ApiResponse.err(
          message: response.message ?? 'Erreur lors de la déconnexion',
          statusCode: response.statusCode,
          raw: response.raw,
        );
      }

      return ApiResponse.ok(null, statusCode: response.statusCode);
    } catch (e) {
      return ApiResponse.err(message: 'Erreur: $e');
    }
  }

  /// POST /api/v1/group/settings - Updates party settings (host only)
  /// [themes]: theme IDs (required, non-empty)
  /// [difficulties]: difficulty IDs (required, non-empty)
  /// [nbQuestions]: number of questions (5, 10, 15, or 20)
  /// [scoreEachRound]: if true, scores sent after each question
  Future<ApiResponse<void>> updateSettings({
    required List<int> themes,
    required List<int> difficulties,
    required int nbQuestions,
    required bool scoreEachRound,
  }) async {
    try {
      if (themes.isEmpty) {
        return ApiResponse.err(message: 'La liste des thèmes ne peut pas être vide');
      }
      if (difficulties.isEmpty) {
        return ApiResponse.err(message: 'La liste des difficultés ne peut pas être vide');
      }
      if (![5, 10, 15, 20].contains(nbQuestions)) {
        return ApiResponse.err(
          message: 'Le nombre de questions doit être 5, 10, 15 ou 20',
        );
      }

      final request = GroupSettingsRequest(
        themes: themes,
        difficulties: difficulties,
        nbQuestions: nbQuestions,
        scoreEachRound: scoreEachRound,
      );

      final response = await _apiClient.postJson(
        '/api/v1/group/settings',
        body: request.toJson(),
        auth: true,
      );

      if (!response.ok) {
        return ApiResponse.err(
          message: response.message ?? 'Erreur lors de la mise à jour des paramètres',
          statusCode: response.statusCode,
          raw: response.raw,
        );
      }

      return ApiResponse.ok(null, statusCode: response.statusCode);
    } catch (e) {
      return ApiResponse.err(message: 'Erreur: $e');
    }
  }
}
