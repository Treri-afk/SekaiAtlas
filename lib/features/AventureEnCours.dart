import 'package:flutter/material.dart';
import 'package:sekai_atlas/features/CommencerUneNouvelleAventure.dart';
import 'package:sekai_atlas/functions/api_call.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AventureEnCours extends StatefulWidget {
  const AventureEnCours({Key? key}) : super(key: key);

  @override
  State<AventureEnCours> createState() => _AventureEnCoursState();
}

class _AventureEnCoursState extends State<AventureEnCours> {
  List<dynamic>? users;
  List<dynamic>? friend;
  Map<String, dynamic>? adventure;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadUsers();
  }

Future<void> loadUsers() async {
    try {
      final providerId = Supabase.instance.client.auth.currentUser?.id;
      if (providerId == null) throw 'Utilisateur non connecté';
      
      final connectedUser = await fetchUserByProviderId(providerId);
      final friendsList = await fetchFriends(connectedUser["id"]);
      final data = await adventureRunning(connectedUser["id"]);
      print(data);

      setState(() {
        friend = friendsList;
        users = data.isNotEmpty ? data[0]["result"]["players"] : [];
        adventure = data.isNotEmpty ? data[0]["result"]["adventure"] : null;
        loading = false;
      });
    } catch (e) {
      print('Erreur loadUsers : $e');
      setState(() {
        loading = false; // ← stoppe le loader même en cas d'erreur
        users = [];
        friend = [];
        adventure = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final bool noAdventure = adventure == null || adventure!["is_running"] == 0;

    if (noAdventure) {
      return InkWell(
        onTap: () async {
          if (users == null) {
            await loadUsers();
          }

          CommencerUneNouvelleAventureForm.show(
            context,
            users: friend,
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: double.infinity,
              height: 300,
              color: Colors.transparent,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Icon(Icons.add, color: Colors.grey, size: 30),
                    ),
                  ),

                  const SizedBox(height: 10),

                  const Text(
                    "Commencer une aventure",
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),
          ],
        ),
      );
    }

    // Affichage de l'aventure en cours avec les participants
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Container(
            height: 300,
            color: Colors.amber,
          ),
        ),

        Positioned(
          bottom: 15,
          left: 15,
          child: SizedBox(
            height: 40,
            width: (users!.length * 20) + 20,
            child: Stack(
              children: [
                ...List<Widget>.generate(users!.length, (index) {
                  final user = users![index];

                  return Positioned(
                    left: index * 20,
                    child: CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.white,
                      child: CircleAvatar(
                        radius: 18,
                        backgroundImage: user["image"] != null && user["image"] != ""
                            ? NetworkImage(user["image"])
                            : null,
                        child: user["image"] == null || user["image"] == ""
                            ? const Icon(Icons.person, size: 18)
                            : null,
                      ),
                    ),
                  );
                })
              ],
            ),
          ),
        )
      ],
    );
  }
}