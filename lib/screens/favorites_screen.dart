import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('お気に入り'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              context.pop();
            } else {
              context.go('/mydeck');
            }
          },
        ),
      ),
      body: const Center(
        child: Text('占い結果のお気に入りは次版で拡充します。現状は履歴から閲覧可能です。'),
      ),
    );
  }
}


