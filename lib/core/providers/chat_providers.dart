import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/chat/item_chat_service.dart';
import 'appraisal_providers.dart';

/// Stateless chat service bound to the production [MessagesTransport].
final itemChatServiceProvider = Provider<ItemChatService>((ref) {
  return ItemChatService(transport: ref.watch(messagesTransportProvider));
});
