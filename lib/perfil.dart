import 'package:flutter/material.dart';
import 'globals.dart' as globals;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'cadastroOportunidades.dart';
import 'cadastroIdeias.dart';
import 'cadastroConteudoApoio.dart';
import 'tela_login.dart'; // Importar a tela de login

class PerfilPage extends StatefulWidget {
  const PerfilPage({super.key});

  @override
  State<PerfilPage> createState() => _PerfilPageState();
}

class _PerfilPageState extends State<PerfilPage> {
  User? user = FirebaseAuth.instance.currentUser;
  File? _profileImage;
  String _userName = 'Usuário';

  final CollectionReference oportunidadesCollection =
      FirebaseFirestore.instance.collection('oportunidade');
  final CollectionReference ideiasCollection =
      FirebaseFirestore.instance.collection('ideias');
  final CollectionReference conteudosCollection =
      FirebaseFirestore.instance.collection('conteudos');

  @override
  void initState() {
    super.initState();
    _loadUserName();
  }

  // Buscar nome do usuário no Firestore
  Future<void> _loadUserName() async {
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(user!.uid)
          .get();

      if (doc.exists) {
        setState(() {
          _userName = doc['nome'] ?? 'Usuário';
        });
      } else if (user?.displayName != null && user!.displayName!.isNotEmpty) {
        setState(() {
          _userName = user!.displayName!;
        });
      }
    }
  }

  // Escolher imagem de perfil
  Future<void> _pickProfileImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });
    }
  }

  // Redirecionar para página de edição
  Future<void> _editPost(DocumentSnapshot doc, String tipo) async {
    if (doc['autorId'] != user?.uid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Você não tem permissão para editar este post.")),
      );
      return;
    }

    if (tipo == 'Oportunidade') {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => RegistroOportunidadePage(oportunidadeDoc: doc),
        ),
      );
    } else if (tipo == 'Ideia') {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => RegistroIdeiaPage(ideiaDoc: doc),
        ),
      );
    } else if (tipo == 'Conteudo') {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => RegistroConteudoPage(conteudoDoc: doc),
        ),
      );
    }
  }

  // Excluir post com confirmação
  Future<void> _deletePost(DocumentSnapshot doc, String tipo) async {
    bool confirmar = false;

    confirmar = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Confirmação'),
            content: Text('Tem certeza que deseja excluir este $tipo?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Excluir'),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmar) return;

    try {
      if (tipo == 'Oportunidade') {
        await oportunidadesCollection.doc(doc.id).delete();
      } else if (tipo == 'Ideia') {
        await ideiasCollection.doc(doc.id).delete();
      } else if (tipo == 'Conteudo') {
        await conteudosCollection.doc(doc.id).delete();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erro ao excluir $tipo: $e")),
      );
    }
  }

  // Stream genérica
  Stream<QuerySnapshot> _getUserPostsStream(String tipo) {
    if (user == null) return const Stream.empty();

    CollectionReference collection;
    if (tipo == 'Oportunidade') {
      collection = oportunidadesCollection;
    } else if (tipo == 'Ideia') {
      collection = ideiasCollection;
    } else {
      collection = conteudosCollection;
    }

    return collection
        .where('autorId', isEqualTo: user!.uid)
        .orderBy('criadoEm', descending: true)
        .snapshots();
  }

  Widget _buildPostCard(DocumentSnapshot post, String tipo) {
    final data = post.data() as Map<String, dynamic>;
    final titulo = data['titulo'] ?? 'Sem título';
    final descricao = data['descricao'] ?? '';
    final imagem = data['figuraUrl']?.toString() ?? '';

    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(tipo, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(titulo, style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 6),
            if (descricao.isNotEmpty) Text(descricao),
            if (imagem.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Image.network(imagem),
              ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: () => _editPost(post, tipo),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _deletePost(post, tipo),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPostsSection(String tipo) {
    return StreamBuilder<QuerySnapshot>(
      stream: _getUserPostsStream(tipo),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text("Erro: ${snapshot.error}"));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final posts = snapshot.data?.docs ?? [];
        if (posts.isEmpty) return Center(child: Text("Nenhum $tipo."));

        return ListView(
          children: posts.map((post) => _buildPostCard(post, tipo)).toList(),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Meu Perfil"),
          backgroundColor: Colors.green,
        ),
        body: Column(
          children: [
            const SizedBox(height: 20),
            GestureDetector(
              onTap: _pickProfileImage,
              child: CircleAvatar(
                radius: 50,
                backgroundImage:
                    _profileImage != null ? FileImage(_profileImage!) : null,
                child: _profileImage == null
                    ? const Icon(Icons.person, size: 50)
                    : null,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _userName,
              style:
                  const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            // Botão de sair
            ElevatedButton.icon(
              onPressed: () async {
                await FirebaseAuth.instance.signOut();

                // Redireciona para a tela de login e remove histórico
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => TelaLogin()),
                  (Route<dynamic> route) => false,
                );
              },
              icon: const Icon(Icons.logout),
              label: const Text('Sair'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            const TabBar(
              labelColor: Colors.green,
              unselectedLabelColor: Colors.black54,
              tabs: [
                Tab(text: "Oportunidades"),
                Tab(text: "Ideias"),
                Tab(text: "Conteúdos"),
              ],
            ),
            const Divider(height: 1, color: Colors.grey),
            Expanded(
              child: TabBarView(
                children: [
                  _buildPostsSection('Oportunidade'),
                  _buildPostsSection('Ideia'),
                  _buildPostsSection('Conteudo'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
