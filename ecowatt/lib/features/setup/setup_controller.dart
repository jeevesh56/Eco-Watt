import '../../app/state_container.dart';
import '../../data/models/bill_model.dart';
import '../../data/models/user_model.dart';
import '../../logic/billing/billing_engine.dart';
import '../../logic/billing/slab_model.dart';

class SetupController {
  Future<void> saveSetup({
    required AppStateScope scope,
    required String connectionType,
    required int occupants,
    required bool inputIsAmount,
    required double inputValue,
    required int month,
    required int year,
  }) async {
    final state = scope.notifier!;
    final type = connectionTypeFromString(connectionType);

    // Prefer unit-based billing. If the user entered amount instead of units,
    // we approximate units using the highest slab rate and then run billing.
    double units;
    if (inputIsAmount) {
      final engine = BillingEngine();
      // Start with a rough guess assuming an effective rate of ₹7/unit.
      units = inputValue / 7.0;
      final billingGuess =
          engine.calculateBill(connectionType: type, units: units);
      // Refine units based on the effective rate from the first pass.
      if (billingGuess.effectiveRatePerUnit > 0) {
        units = inputValue / billingGuess.effectiveRatePerUnit;
      }
    } else {
      units = inputValue;
    }

    final billing =
        BillingEngine().calculateBill(connectionType: type, units: units);

    final user = UserModel(
      userId: 'local',
      connectionType: connectionType,
      occupants: occupants,
      currency: '₹',
      preferences: const {},
    );

    final bill = BillModel(
      billId: '$year-$month',
      month: month,
      year: year,
      unitsConsumed: units,
      billAmount: billing.totalBill.toDouble(),
      calculatedBreakdown: billing.toJson(),
      createdAt: DateTime(year, month, 1),
    );

    await state.settings.saveUser(user);
    await state.bills.upsert(bill);
  }
}

