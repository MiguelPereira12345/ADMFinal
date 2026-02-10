import 'package:flutter/material.dart';

import '../../app/session_scope.dart';
import '../app/app_card.dart';
import '../app/app_text_field.dart';
import '../app/app_button.dart';
import '../app/app_section_title.dart';

//lógica de código do login

class LoginForm extends StatefulWidget {
  final Color bg;
  final Color cardBg;
  final Color loginColor;
  final Color recoverColor;

  const LoginForm({
    super.key,
    required this.bg,
    required this.cardBg,
    required this.loginColor,
    required this.recoverColor,
  });

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

//dispose limpa os dados
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

//email textfield é necessário não estar nulo para o login, ou envia a mensagem abaixo
  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final senha = _passwordController.text;
    if (email.isEmpty || senha.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Preencha email e palavra-passe')));
      return;
    }

    setState(() => _isLoading = true);

    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    try {
      final session = SessionScope.of(context);
      await session.loginPaciente(email: email, senha: senha);
      if (!mounted) return;
      navigator.pushReplacementNamed('/menu');
    } on Exception catch (err) {
      if (!mounted) return;
      String msg = err.toString();
      if (msg.contains('SocketException') || msg.contains('Timeout')) {
        msg = 'Não foi possível conectar ao servidor. Tente novamente mais tarde.';
      }
      messenger.showSnackBar(SnackBar(content: Text('Erro: $msg')));
    } catch (err) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text('Erro inesperado: ${err.toString()}')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }




//layout iniciar sessão
  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(18),
      borderRadius: 14,
      color: widget.cardBg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AppSectionTitle('Iniciar sessão'),
          const SizedBox(height: 12),

          AppTextField(
            controller: _emailController,
            hintText: 'Email',
            prefixIcon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            fillColor: widget.bg,
          ),
          const SizedBox(height: 12),

          AppTextField(
            controller: _passwordController,
            hintText: 'Palavra-passe',
            prefixIcon: Icons.lock_outline,
            obscureText: true,
            fillColor: widget.bg,
          ),
          const SizedBox(height: 16),

          AppButton(
            label: 'Entrar',
            isLoading: _isLoading,
            onPressed: _handleLogin,
            backgroundColor: widget.loginColor,
          ),
          const SizedBox(height: 12),

          AppButton(
            label: 'Recuperar Palavra-passe',
            onPressed: () {
               ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Recuperar Palavra-passe')),
              );
            },
            backgroundColor: widget.recoverColor,
            foregroundColor: Colors.black87,
          ),
        ],
      ),
    );
  }
}
