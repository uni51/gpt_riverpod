import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  await dotenv.load(fileName: '.env');
  runApp(const ProviderScope(child: MyApp()));
}

final apiTextProvider = StateNotifierProvider<ApiTextNotifier, String?>((ref) {
  return ApiTextNotifier();
});

class ApiTextNotifier extends StateNotifier<String?> {
  ApiTextNotifier() : super(null);

  Future<void> getApiResponse(String searchText) async {
    final response = await ChatGPTRequest.getResponse(searchText);
    state = response;
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends ConsumerWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final apiText = ref.watch(apiTextProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(title),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Builder(builder: (context) {
                  final text = apiText;

                  if (text == null) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  return Text(
                    text,
                    style: const TextStyle(
                      fontSize: 14,
                    ),
                  );
                }),
              ),
              TextField(
                decoration: const InputDecoration(
                  hintText: '日本で一番高い山は？',
                ),
                onChanged: (text) {
                  ref.read(apiTextProvider.notifier).getApiResponse(text);
                },
              ),
              ElevatedButton(
                onPressed: () async {
                  const searchText = '日本で一番高い山は？';
                  if (searchText != null) {
                    await ref.read(apiTextProvider.notifier).getApiResponse(searchText);
                  }
                },
                child: const Text('検索'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ChatGPTRequest {
  static final apiKey = dotenv.get('CHATGPT_API_KEY');

  static Future<String> getResponse(String requestText) async {
    final response = await http.post(
      Uri.parse('https://api.openai.com/v1/chat/completions'),
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode(<String, dynamic>{
        'model': 'gpt-3.5-turbo',
        'messages': [
          {"role": "user", "content": requestText}
        ]
      }),
    );
    final body = response.bodyBytes;
    final jsonString = utf8.decode(body);
    final json = jsonDecode(jsonString);
    final content = json['choices'][0]['message']['content'];
    return content;
  }
}
