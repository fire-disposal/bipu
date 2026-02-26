import 'package:dio/dio.dart';
import '../models/contact/contact.dart';
import '../models/common/paginated_response.dart';
import '../models/contact/contact_create.dart';
import '../models/contact/contact_update.dart';

class ContactApi {
  final Dio _dio;

  ContactApi(this._dio);

  Future<PaginatedResponse<Contact>> getContacts({
    int page = 1,
    int size = 20,
  }) async {
    final response = await _dio.get(
      '/api/contacts/',
      queryParameters: {'page': page, 'page_size': size},
    );

    final data = response.data;
    return PaginatedResponse(
      items: (data['contacts'] as List)
          .map((e) => Contact.fromJson(e))
          .toList(),
      total: data['total'],
      page: data['page'],
      size: data['page_size'],
      pages: (data['total'] / data['page_size']).ceil(),
    );
  }

  Future<Contact> addContact(ContactCreate body) async {
    final response = await _dio.post('/api/contacts/', data: body.toJson());
    return Contact.fromJson(response.data);
  }

  Future<Contact> addContactSimple(String contactId, {String? alias}) async {
    final body = ContactCreate(contactId: contactId, alias: alias);
    return addContact(body);
  }

  Future<Contact> updateContact(String contactId, ContactUpdate body) async {
    final response = await _dio.put(
      '/api/contacts/$contactId',
      data: body.toJson(),
    );
    return Contact.fromJson(response.data);
  }

  Future<Contact> updateContactAlias(String contactId, {String? alias}) async {
    final body = ContactUpdate(alias: alias);
    return updateContact(contactId, body);
  }

  Future<void> deleteContact(String contactId) async {
    await _dio.delete('/api/contacts/$contactId');
  }
}
