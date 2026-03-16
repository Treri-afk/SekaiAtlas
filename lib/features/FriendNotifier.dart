import 'package:flutter/foundation.dart';

/// Notifier singleton pour signaler qu'un ami vient d'être ajouté.
/// Utilisation identique à AdventureNotifier :
///   - émettre  : FriendNotifier.instance.notify()
///   - écouter  : FriendNotifier.instance.addListener(callback)
///   - nettoyer : FriendNotifier.instance.removeListener(callback)
class FriendNotifier extends ChangeNotifier {
  FriendNotifier._();
  static final FriendNotifier instance = FriendNotifier._();

  void notify() {
    debugPrint('🔔 [FriendNotifier] notify — rechargement demandé');
    notifyListeners();
  }
}