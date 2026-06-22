# zklogin_dart

[![pub package](https://img.shields.io/pub/v/zklogin_dart.svg)](https://pub.dev/packages/zklogin_dart)
[![license: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

Sui [zkLogin](https://docs.sui.io/concepts/cryptography/zklogin) SDK for Dart.
Derive zkLogin addresses from OAuth/OIDC JWTs, generate ephemeral nonces,
compute address seeds, and assemble the inputs needed for a Sui zkLogin
signature — in pure Dart, so it runs anywhere Dart does (Flutter, server, CLI,
and web).

## Features

- Derive a Sui zkLogin address from a JWT and user salt — `jwtToAddress`.
- Generate ephemeral randomness and the OAuth `nonce` — `generateRandomness`, `generateNonce`.
- Compute the extended ephemeral public key the prover expects — `getExtendedEphemeralPublicKey`.
- Compute the address seed that binds the salt to the JWT claims — `genAddressSeed`.
- Poseidon (BN254) hashing utilities used throughout zkLogin — `poseidonHash`.
- Pure Dart, with no Flutter dependency.

## Installation

```sh
dart pub add zklogin_dart
```

Or add it to your `pubspec.yaml`:

```yaml
dependencies:
  zklogin_dart: ^0.0.6
```

## Usage

```dart
import 'package:sui_dart/sui.dart';
import 'package:zklogin_dart/zklogin.dart';

void main() {
  // 1. Create an ephemeral key pair for the session.
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

  // 3. The prover expects the extended ephemeral public key.
  final extendedEphemeralPublicKey =
      getExtendedEphemeralPublicKey(ephemeralKeypair.getPublicKey());
  print('extendedEphemeralPublicKey: $extendedEphemeralPublicKey');

  // 4. After the provider returns a JWT (a real 3-segment token), derive the
  //    user's zkLogin address.
  const jwt = '<jwt-from-your-oauth-provider>';
  final userSalt = BigInt.parse('248191903847969014646285995941615069143');
  final address = jwtToAddress(jwt, userSalt);
  print('address: $address');
}
```

See [`example/zklogin_dart_example.dart`](example/zklogin_dart_example.dart) for
a runnable, network-free walkthrough.

## The full zkLogin flow

1. Generate an ephemeral key pair, `randomness`, and a `nonce`.
2. Redirect the user to an OAuth/OIDC provider with that `nonce`; receive a JWT.
3. Derive the user's address with `jwtToAddress`.
4. Request a ZK proof from a Sui zkLogin prover using the JWT, the extended
   ephemeral public key, `maxEpoch`, `randomness`, and the salt.
5. Combine the proof with `genAddressSeed` and the ephemeral signature via
   `getZkLoginSignature` (from [`sui_dart`](https://pub.dev/packages/sui_dart))
   and submit the transaction.

The end-to-end flow is shown in the `integration`-tagged test. Run it with:

```sh
dart test --tags integration --run-skipped
```

For background, see the
[Sui zkLogin documentation](https://docs.sui.io/concepts/cryptography/zklogin).

## Credits

This package is a fork of [mofalabs/zklogin](https://github.com/mofalabs/zklogin).
It bundles the Poseidon hash implementation from
[mofalabs/poseidon](https://github.com/mofalabs/poseidon) (MIT, © 2022 0xmove)
under `lib/src/poseidon`.

## License

[MIT](LICENSE). Bundled third-party code retains its original MIT license; see
[`lib/src/poseidon/LICENSE`](lib/src/poseidon/LICENSE).
