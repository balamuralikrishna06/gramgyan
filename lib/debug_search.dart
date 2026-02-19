import 'package:supabase/supabase.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'dart:io';

// HARDCODED CREDENTIALS FOR DEBUGGING
const supabaseUrl = 'https://cepcxehqwlcmhcsohaxs.supabase.co';
const supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNlcGN4ZWhxd2xjbWhjc29oYXhzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzEwOTkxMTUsImV4cCI6MjA4NjY3NTExNX0.6uTsPnF0xj1w-3SZhwkjszkVystrAo-7GXOhHABZHPg';
const geminiApiKey = 'AIzaSyAiNBUCfYdLfIfJalDH0Ur1svfw1IgOBpY';

void main() async {
  print('--- Starting Debug Search ---');

  // 1. Initialize Supabase Client directly (No Flutter binding needed)
  final client = SupabaseClient(supabaseUrl, supabaseAnonKey);

  const testQuery = "I have a rose garden. I didn't get any yield. What to do?";
  print('Query: "$testQuery"');

  try {
    // 2. Generate Embedding
    print('\nStep 1: Generating Embedding (models/gemini-embedding-001)...');
    final embeddingModel = GenerativeModel(
        model: 'models/gemini-embedding-001',
        apiKey: geminiApiKey, 
    );
    final content = Content.text(testQuery);
    
    // Using retrievalQuery checks logic similar to GeminiService
    final result = await embeddingModel.embedContent(content, taskType: TaskType.retrievalQuery);
    final embedding = result.embedding.values;
    
    print('✅ Embedding generated. Length: ${embedding.length}');
    
    // 3. Test RPC match_knowledge
    print('\nStep 2: Calling match_knowledge RPC...');
    final List<dynamic> response = await client.rpc(
      'match_knowledge',
      params: {
        'query_embedding': embedding,
        'match_threshold': 0.1, // Very low threshold to see EVERYTHING
        'match_count': 5,
      },
    );

    print('RPC Response Count: ${response.length}');
    if (response.isEmpty) {
      print('⚠️ No matches found even with 0.1 threshold.');
      
      // Check if table is empty
      final count = await client.from('knowledge_posts').count();
      print('Total rows in knowledge_posts: $count');
    } else {
      for (var row in response) {
        print(' - Match: "${row['original_text'] ?? row['english_text']}"');
        print('   Similarity: ${row['similarity']}');
      }
    }

    // 4. Test AI Answer Generation
    print('\nStep 3: Testing AI Answer Generation (models/gemini-2.5-flash)...');
    final textModel = GenerativeModel(
      model: 'models/gemini-2.5-flash',
      apiKey: geminiApiKey, 
    );
    
    try {
        final prompt = 'Provide a clear, simple agricultural solution for this farmer question: "$testQuery". Keep the answer concise.';
        final aiResponse = await textModel.generateContent([Content.text(prompt)]);
        print('AI Answer: ${aiResponse.text}');
    } catch (e) {
        print('❌ AI Answer Generation Failed: $e');
    }

  } catch (e) {
    print('❌ Exception: $e');
  }
}
