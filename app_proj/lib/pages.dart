import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
  List<String> _randomTexts = [];
  String _displayedText = "Press the button!";

  @override
  void initState() {
    super.initState();
    _fetchRandomTexts();
  }

  Future<void> _fetchRandomTexts() async {
    final QuerySnapshot snapshot =
        await FirebaseFirestore.instance.collection('randomTexts').get();
    final List<String> texts =
        snapshot.docs.map((doc) => doc['text'] as String).toList();
    // Log the texts to the console
    setState(() {
      _randomTexts = texts;
    });
  }

  void _showRandomText() {
    if (_randomTexts.isNotEmpty) {
      setState(() {
        _displayedText = _randomTexts[Random().nextInt(_randomTexts.length)];
      });
    }
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

class LiveUpdatePage extends StatefulWidget {
  const LiveUpdatePage({super.key});

  @override
  _LiveUpdatePageState createState() => _LiveUpdatePageState();
}

class _LiveUpdatePageState extends State<LiveUpdatePage> {
  final TextEditingController _controller = TextEditingController();

  void _addUpdate() {
    final String text = _controller.text;
    if (text.isNotEmpty) {
      FirebaseFirestore.instance.collection('randomTexts').add({'text': text});
      _controller.clear();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Live Updates"),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      labelText: 'Enter update',
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _addUpdate,
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('randomTexts')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return const Center(child: Text('Error fetching data'));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No updates available'));
                }

                final updates = snapshot.data!.docs
                    .map((doc) => doc['text'] as String)
                    .toList();

                return ListView.builder(
                  itemCount: updates.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      title: Text(updates[index]),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
