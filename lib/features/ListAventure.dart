import 'package:flutter/material.dart';

class ListeAventure extends StatelessWidget {
  final int itemCount;

  const ListeAventure({Key? key, this.itemCount = 5}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (itemCount == 0) {
      return Container(
        height: 60, // garde la même hauteur
        alignment: Alignment.center,
        child: Text(
          "Aucune aventure pour le moment",
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return SizedBox(
      height: 100,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: itemCount,
        itemBuilder: (context, index) {
          return InkWell(
            onTap: () {
              print("Aventure $index cliquée");
              // Ici tu peux ouvrir la page de détails de l'aventure
            },
            child: Container(
              width: 100,
              color: Colors.blue,
              child: Center(
                child: Text(
                  "Item $index",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          );
        },
        separatorBuilder: (context, index) => SizedBox(width: 10),
      ),
    );
  }
}