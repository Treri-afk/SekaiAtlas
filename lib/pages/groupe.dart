import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:sekai_atlas/features/AventureEnCours.dart';
import 'package:sekai_atlas/features/Friends.dart';
import 'package:sekai_atlas/features/ListAventure.dart';
import 'package:sekai_atlas/features/ListeAventurier.dart';
import 'package:sekai_atlas/features/UserPopup.dart';
import '../functions/api_call.dart';

class GroupePage extends StatefulWidget {
  const GroupePage({Key? key}) : super(key: key);

  @override
  State<GroupePage> createState() => _GroupePageState();
}

class _GroupePageState extends State<GroupePage> {
  List<dynamic> friends = []; // Liste des utilisateurs récupérés depuis l'API
  Map<String, dynamic> actualUser = {};
  bool isLoading = true;
    List users = [
    {"name": "Alice", "image": "https://picsum.photos/200"},
    {"name": "Bob", "image": "https://picsum.photos/201"},
    {"name": "Paul", "image": "https://picsum.photos/202"},
    {"name": "Jean", "image": "https://picsum.photos/203"},
    {"name": "Juliette", "image": "https://picsum.photos/204"},
    {"name": "Yoshi", "image": "https://picsum.photos/205"},
    {"name": "Laurent", "image": "https://picsum.photos/206"},
    {"name": "Nico", "image": "https://picsum.photos/207"},
  ];
  @override
  void initState() {
    super.initState();
    loadPage();
  }

  void loadPage() async {
    try {
      final friendsList = await fetchFriends(1); // récupère la liste depuis API
      final connectedUser = await fetchUser(1);
      setState(() {
        friends = friendsList; // update la liste
        actualUser = connectedUser;
        print("pas error $actualUser");
        isLoading = false;   // stop le spinner
        
      });
    } catch (e) {
      print("error$e");
      setState(() => isLoading = false);
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // Header avec avatar
                      Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(50),
                            child: Image.network(
                              actualUser["avatar_url"],
                              width: 80,
                              height: 80,
                            ),
                          ),
                          const SizedBox(width: 20),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(actualUser["username"], style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const Spacer(),
                          IconButton(
                            onPressed: () => {FriendsPopUp.show(context)},
                            icon: const Icon(Icons.add_reaction),
                            style: ButtonStyle(
                              backgroundColor:
                                  MaterialStateProperty.all<Color>(Colors.blue),
                              foregroundColor:
                                  MaterialStateProperty.all<Color>(Colors.white),
                              shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                                RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          )
                        ],
                      ),
                      const Divider(),

                      // Aventure en cours
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 20),
                          const Text(
                            "Aventure en cours",
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 10),
                          AventureEnCours(EnCours: true, Users: users),
                        ],
                      ),

                      // Listes des aventures
                      Padding(
                        padding: const EdgeInsets.only(top: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Listes des aventures",
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 10),
                            ListeAventure(itemCount: 0),
                          ],
                        ),
                      ),

                      // Aventuriers de la guilde (liste horizontale)
                      Padding(
                        padding: const EdgeInsets.only(top: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Aventuriers de la guilde",
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 10),
                            ListeAventurier(users: friends)
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}