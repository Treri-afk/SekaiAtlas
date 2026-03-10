import 'package:flutter/material.dart';

class UserPopup {

  static void show(BuildContext context, Map user) {

    showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      builder: (context) {

        return Container(
          padding: EdgeInsets.all(20),
          height: MediaQuery.of(context).size.height - 200,
          width: MediaQuery.of(context).size.width-50,

          child: Column(
            children: [

              CircleAvatar(
                radius: 40,
                backgroundImage: NetworkImage(user["image"]),
              ),

              SizedBox(height: 10),

              Text(
                user["name"],
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              SizedBox(height: 20),

              ElevatedButton(
                onPressed: () {},
                child: Text("Voir profil"),
              )

            ],
          ),
        );

      },
    );

  }

}