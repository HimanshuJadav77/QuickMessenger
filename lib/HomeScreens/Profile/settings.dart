// ignore_for_file: use_build_context_synchronously

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:QuickMessenger/HomeScreens/Profile/blockeduserlist.dart';
import 'package:QuickMessenger/Logins/showdialogs.dart';

import '../home.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

enum ProfileVisibility { public, private }

class _SettingsPageState extends State<SettingsPage> {
  ProfileVisibility? privacyMode = ProfileVisibility.public;

  Future<void> _showConfirmationDialog(selectedMode) async {
    showMessageBox(
        "User Visibility",
        'Are you sure you want to set your profile visibility to ${selectedMode == "public" ? "Public" : "Private"}?',
        context,
        "Confirm", () async {
      await FirebaseFirestore.instance
          .collection("Users")
          .doc(currentUserId)
          .collection("privacy")
          .doc("mode")
          .set({"privacy": selectedMode == "public" ? "public" : "private"});

      Navigator.pop(context);
    });
  }

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
        title: Text('Settings', style: TextStyle(color: Colors.blue, fontSize: 22, fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        children: [
          StreamBuilder(
              stream: FirebaseFirestore.instance
                  .collection("Users")
                  .doc(currentUserId)
                  .collection("privacy")
                  .doc("mode")
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(),
                  );
                }
                if (!snapshot.hasData || snapshot.data!.exists == false) {
                  FirebaseFirestore.instance
                      .collection("Users")
                      .doc(currentUserId)
                      .collection("privacy")
                      .doc("mode")
                      .set({"privacy": "public"});
                  return Center();
                }

                final privacy = snapshot.data?.data()?["privacy"];
                return Column(
                  children: [
                    Align(
                        alignment: Alignment.topLeft,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 15.0, top: 10.0),
                          child: Text(
                            "Privacy",
                            style: TextStyle(color: Colors.blue, fontSize: 18),
                          ),
                        )),
                    RadioListTile(
                      title: Text("Public"),
                      value: "public",
                      groupValue: privacy,
                      onChanged: (value) {
                        if (value != null) {
                          _showConfirmationDialog(value);
                        }
                      },
                    ),
                    RadioListTile(
                      title: Text("Private"),
                      value: "private",
                      groupValue: privacy,
                      onChanged: (value) {
                        if (value != null) {
                          _showConfirmationDialog(value);
                        }
                      },
                    ),
                  ],
                );
              }),
          Divider(),
          ListTile(
            onTap: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => Blockeduserlist(),
                  ));
            },
            leading: Icon(
              Icons.block,
              color: Colors.red,
            ),
            title: Text(
              "Blocked Users",
              style: TextStyle(color: Colors.red),
            ),
          )
        ],
      ),
    );
  }
}
