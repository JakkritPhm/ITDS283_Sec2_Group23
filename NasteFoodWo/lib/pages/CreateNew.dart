import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';

class CreateNewPage extends StatefulWidget {
  const CreateNewPage({Key? key}) : super(key: key);

  @override
  State<CreateNewPage> createState() => _CreateNewPageState();
}

class _CreateNewPageState extends State<CreateNewPage> {
  final Color bgColor = const Color(0xFFF1F8E9);
  final Color primaryGreen = const Color(0xFF4CAF50);

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _caloriesController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  final TextEditingController _mfgDD = TextEditingController();
  final TextEditingController _mfgMM = TextEditingController();
  final TextEditingController _mfgYYYY = TextEditingController();

  final TextEditingController _expDD = TextEditingController();
  final TextEditingController _expMM = TextEditingController();
  final TextEditingController _expYYYY = TextEditingController();

  String _selectedCategory = 'Food';
  final List<String> _categories = [
    'Food',
    'Snack',
    'Drink',
    'Fruit',
    'Vegetable',
  ];

  String? _nameError;
  String? _caloriesError;
  String? _expDateError;
  String? _mfgDateError;
  String? _imageError;

  bool _isLoading = false;

  XFile? _imageFile;
  final ImagePicker _picker = ImagePicker();

  final String cloudName = "doa1txjr3";
  final String uploadPreset = "NasteFoodWo";

  bool _isNumericOnly(String str) {
    return RegExp(r'^\d+$').hasMatch(str);
  }

  bool _isValidRealDate(String dd, String mm, String yyyy) {
    if (dd.isEmpty || mm.isEmpty || yyyy.isEmpty) return false;

    if (!_isNumericOnly(dd) || !_isNumericOnly(mm) || !_isNumericOnly(yyyy))
      return false;

    int? d = int.tryParse(dd);
    int? m = int.tryParse(mm);
    int? y = int.tryParse(yyyy);

    if (d == null || m == null || y == null) return false;
    if (m < 1 || m > 12) return false;
    if (d < 1 || d > 31) return false;

    try {
      DateTime date = DateTime(y, m, d);
      return date.year == y && date.month == m && date.day == d;
    } catch (e) {
      return false;
    }
  }

  void _showImageSourceActionSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final XFile? pickedFile = await _picker.pickImage(
      source: source,
      imageQuality: 70,
    );
    if (pickedFile != null) {
      setState(() {
        _imageFile = pickedFile;
        _imageError = null;
      });
    }
  }

  Future<String?> _uploadToCloudinary(XFile file) async {
    final url = Uri.parse(
      'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
    );

    final request = http.MultipartRequest('POST', url)
      ..fields['upload_preset'] = uploadPreset;
    final bytes = await file.readAsBytes();
    request.files.add(
      http.MultipartFile.fromBytes('file', bytes, filename: file.name),
    );

    final response = await request.send();
    final responseData = await response.stream.toBytes();
    final responseString = String.fromCharCodes(responseData);
    final jsonMap = jsonDecode(responseString);

    if (response.statusCode == 200) {
      return jsonMap['secure_url'];
    } else {
      String exactError = jsonMap['error']['message'] ?? 'Unknown Error';
      print('Cloudinary Error: $exactError');
      throw Exception("Cloudinary says: $exactError");
    }
  }

  void _submitForm() async {
    setState(() {
      _nameError = null;
      _caloriesError = null;
      _expDateError = null;
      _mfgDateError = null;
      _imageError = null;
    });

    bool hasError = false;

    if (_nameController.text.trim().isEmpty) {
      _nameError = 'Please enter food name';
      hasError = true;
    }

    String calText = _caloriesController.text.trim();
    if (calText.isNotEmpty) {
      if (!_isNumericOnly(calText)) {
        _caloriesError = 'Numbers only (No minus or letters)';
        hasError = true;
      } else {
        int? cal = int.tryParse(calText);
        if (cal == null || cal < 0) {
          _caloriesError = 'Invalid calories';
          hasError = true;
        }
      }
    }

    if (_imageFile == null) {
      _imageError = 'Please upload a food picture';
      hasError = true;
    }

    if (!_isValidRealDate(_expDD.text, _expMM.text, _expYYYY.text)) {
      _expDateError = 'Invalid expire date (Real date only)';
      hasError = true;
    }

    bool hasMfgInput =
        _mfgDD.text.isNotEmpty ||
        _mfgMM.text.isNotEmpty ||
        _mfgYYYY.text.isNotEmpty;
    if (hasMfgInput) {
      if (!_isValidRealDate(_mfgDD.text, _mfgMM.text, _mfgYYYY.text)) {
        _mfgDateError = 'Invalid manufacturing date (Real date only)';
        hasError = true;
      }
    }

    if (hasError) return;

    setState(() => _isLoading = true);

    try {
      String? imageUrl = await _uploadToCloudinary(_imageFile!);

      if (imageUrl == null) {
        throw Exception("Failed to upload image to Cloudinary");
      }

      String formattedExpDate =
          "${_expDD.text.padLeft(2, '0')}-${_expMM.text.padLeft(2, '0')}-${_expYYYY.text}";
      int? finalCalories = calText.isNotEmpty ? int.parse(calText) : null;
      String? finalMfgDate = hasMfgInput
          ? "${_mfgDD.text.padLeft(2, '0')}-${_mfgMM.text.padLeft(2, '0')}-${_mfgYYYY.text}"
          : null;
      String? finalNote = _noteController.text.trim().isNotEmpty
          ? _noteController.text.trim()
          : null;
      String currentUserId = FirebaseAuth.instance.currentUser!.uid;

      await FirebaseFirestore.instance.collection('products').add({
        'userId': currentUserId,
        'name': _nameController.text.trim(),
        'category': _selectedCategory,
        'calories': finalCalories,
        'manufacturingDate': finalMfgDate,
        'expiryDate': formattedExpDate,
        'image': imageUrl,
        'note': finalNote,
        'createDate': FieldValue.serverTimestamp(),
      });

      if (mounted) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
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
          'Create New',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLabel('Food Name', isRequired: true),
                  _buildTextField(
                    _nameController,
                    'Ex. Chicken',
                    errorText: _nameError,
                  ),

                  _buildLabel('Category'),
                  _buildDropdown(),

                  _buildLabel('Calories'),
                  _buildTextField(
                    _caloriesController,
                    'Ex. 670',
                    isNumber: true,
                    errorText: _caloriesError,
                  ),

                  _buildLabel('Manufacturing Date'),
                  _buildDateRow(
                    _mfgDD,
                    _mfgMM,
                    _mfgYYYY,
                    errorText: _mfgDateError,
                  ),

                  _buildLabel('Expire Date', isRequired: true),
                  _buildDateRow(
                    _expDD,
                    _expMM,
                    _expYYYY,
                    errorText: _expDateError,
                  ),

                  _buildLabel('Food Picture', isRequired: true),
                  _buildImagePicker(),

                  _buildLabel('Note'),
                  _buildNoteField(),

                  const SizedBox(height: 30),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FloatingActionButton(
                      onPressed: _submitForm,
                      backgroundColor: primaryGreen,
                      child: const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
    );
  }

  Widget _buildLabel(String text, {bool isRequired = false}) {
    return Padding(
      padding: const EdgeInsets.only(top: 15, bottom: 8),
      child: Text.rich(
        TextSpan(
          text: text,
          style: const TextStyle(fontWeight: FontWeight.bold),
          children: [
            if (isRequired)
              const TextSpan(
                text: ' *',
                style: TextStyle(color: Colors.red),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String hint, {
    bool isNumber = false,
    String? errorText,
    int? maxLength,
  }) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      inputFormatters: isNumber
          ? [FilteringTextInputFormatter.digitsOnly]
          : null,
      maxLength: maxLength,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        errorText: errorText,
        counterText: "",
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedCategory,
          isExpanded: true,
          items: _categories
              .map((c) => DropdownMenuItem(value: c, child: Text(c)))
              .toList(),
          onChanged: (v) => setState(() => _selectedCategory = v!),
        ),
      ),
    );
  }

  Widget _buildDateRow(
    TextEditingController d,
    TextEditingController m,
    TextEditingController y, {
    String? errorText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _buildTextField(d, 'DD', isNumber: true, maxLength: 2),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildTextField(m, 'MM', isNumber: true, maxLength: 2),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: _buildTextField(y, 'YYYY', isNumber: true, maxLength: 4),
            ),
          ],
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              errorText,
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),
      ],
    );
  }

  Widget _buildImagePicker() {
    return GestureDetector(
      onTap: _showImageSourceActionSheet,
      child: Container(
        height: 150,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: _imageError != null ? Colors.red : Colors.transparent,
          ),
        ),
        child: _imageFile != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: kIsWeb
                    ? Image.network(_imageFile!.path, fit: BoxFit.cover)
                    : Image.file(File(_imageFile!.path), fit: BoxFit.cover),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.upload, color: Colors.grey.shade400, size: 40),
                  const SizedBox(height: 8),
                  Text(
                    'Tap to upload picture',
                    style: TextStyle(color: Colors.grey.shade500),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildNoteField() {
    return TextField(
      controller: _noteController,
      maxLines: 4,
      decoration: InputDecoration(
        hintText: 'Description',
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
