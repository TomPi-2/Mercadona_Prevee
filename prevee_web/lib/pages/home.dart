import 'package:flutter/material.dart';
import 'package:prevee_web/pages/content.dart';
import '../widgets/header.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          const Header(),
          Expanded(
            child: Container(
              color: Colors.white,
              child: const Center(child: ProductGridView()),
            ),
          ),
        ],
      ),
    );
  }
}
