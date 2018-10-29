import 'dart:collection';
import 'dart:convert';
import 'dart:typed_data';

const _MASK_8 = 0xff;
const _MASK_32 = 0xffffffff;
const _MASK_64 = 0xffffffffffffffff;
const SEGMENT_SIZE = _Segment.SIZE;

class EOFException implements Exception {
  EOFException();
}

class ProtocolException implements Exception {
  final String cause;

  ProtocolException(this.cause);
}

/**
 * Receives a stream of bytes. Use this interface to write data wherever it's needed: to the
 * network, storage, or a buffer in memory. Sinks may be layered to transform received data, such as
 * to compress, encrypt, throttle, or add protocol framing.
 *
 * Most application code shouldn't operate on a sink directly, but rather on a [BufferedSink] which
 * is both more efficient and more convenient. Use [buffer] to wrap any sink with a buffer.
 *
 * Sinks are easy to test: just use a [Buffer] in your tests, and read from it to confirm it
 * received the data that was expected.
 *
 * ### Comparison with OutputStream
 *
 * This interface is functionally equivalent to [java.io.OutputStream].
 *
 * `OutputStream` requires multiple layers when emitted data is heterogeneous: a `DataOutputStream`
 * for primitive values, a `BufferedOutputStream` for buffering, and `OutputStreamWriter` for
 * charset encoding. This library uses `BufferedSink` for all of the above.
 *
 * Sink is also easier to layer: there is no [write()][java.io.OutputStream.write] method that is
 * awkward to implement efficiently.
 *
 * ### Interop with OutputStream
 *
 * Use [sink] to adapt an `OutputStream` to a sink. Use [outputStream()][BufferedSink.outputStream]
 * to adapt a sink to an `OutputStream`.
 */
//abstract class Sink {
//  void write(Buffer source, int byteCount);
//
//  void flush();
//
//  int timeout();
//
//  void close();
//}

class RealBufferedSink extends BufferedSink {
  final BufferedSink sink;
  final Buffer bufferField = Buffer();
  bool closed = false;

  bool get isOpen => !closed;

  @override
  Buffer get buffer => bufferField;

  RealBufferedSink(this.sink);

  void flush() {
    if (closed) throw StateError("closed");
    if (buffer.size > 0) {
      sink.write(buffer, buffer.size);
    }
    sink.flush();
  }

  @override
  void writeInt64(int i, [Endian endian = Endian.big]) {
    if (closed) throw StateError("closed");
    buffer.writeInt64(i, endian);
    emitCompleteSegments();
  }

  @override
  void close() {
    if (closed) return;

    var thrown = null;

    try {
      if (buffer.size > 0) {
        sink.write(buffer, buffer.size);
      }
    } catch (e) {
      thrown = e;
    }

    try {
//      sink.close();
    } catch (e) {
      if (thrown == null) thrown = e;
    }

    closed = true;
    if (thrown != null) throw thrown;
  }

  @override
  void emitCompleteSegments() {
    if (closed) throw StateError("closed");
    final byteCount = buffer.completeSegmentByteCount();
    if (byteCount > 0) sink.write(buffer, byteCount);
  }

  @override
  void emit() {
    if (closed) throw StateError("closed");
    final byteCount = buffer.completeSegmentByteCount();
    if (byteCount > 0) sink.write(buffer, byteCount);
  }

  @override
  void write(Buffer source, int byteCount) {
    if (closed) throw StateError("closed");
    buffer.write(source, byteCount);
    emitCompleteSegments();
  }

  @override
  int writeVarint64(int value) {
    if (closed) throw StateError("closed");
    buffer.writeVarint64(value);
    emitCompleteSegments();
  }

  @override
  int writeVarint32(int value) {
    if (closed) throw StateError("closed");
    buffer.writeVarint32(value);
    emitCompleteSegments();
  }

  @override
  int writeSignedVarint32(int value) {
    if (closed) throw StateError("closed");
    buffer.writeSignedVarint32(value);
    emitCompleteSegments();
  }

  @override
  void writeFloat64(double f, [Endian endian = Endian.big]) {
    if (closed) throw StateError("closed");
    buffer.writeFloat64(f, endian);
    emitCompleteSegments();
  }

  @override
  void writeFloat32(double f, [Endian endian = Endian.big]) {
    if (closed) throw StateError("closed");
    buffer.writeFloat32(f, endian);
    emitCompleteSegments();
  }

  @override
  void writeDouble(double f, [Endian endian = Endian.big]) {
    if (closed) throw StateError("closed");
    buffer.writeDouble(f, endian);
    emitCompleteSegments();
  }

  @override
  void writeUint64(int i, [Endian endian = Endian.big]) {
    if (closed) throw StateError("closed");
    buffer.writeUint64(i, endian);
    emitCompleteSegments();
  }

  @override
  void writeUint32(int i, [Endian endian = Endian.big]) {
    if (closed) throw StateError("closed");
    buffer.writeUint32(i, endian);
    emitCompleteSegments();
  }

  @override
  void writeInt32(int i, [Endian endian = Endian.big]) {
    if (closed) throw StateError("closed");
    buffer.writeInt32(i, endian);
    emitCompleteSegments();
  }

  @override
  void writeUint16(int s, [Endian endian = Endian.big]) {
    if (closed) throw StateError("closed");
    buffer.writeUint16(s, endian);
    emitCompleteSegments();
  }

  @override
  void writeInt16(int s, [Endian endian = Endian.big]) {
    if (closed) throw StateError("closed");
    buffer.writeInt64(s, endian);
    emitCompleteSegments();
  }

  @override
  void writeInt8(int b) {
    if (closed) throw StateError("closed");
    buffer.writeInt8(b);
    emitCompleteSegments();
  }

  @override
  void writeUint8(int b) {
    if (closed) throw StateError("closed");
    buffer.writeUint8(b);
    emitCompleteSegments();
  }

  @override
  void writeByte(int b) {
    if (closed) throw StateError("closed");
    buffer.writeByte(b);
    emitCompleteSegments();
  }

  @override
  int writeUtf8(String string, [int beginIndex = 0, int endIndex = 0]) {
    if (closed) throw StateError("closed");
    buffer.writeUtf8(string, beginIndex, endIndex);
    emitCompleteSegments();
  }

  @override
  int writeAll(BufferedSource source) {
    if (closed) throw StateError("closed");
    buffer.writeAll(source);
    emitCompleteSegments();
  }

  @override
  void writeBytes(List<int> source, [int offset = 0, int byteCount = 0]) {
    if (closed) throw StateError("closed");
    buffer.writeBytes(source, offset, byteCount);
    emitCompleteSegments();
  }
}

class RealBufferedSource {}

///
abstract class BufferedSink {
  Buffer get buffer;

  void flush();

  void writeBytes(List<int> source, [int offset = 0, int byteCount = 0]);

  void write(Buffer source, int byteCount);

  int writeAll(BufferedSource source);

  int writeUtf8(String string, [int beginIndex = 0, int endIndex = 0]);

  void writeByte(int b);

  void writeUint8(int b);

  void writeInt8(int b);

  void writeInt16(int s, [Endian endian = Endian.big]);

  void writeUint16(int s, [Endian endian = Endian.big]);

  void writeInt32(int i, [Endian endian = Endian.big]);

  void writeUint32(int i, [Endian endian = Endian.big]);

  void writeInt64(int i, [Endian endian = Endian.big]);

  void writeUint64(int i, [Endian endian = Endian.big]);

  void writeDouble(double f, [Endian endian = Endian.big]);

  void writeFloat32(double f, [Endian endian = Endian.big]);

  void writeFloat64(double f, [Endian endian = Endian.big]);

  int writeSignedVarint32(int value);

  int writeVarint32(int value);

  int writeVarint64(int value);

  void emit();

  void emitCompleteSegments();
}

//class BytesSource implements BufferedSource {
//  final ByteBuffer bytes;
//  final ByteData data;
//
//  factory BytesSource.of(ByteBuffer buffer) {
//    return BytesSource(buffer, ByteData.view(buffer));
//  }
//
//  BytesSource(this.bytes, this.data);
//
//  @override
//  int read(Buffer sink, int byteCount) {
//    sink.writeBytes(bytes, byteCount);
//  }
//
//  @override
//  void close() {
//  }
//
//  @override
//  int timeout() {
//    return -1;
//  }
//
//  @override
//  BufferedSource peek() {
//
//  }
//
//  @override
//  String readUtf8([int byteCount = 0]) {
//
//  }
//
//  @override
//  int readAll(Sink sink) {
//
//  }
//
//  @override
//  void readFully(List<int> sink, [int byteCount = 0]) {
//
//  }
//
//  @override
//  int readInto(List<int> sink, [int offset = 0, int byteCount = 0]) {
//
//  }
//
//  @override
//  List<int> readByteArray([int byteCount = 0]) {
//
//  }
//
//  @override
//  void skip(int byteCount) {
//
//  }
//
//  @override
//  int readVarint64() {
//
//  }
//
//  @override
//  int readVarint32() {
//
//  }
//
//  @override
//  int readUint64([Endian endian = Endian.big]) {
//
//  }
//
//  @override
//  int readInt64([Endian endian = Endian.big]) {
//
//  }
//
//  @override
//  int readUint32([Endian endian = Endian.big]) {
//
//  }
//
//  @override
//  int readInt32([Endian endian = Endian.big]) {
//
//  }
//
//  @override
//  int readUint16([Endian endian = Endian.big]) {
//
//  }
//
//  @override
//  int readInt16([Endian endian = Endian.big]) {
//
//  }
//
//  @override
//  int readUint8() {
//
//  }
//
//  @override
//  int readInt8() {
//
//  }
//
//  @override
//  int readByte() {
//
//  }
//
//  @override
//  bool request(int byteCount) {
//
//  }
//
//  @override
//  void require(int byteCount) {
//
//  }
//
//  @override
//  bool exhausted() {
//
//  }
//
//  @override
//  Buffer get buffer {
//
//  }
//
//}

/**
 * Supplies a stream of bytes. Use this interface to read data from wherever it's located: from the
 * network, storage, or a buffer in memory. Sources may be layered to transform supplied data, such
 * as to decompress, decrypt, or remove protocol framing.
 *
 * Most applications shouldn't operate on a source directly, but rather on a [BufferedSource] which
 * is both more efficient and more convenient. Use [buffer] to wrap any source with a buffer.
 *
 * Sources are easy to test: just use a [Buffer] in your tests, and fill it with the data your
 * application is to read.
 *
 * ### Comparison with InputStream
 * This interface is functionally equivalent to [java.io.InputStream].
 *
 * `InputStream` requires multiple layers when consumed data is heterogeneous: a `DataInputStream`
 * for primitive values, a `BufferedInputStream` for buffering, and `InputStreamReader` for strings.
 * This library uses `BufferedSource` for all of the above.
 *
 * Source avoids the impossible-to-implement [available()][java.io.InputStream.available] method.
 * Instead callers specify how many bytes they [require][BufferedSource.require].
 *
 * Source omits the unsafe-to-compose [mark and reset][java.io.InputStream.mark] state that's
 * tracked by `InputStream`; instead, callers just buffer what they need.
 *
 * When implementing a source, you don't need to worry about the [read()][java.io.InputStream.read]
 * method that is awkward to implement efficiently and returns one of 257 possible values.
 *
 * And source has a stronger `skip` method: [BufferedSource.skipBytes] won't return prematurely.
 *
 * ### Interop with InputStream
 *
 * Use [source] to adapt an `InputStream` to a source. Use [BufferedSource.inputStream] to adapt a
 * source to an `InputStream`.
 */
//abstract class Source {
//  int read(Buffer sink, int byteCount);
//
//  int timeout();
//
//  void close();
//}

class ListSource extends BufferedSource {
  final List<int> _list;
  final ByteData _data;
  int _pos;
  int _limit;

  factory ListSource.from(List<int> list) {
    if (list is Uint8List) {
      return ListSource.of(list);
    }
    if (list is TypedData) {
      final typed = list as TypedData;
      return ListSource.of(typed.buffer.asUint8List());
    }
    return ListSource.of(Uint8List.fromList(list));
  }

  factory ListSource.of(Uint8List list) =>
      ListSource._(list, ByteData.view(list.buffer));

  ListSource._(this._list, this._data)
      : _pos = 0,
        _limit = _list.length;

  @override
  Buffer get buffer => throw UnsupportedError("Buffer not available");

  @override
  BufferedSource peek() => throw UnsupportedError("Peek not available");

  @override
  String readUtf8([int byteCount = 0]) {
    if (byteCount <= 0) return "";
    final raw = readByteArray(byteCount);
    return utf8.decode(raw);
  }

  @override
  int readAll(Sink<List<int>> sink) {
    sink.add(_list);
  }

  @override
  void readFully(List<int> sink, [int byteCount = 0]) {
    if (byteCount == 0) byteCount = sink.length;
    byteCount = _minOf(sink.length, byteCount);
    final result = Uint8List(byteCount);
    for (int i = 0; i < byteCount; i++) {
      result[i] = _list[_pos + i];
    }
    _pos += byteCount;
  }

  @override
  int readInto(List<int> sink, [int offset = 0, int byteCount = 0]) {}

  @override
  List<int> readByteArray([int byteCount = 0]) {
    if (byteCount == 0) byteCount = _limit - _pos;
    if (byteCount <= 0) return Uint8List(0);
    final result = Uint8List(byteCount);
    for (int i = 0; i < byteCount; i++) {
      result[i] = _list[_pos + i];
    }
    _pos += byteCount;
    return result;
  }

  @override
  void skipBytes(int byteCount) {}

  @override
  double readFloat32([Endian endian = Endian.big]) {
    if (_pos + 4 > _limit) throw EOFException();
    final result = _data.getFloat32(_pos, endian);
    _pos += 4;
    return result;
  }

  @override
  double readFloat64([Endian endian = Endian.big]) {
    if (_pos + 8 >= _limit) throw EOFException();
    final result = _data.getFloat32(_pos, endian);
    _pos += 8;
    return result;
  }

  @override
  double readDouble([Endian endian = Endian.big]) {
    if (_pos + 8 >= _limit) throw EOFException();
    final result = _data.getFloat32(_pos, endian);
    _pos += 8;
    return result;
  }

  @override
  int readVarint64() {
    return 0;
  }

  @override
  int readVarint32() {
    return 0;
  }

  @override
  int readUint64([Endian endian = Endian.big]) {
    if (_pos + 8 >= _limit) throw EOFException();
    final result = _data.getUint64(_pos, endian);
    _pos += 8;
    return result;
  }

  @override
  int readInt64([Endian endian = Endian.big]) {
    if (_pos + 8 >= _limit) throw EOFException();
    final result = _data.getInt64(_pos, endian);
    _pos += 8;
    return result;
  }

  @override
  int readUint32([Endian endian = Endian.big]) {
    if (_pos + 4 >= _limit) throw EOFException();
    final result = _data.getUint32(_pos, endian);
    _pos += 4;
    return result;
  }

  @override
  int readInt32([Endian endian = Endian.big]) {
    if (_pos + 4 >= _limit) throw EOFException();
    final result = _data.getInt32(_pos, endian);
    _pos += 4;
    return result;
  }

  @override
  int readUint16([Endian endian = Endian.big]) {
    if (_pos + 2 >= _limit) throw EOFException();
    final result = _data.getUint16(_pos, endian);
    _pos += 2;
    return result;
  }

  @override
  int readInt16([Endian endian = Endian.big]) {
    if (_pos + 2 >= _limit) throw EOFException();
    final result = _data.getInt16(_pos, endian);
    _pos += 2;
    return result;
  }

  @override
  int readUint8() {
    if (_pos + 1 >= _limit) throw EOFException();
    final result = _data.getUint8(_pos);
    _pos += 1;
    return result;
  }

  @override
  int readInt8() {
    if (_pos + 1 >= _limit) throw EOFException();
    final result = _data.getInt8(_pos);
    _pos += 1;
    return result;
  }

  @override
  int readByte() {
    if (_pos + 1 >= _limit) throw EOFException();
    final result = _data.getUint8(_pos);
    _pos += 1;
    return result;
  }

  @override
  bool request(int byteCount) {}

  @override
  void require(int byteCount) {
    if (byteCount > _limit) throw EOFException();
  }

  @override
  bool exhausted() => _pos >= _limit;

  @override
  void close() {}

  @override
  int read(Buffer sink, int byteCount) {
    if (_pos == 0) {
      sink.writeBytes(_list);
    } else {
      sink.writeBytes(_list.sublist(_pos, _limit - _pos));
    }
  }
}

abstract class BufferedSource {
  Buffer get buffer;

  int read(Buffer sink, int byteCount);

  void close();

  bool exhausted();

  /// Returns when the buffer contains at least `byteCount` bytes. Throws an
  /// [EOFException] if the source is exhausted before the required bytes
  /// can be read.
  void require(int byteCount);

  /// Returns true when the buffer contains at least `byteCount` bytes,
  /// expanding it as necessary. Returns false if the source is exhausted
  /// before the requested bytes can be read.
  bool request(int byteCount);

  int readByte();

  int readInt8();

  int readUint8();

  int readInt16([Endian endian = Endian.big]);

  int readUint16([Endian endian = Endian.big]);

  int readInt32([Endian endian = Endian.big]);

  int readUint32([Endian endian = Endian.big]);

  int readInt64([Endian endian = Endian.big]);

  int readUint64([Endian endian = Endian.big]);

  int readVarint32();

  int readVarint64();

  double readDouble([Endian endian = Endian.big]);

  double readFloat32([Endian endian = Endian.big]);

  double readFloat64([Endian endian = Endian.big]);

  void skipBytes(int byteCount);

  List<int> readByteArray([int byteCount = 0]);

  /// Removes up to `sink.length` bytes from this and copies them into `sink`.
  /// Returns the number of bytes read, or -1 if this source is exhausted.
  int readInto(List<int> sink, [int offset = 0, int byteCount = 0]);

  /// Removes exactly `sink.length` bytes from this and copies them into
  /// `sink`. Throws an [EOFException] if the requested number of bytes
  /// cannot be read.
  void readFully(List<int> sink, [int byteCount = 0]);

  /// Removes all bytes from this and appends them to `sink`. Returns the
  /// total number of bytes written to `sink` which will be 0 if this is
  /// exhausted.
  int readAll(Sink<List<int>> sink);

  /// Removes `byteCount` bytes from this, decodes them as UTF-8, and returns the string.
  /// ```
  /// Buffer buffer = new Buffer()
  ///     .writeUtf8("Uh uh uh!")
  ///     .writeByte(' ')
  ///     .writeUtf8("You didn't say the magic word!");
  /// assertEquals(40, buffer.size());
  ///
  /// assertEquals("Uh uh uh! You ", buffer.readUtf8(14));
  /// assertEquals(26, buffer.size());
  ///
  /// assertEquals("didn't say the", buffer.readUtf8(14));
  /// assertEquals(12, buffer.size());
  ///
  /// assertEquals(" magic word!", buffer.readUtf8(12));
  /// assertEquals(0, buffer.size());
  /// ```
  ///
  String readUtf8([int byteCount = 0]);

  /// Returns a new `BufferedSource` that can read data from this `BufferedSource` without consuming
  /// it. The returned source becomes invalid once this source is next read or closed.
  ///
  /// For example, we can use `peek()` to lookahead and read the same data multiple times.
  ///
  /// ```
  /// val buffer = Buffer()
  /// buffer.writeUtf8("abcdefghi")
  ///
  /// buffer.readUtf8(3) // returns "abc", buffer contains "defghi"
  ///
  /// val peek = buffer.peek()
  /// peek.readUtf8(3) // returns "def", buffer contains "defghi"
  /// peek.readUtf8(3) // returns "ghi", buffer contains "defghi"
  ///
  /// buffer.readUtf8(3) // returns "def", buffer contains "ghi"
  /// ```
  //
  BufferedSource peek();
}

class _SegmentPool {
  static int MAX_SIZE = 1024 * 1024;

  static _Segment _NEXT = null;
  static int BYTE_COUNT = 0;

  static void recycle(_Segment segment) {
    if (segment == null) return;
    if (segment.shared) return;

    if (BYTE_COUNT + _Segment.SIZE > MAX_SIZE) return;

    BYTE_COUNT += _Segment.SIZE;
    segment._next = _NEXT;
    segment.limit = 0;
    segment.pos = segment.limit;
    _NEXT = segment;
  }

  static _Segment take() {
    final result = _NEXT;
    if (result != null) {
      _NEXT = result._next;
      result._next = null;
      BYTE_COUNT -= _Segment.SIZE;
    }
    return _Segment.create();
  }
}

///
class _Segment extends Object with ListMixin<int> {
  static const int SIZE = 8192;
  static const int SHARE_MINIMUM = 1024;

  Uint8List buf;
  ByteData data;
  int pos = 0;
  int limit = 0;
  bool shared = false;
  bool owner = false;
  _Segment _next = null;
  _Segment _prev = null;

  factory _Segment.create() {
    return _Segment(buf: Uint8List(SIZE), owner: true, shared: false);
  }

  _Segment(
      {this.buf,
      this.pos = 0,
      this.limit = 0,
      this.shared = false,
      this.owner = false})
      : this.data = ByteData.view(buf.buffer);

  @override
  int get length {
    return limit - pos;
  }

  @override
  void set length(int i) =>
      throw new StateError('Attempt to modify fixed-length segment');

  @override
  int operator [](int i) => data.getUint8(i);

  @override
  void operator []=(int i, int e) => data.setUint8(i, e);

  _Segment sharedCopy() {
    shared = true;
    return _Segment(
        buf: buf, pos: pos, limit: limit, shared: false, owner: true);
  }

  _Segment unsharedCopy() => _Segment(
      buf: Uint8List.fromList(buf),
      pos: pos,
      limit: limit,
      shared: false,
      owner: true);

  _Segment pop() {
    final result = (_next != this) ? _next : null;
    _prev?._next = _next;
    _next?._prev = _prev;
    _next = null;
    _prev = null;
    return result;
  }

  _Segment push(_Segment segment) {
    segment._prev = this;
    segment._next = _next;
    _next?._prev = segment;
    _next = segment;
    return segment;
  }

  _Segment split(int byteCount) {
    _Segment prefix;

    // We have two competing performance goals:
    //  - Avoid copying data. We accomplish this by sharing segments.
    //  - Avoid short shared segments. These are bad for performance because they are readonly and
    //    may lead to long chains of short segments.
    // To balance these goals we only share segments when the copy will be large.
    if (byteCount >= SHARE_MINIMUM) {
      prefix = sharedCopy();
    } else {
      prefix = _SegmentPool.take();
      List.copyRange(prefix.buf, 0, buf, pos, pos + byteCount);
//      prefix.buf.replaceRange(0, byteCount, buf.getRange(pos, pos + byteCount));
    }

    prefix.limit = prefix.pos + byteCount;
    pos += byteCount;
    _prev?.push(prefix);
    return prefix;
  }

  void compact() {
    if (_prev == null || _prev.owner) return;

    final byteCount = limit - pos;
    final availableByteCount =
        SIZE - _prev?.limit + (_prev.shared ? 0 : _prev.pos);
    if (byteCount > availableByteCount) return;
    writeTo(_prev, byteCount);
    pop();
    _SegmentPool.recycle(this);
  }

  void writeTo(_Segment sink, int byteCount) {
    if (sink.limit + byteCount > SIZE) {
      if (sink.shared) throw ArgumentError();
      if (sink.limit + byteCount - sink.pos > SIZE) throw ArgumentError();

      int len = sink.limit - sink.pos;
      List.copyRange(sink.buf, 0, sink.buf, sink.pos, sink.pos + len);
//      sink.buf
//          .replaceRange(0, len, sink.buf.getRange(sink.pos, sink.pos + len));
      sink.limit -= sink.pos;
      sink.pos = 0;
    }

    List.copyRange(sink.buf, sink.limit, buf, pos, pos + byteCount);
//    sink.buf.replaceRange(
//        sink.limit, sink.limit + byteCount, buf.getRange(pos, pos + byteCount));
    sink.limit += byteCount;
    pos += byteCount;
  }
}

//class _Page {
//
//}
//
//class RandomAccessBuffer extends Object with ListMixin<int> {
////  final Buffer buffer = Buffer();
//  _Segment _current = null;
//  List<_Segment> _segments = [null, null, null, null];
//  int _size = 0;
//
//  int get length => _size;
//
//  int operator [](int pos) {
//    int segmentIndex = pos & _Segment.SIZE;
//    int offset = _Segment.SIZE * segmentIndex;
//    return 0;
//  }
//}

class FlatBufferBuilder {}

class SegmentedBuffer {
  RABase _buffer;
}

abstract class RABase extends Object with ListMixin<int> {}

class SmallRABuffer {}

/// Multiple pages.
class PagedRABuffer {}

class Buffer extends Object
    with ListMixin<int>
    implements BufferedSink, BufferedSource {
  _Segment _head = null;
  int size = 0;

  static ByteData _CONVERT = ByteData.view(Uint8List(8).buffer);

  static int toInt16(int b0, int b1, Endian endian) {
    _CONVERT..setUint8(0, b0)..setUint8(1, b1);
    return _CONVERT.getInt16(0, endian);
  }

  static int toUint16(int b0, int b1, Endian endian) {
    _CONVERT..setUint8(0, b0)..setUint8(1, b1);
    return _CONVERT.getUint16(0, endian);
  }

  static int toInt32(int b0, int b1, int b2, int b3, Endian endian) {
    _CONVERT
      ..setUint8(0, b0)
      ..setUint8(1, b1)
      ..setUint8(2, b2)
      ..setUint8(3, b3);
    return _CONVERT.getInt32(0, endian);
  }

  static int asInt32(int v, Endian endian) {
    _CONVERT.setInt32(0, v);
    return _CONVERT.getInt32(0, endian);
  }

  static int toUint32(int b0, int b1, int b2, int b3, Endian endian) {
    _CONVERT
      ..setUint8(0, b0)
      ..setUint8(1, b1)
      ..setUint8(2, b2)
      ..setUint8(3, b3);
    return _CONVERT.getUint32(0, endian);
  }

  static int toInt64(int b0, int b1, int b2, int b3, int b4, int b5, int b6,
      int b7, Endian endian) {
    _CONVERT
      ..setUint8(0, b0)
      ..setUint8(1, b1)
      ..setUint8(2, b2)
      ..setUint8(3, b3)
      ..setUint8(4, b4)
      ..setUint8(5, b5)
      ..setUint8(6, b6)
      ..setUint8(7, b7);
    return _CONVERT.getInt64(0, endian);
  }

  static int intoInt64(int lower, int upper, Endian endian) {
    _CONVERT..setInt32(0, lower, endian)..setInt32(4, upper, endian);
    return _CONVERT.getInt64(0, endian);
  }

  static int toUint64(int b0, int b1, int b2, int b3, int b4, int b5, int b6,
      int b7, Endian endian) {
    _CONVERT
      ..setUint8(0, b0)
      ..setUint8(1, b1)
      ..setUint8(2, b2)
      ..setUint8(3, b3)
      ..setUint8(4, b4)
      ..setUint8(5, b5)
      ..setUint8(6, b6)
      ..setUint8(7, b7);
    return _CONVERT.getUint64(0, endian);
  }

  static int intoUint64(int ulower, int uupper, Endian endian) {
    _CONVERT..setUint32(0, ulower, endian)..setUint32(4, uupper, endian);
    return _CONVERT.getUint64(0, endian);
  }

  static double toFloat32(int b0, int b1, int b2, int b3, Endian endian) {
    _CONVERT
      ..setUint8(0, b0)
      ..setUint8(1, b1)
      ..setUint8(2, b2)
      ..setUint8(3, b3);
    return _CONVERT.getFloat32(0, endian);
  }

  static double intoFloat64(double ulower, double uupper, Endian endian) {
    _CONVERT..setFloat32(0, ulower, endian)..setFloat32(4, uupper, endian);
    return _CONVERT.getFloat64(0, endian);
  }

  /**
   * Computes the number of bytes that would be needed to encode a signed variable-length integer
   * of up to 32 bits.
   */
  static int int32Size(int value) {
    if (value >= 0) {
      return varint32Size(value);
    } else {
      // Must sign-extend.
      return 10;
    }
  }

  /**
   * Compute the number of bytes that would be needed to encode a varint.
   * {@code value} is treated as unsigned, so it won't be sign-extended
   * if negative.
   */
  static int varint32Size(int value) {
    if ((value & (_MASK_32 << 7)) == 0) return 1;
    if ((value & (_MASK_32 << 14)) == 0) return 2;
    if ((value & (_MASK_32 << 21)) == 0) return 3;
    if ((value & (_MASK_32 << 28)) == 0) return 4;
    return 5;
  }

  /** Compute the number of bytes that would be needed to encode a varint. */
  static int varint64Size(int value) {
    if ((value & (_MASK_64 << 7)) == 0) return 1;
    if ((value & (_MASK_64 << 14)) == 0) return 2;
    if ((value & (_MASK_64 << 21)) == 0) return 3;
    if ((value & (_MASK_64 << 28)) == 0) return 4;
    if ((value & (_MASK_64 << 35)) == 0) return 5;
    if ((value & (_MASK_64 << 42)) == 0) return 6;
    if ((value & (_MASK_64 << 49)) == 0) return 7;
    if ((value & (_MASK_64 << 56)) == 0) return 8;
    if ((value & (_MASK_64 << 63)) == 0) return 9;
    return 10;
  }

  //////////////////////////////////////////////////////////////////////
  // List<int>
  //////////////////////////////////////////////////////////////////////

  @override
  void add(int element) {
    if (element.bitLength <= 8) {
      writeByte(element);
    } else if (element.bitLength <= 16) {
      writeInt16(element);
    } else if (element.bitLength <= 32) {
      writeInt32(element);
    } else {
      writeInt64(element);
    }
  }

  @override
  int get length => size;

  @override
  void set length(int newSize) {
    final oldSize = buffer.size;
    if (newSize <= oldSize) {
      if (newSize < 0) return;

      // Shrink the buffer by either shrinking segments or removing them.
      var bytesToSubtract = oldSize - newSize;
      while (bytesToSubtract > 0) {
        final tail = buffer._head._prev;
        final tailSize = tail.limit - tail.pos;
        if (tailSize <= bytesToSubtract) {
          buffer._head = tail.pop();
          _SegmentPool.recycle(tail);
          bytesToSubtract -= tailSize;
        } else {
          tail.limit -= bytesToSubtract;
          break;
        }
      }
      // Seek to the end.
//      this._segment = null;
//      this.offset = newSize;
//      this.data = null;
//      this.start = -1;
//      this.end = -1;
    } else if (newSize > oldSize) {
      // Enlarge the buffer by either enlarging segments or adding them.
      var needsToSeek = true;
      var bytesToAdd = newSize - oldSize;
      while (bytesToAdd > 0) {
        final tail = buffer.writableSegment(1);
        final segmentBytesToAdd =
            _minOf(bytesToAdd, _Segment.SIZE - tail.limit);
        tail.limit += segmentBytesToAdd;
        bytesToAdd -= segmentBytesToAdd;

        // If this is the first segment we're adding, seek to it.
        if (needsToSeek) {
//          this._segment = tail;
//          this.offset = oldSize;
//          this.data = tail.buf;
//          this.start = tail.limit - segmentBytesToAdd;
//          this.end = tail.limit;
          needsToSeek = false;
        }
      }
    }

    this.size = newSize;
  }

  int grow(int newSize) {
    if (newSize <= size) return size;

    var oldSize = size;
    // Enlarge the buffer by either enlarging segments or adding them.
    var needsToSeek = true;
    var bytesToAdd = newSize - oldSize;
    while (bytesToAdd > 0) {
      final tail = buffer.writableSegment(1);
      final segmentBytesToAdd = _minOf(bytesToAdd, _Segment.SIZE - tail.limit);
      tail.limit += segmentBytesToAdd;
      bytesToAdd -= segmentBytesToAdd;

      // If this is the first segment we're adding, seek to it.
      if (needsToSeek) {
//          this._segment = tail;
//          this.offset = oldSize;
//          this.data = tail.buf;
//          this.start = tail.limit - segmentBytesToAdd;
//          this.end = tail.limit;
        needsToSeek = false;
      }
    }

    return oldSize;
  }

  int operator [](int pos) {
    if (pos < 0 || pos >= size) throw IndexError(pos, this);
    var s = _head;
    if (s == null) throw IndexError(pos, this);

    if (size - pos < pos) {
      // We're scanning in the back half of this buffer.
      // Find the segment starting at the back.
      var offset = size;
      while (offset > pos) {
        s = s._prev;
        offset -= (s.limit - s.pos);
      }
      return s[pos - offset];
    } else {
      // We're scanning in the front half of this buffer.
      // Find the segment starting at the front.
      var offset = 0;
      while (true) {
        final nextOffset = offset + (s.limit - s.pos);
        if (nextOffset > pos) break;
        s = s._next;
        offset = nextOffset;
      }
      return s[pos - offset];
    }
  }

  void operator []=(int pos, int b) {
    if (pos < 0) throw IndexError(pos, this);
    if (pos >= size) {
      // Grow Buffer?
      throw IndexError(pos, this);
    }
    var s = _head;
    if (s == null) throw IndexError(pos, this);

    if (size - pos < pos) {
      // We're scanning in the back half of this buffer.
      // Find the segment starting at the back.
      var offset = size;
      while (offset > pos) {
        s = s._prev;
        offset -= (s.limit - s.pos);
      }
      s[pos - offset] = b;
    } else {
      // We're scanning in the front half of this buffer.
      // Find the segment starting at the front.
      var offset = 0;
      while (true) {
        final nextOffset = offset + (s.limit - s.pos);
        if (nextOffset > pos) break;
        s = s._next;
        offset = nextOffset;
      }
      s[pos - offset] = b;
    }
  }

  void setInt16(int at, int s) {}

  @override
  List<int> toList({bool growable: true}) {
    return readByteArray();
  }

  @override
  void clear() {
    var s = _head;
    if (s == null) return;
    while (s != null) {
      // Unlink.
      s._prev = null;
      var next = s._next;
      s._next = null;

      // Recycle.
      _SegmentPool.recycle(s);
      s = next;
    }

    // Clear head.
    _head = null;
    // Reset size to 0.
    size = 0;
  }

  @override
  int elementAt(int index) => this[index];

  //////////////////////////////////////////////////////////////////////
  // BufferedSource
  //////////////////////////////////////////////////////////////////////

  @override
  bool request(int byteCount) => size >= byteCount;

  @override
  int read(Buffer sink, int byteCount) {
    if (size == 0) return -1;
    if (byteCount > size) byteCount = size;
    sink.write(this, byteCount);
    return byteCount;
  }

  @override
  int readByte() => readUint8();

  @override
  int readUint8() {
    if (size == 0) throw EOFException();

    final segment = _head;
    var pos = segment.pos;
    final limit = segment.limit;

    final data = segment.data;
    final b = data.getUint8(pos++);
    size -= 1;

    if (pos == limit) {
      _head = segment.pop();
      _SegmentPool.recycle(segment);
    } else {
      segment.pos = pos;
    }

    return b;
  }

  @override
  int readInt8() {
    if (size == 0) throw EOFException();

    final segment = _head;
    var pos = segment.pos;
    final limit = segment.limit;

    final data = segment.data;
    final b = data.getInt8(pos++);
    size -= 1;

    if (pos == limit) {
      _head = segment.pop();
      _SegmentPool.recycle(segment);
    } else {
      segment.pos = pos;
    }

    return b;
  }

  @override
  int readInt16([Endian endian = Endian.big]) => readShort(endian);

  @override
  int readShort([Endian endian = Endian.big]) {
    if (size < 2) throw EOFException();

    final segment = _head;
    var pos = segment.pos;
    final limit = segment.limit;

    if (limit - pos < 2) {
      return toInt16(readByte(), readByte(), endian);
    }

    final data = segment.data;
    final s = data.getInt16(pos, endian);
    pos += 2;
    size -= 2;

    if (pos == limit) {
      _head = segment.pop();
      _SegmentPool.recycle(segment);
    } else {
      segment.pos = pos;
    }

    return s;
  }

  @override
  int readUint16([Endian endian = Endian.big]) {
    if (size < 2) throw EOFException();

    final segment = _head;
    var pos = segment.pos;
    final limit = segment.limit;

    if (limit - pos < 2) {
      return toUint16(readByte(), readByte(), endian);
    }

    final data = segment.data;
    final s = data.getUint16(pos, endian);
    pos += 2;
    size -= 2;

    if (pos == limit) {
      _head = segment.pop();
      _SegmentPool.recycle(segment);
    } else {
      segment.pos = pos;
    }

    return s;
  }

  @override
  int readInt32([Endian endian = Endian.big]) {
    if (size < 4) throw EOFException();

    final segment = _head;
    var pos = segment.pos;
    final limit = segment.limit;

    if (limit - pos < 4) {
      return toInt32(readByte(), readByte(), readByte(), readByte(), endian);
    }

    final data = segment.data;
    final i = data.getInt32(pos, endian);
    pos += 4;
    size -= 4;

    if (pos == limit) {
      _head = segment.pop();
      _SegmentPool.recycle(segment);
    } else {
      segment.pos = pos;
    }

    return i;
  }

  @override
  int readUint32([Endian endian = Endian.big]) {
    if (size < 4) throw EOFException();

    final segment = _head;
    var pos = segment.pos;
    final limit = segment.limit;

    if (limit - pos < 4) {
      return toUint32(readByte(), readByte(), readByte(), readByte(), endian);
    }

    final data = segment.data;
    final i = data.getUint32(pos, endian);
    pos += 4;
    size -= 4;

    if (pos == limit) {
      _head = segment.pop();
      _SegmentPool.recycle(segment);
    } else {
      segment.pos = pos;
    }

    return i;
  }

  @override
  int readInt64([Endian endian = Endian.big]) {
    if (size < 8) throw EOFException();

    final segment = _head;
    var pos = segment.pos;
    final limit = segment.limit;

    if (limit - pos < 8) {
      return intoInt64(readInt32(endian), readInt32(endian), endian);
    }

    final data = segment.data;
    final v = data.getInt64(pos, endian);
    pos += 8;
    size -= 8;

    if (pos == limit) {
      _head = segment.pop();
      _SegmentPool.recycle(segment);
    } else {
      segment.pos = pos;
    }

    return v;
  }

  @override
  int readUint64([Endian endian = Endian.big]) {
    if (size < 8) throw EOFException();

    final segment = _head;
    var pos = segment.pos;
    final limit = segment.limit;

    if (limit - pos < 8) {
      return intoUint64(readUint32(endian), readUint32(endian), endian);
    }

    final data = segment.data;
    final v = data.getUint64(pos, endian);
    pos += 8;
    size -= 8;

    if (pos == limit) {
      _head = segment.pop();
      _SegmentPool.recycle(segment);
    } else {
      segment.pos = pos;
    }

    return v;
  }

  @override
  double readDouble([Endian endian = Endian.big]) {
    return readFloat64(endian);
  }

  @override
  double readFloat32([Endian endian = Endian.big]) {
    if (size < 4) throw EOFException();

    final segment = _head;
    var pos = segment.pos;
    final limit = segment.limit;

    if (limit - pos < 4) {
      return toFloat32(readByte(), readByte(), readByte(), readByte(), endian);
    }

    final data = segment.data;
    final i = data.getFloat32(pos, endian);
    pos += 4;
    size -= 4;

    if (pos == limit) {
      _head = segment.pop();
      _SegmentPool.recycle(segment);
    } else {
      segment.pos = pos;
    }

    return i;
  }

  @override
  double readFloat64([Endian endian = Endian.big]) {
    if (size < 8) throw EOFException();

    final segment = _head;
    var pos = segment.pos;
    final limit = segment.limit;

    if (limit - pos < 8) {
      return intoFloat64(readFloat32(endian), readFloat32(endian), endian);
    }

    final data = segment.data;
    final v = data.getFloat64(pos, endian);
    pos += 8;
    size -= 8;

    if (pos == limit) {
      _head = segment.pop();
      _SegmentPool.recycle(segment);
    } else {
      segment.pos = pos;
    }

    return v;
  }

  @override
  List<int> readByteArray([int byteCount = 0]) {
    if (byteCount == 0) byteCount = size;
    if (size < byteCount) throw EOFException();

    final result = Uint8List(byteCount);
    readFully(result);
    return result;
  }

  String readString(int byteCount, [bool allowMalformed = true]) {
    final result = readByteArray(byteCount);
    return utf8.decode(result, allowMalformed: allowMalformed);
  }

  String readUtf8([int byteCount]) => readString(byteCount);

  @override
  void readFully(List<int> sink, [int byteCount = 0]) {
    if (byteCount == 0 || byteCount > sink.length) byteCount = sink.length;
    var offset = 0;
    while (offset < byteCount) {
      final r = readInto(sink, offset, byteCount - offset);
      if (r == -1) throw EOFException();
      offset += r;
    }
  }

  @override
  int readInto(List<int> sink, [int offset = 0, int byteCount = 0]) {
    final s = _head;
    if (s == null) return -1;
    final toCopy = _minOf(byteCount, s.limit - s.pos);

    List.copyRange(sink, offset, s.buf, s.pos, s.pos + toCopy);

    s.pos += toCopy;
    size -= toCopy;

    if (s.pos == s.limit) {
      _head = s.pop();
      _SegmentPool.recycle(s);
    }

    return toCopy;
  }

  @override
  int readAll(Sink<List<int>> sink) {
    final buf = readByteArray();
    sink.add(buf);
    return buf.length;
  }

  @override
  BufferedSource peek() {
//    return _PeekSource.of(this);
    return this;
  }

  int readVarint32() {
    int tmp = readByte();
    if (tmp >= 0) {
      return tmp;
    }
    int result = tmp & 0x7fffffffffffffff;
    if ((tmp = readByte()) >= 0) {
      result |= tmp << 7;
    } else {
      result |= (tmp & 0x7fffffffffffffff) << 7;
      if ((tmp = readByte()) >= 0) {
        result |= tmp << 14;
      } else {
        result |= (tmp & 0x7fffffffffffffff) << 14;
        if ((tmp = readByte()) >= 0) {
          result |= tmp << 21;
        } else {
          result |= (tmp & 0x7fffffffffffffff) << 21;
          result |= (tmp = readByte()) << 28;
          if (tmp < 0) {
            // Discard upper 32 bits.
            for (int i = 0; i < 5; i++) {
              if (readByte() >= 0) {
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

  /** Reads a raw varint up to 64 bits in length from the stream. */
  int readVarint64() {
    int shift = 0;
    int result = 0;
    while (shift < 64) {
      int b = readByte();
      result |= (b & 0x7fffffffffffffff) << shift;
      if ((b & 0x8000000000000000) == 0) {
        return result;
      }
      shift += 7;
    }
    throw ProtocolException("Malformed varint");
  }

  //////////////////////////////////////////////////////////////////////
  // BufferedSink
  //////////////////////////////////////////////////////////////////////

  @override
  bool exhausted() => size == 0;

  @override
  void require(int byteCount) {
    if (size < byteCount) throw EOFException();
  }

  @override
  int timeout() {
    return -1;
  }

  @override
  void close() {}

  @override
  Buffer get buffer => this;

  @override
  int writeAll(BufferedSource source) {
    var totalBytesRead = 0;
    while (true) {
      final readCount = source.read(this, _Segment.SIZE);
      if (readCount == -1) break;
      totalBytesRead += readCount;
    }
    return totalBytesRead;
  }

  @override
  void emit() {}

  @override
  void emitCompleteSegments() {}

  @override
  void flush() {}

  int completeSegmentByteCount() {
    var result = size;
    if (result == 0 || _head == null) return 0;

    // Omit the tail if it's still writable.
    final tail = _head._prev;
    if (tail == null) return 0;
    if (tail.limit < _Segment.SIZE && tail.owner) {
      result -= (tail.limit - tail.pos);
    }
    return result;
  }

  void copyTo(Buffer out, [int offset = 0, int byteCount = -1]) {
    if (byteCount == -1) byteCount = size - offset;
    if (byteCount == 0) return;

    out.size += byteCount;

    var s = _head;
    while (offset >= s.limit - s.pos) {
      offset -= (s.limit - s.pos);
      s = s._next;
    }

    while (byteCount > 0) {
      final copy = s.sharedCopy();
      copy.pos += offset;
      copy.limit = _minOf(copy.pos + byteCount, copy.limit);
      if (out._head == null) {
        copy._prev = copy;
        copy._next = copy._prev;
        out._head = copy._next;
      } else {
        out._head._prev.push(copy);
      }
      byteCount -= (copy.limit - copy.pos);
      offset = 0;
      s = s._next;
    }
  }

  int seek(int offset) {
    final buffer = this;
    if (offset < -1 || offset > buffer.size) {
      throw IndexError(offset, this);
    }

    if (offset == -1 || offset == buffer.size) {}
    return 0;
  }

  @override
  void skipBytes(int byteCount) {
    while (byteCount > 0) {
      final head = this._head;
      if (head == null) throw EOFException();

      final toSkip = _minOf(byteCount, head.limit - head.pos);
      size -= toSkip;
      byteCount -= toSkip;
      head.pos += toSkip;

      if (head.pos == head.limit) {
        this._head = head.pop();
        _SegmentPool.recycle(head);
      }
    }
  }

  void writeInt8(int b) {
    final tail = writableSegment(1);
    tail.data.setInt8(tail.limit++, b);
    size += 1;
  }

  void writeByte(int b) => writeUint8(b);

  void writeUint8(int b) {
    final tail = writableSegment(1);
    tail.data.setUint8(tail.limit++, b);
    size += 1;
  }

  void writeInt16(int s, [Endian endian = Endian.big]) {
    final tail = writableSegment(2);
    final data = tail.data;
    var limit = tail.limit;
    data.setInt16(limit, s, endian);
    tail.limit += 2;
    size += 2;
  }

  void writeUint16(int s, [Endian endian = Endian.big]) {
    final tail = writableSegment(2);
    final data = tail.data;
    var limit = tail.limit;
    data.setUint16(limit, s, endian);
    tail.limit += 2;
    size += 2;
  }

  void writeInt32(int s, [Endian endian = Endian.big]) {
    final tail = writableSegment(4);
    final data = tail.data;
    var limit = tail.limit;
    data.setInt32(limit, s, endian);
    tail.limit += 4;
    size += 4;
  }

  void writeUint32(int s, [Endian endian = Endian.big]) {
    final tail = writableSegment(4);
    final data = tail.data;
    var limit = tail.limit;
    data.setUint32(limit, s, endian);
    tail.limit += 4;
    size += 4;
  }

  void writeInt64(int s, [Endian endian = Endian.big]) {
    final tail = writableSegment(8);
    final data = tail.data;
    var limit = tail.limit;
    data.setInt64(limit, s, endian);
    tail.limit += 8;
    size += 8;
  }

  void writeUint64(int s, [Endian endian = Endian.big]) {
    final tail = writableSegment(8);
    final data = tail.data;
    var limit = tail.limit;
    data.setUint64(limit, s, endian);
    tail.limit += 8;
    size += 8;
  }

  @override
  void writeDouble(double f, [Endian endian = Endian.big]) {
    final tail = writableSegment(8);
    final data = tail.data;
    var limit = tail.limit;
    data.setFloat64(limit, f, endian);
    tail.limit += 8;
    size += 8;
  }

  @override
  void writeFloat32(double f, [Endian endian = Endian.big]) {
    final tail = writableSegment(4);
    final data = tail.data;
    var limit = tail.limit;
    data.setFloat32(limit, f, endian);
    tail.limit += 4;
    size += 4;
  }

  @override
  void writeFloat64(double f, [Endian endian = Endian.big]) {
    final tail = writableSegment(8);
    final data = tail.data;
    var limit = tail.limit;
    data.setFloat64(limit, f, endian);
    tail.limit += 8;
    size += 8;
  }

  int writeSignedVarint32(int value) {
    if (value >= 0) {
      return writeVarint32(value);
    } else {
      // Must sign-extend.
      return writeVarint64(value);
    }
  }

  int writeVarint32(int value) {
    return writeVarint64(value);
//    value = asInt32(value, Endian.little);
//    final tail = writableSegment(5);
//    final data = tail.data;
//    final before = tail.limit;
//    while ((value & ~0x7fffffffffffffff) != 0) {
//      data.setUint8(
//          tail.limit++, value & 0x7fffffffffffffff | 0x8000000000000000);
//      value >>= 7;
//    }
//    data.setUint8(tail.limit++, value);
//    return tail.limit - before;
  }

  int writeVarint64(int value) {
    final tail = writableSegment(10);
    final data = tail.data;
    final before = tail.limit;
    while ((value & ~0x7fffffffffffffff) != 0) {
      data.setUint8(
          tail.limit++, value & 0x7fffffffffffffff | 0x8000000000000000);
      value >>= 7;
    }
    data.setUint8(tail.limit++, value);
    return tail.limit - before;
  }

  void writeBytes(List<int> source, [int offset = 0, int byteCount = 0]) {
    if (byteCount <= 0) byteCount = source.length;
    if (offset < 0) throw IndexError(offset, this);

    final limit = offset + byteCount;
    while (offset < limit) {
      final tail = writableSegment(1);

      final toCopy = _minOf(limit - offset, _Segment.SIZE - tail.limit);

      List.copyRange(tail.buf, tail.limit, source, offset, offset + toCopy);

      offset += toCopy;
      tail.limit += toCopy;
    }

    size += byteCount;
  }

  int writeUtf8(String string, [int beginIndex = 0, int endIndex = -1]) {
    if (endIndex == -1) endIndex = string.length;
    final encoded = utf8.encode(endIndex > beginIndex
        ? string.substring(beginIndex, endIndex)
        : string);
    writeBytes(encoded);
    return encoded.length;
  }

  _Segment writableSegment(int minimumCapacity) {
    if (_head == null) {
      final result = _SegmentPool.take();
      _head = result;
      result._prev = result;
      result._next = result;
      return result;
    }

    var tail = _head._prev;
    if (tail.limit + minimumCapacity > _Segment.SIZE || !tail.owner) {
      tail = tail.push(_SegmentPool.take());
    }
    return tail;
  }

  void write(Buffer source, int byteCount) {
    // Move bytes from the head of the source buffer to the tail of this buffer
    // while balancing two conflicting goals: don't waste CPU and don't waste
    // memory.
    //
    //
    // Don't waste CPU (ie. don't copy data around).
    //
    // Copying large amounts of data is expensive. Instead, we prefer to
    // reassign entire segments from one buffer to the other.
    //
    //
    // Don't waste memory.
    //
    // As an invariant, adjacent pairs of segments in a buffer should be at
    // least 50% full, except for the head segment and the tail segment.
    //
    // The head segment cannot maintain the invariant because the application is
    // consuming bytes from this segment, decreasing its level.
    //
    // The tail segment cannot maintain the invariant because the application is
    // producing bytes, which may require new nearly-empty tail segments to be
    // appended.
    //
    //
    // Moving segments between buffers
    //
    // When writing one buffer to another, we prefer to reassign entire segments
    // over copying bytes into their most compact form. Suppose we have a buffer
    // with these segment levels [91%, 61%]. If we append a buffer with a
    // single [72%] segment, that yields [91%, 61%, 72%]. No bytes are copied.
    //
    // Or suppose we have a buffer with these segment levels: [100%, 2%], and we
    // want to append it to a buffer with these segment levels [99%, 3%]. This
    // operation will yield the following segments: [100%, 2%, 99%, 3%]. That
    // is, we do not spend time copying bytes around to achieve more efficient
    // memory use like [100%, 100%, 4%].
    //
    // When combining buffers, we will compact adjacent buffers when their
    // combined level doesn't exceed 100%. For example, when we start with
    // [100%, 40%] and append [30%, 80%], the result is [100%, 70%, 80%].
    //
    //
    // Splitting segments
    //
    // Occasionally we write only part of a source buffer to a sink buffer. For
    // example, given a sink [51%, 91%], we may want to write the first 30% of
    // a source [92%, 82%] to it. To simplify, we first transform the source to
    // an equivalent buffer [30%, 62%, 82%] and then move the head segment,
    // yielding sink [51%, 91%, 30%] and source [62%, 82%].
    if (source == this)
      throw ArgumentError("can't write to yourself dude... that's super deep");

    while (byteCount > 0) {
      // Is a prefix of the source's head segment all that we need to move?
      if (byteCount < source._head.limit - source._head.pos) {
        final tail = _head != null ? _head._prev : null;

        if (tail != null &&
            tail.owner &&
            byteCount + tail.limit - (tail.shared ? 0 : tail.pos) <=
                _Segment.SIZE) {
          // Our existing segments are sufficient. Move bytes from source's head to our tail.
          source._head.writeTo(tail, byteCount);
          source.size -= byteCount;
          size += byteCount;
          return;
        } else {
          // We're going to need another segment. Split the source's head
          // segment in two, then move the first of those two to this buffer.
          source._head = source._head.split(byteCount);
        }
      }

      // Remove the source's head segment and append it to our tail.
      final segmentToMove = source._head;
      final movedByteCount = (segmentToMove.limit - segmentToMove.pos);
      source._head = segmentToMove.pop();
      if (_head == null) {
        _head = segmentToMove;
        segmentToMove._prev = segmentToMove;
        segmentToMove._next = segmentToMove._prev;
      } else {
        var tail = _head._prev;
        tail = tail.push(segmentToMove);
        tail.compact();
      }
      source.size -= movedByteCount;
      size += movedByteCount;
      byteCount -= movedByteCount;
    }
  }

  void writeUtf8CodePoint(int codePoint) {
    if (codePoint < 0x80) {
      writeByte(codePoint);
    } else if (codePoint < 0x800) {
      // Emit a 11-bit code point with 2 bytes.
      final tail = writableSegment(2);
      tail.data.setUint8(tail.limit, codePoint >> 6 | 0xc0);
      tail.data.setUint8(tail.limit + 1, codePoint & 0x3f | 0x80);
      tail.limit += 2;
      size += 2;
    } else if (codePoint >= 0xd800 && codePoint <= 0xdfff) {
      writeByte('?'.codeUnitAt(0));
    } else if (codePoint < 0x10000) {
      final tail = writableSegment(3);
      tail.data.setUint8(tail.limit, codePoint >> 12 | 0xe0);
      tail.data.setUint8(tail.limit + 1, codePoint >> 6 & 0x3f | 0x80);
      tail.data.setUint8(tail.limit + 2, codePoint & 0x3f | 0x80);
      tail.limit += 3;
      size += 3;
    } else if (codePoint <= 0x10ffff) {
      final tail = writableSegment(3);
      tail.data.setUint8(tail.limit, codePoint >> 18 | 0xf0);
      tail.data.setUint8(tail.limit + 1, codePoint >> 12 & 0x3f | 0x80);
      tail.data.setUint8(tail.limit + 2, codePoint >> 6 & 0x3f | 0x80);
      tail.data.setUint8(tail.limit + 3, codePoint & 0x3f | 0x80);
      tail.limit += 4;
      size += 4;
    } else {
      throw ArgumentError("unexpected code point: $codePoint");
    }
  }

  /// Invoke `lambda` with the segment and offset at `fromIndex`. Searches
  /// from the front or the back depending on what's closer to `fromIndex`.
  T _seek<T>(int fromIndex, T lambda(Segment, int)) {
    var s = _head;
    if (s == null) return lambda(null, -1);

    if (size - fromIndex < fromIndex) {
      // We're scanning in the back half of this buffer. Find the segment starting at the back.
      var offset = size;
      while (offset > fromIndex) {
        s = s._prev;
        offset -= (s.limit - s.pos);
      }
      return lambda(s, offset);
    } else {
      // We're scanning in the front half of this buffer. Find the segment starting at the front.
      var offset = 0;
      while (true) {
        final nextOffset = offset + (s.limit - s.pos);
        if (nextOffset > fromIndex) break;
        s = s._next;
        offset = nextOffset;
      }
      return lambda(s, offset);
    }
  }

  int indexOfByte(int b, [int fromIndex = 0, int toIndex = 0]) {
    if (toIndex == 0 || toIndex > size) toIndex = size;
    if (toIndex <= fromIndex) return -1;

    return _seek(fromIndex, (s, offset) {
      if (s == null) return -1;

      // Scan through the segments, searching for b.
      while (offset < toIndex) {
        final data = s.data;
        final limit = _minOf(s.limit, s.pos + toIndex - offset);
        var pos = (s.pos + fromIndex - offset);
        while (pos < limit) {
          if (data[pos] == b) {
            return pos - s.pos + offset;
          }
          pos++;
        }

        // Not in this segment. Try the next one.
        offset += (s.limit - s.pos);
        fromIndex = offset;
        s = s._next;
      }

      return -1;
    });
  }

  bool rangeEquals(
      _Segment s, int pos, List<int> target, int offset, int bytesSize) {
    for (var i = 0; i < bytesSize; i++) {
      if (s.buf[pos + i] != target[offset + i]) return false;
    }
    return true;
  }

  int indexOfBytes(List<int> bytes, int fromIndex) {
    if (bytes.length == 0) return -1;
    if (fromIndex < 0) return -1;

    return _seek(fromIndex, (s, offset) {
      if (s == null) return -1;

      final targetByteArray = bytes;
      final b0 = targetByteArray[0];
      final bytesSize = bytes.length;
      final resultLimit = size - bytesSize - 1;
      while (offset < resultLimit) {
        // Scan through the current segment.
        final data = s.data;
        final segmentLimit = _minOf(s.limit, s.pos + resultLimit - offset);
        for (var pos = (s.pos + fromIndex - offset);
            pos < segmentLimit;
            pos++) {
          if (data[pos] == b0 &&
              rangeEquals(s, pos + 1, targetByteArray, 1, bytesSize)) {
            return pos - s.pos + offset;
          }
        }

        // Not in this segment. Try the next one.
        offset += (s.limit - s.pos);
        fromIndex = offset;
        s = s._next;
      }

      return -1;
    });
  }

  _width(int v) {
    if (v < 100000000) if (v < 10000) if (v < 100) if (v < 10)
      return 1;
    else
      return 2;
    else if (v < 1000)
      return 3;
    else
      return 4;
    else if (v < 1000000) if (v < 100000)
      return 5;
    else
      return 6;
    else if (v < 10000000)
      return 7;
    else
      return 8;
    else if (v < 1000000000000) if (v < 10000000000) if (v < 1000000000)
      return 9;
    else
      return 10;
    else if (v < 100000000000)
      return 11;
    else
      return 12;
    else if (v < 1000000000000000) if (v < 10000000000000)
      return 13;
    else if (v < 100000000000000)
      return 14;
    else
      return 15;
    else if (v < 100000000000000000) if (v < 10000000000000000)
      return 16;
    else
      return 17;
    else if (v < 1000000000000000000)
      return 18;
    else
      return 19;
  }

  @override
  String toString() {
    return super.toString();
  }

  @override
  bool operator ==(other) {
    if (this == other) return true;
    if (other is! Buffer) return false;
    if (size != other.size) return false;
    if (size == 0) return true;

    var sa = this._head;
    var sb = other._head;
    var posA = sa.pos;
    var posB = sb.pos;

    var pos = 0;
    int count;
    while (pos < size) {
      count = _minOf(sa.limit - posA, sb.limit - posB);

      for (var i = 0; i < count; i++) {
        if (sa.buf[posA++] != sb.buf[posB++]) return false;
      }

      if (posA == sa.limit) {
        sa = sa._next;
        posA = sa.pos;
      }

      if (posB == sb.limit) {
        sb = sb._next;
        posB = sb.pos;
      }
      pos += count;
    }
    return true;
  }

  @override
  int get hashCode {
    var s = _head;
    if (s == null) return 0;
    var result = 1;
    do {
      var pos = s.pos;
      final limit = s.limit;
      while (pos < limit) {
        result = 31 * result + s.buf[pos];
        pos++;
      }
      s = s._next;
    } while (s != _head);
    return result;
  }

  /// Returns a deep copy of this buffer.
  Buffer clone() {
    final result = Buffer();
    if (size == 0) return result;

    result._head = _head.sharedCopy();
    result._head._prev = result._head;
    result._head._next = result._head._prev;
    var s = _head._next;
    while (s != _head) {
      result._head._prev.push(s.sharedCopy());
      s = s._next;
    }
    result.size = size;
    return result;
  }

  /** Returns an immutable copy of the first `byteCount` bytes of this buffer as a byte string. */
//  List<int> snapshot(int byteCount) {
//  return if (byteCount == 0) ByteString.EMPTY else SegmentedByteString.of(this, byteCount)
//  }

  UnsafeCursor readUnsafe([UnsafeCursor unsafeCursor = null]) {
    if (unsafeCursor == null) unsafeCursor = UnsafeCursor();
    if (unsafeCursor.buffer != null)
      throw StateError("already attached to a buffer");

    unsafeCursor.buffer = this;
    unsafeCursor.readWrite = false;
    return unsafeCursor;
  }

  UnsafeCursor readAndWriteUnsafe([UnsafeCursor unsafeCursor = null]) {
    if (unsafeCursor == null) unsafeCursor = UnsafeCursor();
    if (unsafeCursor.buffer != null)
      throw StateError("already attached to a buffer");

    unsafeCursor.buffer = this;
    unsafeCursor.readWrite = true;
    return unsafeCursor;
  }
}

/// A [Source] which peeks into an upstream [BufferedSource] and allows reading and expanding of the
/// buffered data without consuming it. Does this by requesting additional data from the upstream
/// source if needed and copying out of the internal buffer of the upstream source if possible.
///
/// This source also maintains a snapshot of the starting location of the upstream buffer which it
/// validates against on every read. If the upstream buffer is read from, this source will become
/// invalid and throw [StateError] on any future reads.
class _PeekSource {
  final BufferedSource upstream;
  final Buffer buffer;
  _Segment _expectedSegment;
  int _expectedPos;

  bool _closed = false;
  int pos = 0;

  factory _PeekSource.of(BufferedSource upstream) => _PeekSource._(upstream,
      upstream.buffer, upstream.buffer._head, upstream.buffer._head?.pos ?? -1);

  _PeekSource._(
      this.upstream, this.buffer, this._expectedSegment, this._expectedPos);

  int read(Buffer sink, int byteCount) {
    if (_closed) throw StateError("closed");

    // Source becomes invalid if there is an expected Segment and it and
    // the expected position do not match the current head and head position
    // of the upstream buffer.
    if (!(_expectedSegment == null ||
        _expectedSegment == buffer._head && _expectedPos == buffer._head.pos)) {
      throw StateError(
          "Peek source is invalid because upstream source was used");
    }

    upstream.request(pos + byteCount);
    if (_expectedSegment == null && buffer._head != null) {
      // Only once the buffer actually holds data should an expected Segment
      // and position be recorded. This allows reads from the peek source to
      // repeatedly return -1 and for data to be added later. Unit tests depend
      // on this behavior.
      _expectedSegment = buffer._head;
      _expectedPos = buffer._head.pos;
    }

    final toCopy = _minOf(byteCount, buffer.size - pos);
    if (toCopy <= 0) {
      return -1;
    }

    buffer.copyTo(sink, pos, toCopy);
    pos += toCopy;
    return toCopy;
  }

  void close() {
    _closed = true;
  }
}

/**
 * A handle to the underlying data in a buffer. This handle is unsafe because it does not enforce
 * its own invariants. Instead, it assumes a careful user who has studied Okio's implementation
 * details and their consequences.
 *
 * Buffer Internals
 * ----------------
 *
 * Most code should use `Buffer` as a black box: a class that holds 0 or more bytes of
 * data with efficient APIs to append data to the end and to consume data from the front. Usually
 * this is also the most efficient way to use buffers because it allows Okio to employ several
 * optimizations, including:
 *
 *
 *  * **Fast Allocation:** Buffers use a shared pool of memory that is not zero-filled before use.
 *  * **Fast Resize:** A buffer's capacity can change without copying its contents.
 *  * **Fast Move:** Memory ownership can be reassigned from one buffer to another.
 *  * **Fast Copy:** Multiple buffers can share the same underlying memory.
 *  * **Fast Encoding and Decoding:** Common operations like UTF-8 encoding and decimal decoding
 *    do not require intermediate objects to be allocated.
 *
 * These optimizations all leverage the way Okio stores data internally. Okio Buffers are
 * implemented using a doubly-linked list of segments. Each segment is a contiguous range within a
 * 8 KiB `ByteArray`. Each segment has two indexes, `start`, the offset of the first byte of the
 * array containing application data, and `end`, the offset of the first byte beyond `start` whose
 * data is undefined.
 *
 * New buffers are empty and have no segments:
 *
 * ```
 *   val buffer = Buffer()
 * ```
 *
 * We append 7 bytes of data to the end of our empty buffer. Internally, the buffer allocates a
 * segment and writes its new data there. The lone segment has an 8 KiB byte array but only 7
 * bytes of data:
 *
 * ```
 * buffer.writeUtf8("sealion")
 *
 * // [ 's', 'e', 'a', 'l', 'i', 'o', 'n', '?', '?', '?', ...]
 * //    ^                                  ^
 * // start = 0                          end = 7
 * ```
 *
 * When we read 4 bytes of data from the buffer, it finds its first segment and returns that data
 * to us. As bytes are read the data is consumed. The segment tracks this by adjusting its
 * internal indices.
 *
 * ```
 * buffer.readUtf8(4) // "seal"
 *
 * // [ 's', 'e', 'a', 'l', 'i', 'o', 'n', '?', '?', '?', ...]
 * //                        ^              ^
 * //                     start = 4      end = 7
 * ```
 *
 * As we write data into a buffer we fill up its internal segments. When a write doesn't fit into
 * a buffer's last segment, additional segments are allocated and appended to the linked list of
 * segments. Each segment has its own start and end indexes tracking where the user's data begins
 * and ends.
 *
 * ```
 * val xoxo = new Buffer()
 * xoxo.writeUtf8("xo".repeat(5_000))
 *
 * // [ 'x', 'o', 'x', 'o', 'x', 'o', 'x', 'o', ..., 'x', 'o', 'x', 'o']
 * //    ^                                                               ^
 * // start = 0                                                      end = 8192
 * //
 * // [ 'x', 'o', 'x', 'o', ..., 'x', 'o', 'x', 'o', '?', '?', '?', ...]
 * //    ^                                            ^
 * // start = 0                                   end = 1808
 * ```
 *
 * The start index is always **inclusive** and the end index is always **exclusive**. The data
 * preceding the start index is undefined, and the data at and following the end index is
 * undefined.
 *
 * After the last byte of a segment has been read, that segment may be returned to an internal
 * segment pool. In addition to reducing the need to do garbage collection, segment pooling also
 * saves the JVM from needing to zero-fill byte arrays. Okio doesn't need to zero-fill its arrays
 * because it always writes memory before it reads it. But if you look at a segment in a debugger
 * you may see its effects. In this example, one of the "xoxo" segments above is reused in an
 * unrelated buffer:
 *
 * ```
 * val abc = new Buffer()
 * abc.writeUtf8("abc")
 *
 * // [ 'a', 'b', 'c', 'o', 'x', 'o', 'x', 'o', ...]
 * //    ^              ^
 * // start = 0     end = 3
 * ```
 *
 * There is an optimization in `Buffer.clone()` and other methods that allows two segments to
 * share the same underlying byte array. Clones can't write to the shared byte array; instead they
 * allocate a new (private) segment early.
 *
 * ```
 * val nana = new Buffer()
 * nana.writeUtf8("na".repeat(2_500))
 * nana.readUtf8(2) // "na"
 *
 * // [ 'n', 'a', 'n', 'a', ..., 'n', 'a', 'n', 'a', '?', '?', '?', ...]
 * //              ^                                  ^
 * //           start = 0                         end = 5000
 *
 * nana2 = nana.clone()
 * nana2.writeUtf8("batman")
 *
 * // [ 'n', 'a', 'n', 'a', ..., 'n', 'a', 'n', 'a', '?', '?', '?', ...]
 * //              ^                                  ^
 * //           start = 0                         end = 5000
 * //
 * // [ 'b', 'a', 't', 'm', 'a', 'n', '?', '?', '?', ...]
 * //    ^                             ^
 * //  start = 0                    end = 7
 * ```
 *
 * Segments are not shared when the shared region is small (ie. less than 1 KiB). This is intended
 * to prevent fragmentation in sharing-heavy use cases.
 *
 * Unsafe Cursor API
 * -----------------
 *
 * This class exposes privileged access to the internal byte arrays of a buffer. A cursor either
 * references the data of a single segment, it is before the first segment (`offset == -1`), or it
 * is after the last segment (`offset == buffer.size`).
 *
 * Call [UnsafeCursor.seek] to move the cursor to the segment that contains a specified offset.
 * After seeking, [UnsafeCursor.data] references the segment's internal byte array,
 * [UnsafeCursor.start] is the segment's start and [UnsafeCursor.end] is its end.
 *
 *
 * Call [UnsafeCursor.next] to advance the cursor to the next segment. This returns -1 if there
 * are no further segments in the buffer.
 *
 *
 * Use [Buffer.readUnsafe] to create a cursor to read buffer data and [Buffer.readAndWriteUnsafe]
 * to create a cursor to read and write buffer data. In either case, always call
 * [UnsafeCursor.close] when done with a cursor. This is convenient with Kotlin's
 * [use] extension function. In this example we read all of the bytes in a buffer into a byte
 * array:
 *
 * ```
 * val bufferBytes = ByteArray(buffer.size.toInt())
 *
 * buffer.readUnsafe().use { cursor ->
 *   while (cursor.next() != -1) {
 *     System.arraycopy(cursor.data, cursor.start,
 *         bufferBytes, cursor.offset.toInt(), cursor.end - cursor.start);
 *   }
 * }
 * ```
 *
 * Change the capacity of a buffer with [.resizeBuffer]. This is only permitted for
 * read+write cursors. The buffer's size always changes from the end: shrinking it removes bytes
 * from the end; growing it adds capacity to the end.
 *
 * Warnings
 * --------
 *
 * Most application developers should avoid this API. Those that must use this API should
 * respect these warnings.
 *
 * **Don't mutate a cursor.** This class has public, non-final fields because that is convenient
 * for low-level I/O frameworks. Never assign values to these fields; instead use the cursor API
 * to adjust these.
 *
 * **Never mutate `data` unless you have read+write access.** You are on the honor system to never
 * write the buffer in read-only mode. Read-only mode may be more efficient than read+write mode
 * because it does not need to make private copies of shared segments.
 *
 * **Only access data in `[start..end)`.** Other data in the byte array is undefined! It may
 * contain private or sensitive data from other parts of your process.
 *
 * **Always fill the new capacity when you grow a buffer.** New capacity is not zero-filled and
 * may contain data from other parts of your process. Avoid leaking this information by always
 * writing something to the newly-allocated capacity. Do not assume that new capacity will be
 * filled with `0`; it will not be.
 *
 * **Do not access a buffer while is being accessed by a cursor.** Even simple read-only
 * operations like [Buffer.clone] are unsafe because they mark segments as shared.
 *
 * **Do not hard-code the segment size in your application.** It is possible that segment sizes
 * will change with advances in hardware. Future versions of Okio may even have heterogeneous
 * segment sizes.
 *
 * These warnings are intended to help you to use this API safely. It's here for developers
 * that need absolutely the most throughput. Since that's you, here's one final performance tip.
 * You can reuse instances of this class if you like. Use the overloads of [Buffer.readUnsafe] and
 * [Buffer.readAndWriteUnsafe] that take a cursor and close it after use.
 */
class UnsafeCursor {
  Buffer buffer = null;
  bool readWrite = false;
  _Segment _segment = null;
  int offset = -1;
  Uint8List data = null;
  int start = -1;
  int end = -1;

  UnsafeCursor();

  int next() {
    if (offset == -1) {
      return seek(0);
    } else {
      return seek(offset + (end - start));
    }
  }

  int seek(int offset) {
    if (buffer == null) {
      return -1;
    }

    if (offset < -1 || offset > buffer.size) {
      throw IndexError(offset, buffer);
    }

    if (offset == -1 || offset == buffer.size) {
      this._segment = null;
      this.offset = offset;
      this.data = null;
      this.start = -1;
      this.end = -1;
      return -1;
    }

    // Navigate to the segment that contains `offset`.
    // Start from our current segment if possible.
    var min = 0;
    var max = buffer.size;
    var head = buffer._head;
    var tail = buffer._head;
    if (this._segment != null) {
      final segmentOffset = this.offset - (this.start - this._segment.pos);
      if (segmentOffset > offset) {
        // Set the cursor segment to be the 'end'
        max = segmentOffset;
        tail = this._segment;
      } else {
        // Set the cursor segment to be the 'beginning'
        min = segmentOffset;
        head = this._segment;
      }
    }

    _Segment next;
    int nextOffset;
    if (max - offset > offset - min) {
      // Start at the 'beginning' and search forwards
      next = head;
      nextOffset = min;
      while (offset >= nextOffset + (next.limit - next.pos)) {
        nextOffset += (next.limit - next.pos);
        next = next._next;
      }
    } else {
      // Start at the 'end' and search backwards
      next = tail;
      nextOffset = max;
      while (nextOffset > offset) {
        next = next._prev;
        nextOffset -= (next.limit - next.pos);
      }
    }

    // If we're going to write and our segment is shared,
    // swap it for a read-write one.
    if (readWrite && next.shared) {
      final unsharedNext = next.unsharedCopy();
      if (buffer._head == next) {
        buffer._head = unsharedNext;
      }
      next = next.push(unsharedNext);
      next._prev.pop();
    }

    // Update this cursor to the requested offset within the found segment.
    this._segment = next;
    this.offset = offset;
    this.data = next.buf;
    this.start = next.pos + (offset - nextOffset);
    this.end = next.limit;
    return end - start;
  }

  /// Change the size of the buffer so that it equals `newSize` by either adding new
  /// capacity at the end or truncating the buffer at the end. Newly added capacity may span
  /// multiple segments.
  ///
  /// As a side-effect this cursor will [seek][UnsafeCursor.seek]. If the buffer is being enlarged
  /// it will move [UnsafeCursor.offset] to the first byte of newly-added capacity. This is the
  /// size of the buffer prior to the `resizeBuffer()` call. If the buffer is being shrunk it will move
  /// [UnsafeCursor.offset] to the end of the buffer.
  ///
  /// Warning: it is the caller’s responsibility to write new data to every byte of the
  /// newly-allocated capacity. Failure to do so may cause serious security problems as the data
  /// in the returned buffers is not zero filled. Buffers may contain dirty pooled segments that
  /// hold very sensitive data from other parts of the current process.
  ///
  /// @return the previous size of the buffer.
  int resizeBuffer(int newSize) {
    if (buffer == null) throw StateError("not attached to a buffer");
    if (!readWrite)
      throw ArgumentError(
          "resizeBuffer() only permitted to read/write4 buffers");

    final oldSize = buffer.size;
    if (newSize <= oldSize) {
      if (newSize < 0) return -1;

      // Shrink the buffer by either shrinking segments or removing them.
      var bytesToSubtract = oldSize - newSize;
      while (bytesToSubtract > 0) {
        final tail = buffer._head._prev;
        final tailSize = tail.limit - tail.pos;
        if (tailSize <= bytesToSubtract) {
          buffer._head = tail.pop();
          _SegmentPool.recycle(tail);
          bytesToSubtract -= tailSize;
        } else {
          tail.limit -= bytesToSubtract;
          break;
        }
      }
      // Seek to the end.
      this._segment = null;
      this.offset = newSize;
      this.data = null;
      this.start = -1;
      this.end = -1;
    } else if (newSize > oldSize) {
      // Enlarge the buffer by either enlarging segments or adding them.
      var needsToSeek = true;
      var bytesToAdd = newSize - oldSize;
      while (bytesToAdd > 0) {
        final tail = buffer.writableSegment(1);
        final segmentBytesToAdd =
            _minOf(bytesToAdd, _Segment.SIZE - tail.limit);
        tail.limit += segmentBytesToAdd;
        bytesToAdd -= segmentBytesToAdd;

        // If this is the first segment we're adding, seek to it.
        if (needsToSeek) {
          this._segment = tail;
          this.offset = oldSize;
          this.data = tail.buf;
          this.start = tail.limit - segmentBytesToAdd;
          this.end = tail.limit;
          needsToSeek = false;
        }
      }
    }

    buffer.size = newSize;
    return oldSize;
  }

  /// Grow the buffer by adding a ***contiguous range*** of capacity in a single segment. This adds
  /// at least `minByteCount` bytes but may add up to a full segment of additional capacity.
  ///
  /// As a side-effect this cursor will [seek][UnsafeCursor.seek]. It will move
  /// [offset][UnsafeCursor.offset] to the first byte of newly-added capacity. This is the size of
  /// the buffer prior to the `expandBuffer()` call.
  ///
  /// If `minByteCount` bytes are available in the buffer's current tail segment that will
  /// be used; otherwise another segment will be allocated and appended. In either case this
  /// returns the number of bytes of capacity added to this buffer.
  ///
  /// Warning: it is the caller’s responsibility to either write new data to every byte of the
  /// newly-allocated capacity, or to [shrink][UnsafeCursor.resizeBuffer] the buffer to the data
  /// written. Failure to do so may cause serious security problems as the data in the returned
  /// buffers is not zero filled. Buffers may contain dirty pooled segments that hold very
  /// sensitive data from other parts of the current process.
  ///
  /// @param minByteCount the size of the contiguous capacity. Must be positive and not greater
  /// than the capacity size of a single segment (8 KiB).
  /// @return the number of bytes expanded by. Not less than `minByteCount`.
  int expandBuffer(int minByteCount) {
    if (minByteCount <= 0)
      throw ArgumentError("minByteCount <= 0: $minByteCount");
    if (minByteCount > _Segment.SIZE)
      throw ArgumentError("minByteCount > Segment.SIZE: $minByteCount");

    if (buffer == null) throw ArgumentError("not attached to a buffer");
    if (!readWrite)
      throw ArgumentError(
          "resizeBuffer() only permitted to read/write4 buffers");

    final oldSize = buffer.size;
    final tail = buffer.writableSegment(minByteCount);
    final result = _Segment.SIZE - tail.limit;
    tail.limit = _Segment.SIZE;
    buffer.size = oldSize + result;

    // Seek to the old size.
    this._segment = tail;
    this.offset = oldSize;
    this.data = tail.buf;
    this.start = _Segment.SIZE - result;
    this.end = _Segment.SIZE;

    return result;
  }

  void close() {
    if (buffer == null) return;

    buffer = null;
    _segment = null;
    offset = -1;
    data = null;
    start = -1;
    end = -1;
  }
}

int _minOf(int first, int second) {
  return first < second ? first : second;
}
