import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'tela_login.dart';

class CadastroPage extends StatefulWidget {
  const CadastroPage({super.key});

  @override
  State<CadastroPage> createState() => _CadastroPageState();
}

class _CadastroPageState extends State<CadastroPage> {
  bool isAluno = true;

  final nomeController = TextEditingController();
  final emailController = TextEditingController();
  final senhaController = TextEditingController();
  final confirmaSenhaController = TextEditingController();

  bool isEmailInstitucional(String email) {
    return email.toLowerCase().endsWith('@ifsuldeminas.edu.br');
  }

  Future<void> cadastrarUsuario() async {
    if (senhaController.text.trim() != confirmaSenhaController.text.trim()) {
      _mostrarErro("As senhas não coincidem.");
      return;
    }

    final email = emailController.text.trim();
    final senha = senhaController.text.trim();
    final nome = nomeController.text.trim();
    final bool isInstitucional = email.endsWith("@ifsuldeminas.edu.br");

    try {
      // Criar usuário no Authentication
      UserCredential cred = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: senha);

      // Enviar verificação se for institucional
      if (isInstitucional) {
        await cred.user!.sendEmailVerification();
      }

      // Criar documento no Firestore
      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(cred.user!.uid)
          .set({
        'nome': nome,
        'email': email,
        'tipo': isAluno ? 'Aluno' : 'Professor',
        'criadoEm': FieldValue.serverTimestamp(),
        'emailVerificado': !isInstitucional, // se institucional = false
      });

      // Mensagem especial
      if (isInstitucional) {
        _mostrarErro(
          "Enviamos um e-mail de verificação.\n"
          "Confirme seu e-mail institucional antes de fazer login.",
        );
      }

      // Ir para a tela de login
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => TelaLogin()),
      );
    } on FirebaseAuthException catch (e) {
      String mensagem = "Erro ao cadastrar.";

      if (e.code == 'email-already-in-use') {
        mensagem = "Esse e-mail já está em uso.";
      } else if (e.code == 'weak-password') {
        mensagem = "A senha deve ter pelo menos 6 caracteres.";
      }

      _mostrarErro(mensagem);
    } catch (e) {
      _mostrarErro("Erro inesperado: $e");
    }
  }

  void _mostrarErro(String mensagem) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Erro"),
        content: Text(mensagem),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          )
        ],
      ),
    );
  }

  void _mostrarAviso(String mensagem) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Aviso"),
        content: Text(mensagem),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          )
        ],
      ),
    );
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
              children: [
                Image.asset(
                  'assets/logo_eu_empreendedor.png',
                  height: 120,
                ),
                const SizedBox(height: 10),

                // Nome
                campoTexto(
                  'Nome Completo',
                  controller: nomeController,
                ),
                const SizedBox(height: 12),

                // E-mail
                campoTexto(
                  'E-mail',
                  controller: emailController,
                ),
                const SizedBox(height: 12),

                // Senha
                campoTexto(
                  'Senha',
                  isPassword: true,
                  controller: senhaController,
                ),
                const SizedBox(height: 12),

                // Confirmação de senha
                campoTexto(
                  'Confirme sua senha',
                  isPassword: true,
                  controller: confirmaSenhaController,
                ),
                const SizedBox(height: 20),

                // Tipo de usuário
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Tipo de Usuário',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 10),

                Row(
                  children: [
                    // ALUNO
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => isAluno = true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: isAluno ? Colors.green : Colors.white,
                            border: Border.all(color: Colors.green),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Center(
                            child: Text(
                              'Aluno',
                              style: TextStyle(
                                color: isAluno ? Colors.white : Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // PROFESSOR
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => isAluno = false),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: !isAluno ? Colors.green : Colors.white,
                            border: Border.all(color: Colors.green),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Center(
                            child: Text(
                              'Professor',
                              style: TextStyle(
                                color: !isAluno ? Colors.white : Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 30),

                // Botão cadastrar
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: cadastrarUsuario,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF41E16E),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      elevation: 4,
                    ),
                    child: const Text(
                      'Cadastrar',
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Link para login
                RichText(
                  text: TextSpan(
                    text: 'Já tem conta? ',
                    style: const TextStyle(color: Colors.black),
                    children: [
                      TextSpan(
                        text: 'Entrar',
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
                                builder: (_) => TelaLogin(),
                              ),
                            );
                          },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                Image.asset(
                  'assets/logo_ifsuldeminas.png',
                  height: 40,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget campoTexto(
    String label, {
    bool isPassword = false,
    required TextEditingController controller,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
        ),
      ),
    );
  }
}
