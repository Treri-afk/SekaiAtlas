import 'package:flutter/foundation.dart';

/// Singleton global notifié à chaque création ou suppression d'aventure.
/// Toutes les pages qui doivent se recharger écoutent ce notifier.
///
/// Usage :
///   // notifier tout le monde (après create ou terminate)
///   AdventureNotifier.instance.notify();
///
///   // écouter (dans initState)
///   AdventureNotifier.instance.addListener(_reload);
///
///   // se désabonner (dans dispose)
///   AdventureNotifier.instance.removeListener(_reload);
class AdventureNotifier extends ChangeNotifier {
  AdventureNotifier._();
  static final AdventureNotifier instance = AdventureNotifier._();

  void notify() => notifyListeners();
}