import 'package:flutter_test/flutter_test.dart';
import 'package:arsons/constants/constants.dart';
import 'package:arsons/models/product_model.dart';
import 'package:arsons/controllers/inventory_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Inventory Controller & Product Model Tests', () {
    test('ProductModel toMap and fromMap conversion', () {
      final product = ProductModel(
        id: 'p1',
        name: 'ماسٹر مکسر سیٹ',
        category: 'مکسر اور نل',
        company: 'ماسٹر',
        purchaseRate: 5000.0,
        wholesaleRate: 5500.0,
        customerRate: 6000.0,
        unit: 'سیٹ',
      );

      final map = product.toMap();
      final fromMapProduct = ProductModel.fromMap(map);

      expect(fromMapProduct.id, 'p1');
      expect(fromMapProduct.name, 'ماسٹر مکسر سیٹ');
      expect(fromMapProduct.customerRate, 6000.0);
    });

    test('InventoryController default seed data verification', () {
      final controller = InventoryController();
      controller.products.value = List.from(AppConstants.seedProducts);

      expect(controller.products.length, AppConstants.seedProducts.length);

      final pipeProducts = controller.getProductsForCategory('پائپ اور فٹنگ');
      expect(pipeProducts.length, greaterThan(0));
    });
  });
}
