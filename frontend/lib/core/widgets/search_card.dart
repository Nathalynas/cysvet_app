import 'package:flutter/material.dart';

class SearchCard extends StatefulWidget {
  const SearchCard({
    super.key,
    required this.value,
    required this.labelText,
    required this.onChanged,
    this.hintText,
  });

  final String value;
  final String labelText;
  final String? hintText;
  final ValueChanged<String> onChanged;

  @override
  State<SearchCard> createState() => _SearchCardState();
}

class _SearchCardState extends State<SearchCard> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(covariant SearchCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.value != _controller.text) {
      _controller.value = TextEditingValue(
        text: widget.value,
        selection: TextSelection.collapsed(offset: widget.value.length),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _clear() {
    _controller.clear();
    widget.onChanged('');
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: TextField(
          controller: _controller,
          onChanged: widget.onChanged,
          decoration: InputDecoration(
            labelText: widget.labelText,
            hintText: widget.hintText,
            prefixIcon: const Icon(Icons.search_outlined),
            suffixIcon: widget.value.isEmpty
                ? null
                : IconButton(
                    onPressed: _clear,
                    icon: const Icon(Icons.close),
                  ),
          ),
        ),
      ),
    );
  }
}