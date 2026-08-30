import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mediacl_panda/customer/ai/services.dart';



final aiServiceProvider = Provider<AIService>((ref) => AIService());

/// Current active chat session ID (null = new session)
final chatSessionIdProvider = Provider<Notifier<int?>>((ref) {
  final notifier = Notifier<int?>();
  ref.onDispose(notifier.dispose);
  return notifier;
});

/// Simple change notifier for chat messages
class Notifier<T> {
  T? _value;
  final List<void Function(T?)> _listeners = [];

  T? get value => _value;
  set value(T? newValue) {
    _value = newValue;
    for (final l in _listeners) {
      l(newValue);
    }
  }

  void addListener(void Function(T?) listener) => _listeners.add(listener);
  void removeListener(void Function(T?) listener) => _listeners.remove(listener);
  void dispose() => _listeners.clear();
}
