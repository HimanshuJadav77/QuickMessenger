// ignore_for_file: prefer_typing_uninitialized_variables

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:QuickMessenger/HomeScreens/Profile/myprofile.dart';
import 'package:QuickMessenger/HomeScreens/Profile/seachuserprofile.dart';

class FollowFollowingPage extends StatefulWidget {
  const FollowFollowingPage({super.key, required this.userid});

  final userid;

  @override
  State<FollowFollowingPage> createState() => _FollowFollowingPageState();
}

class _FollowFollowingPageState extends State<FollowFollowingPage> {
  @override
  void initState() {
    super.initState();
  }

  final _firestore = FirebaseFirestore.instance;
  final currentUserId = FirebaseAuth.instance.currentUser!.uid;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      animationDuration: Duration(milliseconds: 300),
      initialIndex: 0,
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
              onPressed: () {
                Navigator.pop(context);
              },
              icon: Icon(Icons.arrow_back_ios)),
          bottom: TabBar(labelColor: Colors.blue, unselectedLabelColor: Colors.black, tabs: [
            Tab(
              child: Text(
                "Follower",
                style: TextStyle(fontSize: 18),
              ),
            ),
            Tab(
              child: Text(
                "Following",
                style: TextStyle(fontSize: 18),
              ),
            ),
          ]),
        ),
        body: TabBarView(children: [
          StreamBuilder(
            stream: _firestore
                .collection("Users")
                .doc(widget.userid)
                .collection("followers")
                .where("follower", isEqualTo: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(
                  child: Text("No Followers"),
                );
              }
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: CircularProgressIndicator(),
                );
              }

              final followerIds = snapshot.data!.docs;
              return ListView.builder(
                itemCount: followerIds.length,
                itemBuilder: (context, index) {
                  final followerId = followerIds[index].id;
                  return FutureBuilder(
                    future: _firestore.collection("Users").doc(followerId).get(),
                    builder: (context, userSnapshot) {
                      if (userSnapshot.connectionState == ConnectionState.waiting) {
                        return Center(
                          child: CircularProgressIndicator(),
                        );
                      }
                      if (!userSnapshot.hasData) {
                        return Center();
                      }
                      final followerData = userSnapshot.data!;
                      final username = followerData["username"];
                      final email = followerData["email"];
                      final imageurl = followerData["userimageurl"];
                      final about = followerData["about"];
                      return Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: ListTile(
                          onTap: () {
                            if (followerId == currentUserId) {
                              Navigator.push(
                                context,
                                PageRouteBuilder(
                                  pageBuilder: (context, animation, secondaryAnimation) => MyProfile(),
                                  transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                    const begin = Offset(0.1, 0.0);
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
                              Navigator.push(
                                context,
                                PageRouteBuilder(
                                  pageBuilder: (context, animation, secondaryAnimation) => SearchUserProfile(
                                      username: username,
                                      email: email,
                                      about: about,
                                      imageurl: imageurl,
                                      userid: followerId),
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
                            }
                          },
                          title: Text(
                            followerId == currentUserId ? "$username(you)" : username,
                          ),
                          leading: CircleAvatar(
                              radius: 30,
                              child: ClipOval(
                                child: Image.network(
                                  height: MediaQuery.of(context).size.height,
                                  width: 56,
                                  fit: BoxFit.cover,
                                  imageurl,
                                  filterQuality: FilterQuality.high,
                                ),
                              )),
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
          StreamBuilder(
            stream: _firestore
                .collection("Users")
                .doc(widget.userid)
                .collection("following")
                .where("following", isEqualTo: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(
                  child: Text("No Following Users"),
                );
              }
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: CircularProgressIndicator(),
                );
              }

              final followingIds = snapshot.data!.docs;
              return ListView.builder(
                itemCount: followingIds.length,
                itemBuilder: (context, index) {
                  final followingId = followingIds[index].id;
                  return FutureBuilder(
                    future: _firestore.collection("Users").doc(followingId).get(),
                    builder: (context, userSnapshot) {
                      if (userSnapshot.connectionState == ConnectionState.waiting) {
                        return Center(
                          child: CircularProgressIndicator(),
                        );
                      }
                      if (!userSnapshot.hasData) {
                        return Center();
                      }
                      final followingData = userSnapshot.data!;
                      final username = followingData["username"];
                      final email = followingData["email"];
                      final imageurl = followingData["userimageurl"];
                      final about = followingData["about"];
                      return Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: ListTile(
                          onTap: () {
                            if (followingId == currentUserId) {
                              Navigator.push(
                                context,
                                PageRouteBuilder(
                                  pageBuilder: (context, animation, secondaryAnimation) => MyProfile(),
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
                              Navigator.push(
                                context,
                                PageRouteBuilder(
                                  pageBuilder: (context, animation, secondaryAnimation) => SearchUserProfile(
                                      username: username,
                                      email: email,
                                      about: about,
                                      imageurl: imageurl,
                                      userid: followingId),
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
                            }
                          },
                          title: Text(
                            followingId == currentUserId ? "$username(you)" : username,
                          ),
                          leading: CircleAvatar(
                              radius: 30,
                              child: ClipOval(
                                child: Image.network(
                                  height: MediaQuery.of(context).size.height,
                                  width: 56,
                                  fit: BoxFit.cover,
                                  imageurl,
                                  filterQuality: FilterQuality.high,
                                ),
                              )),
                        ),
                      );
                    },
                  );
                },
              );
            },
          )
        ]),
      ),
    );
  }
}
