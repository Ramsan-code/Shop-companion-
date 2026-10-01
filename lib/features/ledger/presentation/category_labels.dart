import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/widgets.dart';

import '../../../app/l10n/app_localizations.dart';
import '../domain/categories.dart';

extension CategoryLabel on EntryCategory {
  String label(AppLocalizations l10n) => switch (this) {
    EntryCategory.grocery => l10n.catGrocery,
    EntryCategory.vegetables => l10n.catVegetables,
    EntryCategory.bakery => l10n.catBakery,
    EntryCategory.phoneCredit => l10n.catPhoneCredit,
    EntryCategory.otherSale => l10n.catOtherSale,
    EntryCategory.stockPurchase => l10n.catStockPurchase,
    EntryCategory.transport => l10n.catTransport,
    EntryCategory.electricity => l10n.catElectricity,
    EntryCategory.wages => l10n.catWages,
    EntryCategory.rent => l10n.catRent,
    EntryCategory.otherExpense => l10n.catOtherExpense,
  };

  IconData get icon => switch (this) {
    EntryCategory.grocery => FluentIcons.cart_24_regular,
    EntryCategory.vegetables => FluentIcons.food_carrot_24_regular,
    EntryCategory.bakery => FluentIcons.food_24_regular,
    EntryCategory.phoneCredit => FluentIcons.phone_24_regular,
    EntryCategory.otherSale => FluentIcons.receipt_24_regular,
    EntryCategory.stockPurchase => FluentIcons.box_24_regular,
    EntryCategory.transport => FluentIcons.vehicle_bus_24_regular,
    EntryCategory.electricity => FluentIcons.flash_24_regular,
    EntryCategory.wages => FluentIcons.people_24_regular,
    EntryCategory.rent => FluentIcons.building_shop_24_regular,
    EntryCategory.otherExpense => FluentIcons.money_24_regular,
  };
}
