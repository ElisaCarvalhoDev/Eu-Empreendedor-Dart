import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'globals.dart' as globals;

class NotificacoesPage extends StatelessWidget {
  const NotificacoesPage({super.key});

  @override
  Widget build(BuildContext context) {
    if (globals.userId == null) {
      return const Scaffold(
        body: Center(child: Text("Usuário não autenticado")),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text("Notificações"),
        backgroundColor: Colors.green,
        elevation: 2,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('notificacao')
            .where('usuarioId', isEqualTo: globals.userId) // pega notificações do usuário logado
            .orderBy('data', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                "Nenhuma notificação",
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          final notificacoes = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: notificacoes.length,
            itemBuilder: (context, index) {
              final doc = notificacoes[index];
              final dados = doc.data() as Map<String, dynamic>;

              final titulo = dados['titulo'] ?? "Sem título";
              final autor = dados['autor'] ?? "Desconhecido";
              final lida = dados['lida'] ?? false;
              final data = (dados['data'] as Timestamp?)?.toDate();
              final dataInicio = (dados['dataInicio'] as Timestamp?)?.toDate();
              final dataFim = (dados['dataFim'] as Timestamp?)?.toDate();

              return Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () async {
                    if (!lida) {
                      await FirebaseFirestore.instance
                          .collection('notificacao')
                          .doc(doc.id)
                          .update({'lida': true});
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(
                          lida ? Icons.check_circle : Icons.notifications,
                          color: lida ? Colors.green : Colors.redAccent,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                titulo,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight:
                                      lida ? FontWeight.normal : FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                "Por $autor",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                              if (dataInicio != null && dataFim != null)
                                Text(
                                  "De ${dataInicio.day}/${dataInicio.month}/${dataInicio.year} "
                                  "até ${dataFim.day}/${dataFim.month}/${dataFim.year}",
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              if (data != null)
                                Text(
                                  "${data.day}/${data.month}/${data.year} "
                                  "${data.hour}:${data.minute.toString().padLeft(2, '0')}",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade400,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
