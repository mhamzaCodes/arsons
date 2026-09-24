import 'package:flutter_test/flutter_test.dart';
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

    test('InventoryController adding and retrieving products verification', () {
      final controller = InventoryController();
      final sampleProduct = ProductModel(
        id: 'test_1',
        name: 'پائپ 3 انچ PPR',
        category: 'پائپ اور فٹنگ',
        company: 'ماسٹر',
        purchaseRate: 1000.0,
        wholesaleRate: 1200.0,
        customerRate: 1500.0,
        unit: 'فٹ',
      );

      controller.addProduct(sampleProduct);

      expect(controller.products.length, 1);

      final pipeProducts = controller.getProductsForCategory('پائپ اور فٹنگ');
      expect(pipeProducts.length, 1);
      expect(pipeProducts.first.name, 'پائپ 3 انچ PPR');
    });
  });
}
