import 'package:flutter/material.dart';
import 'package:sekai_atlas/features/CommencerUneNouvelleAventure.dart';
import 'package:sekai_atlas/functions/api_call.dart';

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
    final friendsList = await fetchFriends(1);
    final data = await adventureRunning(1);

    setState(() {
      friend = friendsList;
      users = data[0]["result"]["players"];
      adventure = data[0]["result"]["adventure"];
      print(friend![0]);
      loading = false;
    });
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