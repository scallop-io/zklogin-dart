import 'dart:convert';
import 'dart:typed_data';

dynamic unstringifyBigInts(dynamic o) {
  if (o is List) {
    return o.map((element) => unstringifyBigInts(element)).toList();
  } else if (o is Map) {
    Map<String, dynamic> res = {};
    for (var entry in o.entries) {
      res[entry.key] = unstringifyBigInts(entry.value);
    }
    return res;
  } else if (o is String) {
    // Base64 decode
    Uint8List byteArray = Uint8List.fromList(base64Decode(o));
    String hex = byteArray
        .map((x) => x.toRadixString(16).padLeft(2, '0'))
        .join('');
    return BigInt.parse('0x$hex');
  }
  return o;
}
