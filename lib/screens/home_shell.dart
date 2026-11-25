import 'package:material_ui/material_ui.dart';

import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import 'dashboard_screen.dart';
import 'lista_prestamos_screen.dart';
import 'login_screen.dart';
import 'profile_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;
  int _loansReload = 0;
  String? _nombre;

  @override
  void initState() {
    super.initState();
    _loadNombre();
  }

  Future<void> _loadNombre() async {
    try {
      final nombre = await AuthService().nombreSesion();
      if (!mounted) {
        return;
      }
      setState(() => _nombre = nombre);
    } on AuthException {
      await AuthService().logout();
      if (!mounted) {
        return;
      }
      Navigator.of(context).pushAndRemoveUntil(
        AppPage.route(const LoginScreen()),
        (_) => false,
      );
    } catch (_) {
      // Sin nombre se muestra el saludo genérico.
    }
  }

  void _openLoans() {
    setState(() {
      _index = 1;
      _loansReload++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          DashboardScreen(
            nombre: _nombre,
            onSeeAll: _openLoans,
            onLoansChanged: () => setState(() => _loansReload++),
          ),
          ListaPrestamosScreen(reloadToken: _loansReload),
          ProfileScreen(nombre: _nombre),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) {
          setState(() {
            _index = value;
            if (value == 1) {
              _loansReload++;
            }
          });
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.space_dashboard_outlined), selectedIcon: Icon(Icons.space_dashboard_rounded), label: 'Inicio'),
          NavigationDestination(icon: Icon(Icons.account_balance_wallet_outlined), selectedIcon: Icon(Icons.account_balance_wallet_rounded), label: 'Préstamos'),
          NavigationDestination(icon: Icon(Icons.person_outline_rounded), selectedIcon: Icon(Icons.person_rounded), label: 'Perfil'),
        ],
      ),
    );
  }
}
