
import 'package:flutter/material.dart';
import 'channel1.dart';
import 'package:provider/provider.dart';
import 'channel_model.dart'; // импорт модели

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => ChannelModel('Channel1'),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'InstantPlay',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color.fromARGB(255, 18, 32, 47),
      ),
      home: const MainPage(),
    );
  }
}

class MainPage extends StatelessWidget {
  const MainPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const SizedBox(height: 20),
          // Row 1
          Row(
            children: List.generate(9, (index) {
              return Expanded(
                child: Container(
                  key: Key('Column_1-${index + 1}'),
                  margin: const EdgeInsets.all(4),
                  child: index < 8
                      ? Channel1(id: '1-${index + 1}')
                      : const SizedBox.shrink(), // пустая последняя колонка
                ),
              );
            }),
          ),
          const SizedBox(height: 2),
          // Row 2
          Row(
            children: List.generate(9, (index) {
              return Expanded(
                child: Container(
                  key: Key('Column_2-${index + 1}'),
                  margin: const EdgeInsets.all(4),
                  child: index < 8
                      ? Channel1(id: '2-${index + 1}')
                      : const SizedBox.shrink(), // Master колонка пока пустая
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
