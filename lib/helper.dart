import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

String formatAmount(double amount) {
  final formatter = NumberFormat('#,###', 'en_US');
  return formatter.format(amount).replaceAll(',', '.');
}

String formatRupiah(double amount) {
  if (amount == 0) return 'Rp 0';
  final currencyFormatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );
  return currencyFormatter.format(amount);
}

Map<K, List<T>> groupBy<T, K>(List<T> items, K Function(T) selector) {
  Map<K, List<T>> groupedData = {};

  for (var item in items) {
    // The selector function determines which property to group by
    K key = selector(item);

    groupedData.putIfAbsent(key, () => []);
    groupedData[key]!.add(item);
  }

  return groupedData;
}

IconData getIconFromName(String name) {
  switch (name) {
    case 'attach_money': return Icons.attach_money;
    case 'restaurant': return Icons.restaurant;
    case 'shopping_bag': return Icons.shopping_bag;
    case 'work': return Icons.work;
    case 'directions_car': return Icons.directions_car;
    case 'subscriptions': return Icons.subscriptions;
    case 'card_giftcard': return Icons.card_giftcard;
    case 'local_grocery_store': return Icons.local_grocery_store;
    case 'movie': return Icons.movie;
    case 'trending_up': return Icons.trending_up;
    case 'home': return Icons.home;
    case 'flight': return Icons.flight;
    case 'local_hospital': return Icons.local_hospital;
    case 'school': return Icons.school;
    case 'pets': return Icons.pets;
    default: return Icons.label;
  }
}
