import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'Detail.dart';
import 'Notification.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Homepage extends StatefulWidget {
  const Homepage({Key? key}) : super(key: key);

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  final Color bgColor = const Color(0xFFF1F8E9);
  final Color primaryGreen = const Color(0xFF4CAF50);

  final Color cardRed = const Color(0xFFE53935);
  final Color cardYellow = const Color(0xFFFF9800);
  final Color cardGreen = const Color(0xFF4CAF50);

  Color _getColorFromString(String colorText) {
    switch (colorText.toLowerCase()) {
      case 'red':
        return cardRed;
      case 'yellow':
        return cardYellow;
      case 'green':
        return cardGreen;
      default:
        return primaryGreen;
    }
  }

  Color _calculateColorFromDate(String expiryDateString) {
    try {
      DateFormat format = DateFormat("dd-MM-yyyy");
      DateTime expiryDate = format.parse(expiryDateString);

      DateTime now = DateTime.now();
      DateTime today = DateTime(now.year, now.month, now.day);

      int difference = expiryDate.difference(today).inDays;
      if (difference <= 3) {
        return cardRed;
      } else if (difference <= 7) {
        return cardYellow;
      } else {
        return cardGreen;
      }
    } catch (e) {
      return cardGreen;
    }
  }

  bool _isExpired(String expiryDateString) {
    try {
      DateFormat format = DateFormat("dd-MM-yyyy");
      DateTime expiryDate = format.parse(expiryDateString);
      DateTime now = DateTime.now();
      DateTime today = DateTime(now.year, now.month, now.day);
      int difference = expiryDate.difference(today).inDays;

      return difference < 0;
    } catch (e) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(children: [_buildHeader(), _buildBodyContent()]),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Stack(
      children: [
        Container(
          height: 280,
          width: double.infinity,
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/HomepageHeader.png'),
              fit: BoxFit.cover,
            ),
          ),
        ),
        Container(
          height: 280,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [Colors.black.withOpacity(0.7), Colors.transparent],
            ),
          ),
        ),
        Positioned(
          top: 40,
          right: 10,
          child: IconButton(
            icon: const Icon(
              Icons.notifications_none,
              color: Colors.white,
              size: 30,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationPage(),
                ),
              );
            },
          ),
        ),
        Positioned(
          bottom: 40,
          left: 0,
          right: 0,
          child: Column(
            children: const [
              Text(
                'Different',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              Text(
                'Kind of Food',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 50),
          Container(
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.warning_amber_rounded,
              size: 100,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'No food data available.',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
          ),
          const SizedBox(height: 60),
        ],
      ),
    );
  }

  Widget _buildBodyContent() {
    return Transform.translate(
      offset: const Offset(0, -25),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.only(
            left: 20,
            right: 20,
            top: 30,
            bottom: 100,
          ),
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('products')
                .where(
                  'userId',
                  isEqualTo: FirebaseAuth.instance.currentUser?.uid,
                )
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError ||
                  !snapshot.hasData ||
                  snapshot.data!.docs.isEmpty) {
                return _buildEmptyState();
              }

              List<Map<String, dynamic>> allItems = [];
              for (var doc in snapshot.data!.docs) {
                Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
                String dateStr = data['expiryDate'] ?? '';

                if (_isExpired(dateStr)) {
                  continue;
                }

                bool isEaten = data['isEaten'] ?? false;
                if (isEaten) continue;

                allItems.add({
                  'id': doc.id,
                  'name': data['name'] ?? '',
                  'date': dateStr,
                  'expiryDate': dateStr,
                  'image': data['image'] ?? '',
                  'category': data['category'] ?? '',
                  'baseColor': _calculateColorFromDate(dateStr),
                  'calories': data['calories'],
                  'manufacturingDate': data['manufacturingDate'],
                  'note': data['note'],
                  'createDate': data['createDate'],
                });
              }

              if (allItems.isEmpty) {
                return _buildEmptyState();
              }

              var foodItems = allItems
                  .where((i) => i['category'] == 'Food')
                  .toList();
              var snackItems = allItems
                  .where((i) => i['category'] == 'Snack')
                  .toList();
              var drinkItems = allItems
                  .where((i) => i['category'] == 'Drink')
                  .toList();
              var fruitItems = allItems
                  .where((i) => i['category'] == 'Fruit')
                  .toList();
              var vegetableItems = allItems
                  .where((i) => i['category'] == 'Vegetable')
                  .toList();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (foodItems.isNotEmpty)
                    _buildCategorySection('Food', foodItems),
                  if (foodItems.isNotEmpty) const SizedBox(height: 25),

                  if (snackItems.isNotEmpty)
                    _buildCategorySection('Snack', snackItems),
                  if (snackItems.isNotEmpty) const SizedBox(height: 25),

                  if (drinkItems.isNotEmpty)
                    _buildCategorySection('Drink', drinkItems),
                  if (drinkItems.isNotEmpty) const SizedBox(height: 25),

                  if (fruitItems.isNotEmpty)
                    _buildCategorySection('Fruit', fruitItems),
                  if (fruitItems.isNotEmpty) const SizedBox(height: 25),

                  if (vegetableItems.isNotEmpty)
                    _buildCategorySection('Vegetable', vegetableItems),
                  if (vegetableItems.isNotEmpty) const SizedBox(height: 25),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildCategorySection(String title, List<Map<String, dynamic>> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: primaryGreen,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Divider(
                color: primaryGreen.withOpacity(0.5),
                thickness: 1.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),
        ScrollableCategoryList(items: items, primaryGreen: primaryGreen),
      ],
    );
  }
}

class ScrollableCategoryList extends StatefulWidget {
  final List<Map<String, dynamic>> items;
  final Color primaryGreen;

  const ScrollableCategoryList({
    Key? key,
    required this.items,
    required this.primaryGreen,
  }) : super(key: key);

  @override
  State<ScrollableCategoryList> createState() => _ScrollableCategoryListState();
}

class _ScrollableCategoryListState extends State<ScrollableCategoryList> {
  final ScrollController _scrollController = ScrollController();
  double _scrollProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.position.maxScrollExtent > 0) {
        setState(() {
          _scrollProgress =
              _scrollController.position.pixels /
              _scrollController.position.maxScrollExtent;
          if (_scrollProgress < 0) _scrollProgress = 0;
          if (_scrollProgress > 1) _scrollProgress = 1;
        });
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool canScroll = widget.items.length > 3;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 170,
          child: ListView.builder(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            physics: canScroll
                ? const BouncingScrollPhysics()
                : const NeverScrollableScrollPhysics(),
            itemCount: widget.items.length,
            itemBuilder: (context, index) {
              return _buildItemCard(widget.items[index]);
            },
          ),
        ),

        if (canScroll)
          Padding(
            padding: const EdgeInsets.only(top: 15),
            child: Container(
              width: double.infinity,
              height: 4,
              decoration: BoxDecoration(
                color: widget.primaryGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Align(
                alignment: Alignment((_scrollProgress * 2) - 1, 0),
                child: Container(
                  width: 60,
                  height: 4,
                  decoration: BoxDecoration(
                    color: widget.primaryGreen.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildItemCard(Map<String, dynamic> item) {
    Color baseColor = item['baseColor'];

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => DetailPage(item: item)),
        );
      },
      child: Container(
        width: 140,
        margin: const EdgeInsets.only(right: 15),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: baseColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: baseColor, width: 1.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 90,
              width: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                image: DecorationImage(
                  image: NetworkImage(item['image']),
                  fit: BoxFit.cover,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 5,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
            const Spacer(),
            Text(
              item['name'],
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              item['date'],
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 5),
          ],
        ),
      ),
    );
  }
}
