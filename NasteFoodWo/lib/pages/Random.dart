import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'dart:math';
import 'Detail.dart';

class RandomPage extends StatefulWidget {
  const RandomPage({Key? key}) : super(key: key);

  @override
  State<RandomPage> createState() => _RandomPageState();
}

class _RandomPageState extends State<RandomPage> {
  final Color bgColor = const Color(0xFFF1F8E9);
  final Color primaryGreen = const Color(0xFF4CAF50);
  final Color cardRed = const Color(0xFFE53935);

  final ScrollController _scrollController = ScrollController();
  final double itemWidth = 140.0;

  bool _isSpinning = false;
  List<Map<String, dynamic>> _rouletteItems = [];
  Map<String, dynamic>? _winnerItem;
  int _winnerIndex = 0;

  String _selectedCategory = "All";
  final List<String> _categories = [
    'All',
    'Food',
    'Snack',
    'Drink',
    'Fruit',
    'Vegetable',
  ];

  bool _isExpired(String expiryDateString) {
    try {
      DateFormat format = DateFormat("dd-MM-yyyy");
      DateTime expiryDate = format.parse(expiryDateString);
      DateTime now = DateTime.now();
      DateTime today = DateTime(now.year, now.month, now.day);
      return expiryDate.difference(today).inDays < 0;
    } catch (e) {
      return false;
    }
  }

  void _startSpin(List<Map<String, dynamic>> availableItems) {
    if (availableItems.isEmpty || _isSpinning) return;

    setState(() {
      _isSpinning = true;
      _winnerItem = null;
      _rouletteItems = List.generate(
        60,
        (index) => availableItems[Random().nextInt(availableItems.length)],
      );
      _winnerIndex = 45 + Random().nextInt(10);
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;

      double screenWidth = MediaQuery.of(context).size.width;
      double targetOffset =
          (_winnerIndex * itemWidth) + (itemWidth / 2) - (screenWidth / 2);

      double randomJitter = (Random().nextDouble() * 100) - 50;
      targetOffset += randomJitter;

      _scrollController.jumpTo(0);
      _scrollController
          .animateTo(
            targetOffset,
            duration: const Duration(seconds: 5),
            curve: Curves.easeOutQuart,
          )
          .then((_) {
            if (mounted) {
              setState(() {
                _isSpinning = false;
                _winnerItem = _rouletteItems[_winnerIndex];
              });
            }
          });
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('products')
              .where(
                'userId',
                isEqualTo: FirebaseAuth.instance.currentUser?.uid,
              )
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting &&
                _rouletteItems.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            List<Map<String, dynamic>> validItems = [];
            if (snapshot.hasData && snapshot.data != null) {
              for (var doc in snapshot.data!.docs) {
                Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
                String dateStr = data['expiryDate'] ?? '';
                bool isEaten = data['isEaten'] ?? false;
                String catStr = data['category'] ?? '';

                if (!isEaten && !_isExpired(dateStr)) {
                  if (_selectedCategory == 'All' ||
                      catStr == _selectedCategory) {
                    validItems.add({
                      'id': doc.id,
                      'name': data['name'] ?? '',
                      'date': dateStr,
                      'expiryDate': dateStr,
                      'image': data['image'] ?? '',
                      'category': catStr,
                      'baseColor': primaryGreen,
                      'calories': data['calories'],
                      'manufacturingDate': data['manufacturingDate'],
                      'note': data['note'],
                      'createDate': data['createDate'],
                      'isEaten': isEaten,
                    });
                  }
                }
              }
            }

            return Column(
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'Random Food Picker',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                const Text(
                  'Select Category',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 5),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 0,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: primaryGreen, width: 1.5),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedCategory,
                      icon: Icon(Icons.arrow_drop_down, color: primaryGreen),
                      items: _categories.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(
                            value,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        );
                      }).toList(),
                      onChanged: _isSpinning
                          ? null
                          : (newValue) {
                              setState(() {
                                _selectedCategory = newValue!;
                                _winnerItem = null;
                                _rouletteItems = [];
                              });
                            },
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  height: 160,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    border: Border.symmetric(
                      horizontal: BorderSide(
                        color: Colors.grey.shade400,
                        width: 2,
                      ),
                    ),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      if (_rouletteItems.isEmpty)
                        Text(
                          validItems.isEmpty
                              ? 'No items in this category'
                              : 'Press Spin to start!',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey.shade600,
                          ),
                        )
                      else
                        ListView.builder(
                          controller: _scrollController,
                          scrollDirection: Axis.horizontal,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _rouletteItems.length,
                          itemBuilder: (context, index) {
                            var item = _rouletteItems[index];
                            return SizedBox(
                              width: itemWidth,
                              child: Card(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 5,
                                  vertical: 15,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        height: 70,
                                        width: 70,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          image: DecorationImage(
                                            image: NetworkImage(item['image']),
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        item['name'],
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      Container(
                        width: 4,
                        height: double.infinity,
                        color: const Color(0xFFFFB300),
                      ),
                      Positioned(
                        top: 0,
                        child: CustomPaint(
                          size: const Size(20, 15),
                          painter: TrianglePainter(
                            color: const Color(0xFFFFB300),
                            isDown: true,
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        child: CustomPaint(
                          size: const Size(20, 15),
                          painter: TrianglePainter(
                            color: const Color(0xFFFFB300),
                            isDown: false,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      child: _winnerItem != null
                          ? GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        DetailPage(item: _winnerItem!),
                                  ),
                                );
                              },
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text(
                                    'You got!',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(height: 15),
                                  Container(
                                    width: 200,
                                    padding: const EdgeInsets.all(15),
                                    decoration: BoxDecoration(
                                      color: primaryGreen.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(25),
                                      border: Border.all(
                                        color: primaryGreen,
                                        width: 2,
                                      ),
                                    ),
                                    child: Column(
                                      children: [
                                        Container(
                                          height: 120,
                                          width: 120,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            image: DecorationImage(
                                              image: NetworkImage(
                                                _winnerItem!['image'],
                                              ),
                                              fit: BoxFit.cover,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(
                                                  0.1,
                                                ),
                                                blurRadius: 10,
                                                spreadRadius: 2,
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 15),
                                        Text(
                                          _winnerItem!['name'],
                                          style: TextStyle(
                                            fontSize: 22,
                                            fontWeight: FontWeight.w900,
                                            color: primaryGreen,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  const Text(
                                    'Tap to view details',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.black54,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : const SizedBox(),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 20,
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton(
                      onPressed: (_isSpinning || validItems.isEmpty)
                          ? null
                          : () => _startSpin(validItems),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryGreen,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 5,
                      ),
                      child: Text(
                        _isSpinning ? 'Spinning...' : 'Spin!',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class TrianglePainter extends CustomPainter {
  final Color color;
  final bool isDown;

  TrianglePainter({required this.color, required this.isDown});

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()..color = color;
    Path path = Path();
    if (isDown) {
      path.moveTo(0, 0);
      path.lineTo(size.width, 0);
      path.lineTo(size.width / 2, size.height);
    } else {
      path.moveTo(0, size.height);
      path.lineTo(size.width, size.height);
      path.lineTo(size.width / 2, 0);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
