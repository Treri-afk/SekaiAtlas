import 'package:flutter/material.dart';
import 'package:sekai_atlas/features/CopyField.dart';
import 'package:sekai_atlas/features/FriendCodeField.dart';
import 'package:sekai_atlas/functions/api_call.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FriendsPopUp {

  static void show(BuildContext rootContext) async {

    // Récupère le friend_code de l'utilisateur connecté
    final providerId = Supabase.instance.client.auth.currentUser?.id;
    if (providerId == null) return;

    final connectedUser = await fetchUserByProviderId(providerId);
    final friendCode = connectedUser["friend_code"] ?? 'Aucun code ami';

    showModalBottomSheet(
      isScrollControlled: true,
      context: rootContext,
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(20),
          height: MediaQuery.of(context).size.height - 500,
          width: MediaQuery.of(context).size.width - 50,
          child: Column(
            children: [
              Padding(
                padding: EdgeInsetsDirectional.fromSTEB(0, 20, 0, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsetsDirectional.fromSTEB(0, 0, 0, 10),
                      child: Text(
                        "Mon code ami",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    CopyField(text: friendCode), // ← vrai friend_code
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsetsDirectional.fromSTEB(0, 20, 0, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsetsDirectional.fromSTEB(0, 0, 0, 10),
                      child: Text(
                        "Ajouter un ami",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    FriendCodeField()
                  ],
                ),
              )
            ],
          ),
        );
      },
    );
  }
}