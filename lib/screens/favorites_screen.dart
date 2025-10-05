import 'package:flutter/material.dart';
import 'package:mystic_tarot_jp/core/ui/app_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:mystic_tarot_jp/themes/dynamic_tokens.dart';

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
          icon: const Icon(AppIcons.arrowBack),
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
        child: Text(
          '占い結果のお気に入りは次版で拡充します。現状は履歴から閲覧可能です。',
          style: TextStyle(color: DynamicTokens.textGrey600),
        ),
      ),
    );
  }
}


