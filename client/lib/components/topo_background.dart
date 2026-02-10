import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:functional_widget_annotation/functional_widget_annotation.dart';
part "topo_background.g.dart";

@hwidget
Widget topoBackground(
  BuildContext context, {
  Color foreground = const Color.fromARGB(255, 64, 255, 50),
  double scale = 1.7,
  double speed = 0.5,
}) {
  final program = useState<FragmentProgram?>(null);
  final tickerProvider = useSingleTickerProvider();
  final ticker = useRef<Ticker?>(null);
  final elapsedSeconds = useState(0.0);

  void loadShader() async {
    program.value = await FragmentProgram.fromAsset('assets/shaders/perlin_noise.frag');
  }

  useEffect(() {
    loadShader();
    return;
  }, []);

  useEffect(() {
    ticker.value = tickerProvider.createTicker((elapsed) {
      elapsedSeconds.value = elapsed.inMilliseconds / 1000.0;
    })..start();

    return () => ticker.value?.dispose();
  }, [tickerProvider]);

  if (program.value == null) {
    return const SizedBox.expand();
  }

  return CustomPaint(
    painter: ShaderPainter(
      program.value!,
      elapsedSeconds.value,
      foreground,
      scale,
      speed,
    ),
    size: Size.infinite,
  );
}

class ShaderPainter extends CustomPainter {
  final FragmentProgram program;
  final double _elapsedSeconds;
  final Color foreground;
  final double scale;
  final double speed;

  ShaderPainter(
    this.program,
    this._elapsedSeconds,
    this.foreground,
    this.scale,
    this.speed,
  );

  @override
  void paint(Canvas canvas, Size size) {
    final shader = program.fragmentShader();

    shader.setFloat(0, _elapsedSeconds);

    shader.setFloat(1, size.width);
    shader.setFloat(2, size.height);

    shader.setFloat(3, foreground.r);
    shader.setFloat(4, foreground.g);
    shader.setFloat(5, foreground.b);

    shader.setFloat(6, scale);
    shader.setFloat(7, speed);

    canvas.drawRect(Offset.zero & size, Paint()..shader = shader);
  }

  @override
  bool shouldRepaint(_) => true;
}
