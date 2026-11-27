import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../l10n/generated/app_localizations.dart';

import '../data/social_models.dart';
import '../data/social_providers.dart';
import 'messages_screen.dart';

const _forest = Color(0xFF183F32);
const _green = Color(0xFF527B58);
const _cream = Color(0xFFF7F6EF);
const _muted = Color(0xFF59665C);
const _lightGreen = Color(0xFFE5EEE4);
const _text = Color(0xFF27352C);

class CommunityScreen extends ConsumerWidget {
  const CommunityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feed = ref.watch(socialFeedProvider);
    final connections = ref.watch(socialConnectionsProvider);

    return Scaffold(
      backgroundColor: _cream,
      body: SafeArea(
        child: RefreshIndicator(
          color: _forest,
          onRefresh: () async {
            ref.invalidate(socialFeedProvider);
            ref.invalidate(socialConnectionsProvider);
            await Future.wait([
              ref.read(socialFeedProvider.future),
              ref.read(socialConnectionsProvider.future),
            ]);
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(18, 22, 18, 30),
            children: [
              const Text(
                'Community',
                style: TextStyle(
                  color: _forest,
                  fontSize: 27,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 5),
              const Text(
                'Share knowledge with farmers and agricultural experts.',
                style: TextStyle(color: _muted, fontSize: 14, height: 1.4),
              ),
              const SizedBox(height: 20),
              const _PeopleSearchCard(),
              const SizedBox(height: 18),
              _CreatePostCard(
                onCreated: () => ref.invalidate(socialFeedProvider),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Your feed',
                      style: TextStyle(
                        color: _forest,
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: AppLocalizations.of(context)!.communityRefresh,
                    onPressed: () => ref.invalidate(socialFeedProvider),
                    icon: const Icon(Icons.refresh, color: _forest),
                  ),
                ],
              ),
              feed.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(30),
                  child: Center(
                    child: CircularProgressIndicator(color: _forest),
                  ),
                ),
                error: (error, _) => _ErrorPanel(
                  message: _friendlyError(error),
                  onRetry: () => ref.invalidate(socialFeedProvider),
                ),
                data: (posts) {
                  if (posts.isEmpty) {
                    return const _EmptyPanel(
                      icon: Icons.article_outlined,
                      title: 'No posts yet',
                      message:
                          'Be the first to share something with the community.',
                    );
                  }

                  return Column(
                    children: posts
                        .map((post) => _PostCard(post: post))
                        .toList(),
                  );
                },
              ),
              const SizedBox(height: 22),
              const Text(
                'Connections',
                style: TextStyle(
                  color: _forest,
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              connections.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(
                    child: CircularProgressIndicator(color: _forest),
                  ),
                ),
                error: (error, _) => _ErrorPanel(
                  message: _friendlyError(error),
                  onRetry: () => ref.invalidate(socialConnectionsProvider),
                ),
                data: (items) {
                  if (items.isEmpty) {
                    return const _EmptyPanel(
                      icon: Icons.people_outline,
                      title: 'No connections yet',
                      message:
                          'Search for another farmer or expert and send a request.',
                    );
                  }

                  return Column(
                    children: items.map((item) {
                      return _ConnectionCard(
                        connection: item,
                        onChanged: () =>
                            ref.invalidate(socialConnectionsProvider),
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// PEOPLE SEARCH AND DIRECT EXPERT MESSAGING
// -----------------------------------------------------------------------------

class _PeopleSearchCard extends ConsumerStatefulWidget {
  const _PeopleSearchCard();

  @override
  ConsumerState<_PeopleSearchCard> createState() => _PeopleSearchCardState();
}

class _PeopleSearchCardState extends ConsumerState<_PeopleSearchCard> {
  final _controller = TextEditingController();

  String _query = '';
  String? _sendingTo;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _askExpert(PersonSearchResult person) async {
    if (_sendingTo != null) return;

    setState(() => _sendingTo = person.userId);

    try {
      final conversation = await ref
          .read(socialApiServiceProvider)
          .startConversation(person.userId);

      ref.invalidate(socialConversationsProvider);

      if (!mounted) return;

      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ConversationScreen(conversation: conversation),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      _showMessage(_friendlyError(error));
    } finally {
      if (mounted) {
        setState(() => _sendingTo = null);
      }
    }
  }

  Future<void> _connect(PersonSearchResult person) async {
    if (_sendingTo != null) return;

    setState(() => _sendingTo = person.userId);

    try {
      await ref
          .read(socialApiServiceProvider)
          .sendConnectionRequest(person.userId);

      ref.invalidate(socialConnectionsProvider);

      if (!mounted) return;

      _showMessage(
        '${AppLocalizations.of(context)!.communityConnectionSent} ${person.fullName}.',
      );
    } catch (error) {
      if (mounted) {
        _showMessage(_friendlyError(error));
      }
    } finally {
      if (mounted) {
        setState(() => _sendingTo = null);
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final results = ref.watch(peopleSearchProvider(_query));

    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.person_search, color: _forest, size: 21),
                SizedBox(width: 9),
                Text(
                  'Find farmers and experts',
                  style: TextStyle(
                    color: _forest,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              onChanged: (value) {
                setState(() => _query = value.trim());
              },
              style: const TextStyle(color: _text),
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context)!.communitySearch,
                hintStyle: const TextStyle(color: _muted),
                prefixIcon: const Icon(Icons.search, color: _green),
                suffixIcon: _controller.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Clear search',
                        icon: const Icon(Icons.close, color: _muted),
                        onPressed: () {
                          _controller.clear();
                          setState(() => _query = '');
                        },
                      ),
                filled: true,
                fillColor: _cream,
                contentPadding: const EdgeInsets.symmetric(vertical: 13),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            if (_query.length < 2) ...[
              const SizedBox(height: 10),
              const Text(
                'Enter at least 2 characters to search.',
                style: TextStyle(color: _muted, fontSize: 12),
              ),
            ] else ...[
              const SizedBox(height: 10),
              results.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(14),
                  child: Center(
                    child: CircularProgressIndicator(color: _forest),
                  ),
                ),
                error: (error, _) => Text(
                  _friendlyError(error),
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                ),
                data: (people) {
                  if (people.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        'No matching farmers or approved experts found.',
                        style: TextStyle(color: _muted, fontSize: 13),
                      ),
                    );
                  }

                  return Column(
                    children: people.map((person) {
                      final isSending = _sendingTo == person.userId;
                      final isExpert = person.role.toLowerCase() == 'expert';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 5),
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            backgroundColor: _lightGreen,
                            child: Icon(
                              isExpert ? Icons.workspace_premium : Icons.person,
                              color: _forest,
                            ),
                          ),
                          title: Text(
                            person.fullName,
                            style: const TextStyle(
                              color: _forest,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          subtitle: Text(
                            '${person.role.toUpperCase()}'
                            '${person.isVerified ? ' • VERIFIED' : ''}',
                            style: const TextStyle(
                              color: _muted,
                              fontSize: 10,
                              letterSpacing: 0.5,
                            ),
                          ),
                          trailing: isExpert
                              ? FilledButton.tonalIcon(
                                  onPressed: _sendingTo == null
                                      ? () => _askExpert(person)
                                      : null,
                                  icon: isSending
                                      ? const SizedBox(
                                          width: 15,
                                          height: 15,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Icon(
                                          Icons.chat_outlined,
                                          size: 17,
                                        ),
                                  label: Text(
                                    AppLocalizations.of(context)!.communityAsk,
                                  ),
                                  style: FilledButton.styleFrom(
                                    foregroundColor: _forest,
                                    backgroundColor: _lightGreen,
                                  ),
                                )
                              : IconButton(
                                  tooltip: 'Send connection request',
                                  onPressed: _sendingTo == null
                                      ? () => _connect(person)
                                      : null,
                                  icon: isSending
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: _forest,
                                          ),
                                        )
                                      : const Icon(
                                          Icons.person_add_alt_1,
                                          color: _forest,
                                        ),
                                ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// CREATE POST
// -----------------------------------------------------------------------------

class _CreatePostCard extends ConsumerStatefulWidget {
  const _CreatePostCard({required this.onCreated});

  final VoidCallback onCreated;

  @override
  ConsumerState<_CreatePostCard> createState() => _CreatePostCardState();
}

class _CreatePostCardState extends ConsumerState<_CreatePostCard> {
  final _controller = TextEditingController();
  final _picker = ImagePicker();

  XFile? _photo;
  Uint8List? _photoBytes;
  bool _sending = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    if (_sending) return;

    try {
      final photo = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1600,
      );

      if (photo != null) {
        final bytes = await photo.readAsBytes();
        if (mounted) {
          setState(() {
            _photo = photo;
            _photoBytes = bytes;
          });
        }
      }
    } catch (error) {
      if (mounted) {
        _showMessage(
          '${AppLocalizations.of(context)!.communityImageError}: $error',
        );
      }
    }
  }

  Future<void> _submit() async {
    final body = _controller.text.trim();

    if (_sending || (body.isEmpty && _photo == null)) return;

    if (body.length > 5000) {
      _showMessage(AppLocalizations.of(context)!.communityPostTooLong);
      return;
    }

    setState(() => _sending = true);

    try {
      await ref.read(socialApiServiceProvider).createPost(body, photo: _photo);

      if (!mounted) return;

      _controller.clear();

      setState(() {
        _photo = null;
        _photoBytes = null;
      });

      ref.invalidate(socialFeedProvider);
      widget.onCreated();

      _showMessage(AppLocalizations.of(context)!.communityPostPublished);
    } catch (error) {
      if (mounted) {
        _showMessage(_friendlyError(error));
      }
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Row(
              children: [
                Icon(Icons.edit_outlined, color: _forest, size: 20),
                SizedBox(width: 8),
                Text(
                  'Create a post',
                  style: TextStyle(
                    color: _forest,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              minLines: 3,
              maxLines: 6,
              maxLength: 5000,
              enabled: !_sending,
              cursorColor: _forest,
              style: const TextStyle(color: _text, fontSize: 15, height: 1.4),
              decoration: InputDecoration(
                hintText: 'Share an update, question, or farming tip...',
                hintStyle: const TextStyle(color: _muted, fontSize: 14),
                filled: true,
                fillColor: _cream,
                contentPadding: const EdgeInsets.all(14),
                counterStyle: const TextStyle(color: _muted),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(13),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(13),
                  borderSide: const BorderSide(color: _lightGreen),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(13),
                  borderSide: const BorderSide(color: _green, width: 1.5),
                ),
              ),
            ),
            if (_photo != null && _photoBytes != null) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.memory(
                  _photoBytes!,
                  height: 190,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: _sending
                      ? null
                      : () => setState(() {
                          _photo = null;
                          _photoBytes = null;
                        }),
                  icon: const Icon(Icons.delete_outline),
                  label: Text(
                    AppLocalizations.of(context)!.communityRemovePhoto,
                  ),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                ),
              ),
            ],
            const SizedBox(height: 10),
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: _sending ? null : _pickPhoto,
                  icon: const Icon(Icons.image_outlined),
                  label: Text(AppLocalizations.of(context)!.communityAddPhoto),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _forest,
                    side: const BorderSide(color: _green),
                  ),
                ),
                const Spacer(),
                FilledButton.icon(
                  onPressed: _sending ? null : _submit,
                  icon: _sending
                      ? const SizedBox(
                          width: 17,
                          height: 17,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.send_rounded),
                  label: Text(_sending ? 'Publishing...' : 'Publish'),
                  style: FilledButton.styleFrom(
                    backgroundColor: _forest,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 13,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// FEED POST
// -----------------------------------------------------------------------------

class _PostCard extends ConsumerWidget {
  const _PostCard({required this.post});

  final SocialPost post;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final imageUrl = post.imageUrl;

    return Card(
      color: Colors.white,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(17)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  backgroundColor: _lightGreen,
                  child: Icon(Icons.person, color: _forest),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    post.authorName,
                    style: const TextStyle(
                      color: _forest,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  _formatDate(post.createdAt),
                  style: const TextStyle(color: _muted, fontSize: 11),
                ),
              ],
            ),
            if (post.body.isNotEmpty) ...[
              const SizedBox(height: 14),
              SelectableText(
                post.body,
                style: const TextStyle(color: _text, fontSize: 14, height: 1.5),
              ),
            ],
            if (imageUrl != null && imageUrl.isNotEmpty) ...[
              const SizedBox(height: 12),
              FutureBuilder(
                future: ref
                    .read(socialApiServiceProvider)
                    .getPostImage(imageUrl),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Container(
                      height: 120,
                      alignment: Alignment.center,
                      color: _cream,
                      child: const Text(
                        'Image could not be loaded',
                        style: TextStyle(color: _muted),
                      ),
                    );
                  }

                  if (!snapshot.hasData) {
                    return const SizedBox(
                      height: 150,
                      child: Center(
                        child: CircularProgressIndicator(color: _forest),
                      ),
                    );
                  }

                  return ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.memory(
                      snapshot.data!,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// CONNECTIONS
// -----------------------------------------------------------------------------

class _ConnectionCard extends ConsumerWidget {
  const _ConnectionCard({required this.connection, required this.onChanged});

  final SocialConnection connection;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(mySocialProfileProvider);
    final currentId = profile.asData?.value.userId;

    final isIncoming = currentId != null && connection.recipientId == currentId;
    final isPending = connection.status == 'pending';

    final otherUserId = isIncoming
        ? connection.requesterId
        : connection.recipientId;

    return Card(
      color: Colors.white,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 9),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  radius: 19,
                  backgroundColor: _lightGreen,
                  child: Icon(Icons.person_outline, color: _forest, size: 21),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    isIncoming ? 'Incoming request' : 'Connection',
                    style: const TextStyle(
                      color: _forest,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _StatusLabel(status: connection.status),
              ],
            ),
            const SizedBox(height: 12),
            SelectableText(
              'User ID: $otherUserId',
              style: const TextStyle(color: _muted, fontSize: 12),
            ),
            if (isPending && isIncoming) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 9,
                runSpacing: 8,
                children: [
                  FilledButton.icon(
                    onPressed: () => _respond(context, ref, true),
                    icon: const Icon(Icons.check, size: 18),
                    label: Text(AppLocalizations.of(context)!.communityAccept),
                    style: FilledButton.styleFrom(
                      backgroundColor: _forest,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _respond(context, ref, false),
                    icon: const Icon(Icons.close, size: 18),
                    label: Text(AppLocalizations.of(context)!.communityDecline),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _forest,
                      side: const BorderSide(color: _green),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _respond(
    BuildContext context,
    WidgetRef ref,
    bool accept,
  ) async {
    try {
      await ref
          .read(socialApiServiceProvider)
          .respondToConnection(connection.id, accept: accept);

      ref.invalidate(socialConnectionsProvider);
      ref.invalidate(socialConversationsProvider);
      onChanged();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              accept
                  ? 'Connection request accepted.'
                  : 'Connection request declined.',
            ),
          ),
        );
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_friendlyError(error))));
      }
    }
  }
}

// -----------------------------------------------------------------------------
// SHARED UI
// -----------------------------------------------------------------------------

class _StatusLabel extends StatelessWidget {
  const _StatusLabel({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final label = status.isEmpty
        ? 'Unknown'
        : '${status[0].toUpperCase()}${status.substring(1)}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: status == 'accepted'
            ? _lightGreen
            : status == 'pending'
            ? const Color(0xFFFFF3D9)
            : const Color(0xFFF2E5E3),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: status == 'accepted'
              ? _forest
              : status == 'pending'
              ? const Color(0xFF805B16)
              : const Color(0xFF8A3830),
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _EmptyPanel extends StatelessWidget {
  const _EmptyPanel({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
      ),
      child: Column(
        children: [
          Icon(icon, color: _green, size: 38),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(color: _forest, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: _muted, height: 1.4),
          ),
        ],
      ),
    );
  }
}

class _ErrorPanel extends StatelessWidget {
  const _ErrorPanel({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Column(
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.red),
          ),
          const SizedBox(height: 6),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: Text(AppLocalizations.of(context)!.communityRetry),
            style: TextButton.styleFrom(foregroundColor: _forest),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// HELPERS
// -----------------------------------------------------------------------------

String _friendlyError(Object error) {
  if (error is DioException) {
    final responseData = error.response?.data;

    if (responseData is Map) {
      final detail = responseData['detail'];
      if (detail != null) return detail.toString();
    }

    if (error.response?.statusCode == 401) {
      return 'Your session has expired. Please sign in again.';
    }

    if (error.response?.statusCode == 403) {
      return 'You do not have permission to perform this action.';
    }

    if (error.response?.statusCode == 404) {
      return 'The requested user or resource was not found.';
    }

    if (error.response?.statusCode == 409) {
      return 'A connection request already exists or has already been handled.';
    }

    if (error.response == null) {
      return 'Unable to connect to the server. Check your connection.';
    }
  }

  return error.toString().replaceFirst('Exception: ', '');
}

String _formatDate(DateTime date) {
  final local = date.toLocal();
  final now = DateTime.now();

  if (now.difference(local).inDays == 0 &&
      now.day == local.day &&
      now.month == local.month &&
      now.year == local.year) {
    return '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
  }

  return '${local.day}/${local.month}/${local.year}';
}
