import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'globals.dart' as globals;

class ComentariosPage extends StatefulWidget {
  final String postId;
  final String postAutor;

  const ComentariosPage({
    Key? key,
    required this.postId,
    required this.postAutor,
  }) : super(key: key);

  @override
  State<ComentariosPage> createState() => _ComentariosPageState();
}

class _ComentariosPageState extends State<ComentariosPage> {
  final TextEditingController _controller = TextEditingController();

  // 🔥 Buscar nome do usuário logado diretamente do Firestore
  Future<String> _getUserName() async {
    if (globals.userId == null) return "Anônimo";

    DocumentSnapshot doc = await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(globals.userId)
        .get();

    if (!doc.exists) return "Anônimo";

    return doc.get('nome') ?? "Anônimo";
  }

  Future<void> _enviarComentario() async {
    final texto = _controller.text.trim();
    if (texto.isEmpty) return;

    String autorNome = await _getUserName();

    await FirebaseFirestore.instance.collection('comentarios').add({
      'postId': widget.postId,
      'autorId': globals.userId,
      'autorNome': autorNome,
      'texto': texto,
      'criadoEm': Timestamp.now(),
    });

    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Comentários de ${widget.postAutor}"),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('comentarios')
                  .where('postId', isEqualTo: widget.postId)
                  .orderBy('criadoEm', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("Nenhum comentário ainda."));
                }

                final comentarios = snapshot.data!.docs;

                return ListView.builder(
                  reverse: true,
                  itemCount: comentarios.length,
                  itemBuilder: (context, index) {
                    final data =
                        comentarios[index].data() as Map<String, dynamic>;
                    final autor = data['autorNome'] ?? 'Anônimo';
                    final texto = data['texto'] ?? '';
                    final timestamp =
                        (data['criadoEm'] as Timestamp?)?.toDate() ??
                            DateTime.now();
                    final hora =
                        "${timestamp.day.toString().padLeft(2, '0')}/${timestamp.month.toString().padLeft(2, '0')} "
                        "${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}";

                    return ListTile(
                      title: Text(autor,
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(texto),
                      trailing: Text(
                        hora,
                        style: const TextStyle(
                            fontSize: 10, color: Colors.grey),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: "Escreva um comentário...",
                      border: InputBorder.none,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.green),
                  onPressed: _enviarComentario,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
