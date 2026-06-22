## 0.0.6

- Migrated the package to [scallop-io/zklogin-dart](https://github.com/scallop-io/zklogin-dart).
- Vendored the Poseidon hash implementation into `lib/src/poseidon`, removing the accidental Flutter SDK dependency. The package is now pure Dart and supports all platforms.
- Upgraded to `sui_dart ^0.5.0` and raised the Dart SDK lower bound to `^3.11.0`.
- Removed the `pointycastle` dependency override (now resolved transitively via `sui_dart`).
- Migrated lints from `flutter_lints` to the pure-Dart `lints` package.
- Hardened JWT parsing: malformed tokens and invalid claim types now throw a clear `FormatException` instead of a raw `RangeError`/`TypeError`.
- Added an example, expanded API documentation, and refreshed package metadata.

## 0.0.5

- Refactor change flutter_test to test for more platform agnostic
- Upgrade Sui lib

## 0.0.4

- Upgrade Sui

## 0.0.3

- Fix getExtendedEphemeralPublicKey

## 0.0.2

- Add zkLogin Test

## 0.0.1

- Initial version, created by Mofa Labs.
