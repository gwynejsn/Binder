import 'package:binder/models/enums/priority.dart';
import 'package:binder/theme/app_theme.dart';
import 'package:flutter/material.dart';

class ColorUtils {
  // to convert hex to Color
  static Color getColor(String hex) {
    try {
      return Color(int.parse(hex));
    } catch (_) {
      return AppTheme.terracotta;
    }
  }

  // mga decisions kung anong color na pwede ma reuse
  static Color priorityColor(Priority p) {
    switch (p) {
      case Priority.high:
        return AppTheme.rose;
      case Priority.medium:
        return AppTheme.wheat;
      case Priority.low:
        return AppTheme.sage;
    }
  }
}
