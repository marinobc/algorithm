import 'package:flutter/material.dart';

import '../widgets/web_explanation_navbar.dart';

class TeamMemberData {
  final String name;
  final String role;
  final String bio;
  final String email;
  final String github;
  final String? imagePath;
  final IconData icon;

  const TeamMemberData({
    required this.name,
    required this.role,
    required this.bio,
    required this.email,
    required this.github,
    this.imagePath,
    required this.icon,
  });
}

class ContactScreen extends StatelessWidget {
  const ContactScreen({super.key});

  static const List<TeamMemberData> teamMembers = [
    TeamMemberData(
      name: 'Desarrollador 1',
      role: 'Arquitecto de Software & Backend',
      bio: 'Especialista en estructura de aplicaciones, lógica de estado global y motor computacional de grafos.',
      email: 'desarrollador1@ejemplo.com',
      github: 'https://github.com/dev1',
      icon: Icons.code_rounded,
    ),
    TeamMemberData(
      name: 'Desarrollador 2',
      role: 'Diseñador UI/UX & Frontend',
      bio: 'Enfocado en la experiencia de usuario, diseño de interfaces responsivas y componentes interactivos.',
      email: 'desarrollador2@ejemplo.com',
      github: 'https://github.com/dev2',
      icon: Icons.palette_rounded,
    ),
    TeamMemberData(
      name: 'Desarrollador 3',
      role: 'Especialista en Algoritmos & QA',
      bio: 'Investigación e implementación de algoritmos de optimización (Johnson, Asignación) y aseguramiento de calidad.',
      email: 'desarrollador3@ejemplo.com',
      github: 'https://github.com/dev3',
      icon: Icons.functions_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final width = MediaQuery.of(context).size.width;

    return WebExplanationShell(
      activePage: ExplanationWebPage.contact,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.symmetric(
          horizontal: width > 1024
              ? 56
              : width > 600
              ? 32
              : 16,
          vertical: width > 600 ? 40 : 24,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Banner
                _buildHeaderBanner(context, width),
                SizedBox(height: width > 600 ? 40 : 28),

                // Team Section Title
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.badge_rounded,
                        color: colorScheme.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Nuestro Equipo de Desarrolladores (3)',
                      style: TextStyle(
                        fontSize: width > 600 ? 22 : 18,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Team Members Responsive Grid
                LayoutBuilder(
                  builder: (context, constraints) {
                    final maxWidth = constraints.maxWidth;
                    if (maxWidth > 850) {
                      // Desktop/Web View: 3 Columns
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: teamMembers
                            .map(
                              (member) => Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10.0,
                                  ),
                                  child: _buildTeamMemberCard(
                                    context,
                                    member,
                                    isCompact: false,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      );
                    } else if (maxWidth > 580) {
                      // Tablet View: 2 Top, 1 Bottom Centered
                      return Column(
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: _buildTeamMemberCard(
                                  context,
                                  teamMembers[0],
                                  isCompact: false,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildTeamMemberCard(
                                  context,
                                  teamMembers[1],
                                  isCompact: false,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 420),
                            child: _buildTeamMemberCard(
                              context,
                              teamMembers[2],
                              isCompact: false,
                            ),
                          ),
                        ],
                      );
                    } else {
                      // Mobile View: Single Column Stacked
                      return Column(
                        children: teamMembers
                            .map(
                              (member) => Padding(
                                padding: const EdgeInsets.only(bottom: 20.0),
                                child: _buildTeamMemberCard(
                                  context,
                                  member,
                                  isCompact: true,
                                ),
                              ),
                            )
                            .toList(),
                      );
                    }
                  },
                ),
                SizedBox(height: width > 600 ? 48 : 32),

                // General Contact Section
                _buildContactInfoSection(context, width),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderBanner(BuildContext context, double width) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(width > 600 ? 36 : 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primaryContainer,
            colorScheme.surfaceContainerHigh,
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: 0.25),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: colorScheme.primary.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.groups_rounded,
                  size: 16,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  'EQUIPO DE TRABAJO',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Contacto y Desarrolladores',
            style: TextStyle(
              fontSize: width > 600 ? 30 : 22,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Conoce a los 3 integrantes responsables del diseño, desarrollo y pruebas de esta plataforma educativa interactiva de grafos.',
            style: TextStyle(
              fontSize: width > 600 ? 15 : 13.5,
              height: 1.5,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamMemberCard(
    BuildContext context,
    TeamMemberData member, {
    required bool isCompact,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.35),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Square Image Hero Container (1:1 Aspect Ratio)
          AspectRatio(
            aspectRatio: 1.0,
            child: _buildSquareImageContent(context, member),
          ),

          // Content Details Section
          Padding(
            padding: EdgeInsets.all(isCompact ? 16 : 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name
                Text(
                  member.name,
                  style: TextStyle(
                    fontSize: isCompact ? 18 : 20,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 6),

                // Role Tag
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: colorScheme.primary.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Text(
                    member.role,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Bio
                Text(
                  member.bio,
                  style: TextStyle(
                    fontSize: 13.5,
                    height: 1.55,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 18),
                const Divider(height: 1),
                const SizedBox(height: 14),

                // Contact Email
                Row(
                  children: [
                    Icon(
                      Icons.email_outlined,
                      size: 16,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        member.email,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // GitHub Button
                Tooltip(
                  message: 'GitHub: ${member.github}',
                  child: InkWell(
                    onTap: () {},
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: colorScheme.outlineVariant.withValues(
                            alpha: 0.4,
                          ),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.code_rounded,
                            size: 16,
                            color: colorScheme.onSurface,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Ver en GitHub',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
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
        ],
      ),
    );
  }

  Widget _buildSquareImageContent(BuildContext context, TeamMemberData member) {
    final colorScheme = Theme.of(context).colorScheme;

    if (member.imagePath != null) {
      return Image.asset(
        member.imagePath!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            _buildSquareAvatarFallback(colorScheme, member),
      );
    } else {
      return _buildSquareAvatarFallback(colorScheme, member);
    }
  }

  Widget _buildSquareAvatarFallback(
    ColorScheme colorScheme,
    TeamMemberData member,
  ) {
    return Container(
      color: colorScheme.primaryContainer.withValues(alpha: 0.5),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surface.withValues(alpha: 0.7),
                shape: BoxShape.circle,
              ),
              child: Icon(member.icon, size: 40, color: colorScheme.primary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactInfoSection(BuildContext context, double width) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(width > 600 ? 28 : 20),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.mark_email_read_rounded,
                color: colorScheme.primary,
                size: 24,
              ),
              const SizedBox(width: 10),
              Text(
                'Contacto General & Repositorio',
                style: TextStyle(
                  fontSize: width > 600 ? 20 : 17,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Si deseas conocer más detalles del código fuente, arquitectura o contribuir al proyecto, puedes explorar el repositorio oficial.',
            style: TextStyle(
              fontSize: width > 600 ? 14 : 13,
              height: 1.5,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.code_rounded, size: 18),
            label: const Text('Ver Repositorio del Proyecto'),
          ),
        ],
      ),
    );
  }
}
