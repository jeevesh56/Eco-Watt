import 'package:flutter_test/flutter_test.dart';

import 'package:ecowatt/logic/billing/billing_engine.dart';
import 'package:ecowatt/logic/billing/reverse_slab.dart';
import 'package:ecowatt/logic/billing/slab_model.dart';

void main() {
  group('Residential slab billing', () {
    final engine = BillingEngine();

    test('100 units => ₹0', () {
      final res = engine.calculateBill(
        connectionType: ConnectionType.residential,
        units: 100,
      );
      expect(res.totalBill, 0);
    });

    test('200 units => ₹235', () {
      final res = engine.calculateBill(
        connectionType: ConnectionType.residential,
        units: 200,
      );
      expect(res.totalBill, closeTo(235, 0.001));
    });

    test('400 units => ₹1175', () {
      final res = engine.calculateBill(
        connectionType: ConnectionType.residential,
        units: 400,
      );
      expect(res.totalBill, closeTo(1175, 0.001));
    });

    test('500 units => ₹1805', () {
      final res = engine.calculateBill(
        connectionType: ConnectionType.residential,
        units: 500,
      );
      expect(res.totalBill, closeTo(1805, 0.001));
      expect(res.slabProgress.currentSlabStart, 401);
      expect(res.slabProgress.currentSlabLimit, 500);
      expect(res.slabProgress.nextSlabLimit, 600); // next slab 501-600
      expect(res.slabProgress.currentUnits, 500);
    });

    test('801 units => highest slab, nextSlabLimit null', () {
      final res = engine.calculateBill(
        connectionType: ConnectionType.residential,
        units: 801,
      );
      expect(res.slabProgress.currentSlabStart, 801);
      expect(res.slabProgress.currentSlabLimit, 9999);
      expect(res.slabProgress.nextSlabLimit, isNull);
    });
  });

  group('Reverse slab cost->units', () {
    test('₹0 => 100 units', () {
      final units = costToUnitsForConnection(
        connectionType: ConnectionType.residential,
        totalCost: 0,
      );
      expect(units, closeTo(100, 0.001));
    });

    test('₹235 => 200 units', () {
      final units = costToUnitsForConnection(
        connectionType: ConnectionType.residential,
        totalCost: 235,
      );
      expect(units, closeTo(200, 0.001));
    });

    test('₹1805 => 500 units', () {
      final units = costToUnitsForConnection(
        connectionType: ConnectionType.residential,
        totalCost: 1805,
      );
      expect(units, closeTo(500, 0.001));
    });
  });
}

