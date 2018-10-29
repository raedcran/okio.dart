
import 'dart:typed_data';

import 'package:okio/okio.dart';
import 'package:rx_command/rx_command.dart';
import 'package:rxdart/rxdart.dart';

import 'okio_example.dart';

/// Immutable = Built
class LoginRequest$ extends LoginRequest {
  final String _username;
  final String _password;

  LoginRequest$(this._username, this._password);

  String get username => _username;

  String get password => _password;
}

/// Builder = Built
class LoginRequestBuilder extends LoginRequest {
  String _username;
  String _password;

  LoginRequestBuilder();

  LoginRequestBuilder.from(LoginRequest m) {}

  @override
  String get username => _username;

  @override
  set username(String value) => _username = value;

  void withUsername(String value) => username = value;

  @override
  String get password => _password;

  @override
  set password(String value) => _password = value;

  /// Build
  LoginRequest build() => LoginRequest$(_username, _password);

  @override
  String toString() {
    return 'LoginRequestBuilder{username: $_username, password: $_password}';
  }
}

/// Entry errors are errors immediately known upon entry.
/// These are cleared on each pass.
class EntryError {}

/// Verify errors are asynchronously resolved errors provided from elsewhere.
/// Verify pa
class VerifyError {
  // Condition in which to enforce a verify.
}

class FieldModel<T, M> {
  final String name;
  final M model;

  // Binding to model object.
  final PropertyBinding<T, M> binding;

  // Transform incoming value.
  final BehaviorSubject<FieldModel> changeSubject;
  final T Function(T value) transformer;
  List<EntryError> entryErrors = [];
  List<Exception> errors = [];
  final BehaviorSubject<T> value;
  final BehaviorSubject<bool> valid = BehaviorSubject();
  final BehaviorSubject<bool> enabled = BehaviorSubject();

  FieldModel(
      this.name, this.changeSubject, this.model, this.binding, this.transformer)
      : value = BehaviorSubject(seedValue: binding.get(model)) {
    value.map((v) => transformer != null ? transformer(v) : v).listen((v) {
      if (binding != null) binding.set(model, v);

      if (changeSubject != null) changeSubject.add(this);
    });
  }

  bool isValid() {
    enabled.add(true);
  }

  void call(T value) => this.value.add(value);

  void dispose() {
    value.close();
    valid.close();
    enabled.close();
  }
}

abstract class CommandModel<T, M, R> {
  M get model;

  void init();

  void beforeInit() {}

  void afterInit() {}

  void dispose();

  void afterDispose() {}

  bool validate();

  Future<R> execute(T request);
}

abstract class LoginRequestCommand<R>
    extends CommandModel<LoginRequest, LoginRequestBuilder, R> {
  LoginRequestBuilder _builder = LoginRequestBuilder();

  BehaviorSubject<FieldModel> changes = BehaviorSubject();

  // Fields.
  FieldModel<String, LoginRequestBuilder> username;
  FieldModel<String, LoginRequestBuilder> password;

  @override
  LoginRequestBuilder get model => _builder;

  LoginRequestCommand() {
    init();
  }

  void init() {
    // Before.
    beforeInit();

    username = FieldModel(
        "username",
        changes,
        model,
        PropertyBinding<String, LoginRequestBuilder>(
                (LoginRequestBuilder b) => b.username,
                (LoginRequestBuilder b, String v) => b.username = v),
        mapUsername);

    password = FieldModel(
        "password",
        changes,
        model,
        PropertyBinding<String, LoginRequestBuilder>(
                (LoginRequestBuilder b) => b.password,
                (LoginRequestBuilder b, String v) => b.password = v),
        mapPassword);

    // After.
    afterInit();
  }

  void beforeInit() {}

  void afterInit() {}

  String mapUsername(String s) => s.trim();

  String mapPassword(String s) => s.trim();

  List<FieldModel> get fields => [username, password];

  Future<bool> onChange() {
    if (validate()) {
      return Future.value(true);
    } else {
      return Future.value(true);
    }
  }

  bool validate() {
//    print("validate: ${validator}");
//    print(builder);
    return true;
  }

  void dispose() {
    if (username != null) {
      username.dispose();
      username = null;
    }
    if (password != null) {
      password.dispose();
      password = null;
    }
  }
}



class PropertyBinding<T, B> {
  final T Function(B builder) getter;
  final Function(B builder, T value) setter;

  PropertyBinding(this.getter, this.setter);

  T get(B builder) => getter(builder);

  void set(B builder, T value) => setter(builder, value);
}

class FieldDescriptor<T> {
  final int tag;
  final String name;
  final ProtoAdapter<T> proto;

  FieldDescriptor(this.tag, this.name, this.proto);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is FieldDescriptor &&
              runtimeType == other.runtimeType &&
              tag == other.tag &&
              name == other.name;

  @override
  int get hashCode => tag.hashCode ^ name.hashCode;
}

abstract class ModelAdapter<T> {
  ProtoAdapter<T> get proto;

  List<FieldDescriptor> get fields;

  Map<String, FieldDescriptor> get byTags;

  Map<String, FieldDescriptor> get byNames;

  FieldDescriptor ofTag(int tag);

  FieldDescriptor ofName(String name);
}

class LoginRequestAdapter extends ModelAdapter<LoginRequest> {
  static final PROTO = LoginRequestProtoAdapter();

  // Fields
  static final USERNAME = FieldDescriptor(1, "username", ProtoAdapter.STRING);
  static final PASSWORD = FieldDescriptor(2, "password", ProtoAdapter.STRING);

  // Indexes
  static final ALL = <FieldDescriptor>[USERNAME, PASSWORD];
  static final BY_NAME = <String, FieldDescriptor>{
    "username": USERNAME,
    "password": PASSWORD
  };
  static final BY_TAG = <String, FieldDescriptor>{
    "username": USERNAME,
    "password": PASSWORD
  };

  @override
  ProtoAdapter<LoginRequest> get proto => PROTO;

  @override
  List<FieldDescriptor> get fields => ALL;

  @override
  Map<String, FieldDescriptor> get byTags => BY_TAG;

  @override
  Map<String, FieldDescriptor> get byNames => BY_NAME;

  @override
  FieldDescriptor ofTag(int tag) => BY_TAG[tag];

  @override
  FieldDescriptor ofName(String name) => BY_NAME[name];

  final Map<FieldDescriptor, BehaviorSubject> _subjects = {};

  @override
  Map<FieldDescriptor, BehaviorSubject> get subjects => _subjects;

  BehaviorSubject<T> tap<T>(FieldDescriptor<T> field) {
    return subjects[field] as BehaviorSubject<T>;
  }
}

final LoginRequestProto = LoginRequestProtoAdapter();

class LoginRequestProtoAdapter extends ProtoAdapter<LoginRequest> {
  LoginRequestProtoAdapter() : super(FieldEncoding.LENGTH_DELIMITED);

  @override
  int encodedSize(LoginRequest value) {
    return ProtoAdapter.STRING.encodedSizeWithTag(1, value.username) +
        ProtoAdapter.STRING.encodedSizeWithTag(2, value.password);
  }

  @override
  LoginRequest decode(ProtoReader reader) {
    String _username = null;
    String _password = null;
    int token = reader.beginMessage();
    for (int tag; (tag = reader.nextTag()) != -1;) {
      switch (tag) {
        case 1:
          _username = ProtoAdapter.STRING.decode(reader);
          break;
        case 2:
          _password = ProtoAdapter.STRING.decode(reader);
          break;
        default:
          break;
      }
    }
    reader.endMessage(token);

    return LoginRequest$(_username, _password);
  }

  Map<String, dynamic> decodeAsMap(ProtoReader reader) {
    final map = <String, dynamic>{};
    int token = reader.beginMessage();
    for (int tag; (tag = reader.nextTag()) != -1;) {
      switch (tag) {
        case 1:
          map["username"] = ProtoAdapter.STRING.decode(reader);
          break;
        case 2:
          map["password"] = ProtoAdapter.STRING.decode(reader);
          break;
        default:
          break;
      }
    }
    reader.endMessage(token);
    return map;
  }

  @override
  void encode(ProtoWriter writer, LoginRequest value) {
    ProtoAdapter.STRING.encodeWithTag(writer, 1, value.username);
    ProtoAdapter.STRING.encodeWithTag(writer, 2, value.password);
  }
}

abstract class JsonAdapter<T> {}

abstract class FlatAdapter<T> {}
