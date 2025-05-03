import 'package:flutter/cupertino.dart';

class Product {
  final String username;
  final String title;
  final String Category;
  final String price;
  final String deposit;
  final String Description;
  final String Unit;
  final int likes;
  final int views;
  final String imageUrl;

  Product({
    required this.username,
    required this.title,
    required this.Category,
    required this.price,
    required this.Unit,
    required this.deposit,
    required this.Description,
    required this.likes,
    required this.views,
    required this.imageUrl,
  });
}
final List<Product> products = [
  Product(
    username: "test1",
    title: "1 상품 입니다",
    Category: "취미/여가",
    price: "2,000원",
    Unit: "일",
    deposit: "10,000원",
    Description: "예시 입니다",
    likes: 404,
    views: 404,
    imageUrl: "https://picsum.photos/200",
  ),
  Product(
    username: "test1",
    title: "2 번째 상품",
    Category: "취미/여가",
    price: "3,500원",
    Unit: "일",
    deposit: "5,000원",
    Description: "예시 입니다",
    likes: 123,
    views: 987,
    imageUrl: "https://picsum.photos/201",
  ),
  Product(
    username: "test1",
    title: "3 번째 상품",
    Category: "취미/여가",
    price: "1,800원",
    Unit: "일",
    deposit: "12,000원",
    Description: "예시 입니다",
    likes: 56,
    views: 321,
    imageUrl: "https://picsum.photos/202",
  ),
];