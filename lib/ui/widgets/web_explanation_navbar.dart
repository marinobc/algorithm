import 'package:flutter/material.dart';
import '../screens/assignment_algo_screen.dart';
import '../screens/home_library_screen.dart';
import '../screens/johnson_algo_screen.dart';
import '../screens/welcome_explanation_screen.dart';
import '../screens/what_are_graphs_screen.dart';

enum ExplanationWebPage { algorithms, graphs, assignment, johnson }

class WebExplanationNavbar extends StatelessWidget {
  final ExplanationWebPage activePage;

  const WebExplanationNavbar({
    super.key,
    required this.activePage,
  });

  void _navigateTo(BuildContext context, ExplanationWebPage page) {
    if (page == activePage) return;

    Widget targetScreen;
    switch (page) {
      case ExplanationWebPage.algorithms:
        targetScreen = const WelcomeExplanationScreen();
        break;
      case ExplanationWebPage.graphs:
        targetScreen = const WhatAreGraphsScreen();
        break;
      case ExplanationWebPage.assignment:
        targetScreen = const AssignmentAlgoScreen();
        break;
      case ExplanationWebPage.johnson:
        targetScreen = const JohnsonAlgoScreen();
        break;
    }

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => targetScreen,
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 250),
      ),
    );
  }

  void _goToApp(BuildContext context) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeLibraryScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final width = MediaQuery.of(context).size.width;

    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Logo and Title
              InkWell(
                onTap: () => _navigateTo(context, ExplanationWebPage.algorithms),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: colorScheme.primary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.hub_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Nodos & Algoritmos',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.3,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Navigation Links (Wide screen) or Menu Button (Mobile)
              if (width >= 850)
                Row(
                  children: [
                    _buildNavLink(
                      context,
                      label: 'Algoritmos',
                      page: ExplanationWebPage.algorithms,
                      icon: Icons.lightbulb_outline_rounded,
                    ),
                    const SizedBox(width: 4),
                    _buildNavLink(
                      context,
                      label: '¿Qué son Grafos?',
                      page: ExplanationWebPage.graphs,
                      icon: Icons.bubble_chart_outlined,
                    ),
                    const SizedBox(width: 4),
                    _buildNavLink(
                      context,
                      label: 'Algoritmo Asignación',
                      page: ExplanationWebPage.assignment,
                      icon: Icons.assignment_turned_in_outlined,
                    ),
                    const SizedBox(width: 4),
                    _buildNavLink(
                      context,
                      label: 'Algoritmo Johnson',
                      page: ExplanationWebPage.johnson,
                      icon: Icons.alt_route_rounded,
                    ),
                  ],
                ),

              // Action CTA & Mobile Dropdown
              Row(
                children: [
                  if (width < 850)
                    PopupMenuButton<ExplanationWebPage>(
                      tooltip: 'Navegar Temas',
                      icon: Icon(Icons.menu_rounded, color: colorScheme.primary),
                      onSelected: (page) => _navigateTo(context, page),
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: ExplanationWebPage.algorithms,
                          child: Text('1. ¿Qué son Algoritmos?'),
                        ),
                        const PopupMenuItem(
                          value: ExplanationWebPage.graphs,
                          child: Text('2. ¿Qué son Grafos?'),
                        ),
                        const PopupMenuItem(
                          value: ExplanationWebPage.assignment,
                          child: Text('3. Algoritmo Asignación'),
                        ),
                        const PopupMenuItem(
                          value: ExplanationWebPage.johnson,
                          child: Text('4. Algoritmo Johnson'),
                        ),
                      ],
                    ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: () => _goToApp(context),
                    style: FilledButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.apps_rounded, size: 18),
                    label: const Text(
                      'Ir a la App',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavLink(
    BuildContext context, {
    required String label,
    required ExplanationWebPage page,
    required IconData icon,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final isActive = page == activePage;

    return TextButton.icon(
      onPressed: () => _navigateTo(context, page),
      style: TextButton.styleFrom(
        foregroundColor:
            isActive ? colorScheme.primary : colorScheme.onSurfaceVariant,
        backgroundColor: isActive
            ? colorScheme.primaryContainer.withValues(alpha: 0.6)
            : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      icon: Icon(icon, size: 16),
      label: Text(
        label,
        style: TextStyle(
          fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
          fontSize: 13,
        ),
      ),
    );
  }
}
