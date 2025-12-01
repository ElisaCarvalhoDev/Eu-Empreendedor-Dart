import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:teste12/cadastroOportunidades.dart';
import 'tela_login.dart';
import 'cadastroIdeias.dart';
import 'cadastroConteudoApoio.dart';

class PerfilPage extends StatefulWidget {
  const PerfilPage({super.key});

  @override
  State<PerfilPage> createState() => _PerfilPageState();
}

class _PerfilPageState extends State<PerfilPage> {
  User? user = FirebaseAuth.instance.currentUser;
  String userNameFromFirestore = '';

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

  Future<void> _loadUserName() async {
    if (user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(user!.uid)
        .get();

    if (doc.exists && doc.data() != null) {
      final data = doc.data() as Map<String, dynamic>;
      setState(() {
        userNameFromFirestore = data['nome'] ?? '';
      });
    }
  }
  Widget _buildPostsSection(String tipo) {
  return StreamBuilder<QuerySnapshot>(
    stream: _getUserPostsStream(tipo),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator());
      }
      if (snapshot.hasError) {
        return Center(child: Text("Erro ao carregar $tipo"));
      }
      final docs = snapshot.data?.docs ?? [];
      if (docs.isEmpty) {
        return Center(child: Text("Nenhum $tipo encontrado"));
      }
      return ListView.builder(
        itemCount: docs.length,
        itemBuilder: (context, index) {
          return _buildPostCard(docs[index], tipo);
        },
      );
    },
  );
}

@override
Widget build(BuildContext context) {
  final displayName =
      userNameFromFirestore.isNotEmpty ? userNameFromFirestore : (user?.displayName ?? 'Usuário');

  return DefaultTabController(
    length: 3,
    child: Scaffold(
      appBar: null,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 10),
            // CircleAvatar com iniciais
            CircleAvatar(
              radius: 50,
              backgroundColor: Colors.green,
              child: Text(
                _getUserInitials(displayName),
                style: const TextStyle(
                    fontSize: 32, color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 10),
            // Nome completo
            Text(
              displayName,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            // BOTÃO SAIR ESTILIZADO
            GestureDetector(
              onTap: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text("Confirmação"),
                    content: const Text("Tem certeza que deseja sair?"),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text("Não"),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text("Sim"),
                      ),
                    ],
                  ),
                );

                if (confirm == true) {
                  await FirebaseAuth.instance.signOut();
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => TelaLogin()),
                  );
                }
              },
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 32, vertical: 10),
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Colors.redAccent, Colors.red],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withOpacity(0.4),
                      offset: const Offset(0, 4),
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.logout, color: Colors.white),
                    SizedBox(width: 10),
                    Text(
                      "Sair",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Abas
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
            // Conteúdo das abas
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
    ),
  );
}


  String _getUserInitials(String nome) {
    final words = nome.trim().split(' ');
    if (words.isEmpty) return '';
    if (words.length == 1) return words[0][0].toUpperCase();
    return (words.first[0] + words.last[0]).toUpperCase();
  }

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
              // Botão de editar
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.blue),
                onPressed: () => _editPost(post, tipo),
              ),
              // Botão de excluir com confirmação
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text("Excluir item"),
                      content: const Text("Tem certeza que deseja excluir este item?"),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text("Cancelar"),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text("Excluir", style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true) {
                    await _deletePost(post, tipo); // <-- aqui chama sua função já existente
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("$tipo excluído com sucesso!")),
                    );
                  }
                },
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

// Mantém sua função existente de exclusão:
Future<void> _deletePost(DocumentSnapshot doc, String tipo) async {
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
Future<void> _editPost(DocumentSnapshot doc, String tipo) async {
  if (doc['autorId'] != user?.uid) return; // proteção

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
}