import 'package:flutter/material.dart';

logregcontainer(child, BuildContext context) {
  return showBottomSheet(
    sheetAnimationStyle: AnimationStyle(duration: const Duration(milliseconds: 700)),
    enableDrag: true,
    showDragHandle: true,
    elevation: 20,
    backgroundColor: Colors.white,
    context: context,
    builder: (context) {
      return SingleChildScrollView(
        physics: PageScrollPhysics(),
        child: SizedBox(
          height: double.maxFinite,
          width: double.maxFinite,
          child: child,
        ),
      );
    },
  );
}

showCustomDialog(String title, String content, BuildContext context) {
  return showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: title != ""
            ? Text(
                title,
                style: TextStyle(color: Colors.blue, fontSize: 20, fontWeight: FontWeight.bold),
              )
            : null,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        content: Text(
          content,
          style: TextStyle(
            color: Colors.black,
            fontSize: 15,
          ),
        ),
        elevation: 10,
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                  onPressed: () async {
                    Navigator.pop(context);
                  },
                  child: const Text(
                    "Ok",
                    style: TextStyle(color: Colors.blue, fontSize: 18),
                  )),
            ],
          )
        ],
      );
    },
  );
}

showPickerDialog(String title, VoidCallback camera, VoidCallback gallary, BuildContext context) {
  return showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Row(
          children: [
            Text(
              title,
              style: TextStyle(color: Colors.blue, fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(
              width: 120,
            ),
            IconButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: Icon(Icons.close))
          ],
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        elevation: 10,
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              IconButton.outlined(
                onPressed: camera,
                icon: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Icon(Icons.camera_alt_outlined),
                    Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: Text("Camera"),
                    )
                  ],
                ),
              ),
              IconButton.outlined(
                onPressed: gallary,
                icon: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Icon(Icons.photo_library_outlined),
                    Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: Text("Gallery"),
                    )
                  ],
                ),
              )
            ],
          )
        ],
      );
    },
  );
}

profileVisibility(BuildContext context, dropDownVal, onChanged, VoidCallback onPressed) {
  return showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(
          "Privacy",
          style: TextStyle(color: Colors.blue, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        content: Row(
          children: [
            Text(
              "Account Visibility",
              style: TextStyle(
                color: Colors.black,
                fontSize: 15,
              ),
            ),
            DropdownButton<String>(
              value: dropDownVal,
              items: ["Public", "Private"].map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ],
        ),
        elevation: 10,
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                  onPressed: onPressed,
                  child: Text(
                    "Confirm",
                    style: TextStyle(color: Colors.blue, fontSize: 16),
                  )),
            ],
          )
        ],
      );
    },
  );
}

showMessageBox(String title, String content, BuildContext context, buttonName, VoidCallback onPressed) {
  return showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(
          title,
          style: TextStyle(
              color: title == "Deletion" || title == "Block" ? Colors.red : Colors.blue,
              fontSize: 20,
              fontWeight: FontWeight.bold),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        content: Text(
          content,
          style: TextStyle(
            color: Colors.black,
            fontSize: 15,
          ),
        ),
        elevation: 10,
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                  onPressed: () async {
                    Navigator.pop(context);
                  },
                  child: const Text(
                    "Cancel",
                    style: TextStyle(color: Colors.blue, fontSize: 16),
                  )),
              TextButton(
                  onPressed: onPressed,
                  child: Text(
                    buttonName,
                    style: TextStyle(
                        color: buttonName == "Delete" || buttonName == "Block" ? Colors.red : Colors.blue,
                        fontSize: 16),
                  )),
            ],
          )
        ],
      );
    },
  );
}

showDeleteChatBox(
    String title, String content, BuildContext context, VoidCallback deleteForEveryone, VoidCallback deleteForMe) {
  return showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(
          title,
          style: TextStyle(color: Colors.blue, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              content,
              style: TextStyle(
                color: Colors.black,
                fontSize: 15,
              ),
            ),
            Padding(
              padding: EdgeInsets.all(10.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                        onPressed: deleteForEveryone,
                        child: const Text(
                          "Delete for everyone",
                          style: TextStyle(color: Colors.red, fontSize: 16),
                        )),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                        onPressed: deleteForMe,
                        child: const Text(
                          "Delete for me",
                          style: TextStyle(color: Colors.red, fontSize: 16),
                        )),
                  ),
                ],
              ),
            )
          ],
        ),
        elevation: 10,
      );
    },
  );
}
