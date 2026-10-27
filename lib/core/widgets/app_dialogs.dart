import 'package:flutter/cupertino.dart';

/// iOS-native log/register bottom sheet using CupertinoActionSheet.
/// Replaces the legacy Material `showBottomSheet` wrapper.
Future<void> logregcontainer(Widget child, BuildContext context) {
  return showCupertinoModalPopup(
    context: context,
    builder: (context) => CupertinoActionSheet(
      message: child,
      cancelButton: CupertinoActionSheetAction(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
    ),
  );
}

/// iOS-native info dialog using [CupertinoAlertDialog].
/// Replaces the legacy `showCustomDialog` Material AlertDialog.
Future<void> showCustomDialog(
    String title, String content, BuildContext context) {
  return showCupertinoDialog(
    context: context,
    builder: (context) => CupertinoAlertDialog(
      title: title.isNotEmpty ? Text(title) : null,
      content: Text(content),
      actions: [
        CupertinoDialogAction(
          onPressed: () => Navigator.pop(context),
          child: const Text('OK'),
        ),
      ],
    ),
  );
}

/// iOS-native photo picker action sheet using [CupertinoActionSheet].
/// Replaces the legacy Material AlertDialog-based picker.
Future<void> showPickerDialog(String title, VoidCallback camera,
    VoidCallback gallery, BuildContext context) {
  return showCupertinoModalPopup(
    context: context,
    builder: (context) => CupertinoActionSheet(
      title: Text(title),
      actions: [
        CupertinoActionSheetAction(
          onPressed: () {
            Navigator.pop(context);
            camera();
          },
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(CupertinoIcons.camera, size: 22),
              SizedBox(width: 8),
              Text('Camera'),
            ],
          ),
        ),
        CupertinoActionSheetAction(
          onPressed: () {
            Navigator.pop(context);
            gallery();
          },
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(CupertinoIcons.photo, size: 22),
              SizedBox(width: 8),
              Text('Photo Library'),
            ],
          ),
        ),
      ],
      cancelButton: CupertinoActionSheetAction(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
    ),
  );
}

/// iOS-native privacy settings dialog using [CupertinoAlertDialog] with [CupertinoSegmentedControl].
/// Replaces the legacy Material AlertDialog with DropdownButton.
Future<void> profileVisibility(BuildContext context, String dropDownVal,
    ValueChanged<String?> onChanged, VoidCallback onPressed) {
  return showCupertinoDialog(
    context: context,
    builder: (context) => CupertinoAlertDialog(
      title: const Text('Privacy'),
      content: Padding(
        padding: const EdgeInsets.only(top: 16),
        child: CupertinoSegmentedControl<String>(
          children: const {
            'Public': Text('Public'),
            'Private': Text('Private'),
          },
          groupValue: dropDownVal,
          onValueChanged: onChanged,
        ),
      ),
      actions: [
        CupertinoDialogAction(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        CupertinoDialogAction(
          isDefaultAction: true,
          onPressed: () {
            Navigator.pop(context);
            onPressed();
          },
          child: const Text('Confirm'),
        ),
      ],
    ),
  );
}

/// iOS-native confirmation dialog using [CupertinoAlertDialog].
/// Replaces the legacy `showMessageBox` Material AlertDialog.
Future<void> showMessageBox(String title, String content, BuildContext context,
    String buttonName, VoidCallback onPressed) {
  final bool isDestructive = buttonName == 'Delete' || buttonName == 'Block';

  return showCupertinoDialog(
    context: context,
    builder: (context) => CupertinoAlertDialog(
      title: Text(
        title,
        style: TextStyle(
          color: isDestructive
              ? CupertinoColors.systemRed
              : (CupertinoTheme.of(context).brightness == Brightness.dark
                  ? CupertinoColors.white
                  : CupertinoColors.black),
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: Text(content, style: const TextStyle(fontSize: 15)),
      actions: [
        CupertinoDialogAction(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        CupertinoDialogAction(
          isDestructiveAction: isDestructive,
          onPressed: () {
            Navigator.pop(context);
            onPressed();
          },
          child: Text(
            buttonName,
            style: TextStyle(
              color: isDestructive
                  ? CupertinoColors.systemRed
                  : (CupertinoTheme.of(context).brightness == Brightness.dark
                      ? CupertinoColors.white
                      : CupertinoColors.black),
              fontSize: 16,
            ),
          ),
        ),
      ],
    ),
  );
}

/// iOS-native delete confirmation dialog using [CupertinoAlertDialog].
/// Replaces the legacy `showDeleteChatBox` Material AlertDialog.
Future<void> showDeleteChatBox(
  String title,
  String content,
  BuildContext context,
  VoidCallback deleteForEveryone,
  VoidCallback deleteForMe,
) {
  return showCupertinoDialog(
    context: context,
    builder: (context) => CupertinoAlertDialog(
      title: Text(title),
      content: Text(content),
      actions: [
        CupertinoDialogAction(
          isDestructiveAction: true,
          onPressed: () {
            Navigator.pop(context);
            deleteForEveryone();
          },
          child: const Text('Delete for everyone'),
        ),
        CupertinoDialogAction(
          isDestructiveAction: true,
          onPressed: () {
            Navigator.pop(context);
            deleteForMe();
          },
          child: const Text('Delete for me'),
        ),
        CupertinoDialogAction(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ],
    ),
  );
}
