import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:functional_widget_annotation/functional_widget_annotation.dart';
import 'package:provider/provider.dart' as pr;
import 'package:zest_client/components/custom_meal_page.dart';
import 'package:zest_client/components/custom_workout_page.dart';
import 'package:zest_client/components/drawers/add_drawer.dart';
import 'package:zest_client/components/health_page.dart';
import 'package:zest_client/components/home_page.dart';
import 'package:zest_client/components/profile_page.dart';
import 'package:zest_client/components/workout_page.dart';
import 'package:zest_client/providers/language_provider.dart';

part 'pages.g.dart';

@hwidget
Widget pages(BuildContext context) {
  final selectedIndex = useState(0);
  final pageController = usePageController();

  final onNavTap = useCallback(
    (int index) => pageController.animateToPage(
      index < 2 ? index : index - 1,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
    ),
    [pageController],
  );

  final onPageChanged = useCallback(
    (int index) => selectedIndex.value = index < 2 ? index : index + 1,
    [],
  );

  return Scaffold(
    extendBody: true,

    body: PageView(
      controller: pageController,
      onPageChanged: onPageChanged,
      children: const [HomePage(), WorkoutPage(), HealthPage(), ProfilePage()],
    ),

    bottomNavigationBar: Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      child: ClipRRect(
        borderRadius: BorderRadiusGeometry.circular(24),
        child: NavBar(selectedIndex: selectedIndex.value, onNavTap: onNavTap),
      ),
    ),

    // floatingActionButton: ,
    floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    resizeToAvoidBottomInset: false,
  );
}

@hwidget
Widget navBar(
  BuildContext context, {
  required int selectedIndex,
  required ValueChanged<int> onNavTap,
}) {
  final lang = pr.Provider.of<LanguageProvider>(context);

  return BackdropFilter(
    filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
    child: Container(
      decoration: BoxDecoration(
        border: Border.all(color: Color.fromARGB(80, 64, 255, 50)),
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [Colors.transparent, Color.fromARGB(200, 64, 255, 50)],
          transform: GradientRotation(0.5 * pi),
        ),
      ),
      padding: EdgeInsets.symmetric(horizontal: 4),
      child: NavigationBar(
        height: 72,
        backgroundColor: Colors.transparent,
        indicatorColor: Color.fromARGB(80, 64, 255, 50),
        labelTextStyle: WidgetStateProperty.resolveWith<TextStyle>(
          (states) => states.contains(WidgetState.selected)
              ? const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                )
              : const TextStyle(color: Colors.white),
        ),
        selectedIndex: selectedIndex,
        onDestinationSelected: onNavTap,
        destinations: [
          NavigationDestination(
            icon: Icon(Icons.home, color: Colors.white),
            label: lang.getText("home_page"),
          ),
          NavigationDestination(
            icon: Icon(Icons.fitness_center, color: Colors.white),
            label: lang.getText("workout_page"),
          ),

          IconButton(
            style: ButtonStyle(
              backgroundBuilder: (context, states, child) => Container(
                margin: EdgeInsets.all(6),
                height: double.infinity,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  border: Border.all(color: Color.fromARGB(80, 64, 255, 50)),
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      Color.fromARGB(50, 64, 255, 50),
                    ],
                    transform: GradientRotation(0.75 * pi),
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.add, size: 38, color: Colors.white),
              ),
            ),
            icon: const Icon(Icons.add, size: 38, color: Colors.white),
            onPressed: () => showDialog(
              context: context,
              builder: (BuildContext context) => AddDrawer(),
            ),
          ),

          NavigationDestination(
            icon: Icon(Icons.favorite, color: Colors.white),
            label: lang.getText("health_page"),
          ),
          NavigationDestination(
            icon: Icon(Icons.person, color: Colors.white),
            label: lang.getText("profile_page"),
          ),
        ],
      ),
    ),
  );
}
