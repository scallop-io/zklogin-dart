import 'dart:convert';
import 'dart:typed_data';

import 'package:sui_dart/sui.dart';

import 'utils.dart';

/// Maximum length (in base64url characters) of a JWT header supported by the
/// zkLogin circuit.
const MAX_HEADER_LEN_B64 = 248;

/// Maximum length (in bytes) of the SHA-2 padded unsigned JWT supported by the
/// zkLogin circuit.
const MAX_PADDED_UNSIGNED_JWT_LEN = 64 * 25;

/// Validates that [jwt] fits within the size limits enforced by the zkLogin
/// circuit.
///
/// Throws a [FormatException] if [jwt] is not a three-segment JWS, if its
/// header is longer than [MAX_HEADER_LEN_B64], or if the SHA-2 padded unsigned
/// JWT would exceed [MAX_PADDED_UNSIGNED_JWT_LEN].
void lengthChecks(String jwt) {
  final parts = jwt.split('.');
  if (parts.length == 5) {
    throw const FormatException(
      'Only JWTs using Compact JWS serialization can be decoded',
    );
  }
  if (parts.length != 3) {
    throw const FormatException(
      'Invalid JWT: expected three dot-separated segments',
    );
  }
  final header = parts[0];
  final payload = parts[1];
  // Is the header small enough?
  if (header.length > MAX_HEADER_LEN_B64) {
    throw const FormatException('Header is too long');
  }

  // Is the combined length of (header, payload, SHA2 padding) small enough?
  // unsigned_jwt = header + '.' + payload;
  final l = (header.length + 1 + payload.length) * 8;
  final k = (512 + 448 - ((l % 512) + 1)) % 512;

  // The SHA2 padding is a 1 followed by K zeros, followed by the length of the
  // message.
  final paddedUnsignedJwtLen = (l + 1 + k + 64) ~/ 8;

  // The padded unsigned JWT must be less than the max padded length.
  if (paddedUnsignedJwtLen > MAX_PADDED_UNSIGNED_JWT_LEN) {
    throw const FormatException('JWT is too long');
  }
}

/// Derives the Sui zkLogin address for the given [jwt] and [userSalt].
///
/// The [jwt] must be a standard three-segment OAuth/OIDC token containing
/// `sub`, `iss`, and `aud` claims, and its `aud` claim must be a single string
/// (array audiences are not supported by zkLogin). Throws a [FormatException]
/// if the token is malformed or missing/invalid required claims.
String jwtToAddress(String jwt, BigInt userSalt) {
  lengthChecks(jwt);

  final decodedJWT = decodeJwt(jwt);
  if (decodedJWT['sub'] == null ||
      decodedJWT['iss'] == null ||
      decodedJWT['aud'] == null) {
    throw const FormatException('Missing jwt data');
  }

  if (decodedJWT['aud'] is List) {
    throw const FormatException(
      'Not supported aud. Aud is an array, string was expected.',
    );
  }

  if (decodedJWT['sub'] is! String ||
      decodedJWT['iss'] is! String ||
      decodedJWT['aud'] is! String) {
    throw const FormatException(
      'Invalid jwt claims: sub, iss and aud must be strings',
    );
  }

  return computeZkLoginAddress(
    userSalt: userSalt,
    claimName: 'sub',
    claimValue: decodedJWT['sub'] as String,
    aud: decodedJWT['aud'] as String,
    iss: decodedJWT['iss'] as String,
  );
}

/// Computes a Sui zkLogin address from its individual components.
///
/// [claimName]/[claimValue] identify the OAuth claim that anchors the address
/// (typically `sub`), [userSalt] is the user's salt, and [iss]/[aud] are the
/// issuer and audience of the JWT.
String computeZkLoginAddress({
  required String claimName,
  required String claimValue,
  required BigInt userSalt,
  required String iss,
  required String aud,
}) {
  return computeZkLoginAddressFromSeed(
    genAddressSeed(userSalt, claimName, claimValue, aud),
    iss,
  );
}

/// Decodes the payload of a compact-serialized [jwt] into its JSON claims.
///
/// Throws a [FormatException] if [jwt] is not a valid three-segment JWS, has an
/// empty payload, or cannot be base64url/JSON decoded.
Map<String, dynamic> decodeJwt(String jwt) {
  final parts = jwt.split('.');
  if (parts.length == 5) {
    throw const FormatException(
      'Only JWTs using Compact JWS serialization can be decoded',
    );
  }
  if (parts.length != 3) {
    throw const FormatException('Invalid JWT');
  }

  final payload = parts[1];
  if (payload.isEmpty) {
    throw const FormatException('JWTs must contain a payload');
  }

  Uint8List decoded;
  try {
    decoded = base64Url.decode(base64Url.normalize(payload));
  } catch (_) {
    throw const FormatException('Failed to base64url decode the payload');
  }

  try {
    final jsonPayload = utf8.decode(decoded);
    return jsonDecode(jsonPayload) as Map<String, dynamic>;
  } catch (e) {
    throw FormatException('Failed to decode JWT: $e');
  }
}
