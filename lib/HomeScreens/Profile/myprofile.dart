// ignore_for_file: prefer_typing_uninitialized_variables

import 'dart:developer';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:QuickMessenger/HomeScreens/Profile/settings.dart';
import 'package:QuickMessenger/Logins/showdialogs.dart';

import '../../Ui/snackbar.dart';
import 'followfollowing.dart';

class MyProfile extends StatefulWidget {
  const MyProfile({
    super.key,
  });

  @override
  State<MyProfile> createState() => _MyProfileState();
}

class _MyProfileState extends State<MyProfile> {
  File? pickedImage;
  bool modifyUsername = false;
  bool modifyAbout = false;
  final aboutC = TextEditingController();
  final usernameC = TextEditingController();
  final _storage = FirebaseStorage.instance;
  final _firestore = FirebaseFirestore.instance;
  final userid = FirebaseAuth.instance.currentUser!.uid;
  bool loading = false;
  final userData = FirebaseFirestore.instance.collection("Users").doc(FirebaseAuth.instance.currentUser!.uid);
  var username;
  var imageurl;
  var email;
  var about;

  Future<bool> checkUsernameExists(String username) async {
    try {
      final querySnapshot = await _firestore.collection("Users").where("username", isEqualTo: username).get();

      if (querySnapshot.docs.isNotEmpty) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      log("Error checking username: $e");
      return false;
    }
  }

  updateProfile() async {
    try {
      setState(() {
        loading = true;
      });
      if (pickedImage != null) {
        UploadTask uploadTask = _storage.ref("UsersImage").child(userid).putFile(pickedImage!);
        TaskSnapshot taskSnapshot = await uploadTask;
        final imageurl = await taskSnapshot.ref.getDownloadURL();
        await _firestore.collection("Users").doc(userid).update({"userimageurl": imageurl});
        if (mounted) showSnackBar(context, "Image Updated.");
      } else if (usernameC.text != username && modifyUsername) {
        bool isUsernameExist = await checkUsernameExists(usernameC.text);
        if (!isUsernameExist) {
          await _firestore.collection("Users").doc(userid).update({"username": usernameC.text});
          if (mounted) showSnackBar(context, "Username Updated.");
        } else {
          if (mounted) showSnackBar(context, "Username Already Exist.");
        }
      } else if (aboutC.text != about && modifyAbout) {
        await _firestore.collection("Users").doc(userid).update({"about": aboutC.text});
        if (mounted) showSnackBar(context, "About Updated.");
      }

      setState(() {
        loading = false;
        modifyAbout = false;
        modifyUsername = false;
        pickedImage = null;
      });
    } on FirebaseException catch (e) {
      if (mounted) showSnackBar(context, "$e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
        stream: userData.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasData) {
            final data = snapshot.data?.data() as Map<String, dynamic>;
            username = data["username"].toString();
            imageurl = data["userimageurl"].toString();
            email = data["email"].toString();
            about = data["about"].toString();

            return Scaffold(
              appBar: AppBar(
                actions: [
                  if (pickedImage != null || modifyAbout == true || modifyUsername == true)
                    Row(
                      children: [
                        TextButton(
                            onPressed: () {
                              setState(() {
                                pickedImage = null;
                                modifyAbout = false;
                                modifyUsername = false;
                              });
                            },
                            child: Text(
                              "Cancel",
                              style: TextStyle(fontSize: 20, color: Colors.red),
                            )),
                        Padding(
                          padding: const EdgeInsets.only(top: 15, bottom: 15),
                          child: VerticalDivider(),
                        ),
                        !loading
                            ? TextButton(
                                onPressed: () {
                                  updateProfile();
                                },
                                child: Text(
                                  "Update",
                                  style: TextStyle(fontSize: 20, color: Colors.blue),
                                ))
                            : Padding(
                                padding: const EdgeInsets.all(10.0),
                                child: SizedBox(height: 30, width: 30, child: CircularProgressIndicator()),
                              ),
                      ],
                    )
                  else
                    IconButton(
                        onPressed: () {
                          showMenu(
                            color: Colors.white,
                            context: context,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            position: RelativeRect.fromLTRB(100, 20, 27, 20),
                            // Adjust position as needed
                            items: [
                              PopupMenuItem<String>(
                                child: const Text('Privacy'),
                                onTap: () {
                                  Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => SettingsPage(),
                                      ));
                                },
                              ),
                            ],
                          );
                        },
                        icon: Icon(Icons.more_vert_outlined)),
                ],
                title: Text(
                  "My Profile",
                  style: TextStyle(color: Colors.blue, fontSize: 22, fontWeight: FontWeight.bold),
                ),
                leading: IconButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    icon: Icon(Icons.arrow_back_ios_new)),
              ),
              body: ListView(
                children: [
                  Row(
                    children: [
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Stack(
                            children: [
                              Card(
                                elevation: 10,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(60)),
                                child: CircleAvatar(
                                  radius: 60,
                                  child: ClipOval(
                                    child: pickedImage != null
                                        ? Image.file(
                                            width: 120,
                                            height: MediaQuery.of(context).size.height,
                                            fit: BoxFit.cover,
                                            pickedImage!,
                                            filterQuality: FilterQuality.high,
                                          )
                                        : Image.network(
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
                                top: 85,
                                right: 2,
                                child: CircleAvatar(
                                  backgroundColor: Colors.blue.shade400,
                                  child: IconButton(
                                      onPressed: () {
                                        showPickerDialog("Image", () async {
                                          try {
                                            final photo = await ImagePicker().pickImage(source: ImageSource.camera);
                                            if (photo != null) {
                                              final tempImage = File(photo.path);
                                              setState(() {
                                                pickedImage = tempImage;
                                              });
                                            }
                                          } catch (e) {
                                            // ignore: use_build_context_synchronously
                                            showSnackBar(context, "$e");
                                          }
                                          // ignore: use_build_context_synchronously
                                          Navigator.pop(context);
                                        }, () async {
                                          try {
                                            final photo = await ImagePicker().pickImage(source: ImageSource.gallery);
                                            if (photo != null) {
                                              final tempImage = File(photo.path);
                                              setState(() {
                                                pickedImage = tempImage;
                                              });
                                            }
                                          } catch (e) {
                                            // ignore: use_build_context_synchronously
                                            showSnackBar(context, "$e");
                                          }
                                          // ignore: use_build_context_synchronously
                                          Navigator.pop(context);
                                        }, context);
                                      },
                                      icon: Icon(
                                        Icons.camera_alt_outlined,
                                        color: Colors.black,
                                      )),
                                ),
                              )
                            ],
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => FollowFollowingPage(
                                  userid: userid,
                                ),
                              ));
                        },
                        child: SizedBox(
                          width: 265,
                          height: 70,
                          child: Stack(
                            children: [
                              Positioned(
                                child: Padding(
                                  padding: const EdgeInsets.only(left: 40, top: 5),
                                  child: Text(
                                    "Follower",
                                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w400),
                                  ),
                                ),
                              ),
                              Positioned(
                                right: 30,
                                child: Padding(
                                  padding: const EdgeInsets.only(left: 40, top: 5),
                                  child: Text(
                                    "Following",
                                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w400),
                                  ),
                                ),
                              ),
                              Positioned(
                                right: 195,
                                top: 25,
                                child: StreamBuilder<QuerySnapshot>(
                                    stream: _firestore
                                        .collection("Users")
                                        .doc(userid)
                                        .collection("followers")
                                        .where("follower", isEqualTo: true)
                                        .snapshots(),
                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState == ConnectionState.waiting) {
                                        return Padding(
                                          padding: EdgeInsets.only(top: 10, left: 15),
                                          child: SizedBox(
                                            height: 20,
                                            width: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 3,
                                            ),
                                          ),
                                        );
                                      }
                                      return Padding(
                                        padding: const EdgeInsets.only(left: 70, top: 5),
                                        child: Text(
                                          "${snapshot.data?.docs.length}",
                                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w400),
                                        ),
                                      );
                                    }),
                              ),
                              Positioned(
                                right: 65,
                                top: 25,
                                child: StreamBuilder<QuerySnapshot>(
                                    stream: _firestore
                                        .collection("Users")
                                        .doc(userid)
                                        .collection("following")
                                        .where("following", isEqualTo: true)
                                        .snapshots(),
                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState == ConnectionState.waiting) {
                                        return Padding(
                                          padding: EdgeInsets.only(top: 10, left: 15),
                                          child: SizedBox(
                                            height: 20,
                                            width: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 3,
                                            ),
                                          ),
                                        );
                                      }
                                      return Padding(
                                        padding: const EdgeInsets.only(left: 70, top: 5),
                                        child: Text(
                                          "${snapshot.data!.docs.length}",
                                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w400),
                                        ),
                                      );
                                    }),
                              ),
                            ],
                          ),
                        ),
                      )
                    ],
                  ),
                  ListTile(
                    leading: Icon(
                      color: Colors.blue,
                      Icons.person_2_outlined,
                      size: 30,
                    ),
                    title: Text(
                      "Username",
                      style: TextStyle(fontSize: 15, color: Colors.blue),
                    ),
                    subtitle: modifyUsername
                        ? TextFormField(
                            style: TextStyle(fontSize: 18, color: Colors.black),
                            autofocus: true,
                            controller: usernameC,
                          )
                        : Text(
                            username,
                            style: TextStyle(fontSize: 18, color: Colors.black),
                          ),
                    trailing: modifyUsername
                        ? null
                        : IconButton(
                            onPressed: () {
                              setState(() {
                                modifyUsername = true;
                                usernameC.text = username;
                              });
                            },
                            icon: Icon(
                              color: Colors.blue,
                              Icons.mode_edit_outline_outlined,
                              size: 30,
                            )),
                  ),
                  ListTile(
                    leading: Icon(
                      color: Colors.blue,
                      Icons.email_outlined,
                      size: 30,
                    ),
                    title: Text(
                      "Email",
                      style: TextStyle(fontSize: 15, color: Colors.blue),
                    ),
                    subtitle: Text(
                      email,
                      style: TextStyle(fontSize: 18, color: Colors.black),
                    ),
                  ),
                  ListTile(
                    leading: Icon(
                      color: Colors.blue,
                      Icons.info_outline_rounded,
                      size: 30,
                    ),
                    title: Text(
                      "About",
                      style: TextStyle(fontSize: 15, color: Colors.blue),
                    ),
                    subtitle: modifyAbout
                        ? TextFormField(
                            style: TextStyle(fontSize: 18, color: Colors.black),
                            autofocus: true,
                            controller: aboutC,
                          )
                        : Text(
                            about,
                            style: TextStyle(fontSize: 18, color: Colors.black),
                          ),
                    trailing: modifyAbout
                        ? null
                        : IconButton(
                            onPressed: () {
                              setState(() {
                                modifyAbout = true;
                                aboutC.text = about;
                              });
                            },
                            icon: Icon(
                              color: Colors.blue,
                              Icons.mode_edit_outline_outlined,
                              size: 30,
                            )),
                  ),
                ],
              ),
            );
          }
          return Center();
        });
  }
}
