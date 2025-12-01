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
import 'ideias_page.dart';
import "mais_cadastro.dart";
import 'comentarios.dart';

class HomePage extends StatefulWidget {
  final String userName;
  final bool isProfessor;
  final int initialIndex;

  const HomePage({
    Key? key,
    required this.userName,
    this.isProfessor = false,
    this.initialIndex = 0,  // << AQUI está o lugar correto!
  }) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}


class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  String userNameFromFirestore = '';
  String userTipoFromFirestore = '';
  

  bool _showIdeias = true;
  bool _showOportunidades = true;
  bool _showConteudos = true;
  String _searchQuery = "";
  bool _cadastroCompleto = false;

  Map<String, Set<String>> _localLikes = {};
  Map<String, Set<String>> _localInteresse = {};

  @override
void initState() {
  super.initState();
  _fetchUserName();
  _selectedIndex = widget.initialIndex; // <<< CARREGAR ABA CORRETA
   _getFeedStream().listen((posts) {
    setState(() {
      for (var post in posts) {
        _localInteresse.putIfAbsent(
          post['postId'],
          () => Set<String>.from(post['interesse'] ?? []),
        );
      }
    });
  });
}
  Future<void> toggleLike(String postId, String tipoColecao) async {
    final uid = globals.userId;
    if (uid == null) return;

    setState(() {
      _localLikes.putIfAbsent(postId, () => <String>{});
      if (_localLikes[postId]!.contains(uid)) {
        _localLikes[postId]!.remove(uid);
      } else {
        _localLikes[postId]!.add(uid);
      }
    });

    final docRef = FirebaseFirestore.instance
        .collection(tipoColecao)
        .doc(postId);
    final doc = await docRef.get();
    List likes = (doc.data() as Map<String, dynamic>)['likes'] ?? [];

    if (likes.contains(uid)) {
      await docRef.update({
        'likes': FieldValue.arrayRemove([uid]),
      });
    } else {
      await docRef.update({
        'likes': FieldValue.arrayUnion([uid]),
      });
    }
  }

  Future<void> toggleInteresse(String postId, String tipoColecao) async {
  final uid = globals.userId;
  if (uid == null) {
    print("Erro: usuário não está logado!");
    return;
  }

  try {
    final docRef = FirebaseFirestore.instance.collection(tipoColecao).doc(postId);
    final doc = await docRef.get();
    if (!doc.exists) {
      print("Erro: documento não existe");
      return;
    }

    final data = doc.data() as Map<String, dynamic>;
    final interesse = List<String>.from(data['interesse'] ?? []);
    final autorId = data['autorId'] ?? '';
    final autorNome = data['autorNome'] ?? 'Professor';

    if (autorId.isEmpty) {
      print("Erro: autorId vazio");
      return;
    }

    // Pegar dados do usuário atual
    final usuarioSnapshot = await FirebaseFirestore.instance.collection('usuarios').doc(uid).get();
    final usuarioNome = usuarioSnapshot.exists ? usuarioSnapshot.get('nome') ?? 'Usuário' : '';
    final usuarioContato = usuarioSnapshot.exists ? usuarioSnapshot.get('contato') ?? '' : '';

    // Pegar dados do professor
    final autorSnapshot = await FirebaseFirestore.instance.collection('usuarios').doc(autorId).get();
    final autorContato = autorSnapshot.exists ? autorSnapshot.get('contato') ?? '' : '';

    final jaTem = interesse.contains(uid);

    // Atualizar UI local instantaneamente
    setState(() {
      _localInteresse.putIfAbsent(postId, () => <String>{});
      if (jaTem) {
        _localInteresse[postId]!.remove(uid);
      } else {
        _localInteresse[postId]!.add(uid);
      }
    });

    // Atualizar Firestore
    if (jaTem) {
      await docRef.update({
        'interesse': FieldValue.arrayRemove([uid]),
      });
    } else {
      await docRef.update({
        'interesse': FieldValue.arrayUnion([uid]),
      });

      // Notificação para professor
      await FirebaseFirestore.instance.collection('notificacao').add({
        'usuarioId': autorId,
        'mensagem': '$usuarioNome sentiu interesse na sua publicação. Contato: $usuarioContato',
        'lida': false,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Notificação para usuário
      await FirebaseFirestore.instance.collection('notificacao').add({
        'usuarioId': uid,
        'mensagem': 'Você sentiu interesse na publicação do $autorNome. Contato do professor: $autorContato',
        'lida': false,
        'timestamp': FieldValue.serverTimestamp(),
      });
    }

    print("Interesse atualizado com sucesso!");
  } catch (e) {
    print("Erro ao marcar interesse: $e");
  }
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
            userNameFromFirestore = snapshot.get('nome') ?? '';
            userTipoFromFirestore = snapshot.get('tipo') ?? '';
            _cadastroCompleto = snapshot.get('cadastroCompleto') ?? false;
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
                        builder: (context) => const RegistroOportunidadePage(),
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
  Widget _buildWelcomeCardWithButton() {
  return Column(
    children: [
      _buildWelcomeCard(), // seu card verde com o texto

      // Botão de cadastro complementar
      if (!_cadastroCompleto)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CadastroComplementarPage(),
                ),
              ).then((_) async {
                // Recarrega o status após voltar da página de cadastro
                if (globals.userId != null) {
                  DocumentSnapshot snapshot = await FirebaseFirestore.instance
                      .collection('usuarios')
                      .doc(globals.userId)
                      .get();
                  if (snapshot.exists) {
                    setState(() {
                      _cadastroCompleto =
                          snapshot.get('cadastroCompleto') ?? false;
                    });
                  }
                }
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: const Text(
              'Completar Cadastro',
              style: TextStyle(fontSize: 18, color: Colors.white),
            ),
          ),
        ),
    ],
  );
}

  

  Stream<List<Map<String, dynamic>>> _getFeedStream() {
    final oportunidades = FirebaseFirestore.instance
        .collection('oportunidade')
        .orderBy('criadoEm', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs.map((d) {
            final data = d.data() as Map<String, dynamic>;
            return {
              'postId': d.id,
              'tipo': 'oportunidade',
              'autor': data['autorNome'] ?? 'Anônimo',
              'autorId': data['autorId'] ?? '',
              'titulo': data['titulo'] ?? 'Sem título',
              'descricao': data['descricao'] ?? '',
              'criadoEm': data['criadoEm'] ?? Timestamp.now(),
              'imagem': data['figuraUrl'] ?? '',
              'figuraUrl': data['figuraUrl'] ?? '',
              'dataInicio': data['dataInicio'],
              'dataFim': data['dataFim'],
              'contato': data['contato'] ?? '',
              'categoria': data['tipo'] ?? '',
              'likes': data['likes'] ?? [],
              'interesse': data['interesse'] ?? [],
            };
          }).toList(),
        );

    final conteudos = FirebaseFirestore.instance
        .collection('conteudos')
        .orderBy('criadoEm', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs.map((d) {
            final data = d.data() as Map<String, dynamic>;
            return {
              'postId': d.id,
              'tipo': 'conteudo',
              'autor': data['autorNome'] ?? 'Desconhecido',
              'autorId': data['autorId'] ?? '',
              'titulo': data['titulo'] ?? 'Sem título',
              'descricao': data['descricao'] ?? '',
              'criadoEm': data['criadoEm'] ?? Timestamp.now(),
              'link': data['link'] ?? '',
              'imagem': data['imagem'] ?? '',
              'likes': data['likes'] ?? [],
              'interesse': data['interesse'] ?? [],
            };
          }).toList(),
        );

    final ideias = FirebaseFirestore.instance
        .collection('ideias')
        .orderBy('criadoEm', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs.map((d) {
            final data = d.data() as Map<String, dynamic>;
            return {
              'postId': d.id,
              'tipo': 'ideia',
              'autor': data['autorNome'] ?? 'Anônimo',
              'autorId': data['autorId'] ?? '',
              'titulo': data['titulo'] ?? 'Sem título',
              'descricao': data['descricao'] ?? '',
              'criadoEm': data['criadoEm'] ?? Timestamp.now(),
              'likes': data['likes'] ?? [],
              'interesse': data['interesse'] ?? [],
            };
          }).toList(),
        );

    return Rx.combineLatest3(oportunidades, conteudos, ideias, (
      List<Map<String, dynamic>> o,
      List<Map<String, dynamic>> c,
      List<Map<String, dynamic>> i,
    ) {
      final all = [...o, ...c, ...i];
      all.sort((a, b) {
        final t1 = (a['criadoEm'] as Timestamp).toDate();
        final t2 = (b['criadoEm'] as Timestamp).toDate();
        return t2.compareTo(t1);
      });
      return all;
    });
  }

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
                  onSelected: (val) => setState(() => _showOportunidades = val),
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

        // Filtrar tipos
        posts = posts.where((post) {
          if (post['tipo'] == 'ideia' && !_showIdeias) return false;
          if (post['tipo'] == 'oportunidade' && !_showOportunidades)
            return false;
          if (post['tipo'] == 'conteudo' && !_showConteudos) return false;
          return true;
        }).toList();

        // Filtrar busca
        if (_searchQuery.isNotEmpty) {
          posts = posts.where((post) {
            final titulo = (post['titulo'] ?? '').toString().toLowerCase();
            final descricao = (post['descricao'] ?? '')
                .toString()
                .toLowerCase();
            final autor = (post['autor'] ?? '').toString().toLowerCase();
            return titulo.contains(_searchQuery) ||
                descricao.contains(_searchQuery) ||
                autor.contains(_searchQuery);
          }).toList();
        }

        if (posts.isEmpty) {
          return const Text("Nenhum resultado com os filtros aplicados.");
        }

        return ListView.builder(
          key: const PageStorageKey('feedList'), // mantém a posição do scroll
          itemCount: posts.length + 1,
          itemBuilder: (context, index) {
          if (index == 0)
  return _buildWelcomeCardWithButton(); 
            final post = posts[index - 1];
            return FeedCard(
              key: ValueKey(post['postId']),
              post: post,
              localLikes: _localLikes,
              localInteresse: _localInteresse,
              toggleLike: toggleLike,
              toggleInteresse: toggleInteresse,
            );
          },
        );
      },
    );
  }

  Widget _getSelectedPage() {
    switch (_selectedIndex) {
      case 0:
        return Padding(
          padding: const EdgeInsets.all(12),
          child: Column(children: [Expanded(child: _buildFeed())]),
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

    // 🔥 impede overflow
    Expanded(
      child: Column(
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
            maxLines: 1,
            overflow: TextOverflow.ellipsis, // 🔥 não deixa estourar
          ),
          const SizedBox(height: 4),
          const Text(
            'Compartilhe suas ideias hoje mesmo!',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: Color.fromARGB(255, 158, 158, 158),
              fontStyle: FontStyle.italic,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis, // 🔥 evita estourar também
          ),
        ],
      ),
    ),
  ],
),
        actions: [
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('notificacao')
                .where('usuarioId', isEqualTo: globals.userId)
                .where('lida', isEqualTo: false)
                .snapshots(),
            builder: (context, snapshot) {
              int count = 0;
              if (snapshot.hasData) count = snapshot.data!.docs.length;

              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.notifications_none,
                      color: Colors.green,
                    ),
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
      floatingActionButton: FloatingActionButton(
        onPressed: _openCreationMenu,
        backgroundColor: Colors.white,
        foregroundColor: Colors.green,
        shape: const CircleBorder(),
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
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
                color: _selectedIndex == 1 ? Colors.white : Colors.green,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const IdeiasPage()),
                  );
                },
              ),
              const SizedBox(width: 40), // espaço para o FAB
              IconButton(
                tooltip: 'Eventos',
                icon: const Icon(Icons.event),
                color: _selectedIndex == 2 ? Colors.white : Colors.white70,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CalendarioOportunidadesPage(),
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
    );
  }
}

// ───────────────────────────────
// FeedCard Stateful para likes/interesse instantâneo
// ───────────────────────────────
class FeedCard extends StatefulWidget {
  final Map<String, dynamic> post;
  final Map<String, Set<String>> localLikes;
  final Map<String, Set<String>> localInteresse;
  final Function(String, String) toggleLike;
  final Function(String, String) toggleInteresse;

  const FeedCard({
    Key? key,
    required this.post,
    required this.localLikes,
    required this.localInteresse,
    required this.toggleLike,
    required this.toggleInteresse,
  }) : super(key: key);

  @override
  State<FeedCard> createState() => _FeedCardState();
}

class _FeedCardState extends State<FeedCard> {
  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    final String tipo = post['tipo'] ?? 'Não informado';
    final String autor = post['autor'] ?? 'Desconhecido';
    final String postId = post['postId'] ?? '';
    String colecao = tipo == 'oportunidade'
        ? 'oportunidade'
        : tipo == 'conteudo'
            ? 'conteudos'
            : 'ideias';

    String? urlImagem = post['figuraUrl'] ?? post['imagem'];

    final likesList = List<String>.from(
      widget.localLikes[postId] ?? (post['likes'] ?? <dynamic>[]),
    );
    final deuLike = likesList.contains(globals.userId);

    final interesseList = List<String>.from(
      widget.localInteresse[postId] ?? (post['interesse'] ?? []),
    );
    final deuInteresse = interesseList.contains(globals.userId);

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
            const SizedBox(height: 12),
            if (urlImagem != null && urlImagem.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  urlImagem,
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      const Text('Erro ao carregar imagem'),
                ),
              ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // LIKE
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        deuLike ? Icons.thumb_up : Icons.thumb_up_outlined,
                        color: Colors.blue,
                      ),
                      onPressed: () => widget.toggleLike(postId, colecao),
                    ),
                    Text('${likesList.length}'),
                  ],
                ),
                const SizedBox(width: 12),
                // INTERESSE
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        deuInteresse ? Icons.star : Icons.star_border,
                        color: Colors.orange,
                      ),
                      onPressed: globals.userId == null
                          ? null // botão desabilitado se não logado
                          : () => widget.toggleInteresse(postId, colecao),
                    ),
                    Text('${interesseList.length}'),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
