import 'package:get/get.dart';
import '../exports.dart';

class OrderController extends GetxController {
  static OrderController get to => Get.find<OrderController>();

  final RxList<OrderModel> orders = <OrderModel>[].obs;
  final RxString searchQuery = ''.obs;
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadOrders();
  }

  Future<void> loadOrders() async {
    isLoading.value = true;
    try {
      final list = await OrderDatabase.instance.getAllOrders();
      orders.value = list;
    } catch (e) {
      orders.clear();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> addOrder(OrderModel order) async {
    await OrderDatabase.instance.insertOrder(order);
    await loadOrders();
  }

  Future<void> updateOrder(OrderModel order) async {
    await OrderDatabase.instance.updateOrder(order);
    await loadOrders();
  }

  Future<void> deleteOrder(String id) async {
    await OrderDatabase.instance.deleteOrder(id);
    await loadOrders();
  }

  void updateSearchQuery(String query) {
    searchQuery.value = query.trim();
  }

  List<OrderModel> get filteredOrders {
    if (searchQuery.value.isEmpty) {
      return orders;
    }
    final q = searchQuery.value.toLowerCase();
    return orders.where((order) {
      return order.customerName.toLowerCase().contains(q) ||
          order.orderTitle.toLowerCase().contains(q) ||
          order.mobile.toLowerCase().contains(q) ||
          order.date.toLowerCase().contains(q);
    }).toList();
  }
}
