import 'package:flutter/material.dart';
import 'globals.dart' as globals;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'cadastroOportunidades.dart';
import 'cadastroConteudoApoio.dart';
import 'cadastroIdeias.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:url_launcher/url_launcher.dart';
import 'package:rxdart/rxdart.dart';
import 'calendario.dart';
import 'perfil.dart';
import 'notificacoes.dart';

class HomePage extends StatefulWidget {
  final String userName;
  final bool isProfessor;

  const HomePage({Key? key, required this.userName, this.isProfessor = false})
      : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  String userNameFromFirestore = '';
  String userTipoFromFirestore = '';

  // ✅ Filtros e pesquisa
  bool _showIdeias = true;
  bool _showOportunidades = true;
  bool _showConteudos = true;
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _fetchUserName();
  }

  Future<void> _fetchUserName() async {
    if (globals.userId != null) {
      try {
        DocumentSnapshot snapshot = await FirebaseFirestore.instance
            .collection('usuarios')
            .doc(globals.userId)
            .get();

        if (snapshot.exists) {
          setState(() {
            userNameFromFirestore = snapshot.get('nome');
            userTipoFromFirestore = snapshot.get('tipo');
          });
        }
      } catch (e) {
        print('Erro ao buscar nome do usuário: $e');
      }
    }
  }

  void _onNavTap(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _openCreationMenu() {
    showModalBottomSheet(
      context: context,
      builder: (_) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.lightbulb),
                title: const Text('Ideia'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const RegistroIdeiaPage(),
                    ),
                  );
                },
              ),
              if (userTipoFromFirestore == 'Professor')
                ListTile(
                  leading: const Icon(Icons.event),
                  title: const Text('Oportunidade'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                        const RegistroOportunidadePage(),
                      ),
                    );
                  },
                ),
              if (userTipoFromFirestore == 'Professor')
                ListTile(
                  leading: const Icon(Icons.build),
                  title: const Text('Conteúdo de Apoio'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const RegistroConteudoPage(),
                      ),
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWelcomeCard() {
    return Card(
      color: Colors.green.shade100,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: const Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          'O projeto Eu Empreendedor incentiva estudantes a tirarem suas ideias do papel, desenvolvendo soluções criativas com impacto social. Explore, crie e compartilhe sua jornada empreendedora com a comunidade!',
          style: TextStyle(fontSize: 16, color: Colors.black87),
        ),
      ),
    );
  }

  Stream<List<Map<String, dynamic>>> _getFeedStream() {
    final oportunidades = FirebaseFirestore.instance
        .collection('oportunidade')
        .orderBy('criadoEm', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) {
      final data = d.data() as Map<String, dynamic>;
      return {
        'tipo': 'oportunidade',
        'autor': data['autorNome'] ?? 'Anônimo',
        'titulo': data['titulo'] ?? 'Sem título',
        'descricao': data['descricao'] ?? '',
        'criadoEm': data['criadoEm'] ?? Timestamp.now(),
        'imagem': data['figuraUrl'],
        'figuraUrl': data['figuraUrl'],
        'dataInicio': data['dataInicio'],
        'dataFim': data['dataFim'],
        'contato': data['contato'] ?? '',
        'categoria': data['tipo'] ?? '',
      };
    }).toList());

    final conteudos = FirebaseFirestore.instance
        .collection('conteudos')
        .orderBy('criadoEm', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) {
      final data = d.data() as Map<String, dynamic>;
      return {
        'tipo': 'conteudo',
        'autor': data['autorNome'] ?? 'Desconhecido',
        'titulo': data['titulo'] ?? 'Sem título',
        'descricao': data['descricao'] ?? '',
        'criadoEm': data['criadoEm'] ?? Timestamp.now(),
        'link': data['link'],
        'imagem': data['imagem'],
      };
    }).toList());

    final ideias = FirebaseFirestore.instance
        .collection('ideias')
        .orderBy('criadoEm', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) {
      final data = d.data() as Map<String, dynamic>;
      return {
        'tipo': 'ideia',
        'autor': data['autorNome'] ?? 'Anônimo',
        'titulo': data['titulo'] ?? 'Sem título',
        'descricao': data['descricao'] ?? '',
        'criadoEm': data['criadoEm'] ?? Timestamp.now(),
      };
    }).toList());

    return Rx.combineLatest3(
      oportunidades,
      conteudos,
      ideias,
          (List<Map<String, dynamic>> o, List<Map<String, dynamic>> c,
          List<Map<String, dynamic>> i) {
        final all = [...o, ...c, ...i];
        all.sort((a, b) {
          final t1 = (a['criadoEm'] as Timestamp).toDate();
          final t2 = (b['criadoEm'] as Timestamp).toDate();
          return t2.compareTo(t1);
        });
        return all;
      },
    );
  }

  // ✅ Filtros (chips + pesquisa)
  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Wrap(
              spacing: 8,
              children: [
                FilterChip(
                  label: const Text("Ideias"),
                  selected: _showIdeias,
                  onSelected: (val) => setState(() => _showIdeias = val),
                ),
                FilterChip(
                  label: const Text("Oportunidades"),
                  selected: _showOportunidades,
                  onSelected: (val) =>
                      setState(() => _showOportunidades = val),
                ),
                FilterChip(
                  label: const Text("Materiais"),
                  selected: _showConteudos,
                  onSelected: (val) => setState(() => _showConteudos = val),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 150,
            child: TextField(
              decoration: const InputDecoration(
                hintText: "Pesquisar...",
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (val) {
                setState(() {
                  _searchQuery = val.toLowerCase();
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeed() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _getFeedStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Text("Nenhuma publicação encontrada.");
        }

        var posts = snapshot.data!;

        // ✅ aplicar filtros
        posts = posts.where((post) {
          if (post['tipo'] == 'ideia' && !_showIdeias) return false;
          if (post['tipo'] == 'oportunidade' && !_showOportunidades) {
            return false;
          }
          if (post['tipo'] == 'conteudo' && !_showConteudos) return false;
          return true;
        }).toList();

        // ✅ aplicar pesquisa
        if (_searchQuery.isNotEmpty) {
          posts = posts.where((post) {
            final titulo = (post['titulo'] ?? '').toString().toLowerCase();
            final descricao =
            (post['descricao'] ?? '').toString().toLowerCase();
            final autor = (post['autor'] ?? '').toString().toLowerCase(); // Adicionado
            return titulo.contains(_searchQuery) ||
                descricao.contains(_searchQuery) ||
                autor.contains(_searchQuery); // Adicionado
          }).toList();
        }

        if (posts.isEmpty) {
          return const Text("Nenhum resultado com os filtros aplicados.");
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: posts.map((post) => _buildFeedCard(post)).toList(),
        );
      },
    );
  }

  Widget _buildFeedCard(Map<String, dynamic> post) {
    final String tipo = post['tipo'] ?? 'Não informado';
    final String autor = post['autor'] ?? 'Desconhecido';
    final String link = post['link']?.toString() ?? '';

    bool _isYoutubeLink(String url) {
      return url.contains("youtube.com") || url.contains("youtu.be");
    }

    bool _isPdfLink(String url) {
      return url.toLowerCase().endsWith(".pdf");
    }

    Future<void> _abrirPdf(BuildContext context, String url) async {
      try {
        final response = await http.get(Uri.parse(url));
        final dir = await getApplicationDocumentsDirectory();
        final file = File("${dir.path}/temp.pdf");
        await file.writeAsBytes(response.bodyBytes);

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => Scaffold(
              appBar: AppBar(title: const Text("Visualizar PDF")),
              body: PDFView(filePath: file.path),
            ),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erro ao abrir PDF: $e")),
        );
      }
    }

    Future<void> _abrirNavegador(String url) async {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }

    String formatarData(dynamic data) {
      if (data == null) return 'Não informado';
      DateTime dt;
      if (data is Timestamp) {
        dt = data.toDate();
      } else if (data is String) {
        dt = DateTime.tryParse(data) ?? DateTime.now();
      } else {
        return 'Não informado';
      }
      return "${dt.day.toString().padLeft(2, '0')}/"
          "${dt.month.toString().padLeft(2, '0')}/"
          "${dt.year}";
    }

    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "$autor • ${tipo.toUpperCase()}",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              post['titulo'] ?? 'Sem título',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 6),
            if (post['descricao'] != null &&
                post['descricao'].toString().isNotEmpty)
              Text(post['descricao']),

            // ✅ BLOCO DE OPORTUNIDADE COMPLETO
            if (tipo == 'oportunidade') ...[
              const SizedBox(height: 8),
              Text(
                "De: ${formatarData(post['dataInicio'])} até: ${formatarData(post['dataFim'])}",
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              if (post['categoria'] != null &&
                  post['categoria'].toString().isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  "Categoria: ${post['categoria']}",
                  style: const TextStyle(fontSize: 13, color: Colors.black54),
                ),
              ],
              if (post['contato'] != null &&
                  post['contato'].toString().isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  "Contato: ${post['contato']}",
                  style: const TextStyle(fontSize: 13, color: Colors.black87),
                ),
              ],
              if (post['figuraUrl'] != null &&
                  post['figuraUrl'].toString().isNotEmpty) ...[
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    post['figuraUrl'],
                    height: 160,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const Text('Erro ao carregar imagem'), // Adicionado
                  ),
                ),
              ],
            ],

            if (post['imagem'] != null &&
                post['imagem'].toString().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Image.network(
                  post['imagem'],
                  errorBuilder: (context, error, stackTrace) => const Text('Erro ao carregar imagem'), // Adicionado
                ),
              ),

            if (link.isNotEmpty) ...[
              const SizedBox(height: 10),
              if (_isYoutubeLink(link))
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Image.network(
                      'https://img.youtube.com/vi/${YoutubePlayer.convertUrlToId(link) ?? ""}/0.jpg',
                      fit: BoxFit.cover,
                    ),
                    IconButton(
                      iconSize: 64,
                      icon: const Icon(Icons.play_circle_outline,
                          color: Colors.white70),
                      onPressed: () => _abrirNavegador(link),
                    ),
                  ],
                )
              else if (_isPdfLink(link))
                ElevatedButton.icon(
                  onPressed: () => _abrirPdf(context, link),
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text("Abrir PDF"),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white),
                )
              else
                ElevatedButton.icon(
                  onPressed: () => _abrirNavegador(link),
                  icon: const Icon(Icons.link),
                  label: const Text("Abrir Link"),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _getSelectedPage() {
    switch (_selectedIndex) {
      case 0:
        return Padding(
          padding: const EdgeInsets.all(12),
          child: ListView(
            children: [
              _buildWelcomeCard(),
              _buildFilters(),
              _buildFeed(),
            ],
          ),
        );
      case 3:
        return const PerfilPage();
      default:
        return const Center(child: Text("Em desenvolvimento"));
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 4,
        title: Row(
          children: [
            SizedBox(
              width: 40,
              height: 40,
              child: Image.asset('assets/menininho.png', fit: BoxFit.contain),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Olá, ${userNameFromFirestore.isNotEmpty ? userNameFromFirestore : widget.userName}!',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Compartilhe suas ideias hoje mesmo!',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Colors.grey,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ],
        ),

      actions: [
  StreamBuilder<QuerySnapshot>(
    stream: FirebaseFirestore.instance
        .collection('notificacao')
        .where('usuarioId', isEqualTo: globals.userId)
        .where('lida', isEqualTo: false) // só não lidas
        .snapshots(),
    builder: (context, snapshot) {
      int count = 0;
      if (snapshot.hasData) {
        count = snapshot.data!.docs.length;
      }

      return Stack(
        children: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Colors.green),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificacoesPage(),
                ),
              );
            },
          ),
          if (count > 0)
            Positioned(
              right: 8,
              top: 8,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(
                  minWidth: 12,
                  minHeight: 12,
                ),
                child: Center(
                  child: Text(
                    '$count',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
        ],
      );
    },
  ),
  const SizedBox(width: 12),
],

      ),
      body: _getSelectedPage(),
      bottomNavigationBar: SizedBox(
        height: 65,
        child: BottomAppBar(
          shape: const CircularNotchedRectangle(),
          notchMargin: 6,
          color: Colors.green,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              IconButton(
                tooltip: 'Home',
                icon: const Icon(Icons.home),
                color: _selectedIndex == 0 ? Colors.white : Colors.white70,
                onPressed: () => _onNavTap(0),
              ),
              IconButton(
                tooltip: 'Ideias',
                icon: const Icon(Icons.lightbulb),
                color: _selectedIndex == 1 ? Colors.white : Colors.white70,
                onPressed: () {},
              ),
              const SizedBox(width: 40),
              IconButton(
                tooltip: 'Eventos',
                icon: const Icon(Icons.event),
                color: _selectedIndex == 2 ? Colors.white : Colors.white70,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                      const CalendarioOportunidadesPage(),
                    ),
                  );
                },
              ),
              IconButton(
                tooltip: 'Perfil',
                icon: const Icon(Icons.person),
                color: _selectedIndex == 3 ? Colors.white : Colors.white70,
                onPressed: () => _onNavTap(3),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openCreationMenu,
        backgroundColor: Colors.white,
        foregroundColor: Colors.green,
        shape: const CircleBorder(),
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}
