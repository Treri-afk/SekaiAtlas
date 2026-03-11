import 'package:flutter/material.dart';
import 'package:sekai_atlas/features/CommencerUneNouvelleAventure.dart';

class AventureEnCours extends StatelessWidget {
  final bool EnCours;
  final List? Users;

   const AventureEnCours({
    Key? key,
    required this.EnCours,
    this.Users,
  }) : assert(
         !EnCours || Users != null, // Si EnCours == true, Users doit être non null
         'Users doit être fourni si EnCours est true',
       ),
       super(key: key);
  
  @override
  Widget build(BuildContext context) {
    if(EnCours == false){
      return InkWell(
      onTap: () {
        CommencerUneNouvelleAventureForm.show(context, users: Users);
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
              mainAxisAlignment: MainAxisAlignment.center, // centre verticalement
              crossAxisAlignment: CrossAxisAlignment.center, // centre horizontalement
              children: [
                // Le rond + icône
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(Icons.add, color: Colors.grey, size: 30),
                  ),
                ),
                
                SizedBox(height: 10), // espace entre le rond et le texte

                // Le texte
                Text(
                  "Commencer une aventure",
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
         
          SizedBox(height: 8),
         
        ],
      ),
    );
    }
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadiusGeometry.circular(20),
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
            width: (Users!.length * 20) + 20,
            child: Stack(
              children: [
                ...List<Widget>.generate(Users!.length, (index){
                  final user = Users![index];
                  return Positioned(
                    left: index * 20,
                    child: CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.white,
                      child: CircleAvatar(
                        radius: 18,
                        backgroundImage: NetworkImage(user["image"]!),
                      ),
                    )
                  );
                })
              ],
            ),
          )
        )
      ],
    );
  }

}
