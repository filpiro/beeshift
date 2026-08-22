import 'package:catui/catui.dart';
import 'package:flutter/material.dart';

import 'picked_style.dart';

/// One choice in an [EqualRowSegmented]: what selects it, what it draws, and
/// what a screen reader says instead — the drawn label and the spoken one are
/// allowed to differ, same trade as [CatSegmented].
class RowSegment<T> {
  const RowSegment({
    required this.value,
    required this.code,
    required this.color,
    this.label,
  });

  final T value;

  /// What is drawn on the button.
  final String code;

  /// What this segment turns when it is picked — its own colour, decided by
  /// the caller. The widget only draws it: which colour belongs to which
  /// value is not something a shared control can know.
  final Color color;

  /// What a screen reader announces. Falls back to [code] when not given.
  final String? label;
}

/// [CatSegmented]'s separate-buttons idiom, forced to equal shares and one
/// line rather than left to wrap: [Row] over [Wrap], each segment in an
/// [Expanded]. A phone's width divided evenly among six single-letter
/// buttons is exactly what a wrapping group would rather not fit on one line.
///
/// Lives here rather than in `catui`: a variant of an existing widget for one
/// consumer is a guess about what a second app wants. Goes upstream, next to
/// [CatSegmented], the day a second app needs equal-width forced-single-row
/// segments.
class EqualRowSegmented<T> extends StatelessWidget {
  const EqualRowSegmented({
    super.key,
    required this.segments,
    required this.selected,
    required this.onChanged,
  });

  /// In display order.
  final List<RowSegment<T>> segments;

  /// Null draws every segment outlined — a real state, not "nothing chosen
  /// yet" by omission.
  final T? selected;

  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        for (final (index, segment) in segments.indexed) ...[
          if (index > 0) const SizedBox(width: AppTokens.segmentGap),
          Expanded(child: _button(theme, segment)),
        ],
      ],
    );
  }

  /// Outlined either way: the picked one says so with its border and its
  /// letter, not with a filled face — see [pickedStyle].
  Widget _button(ThemeData theme, RowSegment<T> segment) {
    final isSelected = segment.value == selected;
    final picked = pickedStyle(
      theme,
      color: segment.color,
      selected: isSelected,
    );
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        // Only the row's own constraint: tall enough to be a real tap target.
        // Width is [Expanded]'s job, not the button's.
        minimumSize: const Size(0, 48),
        side: picked.side,
        textStyle: picked.labelStyle,
        foregroundColor: picked.labelStyle?.color,
      ),
      onPressed: () => onChanged(segment.value),
      // Said out loud, because nothing else says it: an outlined button
      // carries no selected flag of its own, and now that the fill is gone the
      // colour is the only thing announcing it on screen. Inside the button
      // rather than around it, so it lands on the node the button already
      // publishes instead of a second one beside it.
      child: Semantics(
        selected: isSelected,
        child: Text(segment.code, semanticsLabel: segment.label),
      ),
    );
  }
}
