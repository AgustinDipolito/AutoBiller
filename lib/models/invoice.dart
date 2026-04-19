import 'package:dist_v2/models/customer.dart';
import 'package:dist_v2/models/supplier.dart';

class Invoice {
  final InvoiceInfo info;
  final Supplier supplier;
  final Customer customer;
  final List<InvoiceItem> items;
  final double? discountPercentage; // Porcentaje de descuento (ej: 10 = 10%)
  final double? balance; // Saldo anterior (positivo = debe, negativo = a favor)

  const Invoice({
    required this.info,
    required this.supplier,
    required this.customer,
    required this.items,
    this.discountPercentage,
    this.balance,
  });
}

class InvoiceInfo {
  final String description;
  final String number;
  final DateTime date;
  final DateTime dueDate;

  const InvoiceInfo({
    required this.description,
    required this.number,
    required this.date,
    required this.dueDate,
  });
}

class InvoiceItem {
  final String description;
  final DateTime date;
  final int quantity;
  final double unitPrice;

  const InvoiceItem({
    required this.description,
    required this.date,
    required this.quantity,
    required this.unitPrice,
  });
}
