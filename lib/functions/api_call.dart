import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

// ─── Config ────────────────────────────────────────────────────────────────

final String supabaseUrl = dotenv.env['SUPABASE_URL'] ?? '';
final String anonKey     = dotenv.env['ANON_KEY']     ?? '';

// ─── Headers ───────────────────────────────────────────────────────────────

Map<String, String> get _headers => {
  'apikey':        anonKey,
  'Authorization': 'Bearer $anonKey',
  'Content-Type':  'application/json',
};

Map<String, String> get _headersReturn => {
  ..._headers,
  'Prefer': 'return=representation',
};

// ─────────────────────────────────────────────
//  USERS
// ─────────────────────────────────────────────

Future<Map<String, dynamic>> fetchUserByProviderId(String providerId) async {
  final url = '$supabaseUrl/rest/v1/users?provider_id=eq.$providerId&select=*';
  debugPrint('📡 [fetchUserByProviderId] GET $url');
  final res = await http.get(Uri.parse(url), headers: _headers);
  debugPrint('📡 [fetchUserByProviderId] status=${res.statusCode} body=${res.body}');
  if (res.statusCode == 200) {
    final data = json.decode(res.body) as List;
    debugPrint('📡 [fetchUserByProviderId] ${data.length} résultat(s)');
    if (data.isEmpty) throw Exception('Utilisateur non trouvé provider_id=$providerId');
    return Map<String, dynamic>.from(data[0]);
  }
  throw Exception('Erreur fetchUserByProviderId : ${res.statusCode} — ${res.body}');
}

Future<Map<String, dynamic>> fetchUserById(int userId) async {
  final url = '$supabaseUrl/rest/v1/users?id=eq.$userId&select=*';
  debugPrint('📡 [fetchUserById] GET $url');
  final res = await http.get(Uri.parse(url), headers: _headers);
  debugPrint('📡 [fetchUserById] status=${res.statusCode} body=${res.body}');
  if (res.statusCode == 200) {
    final data = json.decode(res.body) as List;
    debugPrint('📡 [fetchUserById] ${data.length} résultat(s)');
    if (data.isEmpty) throw Exception('Utilisateur non trouvé id=$userId');
    return Map<String, dynamic>.from(data[0]);
  }
  throw Exception('Erreur fetchUserById : ${res.statusCode} — ${res.body}');
}

/// Miroir de Express POST /users
/// 1. Vérifie si l'utilisateur existe déjà (provider_id)
/// 2. Génère un friend_code unique (même alphabet qu'Express)
/// 3. Insère l'utilisateur
Future<Map<String, dynamic>> createUser(
    String username, String avatarUrl, String provider, String providerId) async {
  debugPrint('📡 [createUser] vérification existence providerId=$providerId');

  // Étape 1 : vérifie si déjà existant
  try {
    final existing = await fetchUserByProviderId(providerId);
    debugPrint('📡 [createUser] utilisateur existant → id=${existing["id"]} username=${existing["username"]}');
    return existing;
  } catch (_) {
    debugPrint('📡 [createUser] non trouvé → création en cours');
  }

  // Étape 2 : générer un friend_code unique (même logique qu'Express)
  debugPrint('📡 [createUser] étape 2 — génération friend_code unique');
  final friendCode = await _generateUniqueFriendCode();
  debugPrint('📡 [createUser] friend_code généré → $friendCode');

  // Étape 3 : insérer l'utilisateur
  final url  = '$supabaseUrl/rest/v1/users';
  final body = {
    'username':    username,
    'avatar_url':  avatarUrl,
    'provider':    provider,
    'provider_id': providerId,
    'friend_code': friendCode,
  };
  debugPrint('📡 [createUser] POST $url body=$body');
  final res = await http.post(Uri.parse(url), headers: _headersReturn, body: json.encode(body));
  debugPrint('📡 [createUser] status=${res.statusCode} body=${res.body}');
  if (res.statusCode == 200 || res.statusCode == 201) {
    final data = json.decode(res.body);
    if (data is List && data.isNotEmpty) return Map<String, dynamic>.from(data[0]);
    if (data is Map)                     return Map<String, dynamic>.from(data);
    throw Exception('Réponse createUser inattendue : $data');
  }
  throw Exception('Erreur createUser : ${res.statusCode} — ${res.body}');
}

/// Génère un code ami de 6 caractères parmi l'alphabet d'Express
/// et vérifie qu'il n'est pas déjà utilisé dans Supabase.
Future<String> _generateUniqueFriendCode() async {
  const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  final rng   = math.Random.secure();

  while (true) {
    // Génère 6 caractères aléatoires
    final code = List.generate(6, (_) => chars[rng.nextInt(chars.length)]).join();
    debugPrint('📡 [_generateUniqueFriendCode] tentative code=$code');

    // Vérifie qu'il n'existe pas déjà
    final url = '$supabaseUrl/rest/v1/users?friend_code=eq.$code&select=id';
    final res = await http.get(Uri.parse(url), headers: _headers);
    debugPrint('📡 [_generateUniqueFriendCode] check status=${res.statusCode} body=${res.body}');
    if (res.statusCode == 200) {
      final data = json.decode(res.body) as List;
      if (data.isEmpty) {
        debugPrint('📡 [_generateUniqueFriendCode] ✅ code unique trouvé → $code');
        return code; // Code libre → on l'utilise
      }
      debugPrint('📡 [_generateUniqueFriendCode] code déjà pris → nouvelle tentative');
    } else {
      throw Exception('Erreur vérification friend_code : ${res.statusCode}');
    }
  }
}

Future<Map<String, dynamic>> updateUser(int userId, {String? username, String? avatarUrl}) async {
  final url  = '$supabaseUrl/rest/v1/users?id=eq.$userId';
  final body = <String, dynamic>{};
  if (username  != null) body['username']   = username;
  if (avatarUrl != null) body['avatar_url'] = avatarUrl;
  debugPrint('📡 [updateUser] PATCH userId=$userId body=$body');
  final res = await http.patch(Uri.parse(url), headers: _headersReturn, body: json.encode(body));
  debugPrint('📡 [updateUser] status=${res.statusCode} body=${res.body}');
  if (res.statusCode == 200) {
    final data = json.decode(res.body) as List;
    if (data.isEmpty) throw Exception('Utilisateur non trouvé après update id=$userId');
    return Map<String, dynamic>.from(data[0]);
  }
  throw Exception('Erreur updateUser : ${res.statusCode} — ${res.body}');
}

// ─────────────────────────────────────────────
//  FRIENDS  (table : users_friend)
// ─────────────────────────────────────────────

/// Miroir de Express GET /friends/friend
/// La table s'appelle users_friend.
/// La relation est unilatérale (1 seule ligne par ajout).
/// On cherche dans les deux sens et on déduplique.
Future<List<dynamic>> fetchFriends(int userId) async {
  debugPrint('📡 [fetchFriends] userId=$userId');

  // Côté initiateur : je suis user_id, l'ami est friend_id
  debugPrint('📡 [fetchFriends] requête 1 — où je suis user_id');
  final url1 = '$supabaseUrl/rest/v1/users_friend'
      '?user_id=eq.$userId'
      '&select=friend:users!users_friend_friend_id_fkey(id,username,avatar_url,friend_code)';
  debugPrint('📡 [fetchFriends] GET $url1');
  final res1 = await http.get(Uri.parse(url1), headers: _headers);
  debugPrint('📡 [fetchFriends] req1 status=${res1.statusCode} body=${res1.body}');

  // Côté cible : quelqu'un m'a ajouté, je suis friend_id
  debugPrint('📡 [fetchFriends] requête 2 — où je suis friend_id');
  final url2 = '$supabaseUrl/rest/v1/users_friend'
      '?friend_id=eq.$userId'
      '&select=friend:users!users_friend_user_id_fkey(id,username,avatar_url,friend_code)';
  debugPrint('📡 [fetchFriends] GET $url2');
  final res2 = await http.get(Uri.parse(url2), headers: _headers);
  debugPrint('📡 [fetchFriends] req2 status=${res2.statusCode} body=${res2.body}');

  if (res1.statusCode != 200) throw Exception('Erreur fetchFriends req1 : ${res1.statusCode}');
  if (res2.statusCode != 200) throw Exception('Erreur fetchFriends req2 : ${res2.statusCode}');

  final list1 = (json.decode(res1.body) as List)
      .map((r) => r['friend'])
      .where((f) => f != null)
      .toList();
  final list2 = (json.decode(res2.body) as List)
      .map((r) => r['friend'])
      .where((f) => f != null)
      .toList();

  debugPrint('📡 [fetchFriends] ${list1.length} ami(s) côté user_id, ${list2.length} côté friend_id');

  // Dédupliquer par id
  final seen    = <int>{};
  final friends = <dynamic>[];
  for (final f in [...list1, ...list2]) {
    final id = f['id'] as int;
    if (seen.add(id)) {
      friends.add(f);
      debugPrint('📡 [fetchFriends]   → ami id=$id username=${f["username"]}');
    }
  }
  debugPrint('📡 [fetchFriends] ✅ ${friends.length} ami(s) après déduplication');
  return friends;
}

/// Miroir de Express POST /friends
/// Table : users_friend (relation unilatérale — 1 seule ligne)
Future<Map<String, dynamic>> addFriend(String friendCode, int userId) async {
  final code = friendCode.trim().toUpperCase();
  debugPrint('📡 [addFriend] userId=$userId friendCode=$code');

  // Étape 1 : trouver l'user avec ce friend_code
  debugPrint('📡 [addFriend] étape 1 — recherche par friend_code');
  final searchUrl = '$supabaseUrl/rest/v1/users?friend_code=eq.$code&select=id&limit=1';
  debugPrint('📡 [addFriend] GET $searchUrl');
  final searchRes = await http.get(Uri.parse(searchUrl), headers: _headers);
  debugPrint('📡 [addFriend] search status=${searchRes.statusCode} body=${searchRes.body}');
  if (searchRes.statusCode != 200) {
    throw Exception('Erreur recherche friend_code : ${searchRes.statusCode}');
  }
  final found = json.decode(searchRes.body) as List;
  debugPrint('📡 [addFriend] ${found.length} user(s) trouvé(s)');
  if (found.isEmpty) throw Exception('Aucun utilisateur trouvé avec ce code ami');

  final friendId = found[0]['id'] as int;
  debugPrint('📡 [addFriend] ami trouvé → friendId=$friendId');

  if (friendId == userId) {
    debugPrint('🔴 [addFriend] tentative de s\'ajouter soi-même → refus');
    throw Exception('Vous ne pouvez pas vous ajouter vous-même');
  }

  // Étape 2 : vérifier si relation existe déjà dans les deux sens
  // (même logique que Express : .or(...))
  debugPrint('📡 [addFriend] étape 2 — vérification doublon (les deux sens)');
  final checkUrl = '$supabaseUrl/rest/v1/users_friend'
      '?or=(and(user_id.eq.$userId,friend_id.eq.$friendId),and(user_id.eq.$friendId,friend_id.eq.$userId))'
      '&select=id';
  debugPrint('📡 [addFriend] GET $checkUrl');
  final checkRes = await http.get(Uri.parse(checkUrl), headers: _headers);
  debugPrint('📡 [addFriend] check status=${checkRes.statusCode} body=${checkRes.body}');
  if (checkRes.statusCode == 200) {
    final existing = json.decode(checkRes.body) as List;
    debugPrint('📡 [addFriend] ${existing.length} relation(s) existante(s)');
    if (existing.isNotEmpty) throw Exception('Vous êtes déjà amis');
  }

  // Étape 3 : insérer UNE seule ligne (unilatéral comme Express)
  debugPrint('📡 [addFriend] étape 3 — insertion relation user_id=$userId friend_id=$friendId');
  final url  = '$supabaseUrl/rest/v1/users_friend';
  final body = json.encode({'user_id': userId, 'friend_id': friendId});
  debugPrint('📡 [addFriend] POST $url body=$body');
  final res = await http.post(Uri.parse(url), headers: _headersReturn, body: body);
  debugPrint('📡 [addFriend] status=${res.statusCode} body=${res.body}');
  if (res.statusCode == 200 || res.statusCode == 201) {
    debugPrint('📡 [addFriend] ✅ amitié créée');
    return {'success': true, 'friend_id': friendId};
  }
  final error = json.decode(res.body);
  throw Exception(error['message'] ?? 'Erreur addFriend : ${res.statusCode}');
}

// ─────────────────────────────────────────────
//  ADVENTURES
// ─────────────────────────────────────────────

/// Miroir de Express GET /adventures/user
Future<List<dynamic>> fetchAdventure(int userId) async {
  debugPrint('📡 [fetchAdventure] userId=$userId');
  final url = '$supabaseUrl/rest/v1/adventure_participants'
      '?user_id=eq.$userId'
      '&select=adventures(*)';
  debugPrint('📡 [fetchAdventure] GET $url');
  final res = await http.get(Uri.parse(url), headers: _headers);
  debugPrint('📡 [fetchAdventure] status=${res.statusCode} body=${res.body}');
  if (res.statusCode == 200) {
    final data = json.decode(res.body) as List;
    final adventures = data.map((d) => d['adventures']).where((a) => a != null).toList();
    debugPrint('📡 [fetchAdventure] ${adventures.length} aventure(s)');
    for (final a in adventures) {
      debugPrint('📡 [fetchAdventure]   → id=${a["id"]} name=${a["name"]} is_running=${a["is_running"]}');
    }
    return adventures;
  }
  throw Exception('Erreur fetchAdventure : ${res.statusCode} — ${res.body}');
}

/// Miroir exact de Express GET /adventures/running
/// Fetch toutes les participations → filtre is_running côté Dart → fetch players
Future<List<dynamic>> adventureRunning(int userId) async {
  debugPrint('📡 [adventureRunning] userId=$userId');

  // Étape 1 : toutes les participations avec join aventure
  debugPrint('📡 [adventureRunning] étape 1 — fetch participations');
  final url = '$supabaseUrl/rest/v1/adventure_participants'
      '?user_id=eq.$userId'
      '&select=adventures(*)';
  debugPrint('📡 [adventureRunning] GET $url');
  final res = await http.get(Uri.parse(url), headers: _headers);
  debugPrint('📡 [adventureRunning] status=${res.statusCode} body=${res.body}');
  if (res.statusCode != 200) {
    throw Exception('Erreur adventureRunning step1 : ${res.statusCode} — ${res.body}');
  }

  final participations = json.decode(res.body) as List;
  debugPrint('📡 [adventureRunning] ${participations.length} participation(s) totales');

  // Filtre is_running côté Dart (même logique qu'Express)
  final running = participations
      .map((p) => p['adventures'])
      .where((a) => a != null && a['is_running'] == true)
      .toList();

  debugPrint('📡 [adventureRunning] ${running.length} aventure(s) is_running=true');

  if (running.isEmpty) {
    debugPrint('📡 [adventureRunning] aucune aventure en cours → []');
    return [];
  }

  final adventure = Map<String, dynamic>.from(running[0]);
  debugPrint('📡 [adventureRunning] aventure active → id=${adventure["id"]} name=${adventure["name"]}');

  // Étape 2 : récupérer les participants
  debugPrint('📡 [adventureRunning] étape 2 — fetch participants adventure_id=${adventure["id"]}');
  final partUrl = '$supabaseUrl/rest/v1/adventure_participants'
      '?adventure_id=eq.${adventure["id"]}'
      '&select=users(id,username,avatar_url)';
  debugPrint('📡 [adventureRunning] GET $partUrl');
  final partRes = await http.get(Uri.parse(partUrl), headers: _headers);
  debugPrint('📡 [adventureRunning] participants status=${partRes.statusCode} body=${partRes.body}');
  if (partRes.statusCode != 200) {
    throw Exception('Erreur adventureRunning step2 : ${partRes.statusCode}');
  }

  final partData = json.decode(partRes.body) as List;
  final players  = partData.map((p) => p['users']).where((u) => u != null).toList();
  debugPrint('📡 [adventureRunning] ${players.length} joueur(s)');
  for (final p in players) {
    debugPrint('📡 [adventureRunning]   → id=${p["id"]} username=${p["username"]}');
  }

  // Retourne le même format qu'Express pour compatibilité avec camera_screen.dart
  return [{'result': {'adventure': adventure, 'players': players}}];
}

/// Miroir de Express POST /adventures
Future<Map<String, dynamic>> createAdventure({
  required int creatorId,
  required String name,
  String? description,
  List<int> participantIds = const [],
}) async {
  debugPrint('📡 [createAdventure] creatorId=$creatorId name="$name" participants=$participantIds');

  // Étape 1 : créer l'aventure
  debugPrint('📡 [createAdventure] étape 1 — insertion aventure');
  final advUrl  = '$supabaseUrl/rest/v1/adventures';
  final advBody = json.encode({
    'name':        name,
    'description': description,
    'creator_id':  creatorId,
    'is_running':  true,
  });
  debugPrint('📡 [createAdventure] POST $advUrl body=$advBody');
  final advRes = await http.post(Uri.parse(advUrl), headers: _headersReturn, body: advBody);
  debugPrint('📡 [createAdventure] status=${advRes.statusCode} body=${advRes.body}');
  if (advRes.statusCode != 200 && advRes.statusCode != 201) {
    throw Exception('Erreur createAdventure step1 : ${advRes.statusCode} — ${advRes.body}');
  }

  final advData    = json.decode(advRes.body);
  final adventureId = (advData is List ? advData[0] : advData)['id'] as int;
  debugPrint('📡 [createAdventure] aventure créée → id=$adventureId');

  // Étape 2 : ajouter les participants (dédupliqués, creator inclus)
  final allIds = {...[creatorId], ...participantIds}.toList();
  debugPrint('📡 [createAdventure] étape 2 — insertion ${allIds.length} participant(s) : $allIds');
  final partUrl  = '$supabaseUrl/rest/v1/adventure_participants';
  final partBody = json.encode(
    allIds.map((uid) => {'adventure_id': adventureId, 'user_id': uid}).toList(),
  );
  debugPrint('📡 [createAdventure] POST $partUrl body=$partBody');
  final partRes = await http.post(Uri.parse(partUrl), headers: _headers, body: partBody);
  debugPrint('📡 [createAdventure] participants status=${partRes.statusCode} body=${partRes.body}');
  if (partRes.statusCode != 200 && partRes.statusCode != 201) {
    throw Exception('Erreur createAdventure step2 : ${partRes.statusCode} — ${partRes.body}');
  }

  debugPrint('📡 [createAdventure] ✅ aventure $adventureId avec ${allIds.length} participant(s)');
  return {'success': true, 'adventure_id': adventureId, 'participant_count': allIds.length};
}

/// Miroir de Express GET /adventures/participants
Future<List<dynamic>> fetchAdventureParticipants(int adventureId) async {
  debugPrint('📡 [fetchAdventureParticipants] adventureId=$adventureId');
  final url = '$supabaseUrl/rest/v1/adventure_participants'
      '?adventure_id=eq.$adventureId'
      '&select=users(id,username,avatar_url)';
  debugPrint('📡 [fetchAdventureParticipants] GET $url');
  final res = await http.get(Uri.parse(url), headers: _headers);
  debugPrint('📡 [fetchAdventureParticipants] status=${res.statusCode} body=${res.body}');
  if (res.statusCode == 200) {
    final data         = json.decode(res.body) as List;
    final participants = data.map((d) => d['users']).where((u) => u != null).toList();
    debugPrint('📡 [fetchAdventureParticipants] ${participants.length} participant(s)');
    for (final p in participants) {
      debugPrint('📡 [fetchAdventureParticipants]   → id=${p["id"]} username=${p["username"]}');
    }
    return participants;
  }
  throw Exception('Erreur fetchAdventureParticipants : ${res.statusCode} — ${res.body}');
}

/// Miroir de Express PATCH /adventures/:id/terminate
Future<void> terminateAdventure(int adventureId) async {
  final url = '$supabaseUrl/rest/v1/adventures?id=eq.$adventureId';
  debugPrint('📡 [terminateAdventure] PATCH $url');
  final res = await http.patch(
    Uri.parse(url),
    headers: _headers,
    body: json.encode({'is_running': false}),
  );
  debugPrint('📡 [terminateAdventure] status=${res.statusCode} body=${res.body}');
  if (res.statusCode != 200 && res.statusCode != 204) {
    throw Exception('Erreur terminateAdventure : ${res.statusCode} — ${res.body}');
  }
  debugPrint('📡 [terminateAdventure] ✅ aventure $adventureId terminée');
}

// ─────────────────────────────────────────────
//  PHOTOS  (table : photos, join : poi(...))
// ─────────────────────────────────────────────

/// Miroir de Express GET /photos/adventure
/// Le join sur poi s'écrit poi(...) sans FK explicite (même syntaxe qu'Express).
Future<List<dynamic>> fetchAdventurePhotos(int adventureId) async {
  debugPrint('📡 [fetchAdventurePhotos] adventureId=$adventureId');

  // Syntaxe identique à celle utilisée dans le JS Express côté Supabase client
  const select =
      'id,image_url,latitude,longitude,description,created_at,poi_id,adventure_id,'
      'users!inner(id,username,avatar_url),'
      'adventures!inner(name),'
      'poi(id,name,badge_name,badge_description,rarity,category)';

  final uri = Uri.parse('$supabaseUrl/rest/v1/photos').replace(queryParameters: {
    'adventure_id': 'eq.$adventureId',
    'select':       select,
    'order':        'created_at.desc',
  });
  debugPrint('📡 [fetchAdventurePhotos] GET $uri');
  final res = await http.get(uri, headers: _headers);
  debugPrint('📡 [fetchAdventurePhotos] status=${res.statusCode}');
  debugPrint('📡 [fetchAdventurePhotos] body=${res.body.length > 500 ? res.body.substring(0, 500) + "…" : res.body}');
  if (res.statusCode != 200) {
    throw Exception('Erreur fetchAdventurePhotos : ${res.statusCode} — ${res.body}');
  }
  final raw = json.decode(res.body) as List;
  debugPrint('📡 [fetchAdventurePhotos] ${raw.length} photo(s) brute(s)');
  return _flattenPhotos(raw, caller: 'fetchAdventurePhotos');
}

/// Miroir de Express GET /photos
Future<List<dynamic>> fetchAllPhotos() async {
  debugPrint('📡 [fetchAllPhotos] début');

  const select =
      'id,image_url,latitude,longitude,description,created_at,poi_id,adventure_id,'
      'users!inner(id,username,avatar_url),'
      'adventures!inner(name),'
      'poi(id,name,badge_name,badge_description,rarity,category)';

  final uri = Uri.parse('$supabaseUrl/rest/v1/photos').replace(queryParameters: {
    'select': select,
    'order':  'created_at.desc',
    'limit':  '500',
  });
  debugPrint('📡 [fetchAllPhotos] GET $uri');
  final res = await http.get(uri, headers: _headers);
  debugPrint('📡 [fetchAllPhotos] status=${res.statusCode}');
  debugPrint('📡 [fetchAllPhotos] body (500c) : ${res.body.length > 500 ? res.body.substring(0, 500) + "…" : res.body}');
  if (res.statusCode != 200) {
    throw Exception('Erreur fetchAllPhotos : ${res.statusCode} — ${res.body}');
  }
  final raw = json.decode(res.body) as List;
  debugPrint('📡 [fetchAllPhotos] ${raw.length} photo(s) brute(s)');
  return _flattenPhotos(raw, caller: 'fetchAllPhotos');
}

/// Aplatit les sous-objets joints (users, adventures, poi) en un Map plat.
/// Reproduit exactement la structure attendue par map_page.dart et aventure_detail_popup.dart.
List<Map<String, dynamic>> _flattenPhotos(List raw, {required String caller}) {
  int withPoi = 0, withBadge = 0, withCoords = 0;

  final result = raw.map((p) {
    final m         = Map<String, dynamic>.from(p as Map);
    final user      = m.remove('users')      as Map<String, dynamic>?;
    final adventure = m.remove('adventures') as Map<String, dynamic>?;
    final poi       = m.remove('poi')        as Map<String, dynamic>?; // ← 'poi' pas 'pois'

    // User
    if (user != null) {
      m['username']   = user['username'];
      m['avatar_url'] = user['avatar_url'];
    } else {
      m['username']   = null;
      m['avatar_url'] = null;
      debugPrint('⚠️  [$caller] photo id=${m["id"]} — join user manquant (user_id=${m["user_id"]})');
    }

    // Adventure name
    m['adventure_name'] = adventure?['name'];

    // POI + badge (clé 'poi' en minuscule, nom de la table)
    if (poi != null) {
      m['poi_name']          = poi['name'];
      m['poi_rarity']        = poi['rarity'];
      m['badge_name']        = poi['badge_name'];
      m['badge_description'] = poi['badge_description'];
      withPoi++;
      if (poi['badge_name'] != null && poi['badge_name'].toString().isNotEmpty) withBadge++;
      debugPrint('📡 [$caller] photo id=${m["id"]} → '
          'poi=${poi["name"]} rarity=${poi["rarity"]} badge=${poi["badge_name"]}');
    } else {
      m['poi_name']          = null;
      m['poi_rarity']        = null;
      m['badge_name']        = null;
      m['badge_description'] = null;
      if (m['poi_id'] != null) {
        debugPrint('⚠️  [$caller] photo id=${m["id"]} a poi_id=${m["poi_id"]} '
            'mais le join poi a retourné null — vérifier RLS ou nom de la FK');
      }
    }

    final lat = double.tryParse(m['latitude']?.toString()  ?? '');
    final lng = double.tryParse(m['longitude']?.toString() ?? '');
    if (lat != null && lng != null) withCoords++;

    return m;
  }).toList();

  debugPrint('📡 [$caller] ✅ ${result.length} photos | GPS:$withCoords POI:$withPoi badge:$withBadge');
  return result;
}

/// Miroir de Express POST /photos
Future<void> postPhoto({
  required int userId,
  required int adventureId,
  required String imageUrl,
  String? description,
  double? latitude,
  double? longitude,
  int? poiId,
}) async {
  final url  = '$supabaseUrl/rest/v1/photos';
  final body = <String, dynamic>{
    'user_id':      userId,
    'adventure_id': adventureId,
    'image_url':    imageUrl,
  };
  if (description != null && description.isNotEmpty) body['description'] = description;
  if (latitude    != null) body['latitude']  = latitude;
  if (longitude   != null) body['longitude'] = longitude;
  if (poiId       != null) body['poi_id']    = poiId;

  debugPrint('📡 [postPhoto] POST $url');
  debugPrint('📡 [postPhoto] userId=$userId adventureId=$adventureId');
  debugPrint('📡 [postPhoto] lat=$latitude lng=$longitude poiId=$poiId');
  debugPrint('📡 [postPhoto] imageUrl=$imageUrl description="$description"');

  final res = await http.post(Uri.parse(url), headers: _headersReturn, body: json.encode(body));
  debugPrint('📡 [postPhoto] status=${res.statusCode} body=${res.body}');
  if (res.statusCode == 200 || res.statusCode == 201) {
    debugPrint('📡 [postPhoto] ✅ photo enregistrée');
    return;
  }
  throw Exception('Erreur postPhoto : ${res.statusCode} — ${res.body}');
}

// ─────────────────────────────────────────────
//  POI  (table : poi)
// ─────────────────────────────────────────────

/// Miroir de Express GET /poi
Future<List<dynamic>> fetchAllPoi() async {
  final url = '$supabaseUrl/rest/v1/poi'
      '?select=id,name,description,latitude,longitude,prefecture_code,category,rarity,badge_name,badge_description,radius_meters';
  debugPrint('📡 [fetchAllPoi] GET $url');
  final res = await http.get(Uri.parse(url), headers: _headers);
  debugPrint('📡 [fetchAllPoi] status=${res.statusCode} body=${res.body}');
  if (res.statusCode == 200) {
    final data = json.decode(res.body) as List;
    debugPrint('📡 [fetchAllPoi] ${data.length} POI(s)');
    return data;
  }
  throw Exception('Erreur fetchAllPoi : ${res.statusCode} — ${res.body}');
}

/// Miroir de Express GET /poi/nearby
/// Même logique : fetch tous les POI → filtre Haversine côté Dart
/// en utilisant le radius_meters propre à chaque POI (comme Express).
Future<List<dynamic>> fetchNearbyPoi(double latitude, double longitude) async {
  debugPrint('📡 [fetchNearbyPoi] lat=$latitude lng=$longitude');
  debugPrint('📡 [fetchNearbyPoi] fetch tous les POI → filtre Haversine (même logique qu\'Express)');

  final all = await fetchAllPoi();
  debugPrint('📡 [fetchNearbyPoi] ${all.length} POI(s) totaux à filtrer');

  final nearby = <Map<String, dynamic>>[];

  for (final raw in all) {
    final poi     = Map<String, dynamic>.from(raw as Map);
    final poiLat  = double.tryParse(poi['latitude']?.toString()      ?? '');
    final poiLng  = double.tryParse(poi['longitude']?.toString()     ?? '');
    final radius  = double.tryParse(poi['radius_meters']?.toString() ?? '');

    if (poiLat == null || poiLng == null || radius == null) {
      debugPrint('⚠️  [fetchNearbyPoi] POI id=${poi["id"]} coordonnées ou radius manquant — ignoré');
      continue;
    }

    final dist = _haversineMeters(latitude, longitude, poiLat, poiLng);
    debugPrint('📡 [fetchNearbyPoi] POI id=${poi["id"]} name=${poi["name"]} '
        'dist=${dist.toStringAsFixed(0)}m radius=${radius.toStringAsFixed(0)}m');

    if (dist <= radius) {
      poi['distance_meters'] = dist.round();
      nearby.add(poi);
      debugPrint('📡 [fetchNearbyPoi]   ✅ dans le rayon → ajouté');
    }
  }

  nearby.sort((a, b) =>
      (a['distance_meters'] as int).compareTo(b['distance_meters'] as int));

  debugPrint('📡 [fetchNearbyPoi] ✅ ${nearby.length} POI(s) à proximité');
  return nearby;
}

/// Formule Haversine : distance en mètres.
double _haversineMeters(double lat1, double lng1, double lat2, double lng2) {
  const r    = 6371000.0;
  final dLat = _deg2rad(lat2 - lat1);
  final dLng = _deg2rad(lng2 - lng1);
  final a    = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(_deg2rad(lat1)) * math.cos(_deg2rad(lat2)) *
      math.sin(dLng / 2) * math.sin(dLng / 2);
  return r * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
}

double _deg2rad(double deg) => deg * math.pi / 180;

/// Miroir de Express GET /poi/:id
Future<Map<String, dynamic>> fetchPoiById(int id) async {
  final url = '$supabaseUrl/rest/v1/poi'
      '?id=eq.$id'
      '&select=id,name,description,latitude,longitude,category,rarity,badge_name,badge_description,radius_meters';
  debugPrint('📡 [fetchPoiById] GET $url');
  final res = await http.get(Uri.parse(url), headers: _headers);
  debugPrint('📡 [fetchPoiById] status=${res.statusCode} body=${res.body}');
  if (res.statusCode == 200) {
    final data = json.decode(res.body) as List;
    debugPrint('📡 [fetchPoiById] ${data.length} résultat(s)');
    if (data.isEmpty) throw Exception('POI non trouvé id=$id');
    return Map<String, dynamic>.from(data[0]);
  }
  throw Exception('Erreur fetchPoiById : ${res.statusCode} — ${res.body}');
}

// ─────────────────────────────────────────────
//  BADGES  (table : user_badges, join : poi:poi_id(...))
// ─────────────────────────────────────────────

/// Miroir de Express GET /badges/user
/// Même syntaxe de join que le JS : poi:poi_id(...)
Future<List<dynamic>> fetchUserBadges(int userId) async {
  const select =
      'id,unlocked_at,'
      'poi:poi_id(id,name,badge_name,badge_description,category,rarity)';

  final uri = Uri.parse('$supabaseUrl/rest/v1/user_badges').replace(queryParameters: {
    'user_id': 'eq.$userId',
    'select':  select,
    'order':   'unlocked_at.desc',
  });
  debugPrint('📡 [fetchUserBadges] GET $uri');
  final res = await http.get(uri, headers: _headers);
  debugPrint('📡 [fetchUserBadges] status=${res.statusCode} body=${res.body}');
  if (res.statusCode != 200) {
    throw Exception('Erreur fetchUserBadges : ${res.statusCode} — ${res.body}');
  }

  final raw = json.decode(res.body) as List;
  debugPrint('📡 [fetchUserBadges] ${raw.length} badge(s) brut(s)');

  // Aplatir comme Express le fait
  final result = raw.where((ub) => ub['poi'] != null).map((ub) {
    final m   = Map<String, dynamic>.from(ub as Map);
    final poi = m.remove('poi') as Map<String, dynamic>;
    m['poi_id']            = poi['id'];
    m['name']              = poi['name'];
    m['badge_name']        = poi['badge_name'];
    m['badge_description'] = poi['badge_description'];
    m['category']          = poi['category'];
    m['poi_rarity']        = poi['rarity'];
    debugPrint('📡 [fetchUserBadges]   → id=${m["id"]} poi=${poi["name"]} badge=${poi["badge_name"]}');
    return m;
  }).toList();

  debugPrint('📡 [fetchUserBadges] ✅ ${result.length} badge(s) pour userId=$userId');
  return result;
}

/// Miroir de Express POST /badges
/// Vérifie doublon → insère → retourne {already_unlocked, ...}
Future<Map<String, dynamic>> unlockBadge(int userId, int poiId) async {
  debugPrint('📡 [unlockBadge] userId=$userId poiId=$poiId');

  // Étape 1 : vérifier si déjà débloqué
  debugPrint('📡 [unlockBadge] étape 1 — vérification doublon');
  final checkUrl = '$supabaseUrl/rest/v1/user_badges'
      '?user_id=eq.$userId&poi_id=eq.$poiId&select=id&limit=1';
  debugPrint('📡 [unlockBadge] GET $checkUrl');
  final checkRes = await http.get(Uri.parse(checkUrl), headers: _headers);
  debugPrint('📡 [unlockBadge] check status=${checkRes.statusCode} body=${checkRes.body}');

  if (checkRes.statusCode == 200) {
    final existing = json.decode(checkRes.body) as List;
    debugPrint('📡 [unlockBadge] ${existing.length} entrée(s) existante(s)');
    if (existing.isNotEmpty) {
      debugPrint('📡 [unlockBadge] badge déjà débloqué → already_unlocked=true');
      return {'success': true, 'already_unlocked': true};
    }
  }

  // Étape 2 : insérer le badge
  debugPrint('📡 [unlockBadge] étape 2 — insertion badge');
  final url  = '$supabaseUrl/rest/v1/user_badges';
  final body = json.encode({'user_id': userId, 'poi_id': poiId});
  debugPrint('📡 [unlockBadge] POST $url body=$body');
  final res = await http.post(Uri.parse(url), headers: _headersReturn, body: body);
  debugPrint('📡 [unlockBadge] status=${res.statusCode} body=${res.body}');

  if (res.statusCode == 200 || res.statusCode == 201) {
    final inserted = json.decode(res.body);
    final insertedId = (inserted is List ? inserted[0] : inserted)['id'];
    debugPrint('📡 [unlockBadge] ✅ badge débloqué id=$insertedId → already_unlocked=false');

    // Étape 3 : fetch les infos du POI pour alimenter la dialog de célébration
    debugPrint('📡 [unlockBadge] étape 3 — fetch infos POI id=$poiId pour dialog');
    try {
      final poi = await fetchPoiById(poiId);
      debugPrint('📡 [unlockBadge] POI → name=${poi["name"]} badge_name=${poi["badge_name"]}');
      return {
        'success':           true,
        'already_unlocked':  false,
        'id':                insertedId,
        'badge_name':        poi['badge_name'],
        'badge_description': poi['badge_description'],
        'poi_name':          poi['name'],
        'poi_rarity':        poi['rarity'],
      };
    } catch (e) {
      debugPrint('⚠️  [unlockBadge] impossible de fetch le POI : $e');
      return {'success': true, 'already_unlocked': false, 'id': insertedId};
    }
  }

  throw Exception('Erreur unlockBadge : ${res.statusCode} — ${res.body}');
}