import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sekai_atlas/features/CopyField.dart';
import 'package:sekai_atlas/features/FriendCodeField.dart';

class FriendsPopUp {

  static void show(BuildContext rootContext) {

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

                    CopyField(text: "ABC-123-XYZ"),

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
                        "Mon code ami",
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