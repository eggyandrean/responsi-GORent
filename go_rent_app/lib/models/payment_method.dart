// Metode pembayaran dari GET /payment-methods (OVO, GoPay, Bank Transfer)
class PaymentMethod {
  final int id;
  final String name;

  const PaymentMethod({required this.id, required this.name});

  factory PaymentMethod.fromJson(Map<String, dynamic> json) {
    return PaymentMethod(id: json['id'] as int, name: json['name'] as String);
  }

  Map<String, dynamic> toJson() => {'id': id, 'name': name};
}
