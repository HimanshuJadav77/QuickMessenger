import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:QuickMessenger/HomeScreens/Profile/seachuserprofile.dart';
import 'package:QuickMessenger/networkcheck.dart';
import '../Ui/customcard.dart';

class SearchUser extends StatefulWidget {
  const SearchUser({super.key});

  @override
  State<SearchUser> createState() => _SearchUserState();
}

class _SearchUserState extends State<SearchUser> {
  final searchC = TextEditingController();
  bool blocked = false;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    NetworkCheck().initializeInternetStatus(context);
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    NetworkCheck().cancelSubscription();
  }

  final CollectionReference usersList = FirebaseFirestore.instance.collection("Users");

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: Icon(Icons.arrow_back_ios)),
        title: const Text(
          'Search Users',
          style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          // Search TextField
          Padding(
            padding: const EdgeInsets.only(top: 30, left: 10, right: 10, bottom: 5),
            child: TextField(
              controller: searchC, // Bind TextField to the controller
              onChanged: (value) {
                setState(() {}); // Rebuild when search query changes
              },
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.person_search_outlined),
                labelText: "Search",
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(100),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
            ),
          ),
          const Divider(),

          Expanded(
            child: StreamBuilder(
              stream: usersList.snapshots(), // Get all users
              builder: (context, AsyncSnapshot<QuerySnapshot> streamSnapshot) {
                if (streamSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator()); // Loading state
                }

                if (streamSnapshot.hasError) {
                  return Center(child: Text('Error: ${streamSnapshot.error}'));
                }

                if (streamSnapshot.hasData) {
                  final List<DocumentSnapshot> users = streamSnapshot.data!.docs;
                  final currentUserId = FirebaseAuth.instance.currentUser!.uid;

                  if (searchC.text.isEmpty) {
                    return const Center(child: Text("Please type to search."));
                  }

                  final filteredUsers = users.where((user) {
                    final username = user["username"].toString().toLowerCase().replaceAll(RegExp(r'\s+'), '');
                    final searchQuery = searchC.text.toLowerCase();

                    return username.contains(searchQuery) && user["userid"] != currentUserId;
                  }).toList();

                  if (filteredUsers.isEmpty) {
                    return const Center(child: Text("No users found"));
                  }

                  return ListView.builder(
                    itemCount: filteredUsers.length,
                    itemBuilder: (context, index) {
                      final DocumentSnapshot userData = filteredUsers[index];

                      final inkwell = GlobalKey();

                      return StreamBuilder(
                          stream: FirebaseFirestore.instance
                              .collection("block")
                              .doc(userData["userid"])
                              .collection("blockedid")
                              .doc(currentUserId)
                              .snapshots(),
                          builder: (context, bsnapshot) {
                            if (bsnapshot.connectionState == ConnectionState.waiting) {
                              return Center();
                            }
                            if (!bsnapshot.hasData || bsnapshot.data?.data()?["blocked"] == true) {
                              return Center();
                            }
                            if (bsnapshot.data!.data() == null || bsnapshot.data!.data()!["blocked"] == false) {
                              return InkWell(
                                key: inkwell,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    PageRouteBuilder(
                                      pageBuilder: (context, animation, secondaryAnimation) => SearchUserProfile(
                                        username: userData["username"],
                                        email: userData["email"],
                                        about: userData["about"],
                                        imageurl: userData["userimageurl"],
                                        userid: userData["userid"],
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
                                },
                                child: CustomCard(
                                  subtitle: null,
                                  username: userData["username"],
                                  imageurl: userData["userimageurl"],
                                  color: Colors.white,
                                  trailing: Text(""),
                                ),
                              );
                            }
                            return Center();
                          });
                    },
                  );
                }

                return const Center(child: Text("No Users Found"));
              },
            ),
          )
        ],
      ),
    );
  }
}
