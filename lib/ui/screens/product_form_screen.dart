import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../providers/app_state.dart';

class ProductFormScreen extends StatefulWidget {
  final Product? product;

  const ProductFormScreen({super.key, this.product});

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _barcodeController;
  String? _selectedCategoryId;
  String? _imagePath;
  bool _trackStock = true;
  List<TextEditingController> _additionalBarcodeControllers = [];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product?.name ?? '');
    _priceController = TextEditingController(text: widget.product?.price.toStringAsFixed(0) ?? '');
    _barcodeController = TextEditingController(text: widget.product?.barcode ?? '');
    _selectedCategoryId = widget.product?.categoryId;
    _imagePath = widget.product?.imagePath;
    _trackStock = widget.product?.trackStock ?? true;
    _additionalBarcodeControllers = (widget.product?.additionalBarcodes ?? [])
        .map((b) => TextEditingController(text: b))
        .toList();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _barcodeController.dispose();
    for (var c in _additionalBarcodeControllers) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final appDir = await getApplicationDocumentsDirectory();
      final imagesDir = Directory(path.join(appDir.path, 'product_images'));
      if (!await imagesDir.exists()) {
        await imagesDir.create(recursive: true);
      }

      final fileName = '${DateTime.now().millisecondsSinceEpoch}${path.extension(pickedFile.path)}';
      final savedImage = await File(pickedFile.path).copy(path.join(imagesDir.path, fileName));

      setState(() {
        _imagePath = savedImage.path;
      });
    }
  }

  void _save() async {
    if (_formKey.currentState!.validate()) {
      final state = context.read<AppState>();
      
      if (_selectedCategoryId == null && state.categories.isEmpty) {
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Avval kategoriya yarating')));
         return;
      }
      
      if (_selectedCategoryId == null && state.categories.isNotEmpty) {
        _selectedCategoryId = state.categories.first.id;
      }

      final name = _nameController.text;
      final price = double.tryParse(_priceController.text) ?? 0.0;
      final barcode = _barcodeController.text;
      final additionalBarcodes = _additionalBarcodeControllers
          .map((c) => c.text)
          .where((t) => t.isNotEmpty)
          .toList();

      if (widget.product == null) {
        final product = Product.create(
          name,
          price,
          _selectedCategoryId!,
          barcode,
          imagePath: _imagePath,
          trackStock: _trackStock,
        ).copyWith(additionalBarcodes: additionalBarcodes);
        await state.addProduct(product);
      } else {
        final updatedProduct = widget.product!.copyWith(
          name: name,
          price: price,
          categoryId: _selectedCategoryId,
          barcode: barcode,
          additionalBarcodes: additionalBarcodes,
          imagePath: _imagePath,
          trackStock: _trackStock,
        );
        await state.updateProduct(updatedProduct);
      }

      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset('assets/icon.png', width: 30, height: 30, fit: BoxFit.cover),
            ),
            const SizedBox(width: 12),
            Text(widget.product == null ? 'Yangi Mahsulot' : 'Tahrirlash'),
          ],
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E293B),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildImagePicker(),
              const SizedBox(height: 32),
              _buildTextField('Mahsulot nomi', _nameController, Icons.inventory_2_outlined),
              const SizedBox(height: 20),
              _buildCategoryDropdown(state),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(child: _buildTextField('Narxi (so\'m)', _priceController, Icons.payments_outlined, isNumber: true)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildTextField('Asosiy Shtrix-kod', _barcodeController, Icons.qr_code_scanner_outlined)),
                ],
              ),
              const SizedBox(height: 20),
              _buildAdditionalBarcodes(),
              const SizedBox(height: 20),
              _buildTrackStockToggle(),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('SAQLASH', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePicker() {
    return Center(
      child: InkWell(
        onTap: _pickImage,
        borderRadius: BorderRadius.circular(30),
        child: Stack(
          children: [
            Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10))],
                image: _imagePath != null ? DecorationImage(image: FileImage(File(_imagePath!)), fit: BoxFit.cover) : null,
              ),
              child: _imagePath == null ? const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_a_photo_outlined, size: 48, color: Color(0xFF94A3B8)),
                  SizedBox(height: 8),
                  Text('Rasm yuklash', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                ],
              ) : null,
            ),
            if (_imagePath != null)
              Positioned(
                top: 8,
                right: 8,
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.black.withOpacity(0.5),
                  child: IconButton(
                    icon: const Icon(Icons.close, size: 18, color: Colors.white),
                    onPressed: () => setState(() => _imagePath = null),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon, {bool isNumber = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF64748B))),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade100),
          ),
          child: TextFormField(
            controller: controller,
            keyboardType: isNumber ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: const Color(0xFF6366F1), size: 20),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
            ),
            validator: (v) => v == null || v.isEmpty ? 'Maydonni to\'ldiring' : null,
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryDropdown(AppState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Kategoriya', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF64748B))),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade100),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedCategoryId,
              hint: const Text('Kategoriyani tanlang'),
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF6366F1)),
              items: state.categories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
              onChanged: (v) => setState(() => _selectedCategoryId = v),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAdditionalBarcodes() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Qo\'shimcha Shtrix-kodlar', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF64748B))),
            TextButton.icon(
              onPressed: () => setState(() => _additionalBarcodeControllers.add(TextEditingController())),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Qo\'shish', style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ..._additionalBarcodeControllers.asMap().entries.map((entry) {
          final idx = entry.key;
          final controller = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade100),
              ),
              child: TextFormField(
                controller: controller,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.qr_code, color: Color(0xFF94A3B8), size: 20),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent, size: 20),
                    onPressed: () => setState(() => _additionalBarcodeControllers.removeAt(idx)),
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(12),
                  hintText: 'Shtrix-kodni kiriting',
                  hintStyle: const TextStyle(fontSize: 13),
                ),
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildTrackStockToggle() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: SwitchListTile(
        title: const Text('Ombor hisobini yuritish', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E293B))),
        subtitle: const Text('Sotilganda ombordan ayiriladi', style: TextStyle(fontSize: 12)),
        value: _trackStock,
        onChanged: (v) => setState(() => _trackStock = v),
        activeColor: const Color(0xFF6366F1),
      ),
    );
  }
}
