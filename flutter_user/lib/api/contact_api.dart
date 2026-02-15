import 'package:dio/dio.dart';
import '../models/contact/contact.dart';
import '../models/common/paginated_response.dart';

class ContactApi {
  final Dio _dio;

  ContactApi(this._dio);

  Future<PaginatedResponse<Contact>> getContacts({
    int page = 1,
    int size = 20,
  }) async {
    final response = await _dio.get(
      '/api/contacts/',
      queryParameters: {'page': page, 'size': size},
    );
    return PaginatedResponse.fromJson(
      response.data,
      (json) => Contact.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<Contact> addContact(String bipupuId, {String? alias}) async {
    final response = await _dio.post(
      '/api/contacts/',
      data: {'contact_bipupu_id': bipupuId, 'alias': alias},
    );
    return Contact.fromJson(response.data);
  }

  Future<void> deleteContact(String contactBipupuId) async {
    await _dio.delete('/api/contacts/$contactBipupuId');
  }

  Future<Contact> updateContact(String contactBipupuId, {String? alias}) async {
    final response = await _dio.put(
      '/api/contacts/$contactBipupuId',
      data: {'alias': alias},
    );
    return Contact.fromJson(response.data);
  }
}
