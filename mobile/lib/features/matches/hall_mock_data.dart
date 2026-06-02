import 'package:flutter/material.dart';

/// Entrada mock para Hall da Fama / Hall da Vergonha.
/// Substituir por modelo da API quando o backend existir.
class MockHallEntry {
  final String id;
  final String displayName;
  final String title;
  final String fallbackLetter;
  final Color? avatarColor;

  const MockHallEntry({
    required this.id,
    required this.displayName,
    required this.title,
    required this.fallbackLetter,
    this.avatarColor,
  });
}

/// Dados fictícios — trocar por `session.hallOfFame` etc. no futuro.
abstract final class HallMockData {
  static const previewLabel = 'Prévia';

  static const List<MockHallEntry> hallOfFame = [
    MockHallEntry(
      id: 'fame_1',
      displayName: 'Ana Costa',
      title: 'Maior pontuação da rodada',
      fallbackLetter: 'A',
      avatarColor: Color(0xFFFCD400),
    ),
    MockHallEntry(
      id: 'fame_2',
      displayName: 'Bruno Lima',
      title: 'Placar exato na final',
      fallbackLetter: 'B',
      avatarColor: Color(0xFF4ADE80),
    ),
    MockHallEntry(
      id: 'fame_3',
      displayName: 'Carla Mendes',
      title: 'Sequência de 5 acertos',
      fallbackLetter: 'C',
      avatarColor: Color(0xFF38BDF8),
    ),
  ];

  static const List<MockHallEntry> hallOfShame = [
    MockHallEntry(
      id: 'shame_1',
      displayName: 'Diego Souza',
      title: 'Previu 7×0 no empate',
      fallbackLetter: 'D',
      avatarColor: Color(0xFFFB923C),
    ),
    MockHallEntry(
      id: 'shame_2',
      displayName: 'Elena Rocha',
      title: 'Esqueceu de palpitar na semi',
      fallbackLetter: 'E',
      avatarColor: Color(0xFFF87171),
    ),
    MockHallEntry(
      id: 'shame_3',
      displayName: 'Felipe Alves',
      title: 'Zerou a rodada inteira',
      fallbackLetter: 'F',
      avatarColor: Color(0xFFA78BFA),
    ),
  ];
}
