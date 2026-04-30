import 'package:aplikasi_demo_test/utils/app_color.dart';
import 'package:flutter/material.dart';

class SearchBarWidget extends StatefulWidget {
  final SearchController controller;
  final Function(String)? onChanged;
  final String hintText; // tambahkan ini

  const SearchBarWidget({
    super.key,
    required this.controller,
    this.onChanged,
    this.hintText = "Cari...", // default value biar aman
  });

  @override
  State<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget> {
  @override
  Widget build(BuildContext context) {
    return SearchBar(
      controller: widget.controller,
      padding: const WidgetStatePropertyAll<EdgeInsets>(
        EdgeInsets.symmetric(horizontal: 16.0),
      ),
      keyboardType: TextInputType.name,
      backgroundColor: WidgetStatePropertyAll<Color>(
        AppColor.backgroundColorSecondry,
      ),
      hintText: widget.hintText, // pakai dari parameter
      onChanged: widget.onChanged,
      leading: const Icon(Icons.search),
    );
  }
}
