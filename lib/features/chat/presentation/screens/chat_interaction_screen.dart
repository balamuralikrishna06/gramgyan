import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/services/gemini_service.dart';

// Providers
final chatHistoryProvider = StateProvider.autoDispose<List<ChatMessage>>((ref) => []);
final isChatProcessingProvider = StateProvider.autoDispose<bool>((ref) => false);

class ChatMessage {
  final String text;
  final bool isUser;
  final File? image;

  ChatMessage({
    required this.text,
    required this.isUser,
    this.image,
  });
}

class ChatInteractionScreen extends ConsumerStatefulWidget {
  const ChatInteractionScreen({super.key});

  @override
  ConsumerState<ChatInteractionScreen> createState() => _ChatInteractionScreenState();
}

class _ChatInteractionScreenState extends ConsumerState<ChatInteractionScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
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

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty && _selectedImage == null) return;

    final isProcessing = ref.read(isChatProcessingProvider);
    if (isProcessing) return;

    // 1. Add User Message to History
    final userMsg = ChatMessage(
      text: text,
      isUser: true,
      image: _selectedImage, // Store reference to sent image
    );
    
    ref.read(chatHistoryProvider.notifier).update((state) => [...state, userMsg]);
    ref.read(isChatProcessingProvider.notifier).state = true;
    
    // Clear input
    _textController.clear();
    final imageToAnalyze = _selectedImage;
    setState(() {
      _selectedImage = null;
    });

    // Scroll to bottom
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });

    try {
      // Using direct instantiation for now as no global provider was found in the service file.
      // In a real app, this should be provided via Riverpod.
      final geminiService = GeminiService(); 
      String responseText = '';

      if (imageToAnalyze != null) {
        // Multimodal Analysis
        final query = text.isNotEmpty ? text : "Diagnose this crop issue.";
        final jsonResponse = await geminiService.analyzeCropDisease(imageToAnalyze, query);
        
        // Parse friendly summary from JSON
        try {
           final cleanJson = jsonResponse.replaceAll('```json', '').replaceAll('```', '').trim();
           final Map<String, dynamic> data = json.decode(cleanJson);
           if (data.containsKey('summary_for_farmer')) {
             responseText = data['summary_for_farmer'];
           } else {
             responseText = "பகுப்பாய்வு முடிந்தது. விவரங்களை கீழே காணவும்:\n$cleanJson";
           }
        } catch (e) {
           responseText = jsonResponse; // Fallback to raw text
        }
      } else {
        // Text-only Query
        responseText = await geminiService.generateAnswer(text);
      }

      // 2. Add AI Response
      final aiMsg = ChatMessage(text: responseText, isUser: false);
       ref.read(chatHistoryProvider.notifier).update((state) => [...state, aiMsg]);

    } catch (e) {
      final errorMsg = ChatMessage(text: "மன்னிக்கவும், ஒரு பிழை ஏற்பட்டது: $e", isUser: false);
      ref.read(chatHistoryProvider.notifier).update((state) => [...state, errorMsg]);
    } finally {
      ref.read(isChatProcessingProvider.notifier).state = false;
      // Scroll to bottom again
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
  }

  @override
  Widget build(BuildContext context) {
    final history = ref.watch(chatHistoryProvider);
    final isProcessing = ref.watch(isChatProcessingProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      appBar: AppBar(
        title: const Text('Ask Gram Gyan'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ── Chat List ──
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
                  return _ChatBubble(message: msg, isDark: isDark);
                },
              ),
            ),

            // ── Image Preview ──
            if (_selectedImage != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: isDark ? Colors.black12 : Colors.grey.shade100,
                child: Row(
                  children: [
                    Stack(
                      alignment: Alignment.topRight,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(_selectedImage!, width: 80, height: 80, fit: BoxFit.cover),
                        ),
                        Positioned(
                          top: -4,
                          right: -4,
                          child: GestureDetector(
                            onTap: () => setState(() => _selectedImage = null),
                            child: Container(
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close, size: 16, color: Colors.white),
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

            // ── Input Area ──
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: isDark ? AppColors.cardDark : AppColors.cardLight,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
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
                  // Image Button
                  IconButton(
                    onPressed: isProcessing ? null : () => _showImagePickerModal(context),
                    icon: Icon(Icons.add_photo_alternate_rounded, color: AppColors.primary),
                  ),
                  // Text Field
                  Expanded(
                    child: Container(
                      constraints: const BoxConstraints(maxHeight: 120),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: isDark ? AppColors.dividerDark : AppColors.divider,
                        ),
                      ),
                      child: TextField(
                        controller: _textController,
                        decoration: const InputDecoration(
                          hintText: 'Type your question...',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
                    icon: const Icon(Icons.send_rounded, color: AppColors.primary),
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
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
        decoration: BoxDecoration(
          color: isUser 
              ? AppColors.primary 
              : (isDark ? AppColors.surfaceDark : Colors.white),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: isUser ? const Radius.circular(16) : Radius.zero,
            bottomRight: isUser ? Radius.zero : const Radius.circular(16),
          ),
          border: !isUser ? Border.all(color: isDark ? AppColors.dividerDark : AppColors.divider) : null,
          boxShadow: !isUser ? [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            )
          ] : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (message.image != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(message.image!, height: 150, width: double.infinity, fit: BoxFit.cover),
                ),
              ),
            if (message.text.isNotEmpty)
              isUser 
                ? Text(message.text, style: const TextStyle(color: Colors.white))
                : MarkdownBody(
                    data: message.text, 
                    styleSheet: MarkdownStyleSheet(
                      p: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                    )
                  ),
          ],
        ),
      ),
    );
  }
}
