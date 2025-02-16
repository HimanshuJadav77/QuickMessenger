import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:QuickMessenger/Logins/showdialogs.dart';
import 'package:QuickMessenger/Ui/elvb.dart';

import '../home.dart';

class Blockeduserlist extends StatefulWidget {
  const Blockeduserlist({super.key});

  @override
  State<Blockeduserlist> createState() => _BlockeduserlistState();
}

class _BlockeduserlistState extends State<Blockeduserlist> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: Icon(Icons.arrow_back_ios_new),
        ),
        title: Text('Blocked Users', style: TextStyle(color: Colors.blue, fontSize: 22, fontWeight: FontWeight.bold)),
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection("block")
            .doc(currentUserId)
            .collection("blockedid")
            .where("blocked", isEqualTo: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(),
            );
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text("No Blocked Users"),
            );
          }

          final blockUserList = snapshot.data?.docs.toList();

          return ListView.builder(
            itemCount: blockUserList!.length,
            itemBuilder: (context, index) {
              return StreamBuilder(
                stream: FirebaseFirestore.instance.collection("Users").doc(blockUserList[index].id).snapshots(),
                builder: (context, uSnapshot) {
                  if (!uSnapshot.hasData && blockUserList.isEmpty) {
                    return Center();
                  }
                  if (uSnapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: CircularProgressIndicator(),
                    );
                  }
                  if (uSnapshot.hasData) {
                    final userData = uSnapshot.data!;
                    return ListTile(
                      leading: ClipOval(
                        child: CircleAvatar(
                          backgroundImage: NetworkImage(userData["userimageurl"]),
                        ),
                      ),
                      title: Text(
                        userData["username"],
                        style: TextStyle(color: Colors.black),
                      ),
                      trailing: SizedBox(
                        width: 115,
                        child: Elvb(
                            onpressed: () {
                              showMessageBox(
                                  "Unblock", "Are you want to unblock ${userData["username"]}?", context, "Unblock",
                                  () async {
                                Navigator.pop(context);
                                await FirebaseFirestore.instance
                                    .collection("block")
                                    .doc(currentUserId)
                                    .collection("blockedid")
                                    .doc(userData["userid"])
                                    .set({"blocked": false});
                              });
                            },
                            name: "Unblock",
                            textsize: 12.0,
                            foregroundcolor: Colors.white,
                            backgroundcolor: Colors.blue),
                      ),
                    );
                  }
                  return Center();
                },
              );
            },
          );
        },
      ),
    );
  }
}
