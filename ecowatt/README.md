## ECOWATT – Mobile Electricity Intelligence App

This repository contains the ECOWATT mobile application built with **Flutter + Dart**.
It focuses on realistic Indian household electricity analysis – not a demo UI.

### Architecture

- `lib/app/` – app shell, routing, theme, and global state container.
- `lib/core/` – design system (colors, sizes, strings) and reusable widgets.
- `lib/data/` – models, local repositories (`shared_preferences`) and mock catalogs.
- `lib/logic/` – pure domain logic:
  - `calculator/` – appliance energy, cost, and carbon calculations.
  - `billing/` – centralized tariff, slab, and billing engine for residential vs commercial.
  - `wastage/` and `insights/` – anomaly detection and recommendations.
- `lib/state/` – `ChangeNotifier` based app, bill, appliance and settings state.
- `lib/features/` – feature modules for setup, configuration, analysis, detail, history, and settings.

Electricity billing rules, subsidies, and tariffs are implemented in a **centralized logic layer**
under `lib/logic/billing/`, mimicking how electricity boards manage connection types and slabs.
The **frontend only collects inputs and presents results**, keeping calculations correct,
auditable, and easy to extend for future state-wise or high-tension (HT) tariffs.

