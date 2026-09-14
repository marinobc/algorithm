import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

class VideoResourceCard extends StatelessWidget {
  final String title;
  final String description;
  final String videoUrl;
  final String? thumbnailUrl;
  final String durationOrAuthor;

  const VideoResourceCard({
    super.key,
    required this.title,
    required this.description,
    required this.videoUrl,
    this.thumbnailUrl,
    this.durationOrAuthor = 'Video Explicativo en YouTube',
  });

  String? _extractYouTubeThumbnail(String url) {
    if (thumbnailUrl != null && thumbnailUrl!.isNotEmpty) return thumbnailUrl;
    try {
      final videoId = YoutubePlayerController.convertUrlToId(url);
      if (videoId != null && videoId.isNotEmpty) {
        return 'https://img.youtube.com/vi/$videoId/hqdefault.jpg';
      }
    } catch (_) {}
    return null;
  }

  void _openVideo(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => _InlineVideoModal(
        title: title,
        videoUrl: videoUrl,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final computedThumbnail = _extractYouTubeThumbnail(videoUrl);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 820),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 24,
                spreadRadius: -2,
                offset: const Offset(0, 10),
              ),
              BoxShadow(
                color: colorScheme.primary.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: colorScheme.outlineVariant.withValues(alpha: 0.25),
                width: 1,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            color: colorScheme.surfaceContainerLow,
            child: InkWell(
              onTap: () => _openVideo(context),
              borderRadius: BorderRadius.circular(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Thumbnail Container with Play Overlay
                  if (computedThumbnail != null)
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        AspectRatio(
                          aspectRatio: 2.15,
                          child: Image.network(
                            computedThumbnail,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                                  color: Colors.red.withValues(alpha: 0.15),
                                  child: const Center(
                                    child: Icon(
                                      Icons.movie_rounded,
                                      size: 48,
                                      color: Colors.red,
                                    ),
                                  ),
                                ),
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                color: colorScheme.surfaceContainerHigh,
                                child: const Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        // Dark Vignette Overlay
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.black.withValues(alpha: 0.15),
                                  Colors.black.withValues(alpha: 0.65),
                                ],
                              ),
                            ),
                          ),
                        ),
                        // Glowing Play Button
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFF1744), Color(0xFFD50000)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.red.withValues(alpha: 0.65),
                                blurRadius: 24,
                                spreadRadius: 4,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                        // YouTube Watermark Badge Top Right
                        Positioned(
                          top: 12,
                          right: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.75),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.15),
                              ),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.play_circle_fill,
                                  color: Colors.red,
                                  size: 14,
                                ),
                                SizedBox(width: 6),
                                Text(
                                  'YouTube HD',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                  // Card Body
                  Padding(
                    padding: const EdgeInsets.all(18.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 12,
                          runSpacing: 8,
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.red.withValues(alpha: 0.3),
                                ),
                              ),
                              child: const Text(
                                'TUTORIAL RECOMENDADO',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ),
                            Text(
                              durationOrAuthor,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.2,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          description,
                          style: TextStyle(
                            fontSize: 13.5,
                            height: 1.4,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            FilledButton.icon(
                              onPressed: () => _openVideo(context),
                              style: FilledButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 2,
                              ),
                              icon: const Icon(
                                Icons.play_arrow_rounded,
                                size: 18,
                              ),
                              label: const Text(
                                'Ver video',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Video Player Inline Dialog Modal
// ---------------------------------------------------------------------------
class _InlineVideoModal extends StatefulWidget {
  final String title;
  final String videoUrl;

  const _InlineVideoModal({
    required this.title,
    required this.videoUrl,
  });

  @override
  State<_InlineVideoModal> createState() => _InlineVideoModalState();
}

class _InlineVideoModalState extends State<_InlineVideoModal> {
  late YoutubePlayerController _controller;

  @override
  void initState() {
    super.initState();
    final videoId =
        YoutubePlayerController.convertUrlToId(widget.videoUrl) ?? '';
    _controller = YoutubePlayerController.fromVideoId(
      videoId: videoId,
      autoPlay: true,
      params: const YoutubePlayerParams(
        showControls: true,
        showFullscreenButton: true,
        strictRelatedVideos: true,
        playsInline: true,
      ),
    );
  }

  @override
  void dispose() {
    _controller.close();
    super.dispose();
  }

  Future<void> _launchVideoUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final mediaQuery = MediaQuery.of(context);

    // Header height (padding + action buttons)
    const headerHeight = 52.0;

    // Standard card width (compact, non-blown-up modal width)
    const standardCardWidth = 720.0;

    // Available screen space considering modal margins
    final maxAvailableWidth = math.min(standardCardWidth, mediaQuery.size.width * 0.90);
    final maxAvailableHeight = mediaQuery.size.height * 0.85;

    // Max height allowed for the video player to fit within screen canvas
    final maxVideoHeight = math.max(100.0, maxAvailableHeight - headerHeight);

    // Compute exact video width: stays at standard card width, but shrinks horizontally if screen height is constrained
    final videoWidth = math.min(
      maxAvailableWidth,
      maxVideoHeight * (16 / 9),
    );

    return YoutubePlayerControllerProvider(
      controller: _controller,
      child: Dialog(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        clipBehavior: Clip.antiAlias,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: SizedBox(
          width: videoWidth,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Modal Header
              Container(
                height: headerHeight,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                color: colorScheme.surfaceContainerHighest,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => _launchVideoUrl(widget.videoUrl),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                      ),
                      icon: const Icon(Icons.open_in_new_rounded, size: 16),
                      label: const Text(
                        'YouTube',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      tooltip: 'Cerrar',
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),

              // Video Container — tight 16:9 aspect ratio, zero black bars!
              AspectRatio(
                aspectRatio: 16 / 9,
                child: YoutubePlayer(
                  controller: _controller,
                  aspectRatio: 16 / 9,
                  autoFullScreen: false,
                  enableFullScreenOnVerticalDrag: false,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}



