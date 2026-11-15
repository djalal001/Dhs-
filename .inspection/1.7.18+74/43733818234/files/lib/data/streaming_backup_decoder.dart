import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

typedef BackupImagePump =
    Future<void> Function(void Function(String chunk) addChunk);

typedef BackupImageWriter =
    Future<void> Function(String sourcePath, BackupImagePump pump);

/// Reads the app's existing JSON backup format while streaming each base64
/// image directly to a consumer. Only the small metadata fields are decoded
/// into memory; image payload strings are never accumulated as one value.
Future<Map<String, dynamic>> decodeBackupStream(
  Stream<List<int>> source, {
  required BackupImageWriter writeImage,
  void Function(int bytesRead)? onProgress,
}) async {
  final reader = _JsonByteReader(source, onProgress);
  try {
    await reader.skipWhitespace();
    await reader.expect(0x7b); // {
    final result = <String, dynamic>{};
    await reader.skipWhitespace();
    if (await reader.peek() == 0x7d) {
      await reader.read();
      return result;
    }

    while (true) {
      await reader.skipWhitespace();
      final key = await reader.readString();
      await reader.skipWhitespace();
      await reader.expect(0x3a); // :
      await reader.skipWhitespace();
      if (key == 'imagesBase64') {
        result[key] = await _readImageMap(reader, writeImage);
      } else {
        final raw = await reader.readRawValue();
        result[key] = jsonDecode(utf8.decode(raw));
      }
      await reader.skipWhitespace();
      final separator = await reader.read();
      if (separator == 0x7d) break; // }
      if (separator != 0x2c) {
        throw const FormatException('Invalid JSON backup object.');
      }
    }
    await reader.skipWhitespace();
    if (await reader.peek() != null) {
      throw const FormatException('Unexpected data after the backup.');
    }
    reader.reportFinalProgress();
    return result;
  } finally {
    await reader.close();
  }
}

Future<Map<String, bool>> _readImageMap(
  _JsonByteReader reader,
  BackupImageWriter writeImage,
) async {
  await reader.expect(0x7b); // {
  final imagePaths = <String, bool>{};
  await reader.skipWhitespace();
  if (await reader.peek() == 0x7d) {
    await reader.read();
    return imagePaths;
  }
  while (true) {
    await reader.skipWhitespace();
    final sourcePath = await reader.readString();
    if (imagePaths.containsKey(sourcePath)) {
      throw const FormatException('Duplicate image path in backup.');
    }
    await reader.skipWhitespace();
    await reader.expect(0x3a); // :
    await reader.skipWhitespace();
    await reader.expect(0x22); // opening quote of base64 string
    await writeImage(sourcePath, (addChunk) async {
      await reader.readBase64String(addChunk, sourcePath);
    });
    imagePaths[sourcePath] = true;
    await reader.skipWhitespace();
    final separator = await reader.read();
    if (separator == 0x7d) break; // }
    if (separator != 0x2c) {
      throw const FormatException('Invalid images map in backup.');
    }
  }
  return imagePaths;
}

int _hexValue(int value) {
  if (value >= 0x30 && value <= 0x39) return value - 0x30;
  if (value >= 0x41 && value <= 0x46) return value - 0x41 + 10;
  if (value >= 0x61 && value <= 0x66) return value - 0x61 + 10;
  return -1;
}

class _JsonByteReader {
  _JsonByteReader(Stream<List<int>> source, this._onProgress)
    : _iterator = StreamIterator<List<int>>(source);

  final StreamIterator<List<int>> _iterator;
  final void Function(int bytesRead)? _onProgress;
  List<int> _chunk = const [];
  int _offset = 0;
  int _bytesRead = 0;
  int _lastProgress = 0;

  Future<int?> _availableByte() async {
    while (_offset >= _chunk.length) {
      if (!await _iterator.moveNext()) return null;
      _chunk = _iterator.current;
      _offset = 0;
    }
    return _chunk[_offset];
  }

  Future<int?> peek() => _availableByte();

  Future<int?> read() async {
    final byte = await _availableByte();
    if (byte == null) return null;
    _offset++;
    _bytesRead++;
    _reportProgressIfNeeded();
    return byte;
  }

  Future<void> readBase64String(
    void Function(String chunk) addChunk,
    String sourcePath,
  ) async {
    while (true) {
      if (_offset >= _chunk.length) {
        if (!await _iterator.moveNext()) {
          throw const FormatException('Truncated image data in backup.');
        }
        _chunk = _iterator.current;
        _offset = 0;
        if (_chunk.isEmpty) continue;
      }

      final start = _offset;
      var cursor = start;
      while (cursor < _chunk.length) {
        final value = _chunk[cursor];
        if (value == 0x22 || value == 0x5c || value < 0x20) break;
        cursor++;
      }
      if (cursor > start) {
        addChunk(String.fromCharCodes(_chunk, start, cursor));
        _bytesRead += cursor - start;
        _offset = cursor;
        _reportProgressIfNeeded();
      }
      if (_offset >= _chunk.length) continue;

      final special = _chunk[_offset++];
      _bytesRead++;
      _reportProgressIfNeeded();
      if (special == 0x22) return; // closing quote
      if (special < 0x20) {
        throw FormatException(
          'Invalid encoded image data byte $special in $sourcePath.',
        );
      }

      final int? escaped;
      if (_offset < _chunk.length) {
        escaped = _chunk[_offset++];
        _bytesRead++;
        _reportProgressIfNeeded();
      } else {
        escaped = await read();
      }
      if (escaped == null) {
        throw const FormatException('Truncated escape in image data.');
      }
      var decoded = escaped;
      if (escaped == 0x75) {
        decoded = 0;
        if (_chunk.length - _offset >= 4) {
          for (var digit = 0; digit < 4; digit++) {
            final value = _hexValue(_chunk[_offset + digit]);
            if (value < 0) {
              throw const FormatException('Invalid Unicode escape.');
            }
            decoded = (decoded << 4) | value;
          }
          _offset += 4;
          _bytesRead += 4;
          _reportProgressIfNeeded();
        } else {
          for (var digit = 0; digit < 4; digit++) {
            final hex = await read();
            if (hex == null) {
              throw const FormatException('Truncated Unicode escape.');
            }
            final value = _hexValue(hex);
            if (value < 0) {
              throw const FormatException('Invalid Unicode escape.');
            }
            decoded = (decoded << 4) | value;
          }
        }
        if (decoded > 0x7f) {
          throw const FormatException('Non-ASCII character in base64.');
        }
      } else if (escaped != 0x22 && escaped != 0x5c && escaped != 0x2f) {
        throw const FormatException('Invalid escape in image data.');
      }
      if (decoded < 0x20) {
        throw const FormatException('Control character in image data.');
      }
      addChunk(String.fromCharCode(decoded));
    }
  }

  void _reportProgressIfNeeded() {
    if (_bytesRead - _lastProgress >= 256 * 1024) {
      _lastProgress = _bytesRead;
      _onProgress?.call(_bytesRead);
    }
  }

  void reportFinalProgress() => _onProgress?.call(_bytesRead);

  Future<void> skipWhitespace() async {
    while (true) {
      final byte = await peek();
      if (byte == 0x20 || byte == 0x09 || byte == 0x0a || byte == 0x0d) {
        await read();
      } else {
        return;
      }
    }
  }

  Future<void> expect(int expected) async {
    final actual = await read();
    if (actual != expected) {
      throw const FormatException('Malformed JSON backup.');
    }
  }

  Future<String> readString() async {
    await expect(0x22);
    final bytes = BytesBuilder(copy: false)..addByte(0x22);
    var escaped = false;
    while (true) {
      final byte = await read();
      if (byte == null) throw const FormatException('Unclosed JSON string.');
      bytes.addByte(byte);
      if (escaped) {
        escaped = false;
      } else if (byte == 0x5c) {
        escaped = true;
      } else if (byte == 0x22) {
        break;
      } else if (byte < 0x20) {
        throw const FormatException('Invalid control character in JSON.');
      }
    }
    final value = jsonDecode(utf8.decode(bytes.takeBytes()));
    if (value is! String) throw const FormatException('Expected JSON string.');
    return value;
  }

  Future<List<int>> readRawValue() async {
    final bytes = BytesBuilder(copy: false);
    var depth = 0;
    var inString = false;
    var escaped = false;
    while (true) {
      if (_offset >= _chunk.length) {
        if (!await _iterator.moveNext()) break;
        _chunk = _iterator.current;
        _offset = 0;
        if (_chunk.isEmpty) continue;
      }
      final start = _offset;
      var cursor = start;
      var finished = false;
      while (cursor < _chunk.length) {
        final byte = _chunk[cursor];
        if (!inString &&
            depth == 0 &&
            (byte == 0x2c || byte == 0x7d || byte == 0x5d)) {
          finished = true;
          break;
        }
        cursor++;
        if (inString) {
          if (escaped) {
            escaped = false;
          } else if (byte == 0x5c) {
            escaped = true;
          } else if (byte == 0x22) {
            inString = false;
          }
        } else if (byte == 0x22) {
          inString = true;
        } else if (byte == 0x7b || byte == 0x5b) {
          depth++;
        } else if (byte == 0x7d || byte == 0x5d) {
          depth--;
          if (depth == 0) {
            finished = true;
            break;
          }
        }
      }
      if (cursor > start) {
        bytes.add(_chunk.sublist(start, cursor));
        _bytesRead += cursor - start;
        _offset = cursor;
        _reportProgressIfNeeded();
      }
      if (finished) break;
    }
    if (bytes.length == 0) {
      throw const FormatException('Missing JSON value in backup.');
    }
    return bytes.takeBytes();
  }

  Future<void> close() => _iterator.cancel();
}
