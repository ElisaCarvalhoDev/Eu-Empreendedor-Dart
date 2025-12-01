import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ChatIdeiaPage extends StatefulWidget {
  final String ideiaId;

  const ChatIdeiaPage({super.key, required this.ideiaId});

  @override
  State<ChatIdeiaPage> createState() => _ChatIdeiaPageState();
}

class _ChatIdeiaPageState extends State<ChatIdeiaPage> {
  final msgController = TextEditingController();

  Future<void> enviarMensagem() async {
    var user = FirebaseAuth.instance.currentUser!;

    await FirebaseFirestore.instance
        .collection('ideias')
        .doc(widget.ideiaId)
        .collection('mensagens')
        .add({
      'texto': msgController.text.trim(),
      'autorId': user.uid,
      'autorNome': user.displayName ?? "Usuário",
      'createdAt': FieldValue.serverTimestamp(),
    });

    msgController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Discussão da Ideia")),

      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('ideias')
                  .doc(widget.ideiaId)
                  .collection('mensagens')
                  .orderBy('createdAt')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                var msgs = snapshot.data!.docs;

                return ListView.builder(
                  padding: const EdgeInsets.all(15),
                  itemCount: msgs.length,
                  itemBuilder: (context, i) {
                    var msg = msgs[i];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(msg['autorNome'],
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold)),
                          const SizedBox(height: 3),
                          Text(msg['texto']),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // Caixa de envio
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: msgController,
                    decoration:
                        const InputDecoration(hintText: "Digite uma mensagem"),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: enviarMensagem,
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}
