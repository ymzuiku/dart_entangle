import 'dart:io';
import 'dart:convert';

var entangleClient = _EntangleClient();

String _entangleType = '__entangle__';
String _entangleKey = 'k';
String _entangleController = 'c';

class _EntangleClient {
  int sendReConnectMilliseconds = 500;
  int heartMilliseconds = 2000;
  int autoConnectCount = 5;
  int _autoConnectingCount = 0;
  int _key = 0;
  Map<String, Function> _sendCallbacks = {};

  String lastConnectUrl = '';

  WebSocket client;

  void connectHeart() {
    Future.delayed(Duration(milliseconds: heartMilliseconds), () {
      if (client.readyState != 1) {
        connect(lastConnectUrl);
      } else {
        connectHeart();
      }
    });
  }

  Future connect(String url) async {
    if (lastConnectUrl == '') {
      lastConnectUrl = url;
    }
    client = await WebSocket.connect(url);
    _autoConnectingCount = 0;
    client.listen(_onListen);
    return client;
  }

  void _add(/*String|List<int>*/ data) {
    Future.delayed(Duration(milliseconds: 4), () {
      if (client.readyState == 1) {
        client.add(data);
      } else if (client.readyState != 1) {
        _autoConnectingCount += 1;
        if (_autoConnectingCount < autoConnectCount) {
          Future.delayed(Duration(milliseconds: sendReConnectMilliseconds),
              () async {
            await connect(lastConnectUrl);
            _add(data);
          });
        } else {
          print('$lastConnectUrl connect is error!');
        }
      }
    });
  }

  int _updateSendKey() {
    _key += 1;
    if (_key > 999999) {
      _key = 0;
    }
    return _key;
  }

  Function send(String controllerKey, Map<String, dynamic> data,
      {Function listen, int timeOutMilliseconds = 8000}) {
    int theKey = _updateSendKey();
    if (!controllerKey.contains('.')) {
      controllerKey = controllerKey + '.*';
    }

    if (listen != null) {
      _sendCallbacks[theKey.toString()] = listen;
    }

    data[_entangleType] = {};
    data[_entangleType][_entangleController] = controllerKey;
    data[_entangleType][_entangleKey] = theKey;
    String obj = json.encode(data);
    _add(obj);

    void removeListen() {
      _sendCallbacks.remove(theKey.toString());
    }

    if (timeOutMilliseconds > 0) {
      Future.delayed(Duration(milliseconds: timeOutMilliseconds), removeListen);
    }

    return removeListen;
  }

  void _onListen(dynamic msg) async {
    Map<String, dynamic> data;
    try {
      data = json.decode(msg);
    } catch (err) {
      print('[Client Error], WebSocket msg can not decode: $msg');
    }

    if (data.containsKey(_entangleType)) {
      void removeListen() {
        _sendCallbacks.remove(data[_entangleType][_entangleKey].toString());
      }

      _sendCallbacks[data[_entangleType][_entangleKey].toString()](
          data, removeListen);
    }
  }

  Future close([int code, String reason]) async {
    await client.close(code, reason);
  }
}
