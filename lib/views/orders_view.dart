import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../exports.dart';

class OrdersView extends StatefulWidget {
  const OrdersView({super.key});

  @override
  State<OrdersView> createState() => _OrdersViewState();
}

class _OrdersViewState extends State<OrdersView> {
  final OrderController controller = Get.put(OrderController());
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    controller.loadOrders();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text(
            AppStrings.orderBookingTitle,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
        ),
        body: Column(
          children: [
            _buildSearchHeader(context),
            Expanded(child: _buildOrdersList(context)),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            Get.to(() => const AddEditOrderView());
          },
          icon: const Icon(Icons.add_rounded),
          label: const Text(
            AppStrings.createNewOrder,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: AppColors.primaryTeal,
          foregroundColor: AppColors.white,
        ),
      ),
    );
  }

  Widget _buildSearchHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppColors.primaryTeal,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
      ),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(fontSize: 15),
        onChanged: (val) {
          controller.updateSearchQuery(val);
        },
        decoration: InputDecoration(
          hintText: AppStrings.searchOrdersHint,
          prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primaryTeal),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  onPressed: () {
                    _searchController.clear();
                    controller.updateSearchQuery('');
                  },
                )
              : null,
          fillColor: AppColors.white,
          filled: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildOrdersList(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(
          child: CircularProgressIndicator(color: AppColors.primaryTeal),
        );
      }

      final orders = controller.filteredOrders;

      if (orders.isEmpty) {
        return _buildEmptyState(context);
      }

      return RefreshIndicator(
        onRefresh: () => controller.loadOrders(),
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
          itemCount: orders.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final order = orders[index];
            return _buildOrderCard(context, order);
          },
        ),
      );
    });
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primaryTeal.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.receipt_long_rounded,
                size: 64,
                color: AppColors.primaryTeal,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              AppStrings.noOrdersFound,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                Get.to(() => const AddEditOrderView());
              },
              icon: const Icon(Icons.add_rounded),
              label: const Text(
                AppStrings.createNewOrder,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryTeal,
                foregroundColor: AppColors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderCard(BuildContext context, OrderModel order) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Get.to(() => OrderPdfPreviewView(order: order)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order.orderTitle.isNotEmpty ? order.orderTitle : 'Order',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          order.customerName,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primaryTeal.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      order.date,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryTeal,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (order.subtitle.isNotEmpty) ...[
                Text(
                  order.subtitle,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
              ],
              Row(
                children: [
                  const Icon(Icons.phone_outlined, size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    order.mobile.isNotEmpty ? order.mobile : 'N/A',
                    style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                  const Spacer(),
                  const Icon(Icons.format_list_numbered_rounded, size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    '${order.items.length} items',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                ],
              ),
              const Divider(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () => Get.to(() => OrderPdfPreviewView(order: order)),
                    icon: const Icon(Icons.picture_as_pdf_rounded, size: 18),
                    label: const Text(AppStrings.viewPdfButton),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primaryTeal,
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(Icons.edit_rounded, color: AppColors.editBlue, size: 20),
                    tooltip: AppStrings.editOrder,
                    onPressed: () => Get.to(() => AddEditOrderView(orderToEdit: order)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, color: AppColors.deleteRed, size: 20),
                    tooltip: AppStrings.deleteOrder,
                    onPressed: () => _showDeleteOrderDialog(context, order),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteOrderDialog(BuildContext context, OrderModel order) {
    Get.dialog(
      Directionality(
        textDirection: TextDirection.ltr,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(AppStrings.deleteOrderConfirmTitle),
          content: const Text(AppStrings.deleteOrderConfirmMessage),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: const Text(AppStrings.orderCancelButton),
            ),
            ElevatedButton(
              onPressed: () async {
                await controller.deleteOrder(order.id);
                Get.back();
                Get.snackbar(
                  AppStrings.orderSuccessTitle,
                  AppStrings.orderDeletedSuccess,
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: AppColors.deleteRed,
                  colorText: AppColors.white,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.deleteRed,
                foregroundColor: AppColors.white,
              ),
              child: const Text(AppStrings.deleteOrder),
            ),
          ],
        ),
      ),
    );
  }
}
