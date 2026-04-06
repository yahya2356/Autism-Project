import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:get/get.dart';

import '../constants/app_constants.dart';

class AiService extends GetxService {
  Future<String> summarizeGroupPosts(String postsText) async {
    if (postsText.trim().isEmpty) {
      throw Exception('No post content was provided for summarization.');
    }

    if (AppAiConfig.openAiApiKey.isEmpty) {
      throw Exception('OpenAI API key is missing. Run with --dart-define=OPENAI_API_KEY=your_key');
    }

    final prompt = '''
Summarize the following community discussion from parents of children with autism.

Focus on:

- Advice shared
- Common challenges
- Helpful experiences
- Recommended solutions

Keep the summary clear, supportive, and concise.
Limit the summary to under 150 words.
''';

    final client = HttpClient();
    try {
      final request = await client
          .postUrl(Uri.parse('${AppAiConfig.openAiBaseUrl}/chat/completions'))
          .timeout(const Duration(seconds: 20));
      request.headers.set(HttpHeaders.authorizationHeader, 'Bearer ${AppAiConfig.openAiApiKey}');
      request.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
      request.write(
        jsonEncode({
          'model': AppAiConfig.openAiModel,
          'temperature': 0.3,
          'max_tokens': 220,
          'messages': [
            {
              'role': 'system',
              'content': 'You produce safe, supportive community summaries for parents.',
            },
            {
              'role': 'user',
              'content': '$prompt\n\nDiscussion:\n${postsText.trim()}',
            },
          ],
        }),
      );

      final response = await request.close().timeout(const Duration(seconds: 30));
      final body = await response.transform(utf8.decoder).join();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('AI summarization failed (${response.statusCode}).');
      }

      final data = jsonDecode(body) as Map<String, dynamic>;
      final choices = data['choices'] as List<dynamic>? ?? const [];
      if (choices.isEmpty) {
        throw Exception('AI returned no summary.');
      }
      final message = choices.first['message'] as Map<String, dynamic>? ?? const {};
      final summary = (message['content'] ?? '').toString().trim();
      if (summary.isEmpty) {
        throw Exception('AI returned an empty summary.');
      }
      return summary;
    } on SocketException {
      throw Exception('Network error while generating summary.');
    } on HttpException {
      throw Exception('Unable to reach AI service.');
    } on FormatException {
      throw Exception('Invalid AI response format.');
    } on TimeoutException {
      throw Exception('AI request timed out. Please try again.');
    } finally {
      client.close(force: true);
    }
  }
}
