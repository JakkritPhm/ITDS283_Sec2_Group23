import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'dart:math';
import 'LoginPage.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final Color bgColor = const Color(0xFFF1F8E9);
  final Color primaryGreen = const Color(0xFF4CAF50);

  final Color boxGreen = const Color(0xFFC8E6C9);
  final Color textGreen = const Color(0xFF388E3C);
  final Color boxYellow = const Color(0xFFFFE082);
  final Color textYellow = const Color(0xFFF57C00);
  final Color boxRed = const Color(0xFFFFCDD2);
  final Color textRed = const Color(0xFFD32F2F);
  final Color boxBlue = const Color(0xFFBBDEFB);
  final Color textBlue = const Color(0xFF1976D2);

  int _getDaysLeft(String expiryDateString) {
    try {
      DateFormat format = DateFormat("dd-MM-yyyy");
      DateTime expiryDate = format.parse(expiryDateString);
      DateTime now = DateTime.now();
      DateTime today = DateTime(now.year, now.month, now.day);
      return expiryDate.difference(today).inDays;
    } catch (e) {
      return 999;
    }
  }

  bool _isToday(Timestamp? timestamp) {
    if (timestamp == null) return false;
    DateTime date = timestamp.toDate();
    DateTime now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;
    final String userEmail = user?.email ?? 'Unknown User';

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('products')
              .where('userId', isEqualTo: user?.uid)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            int totalFood = 0;
            int expiring = 0;
            int expired = 0;
            int todayCal = 0;
            int totalCal = 0;
            Map<String, int> categoryCount = {};

            if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
              for (var doc in snapshot.data!.docs) {
                Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
                String dateStr = data['expiryDate'] ?? '';
                bool isEaten = data['isEaten'] ?? false;
                int calories = data['calories'] != null
                    ? int.tryParse(data['calories'].toString()) ?? 0
                    : 0;
                String category = data['category'] ?? 'Other';
                Timestamp? consumedDate = data['consumedDate'] as Timestamp?;

                int daysLeft = _getDaysLeft(dateStr);

                if (!isEaten) {
                  if (daysLeft >= 0) {
                    totalFood++;
                    if (daysLeft <= 7) {
                      expiring++;
                    }
                  } else {
                    expired++;
                  }
                } else {
                  totalCal += calories;
                  if (_isToday(consumedDate)) {
                    todayCal += calories;
                  }

                  categoryCount[category] = (categoryCount[category] ?? 0) + 1;
                }
              }
            }

            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 30,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      'User Account Summary',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      userEmail,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 30),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildStatBox(
                          'Total Food',
                          totalFood.toString(),
                          boxGreen,
                          textGreen,
                        ),
                        const SizedBox(width: 12),
                        _buildStatBox(
                          'Expiring',
                          expiring.toString(),
                          boxYellow,
                          textYellow,
                        ),
                        const SizedBox(width: 12),
                        _buildStatBox(
                          'Expired',
                          expired.toString(),
                          boxRed,
                          textRed,
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildStatBox(
                          'Today Cal.',
                          todayCal.toString(),
                          boxBlue,
                          textBlue,
                        ),
                        const SizedBox(width: 12),
                        _buildStatBox(
                          'Total Cal.',
                          totalCal.toString(),
                          boxBlue,
                          textBlue,
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),
                    const Text(
                      'Consumed Food Summary',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 40),
                    _buildPieChartSection(categoryCount),
                    const SizedBox(height: 50),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _logout,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE53935),
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: const Text(
                          'Logout',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatBox(
    String title,
    String value,
    Color bgColor,
    Color textColor,
  ) {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(color: textColor.withOpacity(0.3), width: 1),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: textColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPieChartSection(Map<String, int> categoryCount) {
    if (categoryCount.isEmpty) {
      return Container(
        height: 200,
        alignment: Alignment.center,
        child: Text(
          'No food consumed yet.',
          style: TextStyle(color: Colors.grey.shade600),
        ),
      );
    }

    final List<Color> chartColors = [
      const Color(0xFF4CAF50),
      const Color(0xFFFF9800),
      const Color(0xFF2196F3),
      const Color(0xFFE91E63),
      const Color(0xFF9C27B0),
      const Color(0xFF00BCD4),
    ];

    int totalItems = categoryCount.values.fold(0, (sum, item) => sum + item);
    List<MapEntry<String, int>> sortedCategories =
        categoryCount.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      children: [
        SizedBox(
          height: 200,
          width: 200,
          child: CustomPaint(
            painter: DonutChartPainter(
              categories: sortedCategories,
              colors: chartColors,
              total: totalItems,
            ),
          ),
        ),
        const SizedBox(height: 40),
        Wrap(
          spacing: 15,
          runSpacing: 10,
          alignment: WrapAlignment.center,
          children: List.generate(sortedCategories.length, (index) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: chartColors[index % chartColors.length],
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  '${sortedCategories[index].key} (${sortedCategories[index].value})',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            );
          }),
        ),
      ],
    );
  }
}

class DonutChartPainter extends CustomPainter {
  final List<MapEntry<String, int>> categories;
  final List<Color> colors;
  final int total;

  DonutChartPainter({
    required this.categories,
    required this.colors,
    required this.total,
  });

  @override
  void paint(Canvas canvas, Size size) {
    double startAngle = -pi / 2;
    final Rect rect = Rect.fromLTWH(0, 0, size.width, size.height);

    for (int i = 0; i < categories.length; i++) {
      final sweepAngle = (categories[i].value / total) * 2 * pi;
      final paint = Paint()
        ..color = colors[i % colors.length]
        ..style = PaintingStyle.stroke
        ..strokeWidth = 40;

      canvas.drawArc(rect, startAngle, sweepAngle, false, paint);

      final gapPaint = Paint()
        ..color = const Color(0xFFF1F8E9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 42;
      canvas.drawArc(
        rect,
        startAngle + sweepAngle - 0.05,
        0.05,
        false,
        gapPaint,
      );

      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
