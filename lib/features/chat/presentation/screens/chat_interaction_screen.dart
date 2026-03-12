import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/services/gemini_service.dart';
import '../../../../core/services/groq_service.dart';
import '../../../../core/providers/language_provider.dart';
import '../providers/smart_prediction_provider.dart';
import '../widgets/soil_input_form.dart';
import '../widgets/crop_result_card.dart';

// ── Providers ──────────────────────────────────────────────────────────────

final chatHistoryProvider =
    StateProvider.autoDispose<List<ChatMessage>>((ref) => []);
final isChatProcessingProvider =
    StateProvider.autoDispose<bool>((ref) => false);

// ── ChatMessage model ──────────────────────────────────────────────────────

class ChatMessage {
  final String text;
  final bool isUser;
  final File? image;

  /// Non-null when this bubble contains Smart Prediction results.
  final List<CropAnalysis>? predictionResults;

  /// True when this is a transient loading step bubble.
  final bool isLoadingStep;

  ChatMessage({
    required this.text,
    required this.isUser,
    this.image,
    this.predictionResults,
    this.isLoadingStep = false,
  });
}

// ── Screen ─────────────────────────────────────────────────────────────────

class ChatInteractionScreen extends ConsumerStatefulWidget {
  const ChatInteractionScreen({super.key});

  @override
  ConsumerState<ChatInteractionScreen> createState() =>
      _ChatInteractionScreenState();
}

class _ChatInteractionScreenState
    extends ConsumerState<ChatInteractionScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;

  // Track the index of the last loading-step bubble so we can replace it.
  int? _loadingBubbleIndex;

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ── Smart Prediction listener ─────────────────────────────────────────

  /// Called by the Riverpod listener whenever the SmartPredictionState changes.
  void _onPredictionStateChanged(
    SmartPredictionState? prev,
    SmartPredictionState next,
  ) {
    final history = ref.read(chatHistoryProvider);

    switch (next.step) {
      case PredictionStep.idle:
        break;

      case PredictionStep.fetchingWeather:
      case PredictionStep.analyzingSoil:
      case PredictionStep.generatingReport:
        // Replace or append the loading bubble
        final bubble = ChatMessage(
          text: next.step.label,
          isUser: false,
          isLoadingStep: true,
        );
        if (_loadingBubbleIndex != null &&
            _loadingBubbleIndex! < history.length) {
          final updated = List<ChatMessage>.from(history);
          updated[_loadingBubbleIndex!] = bubble;
          ref.read(chatHistoryProvider.notifier).state = updated;
        } else {
          _loadingBubbleIndex = history.length;
          ref
              .read(chatHistoryProvider.notifier)
              .update((s) => [...s, bubble]);
        }
        _scrollToBottom();
        break;

      case PredictionStep.done:
        // Replace loading bubble with result bubble
        final resultBubble = ChatMessage(
          text: '🌾 Here are your Top 5 crop recommendations:',
          isUser: false,
          predictionResults: next.results,
        );
        final updated = List<ChatMessage>.from(history);
        if (_loadingBubbleIndex != null &&
            _loadingBubbleIndex! < updated.length) {
          updated[_loadingBubbleIndex!] = resultBubble;
        } else {
          updated.add(resultBubble);
        }
        ref.read(chatHistoryProvider.notifier).state = updated;
        _loadingBubbleIndex = null;
        _scrollToBottom();
        break;

      case PredictionStep.error:
        final errorBubble = ChatMessage(
          text: '❌ ${next.errorMessage ?? "An error occurred. Please try again."}',
          isUser: false,
        );
        final updated = List<ChatMessage>.from(history);
        if (_loadingBubbleIndex != null &&
            _loadingBubbleIndex! < updated.length) {
          updated[_loadingBubbleIndex!] = errorBubble;
        } else {
          updated.add(errorBubble);
        }
        ref.read(chatHistoryProvider.notifier).state = updated;
        _loadingBubbleIndex = null;
        _scrollToBottom();
        break;
    }
  }

  // ── Image pick ────────────────────────────────────────────────────────

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (pickedFile != null) {
        setState(() => _selectedImage = File(pickedFile.path));
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick image: $e')),
        );
      }
    }
  }

  // ── Send regular message ──────────────────────────────────────────────

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty && _selectedImage == null) return;

    final isProcessing = ref.read(isChatProcessingProvider);
    if (isProcessing) return;

    final userMsg = ChatMessage(
      text: text,
      isUser: true,
      image: _selectedImage,
    );
    ref
        .read(chatHistoryProvider.notifier)
        .update((state) => [...state, userMsg]);
    ref.read(isChatProcessingProvider.notifier).state = true;

    _textController.clear();
    final imageToAnalyze = _selectedImage;
    setState(() => _selectedImage = null);

    _scrollToBottom();

    try {
      final geminiService = GeminiService();
      String responseText = '';

      if (imageToAnalyze != null) {
        final userLangCode = ref.read(languageProvider);
        final userLangName = GeminiService.langCodeToName(userLangCode);
        final query =
            text.isNotEmpty ? text : 'Diagnose this crop issue.';
        final jsonResponse = await geminiService.analyzeCropDisease(
          imageToAnalyze,
          query,
          language: userLangName,
        );
        try {
          final cleanJson = jsonResponse
              .replaceAll('```json', '')
              .replaceAll('```', '')
              .trim();
          final Map<String, dynamic> data = json.decode(cleanJson);
          responseText = data.containsKey('summary_for_farmer')
              ? data['summary_for_farmer']
              : 'Analysis complete. Details:\n$cleanJson';
        } catch (_) {
          responseText = jsonResponse;
        }
      } else {
        final userLangCode = ref.read(languageProvider);
        final userLangName = GeminiService.langCodeToName(userLangCode);
        responseText =
            await geminiService.generateAnswer(text, language: userLangName);
      }

      final aiMsg = ChatMessage(text: responseText, isUser: false);
      ref
          .read(chatHistoryProvider.notifier)
          .update((state) => [...state, aiMsg]);
    } catch (e) {
      final errorMsg = ChatMessage(
        text: 'Sorry, an error occurred: $e',
        isUser: false,
      );
      ref
          .read(chatHistoryProvider.notifier)
          .update((state) => [...state, errorMsg]);
    } finally {
      ref.read(isChatProcessingProvider.notifier).state = false;
      _scrollToBottom();
    }
  }

  // ── Open Smart Prediction form ────────────────────────────────────────

  void _openSmartPrediction() {
    // Reset provider state before opening
    ref.read(smartPredictionProvider.notifier).reset();

    // Add an initial user-side message bubble
    final userMsg = ChatMessage(
      text: '🌱 Starting Smart Crop Prediction...',
      isUser: true,
    );
    ref
        .read(chatHistoryProvider.notifier)
        .update((s) => [...s, userMsg]);
    _loadingBubbleIndex = null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const SoilInputForm(),
    );
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

  // ── Build ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final history = ref.watch(chatHistoryProvider);
    final isProcessing = ref.watch(isChatProcessingProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Listen to prediction state changes
    ref.listen<SmartPredictionState>(
      smartPredictionProvider,
      _onPredictionStateChanged,
    );

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor:
          isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      appBar: AppBar(
        title: const Text('Ask Gram Gyan'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ── Chat List ─────────────────────────────────────────────
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                itemCount: history.length + (isProcessing ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == history.length) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  final msg = history[index];

                  // Smart Prediction result bubble
                  if (msg.predictionResults != null) {
                    return _PredictionResultBubble(
                      message: msg,
                      isDark: isDark,
                    );
                  }

                  // Loading step bubble
                  if (msg.isLoadingStep) {
                    return _LoadingStepBubble(text: msg.text, isDark: isDark);
                  }

                  // Regular chat bubble
                  return _ChatBubble(message: msg, isDark: isDark);
                },
              ),
            ),

            // ── Image Preview ─────────────────────────────────────────
            if (_selectedImage != null)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: isDark ? Colors.black12 : Colors.grey.shade100,
                child: Row(
                  children: [
                    Stack(
                      alignment: Alignment.topRight,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            _selectedImage!,
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: -4,
                          right: -4,
                          child: GestureDetector(
                            onTap: () =>
                                setState(() => _selectedImage = null),
                            child: Container(
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close,
                                  size: 16, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Image selected for analysis',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: Theme.of(context).hintColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // ── Input Area ────────────────────────────────────────────
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: isDark ? AppColors.cardDark : AppColors.cardLight,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // 📷 Image Button
                  IconButton(
                    onPressed: isProcessing
                        ? null
                        : () => _showImagePickerModal(context),
                    icon: Icon(
                      Icons.add_photo_alternate_rounded,
                      color: AppColors.primary,
                    ),
                    tooltip: 'Attach Image',
                  ),

                  // 🌱 Smart Prediction Button
                  IconButton(
                    onPressed: () => _openSmartPrediction(),
                    icon: Icon(
                      Icons.agriculture_rounded,
                      color: AppColors.primary,
                    ),
                    tooltip: 'Smart Crop Prediction',
                  ),

                  // Text Field
                  Expanded(
                    child: Container(
                      constraints: const BoxConstraints(maxHeight: 120),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.surfaceDark
                            : AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: isDark
                              ? AppColors.dividerDark
                              : AppColors.divider,
                        ),
                      ),
                      child: TextField(
                        controller: _textController,
                        decoration: const InputDecoration(
                          hintText: 'Type your question...',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                        ),
                        maxLines: null,
                        textCapitalization: TextCapitalization.sentences,
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),

                  // Send Button
                  IconButton(
                    onPressed: isProcessing ? null : _sendMessage,
                    icon: const Icon(Icons.send_rounded,
                        color: AppColors.primary),
                    tooltip: 'Send',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showImagePickerModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ── Regular Chat Bubble ────────────────────────────────────────────────────

class _ChatBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isDark;

  const _ChatBubble({required this.message, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(12),
        constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.8),
        decoration: BoxDecoration(
          color: isUser
              ? AppColors.primary
              : (isDark ? AppColors.surfaceDark : Colors.white),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft:
                isUser ? const Radius.circular(16) : Radius.zero,
            bottomRight:
                isUser ? Radius.zero : const Radius.circular(16),
          ),
          border: !isUser
              ? Border.all(
                  color: isDark
                      ? AppColors.dividerDark
                      : AppColors.divider)
              : null,
          boxShadow: !isUser
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (message.image != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    message.image!,
                    height: 150,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            if (message.text.isNotEmpty)
              isUser
                  ? Text(
                      message.text,
                      style: const TextStyle(color: Colors.white),
                    )
                  : MarkdownBody(
                      data: message.text,
                      styleSheet: MarkdownStyleSheet(
                        p: TextStyle(
                            color:
                                Theme.of(context).colorScheme.onSurface),
                      ),
                    ),
          ],
        ),
      ),
    );
  }
}

// ── Loading Step Bubble ────────────────────────────────────────────────────

class _LoadingStepBubble extends StatelessWidget {
  final String text;
  final bool isDark;

  const _LoadingStepBubble({required this.text, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.82),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomRight: Radius.circular(16),
          ),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark
                      ? AppColors.onSurfaceVariantDark
                      : AppColors.onSurfaceVariantLight,
                  fontStyle: FontStyle.italic,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Prediction Result Bubble ───────────────────────────────────────────────

class _PredictionResultBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isDark;

  const _PredictionResultBubble(
      {required this.message, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final results = message.predictionResults!;

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(12),
        constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.95),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomRight: Radius.circular(16),
          ),
          border: Border.all(
            color: isDark ? AppColors.dividerDark : AppColors.divider,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text('🌾', style: TextStyle(fontSize: 18)),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Smart Crop Analysis',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: isDark
                            ? AppColors.onSurfaceDark
                            : AppColors.onSurfaceLight,
                      ),
                    ),
                    Text(
                      'Top ${results.length} crops for your soil',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Crop cards
            ...results.asMap().entries.map(
                  (e) => CropResultCard(
                    analysis: e.value,
                    rank: e.key + 1,
                  ),
                ),
          ],
        ),
      ),
    );
  }
}
