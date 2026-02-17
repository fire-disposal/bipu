import 'api.dart';
import '../models/contact/contact.dart';
import '../models/common/paginated_response.dart';

class ContactApi {
  final ApiClient _api;

  ContactApi([ApiClient? client]) : _api = client ?? api;

  Future<PaginatedResponse<Contact>> getContacts({
    int page = 1,
    int size = 20,
  }) async {
    final data = await _api.get<Map<String, dynamic>>(
      '/api/contacts/',
      queryParameters: {'page': page, 'size': size},
    );
    return PaginatedResponse.fromJson(
      data,
      (json) => Contact.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<Contact> addContact(String bipupuId, {String? alias}) async {
    final data = await _api.post<Map<String, dynamic>>(
      '/api/contacts/',
      data: {'contact_bipupu_id': bipupuId, 'alias': alias},
    );
    return Contact.fromJson(data);
  }

  Future<void> deleteContact(String contactBipupuId) async {
    await _api.delete<void>('/api/contacts/$contactBipupuId');
  }

  Future<Contact> updateContact(String contactBipupuId, {String? alias}) async {
    final data = await _api.put<Map<String, dynamic>>(
      '/api/contacts/$contactBipupuId',
      data: {'alias': alias},
    );
    return Contact.fromJson(data);
  }
}
