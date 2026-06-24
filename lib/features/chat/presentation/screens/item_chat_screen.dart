import 'dart:async';
import 'package:openhearth_design/openhearth_design.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/chat_providers.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../inventory/domain/entities/item.dart';
import '../../../../services/chat/item_chat_service.dart';

/// Streaming single-item chat screen. Ephemeral — messages live only in the
/// widget's state for the session.
class ItemChatScreen extends ConsumerStatefulWidget {
  final String itemId;
  const ItemChatScreen({super.key, required this.itemId});

  @override
  ConsumerState<ItemChatScreen> createState() => _ItemChatScreenState();
}

class _ItemChatScreenState extends ConsumerState<ItemChatScreen> {
  final _controller = TextEditingController();
  final _scroll = ScrollController();
  final List<ChatMessage> _messages = [];
  // Track which assistant indices were interrupted (onDone fired without
  // a final ChatDelta sentinel) so we can render a small "(interrupted)"
  // chip next to them.
  final Set<int> _interruptedIndices = {};
  StreamSubscription<ChatDelta>? _sub;
  bool _streaming = false;
  bool _completedCleanly = false;
  Item? _item;

  @override
  void initState() {
    super.initState();
    _loadItem();
  }

  Future<void> _loadItem() async {
    final repo = ref.read(itemRepositoryProvider);
    final result = await repo.getItem(widget.itemId);
    result.when(
      success: (i) => mounted ? setState(() => _item = i) : null,
      failure: (_) {},
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _streaming || _item == null) return;
    _controller.clear();
    setState(() {
      _messages.add(ChatMessage(role: 'user', content: text));
      _messages.add(const ChatMessage(role: 'assistant', content: ''));
      _streaming = true;
      _completedCleanly = false;
    });
    final assistantIndex = _messages.length - 1;
    final svc = ref.read(itemChatServiceProvider);
    final stream = svc.streamReplyWithFinal(
      item: _item!,
      history: _historyForRequest(),
    );
    _sub = stream.listen(
      (delta) {
        if (!mounted) return;
        if (delta.isFinal) {
          _completedCleanly = true;
          return;
        }
        setState(() {
          final last = _messages.removeLast();
          _messages.add(
            ChatMessage(role: 'assistant', content: last.content + delta.text),
          );
        });
        _scrollToBottom();
      },
      onError: (Object e) {
        if (!mounted) return;
        setState(() {
          _messages.removeLast();
          _messages.add(ChatMessage(role: 'assistant', content: 'Error: $e'));
          _streaming = false;
        });
      },
      onDone: () {
        if (!mounted) return;
        setState(() {
          if (!_completedCleanly &&
              assistantIndex < _messages.length &&
              _messages[assistantIndex].role == 'assistant') {
            _interruptedIndices.add(assistantIndex);
          }
          _streaming = false;
        });
      },
    );
  }

  List<ChatMessage> _historyForRequest() =>
      _messages.where((m) => m.content.isNotEmpty).toList();

  void _scrollToBottom() {
    if (!_scroll.hasClients) return;
    _scroll.animateTo(
      _scroll.position.maxScrollExtent,
      duration: OhMotion.standard,
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ask about this item'),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: Center(
              child: Chip(
                visualDensity: VisualDensity.compact,
                label: Text('ephemeral', style: TextStyle(fontSize: 11)),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? const Center(
                    child: Padding(
                      padding: OhSpacing.insetLg,
                      child: Text(
                        'Ask anything about this item — maintenance tips, '
                        'warranty questions, troubleshooting, etc.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                : ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.all(12),
                    itemCount: _messages.length,
                    itemBuilder: (_, i) => _MessageBubble(
                      msg: _messages[i],
                      interrupted: _interruptedIndices.contains(i),
                    ),
                  ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      enabled: !_streaming && _item != null,
                      decoration: const InputDecoration(
                        hintText: 'Type a question…',
                        border: OutlineInputBorder(),
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: OhSpacing.sm),
                  IconButton.filled(
                    onPressed: _streaming || _item == null ? null : _send,
                    icon: _streaming
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage msg;
  final bool interrupted;
  const _MessageBubble({required this.msg, this.interrupted = false});

  @override
  Widget build(BuildContext context) {
    final isUser = msg.role == 'user';
    final theme = Theme.of(context);
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isUser
              ? theme.colorScheme.primaryContainer
              : theme.colorScheme.surfaceContainerHigh,
          borderRadius: OhRadii.lg,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(msg.content.isEmpty ? '…' : msg.content),
            if (interrupted) ...[
              const SizedBox(height: OhSpacing.xs),
              Text(
                '(interrupted)',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.error,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
