library entangle;

import 'dart:convert';
import 'dart:io';

String _entangleType = '__entangle__';
// String _entangleKey = 'k';
String _entangleController = 'c';

class Entangle {
  final Map<String, Function> controllers;
  dynamic context;

  Entangle(this.controllers, {this.context}) {
    if (this.controllers == null) {
      throw 'Entangle need init params: controllers';
    }
  }

  Future listen({
    int port = 5000,
    String path = '/ws',
    Function(HttpRequest) handle,
  }) async {
    var server = await HttpServer.bind(InternetAddress.loopbackIPv4, port);
    print('entangle running: http:127.0.0.1:$port');
    print('entangle-ws running: ws:127.0.0.1:$port$path');
    await for (HttpRequest req in server) {
      // 如果路径相同，就使用 websocket
      if (req.uri.path == path) {
        serveRequest(req).catchError((Error error) {
          print('WebSocket error: --start');
          print(error);
          print(error.stackTrace);
          print('[WebSocket error] --end');
        });
      } else {
        if (handle != null) {
          handle(req);
        } else {
          req.response.close();
        }
      }
    }
  }

  Future serveRequest(HttpRequest request) {
    if (WebSocketTransformer.isUpgradeRequest(request)) {
      return WebSocketTransformer.upgrade(request).then((webSocket) {
        // webSockets.add(webSocket);
        webSocket.listen((dynamic msg) {
          handleMessage(msg, webSocket);
        });
      });
    } else {
      request.response.statusCode = HttpStatus.notAcceptable;
      request.response.writeln('Need use WebSocket connect');
      request.response.close();
      return new Future(() {});
    }
  }

  Function webSocketListen;

  void handleMessage(dynamic msg, WebSocket webSocket) {
    if (webSocket.closeCode == null) {
      Map<String, dynamic> data;
      try {
        data = json.decode(msg);
      } catch (err) {
        print('[Server Error], webSocket msg can not decode: $msg');
        if (webSocketListen != null) {
          webSocketListen(msg);
        }
      }

      // if data have _entangleType;
      if (data != null && data.containsKey(_entangleType)) {
        Map<String, dynamic> theType = data[_entangleType];

        if (theType.containsKey(_entangleController)) {
          String ctrl = theType[_entangleController].split('.')[0];
          if (controllers.containsKey(ctrl)) {
            Function ctrlFn = controllers[ctrl];

            void send(Map<String, dynamic> reback) {
              if (webSocket.closeCode == null) {
                Map<String, dynamic> rebackMap = {};
                rebackMap.addAll(reback);
                rebackMap[_entangleType] = theType;
                webSocket.add(json.encode(rebackMap));
              }
            }

            ctrlFn(context, data, send);
          }
        }
      }
    }
  }
}

List<String> entangleGetPaths(Map<String, dynamic> data) {
  if (data.containsKey(_entangleType)) {
    Map<String, dynamic> theType = data[_entangleType];

    if (theType.containsKey(_entangleController)) {
      List<String> paths = theType[_entangleController].split('.');
      return paths;
    }
    return null;
  }
  return null;
}
