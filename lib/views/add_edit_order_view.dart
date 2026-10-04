import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../exports.dart';

class AddEditOrderView extends StatefulWidget {
  final OrderModel? orderToEdit;

  const AddEditOrderView({super.key, this.orderToEdit});

  @override
  State<AddEditOrderView> createState() => _AddEditOrderViewState();
}

class _AddEditOrderViewState extends State<AddEditOrderView> {
  final OrderController controller = Get.put(OrderController());

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _customerController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _orderTitleController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();

  final List<Map<String, TextEditingController>> _itemControllers = [];

  bool get isEditing => widget.orderToEdit != null;

  @override
  void initState() {
    super.initState();
    _initFields();
  }

  void _initFields() {
    if (isEditing) {
      final order = widget.orderToEdit!;
      _customerController.text = order.customerName.isNotEmpty
          ? order.customerName
          : AppStrings.defaultShopName;
      _mobileController.text =
          order.mobile.isNotEmpty ? order.mobile : AppStrings.phoneNumber;
      _orderTitleController.text = order.orderTitle;
      _dateController.text = order.date.isNotEmpty
          ? order.date
          : DateFormat('dd/MM/yy').format(DateTime.now());

      for (var item in order.items) {
        _addItemRow(
          size: item.size,
          gram: item.gram,
          pipes: item.pipes,
        );
      }
    } else {
      // Default header values for orders
      _customerController.text = AppStrings.defaultShopName;
      _mobileController.text = AppStrings.phoneNumber;
      _orderTitleController.text = '';
      _dateController.text = DateFormat('dd/MM/yy').format(DateTime.now());

      // Start with 1 empty item row
      _addItemRow();
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    DateTime initialDate = DateTime.now();
    if (_dateController.text.isNotEmpty) {
      try {
        initialDate = DateFormat('dd/MM/yy').parse(_dateController.text);
      } catch (_) {
        try {
          initialDate = DateFormat('dd/MM/yyyy').parse(_dateController.text);
        } catch (_) {}
      }
    }

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      locale: const Locale('en', 'US'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primaryTeal,
              onPrimary: Colors.white,
              onSurface: AppColors.textDark,
            ),
          ),
          child: Localizations.override(
            context: context,
            locale: const Locale('en', 'US'),
            child: child!,
          ),
        );
      },
    );

    if (picked != null) {
      setState(() {
        _dateController.text = DateFormat('dd/MM/yy').format(picked);
      });
    }
  }

  void _addItemRow({String size = '', String gram = '', String pipes = ''}) {
    setState(() {
      _itemControllers.add({
        'size': TextEditingController(text: size),
        'gram': TextEditingController(text: gram),
        'pipes': TextEditingController(text: pipes),
      });
    });
  }

  void _removeItemRow(int index) {
    setState(() {
      final controllers = _itemControllers.removeAt(index);
      controllers['size']?.dispose();
      controllers['gram']?.dispose();
      controllers['pipes']?.dispose();
    });
  }

  @override
  void dispose() {
    _customerController.dispose();
    _mobileController.dispose();
    _orderTitleController.dispose();
    _dateController.dispose();
    for (var controllers in _itemControllers) {
      controllers['size']?.dispose();
      controllers['gram']?.dispose();
      controllers['pipes']?.dispose();
    }
    super.dispose();
  }

  OrderModel _buildOrderFromInput() {
    final String orderId = isEditing
        ? widget.orderToEdit!.id
        : 'order_${DateTime.now().millisecondsSinceEpoch}';

    List<OrderItemModel> items = [];
    for (int i = 0; i < _itemControllers.length; i++) {
      final controllers = _itemControllers[i];
      final size = controllers['size']?.text.trim() ?? '';
      final gram = controllers['gram']?.text.trim() ?? '';
      final pipes = controllers['pipes']?.text.trim() ?? '';

      if (size.isNotEmpty || gram.isNotEmpty || pipes.isNotEmpty) {
        items.add(
          OrderItemModel(
            id: 'item_${orderId}_$i',
            orderId: orderId,
            srNo: items.length + 1,
            size: size,
            gram: gram,
            pipes: pipes,
          ),
        );
      }
    }

    return OrderModel(
      id: orderId,
      customerName: _customerController.text.trim().isNotEmpty
          ? _customerController.text.trim()
          : AppStrings.defaultShopName,
      mobile: _mobileController.text.trim().isNotEmpty
          ? _mobileController.text.trim()
          : AppStrings.phoneNumber,
      subtitle: AppStrings.defaultOrderSubtitle,
      orderTitle: _orderTitleController.text.trim(),
      date: _dateController.text.trim(),
      createdAt: isEditing
          ? widget.orderToEdit!.createdAt
          : DateTime.now().toIso8601String(),
      items: items,
    );
  }

  Future<void> _saveOrder({bool viewPdf = false}) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final order = _buildOrderFromInput();

    if (isEditing) {
      await controller.updateOrder(order);
      Get.snackbar(
        AppStrings.orderSuccessTitle,
        AppStrings.orderUpdatedSuccess,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.primaryTeal,
        colorText: AppColors.white,
      );
    } else {
      await controller.addOrder(order);
      Get.snackbar(
        AppStrings.orderSuccessTitle,
        AppStrings.orderSavedSuccess,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.successGreen,
        colorText: AppColors.white,
      );
    }

    if (viewPdf) {
      Get.off(() => OrderPdfPreviewView(order: order));
    } else {
      Get.back();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            isEditing ? AppStrings.editOrder : AppStrings.createNewOrder,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeaderSection(),
                const SizedBox(height: 20),
                _buildItemsSection(),
                const SizedBox(height: 24),
                _buildActionButtons(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Permanent Header Info Box
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderGrey),
              ),
              child: Row(
                children: [
                  const Icon(Icons.storefront_rounded,
                      size: 22, color: AppColors.primaryTeal),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          AppStrings.defaultShopName,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: AppColors.textDark,
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          '${AppStrings.ownerProprietorInfoEnglish} | Mobile: ${AppStrings.phoneNumber}',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.lock_rounded, size: 16, color: AppColors.textSecondary),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              AppStrings.orderDetails,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryTealDark,
              ),
            ),
            const Divider(height: 20),
            TextFormField(
              controller: _orderTitleController,
              decoration: const InputDecoration(
                labelText: AppStrings.orderTitleLabel,
                hintText: AppStrings.orderTitleHint,
                prefixIcon: Icon(Icons.bookmark_rounded, color: Colors.red),
                border: OutlineInputBorder(),
              ),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? AppStrings.orderRequiredField : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _dateController,
              readOnly: true,
              onTap: () => _selectDate(context),
              decoration: const InputDecoration(
                labelText: AppStrings.orderDateLabel,
                hintText: AppStrings.orderDateHint,
                prefixIcon: Icon(Icons.calendar_today_rounded, color: AppColors.primaryTeal),
                suffixIcon: Icon(Icons.arrow_drop_down_rounded, color: AppColors.primaryTeal),
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? AppStrings.orderRequiredField : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              AppStrings.orderItemsSection,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryTealDark,
              ),
            ),
            ElevatedButton.icon(
              onPressed: () => _addItemRow(),
              icon: const Icon(Icons.add_rounded),
              label: const Text(AppStrings.addItemRow),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryTeal,
                foregroundColor: AppColors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_itemControllers.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderGrey),
            ),
            child: const Center(
              child: Text(
                AppStrings.noItemsAdded,
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _itemControllers.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final controllers = _itemControllers[index];
              return Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.borderGrey),
                  boxShadow: const [
                    BoxShadow(
                      color: AppColors.shadowLight,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: AppColors.primaryTeal.withValues(alpha: 0.1),
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryTeal,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 4,
                      child: TextField(
                        controller: controllers['size'],
                        decoration: const InputDecoration(
                          labelText: AppStrings.sizeColumnLabel,
                          hintText: AppStrings.sizeColumnHint,
                          isDense: true,
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      flex: 3,
                      child: TextField(
                        controller: controllers['gram'],
                        decoration: const InputDecoration(
                          labelText: AppStrings.gramColumnLabel,
                          hintText: AppStrings.gramColumnHint,
                          isDense: true,
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      flex: 3,
                      child: TextField(
                        controller: controllers['pipes'],
                        decoration: const InputDecoration(
                          labelText: AppStrings.pipesColumnLabel,
                          hintText: AppStrings.pipesColumnHint,
                          isDense: true,
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded,
                          color: AppColors.deleteRed),
                      onPressed: () => _removeItemRow(index),
                      tooltip: AppStrings.removeItemTooltip,
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _saveOrder(viewPdf: false),
            icon: const Icon(Icons.save_rounded),
            label: Text(
              isEditing ? AppStrings.updateOrderButton : AppStrings.saveOrderButton,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryTeal,
              foregroundColor: AppColors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _saveOrder(viewPdf: true),
            icon: const Icon(Icons.picture_as_pdf_rounded),
            label: const Text(
              AppStrings.saveAndViewPdfButton,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primaryTeal,
              side: const BorderSide(color: AppColors.primaryTeal, width: 1.5),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
