import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'Detail.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({Key? key}) : super(key: key);

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  final Color bgColor = const Color(0xFFF1F8E9);
  final Color primaryGreen = const Color(0xFF4CAF50);
  final Color textOrange = const Color(0xFFFF9800);
  final Color textRed = const Color(0xFFE53935);

  int _selectedTabIndex = 0; // 0: All, 1: Expiring, 2: Expired

  // ฟังก์ชันคำนวณจำนวนวันที่เหลือ
  int _getDaysLeft(String expiryDateString) {
    try {
      DateFormat format = DateFormat("dd-MM-yyyy");
      DateTime expiryDate = format.parse(expiryDateString);
      DateTime now = DateTime.now();
      DateTime today = DateTime(now.year, now.month, now.day);
      return expiryDate.difference(today).inDays;
    } catch (e) {
      return 999; // ถ้า Error ให้ถือว่ายังไม่หมดอายุ
    }
  }

  // คำนวณสีสำหรับส่งไปหน้า Detail
  Color _calculateColorFromDate(int daysLeft) {
    if (daysLeft < 0) return textRed; // หมดอายุแล้ว
    if (daysLeft <= 3) return textRed; // แดง (ใกล้หมดมาก)
    if (daysLeft <= 7) return textOrange; // ส้ม (เริ่มเตือน)
    return primaryGreen;
  }

  // ฟังก์ชันแปลงเวลาสำหรับโชว์ใน Notification
  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return '';
    DateTime date = timestamp.toDate();
    return DateFormat("dd MMMM yyyy  HH:mm").format(date);
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
        title: const Text(
          'Notification',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
      ),
      body: Column(
        children: [
          _buildTabs(),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('products')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return _buildEmptyState();
                }

                // กรองเฉพาะรายการที่ต้องแจ้งเตือน
                List<Map<String, dynamic>> notificationItems = [];

                for (var doc in snapshot.data!.docs) {
                  Map<String, dynamic> data =
                      doc.data() as Map<String, dynamic>;
                  String dateStr = data['expiryDate'] ?? '';
                  int daysLeft = _getDaysLeft(dateStr);

                  // ถ้าเหลือมากกว่า 7 วันแปลว่าปลอดภัย (สีเขียว) ไม่ต้องเตือน
                  if (daysLeft > 7) continue;

                  bool isExpired = daysLeft < 0;

                  // กรองตาม Tab ที่เลือก
                  if (_selectedTabIndex == 1 && isExpired)
                    continue; // Tab Expiring ไม่โชว์ของหมดอายุ
                  if (_selectedTabIndex == 2 && !isExpired)
                    continue; // Tab Expired โชว์เฉพาะหมดอายุ

                  notificationItems.add({
                    'id': doc.id,
                    'name': data['name'] ?? '',
                    'date': dateStr,
                    'expiryDate': dateStr,
                    'image': data['image'] ?? '',
                    'category': data['category'] ?? '',
                    'baseColor': _calculateColorFromDate(daysLeft),
                    'calories': data['calories'],
                    'manufacturingDate': data['manufacturingDate'],
                    'note': data['note'],
                    'createDate': data['createDate'],
                    'daysLeft': daysLeft,
                    'isExpired': isExpired,
                  });
                }

                if (notificationItems.isEmpty) {
                  return _buildEmptyState();
                }

                // เรียงลำดับจากใกล้หมดอายุสุดไปหาช้าสุด
                notificationItems.sort(
                  (a, b) =>
                      (a['daysLeft'] as int).compareTo(b['daysLeft'] as int),
                );

                return ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  itemCount: notificationItems.length,
                  itemBuilder: (context, index) {
                    return _buildNotificationItem(notificationItems[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade300, width: 2),
        ),
      ),
      child: Row(
        children: [
          _buildTabItem("All", 0),
          _buildTabItem("Expiring", 1),
          _buildTabItem("Expired", 2),
        ],
      ),
    );
  }

  Widget _buildTabItem(String title, int index) {
    bool isSelected = _selectedTabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedTabIndex = index;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 15),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected ? primaryGreen : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? primaryGreen : Colors.grey.shade400,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationItem(Map<String, dynamic> item) {
    bool isExpired = item['isExpired'];
    int daysLeft = item['daysLeft'];
    String name = item['name'];

    // ตั้งค่าข้อมูลสำหรับแสดงผล
    Color statusColor = isExpired ? textRed : textOrange;
    String titleText = isExpired ? '$name is Expired' : '$name is Expiring';
    String subtitleText = isExpired
        ? 'Expired'
        : '$daysLeft days left before it expires';
    String timestamp = _formatTimestamp(
      item['createDate'],
    ); // ใช้เวลาสร้างเป็น Timestamp แจ้งเตือนอิงตามแบบ

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => DetailPage(item: item)),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Colors.grey.shade300, width: 1),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.chat_bubble_outline, color: statusColor, size: 24),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titleText,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    subtitleText,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 15),
                  Text(
                    timestamp,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.black87),
          ],
        ),
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
              Icons.notifications,
              size: 100,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'No notification to show, check again later.',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
          ),
          const SizedBox(height: 60), // ดันขึ้นนิดหน่อยให้สมดุล
        ],
      ),
    );
  }
}
