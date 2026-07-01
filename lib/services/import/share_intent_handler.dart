// Android's "share to Still Life" intent handler. receive_sharing_intent and
// the file reads it triggers are Android-only, so the real implementation
// lives behind this trio; the web build gets a do-nothing handler (browsers
// have no share-target intent stream — main.dart never wires it there
// anyway).
export 'share_intent_handler_io.dart'
    if (dart.library.js_interop) 'share_intent_handler_stub.dart';
