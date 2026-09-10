import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

import '../../application/providers/grafo_provider.dart';
import '../../domain/services/ai_graph_command_executor.dart';
import '../../domain/services/ai_local_fallback_service.dart';
import '../../domain/services/ai_prompt_service.dart';
import 'ai_chat/chat_input_field.dart';
import 'ai_chat/chat_message_bubble.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({required this.text, required this.isUser, DateTime? timestamp})
    : timestamp = timestamp ?? DateTime.now();
}

class AIChatDialog extends ConsumerStatefulWidget {
  const AIChatDialog({super.key});

  @override
  ConsumerState<AIChatDialog> createState() => _AIChatDialogState();
}

class _AIChatDialogState extends ConsumerState<AIChatDialog> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isAnalyzing = false;
  late final String? _apiKey;

  @override
  void initState() {
    super.initState();
    _apiKey =
        dotenv.env['GEMINI_API_KEY'] ??
        (const String.fromEnvironment('GEMINI_API_KEY').isNotEmpty
            ? const String.fromEnvironment('GEMINI_API_KEY')
            : null);

    _messages.add(
      ChatMessage(
        text:
            '¡Hola! Soy tu **Asistente Experto en Grafos**.\n\n'
            'Puedes hacerme consultas sobre:\n'
            '• La **matriz de adyacencia** y grados de tu grafo actual.\n'
            '• **Cómo usar la aplicación** y sus funciones.\n'
            '• **Crear o modificar grafos** (ej. *"Crea un grafo con los países de América del Sur y sus fronteras"* o *"Añade un nodo llamado Brasil"*).',
        isUser: false,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isAnalyzing) return;

    setState(() {
      _messages.add(ChatMessage(text: text, isUser: true));
      _isAnalyzing = true;
    });

    _controller.clear();
    _scrollToBottom();

    try {
      final graph = ref.read(grafoProvider);
      final key = _apiKey?.trim();
      if (key != null && key.isNotEmpty) {
        final systemPrompt = AIPromptService.buildSystemPrompt(graph);
        final chatHistory = _messages.map((m) {
          return m.isUser
              ? Content.text(m.text)
              : Content.model([TextPart(m.text)]);
        }).toList();

        final response = await _generateWithModelFallback(
          apiKey: key,
          systemPrompt: systemPrompt,
          chatHistory: chatHistory.take(chatHistory.length - 1).toList(),
          userPrompt: text,
        );

        final responseText = response.text ?? 'No se pudo obtener respuesta.';
        if (mounted) {
          setState(() {
            _messages.add(ChatMessage(text: responseText, isUser: false));
            _isAnalyzing = false;
          });
          _scrollToBottom();
          _processGraphActions(responseText);
        }
      } else {
        final responseText = AILocalFallbackService.generateFallbackResponse(
          text,
          graph,
        );
        if (mounted) {
          setState(() {
            _messages.add(ChatMessage(text: responseText, isUser: false));
            _isAnalyzing = false;
          });
          _scrollToBottom();
        }
      }
    } catch (e) {
      if (mounted) {
        final errStr = e.toString();
        final isNetworkError =
            errStr.contains('SocketException') ||
            errStr.contains('Failed host lookup') ||
            errStr.contains('No address associated with hostname') ||
            errStr.contains('network is unreachable');

        final String errorText;
        if (isNetworkError) {
          errorText =
              '⚠️ Error de conexión a red:\n'
              'No fue posible conectar con los servidores de Gemini AI (Failed host lookup).\n\n'
              'Por favor, verifica tu conexión a Internet e inténtalo de nuevo.';
        } else {
          errorText =
              '⚠️ Error al comunicarse con Gemini AI: $e\n\n'
              'Asegúrate de que tu `GEMINI_API_KEY` en el archivo `.env` sea válida y tenga acceso a la API.';
        }

        setState(() {
          _messages.add(ChatMessage(text: errorText, isUser: false));
          _isAnalyzing = false;
        });
        _scrollToBottom();
      }
    }
  }

  Future<GenerateContentResponse> _generateWithModelFallback({
    required String apiKey,
    required String systemPrompt,
    required List<Content> chatHistory,
    required String userPrompt,
  }) async {
    final candidateModels = [
      'gemini-2.0-flash',
      'gemini-1.5-flash',
      'gemini-1.5-pro',
    ];

    Object? lastException;

    for (final modelName in candidateModels) {
      try {
        final model = GenerativeModel(
          model: modelName,
          apiKey: apiKey,
          systemInstruction: Content.system(systemPrompt),
        );

        final response = await model.generateContent([
          ...chatHistory,
          Content.text(userPrompt),
        ]);

        return response;
      } catch (e) {
        lastException = e;
        final errLower = e.toString().toLowerCase();
        if (errLower.contains('socketexception') ||
            errLower.contains('failed host lookup') ||
            errLower.contains('no address associated with hostname') ||
            errLower.contains('network is unreachable')) {
          break;
        }
      }
    }

    throw lastException ??
        Exception('No se pudo conectar con ningún modelo de Gemini.');
  }

  void _processGraphActions(String responseText) {
    AIGraphCommandExecutor.processGraphActions(
      responseText: responseText,
      ref: ref,
      context: context,
      isMounted: () => mounted,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final hasApiKey = _apiKey != null && _apiKey.trim().isNotEmpty;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        width: 540,
        height: 640,
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: colorScheme.primaryContainer,
                  child: Icon(
                    Icons.auto_awesome,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Asistente IA de Grafos',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Análisis de matriz, manual e inserción/edición de grafos',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            if (!hasApiKey)
              Container(
                margin: const EdgeInsets.only(top: 10),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.tertiaryContainer.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: colorScheme.tertiary.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.key_rounded,
                      size: 16,
                      color: colorScheme.onTertiaryContainer,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Clave GEMINI_API_KEY no detectada en .env. Modo analizador local activo.',
                        style: TextStyle(
                          fontSize: 11,
                          color: colorScheme.onTertiaryContainer,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const Divider(height: 20),
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final msg = _messages[index];
                  return ChatMessageBubble(
                    text: msg.text,
                    isUser: msg.isUser,
                    theme: theme,
                    colorScheme: colorScheme,
                  );
                },
              ),
            ),
            if (_isAnalyzing)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6.0),
                child: Row(
                  children: [
                    SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Gemini procesando y analizando...',
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 8),
            ChatInputField(
              controller: _controller,
              onSend: _sendMessage,
              colorScheme: colorScheme,
            ),
          ],
        ),
      ),
    );
  }
}
