import 'package:flutter/material.dart';

class SaveButton extends StatelessWidget {
  final bool enabled;              
  final bool loading;              
  final VoidCallback onPressed;    
  final String label;

  const SaveButton({
    super.key,
    required this.enabled,
    required this.loading,
    required this.onPressed,
    this.label = '保存',
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: (enabled && !loading) ? onPressed : null,
      icon: loading
          ? const SizedBox(
              width: 16, height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.save),
      label: Text(label),
    );
  }
}
