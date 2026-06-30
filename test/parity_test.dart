import 'package:test/test.dart';
import 'package:zklogin_dart/zklogin.dart';
import 'package:sui_dart/sui.dart';

void main() {
  group('genAddressSeed rejects JSON-escaped claims', () {
    final salt = BigInt.parse('248191903847969014646285995941615069143');
    const aud = '1234567890.apps.googleusercontent.com';
    final controlChar = String.fromCharCode(1);

    test('plain claims do not throw', () {
      expect(
        () => genAddressSeed(salt, 'sub', '1234567890', aud),
        returnsNormally,
      );
    });

    test('throws on double-quote, backslash, or control char', () {
      expect(
        () => genAddressSeed(salt, 'sub', 'a"b', aud),
        throwsArgumentError,
      );
      expect(
        () => genAddressSeed(salt, 'sub', 'a\\b', aud),
        throwsArgumentError,
      );
      expect(
        () => genAddressSeed(salt, 'sub', 'a${controlChar}b', aud),
        throwsArgumentError,
      );
      expect(
        () => genAddressSeed(salt, 'su\\b', '1', aud),
        throwsArgumentError,
      );
      expect(
        () => genAddressSeed(salt, 'sub', '1', 'a"b'),
        throwsArgumentError,
      );
    });
  });

  group('getExtendedEphemeralPublicKey', () {
    test('returns the base64 sui public key', () {
      final pk = Ed25519Keypair().getPublicKey();
      expect(getExtendedEphemeralPublicKey(pk), pk.toSuiPublicKey());
    });
  });
}
