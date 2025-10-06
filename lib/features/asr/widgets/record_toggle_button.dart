import 'package:flutter/material.dart';

class RecordToggleButton extends StatelessWidget {
  final bool isRecording;   
  final VoidCallback onStart;
  final VoidCallback onStop;
  final bool disabled;      
  final double size;        

  const RecordToggleButton({
    super.key,
    required this.isRecording,
    required this.onStart,
    required this.onStop,
    this.disabled = false,
    this.size = 56,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final icon = isRecording
        ? const Icon(Icons.stop, color: Colors.red, size: 30)
        : Icon(Icons.mic, color: theme.primaryColor, size: 30);

    final bgColor = isRecording
        ? Colors.red.withOpacity(0.1)
        : theme.primaryColor.withOpacity(0.1);

    return ClipOval(
      child: Material(
        color: bgColor,
        child: InkWell(
          onTap: disabled ? null : () => (isRecording ? onStop() : onStart()),
          child: SizedBox(width: size, height: size, child: icon),
        ),
      ),
    );
  }
}