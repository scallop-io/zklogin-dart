import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:sui_dart/cryptography/keypair.dart';
import 'package:sui_dart/utils/hex.dart';
import 'package:sui_dart/zklogin/utils.dart';

import 'poseidon.dart';

/// The exact length, in characters, of a base64url-encoded zkLogin nonce.
const NONCE_LENGTH = 27;

/// Interprets [bytes] as a big-endian unsigned integer.
BigInt toBigIntBE(Uint8List bytes) {
  final hex = Hex.encode(bytes);
  if (hex.isEmpty) {
    return BigInt.zero;
  }
  return BigInt.parse('0x$hex');
}

/// Generates a cryptographically secure 128-bit randomness value, returned as
/// a decimal string suitable for use as the JWT randomness in a zkLogin flow.
String generateRandomness() {
  final bytes = randomBytes(16);
  return toBigIntBE(bytes).toString();
}

/// Returns [size] cryptographically secure random bytes.
Uint8List randomBytes(int size) {
  final random = Random.secure();
  return Uint8List.fromList(
    List.generate(size, (index) => random.nextInt(256)),
  );
}

/// Generates the zkLogin nonce that commits to the ephemeral [publicKey], the
/// [maxEpoch] until which it is valid, and a [randomness] value.
///
/// [randomness] may be either a decimal [String] (as returned by
/// [generateRandomness]) or a [BigInt]; any other type throws an
/// [ArgumentError]. Throws an [Exception] if the derived nonce is not
/// [NONCE_LENGTH] characters long.
String generateNonce(PublicKey publicKey, int maxEpoch, dynamic randomness) {
  final publicKeyBytes = toBigIntBE(publicKey.toSuiBytes());
  final ephPublicKey0 = publicKeyBytes ~/ BigInt.two.pow(128);
  final ephPublicKey1 = publicKeyBytes % BigInt.two.pow(128);
  BigInt bigNum;

  if (randomness is String) {
    bigNum = poseidonHash([
      ephPublicKey0,
      ephPublicKey1,
      BigInt.from(maxEpoch),
      BigInt.parse(randomness),
    ]);
  } else if (randomness is BigInt) {
    bigNum = poseidonHash([
      ephPublicKey0,
      ephPublicKey1,
      BigInt.from(maxEpoch),
      randomness,
    ]);
  } else {
    throw ArgumentError(
      'Invalid type for randomness. It should be either BigInt or String.',
    );
  }

  final z = toBigEndianBytes(bigNum, 20);
  final nonce = base64UrlEncode(
    z,
  ).replaceAll('=', '').replaceAll('+', '-').replaceAll('/', '_');
  if (nonce.length != NONCE_LENGTH) {
    throw Exception(
      'Length of nonce $nonce (${nonce.length}) is not equal to $NONCE_LENGTH',
    );
  }
  return nonce;
}
