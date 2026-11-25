import 'package:material_ui/material_ui.dart';

import 'screens/home_shell.dart';
import 'screens/login_screen.dart';
import 'services/auth_service.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const GotaAGotaApp());
}

class GotaAGotaApp extends StatelessWidget {
  const GotaAGotaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gota a Gota',
      theme: AppTheme.light(),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late final Future<bool> _session = _checkSession();

  Future<bool> _checkSession() async {
    try {
      return await AuthService().hasSession();
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _session,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF0D7377), Color(0xFF14919B)],
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.all(Radius.circular(32)),
                        boxShadow: [
                          BoxShadow(color: Color(0x33000000), blurRadius: 24, offset: Offset(0, 12)),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.all(Radius.circular(32)),
                        child: Image(
                          image: AssetImage('assets/icon/app_icon.png'),
                          width: 108,
                          height: 108,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    SizedBox(height: 22),
                    Text(
                      'Gota a Gota',
                      style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w700),
                    ),
                    SizedBox(height: 18),
                    SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFC6A15B)),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
        if (snapshot.data == true) {
          return const HomeShell();
        }
        return const LoginScreen();
      },
    );
  }
}
