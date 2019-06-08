import 'package:entangle/entangle-client.dart';

void clientApp() async {
  // wait server runing
  await Future.delayed(Duration(milliseconds: 500), () {});

  await entangleClient.connect('ws://127.0.0.1:5000/ws');

  // heart check at 1500ms, if connect.close, auto conect again;
  entangleClient.connectHeart(1500);

  /// Simple send data, and wait server callback twice
  ///
  /// Example:
  entangleClient.send(
    controller: 'hello-world',
    data: {
      "msg": "helloA",
      "other": 100,
    },
    listen: (data, remove) {
      print('client-get-msg-1: $data');
    },
  );

  ///  Only run once listen ad every send();
  ///
  /// Example:
  entangleClient.send(
    controller: 'hello-world',
    data: {
      "msg": "helloB",
      "other": false,
    },
    listen: (data, remove) {
      print('client-get-msg-2: $data');

      // remove this listen
      remove();
    },
  );

  /// timeOut Feature
  ///
  /// Example:
  entangleClient.send(
    controller: 'hello-world',
    data: {
      "msg": "helloB",
      "other": false,
    },
    listen: (data, clear) {
      print('client-get-msg-2: $data');
    },
    timeOutMilliseconds: 5000,
  );

  /// Auto connect again
  ///
  /// Example:
  Future.delayed(Duration(milliseconds: 1500), () async {
    print('close');
    await entangleClient.client.close();

    // Auto connect at entangleClient.send;
    entangleClient.send(
      controller: 'hello-world',
      data: {"msg": "helloA"},
      listen: (data, clear) {
        print('client-get-msg-again: $data');
      },
    );
  });
}
