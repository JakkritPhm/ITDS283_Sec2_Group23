import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'Edit.dart';

class DetailPage extends StatelessWidget {
  final Map<String, dynamic> item;

  const DetailPage({Key? key, required this.item}) : super(key: key);

  Future<void> _markAsEaten(BuildContext context) async {
    try {
      await FirebaseFirestore.instance
          .collection('products')
          .doc(item['id'])
          .update({
            'isEaten': true,
            'consumedDate': FieldValue.serverTimestamp(),
          });

      if (context.mounted) {
        Navigator.pop(context);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Marked as eaten successfully!')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error updating: $e')));
    }
  }

  void _showEatenConfirmDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Mark as Consumed',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF4CAF50),
          ),
        ),
        content: const Text('Have you already eaten this food?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'No',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ),
          ElevatedButton(
            onPressed: () => _markAsEaten(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CAF50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'Yes',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteItem(BuildContext context) async {
    try {
      await FirebaseFirestore.instance
          .collection('products')
          .doc(item['id'])
          .delete();
      if (context.mounted) {
        Navigator.pop(context);
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error deleting: $e')));
    }
  }

  void _showDeleteConfirmDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Delete Item',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFFE53935),
          ),
        ),
        content: const Text('Are you sure you want to delete this item?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'No',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ),
          ElevatedButton(
            onPressed: () => _deleteItem(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE53935),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'Yes',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Color baseColor = item['baseColor'] ?? const Color(0xFF4CAF50);
    final Color bgColor = const Color(0xFFF1F8E9);

    String expDateStr = item['expiryDate'] ?? '';
    String mfgDateStr = item['manufacturingDate'] ?? '';
    String createDateStr = 'XX-XX-XXXX';

    if (item['createDate'] != null && item['createDate'] is Timestamp) {
      DateTime createD = (item['createDate'] as Timestamp).toDate();
      createDateStr = DateFormat("dd-MM-yyyy").format(createD);
    }

    int daysLeft = 0;
    int totalLife = 0;

    try {
      DateFormat format = DateFormat("dd-MM-yyyy");
      DateTime expDate = format.parse(expDateStr);
      DateTime today = DateTime(
        DateTime.now().year,
        DateTime.now().month,
        DateTime.now().day,
      );

      daysLeft = expDate.difference(today).inDays;

      DateTime startDate = today;
      if (mfgDateStr.isNotEmpty) {
        startDate = format.parse(mfgDateStr);
      } else if (createDateStr != 'XX-XX-XXXX') {
        startDate = format.parse(createDateStr);
      }

      totalLife = expDate.difference(startDate).inDays;
      if (totalLife < 0) totalLife = 0;
    } catch (e) {
      daysLeft = 0;
      totalLife = 0;
    }

    String noteText =
        (item['note'] == null || item['note'].toString().trim().isEmpty)
        ? 'No Description'
        : item['note'];

    String daysLeftText = daysLeft < 0 ? 'Expired' : '$daysLeft Days Left';
    Color daysLeftColor = daysLeft < 0 ? Colors.red : baseColor;

    return Scaffold(
      backgroundColor: bgColor,
      floatingActionButton: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildSquareButton(Icons.check, const Color(0xFF4CAF50), () {
            _showEatenConfirmDialog(context);
          }),

          const SizedBox(width: 12),

          _buildSquareButton(Icons.edit, const Color(0xFFFF9800), () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => EditPage(item: item)),
            );
          }),

          const SizedBox(width: 12),

          _buildSquareButton(Icons.delete, const Color(0xFFE53935), () {
            _showDeleteConfirmDialog(context);
          }),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,

      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 120),
            physics: const BouncingScrollPhysics(),
            child: Stack(
              children: [
                ClipPath(
                  clipper: HeaderCurveClipper(),
                  child: Container(
                    height: 380,
                    width: double.infinity,
                    color: baseColor.withOpacity(0.3),
                  ),
                ),

                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: MediaQuery.of(context).padding.top + 10),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: TextButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(
                          Icons.arrow_back,
                          color: Colors.black,
                          size: 24,
                        ),
                        label: const Text(
                          'Detail',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                        ),
                      ),
                    ),

                    Align(
                      alignment: Alignment.centerRight,
                      child: Container(
                        margin: const EdgeInsets.only(right: 24, top: 10),
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: baseColor, width: 3),
                          image: DecorationImage(
                            image: NetworkImage(item['image'] ?? ''),
                            fit: BoxFit.cover,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 120),

                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 0,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Expanded(
                                child: Text(
                                  item['name'] ?? '',
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: baseColor,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                daysLeftText,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: daysLeftColor,
                                ),
                              ),
                            ],
                          ),

                          Divider(color: baseColor, thickness: 1.5, height: 20),

                          Text(
                            noteText,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          const SizedBox(height: 25),

                          _buildInfoRow('Category', item['category'] ?? '-'),
                          _buildInfoRow(
                            'Calories',
                            item['calories'] != null
                                ? '${item['calories']} kcal'
                                : '-',
                          ),
                          _buildInfoRow('Create Date', createDateStr),
                          _buildInfoRow(
                            'Manufacturing Date',
                            mfgDateStr.isEmpty ? '-' : mfgDateStr,
                          ),
                          _buildInfoRow('Expire Date', expDateStr),

                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              children: [
                                const Text(
                                  'Total Life Time : ',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                Text(
                                  '$totalLife Days',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: baseColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '$label : ',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            TextSpan(
              text: value,
              style: const TextStyle(fontSize: 16, color: Colors.black87),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSquareButton(IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Icon(icon, color: Colors.white, size: 24),
      ),
    );
  }
}

class HeaderCurveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.lineTo(0, size.height - 60);
    path.quadraticBezierTo(
      size.width * 0.4,
      size.height + 20,
      size.width * 0.7,
      size.height - 60,
    );
    path.quadraticBezierTo(
      size.width * 0.9,
      size.height - 110,
      size.width,
      size.height - 100,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
