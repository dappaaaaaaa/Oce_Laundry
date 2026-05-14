import 'package:aplikasi_demo_test/utils/app_color.dart';
import 'package:flutter/material.dart';

class SearchBarWidget extends StatefulWidget {
  final SearchController controller;
  final Function(String)? onChanged;
  final String hintText;

  const SearchBarWidget({
    super.key,
    required this.controller,
    this.onChanged,
    this.hintText = "Cari...",
  });

  @override
  State<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget> {
  @override
  Widget build(BuildContext context) {
    return SearchBar(
      elevation: WidgetStatePropertyAll(0),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(
          borderRadius: BorderRadiusGeometry.circular(8),
          side: BorderSide(color: Colors.black),
        ),
      ),
      controller: widget.controller,
      padding: const WidgetStatePropertyAll<EdgeInsets>(
        EdgeInsets.symmetric(horizontal: 16.0),
      ),
      keyboardType: TextInputType.name,
      backgroundColor: WidgetStatePropertyAll<Color>(
        AppColor.backgroundColorSecondry,
      ),
      hintStyle: WidgetStatePropertyAll<TextStyle>(TextStyle(fontSize: 12)),
      hintText: widget.hintText, // pakai dari parameter
      onChanged: widget.onChanged,
      leading: const Icon(Icons.search, size: 16),
    );
  }
}
