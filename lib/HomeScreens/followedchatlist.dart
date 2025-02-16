import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:QuickMessenger/HomeScreens/chatscreen.dart';
import 'package:QuickMessenger/HomeScreens/searchuser.dart';
import 'package:QuickMessenger/Ui/customcard.dart';
import 'package:QuickMessenger/Ui/elvb.dart';

import 'home.dart';

class FollowedChatList extends StatefulWidget {
  const FollowedChatList({super.key});

  @override
  State<FollowedChatList> createState() => _FollowedChatListState();
}

class _FollowedChatListState extends State<FollowedChatList> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "New Chat",
          style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: Icon(Icons.arrow_back_ios)),
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection("Users")
            .doc(currentUserId)
            .collection("following")
            .where("following", isEqualTo: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(),
            );
          }

          final usersList = snapshot.data!.docs.toList();
          if (!snapshot.hasData || usersList.isEmpty) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Center(
                  child: Text("No user for chatting follow first"),
                ),
                Elvb(
                    onpressed: () {
                      Navigator.push(
                        context,
                        PageRouteBuilder(
                          pageBuilder: (context, animation, secondaryAnimation) => SearchUser(),
                          transitionsBuilder: (context, animation, secondaryAnimation, child) {
                            const begin = Offset(2.0, 1.0);
                            const end = Offset.zero;
                            var tween = Tween(begin: begin, end: end);
                            final offsetAnimation = animation.drive(tween);
                            return SlideTransition(
                              position: offsetAnimation,
                              child: child,
                            );
                          },
                        ),
                      );
                    },
                    name: "Search Users",
                    foregroundcolor: Colors.white,
                    backgroundcolor: Colors.blue)
              ],
            );
          }
          return ListView.builder(
            itemCount: usersList.length,
            itemBuilder: (context, index) {
              return FutureBuilder(
                  future: FirebaseFirestore.instance.collection("Users").doc(usersList[index].id).get(),
                  builder: (context, userSnapshot) {
                    if (userSnapshot.connectionState == ConnectionState.waiting) {
                      return Center(
                        child: CircularProgressIndicator(),
                      );
                    }
                    final userData = userSnapshot.data!;
                    return InkWell(
                      onTap: () async {
                        await FirebaseFirestore.instance
                            .collection("Users")
                            .doc(currentUserId)
                            .collection("chats")
                            .doc(userData["userid"])
                            .set({"chat": true, "time": FieldValue.serverTimestamp()});
                        Navigator.push(
                          // ignore: use_build_context_synchronously
                          context,
                          PageRouteBuilder(
                            pageBuilder: (context, animation, secondaryAnimation) => ChatScreen(
                              imageurl: userData["userimageurl"],
                              username: userData["username"],
                              userid: usersList[index].id,
                              about: userData["about"],
                              email: userData["email"],
                            ),
                            transitionsBuilder: (context, animation, secondaryAnimation, child) {
                              const begin = Offset(2.0, 1.0);
                              const end = Offset.zero;
                              var tween = Tween(begin: begin, end: end);
                              final offsetAnimation = animation.drive(tween);
                              return SlideTransition(
                                position: offsetAnimation,
                                child: child,
                              );
                            },
                          ),
                        );
                      },
                      child: CustomCard(
                        subtitle: null,
                        color: Colors.white,
                        username: userData["username"],
                        imageurl: userData["userimageurl"],
                        trailing: Text(""),
                      ),
                    );
                  });
            },
          );
        },
      ),
    );
  }
}
