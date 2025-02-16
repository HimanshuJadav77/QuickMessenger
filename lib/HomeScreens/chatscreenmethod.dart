import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import '../Logins/showdialogs.dart';
import '../Ui/snackbar.dart';
import 'home.dart';

final firestore = FirebaseFirestore.instance.collection("Users");

String getFileType(String? extension) {
  if ([
    '.mp3',
    '.wav',
    '.flac',
    '.aac',
    '.ogg',
    '.m4a',
    '.wma',
    '.alac',
    '.ape',
    '.ac3',
    '.opus',
    '.aiff',
    '.mid',
    '.mka',
    '.flv',
    '.amr'
  ].contains(extension)) {
    return 'Audio';
  } else if (['.jpg', '.jpeg', '.png', '.gif', '.bmp', '.tiff', '.svg', '.ico', '.webp', '.heif', '.heic', '.raw']
      .contains(extension)) {
    return 'Image';
  } else if (['.pdf'].contains(extension)) {
    return 'PDF Document';
  } else if (['.txt', '.doc', '.docx', '.xls', '.xlsx', '.ppt', '.pptx', '.odt', '.ods', '.odp', '.rtf', '.epub']
      .contains(extension)) {
    return 'Document';
  } else if (['.zip', '.rar', '.tar', '.7z', '.gz', '.iso', '.tar.gz'].contains(extension)) {
    return 'Compressed File';
  } else if ([
    '.mp4',
    '.mkv',
    '.avi',
    '.mov',
    '.wmv',
    '.flv',
    '.webm',
    '.mpeg',
    '.mpg',
    '.3gp',
    '.vob',
    '.ogv',
    '.rm',
    '.ram',
    '.m4v',
    '.asf'
  ].contains(extension)) {
    return 'Video';
  } else {
    return 'Unknown Type';
  }
}

deleteChat(mounted, chatUserId, BuildContext context, Map<String, String> selectedChatMap) async {
  List<String> senderList = selectedChatMap.values.toList();
  List<String> msgList = selectedChatMap.keys.toList();

  if (senderList.contains(chatUserId)) {
    if (mounted) {
      showMessageBox(
        "Deletion",
        "Are you sure delete chats?",
        context,
        "Delete",
        () {
          deleteOwnChat(msgList, chatUserId, context);
          Navigator.pop(context);
        },
      );
    }
  } else if (!senderList.contains(chatUserId)) {
    if (mounted) {
      showDeleteChatBox(
        "Deletion",
        "Are you sure to delete chats?",
        context,
        () {
          deleteUserChat(msgList, chatUserId, context);
          deleteOwnChat(msgList, chatUserId, context);
          Navigator.pop(context);
        },
        () {
          deleteOwnChat(msgList, chatUserId, context);
          Navigator.pop(context);
        },
      );
    }
  }
}

deleteUserChat(msgList, deleteUserid, BuildContext context) async {
  try {
    for (var chatId in msgList) {
      final chat = await firestore
          .doc(deleteUserid)
          .collection("save_chat")
          .doc(currentUserId)
          .collection("messages")
          .doc(chatId)
          .get();
      if (chat.exists) {
        await firestore
            .doc(deleteUserid)
            .collection("save_chat")
            .doc(currentUserId)
            .collection("messages")
            .doc(chatId)
            .delete();
      }
    }
  } on FirebaseException catch (ex) {
    showSnackBar(context, ex.toString());
  }
}

deleteOwnChat(msgList, chatUserid, BuildContext context) async {
  try {
    for (var chatId in msgList) {
      final deleteChat = await firestore
          .doc(currentUserId)
          .collection("save_chat")
          .doc(chatUserid)
          .collection("messages")
          .doc(chatId)
          .get();
      var ext = deleteChat.data()?["extension"];
      Directory filepath = Directory('/storage/emulated/0/Download/QuickMessenger/Files/$chatId$ext');
      File file = File(filepath.path);
      if (ext != null && await file.exists()) {
        await file.delete();
        await firestore
            .doc(currentUserId)
            .collection("save_chat")
            .doc(chatUserid)
            .collection("messages")
            .doc(chatId)
            .delete();
        showSnackBar(context, "Deleted $chatId$ext");
      } else {
        await firestore
            .doc(currentUserId)
            .collection("save_chat")
            .doc(chatUserid)
            .collection("messages")
            .doc(chatId)
            .delete();
      }
    }
  } on FirebaseException catch (ex) {
    showSnackBar(context, ex.toString());
  }
}

void markMessageAsSeen(String messageId, chatUserId,BuildContext context) async {
  try {
    var docSnap = await firestore
        .doc(chatUserId)
        .collection("save_chat")
        .doc(currentUserId)
        .collection("messages")
        .doc(messageId)
        .get();
    if (docSnap.exists) {
      final messageData = docSnap.data();
      String currentState = messageData?["messagestate"];
      if (currentState != "seen") {
        await firestore
            .doc(chatUserId)
            .collection("save_chat")
            .doc(currentUserId)
            .collection("messages")
            .doc(messageId)
            .update({
          "messagestate": "seen",
        });
      }
    }
  } catch (e) {
    showSnackBar(context, "$e");
  }
}
