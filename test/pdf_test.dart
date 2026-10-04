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

  test('Test column 1 complete fill and no continued header on column 2', () {
    // Company A ("ماسٹر"): 21 items -> 22 rows (Header + 21 items)
    final companyA = List.generate(
      21,
      (i) => ProductModel(
        id: 'a_$i',
        name: 'ماسٹر item $i',
        category: 'پائپ',
        company: 'ماسٹر',
        purchaseRate: 100,
        wholesaleRate: 120,
        customerRate: 150,
        unit: 'عدد',
      ),
    );

    // Company B ("پاپولر"): 12 items
    final companyB = List.generate(
      12,
      (i) => ProductModel(
        id: 'b_$i',
        name: 'پاپولر item $i',
        category: 'پائپ',
        company: 'پاپولر',
        purchaseRate: 100,
        wholesaleRate: 120,
        customerRate: 150,
        unit: 'عدد',
      ),
    );

    // Company C ("فاران"): 15 items -> 16 rows
    final companyC = List.generate(
      15,
      (i) => ProductModel(
        id: 'c_$i',
        name: 'فاران item $i',
        category: 'پائپ',
        company: 'فاران',
        purchaseRate: 100,
        wholesaleRate: 120,
        customerRate: 150,
        unit: 'عدد',
      ),
    );

    final columns = PdfGenerator.splitIntoColumnsForTesting([
      ...companyA,
      ...companyB,
      ...companyC,
    ]);

    // Column 1 must be filled completely (25 rows: 1 category header + Company A 22 rows + Company B header & 1 item = 2)
    expect(columns[0].length, equals(25));
    expect(columns[0].first, isA<CategoryHeaderEntry>());

    // Column 2 receives remaining 11 items of Company B directly WITHOUT a continued header bar (11 entries).
    // Company C needs 16 rows which exceeds Column 2's remaining 14 spaces, so Company C moves completely to Page 2!
    expect(columns[1].length, equals(11));

    // Verify first entry in Column 2 is a ProductItemEntry (no continued CompanyHeaderEntry)
    expect(columns[1].first, isA<ProductItemEntry>());

    // Verify Column 3 (Page 2, Column 1) has Company C complete (16 entries)
    expect(columns[2].length, equals(16));
  });
}
