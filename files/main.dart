import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

void main() => runApp(const MyApp());

// ---------- Валидаторы ----------
final _nameRe = RegExp(r'^[А-Яа-яЁёҢңӨөҮү]{3,}$');
final _loginRe = RegExp(r'^[a-z]{3,}$');

String? vName(String v) =>
    _nameRe.hasMatch(v.trim()) ? null : 'Кирилл тамгасы, эң аз 3 тамга';
String? vPhone(String v) =>
    v.startsWith('+996') ? null : '+996 менен башталышы керек';
String? vLogin(String v) =>
    _loginRe.hasMatch(v) ? null : 'Латын, кичине тамга, эң аз 3 тамга';
String? vPass(String v) => v.length >= 8 ? null : 'Эң аз 8 элемент';

// ---------- Bloc ----------
abstract class AuthEvent {}

class RegisterSubmitted extends AuthEvent {
  final String first, last, phone, login, pass, pass2;
  RegisterSubmitted(
      this.first, this.last, this.phone, this.login, this.pass, this.pass2);
}

class LoginSubmitted extends AuthEvent {
  final String login, pass;
  LoginSubmitted(this.login, this.pass);
}

class AuthState {
  final Map<String, String> errors;
  final bool success;
  const AuthState({this.errors = const {}, this.success = false});
}

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc() : super(const AuthState()) {
    on<RegisterSubmitted>(_onRegister);
    on<LoginSubmitted>(_onLogin);
  }

  void _onRegister(RegisterSubmitted e, Emitter<AuthState> emit) {
    final checks = <String, String?>{
      'first': vName(e.first),
      'last': vName(e.last),
      'phone': vPhone(e.phone),
      'login': vLogin(e.login),
      'pass': vPass(e.pass),
      'pass2': e.pass == e.pass2 ? null : 'Сыр сөздөр дал келбейт',
    };
    emit(_result(checks));
  }

  void _onLogin(LoginSubmitted e, Emitter<AuthState> emit) {
    final checks = <String, String?>{
      'login': vLogin(e.login),
      'pass': vPass(e.pass),
    };
    emit(_result(checks));
  }

  AuthState _result(Map<String, String?> checks) {
    final errors = <String, String>{};
    checks.forEach((k, v) {
      if (v != null) errors[k] = v;
    });
    return AuthState(errors: errors, success: errors.isEmpty);
  }
}

// ---------- Общие виджеты ----------
class AuthHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  const AuthHeader(this.title, this.subtitle, {super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const CircleAvatar(
          radius: 45,
          backgroundColor: Colors.blue,
          child: Icon(Icons.school, size: 50, color: Colors.white),
        ),
        const SizedBox(height: 16),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(subtitle, style: const TextStyle(color: Colors.grey)),
        const SizedBox(height: 24),
      ],
    );
  }
}

class AppField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? error;
  final bool obscure;
  final TextInputType? keyboardType;

  const AppField({
    super.key,
    required this.controller,
    required this.label,
    this.error,
    this.obscure = false,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          errorText: error,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}

// ---------- Приложение ----------
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/login',
      routes: {
        '/login': (_) => const LoginPage(),
        '/register': (_) => const RegisterPage(),
      },
    );
  }
}

// ---------- Экран входа ----------
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _login = TextEditingController();
  final _pass = TextEditingController();

  @override
  void dispose() {
    _login.dispose();
    _pass.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AuthBloc(),
      child: Scaffold(
        body: SafeArea(
          child: BlocConsumer<AuthBloc, AuthState>(
            listener: (context, state) {
              if (state.success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Ийгиликтүү!')),
                );
              }
            },
            builder: (context, state) {
              return Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      const AuthHeader('Сынакка кош келиңиз!',
                          'Сынак тапшыруу үчүн платформага кириңиз'),
                      AppField(
                        controller: _login,
                        label: 'Логин',
                        error: state.errors['login'],
                      ),
                      AppField(
                        controller: _pass,
                        label: 'Сыр сөз',
                        error: state.errors['pass'],
                        obscure: true,
                      ),
                      const SizedBox(height: 4),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: () => context
                              .read<AuthBloc>()
                              .add(LoginSubmitted(_login.text, _pass.text)),
                          child: const Text('Кирүү'),
                        ),
                      ),
                      TextButton(
                        onPressed: () =>
                            Navigator.pushNamed(context, '/register'),
                        child: const Text('Аккаунт жокпу? Катталыңыз'),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

// ---------- Экран регистрации ----------
class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _first = TextEditingController();
  final _last = TextEditingController();
  final _phone = TextEditingController(text: '+996');
  final _login = TextEditingController();
  final _pass = TextEditingController();
  final _pass2 = TextEditingController();

  @override
  void dispose() {
    for (final c in [_first, _last, _phone, _login, _pass, _pass2]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AuthBloc(),
      child: Scaffold(
        body: SafeArea(
          child: BlocConsumer<AuthBloc, AuthState>(
            listener: (context, state) {
              if (state.success) {
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
            builder: (context, state) {
              return SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const AuthHeader(
                        'Катталуу', 'Төмөндөгү маалыматты толтуруңуз'),
                    AppField(
                        controller: _first,
                        label: 'Аты',
                        error: state.errors['first']),
                    AppField(
                        controller: _last,
                        label: 'Фамилия',
                        error: state.errors['last']),
                    AppField(
                        controller: _phone,
                        label: 'Телефон номери',
                        error: state.errors['phone'],
                        keyboardType: TextInputType.phone),
                    AppField(
                        controller: _login,
                        label: 'Логин',
                        error: state.errors['login']),
                    AppField(
                        controller: _pass,
                        label: 'Сыр сөз',
                        error: state.errors['pass'],
                        obscure: true),
                    AppField(
                        controller: _pass2,
                        label: 'Сыр сөздү кайрадан жазыңыз',
                        error: state.errors['pass2'],
                        obscure: true),
                    const SizedBox(height: 4),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () => context.read<AuthBloc>().add(
                              RegisterSubmitted(_first.text, _last.text,
                                  _phone.text, _login.text, _pass.text,
                                  _pass2.text),
                            ),
                        child: const Text('Катталуу'),
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pushNamed(context, '/login'),
                      child: const Text('Аккаунт барбы? Кириңиз'),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
