import 'package:flutter/material.dart';
import 'package:sekai_atlas/features/UserPopup.dart';

class ListeAventurier extends StatelessWidget {
  final List<dynamic>? users;

  const ListeAventurier({Key? key, this.users}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (users?.length == 0) {
      return Container(
        height: 60, // garde la même hauteur
        alignment: Alignment.center,
        child: Text(
          "Aucun aventurier pour le moment",
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return SizedBox(
      height: 100,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: users!.length,
        itemBuilder: (context, index) {
          final user = users![index];
          return InkWell(
            onTap: () {
              UserPopup.show(context, user);
            },
            child:  CircleAvatar(
              radius: 40,
              backgroundImage: NetworkImage(user["avatar_url"]!),
            ),
          );
        },
        separatorBuilder: (context, index) => const SizedBox(width: 10),
      ),
    );
  }
}