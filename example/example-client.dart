import 'package:entangle/entangle-client.dart';

void clientApp() async {
  // wait server runing
  await Future.delayed(Duration(milliseconds: 500), () {});

  await entangleClient.connect('ws://127.0.0.1:5000/ws');

  /// simple send data
  ///
  /// send, and wait server callback two message
  entangleClient.send('hello-world', {
    "msg": "helloA",
    "other": 100,
  }, listen: (data, remove) {
    print('client-get-msg-1: $data');
  });

  ///  only run once listen ad every send();
  ///
  /// remove before listen once
  entangleClient.send('hello-world', {
    "msg": "helloB",
    "other": false,
  }, listen: (data, remove) {
    print('client-get-msg-2: $data');

    // remove this listen
    remove();
  });

  /// timeOut Feature
  ///
  /// timeout 5000ms, remove this Function listen
  entangleClient.send('hello-world', {
    "msg": "helloB",
    "other": false,
  }, listen: (data, clear) {
    print('client-get-msg-2: $data');
  }, timeOutMilliseconds: 5000);

  /// Auto connect again
  ///
  /// close and connect:
  Future.delayed(Duration(milliseconds: 1500), () async {
    print('close');
    await entangleClient.client.close();

    // Auto connect at entangleClient.send;
    entangleClient.send('hello-world', {"msg": "helloA"},
        listen: (data, clear) {
      print('client-get-msg-again: $data');
    });
  });
}
