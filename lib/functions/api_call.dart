import 'dart:convert';
import 'package:http/http.dart' as http;

const String baseURL = "http://10.0.2.2:3000";

Future<List<dynamic>> fetchFriends(user_id) async {
  final response = await http.get(Uri.parse('$baseURL/friends/friend?user_id=$user_id'));

  if (response.statusCode == 200) {
    List<dynamic> friends = json.decode(response.body);
    return friends; // <-- IMPORTANT : retourne la liste
  } else {
    throw Exception('Erreur fetchFriends : ${response.statusCode}');
  }
}

Future<Map<String, dynamic>> fetchUser(user_id) async {
  final response = await http.get(Uri.parse('$baseURL/users/user?user_id=$user_id'));

  if (response.statusCode == 200) {
    Map<String, dynamic> user = json.decode(response.body);
    return user; // <-- IMPORTANT : retourne la liste
  } else {
    throw Exception('Erreur fetchFriends : ${response.statusCode}');
  }
}

Future<List<dynamic>> fetchAdventure(user_id) async {
  final response = await http.get(Uri.parse('$baseURL/aventure/user?user_id=$user_id'));

  if (response.statusCode == 200) {
    List<dynamic> friends = json.decode(response.body);
    return friends; // <-- IMPORTANT : retourne la liste
  } else {
    throw Exception('Erreur fetchFriends : ${response.statusCode}');
  }
}

Future<List<dynamic>> adventureRunning(user_id) async {
  final response = await http.get(Uri.parse('$baseURL/aventure/running?user_id=$user_id'));

  if (response.statusCode == 200) {
    List<dynamic> adventureRunning = json.decode(response.body);
    return adventureRunning; // <-- IMPORTANT : retourne la liste
  } else {
    throw Exception('Erreur fetchFriends : ${response.statusCode}');
  }
}