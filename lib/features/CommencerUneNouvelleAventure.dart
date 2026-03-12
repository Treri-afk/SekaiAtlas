import 'package:flutter/material.dart';

class CommencerUneNouvelleAventureForm {
  static void show(BuildContext context, {required List? users}) {
    final _formKey = GlobalKey<FormState>();
    
    // ⚡ Déclare selected ici pour qu'il persiste entre les rebuilds
    List<bool> selected = List<bool>.filled(users!.length, false);

    showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(20),
          height: MediaQuery.of(context).size.height - 100,
          width: MediaQuery.widthOf(context) - 30,
          child: StatefulBuilder(
            builder: (context, setState) {
              void toggleSelected(int index) {
                setState(() {
                  selected[index] = !selected[index];
                });
              }

              return SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Spacer(),
                          ElevatedButton(
                            onPressed: () {
                              // logique de création ici
                              Navigator.pop(context);
                            },
                            child: Text("Valider"),
                          )
                        ],
                      ),
                      Text("Nom"),
                      TextFormField(
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.grey[200],
                          hintText: 'Entrez du texte',
                          hintStyle: TextStyle(color: Colors.grey[600]),
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      SizedBox(height: 20),
                      Text("Description"),
                      TextFormField(
                        maxLines: 5,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.grey[200],
                          hintText: 'Entrez du texte',
                          hintStyle: TextStyle(color: Colors.grey[600]),
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          
                        ),
                      ),
                      SizedBox(height: 20),
                      Text("Participants"),
                      SizedBox(height: 10),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          childAspectRatio: 1,
                        ),
                        itemCount: users.length,
                        itemBuilder: (context, index) {
                          final user = users[index];
                          return Stack(
                            clipBehavior: Clip.none,
                            children: [
                              GestureDetector(
                                onTap: () => toggleSelected(index),
                                child: CircleAvatar(
                                  radius: 50,
                                  backgroundImage: NetworkImage(user['avatar_url']!),
                                ),
                              ),
                              Positioned(
                                bottom: -5,
                                left: -5,
                                child: GestureDetector(
                                  onTap: () => toggleSelected(index),
                                  child: CircleAvatar(
                                    radius: 18,
                                    backgroundColor:
                                        selected[index] ? Colors.green : Colors.grey[300],
                                    child: Icon(
                                      selected[index] ? Icons.check : Icons.add,
                                      color: selected[index] ? Colors.white : Colors.grey[700],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}