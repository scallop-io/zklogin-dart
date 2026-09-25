## 0.5.0

### Breaking

- Require `sui_dart` `^0.12.0`.

## 0.4.0

### Breaking

- Require `sui_dart` `^0.11.0`.

## 0.3.0

### Breaking

- Require `sui_dart` `^0.10.0`. zkLogin's own API is unchanged.

## 0.2.0

### Breaking

- Require `sui_dart` `^0.9.0`. Its transport refactor removed the JSON-RPC
  surface and reshaped the transaction-build options (`SignOptions.client`
  instead of `resolutionClient`), so consumers on `sui_dart` 0.8.x must
  migrate. zkLogin's own API is unchanged.

## 0.1.0

Synced to `f898c13`.

### Breaking

- `getExtendedEphemeralPublicKey` returns the flag-prefixed base64 key (`toSuiPublicKey()`, what the prover expects) instead of a decimal string.
- `jwtToAddress` / `computeZkLoginAddress` default to the current (non-legacy) address and take a `legacyAddress` flag; seeds with leading zeros now derive differently — pass `legacyAddress: true` for the old result.
- Bump `sui_dart` to `^0.8.1`.

### Security

- `genAddressSeed` rejects a key-claim name/value or `aud` with a JSON escape (`"`, `\`, control char) — the circuit hashes raw JWT bytes, so escaped values would derive a different address.

## 0.0.6

- Moved to scallop-io/zklogin-dart; vendored Poseidon into `lib/src/poseidon` (pure Dart, all platforms — removes the accidental Flutter dependency).
- Bump `sui_dart` to `^0.5.0`, Dart SDK to `^3.11.0`; drop the `pointycastle` override; switch `flutter_lints` → `lints`.
- JWT parsing throws `FormatException` on malformed tokens / invalid claim types (was `RangeError`/`TypeError`).
- Add example, docs, metadata.

## 0.0.5

- Platform-agnostic tests (`flutter_test` → `test`); upgrade Sui lib.

## 0.0.4

- Upgrade Sui.

## 0.0.3

- Fix `getExtendedEphemeralPublicKey`.

## 0.0.2

- Add zkLogin test.

## 0.0.1

- Initial version, created by Mofa Labs.
