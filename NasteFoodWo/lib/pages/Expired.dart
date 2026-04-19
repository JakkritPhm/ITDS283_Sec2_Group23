import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'Detail.dart';

class ExpiredPage extends StatefulWidget {
  const ExpiredPage({Key? key}) : super(key: key);

  @override
  State<ExpiredPage> createState() => _ExpiredPageState();
}

class _ExpiredPageState extends State<ExpiredPage> {
  String _searchQuery = "";
  String _selectedCategory = "All";

  final List<String> _categories = [
    'All',
    'Food',
    'Snack',
    'Drink',
    'Fruit',
    'Vegetable',
  ];

  final Color primaryGreen = const Color(0xFF4CAF50);
  final Color bgColor = const Color(0xFFF1F8E9);
  final Color cardRed = const Color(0xFFE53935);

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

  Future<void> _deleteAllExpired() async {
    try {
      var snapshot = await FirebaseFirestore.instance
          .collection('products')
          .where('userId', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
          .get();

      var batch = FirebaseFirestore.instance.batch();
      int deleteCount = 0;

      for (var doc in snapshot.docs) {
        Map<String, dynamic> data = doc.data();
        String dateStr = data['expiryDate'] ?? '';
        bool isEaten = data['isEaten'] ?? false;

        if (_isExpired(dateStr) && !isEaten) {
          batch.delete(doc.reference);
          deleteCount++;
        }
      }

      if (deleteCount > 0) {
        await batch.commit();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Deleted $deleteCount expired items successfully.'),
            ),
          );
        }
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
        Navigator.pop(context);
      }
    }
  }

  void _showDeleteAllDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Delete All Expired?',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
        ),
        content: const Text(
          'Are you sure you want to permanently delete ALL expired items? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ),
          ElevatedButton(
            onPressed: _deleteAllExpired,
            style: ElevatedButton.styleFrom(
              backgroundColor: cardRed,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'Delete All',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.warning_amber_rounded,
              size: 80,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'No food data available.',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 16),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.black),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Expired',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(Icons.delete_sweep, color: cardRed, size: 28),
                    onPressed: _showDeleteAllDialog,
                    tooltip: 'Delete All Expired Items',
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  color: primaryGreen.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: TextField(
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Value',
                    hintStyle: TextStyle(color: primaryGreen),
                    prefixIcon: Icon(Icons.search, color: primaryGreen),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minWidth: MediaQuery.of(context).size.width - 40,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: _categories.map((category) {
                      bool isSelected = _selectedCategory == category;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedCategory = category;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            category,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isSelected
                                  ? primaryGreen
                                  : Colors.grey.shade400,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
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
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return _buildEmptyState();
                    }

                    var items = snapshot.data!.docs
                        .map((doc) {
                          Map<String, dynamic> data =
                              doc.data() as Map<String, dynamic>;
                          String dateStr = data['expiryDate'] ?? '';
                          return {
                            'id': doc.id,
                            'name': data['name'] ?? '',
                            'date': dateStr,
                            'expiryDate': dateStr,
                            'image': data['image'] ?? '',
                            'category': data['category'] ?? '',
                            'baseColor': cardRed,
                            'calories': data['calories'],
                            'manufacturingDate': data['manufacturingDate'],
                            'note': data['note'],
                            'createDate': data['createDate'],
                            'isEaten': data['isEaten'] ?? false,
                          };
                        })
                        .where((item) {
                          String dateStr = item['expiryDate'] ?? '';
                          String nameStr = item['name'] ?? '';
                          String catStr = item['category'] ?? '';
                          bool isEaten = item['isEaten'];

                          if (isEaten) return false;
                          if (!_isExpired(dateStr)) return false;

                          if (_selectedCategory != 'All' &&
                              catStr != _selectedCategory) {
                            return false;
                          }

                          if (_searchQuery.isNotEmpty) {
                            if (!nameStr.toLowerCase().contains(
                              _searchQuery.toLowerCase(),
                            )) {
                              return false;
                            }
                          }

                          return true;
                        })
                        .toList();

                    if (items.isEmpty) {
                      return _buildEmptyState();
                    }

                    return GridView.builder(
                      physics: const BouncingScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 1.0,
                            crossAxisSpacing: 15,
                            mainAxisSpacing: 15,
                          ),
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        var item = items[index];
                        Color cardColor = item['baseColor'];

                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => DetailPage(item: item),
                              ),
                            );
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: cardColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: cardColor, width: 1.5),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    height: 130,
                                    width: 130,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      image: DecorationImage(
                                        image: NetworkImage(
                                          item['image'] ?? '',
                                        ),
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
                                  const SizedBox(height: 12),
                                  Text(
                                    item['name'] ?? '',
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.black87,
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
