import 'package:dio/dio.dart';

import 'social_models.dart';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
class SocialApiService {
  SocialApiService(this._dio);

  final Dio _dio;
  Future<Uint8List> getPostImage(String imageUrl) async {
  final response = await _dio.get<List<int>>(
    imageUrl,
    options: Options(responseType: ResponseType.bytes),
  );

  return Uint8List.fromList(response.data!);
}
  Future<List<PersonSearchResult>> searchPeople(String query) async {
  final response = await _dio.get(
    '/social/people/search',
    queryParameters: {'q': query.trim()},
  );

  return (response.data as List)
      .map(
        (item) => PersonSearchResult.fromJson(
          Map<String, dynamic>.from(item as Map),
        ),
      )
      .toList();
}
  Future<SocialProfile> getMyProfile() async {
    final response = await _dio.get('/social/profile/me');
    return SocialProfile.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  Future<SocialProfile> getProfile(String userId) async {
    final response = await _dio.get('/social/profile/$userId');
    return SocialProfile.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  Future<SocialProfile> updateMyProfile(Map<String, dynamic> updates) async {
    final response = await _dio.patch('/social/profile/me', data: updates);
    return SocialProfile.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  Future<List<SocialPost>> getFeed() async {
    final response = await _dio.get('/social/feed');
    return (response.data as List)
        .map(
          (item) => SocialPost.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList();
  }

Future<SocialPost> createPost(String body, {XFile? photo}) async {
  final formData = FormData.fromMap({
    'body': body,
    if (photo != null)
      'photo': await MultipartFile.fromFile(
        photo.path,
        filename: photo.name,
      ),
  });

  final response = await _dio.post(
    '/social/posts',
    data: formData,
  );

  return SocialPost.fromJson(
    Map<String, dynamic>.from(response.data as Map),
  );
}

  Future<List<SocialConnection>> getConnections() async {
    final response = await _dio.get('/social/connections');
    return (response.data as List)
        .map(
          (item) =>
              SocialConnection.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList();
  }

  Future<SocialConnection> sendConnectionRequest(String recipientId) async {
    final response = await _dio.post(
      '/social/connections',
      data: {'recipient_id': recipientId},
    );
    return SocialConnection.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  Future<SocialConnection> respondToConnection(
    String connectionId, {
    required bool accept,
  }) async {
    final response = await _dio.patch(
      '/social/connections/$connectionId',
      data: {'status': accept ? 'accepted' : 'declined'},
    );
    return SocialConnection.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  Future<List<SocialConversation>> getConversations() async {
    final response = await _dio.get('/social/conversations');
    return (response.data as List)
        .map(
          (item) => SocialConversation.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList();
  }

  Future<SocialConversation> startConversation(String otherUserId) async {
    final response = await _dio.post('/social/conversations/$otherUserId');
    return SocialConversation.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  Future<List<SocialMessage>> getMessages(String conversationId) async {
    final response = await _dio.get(
      '/social/conversations/$conversationId/messages',
    );
    return (response.data as List)
        .map(
          (item) =>
              SocialMessage.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList();
  }

  Future<SocialMessage> sendMessage(String conversationId, String body) async {
    final response = await _dio.post(
      '/social/conversations/$conversationId/messages',
      data: {'body': body},
    );
    return SocialMessage.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }
}
