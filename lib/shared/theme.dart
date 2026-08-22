import 'package:catui/catui.dart';
import 'package:flutter/material.dart';

import 'shift_colors.dart';

/// Beeshift's accent. catui defaults to the palette's mauve; yellow is this
/// app's choice, stated here rather than in the package so a second app can
/// pick its own without touching the house style.
///
/// Taken per flavor rather than fixed, so it tracks the brightness: latte's
/// yellow is dark, mocha's is light, and both carry [Flavor.base] as
/// foreground. secondary is left to catui.
ThemeData _theme(Flavor flavor, Brightness brightness) =>
    catTheme(flavor, brightness, primary: flavor.yellow).copyWith(
      // The Filter's chips are the only chips in either app, so catui leaves
      // them alone — stated here, on the consumer side, rather than pushing a
      // beeshift-shaped decision into the shared package. Matches the shared
      // corner radius instead of Material's fully-rounded chip default.
      chipTheme: const ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppTokens.radius)),
        ),
      ),
      // The Shift Colours ride the theme like every other colour, so a widget
      // reads them from context instead of importing a table.
      extensions: [ShiftColors.forFlavor(flavor)],
    );

final ThemeData lightTheme = _theme(catppuccin.latte, Brightness.light);
final ThemeData darkTheme = _theme(catppuccin.mocha, Brightness.dark);
