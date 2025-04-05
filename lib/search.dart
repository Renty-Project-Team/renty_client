import 'package:flutter/material.dart';
import 'global_theme.dart';
import 'SearchCategory.dart';
import 'bottom_menu_bar.dart';


class SearchPage extends StatelessWidget {
  const SearchPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: SearchCategories()),
    );
  }
}

