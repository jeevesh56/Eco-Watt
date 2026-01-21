import '../../app/state_container.dart';
import '../../data/models/bill_model.dart';
import '../../data/models/user_model.dart';
import '../../logic/calculator/cost_calculator.dart';

class SetupController {
  Future<void> saveSetup({
    required AppStateScope scope,
    required String homeType,
    required int occupants,
    required bool inputIsAmount,
    required double inputValue,
    required int month,
    required int year,
  }) async {
    final state = scope.notifier!;
    final tariff = state.settings.tariff;

    // If user enters amount, estimate units using baseRate (simplified).
    final units = inputIsAmount ? (inputValue / tariff.baseRate) : inputValue;
    final amount = inputIsAmount ? inputValue : CostCalculator.costForUnits(units, tariff);

    final user = UserModel(
      userId: 'local',
      homeType: homeType,
      occupants: occupants,
      tariffSettings: TariffSettings(
        providerName: tariff.providerName,
        baseRate: tariff.baseRate,
        tieredPricing: tariff.tieredPricing
            .map((t) => TariffSlab(upToKWh: t.upToKWh, rate: t.rate))
            .toList(),
      ),
      currency: tariff.currency,
      preferences: const {},
    );

    final bill = BillModel(
      billId: '$year-$month',
      month: month,
      year: year,
      unitsConsumed: units,
      billAmount: amount,
      calculatedBreakdown: {
        'estimatedFrom': inputIsAmount ? 'amount' : 'units',
      },
      createdAt: DateTime(year, month, 1),
    );

    await state.settings.saveUser(user);
    await state.bills.upsert(bill);
  }
}

