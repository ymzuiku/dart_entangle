import 'package:entangle/entangle.dart';
import './example-client.dart';

class Context {
  String name = 'i am a context data';
}

void main() async {
  var entangle = Entangle({
    'hello-world': hello,
  }, context: Context());

  entangle.listen(port: 5000, path: '/ws');

  //simulation client
  clientApp();
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
