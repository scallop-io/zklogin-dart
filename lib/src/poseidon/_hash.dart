final F = BigInt.parse(
  '21888242871839275222246405745257275088548364400416034343698204186575808495617',
);

const List<int> N_ROUNDS_P = [
  56,
  57,
  56,
  60,
  60,
  63,
  64,
  63,
  60,
  66,
  60,
  65,
  70,
  60,
  64,
  68,
];

BigInt pow5(BigInt v) {
  BigInt o = v * v;
  return (v * o * o) % F;
}

List<BigInt> mix(List<BigInt> state, List<List<BigInt>> M) {
  List<BigInt> out = [];
  for (int x = 0; x < state.length; x++) {
    BigInt o = BigInt.zero;
    for (int y = 0; y < state.length; y++) {
      o = o + M[x][y] * state[y];
    }
    out.add(o % F);
  }
  return out;
}

BigInt poseidon(List<BigInt> _inputs, Map<String, dynamic> opt) {
  List<BigInt> inputs = _inputs.map((i) => i).toList();
  if (inputs.isEmpty) {
    throw ArgumentError('poseidon-lite: Not enough inputs');
  }
  if (inputs.length > N_ROUNDS_P.length) {
    throw ArgumentError('poseidon-lite: Too many inputs');
  }

  final t = inputs.length + 1;
  const nRoundsF = 8;
  final nRoundsP = N_ROUNDS_P[t - 2];

  final List<BigInt> C = (opt['C'] as List).map((e) => e as BigInt).toList();
  final List<List<BigInt>> M = (opt['M'] as List)
      .map((value) => (value as List).map((e) => e as BigInt).toList())
      .toList();

  if (M.length != t) {
    throw ArgumentError(
      'poseidon-lite: Incorrect M length, expected $t got ${M.length}',
    );
  }

  List<BigInt> state = [BigInt.zero, ...inputs];
  for (int x = 0; x < nRoundsF + nRoundsP; x++) {
    for (int y = 0; y < state.length; y++) {
      state[y] = state[y] + C[x * t + y];
      if (x < nRoundsF ~/ 2 || x >= nRoundsF ~/ 2 + nRoundsP) {
        state[y] = pow5(state[y]);
      } else if (y == 0) {
        state[y] = pow5(state[y]);
      }
    }
    state = mix(state, M);
  }
  return state[0];
}
