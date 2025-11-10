import 'package:flutter/material.dart';
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
              child: const Center(
                child: Text(
                  'Contenido principal aquí',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}