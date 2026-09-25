import 'package:shadcn_flutter/shadcn_flutter.dart';

/// How the app says "this one is picked", in the one place both the Filter's
/// letters and the Month Editor's row of choices read it from. Both are a
/// plain [Button] wearing this style.
///
/// No fill: a hairline border in the thing's own colour, and its letter bold
/// in that same colour. The colour is the whole signal, which is why nothing
/// tints the face behind it — a fill and a border saying the same thing only
/// make the edge harder to read.
///
/// Unselected is deliberately quiet: the ordinary outline and the muted
/// foreground at normal weight, so a screen of six letters has exactly as many
/// loud ones as the user has chosen.
///
/// The two consumers stay separate widgets — one wraps and multi-selects, the
/// other is a single-choice row — so what is shared is the look, not the
/// behaviour. This is that look and nothing else.
///
/// Lives in the app rather than in a shared package for the same reason
/// [EqualRowSegmented] does: one app's idea of "picked" is a guess about what
/// a second app wants.
ButtonStyle pickedStyle(
  ThemeData theme, {
  required Color color,
  required bool selected,
}) {
  final ink = selected ? color : theme.colorScheme.mutedForeground;
  final edge = Border.all(color: selected ? color : theme.colorScheme.border);
  return ButtonStyle(
    variance: ButtonVariance.outline
        .withBorder(border: edge, hoverBorder: edge, focusBorder: edge)
        // Outline paints a faint fill at rest and a stronger one on hover.
        .withBackgroundColor(
          color: Colors.transparent,
          hoverColor: Colors.transparent,
          focusColor: Colors.transparent,
        )
        .copyWith(
          // Every state: hover must not repaint the letter it is identifying.
          // Larger than the default label: these are the letters the user
          // reads off the real rota. Weight spelled out in both states so the
          // two stay one glance apart.
          textStyle: (context, states, style) => style.merge(
            theme.typography.base.copyWith(
              color: ink,
              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
  );
}
