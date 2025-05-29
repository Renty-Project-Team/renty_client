import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:renty_client/main.dart';
import 'package:renty_client/post/postDataFile.dart';
import 'package:renty_client/detailed_post/buyerDetail/buyerDetailPost.dart';
import 'package:renty_client/core/api_client.dart';

class BuyerPostCard extends StatelessWidget {
  final BuyerPost post;

  const BuyerPostCard({required this.post});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BuyerPostDetailPage(postId: post.id),
          ),
        );
      },
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 2,
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Padding(
          padding: const EdgeInsets.all(18.0),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: post.imageUrl != null
                    ? Image.network(
                  '${apiClient.getDomain}${post.imageUrl}',
                  width: 90,
                  height: 90,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => _noImage(),
                )
                    : _noImage(),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: '[상품요청] ',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                          TextSpan(
                            text: post.title,
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 4),
                    Text('작성일: ${DateFormat('yyyy.MM.dd').format(post.createdAt)}'),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      Icon(Icons.remove_red_eye, size: 14, color: Colors.grey),
                      SizedBox(width: 4),
                      Text('${post.viewCount}', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.comment, size: 14, color: Colors.grey),
                      SizedBox(width: 4),
                      Text('${post.commentCount}', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _noImage() => Container(
    width: 90,
    height: 90,
    color: Colors.grey[300],
    child: Icon(Icons.image_not_supported, size: 40, color: Colors.grey),
  );
}
