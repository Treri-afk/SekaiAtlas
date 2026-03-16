import 'dart:convert';
import 'package:http/http.dart' as http;

const String baseURL = "http://10.0.2.2:3000";

Future<List<dynamic>> fetchFriends(user_id) async {
  final response = await http.get(Uri.parse('$baseURL/friends/friend?user_id=$user_id'));
  if (response.statusCode == 200) return json.decode(response.body);
  throw Exception('Erreur fetchFriends : ${response.statusCode}');
}

Future<Map<String, dynamic>> fetchUserById(user_id) async {
  final response = await http.get(Uri.parse('$baseURL/users/id?user_id=$user_id'));
  if (response.statusCode == 200) return json.decode(response.body);
  throw Exception('Erreur fetchUserById : ${response.statusCode}');
}

Future<Map<String, dynamic>> fetchUserByProviderId(provider_id) async {
  final response = await http.get(Uri.parse('$baseURL/users/provider?provider_id=$provider_id'));
  if (response.statusCode == 200) return json.decode(response.body);
  throw Exception('Erreur fetchUserByProviderId : ${response.statusCode}');
}

Future<Map<String, dynamic>> createUser(
    String username, String avatarUrl, String provider, String providerId) async {
  final response = await http.post(
    Uri.parse('$baseURL/users'),
    headers: {'Content-Type': 'application/json'},
    body: json.encode({
      'username': username,
      'avatar_url': avatarUrl,
      'provider': provider,
      'provider_id': providerId,
    }),
  );
  if (response.statusCode == 200 || response.statusCode == 201) {
    return json.decode(response.body);
  }
  throw Exception('Erreur createUser : ${response.statusCode}');
}

Future<List<dynamic>> fetchAdventure(user_id) async {
  final response = await http.get(Uri.parse('$baseURL/aventure/user?user_id=$user_id'));
  if (response.statusCode == 200) return json.decode(response.body);
  throw Exception('Erreur fetchAdventure : ${response.statusCode}');
}

// Retourne l'aventure en cours — la route backend retourne maintenant
// de vrais objets JS (plus de JSON_OBJECT string) :
// [ { result: { adventure: {...}, players: [...] } } ]
// ou [] si aucune aventure en cours
Future<List<dynamic>> adventureRunning(user_id) async {
  final response = await http.get(Uri.parse('$baseURL/aventure/running?user_id=$user_id'));
  if (response.statusCode == 200) return json.decode(response.body);
  throw Exception('Erreur adventureRunning : ${response.statusCode}');
}

Future<Map<String, dynamic>> addFriend(String friendCode, int userId) async {
  final response = await http.post(
    Uri.parse('$baseURL/friends'),
    headers: {'Content-Type': 'application/json'},
    body: json.encode({'user_id': userId, 'friend_code': friendCode}),
  );
  if (response.statusCode == 200 || response.statusCode == 201) {
    return json.decode(response.body);
  }
  final error = json.decode(response.body);
  throw Exception(error['error'] ?? 'Erreur addFriend : ${response.statusCode}');
}

Future<Map<String, dynamic>> createAdventure({
  required int creatorId,
  required String name,
  String? description,
  List<int> participantIds = const [],
}) async {
  final response = await http.post(
    Uri.parse('$baseURL/aventure'),
    headers: {'Content-Type': 'application/json'},
    body: json.encode({
      'creator_id': creatorId,
      'name': name,
      'description': description,
      'participant_ids': participantIds,
    }),
  );
  if (response.statusCode == 200 || response.statusCode == 201) {
    return json.decode(response.body);
  }
  final error = json.decode(response.body);
  throw Exception(error['error'] ?? 'Erreur createAdventure : ${response.statusCode}');
}

Future<List<dynamic>> fetchAdventurePhotos(int adventureId) async {
  final response = await http.get(
    Uri.parse('$baseURL/photos/adventure?adventure_id=$adventureId'),
  );
  if (response.statusCode == 200) return json.decode(response.body);
  throw Exception('Erreur fetchAdventurePhotos : ${response.statusCode}');
}

Future<List<dynamic>> fetchAdventureParticipants(int adventureId) async {
  final response = await http.get(
    Uri.parse('$baseURL/aventure/participants?adventure_id=$adventureId'),
  );
  if (response.statusCode == 200) return json.decode(response.body);
  throw Exception('Erreur fetchAdventureParticipants : ${response.statusCode}');
}

Future<void> terminateAdventure(int adventureId) async {
  final response = await http.patch(
    Uri.parse('$baseURL/aventure/$adventureId/terminate'),
    headers: {'Content-Type': 'application/json'},
  );
  if (response.statusCode != 200 && response.statusCode != 204) {
    final error = json.decode(response.body);
    throw Exception(error['error'] ?? 'Erreur terminateAdventure');
  }
}

Future<Map<String, dynamic>> postPhoto({
  required int userId,
  required int adventureId,
  required String imageUrl,
}) async {
  final response = await http.post(
    Uri.parse('$baseURL/photos'),
    headers: {'Content-Type': 'application/json'},
    body: json.encode({
      'user_id':      userId,
      'adventure_id': adventureId,
      'image_url':    imageUrl,
    }),
  );
  if (response.statusCode == 200 || response.statusCode == 201) {
    return json.decode(response.body);
  }
  final error = json.decode(response.body);
  throw Exception(error['error'] ?? 'Erreur postPhoto : ${response.statusCode}');
}
 