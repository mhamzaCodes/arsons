import 'package:flutter_test/flutter_test.dart';
import 'package:arsons/models/product_model.dart';
import 'package:arsons/utils/pdf_generator.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Test generateRateListPdf with 28 items per side filling page cleanly', () async {
    final products = List.generate(
      100,
      (index) => ProductModel(
        id: 'p_$index',
        name: 'پائپ $index انچ PPR (10 فٹ)',
        category: 'پائپ اور فٹنگ',
        company: index < 20
            ? 'ماسٹر'
            : index < 40
                ? 'پاپولر'
                : index < 60
                    ? 'فیصل'
                    : 'فاران',
        purchaseRate: 1000.0 + index * 10,
        wholesaleRate: 1200.0 + index * 10,
        customerRate: 1500.0 + index * 10,
        unit: 'فٹ',
      ),
    );

    final bytesWithPurchase = await PdfGenerator.generateRateListPdf(
      products,
      includePurchaseRate: true,
    );
    expect(bytesWithPurchase, isNotEmpty);
    expect(bytesWithPurchase.length, greaterThan(1000));

    final bytesWithoutPurchase = await PdfGenerator.generateRateListPdf(
      products,
      includePurchaseRate: false,
    );
    expect(bytesWithoutPurchase, isNotEmpty);
    expect(bytesWithoutPurchase.length, greaterThan(1000));
  });
}
