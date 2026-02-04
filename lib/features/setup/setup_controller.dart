import '../../app/state_container.dart';
import '../../data/models/bill_model.dart';
import '../../data/models/user_model.dart';
import '../../logic/billing/billing_engine.dart';
import '../../logic/billing/slab_model.dart';
import '../../logic/billing/reverse_slab.dart';

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
    final currentUserId = state.auth.currentUserId;
    final type = connectionTypeFromString(connectionType);

    // convert cost back to units using reverse slab logic.
    final double units = inputIsAmount
        ? costToUnitsForConnection(
            connectionType: type,
            totalCost: inputValue,
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

