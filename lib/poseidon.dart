import 'src/poseidon/poseidon.dart';

/// Poseidon hash functions indexed by input arity, where
/// `poseidonNumToHashFN[n - 1]` hashes a list of `n` field elements.
const poseidonNumToHashFN = [
  poseidon1,
  poseidon2,
  poseidon3,
  poseidon4,
  poseidon5,
  poseidon6,
  poseidon7,
  poseidon8,
  poseidon9,
  poseidon10,
  poseidon11,
  poseidon12,
  poseidon13,
  poseidon14,
  poseidon15,
  poseidon16,
];

/// Computes the Poseidon hash of [inputs] over the BN254 scalar field.
///
/// Supports 1–16 inputs directly, and 17–32 inputs by splitting the list in
/// half and hashing recursively. Throws an [ArgumentError] for an empty list
/// and an [Exception] for more than 32 inputs.
BigInt poseidonHash(List<BigInt> inputs) {
  if (inputs.isEmpty) {
    throw ArgumentError('poseidonHash requires at least one input');
  }
  try {
    if (inputs.length <= poseidonNumToHashFN.length) {
      final hashFN = poseidonNumToHashFN[inputs.length - 1];
      return hashFN(inputs);
    } else if (inputs.length <= 32) {
      final hash1 = inputs.sublist(0, 16);
      final hash2 = inputs.sublist(16);
      return poseidonHash([poseidonHash(hash1), poseidonHash(hash2)]);
    } else {
      throw Exception(
        'Yet to implement: Unable to hash a vector of length ${inputs.length}',
      );
    }
  } catch (e) {
    throw Exception('poseidonHash error: $e');
  }
}
