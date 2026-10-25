import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialize Supabase
  await Supabase.initialize(
    url: 'https://jumaicbtotgcdsketfud.supabase.co', // 👈 Paste your URL
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imp1bWFpY2J0b3RnY2Rza2V0ZnVkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTI5MjM5NjgsImV4cCI6MjEwODQ5OTk2OH0.PWiZLa4kArvJu5rxxYRnVOpaHXwhcHnAxkbyj6qVBJA', // 👈 Paste your anon key
  );

  runApp(const MyApp());
}

// Global reference to Supabase
final supabase = Supabase.instance.client;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'VIP Guestlist',
      theme: ThemeData(primarySwatch: Colors.purple, useMaterial3: true),
      home: const GuestlistScreen(),
    );
  }
}

class GuestlistScreen extends StatefulWidget {
  const GuestlistScreen({super.key});

  @override
  State<GuestlistScreen> createState() => _GuestlistScreenState();
}

class _GuestlistScreenState extends State<GuestlistScreen> {
  final TextEditingController _controller = TextEditingController();
  
  // Real-time stream directly listening to PostgreSQL!
  final _guestStream = supabase.from('guests').stream(primaryKey: ['id']);

  // Function to insert data into PostgreSQL

Future<void> _addGuest() async {
  final text = _controller.text.trim();

  if (text.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please enter a guest name')),
    );
    return;
  }

  try {
    await supabase.from('guests').insert({
      'name': text,
    });

    if (!mounted) return;

    _controller.clear();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Guest added successfully!')),
    );
  } catch (e) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error adding guest: $e')),
    );
    debugPrint('Supabase insert error: $e');
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('VIP Guestlist 💅'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Input field
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      labelText: 'Enter Guest Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _addGuest,
                  child: const Text('Add'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // List displaying PostgreSQL Data in Real-Time
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: _guestStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('No guests on the list yet!'));
                  }

                  final guests = snapshot.data!;
                  return ListView.builder(
                    itemCount: guests.length,
                    itemBuilder: (context, index) {
                      return Card(
                        child: ListTile(
                          leading: const Icon(Icons.person, color: Colors.purple),
                          title: Text(guests[index]['name'] ?? ''),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
