import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:sekai_atlas/features/Friends.dart';
import 'package:sekai_atlas/features/UserPopup.dart';

class GroupePage extends StatelessWidget {
  
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
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
         child:  Padding(padding: EdgeInsetsDirectional.fromSTEB(20, 20, 20, 20), 
          child: Column(
            children: [
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadiusGeometry.circular(50),
                    child:  Image.network('https://picsum.photos/seed/643/600', width: 80, height: 80),
                  ),
                  Padding(padding: EdgeInsetsDirectional.fromSTEB(20, 0, 0, 0), child: 
                    Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Hello world", style: TextStyle(fontSize: 18),),
                        Text("Hello world")
                      ],
                    ), 
                  ),
                  Spacer(),
                  IconButton(onPressed: () => { FriendsPopUp.show(context) }, 
                    icon: Icon(Icons.add_reaction), 
                    style: ButtonStyle(
                      backgroundColor: WidgetStateProperty.resolveWith<Color?>(
                        (states) => Colors.blue, // couleur fixe pour tous les états
                      ),
                      foregroundColor: WidgetStateProperty.resolveWith<Color?>(
                        (states) => Colors.white, // couleur de l'icône
                      ),
                      shape: WidgetStateProperty.resolveWith<OutlinedBorder?>(
                        (states) => RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12), // rayon des coins
                        ),
                      ),
                    ),  
                  )
                ],
              ), 
              Divider(),
              Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(padding: EdgeInsetsDirectional.fromSTEB(0, 20, 0, 0)),
                  Text("Aventure en cours", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Padding(padding: EdgeInsetsDirectional.fromSTEB(0, 10, 0, 0)),
                  ClipRRect(
                    borderRadius: BorderRadiusGeometry.circular(20),
                    child: Container(
                      height: 300,
                      color: Colors.amber,
                    ),
                  )
                ]
              ), 
              Padding(
                padding: EdgeInsetsDirectional.fromSTEB(0, 20, 0, 0),
                child: Column( 
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Listes des aventures", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Padding(
                      padding: EdgeInsetsDirectional.fromSTEB(0, 10, 0, 0), 
                      child: SizedBox(
                        height: 100,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: 5,

                          itemBuilder: (context, index) {

                            return InkWell(
                              onTap: () {
                                 print("je te baise $index fois");
                                // ici tu pourras afficher le profil
                              },
                              child: Container(
                                width: 100,
                                color: Colors.blue,
                                child: Center(child: Text("Item $index")),
                              ),
                            );
                          },

                          separatorBuilder: (context, index) {
                            return SizedBox(width: 10); // espace entre chaque élément
                          },
                        ),
                      ),
                    )
                    
                  ] 
                )
              ),
              Padding(
                padding: EdgeInsetsDirectional.fromSTEB(0, 20, 0, 0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Aventuriers de la guilde", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),),
                    Padding(
                      padding: EdgeInsetsDirectional.fromSTEB(0, 10, 0, 0), 
                      child: SizedBox(
                        height: 80,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: users.length,

                          itemBuilder: (context, index) {
                            final user = users[index];
                            return InkWell(
                              onTap: () {
                                
                              
                                UserPopup.show(context, user);

                                // ici tu pourras afficher le profil
                              },

                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(50),
                                child: Image.network(user["image"])
                              ),
                            );
                          },

                          separatorBuilder: (context, index) {
                            return SizedBox(width: 10);
                          },
                        ),
                      ),
                    )
                  ],
                ),
              )
            ],
          )
        )
        ) 
      )
    );
  }
}