import 'dart:convert';
import 'dart:typed_data';

import 'package:okio/buffer.dart';

const int MAX_INT64 = 9223372036854775807;

///
abstract class ProtoAdapter<E> {
  static final int _FIXED_BOOL_SIZE = 1;
  static final int _FIXED_32_SIZE = 4;
  static final int _FIXED_64_SIZE = 8;

  final FieldEncoding _fieldEncoding;

  ProtoAdapter<E> packedAdapter;
  ProtoAdapter<E> repeatedAdapter;

  ProtoAdapter(this._fieldEncoding);

  /// The size of the non-null data {@code value}. This does not include
  /// the size required for a length-delimited prefix
  /// (should the type require one).
  int encodedSize(E value);

  /// The size of {@code tag} and {@code value} in the wire format.
  /// This size includes the tag, type, length-delimited prefix
  /// (should the type require one), and value. Returns 0 if
  /// {@code value} is null.
  int encodedSizeWithTag(int tag, E value) {
    if (value == null) return 0;
    var size = encodedSize(value);
    if (_fieldEncoding == FieldEncoding.LENGTH_DELIMITED) {
      size += varint32Size(size);
    }
    return size + ProtoWriter.tagSize(tag);
  }

  /// Write non-null {@code value} to {@code writer}.
  void encode(ProtoWriter writer, E value);

  /// rite {@code tag} and {@code value} to {@code writer}. If value is
  /// null this does nothing.
  void encodeWithTag(ProtoWriter writer, int tag, E value) {
    if (value == null) return;
    writer.writeTag(tag, _fieldEncoding);
    if (_fieldEncoding == FieldEncoding.LENGTH_DELIMITED) {
      writer.writeVarint32(encodedSize(value));
    }
    encode(writer, value);
  }

  /// Encode {@code value} and write it to {@code stream}.
  void encodeTo(BufferedSink sink, E value) {
    if (sink == null) return;
    if (value == null) return;
    encode(ProtoWriter(sink: sink), value);
  }

  /// Encode {@code value} as a {@code Uint8List}.
  List<int> encodeToBytes(E value) {
    if (value == null) return Uint8List(0);
    final buffer = Buffer();
    try {
      encodeTo(buffer, value);
    } catch (e) {
      throw AssertionError(e.toString());
    }
    return buffer.readByteArray();
  }

  E decode(ProtoReader reader);

  E decodeFrom(BufferedSource source) {
    return decode(ProtoReader(source: source));
  }

  E decodeFromBytes(List<int> bytes) {
    if (bytes == null) return null;
    final buffer = Buffer();
    buffer.writeBytes(bytes);
    ListSource.of(bytes);
    return decodeFrom(buffer);
  }

  ProtoAdapter<List<E>> _createRepeated() {
    return ListProtoAdapter<E>(this);
  }

  E redact(E value) {
    return null;
  }

  static final ProtoAdapter<bool> BOOL = _BoolAdapter();
  static final ProtoAdapter<int> INT32 = _Int32Adapter();
  static final ProtoAdapter<int> UINT32 = _Uint32Adapter();
  static final ProtoAdapter<int> SINT32 = _Sint32Adapter();
  static final ProtoAdapter<int> FIXED32 = _Fixed32Adapter();
  static final ProtoAdapter<int> INT64 = _Int64Adapter();
  static final ProtoAdapter<int> UINT64 = _Uint64Adapter();
  static final ProtoAdapter<int> SINT64 = _Sint64Adapter();
  static final ProtoAdapter<int> FIXED64 = _Fixed64Adapter();
  static final ProtoAdapter<double> FLOAT = _FloatAdapter();
  static final ProtoAdapter<double> DOUBLE = _DoubleAdapter();
  static final ProtoAdapter<List<int>> BYTES = _BytesAdapter();
  static final ProtoAdapter<String> STRING = _StringAdapter();

  static newMapAdapter<K, V>(
          ProtoAdapter<K> keyAdapter, ProtoAdapter<V> valueAdapter) =>
      _MapProtoAdapter(keyAdapter, valueAdapter);
}

class ListProtoAdapter<E> extends ProtoAdapter<List<E>> {
  final ProtoAdapter<E> adapter;

  ListProtoAdapter(this.adapter) : super(FieldEncoding.LENGTH_DELIMITED);

  @override
  int encodedSize(List value) {
    throw UnsupportedError("Repeated values can only be sized with a tag.");
  }

  @override
  int encodedSizeWithTag(int tag, List<E> value) {
    var size = 0;
    var i = 0;
    var count = value.length;
    for (; i < count; i++) {
      size += adapter.encodedSizeWithTag(tag, value[i]);
    }
    return size;
  }

  @override
  List<E> decode(ProtoReader reader) {
    E value = adapter.decode(reader);
    return [value];
  }

  @override
  void encode(ProtoWriter writer, List<E> value) {
    throw UnsupportedError("Repeated values can only be encoded with a tag.");
  }

  @override
  void encodeWithTag(ProtoWriter writer, int tag, List<E> value) {
    var i = 0;
    var count = value.length;
    for (; i < count; i++) {
      adapter.encodeWithTag(writer, tag, value[i]);
    }
  }

  @override
  List<E> redact(List value) {
    return [];
  }
}

class SetProtoAdapter<E> {}

class _MapProtoAdapter<K, V> extends ProtoAdapter<Map<K, V>> {
  final _MapEntryProtoAdapter<K, V> entryAdapter;

  _MapProtoAdapter(ProtoAdapter<K> keyAdapter, ProtoAdapter<V> valueAdapter)
      : entryAdapter = _MapEntryProtoAdapter(keyAdapter, valueAdapter),
        super(FieldEncoding.LENGTH_DELIMITED);

  @override
  int encodedSize(Map<K, V> value) {
    throw UnsupportedError("Repeated values can only be sized with a tag.");
  }

  @override
  int encodedSizeWithTag(int tag, Map<K, V> value) {
    int size = 0;
    value.entries.forEach(
        (entry) => size += entryAdapter.encodedSizeWithTag(tag, entry));
    return size;
  }

  @override
  Map<K, V> decode(ProtoReader reader) {
    K key = null;
    V value = null;

    int token = reader.beginMessage();
    for (int tag; (tag = reader.nextTag()) != -1;) {
      switch (tag) {
        case 1:
          key = entryAdapter.keyAdapter.decode(reader);
          break;
        case 2:
          value = entryAdapter.valueAdapter.decode(reader);
          break;
        default:
          break;
      }
    }
    reader.endMessage(token);

    if (key == null) throw StateError("MapEntry with null key");
    if (value == null) throw StateError("MapEntry with null value");
    return <K, V>{key: value};
  }

  @override
  void encode(ProtoWriter writer, Map<K, V> value) {
    throw UnsupportedError("Repeated values can only be encoded with a tag.");
  }

  @override
  void encodeWithTag(ProtoWriter writer, int tag, Map<K, V> value) {
    value.entries
        .forEach((entry) => entryAdapter.encodeWithTag(writer, tag, entry));
  }

  @override
  Map<K, V> redact(Map value) {
    return {};
  }
}

class _MapEntryProtoAdapter<K, V> extends ProtoAdapter<MapEntry<K, V>> {
  final ProtoAdapter<K> keyAdapter;
  final ProtoAdapter<V> valueAdapter;

  _MapEntryProtoAdapter(this.keyAdapter, this.valueAdapter)
      : super(FieldEncoding.LENGTH_DELIMITED);

  @override
  int encodedSize(MapEntry<K, V> value) {
    return keyAdapter.encodedSizeWithTag(1, value.key) +
        valueAdapter.encodedSizeWithTag(2, value.value);
  }

  @override
  void encode(ProtoWriter writer, MapEntry<K, V> value) {
    keyAdapter.encodeWithTag(writer, 1, value.key);
    valueAdapter.encodeWithTag(writer, 2, value.value);
  }

  @override
  MapEntry<K, V> decode(ProtoReader reader) {
    throw UnsupportedError("Decoding happens in MapProtoAdapter");
  }
}

class _BoolAdapter extends ProtoAdapter<bool> {
  _BoolAdapter() : super(FieldEncoding.VARINT);

  @override
  bool decode(ProtoReader reader) {
    int value = reader.readVarint32();
    if (value == 0) return false;
    if (value == 1) return true;
    throw StateError("invalid boolean value ${value}");
  }

  @override
  void encode(ProtoWriter writer, bool value) {
    writer.writeVarint32(value ? 1 : 0);
  }

  @override
  int encodedSize(bool value) {
    return ProtoAdapter._FIXED_BOOL_SIZE;
  }
}

class _Int32Adapter extends ProtoAdapter<int> {
  _Int32Adapter() : super(FieldEncoding.VARINT);

  @override
  int encodedSize(int value) {
    return int32Size(value);
  }

  @override
  void encode(ProtoWriter writer, int value) {
    writer.writeSignedVarint32(value);
  }

  @override
  int decode(ProtoReader reader) {
    return reader.readVarint32();
  }
}

class _Uint32Adapter extends ProtoAdapter<int> {
  _Uint32Adapter() : super(FieldEncoding.VARINT);

  @override
  int encodedSize(int value) {
    return varint32Size(value);
  }

  @override
  void encode(ProtoWriter writer, int value) {
    writer.writeVarint32(value);
  }

  @override
  int decode(ProtoReader reader) {
    return reader.readVarint32();
  }
}

class _Sint32Adapter extends ProtoAdapter<int> {
  _Sint32Adapter() : super(FieldEncoding.VARINT);

  @override
  int encodedSize(int value) {
    return varint32Size(_encodeZigZag32(value));
  }

  @override
  void encode(ProtoWriter writer, int value) {
    writer.writeVarint32(_encodeZigZag32(value));
  }

  @override
  int decode(ProtoReader reader) {
    return _decodeZigZag32(reader.readVarint32());
  }
}

class _Fixed32Adapter extends ProtoAdapter<int> {
  _Fixed32Adapter() : super(FieldEncoding.FIXED_32);

  @override
  int encodedSize(int value) {
    return ProtoAdapter._FIXED_32_SIZE;
  }

  @override
  void encode(ProtoWriter writer, int value) {
    writer.writeFixed32(value);
  }

  @override
  int decode(ProtoReader reader) {
    return reader.readFixed32();
  }
}

class _Int64Adapter extends ProtoAdapter<int> {
  _Int64Adapter() : super(FieldEncoding.VARINT);

  @override
  int encodedSize(int value) {
    return varint64Size(value);
  }

  @override
  void encode(ProtoWriter writer, int value) {
    writer.writeVarint64(value);
  }

  @override
  int decode(ProtoReader reader) {
    return reader.readVarint64();
  }
}

class _Uint64Adapter extends ProtoAdapter<int> {
  _Uint64Adapter() : super(FieldEncoding.VARINT);

  @override
  int encodedSize(int value) {
    return varint64Size(value);
  }

  @override
  void encode(ProtoWriter writer, int value) {
    writer.writeVarint64(value);
  }

  @override
  int decode(ProtoReader reader) {
    return reader.readVarint32();
  }
}

class _Sint64Adapter extends ProtoAdapter<int> {
  _Sint64Adapter() : super(FieldEncoding.VARINT);

  @override
  int encodedSize(int value) {
    return varint64Size(encodeZigZag64(value));
  }

  @override
  void encode(ProtoWriter writer, int value) {
    writer.writeVarint64(encodeZigZag64(value));
  }

  @override
  int decode(ProtoReader reader) {
    return _decodeZigZag64(reader.readVarint64());
  }
}

class _Fixed64Adapter extends ProtoAdapter<int> {
  _Fixed64Adapter() : super(FieldEncoding.FIXED_64);

  @override
  int encodedSize(int value) {
    return ProtoAdapter._FIXED_64_SIZE;
  }

  @override
  void encode(ProtoWriter writer, int value) {
    writer.writeFixed64(value);
  }

  @override
  int decode(ProtoReader reader) {
    return reader.readFixed64();
  }
}

class _FloatAdapter extends ProtoAdapter<double> {
  _FloatAdapter() : super(FieldEncoding.FIXED_32);

  @override
  int encodedSize(double value) {
    return ProtoAdapter._FIXED_32_SIZE;
  }

  @override
  void encode(ProtoWriter writer, double value) {
    writer.writeFloat(value);
  }

  @override
  double decode(ProtoReader reader) {
    return reader.readFloat();
  }
}

class _DoubleAdapter extends ProtoAdapter<double> {
  _DoubleAdapter() : super(FieldEncoding.FIXED_64);

  @override
  int encodedSize(double value) {
    return ProtoAdapter._FIXED_64_SIZE;
  }

  @override
  void encode(ProtoWriter writer, double value) {
    writer.writeDouble(value);
  }

  @override
  double decode(ProtoReader reader) {
    return reader.readDouble();
  }
}

class _BytesAdapter extends ProtoAdapter<List<int>> {
  _BytesAdapter() : super(FieldEncoding.LENGTH_DELIMITED);

  @override
  int encodedSize(List<int> value) {
    return value.length;
  }

  @override
  void encode(ProtoWriter writer, List<int> value) {
    writer.writeBytes(value);
  }

  @override
  List<int> decode(ProtoReader reader) {
    return reader.readBytes();
  }
}

class _StringAdapter extends ProtoAdapter<String> {
  _StringAdapter() : super(FieldEncoding.LENGTH_DELIMITED);

  @override
  int encodedSize(String value) {
    return value.length;
  }

  @override
  void encode(ProtoWriter writer, String value) {
    writer.writeString(value);
  }

  @override
  String decode(ProtoReader reader) {
    return reader.readString();
  }
}

/// Computes the number of bytes that would be needed to encode a signed
/// variable-length integer of up to 32 bits.
int int32Size(int value) {
  if (value >= 0) {
    return varint32Size(value);
  } else {
// Must sign-extend.
    return 10;
  }
}

/// Compute the number of bytes that would be needed to encode a varint.
/// {@code value} is treated as unsigned, so it won't be sign-extended
/// if negative.
int varint32Size(int value) {
  if ((value & (0xffffffff << 7)) == 0) return 1;
  if ((value & (0xffffffff << 14)) == 0) return 2;
  if ((value & (0xffffffff << 21)) == 0) return 3;
  if ((value & (0xffffffff << 28)) == 0) return 4;
  return 5;
}

/// Compute the number of bytes that would be needed to encode a varint.
int varint64Size(int value) {
  if ((value & (0xffffffffffffffff << 7)) == 0) return 1;
  if ((value & (0xffffffffffffffff << 14)) == 0) return 2;
  if ((value & (0xffffffffffffffff << 21)) == 0) return 3;
  if ((value & (0xffffffffffffffff << 28)) == 0) return 4;
  if ((value & (0xffffffffffffffff << 35)) == 0) return 5;
  if ((value & (0xffffffffffffffff << 42)) == 0) return 6;
  if ((value & (0xffffffffffffffff << 49)) == 0) return 7;
  if ((value & (0xffffffffffffffff << 56)) == 0) return 8;
  if ((value & (0xffffffffffffffff << 63)) == 0) return 9;
  return 10;
}

/// Encode a ZigZag-encoded 32-bit value. ZigZag encodes signed integers into
/// values that can be efficiently encoded with varint. (Otherwise, negative
/// values must be sign-extended to 64 bits to be varint encoded, thus always
/// taking 10 bytes on the wire.)
///
/// @param n A signed 32-bit integer.
/// @return An unsigned 32-bit integer, stored in a signed int because
///         Dart has no explicit unsigned support.
int _encodeZigZag32(int value) => (value << 1) ^ (value >> 31);

/// Encode a ZigZag-encoded 64-bit value. ZigZag encodes signed integers into
/// values that can be efficiently encoded with varint. (Otherwise, negative
/// values must be sign-extended to 64 bits
/// to be varint encoded, thus always taking 10 bytes on the wire.)
///
/// @param n A signed 64-bit integer.
/// @return An unsigned 64-bit integer, stored in a signed int because Dart
///         has no explicit unsigned support.
int encodeZigZag64(int value) => (value << 1) ^ (value >> 63);

/// Decodes a ZigZag-encoded 32-bit value. ZigZag encodes signed integers into
/// values that can be efficiently encoded with varint. (Otherwise, negative
/// values must be sign-extended to 64 bits to be varint encoded, thus always
/// taking 10 bytes on the wire.)
///
/// @param value An unsigned 32-bit integer, stored in a signed int because Dart
///              has no explicit unsigned support.
/// @return A signed 32-bit integer.
int _decodeZigZag32(int value) {
  if ((value & 0x1) == 1) {
    return -(value >> 1) - 1;
  } else {
    return value >> 1;
  }
}

/// Decodes a ZigZag-encoded 64-bit value. ZigZag encodes signed integers into
/// values that can be efficiently encoded with varint. (Otherwise, negative
/// values must be sign-extended to 64 bits to be varint encoded, thus always
/// taking 10 bytes on the wire.)
///
/// @param n An unsigned 64-bit integer, stored in a signed int because Dart
///          has no explicit unsigned support.
/// @return A signed 64-bit integer.
int _decodeZigZag64(int value) {
  if ((value & 0x1) == 1) value = -value;
  return value >> 1;
}

class FieldEncoding {
  final int value;

  const FieldEncoding(this.value);

  static const VARINT = const FieldEncoding(0);
  static const FIXED_64 = const FieldEncoding(1);
  static const LENGTH_DELIMITED = const FieldEncoding(2);
  static const FIXED_32 = const FieldEncoding(5);

  static FieldEncoding get(int value) {
    switch (value) {
      case 0:
        return VARINT;
      case 1:
        return FIXED_32;
      case 2:
        return LENGTH_DELIMITED;
      case 5:
        return FIXED_32;
      default:
        throw ProtocolException('Unexpected FieldEncoding: $value');
    }
  }

  ProtoAdapter rawProtoAdapter() {
    switch (this) {
      case VARINT:
        return ProtoAdapter.UINT64;
      case FIXED_32:
        return ProtoAdapter.FIXED32;
      case FIXED_64:
        return ProtoAdapter.FIXED64;
      case LENGTH_DELIMITED:
        return ProtoAdapter.BYTES;
      default:
        throw AssertionError();
    }
  }
}

abstract class TagHandler {
  static final UNKNOWN_TAG = Object();

  /// Reads a value from the calling reader. Returns {@link #UNKNOWN_TAG} if
  /// no value was read, or any other value otherwise.
  Object decodeMessage(int tag);
}

class ProtoReader {
  static final int RECURSION_LIMIT = 65;
  static final int FIELD_ENCODING_MASK = 0x7;
  static final int TAG_FIELD_ENCODING_BITS = 3;

  // Read states. These constants correspond to field encodings
  // where both exist.
  static const int STATE_VARINT = 0;
  static const int STATE_FIXED64 = 1;
  static const int STATE_LENGTH_DELIMITED = 2;
  static const int STATE_START_GROUP = 3;
  static const int STATE_END_GROUP = 4;
  static const int STATE_FIXED32 = 5;
  static const int STATE_TAG = 6; // Note: not a field encoding.
  static const int STATE_PACKED_TAG = 7; // Note: not a field encoding.

  BufferedSource source;

  /// The current position in the input source, starting at 0 and
  /// increasing monotonically.
  int pos = 0;

  /// The absolute position of the end of the current message.
  int limit = MAX_INT64;

  /// The current number of levels of message nesting.
  int recursionDepth;

  /// How to interpret the next read call.
  int state = STATE_LENGTH_DELIMITED;

  /// The most recently read tag. Used to make packed values look
  /// like regular values.
  int tag = -1;

  /// Limit once we complete the current length-delimited value.
  int pushedLimit = -1;

  /// The encoding of the next value to be read.
  FieldEncoding nextFieldEncoding;

  ProtoReader({this.source}) {
    if (source == null) {
      source = Buffer();
    }
  }

  /// Begin a nested message. A call to this method will restrict the reader
  /// so that {@link #nextTag()} returns -1 when the message is complete.
  /// An accompanying call to {@link #endMessage(long)} must then occur
  ///   with the opaque token returned from this method.
  int beginMessage() {
    if (state != STATE_LENGTH_DELIMITED) {
      throw StateError("Unexpected call to beginMessage()");
    }
    if (++recursionDepth > RECURSION_LIMIT) {
      throw ProtocolException("Wire recursion limit exceeded");
    }
    // Give the pushed limit to the caller to hold. The value is returned in
    // endMessage() where we resume using it as our limit.
    int token = pushedLimit;
    pushedLimit = -1;
    state = STATE_TAG;
    return token;
  }

  /// End a length-delimited nested message. Calls to this method must be
  /// symmetric with calls to {@link #beginMessage()}.
  ///
  /// @param token value returned from the corresponding call
  /// to {@link #beginMessage()}.
  void endMessage(int token) {
    if (state != STATE_TAG) throw StateError("Unexpected call to endMessage()");

    if (--recursionDepth < 0 || pushedLimit != -1)
      throw StateError("No corresponding call to beginMessage()");

    if (pos != limit && recursionDepth != 0)
      throw ProtocolException("Expected to end at ${limit} but was ${pos}");

    limit = token;
  }

  /// Reads and returns the next tag of the message, or -1 if there are no
  /// further tags. Use {@link #peekFieldEncoding()} after calling this
  /// method to query its encoding. This silently skips groups.
  int nextTag() {
    if (state == STATE_PACKED_TAG) {
      state = STATE_LENGTH_DELIMITED;
      return tag;
    } else if (state != STATE_TAG) {
      throw StateError("unexpected call to nextTag()");
    }

    while (pos < limit && !source.exhausted()) {
      var tagAndFieldEncoding = _internalReadVarint32();
      if (tagAndFieldEncoding == 0) throw ProtocolException("unexpected tag 0");

      tag = tagAndFieldEncoding >> TAG_FIELD_ENCODING_BITS;
      var groupOrFieldEncoding = tagAndFieldEncoding & FIELD_ENCODING_MASK;
      switch (groupOrFieldEncoding) {
        case STATE_START_GROUP:
          _skipGroup(tag);
          continue;

        case STATE_END_GROUP:
          throw ProtocolException("unexpected end group");

        case STATE_LENGTH_DELIMITED:
          nextFieldEncoding = FieldEncoding.LENGTH_DELIMITED;
          state = STATE_LENGTH_DELIMITED;
          var length = _internalReadVarint32();
          if (length < 0) throw ProtocolException("negative length: ${length}");
          if (pushedLimit != -1) throw StateError("unexpected pushedLimit");
          // Push the current limit, and set a new limit to the length
          // of this value.
          pushedLimit = limit;
          limit = pos + length;
          if (limit > pushedLimit) throw EOFException();
          return tag;

        case STATE_VARINT:
          nextFieldEncoding = FieldEncoding.VARINT;
          state = STATE_VARINT;
          return tag;

        case STATE_FIXED64:
          nextFieldEncoding = FieldEncoding.FIXED_64;
          state = STATE_FIXED64;
          return tag;

        case STATE_FIXED32:
          nextFieldEncoding = FieldEncoding.FIXED_32;
          state = STATE_FIXED32;
          return tag;

        default:
          throw ProtocolException(
              "unexpected field encoding: ${groupOrFieldEncoding}");
      }
    }
    return -1;
  }

  /// Returns the encoding of the next field value. {@link #nextTag()}
  /// must be called before this method.
  FieldEncoding peekFieldEncoding() {
    return nextFieldEncoding;
  }

  /**
   * Skips the current field's value. This is only safe to call immediately
   * following a call to {@link #nextTag()}.
   */
  void skip() {
    switch (state) {
      case STATE_LENGTH_DELIMITED:
        int byteCount = _beforeLengthDelimitedScalar();
        source.skipBytes(byteCount);
        break;
      case STATE_VARINT:
        readVarint64();
        break;
      case STATE_FIXED64:
        readFixed64();
        break;
      case STATE_FIXED32:
        readFixed32();
        break;
      default:
        throw StateError("Unexpected call to skip()");
    }
  }

  /// Skips a section of the input delimited by START_GROUP/END_GROUP
  /// type markers.
  void _skipGroup(int expectedEndTag) {
    while (pos < limit && !source.exhausted()) {
      int tagAndFieldEncoding = _internalReadVarint32();
      if (tagAndFieldEncoding == 0) throw ProtocolException("Unexpected tag 0");
      int tag = tagAndFieldEncoding >> TAG_FIELD_ENCODING_BITS;
      int groupOrFieldEncoding = tagAndFieldEncoding & FIELD_ENCODING_MASK;
      switch (groupOrFieldEncoding) {
        case STATE_START_GROUP:
          _skipGroup(tag); // Nested group.
          break;
        case STATE_END_GROUP:
          if (tag == expectedEndTag) return; // Success!
          throw ProtocolException("Unexpected end group");
        case STATE_LENGTH_DELIMITED:
          int length = _internalReadVarint32();
          pos += length;
          source.skipBytes(length);
          break;
        case STATE_VARINT:
          state = STATE_VARINT;
          readVarint64();
          break;
        case STATE_FIXED64:
          state = STATE_FIXED64;
          readFixed64();
          break;
        case STATE_FIXED32:
          state = STATE_FIXED32;
          readFixed32();
          break;
        default:
          throw ProtocolException(
              "Unexpected field encoding: ${groupOrFieldEncoding}");
      }
    }
    throw EOFException();
  }

  /// Reads a {@code bytes} field value from the stream. The length is
  /// read from the stream prior to the actual data.
  List<int> readBytes() {
    int byteCount = _beforeLengthDelimitedScalar();
    return source.readByteArray(byteCount);
  }

  /// Reads a {@code string} field value from the stream.
  String readString([bool allowMalformed = true]) {
    return utf8.decode(readBytes(), allowMalformed: allowMalformed);
  }

  /// Reads a raw varint from the stream.  If larger than 32 bits, discard the
  /// upper bits.
  int readVarint32() {
    if (state != STATE_VARINT && state != STATE_LENGTH_DELIMITED) {
      throw ProtocolException(
          "Expected VARINT or LENGTH_DELIMITED but was ${state}");
    }
    int result = _internalReadVarint32();
    _afterPackableScalar(STATE_VARINT);
    return result;
  }

  int _internalReadVarint32() {
    pos++;
    int tmp = source.readByte();
    if (tmp >= 0) {
      return tmp;
    }
    int result = tmp & 0x7fffffffffffffff;
    pos++;
    if ((tmp = source.readByte()) >= 0) {
      result |= tmp << 7;
    } else {
      result |= (tmp & 0x7fffffffffffffff) << 7;
      pos++;
      if ((tmp = source.readByte()) >= 0) {
        result |= tmp << 14;
      } else {
        result |= (tmp & 0x7fffffffffffffff) << 14;
        pos++;
        if ((tmp = source.readByte()) >= 0) {
          result |= tmp << 21;
        } else {
          result |= (tmp & 0x7fffffffffffffff) << 21;
          pos++;
          result |= (tmp = source.readByte()) << 28;
          if (tmp < 0) {
            // Discard upper 32 bits.
            for (int i = 0; i < 5; i++) {
              pos++;
              if (source.readByte() >= 0) {
                return result;
              }
            }
            throw ProtocolException("Malformed VARINT");
          }
        }
      }
    }
    return result;
  }

  /// Reads a raw varint up to 64 bits in length from the stream.
  int readVarint64() {
    if (state != STATE_VARINT && state != STATE_LENGTH_DELIMITED) {
      throw ProtocolException(
          "Expected VARINT or LENGTH_DELIMITED but was ${state}");
    }
    int shift = 0;
    int result = 0;
    while (shift < 64) {
      pos++;
      int b = source.readByte();
      result |= (b & 0x7fffffffffffffff) << shift;
      if ((b & 0x8000000000000000) == 0) {
        _afterPackableScalar(STATE_VARINT);
        return result;
      }
      shift += 7;
    }
    throw ProtocolException("WireInput encountered a malformed varint");
  }

  /// Reads a 32-bit little-endian integer from the stream.
  int readFixed32() {
    if (state != STATE_FIXED32 && state != STATE_LENGTH_DELIMITED) {
      throw ProtocolException(
          "Expected FIXED32 or LENGTH_DELIMITED but was ${state}");
    }
    source.require(4); // Throws EOFException if insufficient.
    pos += 4;
    int result = source.readInt32(Endian.little);
    _afterPackableScalar(STATE_FIXED32);
    return result;
  }

  /// Reads a 32-bit little-endian floating point number from the stream.
  double readFloat() {
    if (state != STATE_FIXED32 && state != STATE_LENGTH_DELIMITED) {
      throw ProtocolException(
          "Expected FIXED32 or LENGTH_DELIMITED but was $state");
    }
    source.require(4); // Throws EOFException if insufficient.
    pos += 4;
    double result = source.readFloat32(Endian.little);
    _afterPackableScalar(STATE_FIXED32);
    return result;
  }

  /// Reads a 64-bit little-endian integer from the stream.
  int readFixed64() {
    if (state != STATE_FIXED64 && state != STATE_LENGTH_DELIMITED) {
      throw ProtocolException(
          "Expected FIXED64 or LENGTH_DELIMITED but was $state");
    }
    source.require(8); // Throws EOFException if insufficient.
    pos += 8;
    int result = source.readInt64(Endian.little);
    _afterPackableScalar(STATE_FIXED64);
    return result;
  }

  /// Reads a 64-bit little-endian floating point number from the stream.
  double readDouble() {
    if (state != STATE_FIXED64 && state != STATE_LENGTH_DELIMITED) {
      throw ProtocolException(
          "Expected FIXED64 or LENGTH_DELIMITED but was $state");
    }
    source.require(8); // Throws EOFException if insufficient.
    pos += 8;
    double result = source.readFloat64(Endian.little);
    _afterPackableScalar(STATE_FIXED64);
    return result;
  }

  void _afterPackableScalar(int fieldEncoding) {
    if (state == fieldEncoding) {
      state = STATE_TAG;
    } else {
      if (pos > limit) {
        throw ProtocolException("Expected to end at $limit but was $pos");
      } else if (pos == limit) {
        // We've completed a sequence of packed values. Pop the limit.
        limit = pushedLimit;
        pushedLimit = -1;
        state = STATE_TAG;
      } else {
        state = STATE_PACKED_TAG;
      }
    }
  }

  int _beforeLengthDelimitedScalar() {
    if (state != STATE_LENGTH_DELIMITED) {
      throw ProtocolException("Expected LENGTH_DELIMITED but was $state");
    }
    int byteCount = limit - pos;
    source.require(byteCount); // Throws EOFException if insufficient.
    state = STATE_TAG;
    // We've completed a length-delimited scalar. Pop the limit.
    pos = limit;
    limit = pushedLimit;
    pushedLimit = -1;
    return byteCount;
  }

  /// Reads each tag, handles it, and returns a byte string with the
  /// unknown fields.
  List<int> forEachTag(TagHandler tagHandler) {
    Buffer unknownFieldsBuffer = null;
    ProtoWriter unknownFieldsWriter = null;

    var token = beginMessage();
    for (int tag; (tag = nextTag()) != -1;) {
      if (tagHandler.decodeMessage(tag) != TagHandler.UNKNOWN_TAG) continue;
      if (unknownFieldsBuffer == null) {
        unknownFieldsBuffer = Buffer();
        unknownFieldsWriter = ProtoWriter(sink: unknownFieldsBuffer);
      }
      copyTag(unknownFieldsWriter, tag);
    }
    endMessage(token);

    return unknownFieldsBuffer != null
        ? unknownFieldsBuffer.readByteArray()
        : Iterable.empty();
  }

  /// Reads the next value from this and writes it to {@code writer}.
  void copyTag(ProtoWriter writer, int tag) {
    final fieldEncoding = peekFieldEncoding();
    final protoAdapter = fieldEncoding.rawProtoAdapter();
    final value = protoAdapter.decode(this);
    try {
      protoAdapter.encodeWithTag(writer, tag, value);
    } catch (e) {
      throw AssertionError(); // Impossible.
    }
  }
}

class ProtoWriter {
  static int makeTag(int fieldNumber, FieldEncoding fieldEncoding) {
    return (fieldNumber << ProtoReader.TAG_FIELD_ENCODING_BITS) |
        fieldEncoding.value;
  }

  /// Compute the number of bytes that would be needed to encode a tag.
  static int tagSize(int tag) {
    return varint32Size(makeTag(tag, FieldEncoding.VARINT));
  }

  BufferedSink sink;

  ProtoWriter({this.sink}) {
    if (sink == null) {
      sink = Buffer();
    }
  }

  void writeTag(int fieldNumber, FieldEncoding fieldEncoding) {
    writeVarint32(makeTag(fieldNumber, fieldEncoding));
  }

  void writeSignedVarint32(int value) {
    if (value >= 0) {
      writeVarint32(value);
    } else {
      // Must sign-extend.
      writeVarint64(value);
    }
  }

  void writeVarint32(int value) {
    sink.writeVarint32(value);
  }

  void writeVarint64(int value) {
    sink.writeVarint64(value);
  }

  void writeFixed32(int value) {
    sink.writeInt32(value, Endian.little);
  }

  void writeFloat(double value) {
    sink.writeFloat32(value, Endian.little);
  }

  void writeFixed64(int value) {
    sink.writeInt64(value, Endian.little);
  }

  void writeDouble(double value) {
    sink.writeFloat64(value, Endian.little);
  }

  void writeBytes(List<int> source, [int offset = 0, int byteCount = 0]) {
    sink.writeBytes(source, offset, byteCount);
  }

  void writeString(String string) {
    sink.writeUtf8(string);
  }
}
