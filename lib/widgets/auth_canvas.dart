import 'package:material_ui/material_ui.dart';

class AuthCanvas extends StatelessWidget {
  const AuthCanvas({super.key, required this.child, this.onBack});

  final Widget child;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFE7F3F3), Color(0xFFF8F9FA), Color(0xFFF3F6F6)],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              if (onBack != null)
                Positioned(
                  left: 8,
                  top: 4,
                  child: IconButton(
                    onPressed: onBack,
                    icon: const Icon(Icons.arrow_back_rounded),
                    color: const Color(0xFF0B3D34),
                  ),
                ),
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: child,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class BrandHeader extends StatefulWidget {
  const BrandHeader({super.key, required this.subtitle});

  final String subtitle;

  @override
  State<BrandHeader> createState() => _BrandHeaderState();
}

class _BrandHeaderState extends State<BrandHeader> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  )..forward();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(parent: _controller, curve: Curves.easeOutBack);
    return Column(
      children: [
        FadeTransition(
          opacity: CurvedAnimation(parent: _controller, curve: Curves.easeOut),
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.82, end: 1).animate(curved),
            child: Container(
              width: 108,
              height: 108,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(32),
                boxShadow: const [
                  BoxShadow(color: Color(0x330D7377), blurRadius: 28, offset: Offset(0, 14)),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Image.asset('assets/icon/app_icon.png', fit: BoxFit.cover),
            ),
          ),
        ),
        const SizedBox(height: 22),
        Text(
          'Gota a Gota',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 8),
        Text(
          widget.subtitle,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: const Color(0xFF667085)),
        ),
      ],
    );
  }
}
