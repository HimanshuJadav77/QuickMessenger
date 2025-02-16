import 'package:flutter/material.dart';

class CustomCard extends StatelessWidget {
  const CustomCard({
    super.key,
    required this.username,
    required this.imageurl,
    this.about,
    required this.color,
    required this.trailing,
    required this.subtitle,
  });

  // ignore: prefer_typing_uninitialized_variables
  final imageurl;

  // ignore: prefer_typing_uninitialized_variables
  final username;

  // ignore: prefer_typing_uninitialized_variables
  final about;
  final Color color;
  final Widget trailing;

  // ignore: prefer_typing_uninitialized_variables
  final Widget? subtitle;

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(),
      color: color,
      child: Padding(
        padding: const EdgeInsets.all(5.0),
        child: ListTile(
          trailing: trailing,
          title: Text(
            username,
            style: TextStyle(fontSize: 18),
          ),
          subtitle: subtitle,
          leading: InkWell(
              child: CircleAvatar(
                  radius: 30,
                  child: ClipOval(
                    child: Image.network(
                      width: 56,
                      height: MediaQuery.of(context).size.height,
                      fit: BoxFit.cover,
                      imageurl,
                      filterQuality: FilterQuality.high,
                    ),
                  ))),
        ),
      ),
    );
  }
}
