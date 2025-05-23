import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'dbman.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}
DBMan dbman = DBMan();

class MyApp extends StatelessWidget {
  MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Firebase Shopping List ',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(title: 'Shopping list'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  late Future<List<Map<String, dynamic>>> allitems;

  @override
  void initState() {
    super.initState();
    allitems = dbman.getAllItems();
  }

  double getTotal(String quantityText, String priceText) {
    if (quantityText.isEmpty || priceText.isEmpty) {
      return 0.0;
    }
    final quantity = double.tryParse(quantityText);
    final price = double.tryParse(priceText);
    if (quantity == null || price == null) {
      return 0.0;
    }
    return quantity * price;
  }

  void AddItemsWithRizz(context) {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController quantityController = TextEditingController();
    final TextEditingController priceController = TextEditingController();
    final TextEditingController pricepaidController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Item'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Item Name'),
              ),
              TextField(
              controller: quantityController,
              decoration: const InputDecoration(labelText: 'Quantity'),
              keyboardType: TextInputType.number,
              onChanged: (_) { 
                // Rebuild dialog to update total
                (context as Element).markNeedsBuild();
              },
              ),
              TextField(
              controller: priceController,
              decoration: const InputDecoration(labelText: 'Price Per Unit(in €)'),
              keyboardType: TextInputType.number,
              onChanged: (_) {
                (context as Element).markNeedsBuild();
              },
              ),
              Builder(
              builder: (context) {
                return Text('Total: ${getTotal(quantityController.text, priceController.text).toStringAsFixed(2)} €');
              },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                final name = nameController.text.trim();
                final quantityText = quantityController.text.trim();
                final priceText = priceController.text.trim();

                if (name.isEmpty || quantityText.isEmpty || priceText.isEmpty) {
                  return;
                }

                final quantity = double.tryParse(quantityText);
                final price = double.tryParse(priceText);

                if (quantity == null || price == null) {
                  return;
                }

                dbman.addItem(
                  name,
                  quantity,
                  price,
                  quantity * price,
                );
                setState(() { 
                  allitems = dbman.getAllItems();
                });
                Navigator.of(context).pop();
              },
              child: const Text('Add'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            )
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: allitems,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No items found.'));
          } else {
            final items = snapshot.data!;
            return ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return ListTile(
                  leading: Checkbox(
                      value: item['isChecked'],
                      onChanged: ((value) {
                        setState(() {
                          item['isChecked'] = value;
                          dbman.updateItem(
                            item['id'],
                            item['item'] ?? '',
                            (item['quantity'] ?? 0).toDouble(),
                            (item['priceperunit'] ?? 0).toDouble(),
                            (item['price-paid'] ?? 0).toDouble(),
                            value ?? false
                          );
                        });
                      }),
                    ),
                  title: Text('Name: ${item['item'] ?? ''}'),
                  subtitle: Text('Quantity: ${item['quantity'] ?? ''} | Price: ${item['priceperunit'] ?? ''} | Total: ${item['price-paid'] ?? ''}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () {
                      dbman.deleteItem(item['id']);
                      setState(() {
                        allitems = dbman.getAllItems();
                      });
                    },
                  ),
                );
              },
            );
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: (() {
          AddItemsWithRizz(context);   
        }),
        tooltip: 'Add Item',
        child: const Icon(Icons.add),),
    );
  }
}
