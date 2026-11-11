import 'package:binder/models/enums/priority.dart';
import 'package:binder/theme/app_theme.dart';
import 'package:flutter/material.dart';

// mga decisions kung anong color na pwede ma reuse
class ColorUtils {
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
