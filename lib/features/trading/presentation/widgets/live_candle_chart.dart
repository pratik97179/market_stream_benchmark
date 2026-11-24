import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/market_store.dart';

/// OHLC chart. Repaints directly from [repaint], so new candles never
/// rebuild any widgets.
class LiveCandleChart extends StatelessWidget {
  const LiveCandleChart({
    super.key,
    required this.candles,
    required this.repaint,
  });

  /// Oldest first; read at paint time.
  final List<Candle> candles;

  /// Notifies when [candles] changed.
  final Listenable repaint;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: SizedBox(
        height: 260,
        width: double.infinity,
        child: CustomPaint(painter: _CandleChartPainter(candles, repaint)),
      ),
    );
  }
}

class _CandleChartPainter extends CustomPainter {
  _CandleChartPainter(this.candles, Listenable repaint)
    : super(repaint: repaint);

  final List<Candle> candles;

  static const _left = 8.0;
  static const _right = 52.0;
  static const _top = 12.0;
  static const _bottom = 22.0;
  static const _labelStyle = TextStyle(color: Color(0xFF718096), fontSize: 9);

  static final Paint _gridPaint = Paint()
    ..color = const Color(0xFF26313B)
    ..strokeWidth = 0.7;
  static final Paint _bullWick = Paint()
    ..color = const Color(0xFF26A69A)
    ..strokeWidth = 1.2;
  static final Paint _bearWick = Paint()
    ..color = const Color(0xFFEF5350)
    ..strokeWidth = 1.2;
  static final Paint _bullBody = Paint()..color = const Color(0xFF26A69A);
  static final Paint _bearBody = Paint()..color = const Color(0xFFEF5350);

  /// Laid-out axis labels, reused across frames. Labels change only when
  /// the price range moves, so this stays small; it is capped to be safe.
  static final Map<String, TextPainter> _labelCache = {};

  static TextPainter _label(String text) {
    final cached = _labelCache[text];
    if (cached != null) return cached;
    if (_labelCache.length > 256) {
      for (final painter in _labelCache.values) {
        painter.dispose();
      }
      _labelCache.clear();
    }
    return _labelCache[text] = TextPainter(
      text: TextSpan(text: text, style: _labelStyle),
      textDirection: TextDirection.ltr,
    )..layout();
  }

  static final TextPainter _waiting = TextPainter(
    text: const TextSpan(
      text: 'Waiting for candle history...',
      style: TextStyle(color: Colors.white38),
    ),
    textDirection: TextDirection.ltr,
  )..layout();

  @override
  void paint(Canvas canvas, Size size) {
    if (candles.length < 2) {
      _waiting.paint(
        canvas,
        Offset(
          (size.width - _waiting.width) / 2,
          (size.height - _waiting.height) / 2,
        ),
      );
      return;
    }

    final chartWidth = size.width - _left - _right;
    final chartHeight = size.height - _top - _bottom;

    var minPrice = candles.first.low;
    var maxPrice = candles.first.high;
    for (final candle in candles) {
      if (candle.low < minPrice) minPrice = candle.low;
      if (candle.high > maxPrice) maxPrice = candle.high;
    }

    final range = math.max((maxPrice - minPrice).toDouble(), 1.0);
    final padding = range * 0.08;
    final high = maxPrice + padding;
    final totalRange = range + padding * 2;

    double yFor(int price) =>
        _top + ((high - price) / totalRange) * chartHeight;

    for (var i = 0; i <= 4; i++) {
      final y = _top + chartHeight * i / 4;
      canvas.drawLine(
        Offset(_left, y),
        Offset(size.width - _right, y),
        _gridPaint,
      );
      final price = high - totalRange * i / 4;
      final label = _label((price / 100).toStringAsFixed(2));
      label.paint(
        canvas,
        Offset(size.width - _right + 5, y - label.height / 2),
      );
    }

    final step = chartWidth / candles.length;
    final candleWidth = math.max(2.0, math.min(10.0, step * 0.58));

    for (var i = 0; i < candles.length; i++) {
      final candle = candles[i];
      final bullish = candle.close >= candle.open;
      final x = _left + step * (i + 0.5);

      canvas.drawLine(
        Offset(x, yFor(candle.high)),
        Offset(x, yFor(candle.low)),
        bullish ? _bullWick : _bearWick,
      );

      final openY = yFor(candle.open);
      final closeY = yFor(candle.close);
      final bodyTop = math.min(openY, closeY);
      final bodyHeight = math.max((closeY - openY).abs(), 1.5);

      canvas.drawRect(
        Rect.fromLTWH(x - candleWidth / 2, bodyTop, candleWidth, bodyHeight),
        bullish ? _bullBody : _bearBody,
      );
    }
  }

  @override
  bool shouldRepaint(_CandleChartPainter oldDelegate) =>
      !identical(oldDelegate.candles, candles);
}
