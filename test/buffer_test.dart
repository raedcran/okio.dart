import 'package:test/test.dart';
import 'package:okio/okio.dart';

import 'package:okio/protobuf.dart';

void assertEquals(dynamic left, dynamic right) {
  expect(left == right, isTrue);
}

String repeat(String value, int count) {
  final output = StringBuffer();
  for (var i = 0; i < count; i++) {
    output.write(value);
  }
  return output.toString();
}

void main() {
  group('A group of tests', () {
    setUp(() {

    });

//    final buffer = Buffer();
//    final writer = ProtoWriter(sink: buffer);
//    final reader = ProtoReader(source: buffer);

    test('randomAccess', () {
      final buffer = Buffer();
      buffer.length = 10000;
      buffer[0] = 5;
      buffer[SEGMENT_SIZE] = 2;
      buffer[SEGMENT_SIZE + 1] = 3;
      assertEquals(buffer.size, 10000);
    });

    test('readAndWriteUtf8', () {
      final buffer = Buffer();
      buffer.writeUtf8("ab");

      assertEquals(2, buffer.size);
      buffer.writeUtf8("cdef");
      assertEquals(6, buffer.size);
      assertEquals("abcd", buffer.readUtf8(4));
      assertEquals(2, buffer.size);
      assertEquals("ef", buffer.readUtf8(2));
      assertEquals(0, buffer.size);
      try {
        buffer.readUtf8(1);
      } catch (e, stackTrace) {
        expect(e is EOFException, isTrue);
      }
    });

    test('completeSegmentByteCountOnEmptyBuffer', () {
      final buffer = Buffer();
      assertEquals(0, buffer.completeSegmentByteCount());
    });

    test('completeSegmentByteCountOnBufferWithFullSegments', () {
      final buffer = Buffer();
      buffer.writeUtf8(repeat('a', SEGMENT_SIZE * 4));
      assertEquals(SEGMENT_SIZE * 4, buffer.completeSegmentByteCount());
    });

    test('completeSegmentByteCountOnBufferWithIncompleteTailSegment', () {
      final buffer = Buffer();
      buffer.writeUtf8(repeat('a', SEGMENT_SIZE * 4 - 10));
      assertEquals(SEGMENT_SIZE * 3, buffer.completeSegmentByteCount());
    });

    test('multipleSegmentBuffers', () {
      Buffer buffer = new Buffer();
      buffer.writeUtf8(repeat('a', 1000));
      buffer.writeUtf8(repeat('b', 2500));
      buffer.writeUtf8(repeat('c', 5000));
      buffer.writeUtf8(repeat('d', 10000));
      buffer.writeUtf8(repeat('e', 25000));
      buffer.writeUtf8(repeat('f', 50000));

      assertEquals(repeat('a', 999), buffer.readUtf8(999)); // a...a
      assertEquals("a" + repeat('b', 2500) + "c", buffer.readUtf8(2502)); // ab...bc
      assertEquals(repeat('c', 4998), buffer.readUtf8(4998)); // c...c
      assertEquals("c" + repeat('d', 10000) + "e", buffer.readUtf8(10002)); // cd...de
      assertEquals(repeat('e', 24998), buffer.readUtf8(24998)); // e...e
      assertEquals("e" + repeat('f', 50000), buffer.readUtf8(50001)); // ef...f
      assertEquals(0, buffer.size);
      buffer.writeUtf8(repeat('a', 1000));
      assertEquals(repeat('a', 999), buffer.readUtf8(999)); // a...a
      assertEquals(buffer.readUtf8(1), 'a');
      assertEquals(0, buffer.size);
    });
  });
}
