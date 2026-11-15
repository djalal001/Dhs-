import 'package:flutter/material.dart';

/// The exact Decisions mark from TraderDesk_Decisions_Logo_Concept.html,
/// recreated as a small vector painter for crisp rendering at any size.
class DecisionSectionLogo extends StatelessWidget {
  const DecisionSectionLogo({
    super.key,
    this.size = 26,
    this.label = 'Decisions logo',
  });

  final double size;
  final String label;

  @override
  Widget build(BuildContext context) => Semantics(
        image: true,
        label: label,
        child: SizedBox.square(
          dimension: size,
          child: CustomPaint(painter: _DecisionSectionLogoPainter()),
        ),
      );
}

class _DecisionSectionLogoPainter extends CustomPainter {
  static const Color _decision = Color(0xFFC6A071);
  static const Color _metalLight = Color(0xFFE8D1A9);
  static const Color _metalDeep = Color(0xFFB88D59);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 80, size.height / 80);

    final tileRect = RRect.fromLTRBR(
      5.5,
      5.5,
      74.5,
      74.5,
      const Radius.circular(19),
    );
    canvas.drawRRect(
      tileRect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment(-1.0, -1.0),
          end: Alignment(1.0, 1.0),
          colors: [Color(0xFF302B3A), Color(0xFF171D28)],
        ).createShader(const Rect.fromLTWH(10, 8, 58, 64)),
    );
    canvas.drawRRect(
      tileRect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = _decision.withValues(alpha: .48),
    );

    final metalShader = const LinearGradient(
      begin: Alignment(-1, -1),
      end: Alignment(1, 1),
      colors: [_metalLight, _metalDeep],
    ).createShader(const Rect.fromLTWH(17, 14, 45, 48));

    final stem = Path()
      ..moveTo(40, 63)
      ..lineTo(40, 51);
    canvas.drawPath(
      stem,
      Paint()
        ..shader = metalShader
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.6
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(const Offset(40, 64), 3.1, Paint()..color = _decision);

    final branches = Path()
      ..moveTo(29, 33)
      ..cubicTo(23, 30, 19.5, 25.8, 17.8, 19.5)
      ..moveTo(51, 33)
      ..cubicTo(57, 30, 60.5, 25.8, 62.2, 19.5)
      ..moveTo(40, 25)
      ..lineTo(40, 15.5);
    canvas.drawPath(
      branches,
      Paint()
        ..color = _decision.withValues(alpha: .78)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round,
    );

    final nodePaint = Paint()
      ..color = const Color(0xFF232431)
      ..style = PaintingStyle.fill;
    final nodeBorder = Paint()
      ..color = _decision
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    for (final center in const [Offset(17, 16), Offset(63, 16)]) {
      canvas.drawCircle(center, 3.25, nodePaint);
      canvas.drawCircle(center, 3.25, nodeBorder);
    }
    canvas.drawCircle(
      const Offset(40, 13),
      3.1,
      Paint()..color = _metalLight,
    );

    final diamond = Path()
      ..moveTo(40, 24)
      ..lineTo(52, 36.5)
      ..lineTo(40, 49)
      ..lineTo(28, 36.5)
      ..close();
    canvas.drawPath(diamond, Paint()..color = const Color(0xFF3A302C));
    canvas.drawPath(
      diamond,
      Paint()
        ..shader = metalShader
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.35
        ..strokeJoin = StrokeJoin.round,
    );

    final check = Path()
      ..moveTo(34.7, 36.6)
      ..lineTo(38.5, 40.2)
      ..lineTo(45.6, 32.9);
    canvas.drawPath(
      check,
      Paint()
        ..color = const Color(0xFFF0DDBE)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.45
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    final fineDetails = Path()
      ..moveTo(12, 58.5)
      ..lineTo(16, 58.5)
      ..moveTo(64, 58.5)
      ..lineTo(68, 58.5);
    canvas.drawPath(
      fineDetails,
      Paint()
        ..color = _decision.withValues(alpha: .42)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..strokeCap = StrokeCap.round,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _DecisionSectionLogoPainter oldDelegate) => false;
}
