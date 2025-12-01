import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'globals.dart' as globals;

class CadastroComplementarPage extends StatefulWidget {
  const CadastroComplementarPage({Key? key}) : super(key: key);

  @override
  State<CadastroComplementarPage> createState() =>
      _CadastroComplementarPageState();
}

class _CadastroComplementarPageState extends State<CadastroComplementarPage> {
  final _formKey = GlobalKey<FormState>();

  // Perguntas (valores de 1 a 10)
  int conhecimentoEmpreendedorismo = 5;
  int interesseArea = 5;
  int experienciaPrevia = 5;
  int confiancaCriarIdeias = 5;
  int aberturaAprender = 5;
  int perfilColaborativo = 5;
  int visaoImpacto = 5;

  // Bio
  final TextEditingController bioController = TextEditingController();

  // Contato
  final TextEditingController emailController = TextEditingController();
  final TextEditingController telefoneController = TextEditingController();
  final TextEditingController linkController = TextEditingController();


  Future<void> _salvarCadastro() async {
    if (globals.userId == null) return;

    final data = {
      'conhecimentoEmpreendedorismo': conhecimentoEmpreendedorismo,
      'interesseArea': interesseArea,
      'experienciaPrevia': experienciaPrevia,
      'confiancaCriarIdeias': confiancaCriarIdeias,
      'aberturaAprender': aberturaAprender,
      'perfilColaborativo': perfilColaborativo,
      'visaoImpacto': visaoImpacto,
      'bio': bioController.text.trim(),
      'email': emailController.text.trim(),
      'telefone': telefoneController.text.trim(),
      'link': linkController.text.trim(),
      'cadastroCompleto': true,
    };

    try {
      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(globals.userId)
          .update(data);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Cadastro complementar salvo!")),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erro ao salvar cadastro: $e")),
      );
    }
  }

  Widget _buildSlider(String label, int value, Function(int) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontWeight: FontWeight.bold, color: Colors.black87)),
        Slider(
          value: value.toDouble(),
          min: 1,
          max: 10,
          divisions: 9,
          label: value.toString(),
          activeColor: Colors.green,
          inactiveColor: Colors.green.shade100,
          onChanged: (double val) {
            onChanged(val.toInt());
          },
        ),
        const SizedBox(height: 8),
      ],
    );
  }



  Widget _buildCardSection({required Widget child, EdgeInsets? padding}) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shadowColor: Colors.green.shade100,
      child: Padding(
        padding: padding ?? const EdgeInsets.all(16),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Cadastro Complementar"),
        backgroundColor: Colors.green,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCardSection(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Avalie seu perfil",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    _buildSlider(
                      "1. Entendimento sobre empreendedorismo",
                      conhecimentoEmpreendedorismo,
                      (v) => setState(() => conhecimentoEmpreendedorismo = v),
                    ),
                    _buildSlider(
                      "2. Interesse em inovação e empreendedorismo",
                      interesseArea,
                      (v) => setState(() => interesseArea = v),
                    ),
                    _buildSlider(
                      "3. Experiência prévia em projetos ou feiras",
                      experienciaPrevia,
                      (v) => setState(() => experienciaPrevia = v),
                    ),
                    _buildSlider(
                      "4. Confiança em criar ideias próprias",
                      confiancaCriarIdeias,
                      (v) => setState(() => confiancaCriarIdeias = v),
                    ),
                    _buildSlider(
                      "5. Abertura para aprender e experimentar",
                      aberturaAprender,
                      (v) => setState(() => aberturaAprender = v),
                    ),
                    _buildSlider(
                      "6. Perfil colaborativo",
                      perfilColaborativo,
                      (v) => setState(() => perfilColaborativo = v),
                    ),
                    _buildSlider(
                      "7. Visão de impacto da ideia/projeto",
                      visaoImpacto,
                      (v) => setState(() => visaoImpacto = v),
                    ),
                  ],
                ),
              ),
              _buildCardSection(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Bio",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: bioController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: "Escreva um pouco sobre você",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.green.shade50,
                      ),
                    ),
                  ],
                ),
              ),
              _buildCardSection(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Informações de contato",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: emailController,
                      decoration: InputDecoration(
                        labelText: "Email",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.green.shade50,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: telefoneController,
                      decoration: InputDecoration(
                        labelText: "Telefone",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.green.shade50,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: linkController,
                      decoration: InputDecoration(
                        labelText: "Link (opcional)",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.green.shade50,
                      ),
                    ),
                  ],
                ),
              ),
            
              const SizedBox(height: 24),
              Center(
                child: ElevatedButton(
                  onPressed: _salvarCadastro,
                  child: const Text(
                    "Salvar Cadastro",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24)),
                    elevation: 4,
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
