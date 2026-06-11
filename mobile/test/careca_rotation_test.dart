import 'package:flutter_test/flutter_test.dart';

/// Espelha a rotação do backend: índice = isoWeek % 3.
int carecaRotationIndex(int isoWeek, int candidateCount) {
  return ((isoWeek % candidateCount) + candidateCount) % candidateCount;
}

void main() {
  const count = 3;

  test('semana ISO 24 seleciona limirio (índice 0)', () {
    expect(carecaRotationIndex(24, count), 0);
  });

  test('semana ISO 25 seleciona guilherme (índice 1)', () {
    expect(carecaRotationIndex(25, count), 1);
  });

  test('semana ISO 26 seleciona igor (índice 2)', () {
    expect(carecaRotationIndex(26, count), 2);
  });

  test('múltiplo de 3 cai no primeiro da lista', () {
    expect(carecaRotationIndex(3, count), 0);
    expect(carecaRotationIndex(6, count), 0);
  });
}
