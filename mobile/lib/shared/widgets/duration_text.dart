/// Big, monospaced mm:ss/hh:mm:ss duration display.
///
/// Pure presentation; the parent supplies the integer seconds so it
/// stays easy to drive from a stream / tick.
import 'package:flutter/material.dart';

class DurationText extends StatelessWidget {
  const DurationText({
    super.key,
    required this.seconds,
    this.style,
  });

  final int seconds;
  final TextStyle? style;

  String _format(int s) {
    final h = s ~/ 3600;
    final m = (s % 3600) ~/ 60;
    final sec = s % 60;
    final hh = h.toString().padLeft(2, '0');
    final mm = m.toString().padLeft(2, '0');
    final ss = sec.toString().padLeft(2, '0');
    return h > 0 ? '$hh:$mm:$ss' : '$mm:$ss';
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _format(seconds),
      textAlign: TextAlign.center,
      style: style ?? Theme.of(context).textTheme.displayLarge,
    );
  }
}