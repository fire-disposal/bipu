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

  Future<Contact> addContact(String bipupuId, {String? remark}) async {
    final response = await _dio.post(
      '/api/contacts/',
      data: {'contact_id': bipupuId, 'remark': remark},
    );
    return Contact.fromJson(response.data);
  }

  Future<void> deleteContact(int contactId) async {
    await _dio.delete('/api/contacts/$contactId');
  }

  Future<Contact> updateContact(int contactId, {String? remark}) async {
    final response = await _dio.put(
      '/api/contacts/$contactId',
      data: {'remark': remark},
    );
    return Contact.fromJson(response.data);
  }
}
