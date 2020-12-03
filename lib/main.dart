import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(MaterialApp(
    home: Home(),
  ));
}

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  List<Task> _todoList = <Task>[];
  final _taskTitle = TextEditingController();
  Task _lastRemoved;
  int _lastRemovedPosition;

  @override
  void initState() {
    super.initState();

    _readData().then((value) {
      List listFromJson = json.decode(value);

      setState(() {
        for (var item in listFromJson) {
          _todoList.add(Task.fromJson(item));
        }
      });
    });
  }

  void _addTask() {
    _todoList.add(Task(_taskTitle.text));
    _saveData();

    _taskTitle.text = '';
  }

  Future<File> _getFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/data.json');
  }

  Future<File> _saveData() async {
    String data = json.encode(_todoList);

    final file = await _getFile();
    print(file.lastModified());
    return file.writeAsString(data);
  }

  Future<String> _readData() async {
    try {
      final file = await _getFile();
      return file.readAsString();
    } catch (err) {
      print(err.toString());
      return null;
    }
  }

  Widget buildItem(context, index) {
    return Dismissible(
      key: Key(_todoList[index].title),
      background: Container(
        color: Colors.red,
        child: Align(
          alignment: Alignment(-0.9, 0.0),
          child: Icon(
            Icons.delete,
            color: Colors.white,
          ),
        ),
      ),
      direction: DismissDirection.startToEnd,
      child: CheckboxListTile(
        title: Text(
          _todoList[index].title,
          style: TextStyle(
            color: _todoList[index].status ? Colors.grey : Colors.blueAccent,
          ),
        ),
        value: _todoList[index].status,
        secondary: CircleAvatar(
          child: Icon(
            _todoList[index].status ? Icons.check : Icons.error,
          ),
        ),
        onChanged: (bool value) {
          setState(() {
            _todoList[index].status = value;
            _saveData();
          });
        },
      ),
      onDismissed: (direction) {
        setState(() {
          _lastRemoved = _todoList[index];
          _lastRemovedPosition = index;
          _todoList.removeAt(index);

          _saveData();
        });

        final snack = SnackBar(
          content: Text('Tarefa removida.'),
          duration: Duration(seconds: 2),
          action: SnackBarAction(
            label: 'Desfazer',
            onPressed: () {
              setState(() {
                _todoList.insert(_lastRemovedPosition, _lastRemoved);
                _saveData();
              });
            },
          ),
        );

        Scaffold.of(context).removeCurrentSnackBar();
        Scaffold.of(context).showSnackBar(snack);
      },
    );
  }

  Future<Null> _refresh() async {
    await Future.delayed(Duration(seconds: 1));

    setState(() {
      _todoList.sort((a, b) {
        if (a.status && !b.status)
          return 1;
        else if (!a.status && b.status)
          return -1;
        else
          return 0;
      });

      _saveData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Lista de tarefas'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Column(
        children: <Widget>[
          Container(
            padding: EdgeInsets.fromLTRB(16, 4, 8, 16),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: _taskTitle,
                    decoration: InputDecoration(
                      labelText: 'Nova tarefa',
                      labelStyle: TextStyle(color: Colors.blueAccent),
                    ),
                  ),
                ),
                RaisedButton(
                  onPressed: () {
                    setState(() {
                      _addTask();
                    });
                  },
                  child: Icon(Icons.add),
                  textColor: Colors.white,
                  color: Colors.blueAccent,
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refresh,
              child: ListView.builder(
                padding: EdgeInsets.only(top: 8.0),
                itemCount: _todoList.toList().length,
                itemBuilder: buildItem,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class Task {
  String title;
  bool status = false;

  Task(this.title);

  Task.fromJson(Map<String, dynamic> json) {
    this.title = json['t'];
    this.status = json['s'];
  }

  Map<String, dynamic> toJson() {
    return {
      't': this.title,
      's': this.status,
    };
  }
}
