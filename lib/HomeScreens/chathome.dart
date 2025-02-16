// ignore_for_file: use_build_context_synchronously
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:QuickMessenger/HomeScreens/chatscreen.dart';
import 'package:QuickMessenger/Logins/showdialogs.dart';
import 'package:QuickMessenger/Ui/customcard.dart';

import 'home.dart';

class ChatHome extends StatefulWidget {
  const ChatHome({super.key});

  @override
  State<ChatHome> createState() => _ChatHomeState();
}

class _ChatHomeState extends State<ChatHome> {
  List<bool> selectedStates = [];
  int indexSelected = 0;
  List<dynamic> selectedUserList = [];
  var messageCount = [];
  final firestore = FirebaseFirestore.instance.collection("Users");

  final usersList = FirebaseFirestore.instance.collection("Users").doc(currentUserId).collection("chats");

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  deleteChat(selectedUserList) async {
    showMessageBox(
      "Deletion",
      "Are you want to delete this chats? It also delete the conversation.",
      context,
      "Delete",
      () async {
        for (var userid in selectedUserList) {
          usersList.doc(userid).delete();
          final docs =
              await firestore.doc(currentUserId).collection("save_chat").doc(userid).collection("messages").get();
          for (var msg in docs.docs) {
            msg.reference.delete();
          }
        }
        selectedUserList.clear();
        selectedStates.clear();
        Navigator.pop(context);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
        stream: usersList.orderBy("time", descending: true).snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> streamSnapshot) {
          if (!streamSnapshot.hasData || streamSnapshot.data!.docs.isEmpty) {
            return Center(
              child: Text("No Users Available For Chat."),
            );
          }

          if (streamSnapshot.hasData) {
            final List<DocumentSnapshot> users = streamSnapshot.data!.docs.toList();
            if (selectedStates.length != users.length) {
              selectedStates = List.generate(
                users.length,
                (index) => false,
              );
            }
            int getSelectedStatesCount() {
              return selectedStates
                  .where(
                    (isSelected) => isSelected,
                  )
                  .length;
            }

            return Scaffold(
              body: Column(
                children: [
                  AnimatedContainer(
                    curve: Curves.linear,
                    height: selectedStates.contains(true) ? 50 : 0,
                    duration: Duration(milliseconds: 200),
                    child: AppBar(
                      leading: IconButton(
                          tooltip: "Cancel",
                          onPressed: () {
                            setState(() {
                              selectedStates = List.generate(
                                users.length,
                                (index) {
                                  return false;
                                },
                              );
                            });
                          },
                          icon: Icon(
                            Icons.cancel,
                            color: Colors.blue,
                          )),
                      title: Text(
                        "${getSelectedStatesCount()} selected",
                        style: TextStyle(fontSize: 20),
                      ),
                      actions: [
                        IconButton(
                            tooltip: "Delete Selected Chats",
                            onPressed: () => deleteChat(selectedUserList),
                            icon: Icon(
                              Icons.remove_circle,
                              color: Colors.red,
                              size: 25,
                            ))
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: users.length,
                      itemBuilder: (context, index) {
                        final DocumentSnapshot user = users[index];
                        messageCount = List.generate(
                          users.length,
                          (index) {
                            return 0;
                          },
                        );
                        if (selectedStates[index] == true) {
                          if (!selectedUserList.contains(user.id)) {
                            selectedUserList.add(user.id);
                          }
                        } else if (selectedStates[index] == false) {
                          if (selectedUserList.contains(user.id)) {
                            selectedUserList.remove(user.id);
                          }
                        }

                        return StreamBuilder(
                            stream: FirebaseFirestore.instance.collection("Users").doc(user.id).snapshots(),
                            builder: (context, snapshot) {
                              if (snapshot.hasData && snapshot.data != null) {
                                final userData = snapshot.data!;
                                return Column(
                                  children: [
                                    InkWell(
                                        onLongPress: () {
                                          setState(() {
                                            selectedStates[index] = !selectedStates[index];
                                          });
                                        },
                                        onTap: () {
                                          if (!selectedStates[index] && !selectedStates.contains(true)) {
                                            Navigator.pushReplacement(
                                              context,
                                              PageRouteBuilder(
                                                pageBuilder: (context, animation, secondaryAnimation) => ChatScreen(
                                                  imageurl: userData["userimageurl"],
                                                  username: userData["username"],
                                                  userid: userData["userid"],
                                                  about: userData["about"],
                                                  email: userData["email"],
                                                ),
                                                // The page to navigate to
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
                                          } else {
                                            setState(() {
                                              selectedStates[index] = !selectedStates[index];
                                            });
                                          }
                                        },
                                        child: Stack(
                                          children: [
                                            StreamBuilder(
                                                stream: FirebaseFirestore.instance
                                                    .collection("Users")
                                                    .doc(userData["userid"])
                                                    .collection("save_chat")
                                                    .doc(currentUserId)
                                                    .collection("messages")
                                                    .orderBy("time")
                                                    .snapshots(),
                                                builder: (context, snapshot) {
                                                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                                                    return Center();
                                                  }
                                                  if (snapshot.connectionState == ConnectionState.waiting) {
                                                    return Center();
                                                  }

                                                  final data = snapshot.data!.docs.toList();

                                                  messageCount[index] = data.where(
                                                    (message) {
                                                      return message["sender"] == userData["userid"] &&
                                                          message["messagestate"] == "send";
                                                    },
                                                  ).length;

                                                  return SizedBox();
                                                }),
                                            CustomCard(
                                              subtitle: StreamBuilder(
                                                  stream: FirebaseFirestore.instance
                                                      .collection("Users")
                                                      .doc(currentUserId)
                                                      .collection("save_chat")
                                                      .doc(userData["userid"])
                                                      .collection("messages")
                                                      .orderBy("time")
                                                      .snapshots(),
                                                  builder: (context, snapshot) {
                                                    if (snapshot.connectionState == ConnectionState.waiting) {
                                                      return Center();
                                                    }
                                                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                                                      return Center();
                                                    }

                                                    if (snapshot.hasData) {
                                                      final data = snapshot.data!.docs.toList();
                                                      final message = data.last.data()["message"];
                                                      var senderId = data.last.data()["sender"];

                                                      if (messageCount[index] == 0) {
                                                        if (message == currentUserId || message == userData["userid"]) {
                                                          final filename = data.last.id + data.last.data()["extension"];
                                                          return Text(filename);
                                                        } else if (senderId == currentUserId ||
                                                            senderId == userData["userid"]) {
                                                          return Text(message);
                                                        }
                                                      } else if (messageCount[index] == 1) {
                                                        return Text("1 new message");
                                                      } else if (messageCount[index] > 1) {
                                                        return Text("${messageCount[index]} new messages");
                                                      }
                                                    }

                                                    return Center();
                                                  }),
                                              trailing: Text(""),
                                              username: userData["username"],
                                              imageurl: userData["userimageurl"],
                                              color: selectedStates[index] ? Colors.blue.shade50 : Colors.white,
                                            ),
                                            Positioned(
                                              left: 70,
                                              bottom: 20,
                                              child: StreamBuilder(
                                                  stream: firestore.doc(userData["userid"]).snapshots(),
                                                  builder: (context, snapshot) {
                                                    if (!snapshot.hasData) {}
                                                    if (snapshot.connectionState == ConnectionState.waiting) {}
                                                    final snap = snapshot.data?.data();
                                                    final isOnline = snap?["online"].toString();

                                                    return SizedBox(
                                                      height: 13,
                                                      width: 13,
                                                      child: CircleAvatar(
                                                        backgroundColor: isOnline == "true"
                                                            ? Colors.greenAccent.shade400
                                                            : Colors.transparent,
                                                      ),
                                                    );
                                                  }),
                                            ),
                                            selectedStates[index]
                                                ? Positioned(
                                                    left: 65,
                                                    bottom: 15,
                                                    child: CircleAvatar(
                                                      radius: 12,
                                                      backgroundColor: Colors.black,
                                                      child: Icon(
                                                        Icons.check_circle_sharp,
                                                        color: Colors.blueAccent,
                                                      ),
                                                    ),
                                                  )
                                                : SizedBox.shrink(),
                                          ],
                                        )),
                                  ],
                                );
                              }
                              return SizedBox.shrink();
                            });
                      },
                    ),
                  ),
                ],
              ),
            );
          }
          return Center();
        });
  }
}
