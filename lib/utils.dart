import 'package:sui_dart/sui.dart';
import 'package:sui_dart/utils/hex.dart';

import 'poseidon.dart';

/// Maximum length of an OAuth key-claim name supported by zkLogin.
const MAX_KEY_CLAIM_NAME_LENGTH = 32;

/// Maximum length of an OAuth key-claim value supported by zkLogin.
const MAX_KEY_CLAIM_VALUE_LENGTH = 115;

/// Maximum length of an OAuth `aud` value supported by zkLogin.
const MAX_AUD_VALUE_LENGTH = 145;

/// Bit width used when packing ASCII strings into field elements.
const PACK_WIDTH = 248;

/// Returns the extended ephemeral public key for [publicKey] as a decimal
/// string, the form expected by the Sui zkLogin prover.
String getExtendedEphemeralPublicKey(PublicKey publicKey) {
  return BigInt.parse(Hex.encode(publicKey.toSuiBytes()), radix: 16).toString();
}

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
  return poseidonHash([
    hashASCIIStrToField(name, maxNameLength),
    hashASCIIStrToField(value, maxValueLength),
    hashASCIIStrToField(aud, maxAudLength),
    poseidonHash([salt]),
  ]);
}
