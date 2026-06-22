// ignore_for_file: avoid_print
import 'package:sui_dart/sui.dart';
import 'package:zklogin_dart/zklogin.dart';

/// A minimal, network-free walkthrough of the zkLogin building blocks:
/// generating an ephemeral key pair and nonce, and deriving a zkLogin address
/// from a JWT.
///
/// A full flow additionally exchanges the nonce for a real OAuth/OIDC JWT and
/// requests a proof from a Sui zkLogin prover — see the `integration` test for
/// that end-to-end example.
void main() {
  // 1. Create an ephemeral key pair for this session.
  final ephemeralKeypair = Ed25519Keypair();

  // 2. Generate randomness and the nonce to hand to the OAuth/OIDC provider.
  const maxEpoch = 140;
  final randomness = generateRandomness();
  final nonce = generateNonce(
    ephemeralKeypair.getPublicKey(),
    maxEpoch,
    randomness,
  );
  print('nonce: $nonce');

  // 3. The zkLogin prover expects the extended ephemeral public key.
  final extendedEphemeralPublicKey = getExtendedEphemeralPublicKey(
    ephemeralKeypair.getPublicKey(),
  );
  print('extendedEphemeralPublicKey: $extendedEphemeralPublicKey');

  // 4. After the provider returns a JWT, derive the user's zkLogin address.
  //    (This sample JWT is for illustration only.)
  const jwt =
      'eyJraWQiOiJzdWkta2V5LWlkIiwidHlwIjoiSldUIiwiYWxnIjoiUlMyNTYifQ.eyJzdWIiOiI4YzJkN2Q2Ni04N2FmLTQxZmEtYjZmYy02M2U4YmI3MWZhYjQiLCJhdWQiOiJ0ZXN0IiwibmJmIjoxNjk3NDY1NDQ1LCJpc3MiOiJodHRwczovL29hdXRoLnN1aS5pbyIsImV4cCI6MTY5NzU1MTg0NSwibm9uY2UiOiJoVFBwZ0Y3WEFLYlczN3JFVVM2cEVWWnFtb0kifQ.';
  final userSalt = BigInt.parse('248191903847969014646285995941615069143');

  final address = jwtToAddress(jwt, userSalt);
  print('zkLogin address: $address');

  // The address seed binds the salt to the JWT claims. Combined with the
  // prover output it is used to build the zkLogin signature.
  final claims = decodeJwt(jwt);
  final addressSeed = genAddressSeed(
    userSalt,
    'sub',
    claims['sub'].toString(),
    claims['aud'].toString(),
  );
  print('address seed: $addressSeed');
}
