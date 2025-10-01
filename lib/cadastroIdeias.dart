import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RegistroIdeiaPage extends StatefulWidget {
  final DocumentSnapshot? ideiaDoc; // Se for edição, passa o documento

  const RegistroIdeiaPage({super.key, this.ideiaDoc});

  @override
  State<RegistroIdeiaPage> createState() => _RegistroIdeiaPageState();
}

class _RegistroIdeiaPageState extends State<RegistroIdeiaPage> {
  final TextEditingController tituloController = TextEditingController();
  final TextEditingController descricaoController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Se for edição, preencher campos com os dados existentes
    if (widget.ideiaDoc != null) {
      final data = widget.ideiaDoc!.data() as Map<String, dynamic>;
      tituloController.text = data['titulo'] ?? '';
      descricaoController.text = data['descricao'] ?? '';
    }
  }

  Future<void> salvarIdeia() async {
    if (tituloController.text.isEmpty || descricaoController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Preencha título e descrição")),
      );
      return;
    }

    try {
      User? usuario = FirebaseAuth.instance.currentUser;

      if (widget.ideiaDoc == null) {
        // Criar nova ideia
        await FirebaseFirestore.instance.collection('ideias').add({
          'titulo': tituloController.text,
          'descricao': descricaoController.text,
          'criadoEm': FieldValue.serverTimestamp(),
          'autorId': usuario?.uid,
          'autorNome': usuario?.displayName ?? usuario?.email ?? 'Anônimo',
        });
      } else {
        // Atualizar ideia existente
        await FirebaseFirestore.instance
            .collection('ideias')
            .doc(widget.ideiaDoc!.id)
            .update({
          'titulo': tituloController.text,
          'descricao': descricaoController.text,
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.ideiaDoc == null
              ? "Ideia cadastrada com sucesso!"
              : "Ideia atualizada com sucesso!"),
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erro ao salvar: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        elevation: 4,
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.green),
        title: Text(
          widget.ideiaDoc == null ? "Registrar Ideia" : "Editar Ideia",
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            children: [
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      TextField(
                        controller: tituloController,
                        decoration: InputDecoration(
                          labelText: "Título da Ideia",
                          prefixIcon: const Icon(Icons.title, color: Colors.green),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: descricaoController,
                        maxLines: 5,
                        decoration: InputDecoration(
                          labelText: "Descrição da Ideia",
                          prefixIcon: const Icon(Icons.description, color: Colors.green),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: salvarIdeia,
                icon: const Icon(Icons.check, color: Colors.white),
                label: Text(
                  widget.ideiaDoc == null ? "Salvar Ideia" : "Atualizar Ideia",
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  minimumSize: const Size(double.infinity, 55),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
