class CardModel {
  final int? id;
  final String cardNumber;
  final String holderName;
  final String expiryDate;
  final String cvv;

  CardModel({
    this.id,
    required this.cardNumber,
    required this.holderName,
    required this.expiryDate,
    required this.cvv,
  });

  factory CardModel.fromMap(Map<String, dynamic> json) => CardModel(
        id: json['id'],
        cardNumber: json['cardNumber'],
        holderName: json['holderName'],
        expiryDate: json['expiryDate'],
        cvv: json['cvv'],
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'cardNumber': cardNumber,
        'holderName': holderName,
        'expiryDate': expiryDate,
        'cvv': cvv,
      };
}