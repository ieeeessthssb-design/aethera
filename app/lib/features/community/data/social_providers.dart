import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../authentication/data/auth_providers.dart';
import 'social_api_service.dart';
import 'social_models.dart';

final socialApiServiceProvider = Provider<SocialApiService>((ref) {
  final dio = ref.watch(apiClientProvider).dio;
  return SocialApiService(dio);
});

final mySocialProfileProvider = FutureProvider.autoDispose<SocialProfile>(
  (ref) => ref.watch(socialApiServiceProvider).getMyProfile(),
);

final socialProfileProvider = FutureProvider.autoDispose
    .family<SocialProfile, String>(
      (ref, userId) => ref.watch(socialApiServiceProvider).getProfile(userId),
    );

final peopleSearchProvider = FutureProvider.autoDispose
    .family<List<PersonSearchResult>, String>((ref, query) async {
      if (query.trim().length < 2) {
        return [];
      }

      return ref.watch(socialApiServiceProvider).searchPeople(query.trim());
    });

final socialFeedProvider = FutureProvider.autoDispose<List<SocialPost>>(
  (ref) => ref.watch(socialApiServiceProvider).getFeed(),
);

final socialConnectionsProvider =
    FutureProvider.autoDispose<List<SocialConnection>>(
      (ref) => ref.watch(socialApiServiceProvider).getConnections(),
    );

final socialConversationsProvider =
    FutureProvider.autoDispose<List<SocialConversation>>(
      (ref) => ref.watch(socialApiServiceProvider).getConversations(),
    );

final socialMessagesProvider = FutureProvider.autoDispose
    .family<List<SocialMessage>, String>(
      (ref, conversationId) =>
          ref.watch(socialApiServiceProvider).getMessages(conversationId),
    );
