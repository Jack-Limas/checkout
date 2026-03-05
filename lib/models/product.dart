class PromoModel {
  final int? id;
  final String code;
  final double discount;
  final double minAmount;

  PromoModel({
    this.id,
    required this.code,
    required this.discount,
    required this.minAmount,
  });

  factory PromoModel.fromMap(Map<String, dynamic> json) => PromoModel(
        id: json['id'],
        code: json['code'],
        discount: json['discount'],
        minAmount: json['minAmount'],
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'code': code,
        'discount': discount,
        'minAmount': minAmount,
      };
}