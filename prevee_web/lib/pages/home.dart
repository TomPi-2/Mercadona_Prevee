import 'package:flutter/material.dart';
import 'package:prevee_web/pages/lists.dart';
import 'package:prevee_web/pages/recipes.dart';
import '../widgets/header.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const CombinedListsPage(),
    RecipesPage(),
  ];

  void _onNavigate(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Header(selectedIndex: _selectedIndex, onNavigate: _onNavigate),
          Expanded(child: _pages[_selectedIndex]),
        ],
      ),
    );
  }
}
