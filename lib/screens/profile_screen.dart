import 'package:material_ui/material_ui.dart';

import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import 'login_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key, this.nombre});

  final String? nombre;

  Future<void> _logout(BuildContext context) async {
    await AuthService().logout();
    if (!context.mounted) {
      return;
    }
    Navigator.of(context).pushAndRemoveUntil(
      AppPage.route(const LoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(title: const Text('Perfil')),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE6F4F1),
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: const Icon(Icons.person_rounded, size: 42, color: AppTheme.teal),
                ),
                const SizedBox(height: 16),
                Text(
                  nombre == null || nombre!.trim().isEmpty ? 'Bienvenido' : 'Hola, ${nombre!.trim()}',
                  style: Theme.of(context).textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                const Text(
                  'Tu sesión está activa en este dispositivo.',
                  style: TextStyle(color: Color(0xFF667085)),
                ),
                const SizedBox(height: 28),
                PressableLogout(onPressed: () => _logout(context)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class PressableLogout extends StatelessWidget {
  const PressableLogout({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.logout_rounded),
        label: const Text('Cerrar sesión'),
      ),
    );
  }
}
