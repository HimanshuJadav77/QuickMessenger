// ignore_for_file: use_build_context_synchronously

import 'package:QuickMessenger/HomeScreens/Profile/seachuserprofile.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:QuickMessenger/Logins/showdialogs.dart';
import 'package:QuickMessenger/Ui/elvb.dart';

import 'home.dart';

class Updates extends StatefulWidget {
  const Updates({super.key,});


  @override
  State<Updates> createState() => _UpdatesState();
}

class _UpdatesState extends State<Updates> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(
            flex: -1,
            child: StreamBuilder(
                stream: FirebaseFirestore.instance
                    .collection("Users")
                    .doc(currentUserId)
                    .collection("followers")
                    .where("follower", isEqualTo: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return Center();
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center();
                  }

                  final followerList = snapshot.data!.docs.toList();
                  return ListView.builder(
                    shrinkWrap: true,
                    itemCount: followerList.length,
                    itemBuilder: (context, index) {
                      return StreamBuilder(
                        stream: FirebaseFirestore.instance.collection("Users").doc(followerList[index].id).snapshots(),
                        builder: (context, uSnapshot) {
                          if (!uSnapshot.hasData) {
                            return Center();
                          }
                          if (uSnapshot.connectionState == ConnectionState.waiting) {
                            return Center();
                          }
                          final userData = uSnapshot.data;
                          return InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                PageRouteBuilder(
                                  pageBuilder: (context, animation, secondaryAnimation) => SearchUserProfile(
                                      username: userData?["username"],
                                      email: userData?["email"],
                                      about: userData?["about"],
                                      imageurl: userData?["userimageurl"],
                                      userid: userData?["userid"]),
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
                            },
                            child: ListTile(
                                leading: ClipOval(
                                  child: CircleAvatar(
                                    backgroundImage: NetworkImage(userData?["userimageurl"]),
                                  ),
                                ),
                                title: Text(
                                  "${userData?["username"]}",
                                  style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                                ),
                                subtitle: Text(
                                  "is started follow you.",
                                  style: TextStyle(
                                    color: Colors.black,
                                  ),
                                )),
                          );
                        },
                      );
                    },
                  );
                }),
          ),
          Expanded(
            child: StreamBuilder(
              stream: FirebaseFirestore.instance
                  .collection("Users")
                  .doc(currentUserId)
                  .collection("requests")
                  .where("request", isEqualTo: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData) {
                  return Center();
                }

                final updatesList = snapshot.data!.docs.toList();
                if (updatesList.isNotEmpty) {
                  return ListView.builder(
                    shrinkWrap: true,
                    itemCount: updatesList.length,
                    itemBuilder: (context, index) {
                      final update = updatesList[index];

                      return StreamBuilder(
                          stream: FirebaseFirestore.instance.collection("Users").doc(update.id).snapshots(),
                          builder: (context, uSnapshot) {
                            if (uSnapshot.connectionState == ConnectionState.waiting) {
                              return Center(
                                child: CircularProgressIndicator(),
                              );
                            }
                            if (!uSnapshot.hasData && uSnapshot.data!.data()!.isEmpty) {}
                            final userData = uSnapshot.data!.data();

                            return ListTile(
                                leading: ClipOval(
                                  child: CircleAvatar(
                                    backgroundImage: NetworkImage(userData?["userimageurl"]),
                                  ),
                                ),
                                title: Text(
                                  "${userData?["username"]}",
                                  style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                                ),
                                subtitle: Text(
                                  "is requested for follow you.",
                                  style: TextStyle(
                                    color: Colors.black,
                                  ),
                                ),
                                trailing: SizedBox(
                                  height: 50,
                                  width: 109,
                                  child: StreamBuilder(
                                      stream: FirebaseFirestore.instance
                                          .collection("Users")
                                          .doc(currentUserId)
                                          .collection("followers")
                                          .doc(update.id)
                                          .snapshots(),
                                      builder: (context, fSnapshot) {
                                        if (fSnapshot.connectionState == ConnectionState.waiting) {
                                          return Center(child: CircularProgressIndicator());
                                        }
                                        if (!fSnapshot.data!.exists || fSnapshot.data!.exists) {
                                          return fSnapshot.data!.exists && fSnapshot.data?["follower"] == true
                                              ? Center(
                                                  child: Text(
                                                    "Accepted",
                                                    style: TextStyle(fontSize: 15, color: Colors.blue),
                                                  ),
                                                )
                                              : Elvb(
                                                  onpressed: () {
                                                    if (!fSnapshot.data!.exists ||
                                                        fSnapshot.data!.exists &&
                                                            fSnapshot.data?["follower"] == false) {
                                                      showMessageBox(
                                                          "User Request",
                                                          "Are you sure want to accept ${userData?["username"]}'s request? ",
                                                          context,
                                                          "Confirm", () async {
                                                        await FirebaseFirestore.instance
                                                            .collection("Users")
                                                            .doc(currentUserId)
                                                            .collection("followers")
                                                            .doc(update.id)
                                                            .set({"follower": true});

                                                        await FirebaseFirestore.instance
                                                            .collection("Users")
                                                            .doc(update.id)
                                                            .collection("following")
                                                            .doc(currentUserId)
                                                            .set({"following": true});
                                                        Navigator.pop(context);
                                                      });
                                                    } else if (fSnapshot.data!.exists &&
                                                        fSnapshot.data?["follower"] == true) {}
                                                  },
                                                  name: "Accept",
                                                  foregroundcolor: Colors.white,
                                                  backgroundcolor: Colors.blue);
                                        }
                                        return Center();
                                      }),
                                ));
                          });
                    },
                  );
                } else {
                  return Center(
                    child: Text("No any other updates available"),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
