import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RegistroConteudoPage extends StatefulWidget {
  final DocumentSnapshot? conteudoDoc; // Se for edição, passa o documento

  const RegistroConteudoPage({super.key, this.conteudoDoc});

  @override
  State<RegistroConteudoPage> createState() => _RegistroConteudoPageState();
}

class _RegistroConteudoPageState extends State<RegistroConteudoPage> {
  final TextEditingController tituloController = TextEditingController();
  final TextEditingController descricaoController = TextEditingController();
  final TextEditingController linkController = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  bool _salvando = false;

  @override
  void initState() {
    super.initState();
    // Se for edição, preencher campos com os dados existentes
    if (widget.conteudoDoc != null) {
      final data = widget.conteudoDoc!.data() as Map<String, dynamic>;
      tituloController.text = data['titulo'] ?? '';
      descricaoController.text = data['descricao'] ?? '';
      linkController.text = data['link'] ?? '';
    }
  }

  Future<void> salvarConteudo() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _salvando = true);

    try {
      User? usuario = FirebaseAuth.instance.currentUser;
      String autorNome = "Professor";

      if (usuario != null) {
        var docUsuario = await FirebaseFirestore.instance
            .collection('usuarios')
            .doc(usuario.uid)
            .get();

        if (docUsuario.exists) {
          autorNome = docUsuario.data()?['nome'] ?? "Professor";
        }
      }

      if (widget.conteudoDoc == null) {
        // Criar novo conteúdo
        await FirebaseFirestore.instance.collection('conteudos').add({
          'titulo': tituloController.text.trim(),
          'descricao': descricaoController.text.trim(),
          'link': linkController.text.trim(),
          'criadoEm': FieldValue.serverTimestamp(),
          'autorId': usuario?.uid,
          'autorNome': autorNome,
        });
      } else {
        // Atualizar conteúdo existente
        await FirebaseFirestore.instance
            .collection('conteudos')
            .doc(widget.conteudoDoc!.id)
            .update({
          'titulo': tituloController.text.trim(),
          'descricao': descricaoController.text.trim(),
          'link': linkController.text.trim(),
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.conteudoDoc == null
                ? "✅ Conteúdo salvo com sucesso!"
                : "✅ Conteúdo atualizado com sucesso!"),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ Erro ao salvar: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  InputDecoration _inputStyle(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: Colors.green),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.green, width: 2),
      ),
    );
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
          widget.conteudoDoc == null
              ? "Registrar Conteúdo de Apoio"
              : "Editar Conteúdo de Apoio",
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: tituloController,
                      decoration: _inputStyle("Título", Icons.title),
                      validator: (value) =>
                      value == null || value.isEmpty ? "Informe o título" : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: descricaoController,
                      decoration: _inputStyle("Descrição", Icons.description),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: linkController,
                      decoration: _inputStyle(
                          "Link (YouTube, PDF, artigo...)", Icons.link),
                      validator: (value) =>
                      value == null || value.isEmpty ? "Informe o link" : null,
                    ),
                    const SizedBox(height: 24),
                    _salvando
                        ? const CircularProgressIndicator(color: Colors.green)
                        : ElevatedButton.icon(
                      onPressed: salvarConteudo,
                      icon: const Icon(Icons.save, color: Colors.white),
                      label: Text(
                        widget.conteudoDoc == null
                            ? "Salvar Conteúdo"
                            : "Atualizar Conteúdo",
                        style: const TextStyle(
                            color: Colors.white, fontSize: 18),
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
          ),
        ),
      ),
    );
  }
}
