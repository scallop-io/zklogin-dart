// Vendored from the `poseidon` package (https://pub.dev/packages/poseidon),
// originally by mofalabs / 0xmove, released under the MIT License:
//
//   MIT License
//   Copyright (c) 2022 0xmove
//
//   Permission is hereby granted, free of charge, to any person obtaining a
//   copy of this software and associated documentation files (the "Software"),
//   to deal in the Software without restriction, including without limitation
//   the rights to use, copy, modify, merge, publish, distribute, sublicense,
//   and/or sell copies of the Software, and to permit persons to whom the
//   Software is furnished to do so, subject to the following conditions:
//
//   The above copyright notice and this permission notice shall be included in
//   all copies or substantial portions of the Software.
//
// The source was vendored (rather than depended on) because the upstream
// package declares a Flutter SDK dependency it does not actually use, which
// pins `meta` to a version incompatible with sui_dart and prevents this
// package from being a pure-Dart, all-platform library.
//
// Poseidon hash functions `poseidon1` … `poseidon16` over the BN254 scalar
// field, used by Sui zkLogin address and nonce derivation.

export 'constants/p1.dart';
export 'constants/p2.dart';
export 'constants/p3.dart';
export 'constants/p4.dart';
export 'constants/p5.dart';
export 'constants/p6.dart';
export 'constants/p7.dart';
export 'constants/p8.dart';
export 'constants/p9.dart';
export 'constants/p10.dart';
export 'constants/p11.dart';
export 'constants/p12.dart';
export 'constants/p13.dart';
export 'constants/p14.dart';
export 'constants/p15.dart';
export 'constants/p16.dart';
