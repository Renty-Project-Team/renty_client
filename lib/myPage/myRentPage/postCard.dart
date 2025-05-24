import 'package:flutter/material.dart';
import 'package:renty_client/core/api_client.dart';
import 'package:renty_client/main.dart';
import 'myRantOutData.dart';
import 'package:intl/intl.dart';

class ProductCardByItemId extends StatelessWidget {
  final RentOutItem item;

  const ProductCardByItemId({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final imageUrl = '${apiClient.getDomain}${item.imgUrl}';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              imageUrl,
              width: 80,
              height: 80,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
              const Icon(Icons.broken_image, size: 80),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "가격: ${NumberFormat("#,###").format(item.price.toInt())}원 / ${item.priceUnit}",
                  style: const TextStyle(color: Colors.black54),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
