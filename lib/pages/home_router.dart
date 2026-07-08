import 'package:flutter/material.dart';

class HomeRouter extends StatelessWidget {
  final String userRole;
  const HomeRouter({super.key, required this.userRole});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text("Home Router - À coder")),
    );
  }
}
