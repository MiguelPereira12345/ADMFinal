import 'package:flutter/material.dart';

import 'app_colors.dart';

enum AppLeading { back, close, none }

class AppScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final List<Widget>? actions;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final AppLeading leading;
  final bool centerTitle;
  final Color? backgroundColor;

  const AppScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.leading = AppLeading.back,
    this.centerTitle = false,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final bg = backgroundColor ?? AppColors.bg;

    return Scaffold(
      backgroundColor: bg,
      appBar: title.isEmpty
          ? null
          : AppBar(
              backgroundColor: bg,
              elevation: 0,
              centerTitle: centerTitle,
              surfaceTintColor: Colors.transparent,
              automaticallyImplyLeading: leading == AppLeading.back,
              leading: switch (leading) {
                AppLeading.close => IconButton(
                  tooltip: 'Fechar',
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: const Icon(Icons.close),
                ),
                AppLeading.none => null,
                AppLeading.back => null,
              },
              iconTheme: const IconThemeData(color: Colors.black),
              title: Text(
                title,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              actions: actions,
            ),
      body: SafeArea(child: body),
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
    );
  }
}
