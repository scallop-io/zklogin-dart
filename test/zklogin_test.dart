@Tags(['integration'])
library;

import 'dart:convert';

import 'package:test/test.dart';

import 'package:sui_dart/sui.dart';

import 'package:dio/dio.dart';
import 'package:zklogin_dart/zklogin.dart';

void main() {
  // End-to-end zkLogin flow. It requires a live Sui zkLogin prover and a
  // funded devnet account, so it is tagged `integration` and skipped by
  // default (see dart_test.yaml).
  //
  // Run it explicitly with:
  //   dart test --tags integration --run-skipped
  test('zkLogin transaction (integration)', () async {
    const maxEpoch = 140;

    final randomness = generateRandomness();

    final ephemeralKeypair = Ed25519Keypair();

    // In a real flow this nonce is handed to the OAuth/OIDC provider, which
    // embeds it in the returned JWT.
    final nonce = generateNonce(
      ephemeralKeypair.getPublicKey(),
      maxEpoch,
      randomness,
    );
    expect(nonce, isNotEmpty);

    // Replace with a freshly minted token whose `nonce` claim matches `nonce`
    // above when running against a real prover.
    const jwtStr =
        'eyJraWQiOiJzdWkta2V5LWlkIiwidHlwIjoiSldUIiwiYWxnIjoiUlMyNTYifQ.eyJzdWIiOiI4YzJkN2Q2Ni04N2FmLTQxZmEtYjZmYy02M2U4YmI3MWZhYjQiLCJhdWQiOiJ0ZXN0IiwibmJmIjoxNjk3NDY1NDQ1LCJpc3MiOiJodHRwczovL29hdXRoLnN1aS5pbyIsImV4cCI6MTY5NzU1MTg0NSwibm9uY2UiOiJoVFBwZ0Y3WEFLYlczN3JFVVM2cEVWWnFtb0kifQ.';
    final jwt = decodeJwt(jwtStr);

    final userSalt = BigInt.parse('244579473807694399890185396317414759380');

    final address = jwtToAddress(jwtStr, userSalt);

    final extendedEphemeralPublicKey = getExtendedEphemeralPublicKey(
      ephemeralKeypair.getPublicKey(),
    );

    final body = {
      "jwt": jwtStr,
      "extendedEphemeralPublicKey": extendedEphemeralPublicKey,
      "maxEpoch": maxEpoch,
      "jwtRandomness": randomness,
      "salt": userSalt.toString(),
      "keyClaimName": "sub",
    };

    final zkProof = (await Dio().post(
      'https://prover-dev.mystenlabs.com/v1',
      data: body,
    )).data;

    final txb = Transaction();
    txb.setSenderIfNotSet(address);
    final coin = txb.splitCoins(txb.gas, [txb.pureInt(22222)]);
    txb.transferObjects([coin], txb.pureAddress(address));

    final client = SuiClient(SuiUrls.devnet);
    final sign = await txb.sign(
      SignOptions(signer: ephemeralKeypair, client: client),
    );

    final addressSeed = genAddressSeed(
      userSalt,
      'sub',
      jwt['sub'].toString(),
      jwt['aud'].toString(),
    );
    zkProof["addressSeed"] = addressSeed.toString();

    final zksign = getZkLoginSignature(
      ZkLoginSignature(
        inputs: ZkLoginSignatureInputs.fromJson(zkProof),
        maxEpoch: maxEpoch,
        userSignature: base64Decode(sign.signature),
      ),
    );

    final resp = await client.executeTransactionBlock(sign.bytes, [
      zksign,
    ], options: SuiTransactionBlockResponseOptions(showEffects: true));
    expect(resp.effects?.status.status, ExecutionStatusType.success);
  });
}
