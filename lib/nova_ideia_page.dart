import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class CriarIdeiaPage extends StatefulWidget {
  const CriarIdeiaPage({super.key});

  @override
  State<CriarIdeiaPage> createState() => _CriarIdeiaPageState();
}

class _CriarIdeiaPageState extends State<CriarIdeiaPage> {
  final tituloController = TextEditingController();
  final descricaoController = TextEditingController();
  bool carregando = false;

  Future<void> salvarIdeia() async {
    setState(() => carregando = true);

    var user = FirebaseAuth.instance.currentUser!;

    await FirebaseFirestore.instance.collection('ideias').add({
      'titulo': tituloController.text.trim(),
      'descricao': descricaoController.text.trim(),
      'autorId': user.uid,
      'autorNome': user.displayName ?? "Usuário",
      'createdAt': FieldValue.serverTimestamp(),
    });

    setState(() => carregando = false);

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Criar nova ideia")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: tituloController,
              decoration: const InputDecoration(labelText: "Título"),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: descricaoController,
              maxLines: 5,
              decoration: const InputDecoration(labelText: "Descrição"),
            ),
            const SizedBox(height: 30),
            carregando
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: salvarIdeia,
                    child: const Text("Salvar"),
                  )
          ],
        ),
      ),
    );
  }
}
