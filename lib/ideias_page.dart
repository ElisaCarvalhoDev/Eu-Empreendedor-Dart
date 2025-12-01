import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'nova_ideia_page.dart';
import 'ideia_chat_page.dart';

class IdeiasPage extends StatelessWidget {
  const IdeiasPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Ideias"),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('ideias')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          var docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(
              child: Text("Nenhuma ideia cadastrada ainda."),
            );
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, i) {
              var ideia = docs[i];
              return Card(
                margin: const EdgeInsets.all(10),
                child: ListTile(
                  title: Text(ideia['titulo']),
                  subtitle: Text(ideia['autorNome']),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatIdeiaPage(ideiaId: ideia.id),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CriarIdeiaPage()),
          );
        },
        label: const Text("Criar ideia"),
        icon: const Icon(Icons.add),
      ),
    );
  }
}
