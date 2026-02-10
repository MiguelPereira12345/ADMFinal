import 'package:flutter/material.dart';
import 'widgets/login/login_widgets.dart'; // exportar fields, buttons, logotipo, form

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {

  @override
  Widget build(BuildContext context) {
    
    final bg = const Color(0xFFFAF7F4);
    final cardBg = Colors.white;
    final primaryGold = const Color(0xFFA87B05);
    final beige = const Color(0xFFF3EDE7);
    const titleText = 'Clinimolelos';
    const titleStyle = TextStyle(fontSize: 20, fontWeight: FontWeight.w700);



    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,

              
              children: [
                Column(
                  children: [
                        Logotipo(titleText: titleText, titleStyle: titleStyle),
                  ],
                ),
                const SizedBox(height: 24),


                //lógica de login
                LoginForm(bg: bg, cardBg: cardBg, loginColor: primaryGold, recoverColor: beige),
                const SizedBox(height: 28),

              ],
            ),
          ),
        ),
      ),
    );
  }
}
