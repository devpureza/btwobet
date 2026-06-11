import 'dart:async';

import 'package:flutter/material.dart';

import '../features/matches/hall_entry.dart';
import 'careca_da_rodada_card.dart';
import 'hall_sections.dart';

/// Fama, Vergonha e Careca da rodada em uma única faixa horizontal.
class HallHighlightsRow extends StatefulWidget {
  final HallOfWeekData data;

  const HallHighlightsRow({super.key, required this.data});

  @override
  State<HallHighlightsRow> createState() => _HallHighlightsRowState();
}

class _HallHighlightsRowState extends State<HallHighlightsRow> {
  static const _rotateInterval = Duration(seconds: 4);
  static const _wideBreakpoint = 720.0;
  static const _scrollCardWidth = 272.0;

  Timer? _timer;
  int _fameIndex = 0;
  int _shameIndex = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(_rotateInterval, (_) {
      if (!mounted) return;
      setState(() {
        if (widget.data.fame.isNotEmpty) {
          _fameIndex = (_fameIndex + 1) % widget.data.fame.length;
        }
        if (widget.data.shame.isNotEmpty) {
          _shameIndex = (_shameIndex + 1) % widget.data.shame.length;
        }
      });
    });
  }

  @override
  void didUpdateWidget(covariant HallHighlightsRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data.fame.length != widget.data.fame.length) {
      _fameIndex = 0;
    }
    if (oldWidget.data.shame.length != widget.data.shame.length) {
      _shameIndex = 0;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= _wideBreakpoint;
    final careca = widget.data.careca;

    final fameCard = HallCard(
      kind: HallCardKind.fame,
      entries: widget.data.fame,
      highlightedIndex: _fameIndex,
      periodLabel: widget.data.periodLabel,
      compact: true,
    );
    final shameCard = HallCard(
      kind: HallCardKind.shame,
      entries: widget.data.shame,
      highlightedIndex: _shameIndex,
      periodLabel: widget.data.periodLabel,
      compact: true,
    );
    final carecaCard = careca == null ? null : CarecaDaRodadaCard(data: careca, compact: true);

    if (isWide) {
      return IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: fameCard),
            const SizedBox(width: 12),
            Expanded(child: shameCard),
            if (carecaCard != null) ...[
              const SizedBox(width: 12),
              Expanded(child: carecaCard),
            ],
          ],
        ),
      );
    }

    final cards = <Widget>[
      SizedBox(width: _scrollCardWidth, child: fameCard),
      const SizedBox(width: 12),
      SizedBox(width: _scrollCardWidth, child: shameCard),
      if (carecaCard != null) ...[
        const SizedBox(width: 12),
        SizedBox(width: _scrollCardWidth, child: carecaCard),
      ],
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: cards,
      ),
    );
  }
}
