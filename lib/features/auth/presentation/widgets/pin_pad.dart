import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';

/// Large-key PIN entry (PRD N10: large numerals, 48 dp+ targets). Calls
/// [onCompleted] once four digits are entered, then clears itself.
class PinPad extends StatefulWidget {
  const PinPad({super.key, required this.onCompleted, this.enabled = true});

  final Future<void> Function(String pin) onCompleted;
  final bool enabled;

  static const length = 4;

  @override
  State<PinPad> createState() => _PinPadState();
}

class _PinPadState extends State<PinPad> {
  String _pin = '';

  Future<void> _press(String digit) async {
    if (!widget.enabled || _pin.length >= PinPad.length) return;
    setState(() => _pin += digit);
    if (_pin.length == PinPad.length) {
      final pin = _pin;
      await widget.onCompleted(pin);
      if (mounted) setState(() => _pin = '');
    }
  }

  void _backspace() {
    if (_pin.isNotEmpty) {
      setState(() => _pin = _pin.substring(0, _pin.length - 1));
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    Widget key(String digit) => _Key(
      label: digit,
      semanticsLabel: digit,
      onPressed: () => _press(digit),
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          label: '${_pin.length} / ${PinPad.length}',
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < PinPad.length; i++)
                Container(
                  key: ValueKey('pin-dot-$i'),
                  margin: const EdgeInsets.all(10),
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i < _pin.length ? scheme.primary : null,
                    border: Border.all(color: scheme.primary, width: 2),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        for (final row in const [
          ['1', '2', '3'],
          ['4', '5', '6'],
          ['7', '8', '9'],
        ])
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [for (final d in row) key(d)],
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(width: 88, height: 72),
            key('0'),
            _Key(
              icon: FluentIcons.backspace_24_regular,
              semanticsLabel: MaterialLocalizations.of(context)
                  .deleteButtonTooltip,
              onPressed: _backspace,
            ),
          ],
        ),
      ],
    );
  }
}

class _Key extends StatelessWidget {
  const _Key({
    this.label,
    this.icon,
    required this.semanticsLabel,
    required this.onPressed,
  });

  final String? label;
  final IconData? icon;
  final String semanticsLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(8),
    child: SizedBox(
      width: 72,
      height: 56,
      child: TextButton(
        onPressed: onPressed,
        child: label != null
            ? Text(
                label!,
                semanticsLabel: semanticsLabel,
                style: Theme.of(context).textTheme.headlineMedium,
              )
            : Icon(icon, semanticLabel: semanticsLabel),
      ),
    ),
  );
}
