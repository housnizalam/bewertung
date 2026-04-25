import 'package:flutter/material.dart';

class WeightPicker extends StatefulWidget {
  const WeightPicker({
    super.key,
    required this.initialValue,
    required this.onChanged,
  });

  final double initialValue;
  final ValueChanged<double> onChanged;

  @override
  State<WeightPicker> createState() => _WeightPickerState();
}

class _WeightPickerState extends State<WeightPicker> {
  late int _tens;
  late int _ones;
  late final FixedExtentScrollController _tensController;
  late final FixedExtentScrollController _onesController;

  @override
  void initState() {
    super.initState();
    final rounded = widget.initialValue.round().clamp(0, 99);
    _tens = rounded ~/ 10;
    _ones = rounded % 10;
    _tensController = FixedExtentScrollController(initialItem: _tens);
    _onesController = FixedExtentScrollController(initialItem: _ones);
  }

  @override
  void dispose() {
    _tensController.dispose();
    _onesController.dispose();
    super.dispose();
  }

  void _notify() {
    widget.onChanged((_tens * 10 + _ones).toDouble());
  }

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.titleLarge;

    return SizedBox(
      height: 92,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _DigitWheel(
            controller: _tensController,
            selectedValue: _tens,
            onChanged: (value) {
              setState(() => _tens = value);
              _notify();
            },
            textStyle: textStyle,
          ),
          const SizedBox(width: 10),
          _DigitWheel(
            controller: _onesController,
            selectedValue: _ones,
            onChanged: (value) {
              setState(() => _ones = value);
              _notify();
            },
            textStyle: textStyle,
          ),
          const SizedBox(width: 12),
          Text('%', style: textStyle?.copyWith(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _DigitWheel extends StatelessWidget {
  const _DigitWheel({
    required this.controller,
    required this.selectedValue,
    required this.onChanged,
    required this.textStyle,
  });

  final FixedExtentScrollController controller;
  final int selectedValue;
  final ValueChanged<int> onChanged;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 46,
      child: ListWheelScrollView.useDelegate(
        controller: controller,
        itemExtent: 34,
        diameterRatio: 1.9,
        perspective: 0.002,
        physics: const FixedExtentScrollPhysics(),
        onSelectedItemChanged: onChanged,
        childDelegate: ListWheelChildBuilderDelegate(
          childCount: 10,
          builder: (context, index) {
            if (index < 0 || index > 9) return null;
            final selected = index == selectedValue;
            return Center(
              child: Text(
                '$index',
                style: textStyle?.copyWith(
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                  fontSize: selected ? 22 : 16,
                  color: selected
                      ? Theme.of(context).colorScheme.onSurface
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
