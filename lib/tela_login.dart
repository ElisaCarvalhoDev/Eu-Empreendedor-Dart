import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'home.dart';
import 'cadastroUsuarios.dart';
import 'esquecisenha.dart';
import 'globals.dart' as globals;
import 'package:cloud_firestore/cloud_firestore.dart';

class TelaLogin extends StatelessWidget {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController senhaController = TextEditingController();

  TelaLogin({super.key});

  /// 🔐 Login do usuário
 Future<void> login(BuildContext context) async {
  try {
    final emailDigitado = emailController.text.trim().toLowerCase();

    UserCredential userCredential = await FirebaseAuth.instance
        .signInWithEmailAndPassword(
      email: emailDigitado,
      password: senhaController.text.trim(),
    );

    globals.userId = userCredential.user?.uid;

    DocumentSnapshot doc = await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(globals.userId)
        .get();

    if (!doc.exists) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Erro'),
          content: const Text('Conta não encontrada no banco.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    final data = doc.data() as Map<String, dynamic>;
    bool emailVerificado = data['emailVerificado'] ?? false;

    // Professores reais
    bool isProfessor = emailDigitado.endsWith('@ifsuldeminas.edu.br');

    // Professores testes (gmail)
    List<String> professoresTeste = [
      "prof201@gmail.com",
      "prof.teste02@gmail.com",
      "outroprof@gmail.com",
    ];

    bool isProfessorTeste = professoresTeste.contains(emailDigitado);

    // Se for professor real E não for teste E não tiver verificado = bloqueia
    if (isProfessor && !isProfessorTeste && !emailVerificado) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Erro'),
          content: const Text(
              'Professor: verifique seu e-mail antes de entrar. Clique no link enviado.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    // ---------- LOGIN LIBERADO ----------
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) =>
            HomePage(userName: userCredential.user?.email ?? ''),
      ),
    );
  } on FirebaseAuthException catch (e) {
    String message;

    if (e.code == 'user-not-found') {
      message = 'Nenhum usuário encontrado para esse e-mail.';
    } else if (e.code == 'wrong-password') {
      message = 'Senha incorreta.';
    } else {
      message = 'Erro desconhecido. Tente novamente.';
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Erro'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('assets/logo_eu_empreendedor.png', height: 230),
                const SizedBox(height: 30),

                /// CAMPO DE EMAIL
                TextField(
                  controller: emailController,
                  decoration: InputDecoration(
                    hintText: 'E-mail',
                    filled: true,
                    fillColor: Colors.grey[300],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                /// CAMPO DE SENHA
                TextField(
                  controller: senhaController,
                  obscureText: true,
                  decoration: InputDecoration(
                    hintText: 'Senha',
                    filled: true,
                    fillColor: Colors.grey[300],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),

                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EsqueciSenhaPage(),
                        ),
                      );
                    },
                    child: const Text(
                      'Esqueceu a senha?',
                      style: TextStyle(color: Colors.green),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                /// BOTÃO DE ENTRAR
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: () => login(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF41E16E),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Entrar',
                      style: TextStyle(fontSize: 26, color: Colors.white),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                /// TEXTO "cadastre-se"
                RichText(
                  text: TextSpan(
                    text: 'Ainda não possui cadastro? ',
                    style: const TextStyle(color: Colors.black),
                    children: [
                      TextSpan(
                        text: 'Cadastre-se',
                        style: const TextStyle(
                          color: Colors.green,
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.bold,
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const CadastroPage(),
                              ),
                            );
                          },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                Image.asset('assets/logo_ifsuldeminas.png', height: 60),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
