import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:functional_widget_annotation/functional_widget_annotation.dart';
import 'package:provider/provider.dart' as pr;
import 'package:zest_client/components/drawers/add_drawer.dart';
import 'package:zest_client/components/health_page.dart';
import 'package:zest_client/components/home_page.dart';
import 'package:zest_client/components/profile_page.dart';
import 'package:zest_client/components/topo_background.dart';
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

    body: Stack(
      children: [
        // bg effect
        Container(
          width: double.infinity,
          height: MediaQuery.of(context).size.height * 0.5,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.transparent, Color.fromARGB(50, 64, 255, 50)],
              transform: GradientRotation(-0.5 * pi),
            ),
          ),
          child: Opacity(opacity: 98 / 255, child: TopoBackground()),
        ),

        PageView(
          controller: pageController,
          onPageChanged: onPageChanged,
          children: const [
            HomePage(),
            WorkoutPage(),
            HealthPage(),
            ProfilePage(),
          ],
        ),
      ],
    ),

    bottomNavigationBar: Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      child: NavBar(selectedIndex: selectedIndex.value, onNavTap: onNavTap),
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

  return SafeArea(
    child: ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: Color.fromARGB(80, 64, 255, 50)),
            borderRadius: BorderRadius.circular(24),
            // gradient: LinearGradient(
            //   colors: [Colors.transparent, Color.fromARGB(200, 64, 255, 50)],
            //   transform: GradientRotation(0.5 * pi),
            // ),
            color: Color.fromARGB(40, 64, 255, 50),
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
                icon: Icon(Icons.home_rounded, color: Colors.white),
                label: lang.getText("home_page"),
              ),
              NavigationDestination(
                icon: Icon(Icons.fitness_center_rounded, color: Colors.white),
                label: lang.getText("workout_page"),
              ),

              IconButton(
                style: ButtonStyle(
                  backgroundBuilder: (context, states, child) => Container(
                    margin: EdgeInsets.all(6),
                    height: double.infinity,
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Color.fromARGB(80, 64, 255, 50),
                      ),
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          Color.fromARGB(50, 64, 255, 50),
                        ],
                        transform: GradientRotation(0.75 * pi),
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.add_rounded,
                      size: 38,
                      color: Colors.white,
                    ),
                  ),
                ),
                icon: const Icon(
                  Icons.add_rounded,
                  size: 38,
                  color: Colors.white,
                ),
                onPressed: () => showModalBottomSheet(
                  context: context,
                  builder: (BuildContext context) => AddDrawer(),
                ),
              ),

              NavigationDestination(
                icon: Icon(Icons.favorite_rounded, color: Colors.white),
                label: lang.getText("health_page"),
              ),
              NavigationDestination(
                icon: Icon(Icons.person_rounded, color: Colors.white),
                label: lang.getText("profile_page"),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

@hwidget
Widget mainPageLayout(
  BuildContext context, {
  required String title,
  required IconData icon,
  required List<Widget> children,
}) {
  return Stack(
    children: [
      SingleChildScrollView(
        child: Stack(
          children: [
            Positioned.fill(
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    height: MediaQuery.of(context).size.height * 0.5,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color.fromARGB(255, 20, 20, 20),
                          Colors.transparent,
                        ],
                        transform: GradientRotation(-0.5 * pi),
                      ),
                    ),
                  ),

                  Expanded(
                    child: Container(
                      color: const Color.fromARGB(255, 20, 20, 20),
                      width: double.infinity,
                    ),
                  ),
                ],
              ),
            ),

            SafeArea(
              child: Padding(
                padding: EdgeInsets.all(24).copyWith(top: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [const SizedBox(height: 50), ...children],
                ),
              ),
            ),
          ],
        ),
      ),
      Positioned(
        top: 12,
        left: 24,
        right: 24,
        child: SafeArea(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ClipRRect(
                borderRadius: BorderRadiusGeometry.circular(24),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                  // filter: ImageFilter.blur(),
                  child: Container(
                    padding: const EdgeInsets.only(
                      left: 16,
                      right: 20,
                      top: 8,
                      bottom: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Color.fromARGB(75, 0, 0, 0),
                    ),
                    child: Row(
                      spacing: 8,
                      children: [
                        Icon(icon, color: Colors.white, size: 24),
                        Text(
                          title,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ],
  );
}
