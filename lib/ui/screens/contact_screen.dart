import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../widgets/web_explanation_navbar.dart';

class TeamMemberData {
  final String name;
  final String email;
  final String imagePath;

  const TeamMemberData({
    required this.name,
    required this.email,
    required this.imagePath,
  });
}

class ContactScreen extends StatelessWidget {
  const ContactScreen({super.key});

  static const List<TeamMemberData> teamMembers = [
    TeamMemberData(
      name: 'Neil Erick Lipan Valdez',
      email: 'neil.lipan.valdez@gmail.com',
      imagePath: 'assets/images/Neil.webp',
    ),
    TeamMemberData(
      name: 'Eduardo Hugo Apaza Condori',
      email: 'eduardo.apaza@ucb.edu.bo',
      imagePath: 'assets/images/Eduardo.webp',
    ),
    TeamMemberData(
      name: 'Saire Marino Barroso Calle',
      email: 'saire.barroso@ucb.edu.bo',
      imagePath: 'assets/images/Marino.webp',
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
                      'Equipo SleepCode();',
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
                  'EQUIPO: SleepCode();',
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
            'Desarrolladores de SleepCode();',
            style: TextStyle(
              fontSize: width > 600 ? 30 : 22,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Conoce a los integrantes del equipo SleepCode(); y explora el código fuente del proyecto.',
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
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Square Image Hero Container (1:1 Aspect Ratio)
          AspectRatio(
            aspectRatio: 1.0,
            child: Image.asset(
              member.imagePath,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                color: colorScheme.primaryContainer.withValues(alpha: 0.5),
                child: Center(
                  child: Icon(
                    Icons.person_rounded,
                    size: 48,
                    color: colorScheme.primary,
                  ),
                ),
              ),
            ),
          ),

          // Name & Email Section
          Padding(
            padding: EdgeInsets.all(isCompact ? 16 : 20),
            child: Column(
              children: [
                Text(
                  member.name,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: isCompact ? 16 : 18,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () async {
                    final uri = Uri(scheme: 'mailto', path: member.email);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri);
                    }
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 4,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.email_outlined,
                          size: 14,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            member.email,
                            style: TextStyle(
                              fontSize: 12,
                              color: colorScheme.primary,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
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
            onPressed: () async {
              final uri = Uri.parse('https://github.com/marinobc/algorithm');
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
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
