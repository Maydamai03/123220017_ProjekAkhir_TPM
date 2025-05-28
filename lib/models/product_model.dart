class ProductModel {
  final int id;
  final String name;
  final String description;
  final int price;
  final String image;

  ProductModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.image,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) => ProductModel(
        id: json['id'],
        name: json['name'],
        description: json['description'],
      price: int.parse(json['price'].toString()), // aman untuk int/string
        image: json['image'],
      );
}
