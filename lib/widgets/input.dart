import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/state.dart';

class HyperLocalInput extends StatelessWidget {
  final String label;
  final String placeholder;
  final bool obscureText;
  final TextInputType keyboardType;
  final ValueChanged<String>? onChanged;
  final String? initialValue;
  final TextEditingController? controller;
  final String? errorText;
  final bool isRequiredError;

  const HyperLocalInput({
    super.key,
    required this.label,
    required this.placeholder,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.onChanged,
    this.initialValue,
    this.controller,
    this.errorText,
    this.isRequiredError = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: isRequiredError ? theme.colorScheme.error : theme.colorScheme.onSurfaceVariant,
              fontWeight: isRequiredError ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: controller,
            initialValue: controller == null ? initialValue : null,
            obscureText: obscureText,
            keyboardType: keyboardType,
            onChanged: onChanged,
            decoration: InputDecoration(
              hintText: placeholder,
              hintStyle: const TextStyle(color: Color(0xFF757575)),
              filled: true,
              fillColor: theme.colorScheme.surfaceContainerLowest,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              errorText: errorText,
              errorStyle: isRequiredError ? TextStyle(color: theme.colorScheme.error, fontWeight: FontWeight.bold) : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: isRequiredError ? theme.colorScheme.error : theme.colorScheme.outlineVariant,
                  width: isRequiredError ? 2.0 : 1.0,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: isRequiredError ? theme.colorScheme.error : theme.colorScheme.outlineVariant,
                  width: isRequiredError ? 2.0 : 1.0,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: isRequiredError ? theme.colorScheme.error : theme.colorScheme.primary,
                  width: 2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class HyperLocalOTPField extends ConsumerStatefulWidget {
  final ValueChanged<String>? onCompleted;

  const HyperLocalOTPField({super.key, this.onCompleted});

  @override
  ConsumerState<HyperLocalOTPField> createState() => _HyperLocalOTPFieldState();
}

class _HyperLocalOTPFieldState extends ConsumerState<HyperLocalOTPField> {
  List<FocusNode>? _focusNodes;
  List<TextEditingController>? _controllers;
  int _length = 0;

  void _initFields(int length) {
    _length = length;
    _focusNodes = List.generate(length, (_) => FocusNode());
    _controllers = List.generate(length, (_) => TextEditingController());
  }

  @override
  void dispose() {
    if (_focusNodes != null) {
      for (var node in _focusNodes!) {
        node.dispose();
      }
    }
    if (_controllers != null) {
      for (var ctrl in _controllers!) {
        ctrl.dispose();
      }
    }
    super.dispose();
  }

  void _onChanged(String val, int idx) {
    if (val.length == 1 && idx < _length - 1) {
      _focusNodes![idx + 1].requestFocus();
    }
    
    final pin = _controllers!.map((c) => c.text).join();
    if (pin.length == _length && widget.onCompleted != null) {
      widget.onCompleted!(pin);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final config = ref.read(appConfigProvider);
    
    if (_controllers == null) {
      _initFields(config.otpLength);
    }
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(config.otpLength, (index) {
        return SizedBox(
          width: 40,
          height: 48,
          child: TextFormField(
            controller: _controllers![index],
            focusNode: _focusNodes![index],
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            maxLength: 1,
            onChanged: (val) => _onChanged(val, index),
            style: theme.textTheme.titleMedium,
            decoration: InputDecoration(
              counterText: '',
              filled: true,
              fillColor: theme.colorScheme.surfaceContainerLowest,
              contentPadding: EdgeInsets.zero,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
              ),
            ),
          ),
        );
      }),
    );
  }
}

