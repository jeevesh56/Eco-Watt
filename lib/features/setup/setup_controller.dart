import '../../app/state_container.dart';
import '../../data/models/bill_model.dart';
import '../../data/models/user_model.dart';
import '../../logic/billing/billing_engine.dart';
import '../../logic/billing/billing_result.dart';
import '../../logic/billing/slab_model.dart';

class SetupController {
  /// Numerically inverts the billing engine to estimate units from a
  /// target bill amount for the given connection type.
  ///
  /// This ensures that entering a known bill amount (e.g. ₹1805) produces
  /// units that, when billed again, give back approximately the same amount.
  static double estimateUnitsFromAmount({
    required ConnectionType type,
    required double amount,
  }) {
    final engine = BillingEngine();

    // Grow an upper bound until the billed amount is >= target, or cap out.
    double low = 0;
    double high = 500; // start with a reasonable bound
    const maxHigh = 100000.0;

    BillingResult billFor(double units) =>
        engine.calculateBill(connectionType: type, units: units);

    while (billFor(high).totalBill < amount && high < maxHigh) {
      low = high;
      high *= 2;
    }

    // Binary search for units such that totalBill ~= amount.
    for (var i = 0; i < 40; i++) {
      final mid = (low + high) / 2;
      final bill = billFor(mid).totalBill.toDouble();
      if (bill > amount) {
        high = mid;
      } else {
        low = mid;
      }
    }

    return (low + high) / 2;
  }

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
    final currentUserId = state.auth.currentUserId;
    final type = connectionTypeFromString(connectionType);

    // Prefer unit-based billing. If the user entered amount instead of units,
    // we numerically invert the billing engine to find the matching units.
    final units = inputIsAmount
        ? SetupController.estimateUnitsFromAmount(
            type: type,
            amount: inputValue,
          )
        : inputValue;

    final billing =
        BillingEngine().calculateBill(connectionType: type, units: units);

    final user = UserModel(
      userId: (currentUserId ?? 0).toString(),
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
    await state.bills.addMonthlyBill(
      userId: currentUserId,
      bill: bill,
      connectionType: connectionType,
    );
  }
}

