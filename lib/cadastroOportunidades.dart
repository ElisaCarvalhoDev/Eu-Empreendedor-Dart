import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RegistroOportunidadePage extends StatefulWidget {
  final DocumentSnapshot? oportunidadeDoc; // Se for edição, passa o documento

  const RegistroOportunidadePage({super.key, this.oportunidadeDoc});

  @override
  State<RegistroOportunidadePage> createState() =>
      _RegistroOportunidadePageState();
}

class _RegistroOportunidadePageState extends State<RegistroOportunidadePage> {
  final TextEditingController tituloController = TextEditingController();
  final TextEditingController descricaoController = TextEditingController();
  final TextEditingController contatoController = TextEditingController();
  final TextEditingController figuraController = TextEditingController();
  final TextEditingController dataInicioController = TextEditingController();
  final TextEditingController dataFimController = TextEditingController();

  String? tipoSelecionado;
  final List<String> tipos = [
    'Evento',
    'Oficina',
    'Viagem',
    'Projeto',
    'Curso',
    'Outro',
  ];

  @override
  void initState() {
    super.initState();
    // Se for edição, preencher campos com os dados existentes
    if (widget.oportunidadeDoc != null) {
      final data = widget.oportunidadeDoc!.data() as Map<String, dynamic>;
      tituloController.text = data['titulo'] ?? '';
      descricaoController.text = data['descricao'] ?? '';
      contatoController.text = data['contato'] ?? '';
      figuraController.text = data['figuraUrl'] ?? '';
      tipoSelecionado = data['tipo'];
      dataInicioController.text =
          (data['dataInicio'] as Timestamp?)
              ?.toDate()
              .toIso8601String()
              .split("T")
              .first ??
          '';
      dataFimController.text =
          (data['dataFim'] as Timestamp?)
              ?.toDate()
              .toIso8601String()
              .split("T")
              .first ??
          '';
    }
  }

 Future<void> salvarOportunidade() async {
  if (tituloController.text.isEmpty ||
      tipoSelecionado == null ||
      dataInicioController.text.isEmpty ||
      dataFimController.text.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Preencha título, tipo e datas")),
    );
    return;
  }

  try {
    User? usuario = FirebaseAuth.instance.currentUser;

    DateTime? dtInicio = DateTime.tryParse(dataInicioController.text);
    DateTime? dtFim = DateTime.tryParse(dataFimController.text);

    if (dtInicio == null || dtFim == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Datas inválidas")),
      );
      return;
    }

    Timestamp dataInicio = Timestamp.fromDate(dtInicio);
    Timestamp dataFim = Timestamp.fromDate(dtFim);

    // 1️⃣ Criar a oportunidade
    final docRef = await FirebaseFirestore.instance.collection('oportunidade').add({
      'titulo': tituloController.text,
      'descricao': descricaoController.text,
      'contato': contatoController.text,
      'figuraUrl': figuraController.text,
      'dataInicio': dataInicio,
      'dataFim': dataFim,
      'tipo': tipoSelecionado,
      'criadoEm': FieldValue.serverTimestamp(),
      'autorId': usuario?.uid,
      'autorNome': usuario?.displayName ?? usuario?.email ?? 'Anônimo',
      'dataInicioFormatado': {
        'ano': dtInicio.year,
        'mes': dtInicio.month,
        'dia': dtInicio.day,
      },
      'dataFimFormatado': {
        'ano': dtFim.year,
        'mes': dtFim.month,
        'dia': dtFim.day,
      },
    });

    // 2️⃣ Buscar todos os usuários
    final usuariosSnapshot = await FirebaseFirestore.instance.collection('usuarios').get();

    // 3️⃣ Criar notificações para todos
    for (var u in usuariosSnapshot.docs) {
      // Aqui usamos o ID do documento do usuário, que sempre existe
      final uidUsuario = u.id;

      await FirebaseFirestore.instance.collection('notificacao').add({
        'titulo': "Nova oportunidade: ${tituloController.text}",
        'autor': usuario?.displayName ?? usuario?.email ?? 'Anônimo',
        'data': FieldValue.serverTimestamp(),
        'lida': false,
        'oportunidadeId': docRef.id,
        'usuarioId': uidUsuario,
      });
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Oportunidade salva com sucesso!")),
    );

    Navigator.pop(context);

  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Erro ao salvar: $e")),
    );
  }
}



  Future<void> _selecionarData(TextEditingController controller) async {
    DateTime? dataSelecionada = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      locale: const Locale("pt", "BR"),
    );

    if (dataSelecionada != null) {
      setState(() {
        controller.text = dataSelecionada.toIso8601String().split("T").first;
      });
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
          widget.oportunidadeDoc == null
              ? "Registrar Oportunidade"
              : "Editar Oportunidade",
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
                          labelText: "Título",
                          prefixIcon: const Icon(
                            Icons.title,
                            color: Colors.green,
                          ),
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
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: "Descrição",
                          prefixIcon: const Icon(
                            Icons.description,
                            color: Colors.green,
                          ),

                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: contatoController,
                        decoration: InputDecoration(
                          labelText: "Contato",
                          prefixIcon: const Icon(
                            Icons.contact_mail,
                            color: Colors.green,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: figuraController,
                        decoration: InputDecoration(
                          labelText: "Figura/Capa (link da imagem)",
                          prefixIcon: const Icon(
                            Icons.image,
                            color: Colors.green,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: dataInicioController,
                        readOnly: true,
                        decoration: InputDecoration(
                          labelText: "Data Início",
                          prefixIcon: const Icon(
                            Icons.calendar_today,
                            color: Colors.green,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        onTap: () => _selecionarData(dataInicioController),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: dataFimController,
                        readOnly: true,
                        decoration: InputDecoration(
                          labelText: "Data Fim",
                          prefixIcon: const Icon(
                            Icons.calendar_today,
                            color: Colors.green,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        onTap: () => _selecionarData(dataFimController),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: tipoSelecionado,
                        items: tipos.map((tipo) {
                          return DropdownMenuItem(
                            value: tipo,
                            child: Text(tipo),
                          );
                        }).toList(),
                        onChanged: (valor) {
                          setState(() {
                            tipoSelecionado = valor;
                          });
                        },
                        decoration: InputDecoration(
                          labelText: "Tipo",
                          prefixIcon: const Icon(
                            Icons.category,
                            color: Colors.green,
                          ),
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
                onPressed: salvarOportunidade,
                icon: const Icon(Icons.check, color: Colors.white),
                label: Text(
                  widget.oportunidadeDoc == null
                      ? "Salvar Oportunidade"
                      : "Atualizar Oportunidade",
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
