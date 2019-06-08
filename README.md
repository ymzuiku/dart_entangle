# entangle

entangle 取至量子纠缠(Quantum Entanglement)

entangle 是基于 websocket 运行在 dart VM 的服务端框架

在 flutter 中, 与之配套的有 entangle-client 可以在客户端更简洁的调用 entangle, 并且处理好了断线重连， 心跳重连等机制

entangle-client 配合 entangle 能让我们像在本机异步处理对象一样访问服务器的函数, 并传递 json 对象

其他非 dart 语言的客户端亦可以直接使用 websocket 进行调用

## Server:

```dart
import 'package:entangle/entangle.dart';

class Context {
  String name = 'i am a context data';
}

void main() async {
  var entangle = Entangle({
    'hello-world': hello,
  }, context: Context());

  entangle.listen(port: 5000, path: '/ws');
}

// controller example
void hello(Context ctx, data, send) {
  send({'msg': '${data['msg']}-world', 'ctx-name': ctx.name});

  // if other == 100, send message at 1000ms ago
  if (data['other'] == 100) {
    Future.delayed(Duration(milliseconds: 1000), () {
      send({'other': 'server take the initiative at 1000ms ago'});
    });
  }
}

```

## client:

```dart
import 'package:entangle/entangle-client.dart';

void clientApp() async {
  // wait server runing
  await Future.delayed(Duration(milliseconds: 500), () {});

  await entangleClient.connect('ws://127.0.0.1:5000/ws');

  // heart check at 1500ms, if connect.close, auto conect again;
  entangleClient.connectHeart(1500);

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

```
