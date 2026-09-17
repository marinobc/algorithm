import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../algorithms/core/algorithm_registry.dart';
import '../screens/assignment_algo_screen.dart';
import '../screens/contact_screen.dart';
import '../screens/graph_editor_screen.dart';
import '../screens/johnson_algo_screen.dart';
import '../screens/welcome_explanation_screen.dart';
import '../screens/what_are_graphs_screen.dart';

enum ExplanationWebPage { algorithms, graphs, assignment, johnson, contact }

class WebExplanationShell extends ConsumerWidget {
  final ExplanationWebPage activePage;
  final Widget? child;

  const WebExplanationShell({super.key, required this.activePage, this.child});

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
      case ExplanationWebPage.contact:
        targetScreen = const ContactScreen();
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

  void _goToApp(BuildContext context, WidgetRef ref) {
    if (activePage == ExplanationWebPage.assignment) {
      ref
          .read(activeAlgorithmProvider.notifier)
          .selectById(AlgorithmRegistry.assignmentId);
    } else if (activePage == ExplanationWebPage.johnson) {
      ref
          .read(activeAlgorithmProvider.notifier)
          .selectById(AlgorithmRegistry.johnsonId);
    } else {
      ref.read(activeAlgorithmProvider.notifier).clear();
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const GraphEditorScreen()),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final width = MediaQuery.of(context).size.width;

    if (width >= 1024) {
      // Desktop Viewport Layout: Left Vertical Sidebar Navigation (>= 1024px)
      return Scaffold(
        backgroundColor: colorScheme.surface,
        body: SafeArea(
          top: true,
          bottom: true,
          left: true,
          right: true,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Left Desktop Vertical Menu Sidebar (270px)
              Container(
                width: 270,
                height: double.infinity,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHigh,
                  border: Border(
                    right: BorderSide(
                      color: colorScheme.outline.withValues(alpha: 0.25),
                      width: 1.5,
                    ),
                  ),
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 20,
                          ),
                          child: _buildSidebarMenuContent(context, ref),
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Right Scrollable Main Content Area
              Expanded(
                child: SizedBox(
                  height: double.infinity,
                  child: child ?? const SizedBox.shrink(),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Mobile & Tablet Viewport Layout (< 1024px) with Side Drawer
    final topPadding = MediaQuery.of(context).padding.top;
    return Scaffold(
      backgroundColor: colorScheme.surface,
      drawer: Drawer(
        backgroundColor: colorScheme.surfaceContainerHigh,
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 20,
                    ),
                    child: _buildSidebarMenuContent(
                      context,
                      ref,
                      isDrawer: true,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(60 + (topPadding > 0 ? topPadding : 0)),
        child: Container(
          padding: EdgeInsets.only(
            top: topPadding > 0 ? topPadding + 4 : 8,
            bottom: 8,
            left: 16,
            right: 16,
          ),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHigh,
            border: Border(
              bottom: BorderSide(
                color: colorScheme.outline.withValues(alpha: 0.25),
                width: 1.5,
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Mobile Logo & Brand Title
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: colorScheme.outline.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(3),
                      child: SvgPicture.asset(
                        'assets/icons/logo.svg',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'sleepNode',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ],
              ),

              // Mobile Hamburger Drawer Trigger Button
              Builder(
                builder: (scaffoldCtx) => IconButton(
                  icon: Icon(
                    Icons.menu_rounded,
                    color: colorScheme.primary,
                    size: 26,
                  ),
                  tooltip: 'Abrir Menú Principal',
                  onPressed: () => Scaffold.of(scaffoldCtx).openDrawer(),
                ),
              ),
            ],
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        left: true,
        right: true,
        bottom: true,
        child: child ?? const SizedBox.shrink(),
      ),
    );
  }

  Widget _buildSidebarMenuContent(
    BuildContext context,
    WidgetRef ref, {
    bool isDrawer = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top Logo & Brand Title
        InkWell(
          onTap: () {
            if (isDrawer) Navigator.of(context).pop();
            _navigateTo(context, ExplanationWebPage.algorithms);
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: colorScheme.outline.withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: SvgPicture.asset(
                      'assets/icons/logo.svg',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'sleepNode',
                    style: const TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.3,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),

        // FIRST ACTION OPTION: "Editar Grafos"
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: () {
              if (isDrawer) Navigator.of(context).pop();
              _goToApp(context, ref);
            },
            style: FilledButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
            ),
            icon: const Icon(Icons.edit_note_rounded, size: 20),
            label: const Text(
              'Editar Grafos',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
        ),
        const SizedBox(height: 20),
        const Divider(height: 1),
        const SizedBox(height: 16),

        // Sidebar Section Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Text(
            'TEMAS Y GUÍAS',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
              color: colorScheme.primary,
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Vertical Navigation Menu Items
        _buildVerticalNavLink(
          context,
          label: '1. Inicio',
          page: ExplanationWebPage.algorithms,
          icon: Icons.home_outlined,
          isDrawer: isDrawer,
        ),
        const SizedBox(height: 6),
        _buildVerticalNavLink(
          context,
          label: '2. Grafos',
          page: ExplanationWebPage.graphs,
          icon: Icons.hub_outlined,
          isDrawer: isDrawer,
        ),
        const SizedBox(height: 14),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 4.0),
          child: Text(
            'Algoritmos',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
              color: colorScheme.primary,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.only(left: 12.0),
          child: Column(
            children: [
              _buildVerticalNavLink(
                context,
                label: 'Asignación',
                page: ExplanationWebPage.assignment,
                icon: Icons.assignment_turned_in_outlined,
                isDrawer: isDrawer,
              ),
              const SizedBox(height: 6),
              _buildVerticalNavLink(
                context,
                label: 'Johnson',
                page: ExplanationWebPage.johnson,
                icon: Icons.alt_route_rounded,
                isDrawer: isDrawer,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Divider(height: 1, indent: 12, endIndent: 12),
        const SizedBox(height: 12),
        _buildVerticalNavLink(
          context,
          label: 'Contacto',
          page: ExplanationWebPage.contact,
          icon: Icons.people_outline_rounded,
          isDrawer: isDrawer,
        ),
      ],
    );
  }

  Widget _buildVerticalNavLink(
    BuildContext context, {
    required String label,
    required ExplanationWebPage page,
    required IconData icon,
    bool isDrawer = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final isActive = page == activePage;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          if (isDrawer) Navigator.of(context).pop();
          _navigateTo(context, page);
        },
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: isActive
                ? colorScheme.primaryContainer.withValues(alpha: 0.8)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: isActive
                ? Border.all(
                    color: colorScheme.primary.withValues(alpha: 0.4),
                    width: 1.5,
                  )
                : Border.all(color: Colors.transparent),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 18,
                color: isActive
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                    fontSize: 13.5,
                    color: isActive
                        ? colorScheme.onSurface
                        : colorScheme.onSurfaceVariant,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

typedef WebExplanationNavbar = WebExplanationShell;
