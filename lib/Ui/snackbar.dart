import 'package:flutter/material.dart';

showSnackBar(BuildContext context, String text) {
  return ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      elevation: 10,
      shape: OutlineInputBorder(borderRadius: BorderRadius.circular(50)),
      backgroundColor: Colors.black,
      duration: const Duration(seconds: 2),
      content: Text(
        text,
        style: const TextStyle(color: Colors.white),
      ),
    ),
  );
}
