class Product {
  final int? id;
  final String name;
  final double price;

  Product({
    this.id,
    required this.name,
    required this.price,
  });

  factory Product.fromMap(Map<String, dynamic> json) => Product(
        id: json['id'],
        name: json['name'],
        price: json['price'],
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'price': price,
      };
}