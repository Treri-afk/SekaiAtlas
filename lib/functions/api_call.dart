import 'dart:convert';
import 'package:http/http.dart' as http;

class api_call {
  
  String baseURL = "http://localhost:3000/";


  Future<void> fetchFriends() async {
    final response = await http.get(Uri.parse('$baseURL/friend?user_id=1'));

    if (response.statusCode == 200) {
      // Parse JSON
      List<dynamic> friends = json.decode(response.body);

      // Chaque élément est une Map<String, dynamic>
      for (var friend in friends) {
        print(friend['username']);   // ex: "alex"
        print(friend['avatar_url']); // ex: "https://picsum.photos/205"
      }
    } else {
      print('Erreur : ${response.statusCode}');
    }
  }
}