import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.cyan,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  _MyHomepageState createState() => _MyHomepageState();
}

class _MyHomepageState extends State<MyHomePage> {
  TextEditingController _name = TextEditingController();
  TextEditingController _email = TextEditingController();
  TextEditingController _phone = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final ref = FirebaseDatabase.instance.ref().child('users');

  void writeData(String name, String email, String phone) {
    _name.clear();
    _email.clear();
    _phone.clear();
    var timestamp = DateTime.now().millisecondsSinceEpoch;
    ref.child('$timestamp').set({
      'name': name,
      'email': email,
      'phone': phone,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Form(
        key: _formKey,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextFormField(
                controller: _name,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a name';
                  }
                  return null;
                },
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Enter Name',
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextFormField(
                controller: _email,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an email';
                  }
                  return null;
                },
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Enter Email',
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextFormField(
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                controller: _phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a phone number';
                  }
                  return null;
                },
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Enter Phone',
                ),
              ),
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      writeData(_name.text, _email.text, _phone.text);
                    }
                  },
                  child: Text('Submit data'),
                ),
                MaterialButton(
                  onPressed: () {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => NewScreen(),
                    ));
                  },
                  child: Text('Next screen'),
                )
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class NewScreen extends StatefulWidget {
  const NewScreen({Key? key}) : super(key: key);

  @override
  _NewScreenState createState() => _NewScreenState();
}

class _NewScreenState extends State<NewScreen> {
  late DatabaseReference ref;
  List<Map<String, dynamic>> dataList = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    ref = FirebaseDatabase.instance.ref().child('users');
    fetchData();
  }

  void fetchData() {
    ref.onValue.listen((DatabaseEvent event) {
      final snapshot = event.snapshot;
      if (snapshot.exists) {
        final values = snapshot.value as Map<dynamic, dynamic>;
        dataList = values.entries.map((entry) {
          var value = entry.value as Map<dynamic, dynamic>;
          return {
            'key': entry.key,
            'name': value['name'] as String,
            'email': value['email'] as String,
            'phone': value['phone'] as String,
          };
        }).toList();
        setState(() {
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
      }
    }, onError: (error) {
      setState(() {
        isLoading = false;
      });
      print('Error fetching data: $error');
    });
  }

  void updateData(String key, String name, String email, String phone) {
    ref.child(key).update({
      'name': name,
      'email': email,
      'phone': phone,
    }).then((_) {
      Navigator.of(context).pop(); // Go back after updating data
    }).catchError((error) {
      print('Error updating data: $error');
    });
  }

  void deleteData(String key) {
    ref.child(key).remove().then((_) {
      setState(() {
        dataList.removeWhere((item) => item['key'] == key);
      });
    }).catchError((error) {
      print('Error deleting data: $error');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Data List'),
      ),
      body: isLoading
          ? Center(
        child: CircularProgressIndicator(),
      )
          : dataList.isEmpty
          ? Center(
        child: Text('No data available'),
      )
          : ListView.builder(
        itemCount: dataList.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text('Name: ${dataList[index]['name']}'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Email: ${dataList[index]['email']}'),
                Text('Phone: ${dataList[index]['phone']}'),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.edit),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => EditScreen(
                          key: ValueKey(dataList[index]['key']),
                          data: dataList[index],
                        ),
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: Icon(Icons.delete),
                  onPressed: () {
                    deleteData(dataList[index]['key']);
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class EditScreen extends StatefulWidget {
  final Map<String, dynamic> data;

  const EditScreen({Key? key, required this.data}) : super(key: key);

  @override
  _EditScreenState createState() => _EditScreenState();
}

class _EditScreenState extends State<EditScreen> {
  late TextEditingController _name;
  late TextEditingController _email;
  late TextEditingController _phone;
  late DatabaseReference ref;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.data['name']);
    _email = TextEditingController(text: widget.data['email']);
    _phone = TextEditingController(text: widget.data['phone']);
    ref = FirebaseDatabase.instance.ref().child('users');
  }

  void updateData() {
    ref.child(widget.data['key']).update({
      'name': _name.text,
      'email': _email.text,
      'phone': _phone.text,
    }).then((_) {
      Navigator.of(context).pop(); // Go back after updating data
    }).catchError((error) {
      print('Error updating data: $error');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Data'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextFormField(
              controller: _name,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Enter Name',
              ),
            ),
            SizedBox(height: 8),
            TextFormField(
              controller: _email,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Enter Email',
              ),
            ),
            SizedBox(height: 8),
            TextFormField(
              controller: _phone,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Enter Phone',
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: updateData,
              child: Text('Update Data'),
            ),
          ],
        ),
      ),
    );
  }
}
