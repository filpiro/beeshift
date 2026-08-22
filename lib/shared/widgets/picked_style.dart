import 'package:flutter/material.dart';

/// How the app says "this one is picked", in the one place both the Filter's
/// chips and the Month Editor's row of choices read it from.
///
/// No fill: a two-pixel border in the thing's own colour, and its letter bold
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
/// Lives here rather than in `catui` for the same reason [EqualRowSegmented]
/// does: one app's idea of "picked" is a guess about what a second app wants.
/// Goes upstream the day a second app wants this exact idiom.
({BorderSide side, TextStyle? labelStyle}) pickedStyle(
  ThemeData theme, {
  required Color color,
  required bool selected,
}) => (
  side: selected
      ? BorderSide(color: color, width: 2)
      : BorderSide(color: theme.colorScheme.outlineVariant),
  // Larger than Material's default label in both places: these are the letters
  // the user reads off the real rota.
  labelStyle: theme.textTheme.titleMedium?.copyWith(
    color: selected ? color : theme.colorScheme.onSurfaceVariant,
    // Spelled out rather than left to fall through: `titleMedium` is w500 of
    // its own accord, and a null here would quietly keep it — near enough to
    // bold that the two states stop being one glance apart.
    fontWeight: selected ? FontWeight.bold : FontWeight.normal,
  ),
);
