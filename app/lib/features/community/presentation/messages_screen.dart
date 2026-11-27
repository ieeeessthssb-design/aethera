import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/social_models.dart';
import '../data/social_providers.dart';
import '../../../l10n/generated/app_localizations.dart';

const _forest = Color(0xFF183F32);
const _green = Color(0xFF527B58);
const _cream = Color(0xFFF7F6EF);
const _muted = Color(0xFF59665C);

class MessagesScreen extends ConsumerWidget {
  const MessagesScreen({super.key});

  Future<void> _refresh(WidgetRef ref) async {
    ref.invalidate(socialConversationsProvider);
    await ref.read(socialConversationsProvider.future);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conversations = ref.watch(socialConversationsProvider);

    return Scaffold(
      backgroundColor: _cream,
      body: SafeArea(
        child: RefreshIndicator(
          color: _forest,
          onRefresh: () => _refresh(ref),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            children: [
              const Text(
                'Messages',
                style: TextStyle(
                  color: _forest,
                  fontSize: 27,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 5),
              const Text(
                'Your conversations with farmers and experts.',
                style: TextStyle(color: _muted),
              ),
              const SizedBox(height: 20),
              conversations.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(
                    child: CircularProgressIndicator(color: _forest),
                  ),
                ),
                error: (error, _) => _ErrorPanel(
                  message: _friendlyError(error),
                  onRetry: () => ref.invalidate(socialConversationsProvider),
                ),
                data: (items) {
                  if (items.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.only(top: 90),
                      child: Column(
                        children: [
                          Icon(Icons.forum_outlined, size: 55, color: _forest),
                          SizedBox(height: 15),
                          Text(
                            'No conversations yet',
                            style: TextStyle(
                              color: _forest,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Accept a connection request before starting a conversation.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: _muted),
                          ),
                        ],
                      ),
                    );
                  }

                  return Column(
                    children: items
                        .map(
                          (conversation) =>
                              _ConversationTile(conversation: conversation),
                        )
                        .toList(),
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

class _ConversationTile extends StatelessWidget {
  const _ConversationTile({required this.conversation});

  final SocialConversation conversation;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 9),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 7),
        leading: const CircleAvatar(
          radius: 24,
          backgroundColor: Color(0xFFE5EEE4),
          child: Icon(Icons.person, color: _forest),
        ),
        title: Text(
          conversation.otherUserName,
          style: const TextStyle(color: _forest, fontWeight: FontWeight.bold),
        ),
        subtitle: const Text(
          'Open conversation',
          style: TextStyle(color: _muted),
        ),
        trailing: const Icon(Icons.chevron_right, color: _forest),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => ConversationScreen(conversation: conversation),
            ),
          );
        },
      ),
    );
  }
}

class ConversationScreen extends ConsumerStatefulWidget {
  const ConversationScreen({required this.conversation, super.key});

  final SocialConversation conversation;

  @override
  ConsumerState<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends ConsumerState<ConversationScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  bool _sending = false;

  String get _conversationId => widget.conversation.id;

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _refreshMessages() async {
    ref.invalidate(socialMessagesProvider(_conversationId));
    await ref.read(socialMessagesProvider(_conversationId).future);
  }

  Future<void> _send() async {
    final body = _controller.text.trim();

    if (body.isEmpty || _sending) return;

    if (body.length > 5000) {
      _showMessage(AppLocalizations.of(context)!.messageTooLong);
      return;
    }

    setState(() => _sending = true);

    try {
      await ref
          .read(socialApiServiceProvider)
          .sendMessage(_conversationId, body);

      if (!mounted) return;

      _controller.clear();

      ref.invalidate(socialMessagesProvider(_conversationId));
      ref.invalidate(socialConversationsProvider);
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
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(socialMessagesProvider(_conversationId));
    final currentUserId = ref
        .watch(mySocialProfileProvider)
        .asData
        ?.value
        .userId;

    return Scaffold(
      backgroundColor: _cream,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: _forest,
        elevation: 0,
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.conversation.otherUserName,
              style: const TextStyle(
                color: _forest,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Text(
              'Conversation',
              style: TextStyle(
                color: _muted,
                fontSize: 12,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: messages.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: _forest),
                ),
                error: (error, _) => _ErrorPanel(
                  message: _friendlyError(error),
                  onRetry: () {
                    ref.invalidate(socialMessagesProvider(_conversationId));
                  },
                ),
                data: (items) {
                  return RefreshIndicator(
                    color: _forest,
                    onRefresh: _refreshMessages,
                    child: items.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: const [
                              SizedBox(height: 180),
                              Icon(
                                Icons.chat_bubble_outline,
                                size: 48,
                                color: _green,
                              ),
                              SizedBox(height: 15),
                              Center(
                                child: Text(
                                  'Start the conversation',
                                  style: TextStyle(
                                    color: _forest,
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              SizedBox(height: 7),
                              Center(
                                child: Text(
                                  'Send your first message below.',
                                  style: TextStyle(color: _muted),
                                ),
                              ),
                            ],
                          )
                        : ListView.builder(
                            controller: _scrollController,
                            physics: const AlwaysScrollableScrollPhysics(),
                            reverse: true,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 15,
                              vertical: 18,
                            ),
                            itemCount: items.length,
                            itemBuilder: (context, index) {
                              final message = items[items.length - 1 - index];

                              final isMe =
                                  currentUserId != null &&
                                  message.senderId == currentUserId;

                              return _MessageBubble(
                                message: message,
                                isMe: isMe,
                              );
                            },
                          ),
                  );
                },
              ),
            ),
            _MessageComposer(
              controller: _controller,
              sending: _sending,
              onSend: _send,
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageComposer extends StatelessWidget {
  const _MessageComposer({
    required this.controller,
    required this.sending,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool sending;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              minLines: 1,
              maxLines: 4,
              maxLength: 5000,
              textCapitalization: TextCapitalization.sentences,
              style: const TextStyle(color: _forest, fontSize: 15),
              cursorColor: _green,
              decoration: InputDecoration(
                counterText: '',
                hintText: AppLocalizations.of(context)!.messageHint,
                hintStyle: const TextStyle(color: _muted),
                filled: true,
                fillColor: _cream,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: (_) => onSend(),
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filled(
            onPressed: sending ? null : onSend,
            style: IconButton.styleFrom(
              backgroundColor: _forest,
              foregroundColor: Colors.white,
              disabledBackgroundColor: _forest.withValues(alpha: 0.5),
            ),
            icon: sending
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.send_rounded),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message, required this.isMe});

  final SocialMessage message;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.78,
        ),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: isMe ? _forest : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              message.body,
              style: TextStyle(
                color: isMe ? Colors.white : _forest,
                height: 1.4,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              _formatMessageTime(message.createdAt),
              style: TextStyle(
                color: isMe ? Colors.white70 : _muted,
                fontSize: 10,
              ),
            ),
          ],
        ),
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
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_outlined, size: 42, color: _muted),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: _muted),
          ),
          const SizedBox(height: 10),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: Text(AppLocalizations.of(context)!.messageRetry),
            style: TextButton.styleFrom(foregroundColor: _forest),
          ),
        ],
      ),
    );
  }
}

String _friendlyError(Object error) {
  return error
      .toString()
      .replaceFirst('Exception: ', '')
      .replaceFirst('DioException [bad response]: ', '');
}

String _formatMessageTime(DateTime dateTime) {
  final local = dateTime.toLocal();

  return '${local.hour.toString().padLeft(2, '0')}:'
      '${local.minute.toString().padLeft(2, '0')}';
}
