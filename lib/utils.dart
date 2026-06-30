import 'poseidon.dart';

/// Maximum length of an OAuth key-claim name supported by zkLogin.
const MAX_KEY_CLAIM_NAME_LENGTH = 32;

/// Maximum length of an OAuth key-claim value supported by zkLogin.
const MAX_KEY_CLAIM_VALUE_LENGTH = 115;

/// Maximum length of an OAuth `aud` value supported by zkLogin.
const MAX_AUD_VALUE_LENGTH = 145;

/// Bit width used when packing ASCII strings into field elements.
const PACK_WIDTH = 248;

/// Splits [array] into chunks of size [chunkSize]. If the array is not evenly
/// divisible by [chunkSize], the first chunk will be smaller than [chunkSize].
///
/// E.g., `chunkArray([1, 2, 3, 4, 5], 2)` => `[[1], [2, 3], [4, 5]]`.
List<List<T>> chunkArray<T>(List<T> array, int chunkSize) {
  final revArray = array.reversed;
  final chunks = List.generate(
    (revArray.length / chunkSize).ceil(),
    (i) => List<T>.from(
      revArray.skip(i * chunkSize).take(chunkSize).toList().reversed,
    ),
  );
  return chunks.reversed.toList();
}

/// Interprets [bytes] as a big-endian unsigned integer.
BigInt bytesBEToBigInt(List<int> bytes) {
  if (bytes.isEmpty) {
    return BigInt.zero;
  }
  final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  return BigInt.parse('0x$hex');
}

/// Hashes an ASCII [str] to a single field element, padding with zero bytes up
/// to [maxSize]. Throws an [ArgumentError] if [str] is longer than [maxSize].
BigInt hashASCIIStrToField(String str, int maxSize) {
  if (str.length > maxSize) {
    throw ArgumentError('String $str is longer than $maxSize chars');
  }

  // Padding with zeroes is safe because we are only using this function to map
  // a human-readable sequence of bytes. The ASCII values of those characters
  // will never be zero (the null character).
  final strPadded = str.padRight(maxSize, String.fromCharCode(0)).codeUnits;

  const chunkSize = PACK_WIDTH ~/ 8;
  final packed = chunkArray(strPadded, chunkSize).map(bytesBEToBigInt).toList();
  return poseidonHash(packed);
}

/// Rejects a claim whose decoded form contains a JSON escape (`"`, `\`, or a
/// control char): the circuit hashes raw JWT bytes, so an escaped value would
/// derive a different address.
void _assertNoJsonEscape(String value, String label) {
  for (var i = 0; i < value.length; i++) {
    final c = value.codeUnitAt(i);
    if (c < 0x20 || c == 0x22 || c == 0x5c) {
      throw ArgumentError(
        'zkLogin $label contains a JSON-escaped character (code $c); the '
        'circuit hashes raw JWT bytes, so claim values with escapes are not '
        'supported',
      );
    }
  }
}

/// Generates the zkLogin address seed from the user's [salt], the OAuth claim
/// identified by [name]/[value], and the token's [aud].
BigInt genAddressSeed(
  BigInt salt,
  String name,
  String value,
  String aud, {
  int maxNameLength = MAX_KEY_CLAIM_NAME_LENGTH,
  int maxValueLength = MAX_KEY_CLAIM_VALUE_LENGTH,
  int maxAudLength = MAX_AUD_VALUE_LENGTH,
}) {
  _assertNoJsonEscape(name, 'key claim name');
  _assertNoJsonEscape(value, 'key claim value');
  _assertNoJsonEscape(aud, 'aud');
  return poseidonHash([
    hashASCIIStrToField(name, maxNameLength),
    hashASCIIStrToField(value, maxValueLength),
    hashASCIIStrToField(aud, maxAudLength),
    poseidonHash([salt]),
  ]);
}
