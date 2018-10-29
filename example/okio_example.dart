library example.model;

import 'dart:typed_data';

import 'package:okio/okio.dart';
import 'package:rx_command/rx_command.dart';
import 'package:rxdart/rxdart.dart';

import 'okio_example_generated.dart' as generated;

//main2() {
////  print(varint32Size(16383));
////  print(varint64Size(80100000000));
//  final list = Uint8List(8);
//  final view = ByteData.view(list.buffer);
//
//  view.setFloat64(0, 10.876, Endian.little);
//  print(view.getFloat64(0, Endian.little));
//  print(view.getInt32(0));
//
//  var db = 10.123.toDouble();
//  var asint = db.toInt();
//  var db2 = asint.toDouble();
//
//  print(db);
//  print(asint);
//  print(db2);
//
//  final buffer = Buffer();
//  print("wrote: ${buffer.writeUtf8("hi")}");
//  buffer.writeInt32(100, Endian.big);
//  buffer.writeInt32(100, Endian.little);
//  print(buffer.readUtf8(2));
//  print(buffer.readInt32(Endian.big));
//  print(buffer.readInt32(Endian.little));
//
//
////  final segment = Segment.create();
////  final buffer = Buffer();
////
////  final i = 16000000;
////
////  buffer.writeInt32(i);
////
////  final b1 = buffer.readByte();
////  final b2 = buffer.readByte();
////  final b3 = buffer.readByte();
////  final b4 = buffer.readByte();
////
////  final val = Buffer.toInt32(b1, b2, b3, b4, Endian.big);
////
////  print(val);
////
////  final ProtoReader reader = ProtoReader();
//}

main() async {
  final command = LoginManager();

  command.changes.listen((change) {
    print(change.value.value);
  });

  // Pump username.
  command.username("myname");

  // Set password to an empty string.
  await Future.microtask(() => command.password(""));

  // Pump password in a second.
  await Future.delayed(Duration(milliseconds: 1000), () => command.password("test"));
}

abstract class AppManager {
  UserManager user;
}

class UserManager {
  String username;
  String token;
  DateTime expires;
}

class LoginResponse {
  String token;
  DateTime expires;
}

class LoginManager extends generated.LoginRequestCommand<LoginResponse> {
  @override
  bool validate() {

    super.validate();
    return true;
  }

  @override
  Future<LoginResponse> execute(LoginRequest request) {
    return Future.delayed(
        Duration(milliseconds: 1000), () => Future.value(LoginResponse()));
  }
}

abstract class LoginRequest {
  @Wire(tag: 1)
  String get username;

  @Wire(tag: 2, json: "pwd")
  String get password;

  static generated.LoginRequestBuilder builder() =>
      generated.LoginRequestBuilder();
}


class Wire {
  final int tag;
  final String json;

  const Wire({this.tag = -1, this.json = ""});
}



