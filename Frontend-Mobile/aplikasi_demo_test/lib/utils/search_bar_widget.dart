import 'package:aplikasi_demo_test/utils/app_color.dart';
import 'package:flutter/material.dart';

class SearchBarWidget extends StatefulWidget {
  final SearchController controller;
  final Function(String)? onChanged; // tambahkan

  const SearchBarWidget({super.key, required this.controller, this.onChanged});

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
      hintText: "Masukan Nama Pelanggan",
      onChanged: widget.onChanged,
      leading: const Icon(Icons.search),
    );
  }
}
