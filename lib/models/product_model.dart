import 'package:hive/hive.dart';

part 'product_model.g.dart'; // Ini akan dibuat otomatis oleh hive_generator

@HiveType(typeId: 0) // typeId UNIK, contoh: 0
class ProductModel extends HiveObject { // Harus extends HiveObject
  @HiveField(0)
  final int id;
  @HiveField(1)
  final String name;
  @HiveField(2)
  final String description;
  @HiveField(3)
  final int price;
  @HiveField(4)
  final String image;

  ProductModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.image,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) => ProductModel(
        id: json['id'] as int,
        name: json['name'] as String,
        description: json['description'] as String,
        price: int.parse(json['price'].toString()),
        image: json['image'] as String,
      );
}