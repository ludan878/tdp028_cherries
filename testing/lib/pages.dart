import 'package:flutter/material.dart';
import 'dart:math';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;
  NetworkImage _image = const NetworkImage('https://picsum.photos/200/300');

  void _buttonPress() {
    setState(() {
      _counter++;
      _image = NetworkImage('https://picsum.photos/200/300?random=$_counter');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Image(
              image: _image,
            ),
            const SizedBox(height: 20),
            Text(
              'Random Image Generator',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _buttonPress,
        tooltip: 'Press to see something cool!',
        child: const Icon(Icons.add),
      ),
    );
  }
}

class TextPage extends StatefulWidget {
  const TextPage({super.key});

  @override
  TextPageState createState() => TextPageState();
}

class TextPageState extends State<TextPage> {
  final List<String> _randomTexts = [
    // Generated Texts from chat-gpt
    "I'm not lazy, I'm on energy-saving mode.",
    "I'm not arguing, I'm just explaining why I'm right.",
    "I'm not shy, I'm holding back my awesomeness so I don't intimidate you.",
    "I'm not short, I'm concentrated awesome!",
    "I'm not a complete idiot, some parts are missing.",
    "I'm not a control freak, but you're doing it wrong.",
    "I'm not a morning person, don't pull my covers off.",
    "I'm not a smart aleck, I'm just witty beyond my years.",
    "I'm not a vegetarian because I love animals. I'm a vegetarian because I hate plants.",
    "I'm not clumsy, everything is just in the wrong place.",
    "The only thing I throwback on Thursday is a glass of wine.",
    "I'm not a shopaholic, I'm helping the economy.",
    "I'm not a player, I'm the game.",
    "The only thing I love more than wine is winning.",
    "Snus is the new black.",
    "I love to snus and tell.",
  ];
  String _displayedText = "Press the button!";

  void _showRandomText() {
    setState(() {
      _displayedText = _randomTexts[Random().nextInt(_randomTexts.length)];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Random Text Generator"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              _displayedText,
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _showRandomText,
              child: const Text("Show Random Text"),
            ),
          ],
        ),
      ),
    );
  }
}
