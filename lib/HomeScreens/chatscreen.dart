// ignore_for_file: use_build_context_synchronously

import 'dart:io';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:QuickMessenger/HomeScreens/Profile/seachuserprofile.dart';
import 'package:QuickMessenger/HomeScreens/home.dart';
import 'package:QuickMessenger/Logins/showdialogs.dart';
import 'package:QuickMessenger/Ui/receivecard.dart';
import 'package:QuickMessenger/Ui/receivemedia.dart';
import 'package:QuickMessenger/Ui/sendmedia.dart';
import 'package:QuickMessenger/Ui/snackbar.dart';
import 'package:QuickMessenger/networkcheck.dart';
import '../Ui/sendcard.dart';
import 'chatscreenmethod.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen(
      {super.key,
      required this.imageurl,
      required this.username,
      required this.userid,
      required this.about,
      required this.email});

  // ignore: prefer_typing_uninitialized_variables
  final imageurl;

  // ignore: prefer_typing_uninitialized_variables
  final about;

  // ignore: prefer_typing_uninitialized_variables
  final email;

  // ignore: prefer_typing_uninitialized_variables
  final username;

  // ignore: prefer_typing_uninitialized_variables
  final userid;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with WidgetsBindingObserver {
  Map<String, IconData> iconList = {
    "Audio": Icons.music_note_outlined,
    "Image": Icons.image_outlined,
    "Video": FontAwesomeIcons.video,
    "Document": FontAwesomeIcons.file,
    "Unknown Type": FontAwesomeIcons.file,
    "Compressed File": Icons.folder_zip_outlined,
    "PDF Document": FontAwesomeIcons.filePdf,
  };
  bool loading = false;
  File? pickedImage;
  List<XFile?> pickedImages = [];
  List<PlatformFile> pickedFiles = [];
  final sendmsgC = TextEditingController();
  final firestore = FirebaseFirestore.instance.collection("Users");
  final userid = FirebaseAuth.instance.currentUser!.uid;
  bool blocked = false;
  final ScrollController _scrollController = ScrollController();

  Map<String, String> selectedChatMap = {};
  List<bool> selectedStates = [];

  @override
  Future<void> didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.paused) {
      await FirebaseFirestore.instance.collection("Users").doc(currentUserId).update({"online": false});
    } else if (state == AppLifecycleState.resumed) {
      await FirebaseFirestore.instance.collection("Users").doc(currentUserId).update({"online": true});
    }
  }

  setFollowFollowing() async {
    final myfollower = await FirebaseFirestore.instance
        .collection("Users")
        .doc(currentUserId)
        .collection("followers")
        .doc(widget.userid)
        .get();
    final myfollowing = await FirebaseFirestore.instance
        .collection("Users")
        .doc(currentUserId)
        .collection("following")
        .doc(widget.userid)
        .get();
    final userfollower = await FirebaseFirestore.instance
        .collection("Users")
        .doc(widget.userid)
        .collection("followers")
        .doc(currentUserId)
        .get();
    final userfollowing = await FirebaseFirestore.instance
        .collection("Users")
        .doc(widget.userid)
        .collection("following")
        .doc(currentUserId)
        .get();
    if (myfollower.exists == false) {
      await FirebaseFirestore.instance
          .collection("Users")
          .doc(currentUserId)
          .collection("followers")
          .doc(widget.userid)
          .set({"follower": false});
    } else if (myfollowing.exists == false) {
      await FirebaseFirestore.instance
          .collection("Users")
          .doc(currentUserId)
          .collection("following")
          .doc(widget.userid)
          .set({"following": false});
    } else if (userfollowing.exists == false) {
      await FirebaseFirestore.instance
          .collection("Users")
          .doc(widget.userid)
          .collection("following")
          .doc(currentUserId)
          .set({"following": false});
    } else if (userfollower.exists == false) {
      await FirebaseFirestore.instance
          .collection("Users")
          .doc(widget.userid)
          .collection("followers")
          .doc(currentUserId)
          .set({"follower": false});
    }
  }

  blockUser(blockUserid) async {
    if (blocked) {
      await FirebaseFirestore.instance
          .collection("block")
          .doc(currentUserId)
          .collection("blockedid")
          .doc(blockUserid)
          .set({"blocked": false});
      setState(() {
        blocked = false;
      });
    } else {
      await FirebaseFirestore.instance
          .collection("Users")
          .doc(currentUserId)
          .collection("followers")
          .doc(widget.userid)
          .update({"follower": false});
      await FirebaseFirestore.instance
          .collection("Users")
          .doc(currentUserId)
          .collection("following")
          .doc(widget.userid)
          .update({"following": false});
      await FirebaseFirestore.instance
          .collection("Users")
          .doc(widget.userid)
          .collection("followers")
          .doc(currentUserId)
          .update({"follower": false});
      await FirebaseFirestore.instance
          .collection("Users")
          .doc(widget.userid)
          .collection("following")
          .doc(currentUserId)
          .update({"following": false});
      await FirebaseFirestore.instance
          .collection("block")
          .doc(currentUserId)
          .collection("blockedid")
          .doc(blockUserid)
          .set({"blocked": true});
      setState(() {
        blocked = true;
      });
    }
  }

  checkBlockedOrNot(userId) async {
    final status = await FirebaseFirestore.instance
        .collection("block")
        .doc(currentUserId)
        .collection("blockedid")
        .doc(userId)
        .get();
    final statusB = status.data()?["blocked"];
    if (statusB == true) {
      setState(() {
        blocked = true;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    checkBlockedOrNot(widget.userid);
    blockedByUserOrNot();
    setFollowFollowing();
    WidgetsBinding.instance.addObserver(this);
    NetworkCheck().initializeInternetStatus(context);
  }

  blockedByUserOrNot() async {
    final getBlockState = await FirebaseFirestore.instance
        .collection("block")
        .doc(widget.userid)
        .collection("blockedid")
        .doc(currentUserId)
        .get();
    if (getBlockState.exists == false) {
      await FirebaseFirestore.instance
          .collection("block")
          .doc(widget.userid)
          .collection("blockedid")
          .doc(currentUserId)
          .set({"blocked": false});
    }
  }

  @override
  void dispose() {
    super.dispose();
    _scrollController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    NetworkCheck().cancelSubscription();
  }

  addSendChatToUser() async {
    await FirebaseFirestore.instance
        .collection("Users")
        .doc(widget.userid)
        .collection("chats")
        .doc(currentUserId)
        .set({"chat": true, "time": FieldValue.serverTimestamp()});
  }

  void scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.linear,
        );
      }
    });
  }

  void sendFiles(List<PlatformFile> pickedFiles, sender, receiver) async {
    Directory savePath = Directory('/storage/emulated/0/Download');
    Directory qmsg = Directory("${savePath.path}/QuickMessenger");
    if (!await qmsg.exists()) {
      qmsg.create(recursive: true);
    }
    Directory fileDir = Directory("${qmsg.path}/Files");
    if (!await fileDir.exists()) {
      fileDir.create();
    }

    for (var file in pickedFiles) {
      Random random = Random();
      final docname = random.nextInt(1000000).toString();
      Directory filepath = Directory("${fileDir.path}/$docname.${file.extension}");

      File fileCopy = File(file.path.toString());
      await fileCopy.copy(filepath.path);
      String fileType = getFileType(".${file.extension}");

      try {
        UploadTask uploadTask =
            FirebaseStorage.instance.ref("UserSendDocs").child(sender).child(docname).putFile(File(file.xFile.path));
        TaskSnapshot taskSnapshot = await uploadTask;
        final fileurl = await taskSnapshot.ref.getDownloadURL();
        await firestore.doc(userid).collection("save_chat").doc(receiver).collection("messages").doc(docname).set({
          "messagestate": "send",
          "filetype": fileType,
          "sender": userid,
          "receiver": receiver,
          "message": userid,
          "fileurl": fileurl,
          "extension": ".${file.extension}",
          "time": DateTime.now().toLocal()
        });
        await firestore.doc(receiver).collection("save_chat").doc(userid).collection("messages").doc(docname).set({
          "messagestate": "No State",
          "filetype": fileType,
          "sender": userid,
          "receiver": receiver,
          "fileurl": fileurl,
          "extension": ".${file.extension}",
          "message": userid,
          "time": DateTime.now().toLocal()
        });
        scrollToBottom();
        addSendChatToUser();
      } on FirebaseException catch (e) {
        if (mounted) showCustomDialog("SendError", "Error: $e", context);
      }
    }
    setState(() {
      loading = false;
      pickedFiles.clear();
    });
  }

  void sendImage(File? pickedimage, List<XFile?> pickedImages, sender, receiver) async {
    Directory savePath = Directory('/storage/emulated/0/Download');
    Directory qmsg = Directory("${savePath.path}/QuickMessenger");
    if (!await qmsg.exists()) {
      qmsg.create(recursive: true);
    }
    Directory imageDir = Directory("${qmsg.path}/Files");
    if (!await imageDir.exists()) {
      imageDir.create();
    }

    if (pickedimage != null) {
      Random random = Random();
      final docname = random.nextInt(1000000).toString();
      Directory imagepath = Directory("${imageDir.path}/$docname.jpg");
      File(pickedimage.path).copy(imagepath.path);

      try {
        UploadTask uploadTask =
            FirebaseStorage.instance.ref("UserSendDocs").child(sender).child(docname).putFile(pickedimage);
        TaskSnapshot taskSnapshot = await uploadTask;
        final imageurl = await taskSnapshot.ref.getDownloadURL();
        await firestore.doc(userid).collection("save_chat").doc(receiver).collection("messages").doc(docname).set({
          "messagestate": "send",
          "sender": userid,
          "receiver": receiver,
          "filetype": "Image",
          "extension": ".jpg",
          "message": userid,
          "fileurl": imageurl,
          "time": DateTime.now().toLocal()
        });
        await firestore.doc(receiver).collection("save_chat").doc(userid).collection("messages").doc(docname).set({
          "messagestate": "No State",
          "sender": userid,
          "receiver": receiver,
          "filetype": "Image",
          "extension": ".jpg",
          "fileurl": imageurl,
          "message": userid,
          "time": DateTime.now().toLocal()
        });
        scrollToBottom();
        addSendChatToUser();
      } on FirebaseException catch (e) {
        if (mounted) showCustomDialog("SendError", "Error: $e", context);
      }
      setState(() {
        loading = false;
        pickedImage = null;
      });
    } else {
      for (var image in pickedImages.toList()) {
        Random random = Random();
        final docname = random.nextInt(1000000).toString();

        Directory imagepath = Directory("${imageDir.path}/$docname.jpg");
        File imageCopy = File(image!.path);
        await imageCopy.copy(imagepath.path);
        try {
          UploadTask uploadTask =
              FirebaseStorage.instance.ref("UserSendDocs").child(sender).child(docname).putFile(File(image.path));
          TaskSnapshot taskSnapshot = await uploadTask;
          final imageurl = await taskSnapshot.ref.getDownloadURL();
          await firestore.doc(userid).collection("save_chat").doc(receiver).collection("messages").doc(docname).set({
            "messagestate": "send",
            "sender": userid,
            "receiver": receiver,
            "filetype": "Image",
            "extension": ".jpg",
            "message": userid,
            "fileurl": imageurl,
            "time": DateTime.now().toLocal()
          });
          await firestore.doc(receiver).collection("save_chat").doc(userid).collection("messages").doc(docname).set({
            "messagestate": "No State",
            "sender": userid,
            "receiver": receiver,
            "filetype": "Image",
            "extension": ".jpg",
            "fileurl": imageurl,
            "message": userid,
            "time": DateTime.now().toLocal()
          });
          scrollToBottom();
          addSendChatToUser();
        } on FirebaseException catch (e) {
          if (mounted) showCustomDialog("SendError", "Error: $e", context);
        }
        setState(() {
          loading = false;
          pickedImages.clear();
        });
      }
    }
  }

  void sendMessage(String message, sender, receiver) async {
    if (sendmsgC.text.isNotEmpty) {
      Random random = Random();
      final docname = random.nextInt(1000000).toString();

      try {
        await firestore.doc(userid).collection("save_chat").doc(receiver).collection("messages").doc(docname).set({
          "messagestate": "send",
          "sender": userid,
          "receiver": receiver,
          "message": message,
          "time": DateTime.now().toLocal()
        });
        await firestore.doc(receiver).collection("save_chat").doc(userid).collection("messages").doc(docname).set({
          "messagestate": "No State",
          "sender": userid,
          "receiver": receiver,
          "message": message,
          "time": DateTime.now().toLocal()
        });
        scrollToBottom();
        addSendChatToUser();
      } on FirebaseException catch (e) {
        if (mounted) showCustomDialog("SendError", "Error: $e", context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        await Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => HomeScreen(),
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
        return super.mounted;
      },
      child: Scaffold(
        appBar: AppBar(
          leadingWidth: 300,
          elevation: 2,
          leading: SizedBox(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                IconButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        PageRouteBuilder(
                          pageBuilder: (context, animation, secondaryAnimation) => HomeScreen(),
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
                      );
                    },
                    icon: Icon(Icons.arrow_back_ios_new)),
                InkWell(
                  onTap: () async {
                    final getBlockState = await FirebaseFirestore.instance
                        .collection("block")
                        .doc(widget.userid)
                        .collection("blockedid")
                        .doc(currentUserId)
                        .get();

                    final data = getBlockState.data()?["blocked"].toString();
                    data == "false"
                        ? Navigator.push(
                            context,
                            PageRouteBuilder(
                              pageBuilder: (context, animation, secondaryAnimation) => SearchUserProfile(
                                  username: widget.username,
                                  email: widget.email,
                                  about: widget.about,
                                  imageurl: widget.imageurl,
                                  userid: widget.userid),
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
                          )
                        : showCustomDialog("", "${widget.username} has been blocked you.", context);
                  },
                  child: SizedBox(
                    width: 250,
                    child: Stack(
                      children: [
                        CircleAvatar(
                            radius: 25,
                            child: ClipOval(
                              child: Image.network(
                                width: 55,
                                height: MediaQuery.of(context).size.height,
                                fit: BoxFit.cover,
                                widget.imageurl,
                                filterQuality: FilterQuality.high,
                              ),
                            )),
                        Positioned(
                          left: 50,
                          bottom: 0,
                          child: Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Text(
                              widget.username,
                              style: TextStyle(fontSize: 20),
                            ),
                          ),
                        ),
                        StreamBuilder(
                            stream: firestore.doc(widget.userid).snapshots(),
                            builder: (context, snapshot) {
                              if (!snapshot.hasData) {}
                              if (snapshot.connectionState == ConnectionState.waiting) {}
                              final snap = snapshot.data?.data();
                              final isOnline = snap?["online"].toString();

                              return Positioned(
                                left: 40,
                                bottom: 5,
                                child: SizedBox(
                                  height: 13,
                                  width: 13,
                                  child: CircleAvatar(
                                    backgroundColor:
                                        isOnline == "true" ? Colors.greenAccent.shade400 : Colors.transparent,
                                  ),
                                ),
                              );
                            })
                      ],
                    ),
                  ),
                )
              ],
            ),
          ),
          actions: [
            IconButton(
                onPressed: () async {
                  final getBlockState = await FirebaseFirestore.instance
                      .collection("block")
                      .doc(widget.userid)
                      .collection("blockedid")
                      .doc(currentUserId)
                      .get();

                  final data = getBlockState.data()?["blocked"].toString();

                  data == "false"
                      ? showMenu(
                          color: Colors.white,
                          elevation: 10,
                          shadowColor: Colors.black54,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          context: context,
                          position: const RelativeRect.fromLTRB(100.0, 20.0, 20.0, 0.0),
                          // Adjust position as needed
                          items: [
                            PopupMenuItem<String>(
                              child: const Text(
                                'Clear Chats',
                              ),
                              onTap: () {
                                showMessageBox(
                                  "Deletion",
                                  "Are you sure clear all chat?",
                                  context,
                                  "Delete",
                                  () async {
                                    if (mounted) Navigator.pop(context);
                                    final docs = await firestore
                                        .doc(currentUserId)
                                        .collection("save_chat")
                                        .doc(widget.userid)
                                        .collection("messages")
                                        .get();
                                    for (var msg in docs.docs) {
                                      msg.reference.delete();
                                    }
                                  },
                                );
                              },
                            ),
                            PopupMenuItem<String>(
                              onTap: () {
                                blocked
                                    ? showMessageBox(
                                        "Unblock", "Are you want to unblock ${widget.username}", context, "Unblock",
                                        () {
                                        blockUser(widget.userid);
                                        Navigator.pop(context);
                                      })
                                    : showMessageBox(
                                        "Block", "Are you sure to block ${widget.username}", context, "Block",
                                        () async {
                                        blockUser(widget.userid);
                                        Navigator.pop(context);
                                      });
                              },
                              child: StreamBuilder(
                                  stream: FirebaseFirestore.instance
                                      .collection("block")
                                      .doc(currentUserId)
                                      .collection("blockedid")
                                      .doc(widget.userid)
                                      .snapshots(),
                                  builder: (context, snapshot) {
                                    if (snapshot.data?.exists == false) {
                                      FirebaseFirestore.instance
                                          .collection("block")
                                          .doc(currentUserId)
                                          .collection("blockedid")
                                          .doc(widget.userid)
                                          .set({"blocked": false});
                                      return Center(
                                        child: CircularProgressIndicator(),
                                      );
                                    }
                                    if (snapshot.hasData) {
                                      final data = snapshot.data;
                                      var block = data!["blocked"].toString();

                                      return Text(
                                        block == "true" ? "Unblock" : 'Block',
                                        style: TextStyle(color: block == "true" ? Colors.blue : Colors.red),
                                      );
                                    }
                                    return Center();
                                  }),
                            )
                          ],
                        )
                      : null;
                },
                icon: const Icon(Icons.more_vert_outlined))
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: StreamBuilder(
                  stream: firestore
                      .doc(userid)
                      .collection("save_chat")
                      .doc(widget.userid)
                      .collection("messages")
                      .orderBy("time")
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Center(
                        child: Text("No Messages"),
                      );
                    }

                    final messageList = snapshot.data!.docs.toList();
                    if (selectedStates.length != messageList.length) {
                      selectedStates = List.generate(
                        messageList.length,
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

                    if (!selectedStates.contains(true)) scrollToBottom();
                    return Column(
                      children: [
                        AnimatedContainer(
                          curve: Curves.easeInOut,
                          height: selectedStates.contains(true) ? 50 : 0,
                          duration: Duration(milliseconds: 200),
                          child: AppBar(
                            leading: IconButton(
                                tooltip: "Cancel",
                                onPressed: () {
                                  setState(() {
                                    selectedStates = List.generate(
                                      messageList.length,
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
                                  onPressed: () {
                                    deleteChat(mounted, widget.userid, context, selectedChatMap);
                                  },
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
                            controller: _scrollController,
                            shrinkWrap: true,
                            itemCount: messageList.length,
                            itemBuilder: (context, index) {
                              final messageData = messageList[index];
                              final messageId = messageList[index].id;
                              final txtMessage = messageData["message"];
                              var senderId = messageData["sender"];
                              final timestamp = messageData["time"];
                              final messageState = messageData["messagestate"];
                              final formatedTime = DateFormat("hh:mm a").format(timestamp.toDate());
                              final inkwell = GlobalKey();

                              if (selectedStates[index] == true) {
                                if (!selectedChatMap.containsKey(messageId)) {
                                  selectedChatMap[messageId.toString()] = senderId.toString();
                                }
                              } else if (selectedStates[index] == false) {
                                if (selectedChatMap.containsKey(messageId)) {
                                  selectedChatMap.remove(messageId);
                                }
                              }

                              if (txtMessage == userid && senderId == userid) {
                                final fileType = messageData["filetype"];
                                final extension = messageData["extension"];

                                final id = messageData.id;
                                Directory filepath =
                                    Directory('/storage/emulated/0/Download/QuickMessenger/Files/$id$extension');

                                File image = File(filepath.path);
                                return InkWell(
                                  key: inkwell,
                                  onLongPress: () {
                                    setState(() {
                                      selectedStates[index] = !selectedStates[index];
                                    });
                                  },
                                  onTap: () async {
                                    if (selectedStates.contains(true)) {
                                      setState(() {
                                        selectedStates[index] = !selectedStates[index];
                                      });
                                    } else {
                                      final renderbox = inkwell.currentContext?.findRenderObject() as RenderBox;
                                      final position = renderbox.localToGlobal(Offset.zero);

                                      showMenu(
                                        color: Colors.white,
                                        elevation: 10,
                                        shadowColor: Colors.black54,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                        context: context,
                                        position: RelativeRect.fromLTRB(
                                            position.dx + 200, position.dy + 30, position.dx + 400, position.dy + 100),
                                        items: [
                                          PopupMenuItem<String>(
                                            child: Row(
                                              children: [
                                                Icon(
                                                  Icons.folder_open_outlined,
                                                  size: 20,
                                                ),
                                                SizedBox(
                                                  width: 5,
                                                ),
                                                const Text('Open'),
                                              ],
                                            ),
                                            onTap: () async {
                                              try {
                                                if (fileType == "Image") {
                                                  await OpenFile.open(
                                                    filepath.path,
                                                  );
                                                } else {
                                                  if (fileType == "Compressed File") {
                                                    showSnackBar(
                                                        context, "Go to Downloads In App folder for Compressed Files.");
                                                  }
                                                  await OpenFile.open(
                                                    filepath.path,
                                                  );
                                                }
                                              } catch (e) {
                                                //
                                              }
                                            },
                                          ),
                                        ],
                                      );
                                    }
                                  },
                                  child: Container(
                                    color: selectedStates[index] ? Colors.blue.shade100 : Colors.transparent,
                                    child: SendMedia(
                                      fileType: fileType,
                                      filename: "$id$extension",
                                      iconData: iconList[fileType],
                                      time: formatedTime,
                                      messageState: messageState,
                                      fileImage: image,
                                    ),
                                  ),
                                );
                              } else if (txtMessage == widget.userid && senderId == widget.userid) {
                                markMessageAsSeen(messageId, widget.userid, context);
                                final fileType = messageData["filetype"];
                                final extension = messageData["extension"];
                                final fileUrl = messageData["fileurl"];
                                final id = messageData.id;
                                Directory filepath =
                                    Directory('/storage/emulated/0/Download/QuickMessenger/Files/$id$extension');
                                File file = File(filepath.path);
                                return InkWell(
                                  key: inkwell,
                                  onLongPress: () {
                                    setState(() {
                                      selectedStates[index] = !selectedStates[index];
                                    });
                                  },
                                  onTap: () {
                                    if (selectedStates.contains(true)) {
                                      setState(() {
                                        selectedStates[index] = !selectedStates[index];
                                      });
                                    } else {}
                                  },
                                  child: Container(
                                    color: selectedStates[index] ? Colors.blue.shade100 : Colors.transparent,
                                    child: Receivemedia(
                                      file: file,
                                      senderId: widget.userid,
                                      fileurl: fileUrl,
                                      fileType: fileType,
                                      filename: "$id$extension",
                                      iconData: iconList[fileType],
                                      time: formatedTime,
                                    ),
                                  ),
                                );
                              }

                              if (senderId == userid && txtMessage != userid) {
                                return InkWell(
                                  onLongPress: () {
                                    setState(() {
                                      selectedStates[index] = !selectedStates[index];
                                    });
                                  },
                                  onTap: () {
                                    if (selectedStates.contains(true)) {
                                      setState(() {
                                        selectedStates[index] = !selectedStates[index];
                                      });
                                    }
                                  },
                                  child: Container(
                                    color: selectedStates[index] ? Colors.blue.shade100 : Colors.transparent,
                                    child: Sendcard(
                                      messageState: messageState,
                                      time: formatedTime,
                                      message: txtMessage,
                                    ),
                                  ),
                                );
                              } else if (senderId == widget.userid && txtMessage != widget.userid) {
                                markMessageAsSeen(messageData.id, widget.userid, context);

                                return InkWell(
                                  onLongPress: () {
                                    setState(() {
                                      selectedStates[index] = !selectedStates[index];
                                    });
                                  },
                                  onTap: () {
                                    if (selectedStates.contains(true)) {
                                      setState(() {
                                        selectedStates[index] = !selectedStates[index];
                                      });
                                    }
                                  },
                                  child: Container(
                                    color: selectedStates[index] ? Colors.blue.shade100 : Colors.transparent,
                                    child: Receivecard(
                                      time: formatedTime,
                                      message: txtMessage,
                                    ),
                                  ),
                                );
                              }
                              return null;
                            },
                          ),
                        ),
                        loading
                            ? Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              )
                            : Center(),
                        pickedFiles.isNotEmpty || pickedImage != null || pickedImages.isNotEmpty
                            ? Container(
                                height: 100,
                                width: 400,
                                color: Colors.transparent,
                                child: Card(
                                  elevation: 5,
                                  color: Colors.grey.shade100,
                                  child: Stack(
                                    children: [
                                      pickedFiles.isNotEmpty
                                          ? Container(
                                              height: MediaQuery.of(context).size.height,
                                              width: MediaQuery.of(context).size.height,
                                              color: Colors.transparent,
                                              child: ListView.builder(
                                                itemCount: pickedFiles.length,
                                                itemBuilder: (context, index) {
                                                  final filename = pickedFiles[index].name;
                                                  String fileType = getFileType(".${pickedFiles[index].extension}");

                                                  return Column(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      ListTile(
                                                        leading: Icon(
                                                          iconList[fileType],
                                                          size: 35,
                                                        ),
                                                        title: Text(filename),
                                                      ),
                                                      pickedFiles.last == pickedFiles[index]
                                                          ? Text("")
                                                          : Padding(
                                                              padding: const EdgeInsets.only(left: 20, right: 120),
                                                              child: Divider(),
                                                            )
                                                    ],
                                                  );
                                                },
                                              ),
                                            )
                                          : SizedBox(),
                                      pickedImage != null
                                          ? Positioned(
                                              top: 10,
                                              bottom: 10,
                                              left: 100,
                                              right: 120,
                                              child: Text(
                                                pickedImage!.path.toString().replaceRange(0, 40, ""),
                                                style: TextStyle(
                                                  color: Colors.black,
                                                ),
                                              ))
                                          : Text(""),
                                      pickedImage != null
                                          ? Positioned(
                                              top: 10,
                                              bottom: 10,
                                              left: 10,
                                              child: ClipRRect(
                                                borderRadius: BorderRadius.circular(10),
                                                child: CircleAvatar(
                                                  radius: 36,
                                                  child: Image.file(
                                                    fit: BoxFit.cover,
                                                    height: 100,
                                                    File(pickedImage!.path),
                                                    width: 100,
                                                  ),
                                                ),
                                              ),
                                            )
                                          : pickedImages.isNotEmpty
                                              ? Container(
                                                  height: MediaQuery.of(context).size.height,
                                                  width: MediaQuery.of(context).size.height,
                                                  color: Colors.transparent,
                                                  child: ListView.builder(
                                                    itemCount: pickedImages.length,
                                                    itemBuilder: (context, index) {
                                                      return Padding(
                                                        padding: EdgeInsets.only(top: 8.0, right: 40.0, bottom: 8.0),
                                                        child: ListTile(
                                                          leading: ClipRRect(
                                                              borderRadius: BorderRadius.circular(10),
                                                              child: Image.file(
                                                                  fit: BoxFit.cover, File(pickedImages[index]!.path))),
                                                          title: Text(pickedImages[index]!.name),
                                                        ),
                                                      );
                                                    },
                                                  ),
                                                )
                                              : SizedBox(),
                                      Positioned(
                                        right: 10,
                                        top: 20,
                                        child: Padding(
                                          padding: const EdgeInsets.only(top: 5),
                                          child: IconButton.outlined(
                                              onPressed: () {
                                                setState(() {
                                                  pickedImage = null;
                                                  pickedImages.clear();
                                                  pickedFiles.clear();
                                                });
                                              },
                                              icon: Row(
                                                children: [
                                                  Icon(
                                                    Icons.highlight_remove_outlined,
                                                    size: 20,
                                                    color: Colors.black,
                                                  ),
                                                  Padding(
                                                    padding: const EdgeInsets.only(left: 8.0, right: 5),
                                                    child: Text(
                                                      "Cancel",
                                                      style: TextStyle(color: Colors.black),
                                                    ),
                                                  )
                                                ],
                                              )),
                                        ),
                                      )
                                    ],
                                  ),
                                ),
                              )
                            : SizedBox(),
                      ],
                    );
                  }),
            ),
            Container(
              height: 70,
              width: double.maxFinite,
              color: Colors.transparent,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 5.0, right: 10.0),
                    child: SizedBox(
                        width: MediaQuery.of(context).size.width - 75,
                        child: TextFormField(
                          controller: sendmsgC,
                          decoration: InputDecoration(
                            suffixIcon: Container(
                              color: Colors.transparent,
                              height: 10,
                              width: 120,
                              child: Stack(
                                children: [
                                  Positioned(
                                    right: 70,
                                    top: 0,
                                    bottom: 0,
                                    child: IconButton(
                                        onPressed: () async {
                                          try {
                                            FilePickerResult? pickFiles = await FilePicker.platform.pickFiles(
                                              allowedExtensions: [
                                                'mp3',
                                                'wav',
                                                'flac',
                                                'aac',
                                                'ogg',
                                                'm4a',
                                                'wma',
                                                'alac',
                                                'ape',
                                                'ac3',
                                                'opus',
                                                'aiff',
                                                'mid',
                                                'mka',
                                                'flv',
                                                'amr',
                                                'pdf',
                                                'txt',
                                                'doc',
                                                'docx',
                                                'xls',
                                                'xlsx',
                                                'ppt',
                                                'pptx',
                                                'odt',
                                                'ods',
                                                'odp',
                                                'rtf',
                                                'epub',
                                                'zip',
                                                'rar',
                                                'tar',
                                                '7z',
                                                'gz',
                                                'iso',
                                                'tar',
                                                'gz',
                                                'mp4',
                                                'mkv',
                                                'avi',
                                                'mov',
                                                'wmv',
                                                'flv',
                                                'webm',
                                                'mpeg',
                                                'mpg',
                                                '3gp',
                                                'vob',
                                                'ogv',
                                                'rm',
                                                'ram',
                                                'm4v',
                                                'asf'
                                              ],
                                              allowMultiple: true,
                                              allowCompression: true,
                                              type: FileType.custom,
                                            );
                                            if (pickFiles != null) {
                                              setState(() {
                                                pickedFiles = pickFiles.files;
                                              });
                                            }
                                          } catch (e) {
                                            if (context.mounted) {
                                              showSnackBar(context, "$e");
                                            }
                                          }
                                        },
                                        icon: Icon(
                                          FontAwesomeIcons.paperclip,
                                          size: 20,
                                        )),
                                  ),
                                  Positioned(
                                    right: 35,
                                    top: 0,
                                    bottom: 0,
                                    child: IconButton(
                                        onPressed: () async {
                                          try {
                                            final photo = await ImagePicker().pickImage(source: ImageSource.camera);
                                            if (photo != null) {
                                              final tempImage = File(photo.path);

                                              setState(() {
                                                pickedImage = tempImage;
                                              });
                                            }
                                          } catch (e) {
                                            showSnackBar(context, "$e");
                                          }
                                        },
                                        icon: Icon(Icons.camera_alt_outlined)),
                                  ),
                                  Positioned(
                                    right: 0,
                                    top: 0,
                                    bottom: 0,
                                    child: IconButton(
                                      onPressed: () async {
                                        try {
                                          final photos =
                                              await ImagePicker().pickMultiImage(limit: 5, requestFullMetadata: true);
                                          if (photos.isNotEmpty) {
                                            setState(() {
                                              pickedImages = photos;
                                            });
                                          }
                                        } catch (e) {
                                          showSnackBar(context, "$e");
                                        }
                                      },
                                      icon: Icon(
                                        Icons.image_outlined,
                                        size: 25,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            filled: true,
                            prefixIcon: Icon(
                              Icons.textsms_outlined,
                              size: 23,
                            ),
                            fillColor: Colors.white,
                            focusedBorder: OutlineInputBorder(
                                borderSide: const BorderSide(color: Colors.black26),
                                borderRadius: BorderRadius.circular(30)),
                            enabledBorder: OutlineInputBorder(
                                borderSide: const BorderSide(color: Colors.black26),
                                borderRadius: BorderRadius.circular(30)),
                          ),
                        )),
                  ),
                  SizedBox(
                    height: 55,
                    width: 55,
                    child: FloatingActionButton(
                      autofocus: true,
                      elevation: 10,
                      backgroundColor: Colors.blue.shade500,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                      onPressed: () async {
                        if (blocked == false) {
                          final getBlockState = await FirebaseFirestore.instance
                              .collection("block")
                              .doc(widget.userid)
                              .collection("blockedid")
                              .doc(currentUserId)
                              .get();
                          final data = getBlockState.data()?["blocked"].toString();
                          if (data != "true") {
                            if (sendmsgC.text.isNotEmpty) {
                              if (connectedToInternet == false) {
                                showCustomDialog("Network", "You are not connected to Internet!", context);
                              } else if (connectedToInternet == true) {
                                sendMessage(sendmsgC.text, userid, widget.userid);
                                sendmsgC.clear();
                              }
                            } else if (pickedImage != null || pickedImages.isNotEmpty) {
                              sendImage(pickedImage, pickedImages, currentUserId, widget.userid);

                              setState(() {
                                loading = true;
                              });
                            } else if (pickedFiles.isNotEmpty) {
                              setState(() {
                                loading = true;
                              });
                              sendFiles(pickedFiles, currentUserId, widget.userid);
                            }
                          } else {
                            showCustomDialog("", "${widget.username} has been blocked your account.", context);
                          }
                        } else {
                          showCustomDialog("", "You have been blocked this account.", context);
                        }
                      },
                      child: const Icon(
                        Icons.send,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
