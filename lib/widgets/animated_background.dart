import 'dart:math';
import 'package:flutter/material.dart';

class AnimatedBackground extends StatefulWidget {
  @override
  _AnimatedBackgroundState createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground> with TickerProviderStateMixin {
  late List<ParticleModel> particles;
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    particles = List.generate(20, (index) => ParticleModel());
    _controller = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: ParticlePainter(
            particles: particles,
            animation: _controller,
          ),
          child: Container(),
        );
      },
    );
  }
}

class ParticleModel {
  late Offset position;
  late double speed;
  late double theta;
  late double radius;

  ParticleModel() {
    Random random = Random();
    position = Offset(
      random.nextDouble() * 400,
      random.nextDouble() * 800,
    );
    speed = 1.0 + random.nextDouble() * 2.0;
    theta = random.nextDouble() * 2 * pi;
    radius = 2.0 + random.nextDouble() * 3.0;
  }
}

class ParticlePainter extends CustomPainter {
  final List<ParticleModel> particles;
  final Animation<double> animation;

  ParticlePainter({
    required this.particles,
    required this.animation,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..style = PaintingStyle.fill;

    particles.forEach((particle) {
      var progress = animation.value;
      var dx = particle.speed * cos(particle.theta) * progress * 100;
      var dy = particle.speed * sin(particle.theta) * progress * 100;

      var offset = Offset(
        (particle.position.dx + dx) % size.width,
        (particle.position.dy + dy) % size.height,
      );

      canvas.drawCircle(offset, particle.radius, paint);
    });
  }

  @override
  bool shouldRepaint(ParticlePainter oldDelegate) => true;
}