import 'package:flutter/material.dart';
import 'pages/Homepage.dart';
import 'pages/Food.dart';
import 'pages/CreateNew.dart';
import 'pages/ProfilePage.dart';
import 'pages/Random.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({Key? key}) : super(key: key);

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 1;

  final Color bgColor = const Color(0xFFF1F8E9);

  final List<Widget> _pages = [
    const FoodPage(),
    const Homepage(),
    const ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: _pages[_selectedIndex],
      bottomNavigationBar: Container(
        height: 80,
        decoration: const BoxDecoration(
          color: Color(0xFF4CAF50),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(Icons.restaurant_menu, "Food", 0),
            _buildNavItem(Icons.home, "Home", 1),
            _buildNavItem(Icons.shuffle, "Random", -1, isAction: true),
            _buildNavItem(Icons.person_outline, "Profile", 2),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateNewPage()),
          );
        },
        backgroundColor: const Color(0xFF4CAF50),
        child: const Icon(Icons.add, size: 35, color: Colors.white),
      ),
    );
  }

  Widget _buildNavItem(
    IconData icon,
    String label,
    int index, {
    bool isAction = false,
  }) {
    bool isSelected = _selectedIndex == index && !isAction;
    return GestureDetector(
      onTap: () {
        if (isAction) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const RandomPage()),
          );
        } else {
          setState(() {
            _selectedIndex = index;
          });
        }
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isSelected ? Colors.white : Colors.transparent,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: isSelected ? const Color(0xFF4CAF50) : Colors.white70,
              size: 28,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
