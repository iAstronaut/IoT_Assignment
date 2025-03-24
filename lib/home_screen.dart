import 'package:flutter/material.dart';
import 'package:heart_rate_monitor/about_page.dart';
import 'package:heart_rate_monitor/help_page.dart';
import 'package:heart_rate_monitor/history_page.dart';
import 'package:heart_rate_monitor/measure_page.dart';
import 'package:heart_rate_monitor/services/auth_service.dart';
import 'package:heart_rate_monitor/login_page.dart';
import 'package:heart_rate_monitor/widgets/glass_card.dart';
import 'package:heart_rate_monitor/widgets/animated_background.dart';
import 'package:heart_rate_monitor/widgets/gradient_button.dart';
import 'package:heart_rate_monitor/theme/app_theme.dart';
import 'package:flutter_svg/flutter_svg.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService.currentUser;
    var size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: <Widget>[
          Container(
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
            ),
          ),
          AnimatedBackground(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.defaultPadding),
              child: Column(
                children: <Widget>[
                  GlassCard(
                    padding: const EdgeInsets.all(AppTheme.defaultPadding),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Text(
                              'Welcome back,',
                              style: AppTheme.subheadingStyle,
                            ),
                            Text(
                              user?.name ?? 'User',
                              style: AppTheme.headingStyle,
                            ),
                          ],
                        ),
                        GradientButton(
                          icon: Icons.logout,
                          text: 'Logout',
                          onPressed: () async {
                            await AuthService.logout();
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(
                                builder: (context) => LoginPage(),
                              ),
                            );
                          },
                          gradient: AppTheme.secondaryGradient,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppTheme.defaultPadding * 1.5),
                  Expanded(
                    child: ScaleTransition(
                      scale: _scaleAnimation,
                      child: GridView.count(
                        crossAxisCount: 2,
                        childAspectRatio: .85,
                        crossAxisSpacing: AppTheme.defaultPadding,
                        mainAxisSpacing: AppTheme.defaultPadding,
                        children: <Widget>[
                          CategoryCard(
                            title: "Measure",
                            icon: "assets/images/heart.svg",
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => MeasurePage()),
                            ),
                          ),
                          CategoryCard(
                            title: "History",
                            icon: "assets/images/list.svg",
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => HistoryPage()),
                            ),
                          ),
                          CategoryCard(
                            title: "Help",
                            icon: "assets/images/instructions.svg",
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => HelpPage()),
                            ),
                          ),
                          CategoryCard(
                            title: "About",
                            icon: "assets/images/editor.svg",
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => AboutPage()),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}

class CategoryCard extends StatefulWidget {
  final String title;
  final String icon;
  final Function() onTap;

  const CategoryCard({
    Key? key,
    required this.title,
    required this.icon,
    required this.onTap,
  }) : super(key: key);

  @override
  _CategoryCardState createState() => _CategoryCardState();
}

class _CategoryCardState extends State<CategoryCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
    _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    _controller.reverse();
    widget.onTap();
  }

  void _onTapCancel() {
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: GlassCard(
          padding: const EdgeInsets.all(AppTheme.defaultPadding),
          gradient: AppTheme.secondaryGradient,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              SvgPicture.asset(
                widget.icon,
                height: 80,
                color: Colors.white,
              ),
              const SizedBox(height: AppTheme.defaultPadding),
              Text(
                widget.title,
                textAlign: TextAlign.center,
                style: AppTheme.buttonTextStyle,
              ),
            ],
          ),
        ),
      ),
    );
  }
}