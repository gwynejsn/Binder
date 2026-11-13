import 'package:binder/screens/binder/binder_screen.dart';
import 'package:binder/screens/cleaner/cleaner_screen.dart';
import 'package:binder/screens/todo/todo_screen.dart';
import 'package:binder/theme/app_theme.dart';
import 'package:flutter/material.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<StatefulWidget> createState() {
    return MainNavigationState();
  }
}

class MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // https://api.flutter.dev/flutter/widgets/IndexedStack-class.html
      body: IndexedStack(
        index: _currentIndex,
        children: [
          TodoScreen(),
          BindersScreen(),
          CleanerScreen(),
          Container(),
          Container(),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.only(left: 20, right: 20, bottom: 30, top: 4),
        child: _navigationBar(),
      ),
    );
  }

  Widget _navigationBar() {
    return SizedBox(
      height: 64,
      child: Stack(
        alignment:
            Alignment.center, // to set the container and cleaner button center
        children: [
          Container(
            height: 56,
            decoration: BoxDecoration(
              color: AppTheme.surface.withValues(alpha: 0.96),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: AppTheme.border, width: 1.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.45),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _navItem(
                        index: 0,
                        label: 'Todo',
                        icon: Icons.check_circle_rounded,
                        unselectedIcon: Icons.check_circle_outline_rounded,
                      ),
                      _navItem(
                        index: 1,
                        label: 'Binder',
                        icon: Icons.folder_rounded,
                        unselectedIcon: Icons.folder_outlined,
                      ),
                    ],
                  ),
                ),

                // space para sa cleaner button
                const SizedBox(width: 58),

                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _navItem(
                        index: 3,
                        label: 'Calendar',
                        icon: Icons.calendar_month_rounded,
                        unselectedIcon: Icons.calendar_today_rounded,
                      ),
                      _navItem(
                        index: 4,
                        label: 'Pomodoro',
                        icon: Icons.timer_rounded,
                        unselectedIcon: Icons.timer_outlined,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // since this is a stack, this button is above the container with nav items!
          _cleanerButton(index: 2),
        ],
      ),
    );
  }

  Widget _navItem({
    required int index,
    required String label,
    required IconData icon,
    required IconData unselectedIcon,
  }) {
    // each nav item index corresponds to the specific screen index na nasa indexedStack
    final isSelected = _currentIndex == index;

    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 3.5),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppTheme.terracotta.withValues(alpha: 0.18)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              isSelected ? icon : unselectedIcon,
              color: isSelected
                  ? AppTheme.terracottaLight
                  : AppTheme.textSecondary.withValues(alpha: 0.65),
              size: 21,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            label,
            style: AppTheme.sans(
              fontSize: 10.5,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              color: isSelected
                  ? AppTheme.textPrimary
                  : AppTheme.textSecondary.withValues(alpha: 0.65),
            ),
          ),
        ],
      ),
    );
  }

  // we create a separate widget to customize this button
  Widget _cleanerButton({required int index}) {
    final isSelected = _currentIndex == index;

    return GestureDetector(
      onTap: () => setState(() => _currentIndex = 2),
      child: Container(
        width: 58,
        height: 58,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isSelected
                ? const [AppTheme.terracottaLight, AppTheme.terracotta]
                : const [AppTheme.terracotta, AppTheme.terracottaDark],
          ),
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected
                ? Colors.white
                : AppTheme.terracottaLight.withValues(alpha: 0.6),
            width: isSelected ? 2.2 : 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.terracotta.withValues(
                alpha: isSelected ? 0.5 : 0.35,
              ),
              blurRadius: isSelected ? 14 : 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Center(
          child: Icon(Icons.style_rounded, color: Color(0xFFFDFBF7), size: 24),
        ),
      ),
    );
  }
}
