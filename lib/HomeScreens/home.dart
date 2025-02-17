import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:QuickMessenger/HomeScreens/Profile/myprofile.dart';
import 'package:QuickMessenger/HomeScreens/Profile/settings.dart';
import 'package:QuickMessenger/HomeScreens/chathome.dart';
import 'package:QuickMessenger/HomeScreens/followedchatlist.dart';
import 'package:QuickMessenger/HomeScreens/searchuser.dart';
import 'package:QuickMessenger/HomeScreens/updates.dart';
import 'package:QuickMessenger/Logins/logreg.dart';

import '../Logins/showdialogs.dart';
import '../networkcheck.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

String currentUserId = "";

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  bool index = false;
  GlobalKey<ScaffoldState> drawerController = GlobalKey<ScaffoldState>();
  final _firestore = FirebaseFirestore.instance;
  bool disabled = false;

  @override
  void initState() {
    super.initState();
    setState(() {
      currentUserId = FirebaseAuth.instance.currentUser!.uid;
    });
    requestPermissions();
    onlineState();
    getUserEmailVerifiedOrNot();
    NetworkCheck().initializeInternetStatus(context);
    WidgetsBinding.instance.addObserver(this);
  }

  getUserEmailVerifiedOrNot() {
    bool verified = FirebaseAuth.instance.currentUser!.emailVerified;
    if (verified == true) {
    } else if (verified == false) {
      Navigator.pushAndRemoveUntil(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => LogReg(),
          // The page to navigate to
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(.0, 1.0);
            const end = Offset.zero;
            var tween = Tween(begin: begin, end: end);
            final offsetAnimation = animation.drive(tween);
            return SlideTransition(
              position: offsetAnimation,
              child: child,
            );
          },
        ),
        (Route<dynamic> route) => false, // This removes all previous routes
      );
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      FirebaseFirestore.instance.collection("Users").doc(currentUserId).update({"online": false});
    } else if (state == AppLifecycleState.resumed) {
      onlineState();
    }
  }

  @override
  void dispose() {
    super.dispose();
    NetworkCheck().cancelSubscription();
    WidgetsBinding.instance.removeObserver(this);
  }

  onlineState() {
    FirebaseFirestore.instance.collection("Users").doc(currentUserId).update({"online": true});
  }

  requestPermissions() async {
    await Permission.camera.request();
    await Permission.storage.request();

    if (await Permission.camera.isDenied || await Permission.storage.isDenied) {
      await Permission.camera.isGranted;
      await Permission.storage.isGranted;
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      initialIndex: 0,
      length: 2,
      child: Stack(
        children: [
          StreamBuilder(
            stream: FirebaseFirestore.instance.collection("disabled_account").doc(currentUserId).snapshots(),
            builder: (context, dsnapshot) {
              if (!dsnapshot.hasData || dsnapshot.data!.exists == false) {
                if (dsnapshot.connectionState != ConnectionState.waiting) {
                  FirebaseFirestore.instance.collection("disabled_account").doc(currentUserId).set({"disabled": false});
                  return Center(
                    child: CircularProgressIndicator(),
                  );
                }
                return Center();
              } else if (dsnapshot.connectionState == ConnectionState.waiting || dsnapshot.hasData) {
                final disable = dsnapshot.data?.data()?["disabled"];
                if (disable == true) {
                  disabled = true;
                }
                if (disable == false) {
                  disabled = false;
                }

                return disabled == true
                    ? Scaffold(
                        body: Center(
                          child: Text("Your account has been disabled by the administrator."),
                        ),
                      )
                    : Scaffold(
                        key: drawerController,
                        drawer: Drawer(
                          width: MediaQuery.of(context).size.width - 130,
                          child: Column(
                            children: [
                              Container(
                                width: double.maxFinite,
                                height: 170,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(colors: [
                                    Colors.indigo.shade900,
                                    Colors.indigo.shade700,
                                    Colors.blue.shade600,
                                    Colors.blueAccent.shade400,
                                  ]),
                                ),
                                child: StreamBuilder(
                                    stream: _firestore.collection("Users").doc(currentUserId).snapshots(),
                                    builder: (context, snapshot) {
                                      final data = snapshot.data!;
                                      final imageurl = data["userimageurl"];
                                      final username = data["username"];
                                      final email = data["email"];

                                      return Stack(
                                        children: [
                                          Positioned(
                                            top: 10,
                                            left: 10,
                                            child: CircleAvatar(
                                              radius: 60,
                                              child: ClipOval(
                                                child: Image.network(
                                                  errorBuilder: (context, error, stackTrace) {
                                                    return CircularProgressIndicator();
                                                  },
                                                  width: 120,
                                                  height: MediaQuery.of(context).size.height,
                                                  fit: BoxFit.cover,
                                                  imageurl,
                                                  filterQuality: FilterQuality.high,
                                                ),
                                              ),
                                            ),
                                          ),
                                          Positioned(
                                            bottom: 20,
                                            right: 10,
                                            child: Text(
                                              username,
                                              style: TextStyle(color: Colors.white, fontSize: 22),
                                            ),
                                          ),
                                          Positioned(
                                            bottom: 10,
                                            right: 10,
                                            child: Text(
                                              email,
                                              style: TextStyle(color: Colors.white, fontSize: 12),
                                            ),
                                          )
                                        ],
                                      );
                                    }),
                              ),
                              ListTile(
                                onTap: () {
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
                                },
                                leading: Icon(
                                  Icons.account_circle_outlined,
                                  size: 30,
                                  color: Colors.black,
                                ),
                                title: Text(
                                  "My Profile",
                                  style: TextStyle(color: Colors.black),
                                ),
                              ),
                              ListTile(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    PageRouteBuilder(
                                      pageBuilder: (context, animation, secondaryAnimation) => SettingsPage(),
                                      transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                        const begin = Offset(3.0, 1.0);
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
                                leading: Icon(
                                  color: Colors.black,
                                  Icons.settings_outlined,
                                  size: 30,
                                ),
                                title: Text(
                                  "Settings",
                                  style: TextStyle(color: Colors.black),
                                ),
                              ),
                              ListTile(
                                onTap: () {
                                  showMessageBox("Logout", "Are You Sure To Logout?", context, "Yes", () {
                                    if (mounted) {
                                      FirebaseAuth.instance.signOut();
                                      FirebaseFirestore.instance
                                          .collection("Users")
                                          .doc(currentUserId)
                                          .update({"online": false});
                                      Navigator.pop(context);
                                      Navigator.pushAndRemoveUntil(
                                          context,
                                          PageRouteBuilder(
                                            pageBuilder: (context, animation, secondaryAnimation) => LogReg(),
                                            // The page to navigate to
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
                                          (Route<dynamic> route) => false);
                                    }
                                  });
                                },
                                leading: Icon(
                                  color: Colors.red,
                                  Icons.logout_outlined,
                                  size: 30,
                                ),
                                title: Text(
                                  "Log Out",
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          ),
                        ),
                        appBar: AppBar(
                          actions: [
                            IconButton(
                              tooltip: "Search Users",
                              splashColor: Colors.white60,
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  PageRouteBuilder(
                                    pageBuilder: (context, animation, secondaryAnimation) => SearchUser(),
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
                              icon: Icon(
                                Icons.search_rounded,
                                color: Colors.black,
                              ),
                            ),
                            IconButton(
                                onPressed: () {
                                  showMenu(
                                    color: Colors.white,
                                    elevation: 10,
                                    shadowColor: Colors.black54,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                    context: context,
                                    position: const RelativeRect.fromLTRB(100.0, 20.0, 20.0, 0.0),
                                    // Adjust position as needed
                                    items: [
                                      PopupMenuItem<String>(
                                        child: const Text(
                                          'Logout',
                                          style: TextStyle(color: Colors.red),
                                        ),
                                        onTap: () {
                                          showMessageBox("Logout", "Are You Sure To Logout?", context, "Yes", () {
                                            if (mounted) {
                                              FirebaseAuth.instance.signOut();
                                              FirebaseFirestore.instance
                                                  .collection("Users")
                                                  .doc(currentUserId)
                                                  .update({"online": false});
                                              Navigator.pop(context);
                                              Navigator.pushAndRemoveUntil(
                                                context,
                                                PageRouteBuilder(
                                                  pageBuilder: (context, animation, secondaryAnimation) => LogReg(),
                                                  // The page to navigate to
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
                                                (Route<dynamic> route) => false, // This removes all previous routes
                                              );
                                            }
                                          });
                                        },
                                      ),
                                      PopupMenuItem<String>(
                                        child: Text('Settings'),
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            PageRouteBuilder(
                                              pageBuilder: (context, animation, secondaryAnimation) => SettingsPage(),
                                              // The page to navigate to
                                              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                                const begin = Offset(3.0, 1.0);
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
                                      ),
                                    ],
                                  );
                                },
                                icon: const Icon(Icons.more_vert_outlined))
                          ],
                          leading: IconButton(
                              onPressed: () {
                                setState(() {
                                  drawerController.currentState?.openDrawer();
                                });
                              },
                              icon: const Icon(
                                Icons.menu_outlined,
                                size: 30,
                              )),
                          bottom: TabBar(
                              automaticIndicatorColorAdjustment: true,
                              unselectedLabelColor: Colors.black,
                              labelColor: Colors.indigoAccent,
                              tabs: const [
                                Tab(
                                  icon: FaIcon(FontAwesomeIcons.message),
                                  text: "Chats",
                                ),
                                Tab(
                                    text: "Updates",
                                    icon: Icon(
                                      Icons.update,
                                      size: 30,
                                    )),
                              ]),
                        ),
                        body: TabBarView(children: [ChatHome(), Updates()]),
                        floatingActionButton: FloatingActionButton(
                          elevation: 10,
                          splashColor: Colors.white60,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          autofocus: true,
                          backgroundColor: Colors.blue.shade400,
                          onPressed: () {
                            Navigator.push(
                              context,
                              PageRouteBuilder(
                                pageBuilder: (context, animation, secondaryAnimation) => FollowedChatList(),
                                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                  const begin = Offset(3.0, 1.0);
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
                          child: Icon(
                            Icons.chat_outlined,
                            color: Colors.white,
                          ),
                        ),
                      );
              }

              return Center();
            },
          ),
        ],
      ),
    );
  }
}
