import 'package:catui/catui.dart';
import 'package:flutter/material.dart';

/// One choice in an [EqualRowSegmented]: what selects it, what it draws, and
/// what a screen reader says instead — the drawn label and the spoken one are
/// allowed to differ, same trade as [CatSegmented].
class RowSegment<T> {
  const RowSegment({required this.value, required this.code, this.label});

  final T value;

  /// What is drawn on the button.
  final String code;

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
    return Row(
      children: [
        for (final (index, segment) in segments.indexed) ...[
          if (index > 0) const SizedBox(width: AppTokens.segmentGap),
          Expanded(
            child: segment.value == selected
                ? FilledButton(
                    style: _style,
                    onPressed: () => onChanged(segment.value),
                    child: Text(segment.code, semanticsLabel: segment.label),
                  )
                : OutlinedButton(
                    style: _style,
                    onPressed: () => onChanged(segment.value),
                    child: Text(segment.code, semanticsLabel: segment.label),
                  ),
          ),
        ],
      ],
    );
  }

  /// Only the row's own constraint: tall enough to be a real tap target.
  /// Width is [Expanded]'s job, not the button's.
  static const _style = ButtonStyle(
    minimumSize: WidgetStatePropertyAll(Size(0, 48)),
  );
}
