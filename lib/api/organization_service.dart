import 'package:dio/dio.dart';
import 'api_client.dart';
import '../models/organization.dart';

class OrganizationService {
  final ApiClient _apiClient = ApiClient();

  Future<Organization> getOrganization(String id) async {
    final response = await _apiClient.get(
      '/organization',
      queryParameters: {'organizationId': id},
    );
    return Organization.fromJson(response.data);
  }

  Future<Organization> updateOrganization(
    String id,
    Map<String, dynamic> data,
  ) async {
    final response = await _apiClient.patch(
      '/organization',
      data: data,
      queryParameters: {'organizationId': id},
    );
    return Organization.fromJson(response.data);
  }

  Future<String> uploadLogo(String orgId, String filePath) async {
    final fileName = filePath.split('/').last;
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath, filename: fileName),
    });

    final response = await _apiClient.post(
      '/organization/logo',
      data: formData,
      queryParameters: {'organizationId': orgId},
    );
    return response.data['logo'];
  }

  // --- Team / Invitations ---

  Future<List<Invitation>> getInvitations(String orgId) async {
    final response = await _apiClient.get('/organization/$orgId/invitations');
    if (response.data is List) {
      return (response.data as List)
          .map((i) => Invitation.fromJson(i))
          .toList();
    }
    return [];
  }

  Future<void> inviteMember(
    String orgId,
    String email,
    String role,
    String customRoleId,
  ) async {
    await _apiClient.post(
      '/organization/$orgId/invite',
      data: {'email': email, 'role': role, 'customRoleId': customRoleId},
    );
  }

  Future<void> resendInvitation(String orgId, String invitationId) async {
    await _apiClient.post(
      '/organization/$orgId/invitations/$invitationId/resend',
    );
  }

  Future<void> cancelInvitation(String orgId, String invitationId) async {
    await _apiClient.delete('/organization/$orgId/invitations/$invitationId');
  }

  // --- Roles ---

  Future<List<CustomRole>> getRoles(String orgId) async {
    final response = await _apiClient.get('/organization/$orgId/roles');
    if (response.data is List) {
      return (response.data as List)
          .map((i) => CustomRole.fromJson(i))
          .toList();
    }
    return [];
  }

  Future<CustomRole> createRole(
    String orgId,
    String name,
    List<String> permissions,
  ) async {
    final response = await _apiClient.post(
      '/organization/$orgId/roles',
      data: {'name': name, 'permissions': permissions},
    );
    return CustomRole.fromJson(response.data);
  }

  Future<CustomRole> updateRole(
    String orgId,
    String roleId,
    String name,
    List<String> permissions,
  ) async {
    final response = await _apiClient.patch(
      '/organization/$orgId/roles/$roleId',
      data: {'name': name, 'permissions': permissions},
    );
    return CustomRole.fromJson(response.data);
  }

  Future<void> deleteRole(String orgId, String roleId) async {
    await _apiClient.delete('/organization/$orgId/roles/$roleId');
  }

  // --- Members ---

  Future<void> updateMemberRole(
    String orgId,
    String membershipId,
    String customRoleId,
  ) async {
    await _apiClient.patch(
      '/organization/$orgId/members/$membershipId/role',
      data: {'customRoleId': customRoleId},
    );
  }

  Future<void> removeMember(String orgId, String membershipId) async {
    await _apiClient.delete('/organization/$orgId/members/$membershipId');
  }
}
