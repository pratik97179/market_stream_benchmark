import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

/// Pre-shaped glyphs for numbers, drawn in one batch per panel.
///
/// Laying out text (shaping) is the expensive part of drawing a busy market
/// table. Prices, quantities and percentages use only a handful of
/// characters, so each is shaped once into an image here. A panel then
/// draws all its numbers with a single [Canvas.drawRawAtlas] call, with no
/// text layout per frame. Digits use tabular figures, so columns line up.
class GlyphAtlas {
  GlyphAtlas._(this.image, this._src, this._advance, this.height, this._dpr);

  /// Characters a market number can contain.
  static const String charset = '0123456789.,-+%KLCr—– ';

  static final Map<(double, FontWeight, double), GlyphAtlas> _cache = {};

  /// Shared atlas for a font size, weight and device pixel ratio.
  static GlyphAtlas of(
    double fontSize, {
    FontWeight weight = FontWeight.normal,
    required double devicePixelRatio,
  }) => _cache[(fontSize, weight, devicePixelRatio)] ??= _build(
    fontSize,
    weight,
    devicePixelRatio,
  );

  final ui.Image image;

  /// Source rect per char code (in image pixels): left, top, right, bottom.
  final Map<int, Float32List> _src;

  /// Advance width per char code, in logical pixels.
  final Map<int, double> _advance;

  /// Line height in logical pixels.
  final double height;
  final double _dpr;

  static GlyphAtlas _build(double fontSize, FontWeight weight, double dpr) {
    final style = TextStyle(
      color: const Color(0xFFFFFFFF),
      fontSize: fontSize,
      fontWeight: weight,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    final painters = [
      for (final char in charset.split(''))
        TextPainter(
          text: TextSpan(text: char, style: style),
          textDirection: TextDirection.ltr,
        )..layout(),
    ];

    const gap = 2.0; // keeps neighbouring glyphs from bleeding
    var width = gap;
    var height = 0.0;
    for (final painter in painters) {
      width += painter.width + gap;
      if (painter.height > height) height = painter.height;
    }

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder)..scale(dpr);
    final src = <int, Float32List>{};
    final advance = <int, double>{};
    var x = gap;
    for (var i = 0; i < painters.length; i++) {
      final painter = painters[i];
      painter.paint(canvas, Offset(x, 0));
      final code = charset.codeUnitAt(i);
      src[code] = Float32List.fromList([
        x * dpr,
        0,
        (x + painter.width) * dpr,
        height * dpr,
      ]);
      advance[code] = painter.width;
      x += painter.width + gap;
      painter.dispose();
    }
    final image = recorder.endRecording().toImageSync(
      (width * dpr).ceil(),
      (height * dpr).ceil(),
    );
    return GlyphAtlas._(image, src, advance, height, dpr);
  }

  /// Width of [text] in logical pixels.
  double measure(String text) {
    var width = 0.0;
    for (var i = 0; i < text.length; i++) {
      width += _advance[text.codeUnitAt(i)] ?? 0;
    }
    return width;
  }

  /// Queues [text] with its top-left at ([x], [y]).
  void add(GlyphBatch batch, String text, double x, double y, Color color) {
    final scale = 1 / _dpr;
    // Snap to device pixels so glyphs stay crisp.
    var px = (x * _dpr).roundToDouble() / _dpr;
    final py = (y * _dpr).roundToDouble() / _dpr;
    final argb = color.toARGB32();
    for (var i = 0; i < text.length; i++) {
      final code = text.codeUnitAt(i);
      final src = _src[code];
      if (src == null) continue;
      batch._add(scale, px, py, src, argb);
      px += _advance[code]!;
    }
  }

  /// Queues [text] right-aligned to [right].
  void addRight(
    GlyphBatch batch,
    String text,
    double right,
    double y,
    Color color,
  ) => add(batch, text, right - measure(text), y, color);

  /// Queues [text] centred on [centre].
  void addCentred(
    GlyphBatch batch,
    String text,
    double centre,
    double y,
    Color color,
  ) => add(batch, text, centre - measure(text) / 2, y, color);
}

/// Reusable buffers for one [Canvas.drawRawAtlas] call.
class GlyphBatch {
  Float32List _transforms = Float32List(4 * 256);
  Float32List _rects = Float32List(4 * 256);
  Int32List _colors = Int32List(256);
  int _count = 0;

  static final Paint _paint = Paint()..filterQuality = FilterQuality.low;

  void _add(double scale, double x, double y, Float32List src, int argb) {
    if (_count == _colors.length) _grow();
    final o = _count * 4;
    _transforms[o] = scale; // scos
    _transforms[o + 1] = 0; // ssin
    _transforms[o + 2] = x;
    _transforms[o + 3] = y;
    _rects[o] = src[0];
    _rects[o + 1] = src[1];
    _rects[o + 2] = src[2];
    _rects[o + 3] = src[3];
    _colors[_count] = argb;
    _count++;
  }

  void _grow() {
    final capacity = _colors.length * 2;
    _transforms = Float32List(capacity * 4)
      ..setRange(0, _count * 4, _transforms);
    _rects = Float32List(capacity * 4)..setRange(0, _count * 4, _rects);
    _colors = Int32List(capacity)..setRange(0, _count, _colors);
  }

  /// Draws everything queued with [atlas], then empties the batch.
  void draw(Canvas canvas, GlyphAtlas atlas) {
    if (_count == 0) return;
    canvas.drawRawAtlas(
      atlas.image,
      Float32List.sublistView(_transforms, 0, _count * 4),
      Float32List.sublistView(_rects, 0, _count * 4),
      Int32List.sublistView(_colors, 0, _count),
      BlendMode.modulate,
      null,
      _paint,
    );
    _count = 0;
  }
}
