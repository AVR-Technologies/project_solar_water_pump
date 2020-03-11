import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';

void main() => runApp(MaterialApp(
  debugShowCheckedModeBanner: false,
  home: ControllerPage(),
  theme: ThemeData(
    primaryColor: Colors.blueGrey[800]
  ),
  title: 'Solar Controller',
),);

class ControllerPage extends StatefulWidget{
  @override _ControllerPageState createState() => _ControllerPageState();
}

class _ControllerPageState extends State<ControllerPage> {
  final onTimeController  = new TextEditingController();
  final offTimeController = new TextEditingController();
  Socket socket;
  bool isConnected = false;
  bool currentStatus = false; // On and Off
  String host = '192.168.4.1';
  int port = 7777;
  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text('Controller'),
    ),
    body: SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          row1(),
          row2(),
          row3(),
        ],
      ),
    ),
  );
  Widget row1() => Row(
    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
    children: <Widget>[
      Text('$host:$port'),
      FlatButton(
        onPressed: !isConnected ? connect : null,
        child: Text('Connect'),
        color: Colors.green[800],
        textColor: Colors.white,
      ),
      FlatButton(
        onPressed: isConnected ? disConnect : null,
        child: Text('Disconnect'),
        color: Colors.red[800],
        textColor: Colors.white,
      ),
    ],
  );
  Widget row2() => Visibility(
    visible: isConnected,
    child: Column(
      children: <Widget>[
        Divider(),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            Text('Status:'),
            Text(currentStatus ? 'On': 'Off', style: TextStyle(color: Colors.blue[800], fontSize: 18,),),
            FlatButton(
              onPressed: turnOnPump,
              child: Text('On'),
              color: Colors.green[800],
              textColor: Colors.white,
            ),
            FlatButton(
              onPressed: turnOffPump,
              child: Text('Off'),
              color: Colors.red[800],
              textColor: Colors.white,
            ),
          ],
        ),
      ],
    ),
  );
  Widget row3() => Visibility(
    visible: isConnected,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Divider(),
        inputField('On time', onTimeController),
        inputField('Off time', offTimeController),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: FlatButton(
            onPressed: sendTime,
            color: Colors.blueGrey[800],
            textColor: Colors.white,
            child: Text('Send'),
          ),
        ),
        Divider(),
      ],
    ),
  );
  Widget inputField(String label, TextEditingController controller) => Padding(
    padding: const EdgeInsets.all(8.0),
    child: TextField(
      readOnly: true,
      onTap: () => pickTime(controller),
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(),
      ),
    ),
  );
  Widget dialogUi(String title, String content) => AlertDialog(
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10)
    ),
    title: Text(title),
    content: Text(content),
    actions: <Widget>[
      FlatButton(
        onPressed: () => Navigator.pop(context),
        child: Text('Close'),
      ),
    ],
  );
  showOnDialog() => showDialog(context: context, builder: (context) => dialogUi('On', 'Pump in on'));
  showOffDialog() => showDialog(context: context, builder: (context) => dialogUi('Off', 'Pump in off'));
  showAllDataNeededDialog() => showDialog(context: context, builder: (context) => dialogUi('Alert', 'Both ON time and OFF time needed'));
  sendTime() => onTimeController.text.length + offTimeController.text.length > 0 ? sendToServer('t,' + onTimeController.text + ',' +offTimeController.text) : showAllDataNeededDialog();
  turnOnPump() {
    sendToServer('n');
    setState(() => currentStatus = true);
  }
  turnOffPump() {
    sendToServer('f');
    setState(() => currentStatus = false);
  }
  pickTime(TextEditingController controller) => showTimePicker(context: context, initialTime: TimeOfDay.now()).then((value) => controller.text = '${withLengthTwo(value.hour.toString())}:${withLengthTwo(value.minute.toString())}');
  //tcp client functions
  connect() async {
    socket = await Socket.connect(host, port);
    setState(() => isConnected = true);
    socket.listen((event) {
      List<int> data = new List();
      data.add(event[0]);
      String message = utf8.decode(data);
      print(message);
      setState(() {
        if(message == 'n'){
          currentStatus = true;
          showOnDialog();
        }
        else if (message == 'f') {
          currentStatus = false;
          showOffDialog();
        }
      });

    });
  }
  disConnect(){
    socket.close();
    setState(() => isConnected = false);
  }
  sendToServer(_message) => socket.add(utf8.encode(_message));
  withLengthTwo(String data) => data.length > 1 ? data : '0$data';
}