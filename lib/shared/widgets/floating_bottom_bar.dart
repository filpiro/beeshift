import 'package:flutter/material.dart';

/// Space the Calendar reserves under its grid for [FloatingBottomBar]: the
/// bar's own height, the margin below it, and a further gap so the last row
/// is not touching it. Kept alongside the bar rather than guessed at from
/// the caller's side.
const barReserve = 80.0;

/// Gap between the bar and the bottom of the screen.
const barBottomMargin = 16.0;

/// One button in a [FloatingBottomBar]: a destination, drawn active while its
/// screen is showing, or an action — pass [active]: false and it never lights
/// up. A null [onPressed] disables the button.
class BarDestination {
  const BarDestination({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.active = false,
  });

  final IconData icon;

  /// The button's name to a screen reader — the glyph alone says nothing.
  final String label;

  final VoidCallback? onPressed;

  final bool active;
}

/// A rounded pill floating above the bottom edge, hugging its buttons rather
/// than spanning the screen. Lives here rather than in `catui`: it has one
/// consumer today — see ADR 0004 — and a third destination is a list entry,
/// not a new widget.
class FloatingBottomBar extends StatelessWidget {
  const FloatingBottomBar({super.key, required this.destinations});

  final List<BarDestination> destinations;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerHigh,
      elevation: 4,
      shape: const StadiumBorder(),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [for (final d in destinations) _BarButton(d)],
        ),
      ),
    );
  }
}

class _BarButton extends StatelessWidget {
  const _BarButton(this.destination);

  final BarDestination destination;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return IconButton(
      // A stable key, not the tooltip: the tooltip is its own widget one
      // level down, so finding a button by its tooltip finds that instead.
      key: Key(destination.label),
      tooltip: destination.label,
      onPressed: destination.onPressed,
      style: IconButton.styleFrom(
        shape: const StadiumBorder(),
        backgroundColor: destination.active ? scheme.primary : null,
        foregroundColor: destination.active
            ? scheme.onPrimary
            : scheme.onSurfaceVariant,
      ),
      // The tooltip is a hint, not the accessible name — the glyph needs its
      // own label to be announced at all.
      icon: Icon(destination.icon, semanticLabel: destination.label),
    );
  }
}
