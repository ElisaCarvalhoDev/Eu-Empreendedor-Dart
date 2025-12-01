import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'ideias_page.dart';
import 'perfil.dart';
import 'home.dart';
import 'cadastroOportunidades.dart';
import 'cadastroConteudoApoio.dart';
import 'cadastroIdeias.dart';

class CalendarioOportunidadesPage extends StatefulWidget {
  const CalendarioOportunidadesPage({super.key});

  @override
  State<CalendarioOportunidadesPage> createState() =>
      _CalendarioOportunidadesPageState();
}

class _CalendarioOportunidadesPageState
    extends State<CalendarioOportunidadesPage> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<Color>> _oportunidadesDias = {};
  int _selectedIndex = 2; // Calendário é o terceiro ícone

  @override
  void initState() {
    super.initState();
    _carregarOportunidadesDias();
  }

  Future<void> _carregarOportunidadesDias() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('oportunidade').get();

      final Map<DateTime, List<Color>> dias = {};
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        if (data.containsKey('dataInicioFormatado')) {
          final inicio = data['dataInicioFormatado'] as Map<String, dynamic>;
          final diaKey = DateTime(
            inicio['ano'] ?? 2025,
            inicio['mes'] ?? 1,
            inicio['dia'] ?? 1,
          );
          Color cor = Colors.green;
          if (dias.containsKey(diaKey)) {
            dias[diaKey]!.add(cor);
          } else {
            dias[diaKey] = [cor];
          }
        }
      }

      setState(() {
        _oportunidadesDias = dias;
      });
    } catch (e) {
      print("Erro ao carregar oportunidades: $e");
    }
  }

  Stream<List<Map<String, dynamic>>> _getOportunidadesPorDia(DateTime dia) {
    final inicioDoDia = DateTime(dia.year, dia.month, dia.day);
    final fimDoDia = inicioDoDia.add(const Duration(days: 1));

    return FirebaseFirestore.instance
        .collection('oportunidade')
        .where('dataInicio', isGreaterThanOrEqualTo: inicioDoDia)
        .where('dataInicio', isLessThan: fimDoDia)
        .snapshots()
        .map((snap) => snap.docs.map((d) {
              final data = d.data() as Map<String, dynamic>;
              return {
                'autor': data['autorNome'] ?? 'Anônimo',
                'titulo': data['titulo'] ?? 'Sem título',
                'descricao': data['descricao'] ?? '',
                'imagem': data['figuraUrl'],
                'dataInicio': data['dataInicio'],
                'dataFim': data['dataFim'],
              };
            }).toList());
  }

  Widget _buildMiniCard(Map<String, dynamic> oportunidade) {
    final inicio = oportunidade['dataInicio'];
    final fim = oportunidade['dataFim'];

    String dataInicioStr = inicio != null
        ? DateFormat('dd/MM/yyyy').format((inicio as Timestamp).toDate())
        : "Sem data";

    String dataFimStr = fim != null
        ? DateFormat('dd/MM/yyyy').format((fim as Timestamp).toDate())
        : "Sem data";

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      elevation: 3,
      child: ListTile(
        title: Text(
          oportunidade['titulo'],
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("📅 Início: $dataInicioStr"),
            Text("📅 Fim: $dataFimStr"),
            const SizedBox(height: 4),
            Text(
              oportunidade['descricao'],
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        trailing: Text(
          oportunidade['autor'],
          style: const TextStyle(fontSize: 12, color: Colors.green),
        ),
      ),
    );
  }

  void _mostrarOportunidades(DateTime dia) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return SizedBox(
          height: MediaQuery.of(context).size.height * 0.6,
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: _getOportunidadesPorDia(dia),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(
                  child: Text(
                    "Nenhuma oportunidade neste dia.",
                    style: TextStyle(fontSize: 16),
                  ),
                );
              }
              final oportunidades = snapshot.data!;
              return ListView.builder(
                itemCount: oportunidades.length,
                itemBuilder: (context, index) =>
                    _buildMiniCard(oportunidades[index]),
              );
            },
          ),
        );
      },
    );
  }

  void _onNavTap(int index) {
    switch (index) {
      case 0:
     Navigator.pushAndRemoveUntil(
  context,
  MaterialPageRoute(builder: (_) => HomePage(userName: "Usuário")),
  (route) => false, // remove todas as rotas anteriores
);

        break;
      case 1:
  Navigator.pushAndRemoveUntil(
    context,
    MaterialPageRoute(builder: (_) => const IdeiasPage()),
    (route) => false,
  );

        break;
      case 2:
        setState(() {
          _selectedIndex = 2;
        });
        break; // já estamos aqui
case 3:
 // Se houver algum modal aberto, fechar antes (seguro)
  if (Navigator.canPop(context)) Navigator.popUntil(context, (route) => route.isFirst);

  // Navega para a Home e remove todas as rotas anteriores
  Navigator.pushAndRemoveUntil(
    context,
    MaterialPageRoute(
      builder: (_) => HomePage(
        userName: "Usuário",
        initialIndex: 3, // abre direto na aba PERFIL
      ),
    ),
    (route) => false,
  );
  break;
    }
  }

  void _abrirMenuCriacao() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return SizedBox(
          height: 220,
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.lightbulb, color: Color.fromARGB(112, 63, 62, 62)),
                title: const Text("Ideia"),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const RegistroIdeiaPage()));
                },
              ),
              ListTile(
                leading: const Icon(Icons.event, color: Color.fromARGB(112, 63, 62, 62)),
                title: const Text("Oportunidade"),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const RegistroOportunidadePage()));
                },
              ),
              ListTile(
                leading: const Icon(Icons.build, color: Color.fromARGB(112, 63, 62, 62)),
                title: const Text("Conteúdo de Apoio"),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const RegistroConteudoPage()));
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.green,
        elevation: 6,
        centerTitle: true,
        automaticallyImplyLeading: false, // remove botão voltar
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.calendar_month, color: Colors.white, size: 26),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                "Calendário de Oportunidades",
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18, // menor e elegante
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  letterSpacing: 0.3,
                  shadows: [
                    Shadow(
                      color: Colors.black26,
                      offset: Offset(0, 1),
                      blurRadius: 2,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: TableCalendar(
          firstDay: DateTime.utc(2020, 1, 1),
          lastDay: DateTime.utc(2100, 12, 31),
          focusedDay: _focusedDay,
          selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
          onDaySelected: (selectedDay, focusedDay) {
            setState(() {
              _selectedDay = selectedDay;
              _focusedDay = focusedDay;
            });
            _mostrarOportunidades(selectedDay);
          },
          headerStyle: const HeaderStyle(
            formatButtonVisible: false,
            titleCentered: true,
            titleTextStyle:
                TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
            leftChevronIcon: Icon(Icons.chevron_left, color: Colors.green),
            rightChevronIcon: Icon(Icons.chevron_right, color: Colors.green),
          ),
          calendarStyle: const CalendarStyle(
            todayDecoration:
                BoxDecoration(color: Colors.green, shape: BoxShape.circle),
            selectedDecoration:
                BoxDecoration(color: Colors.greenAccent, shape: BoxShape.circle),
            weekendTextStyle: TextStyle(color: Colors.redAccent),
          ),
          daysOfWeekStyle: const DaysOfWeekStyle(
            weekdayStyle: TextStyle(fontWeight: FontWeight.bold),
            weekendStyle:
                TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
          ),
          calendarBuilders: CalendarBuilders(
            markerBuilder: (context, date, events) {
              final diaKey = DateTime(date.year, date.month, date.day);
              if (_oportunidadesDias.containsKey(diaKey)) {
                final cores = _oportunidadesDias[diaKey]!;
                return Positioned(
                  bottom: 4,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: cores
                        .take(3)
                        .map((c) => Container(
                              margin: const EdgeInsets.symmetric(horizontal: 1.5),
                              width: 6,
                              height: 6,
                              decoration:
                                  BoxDecoration(color: c, shape: BoxShape.circle),
                            ))
                        .toList(),
                  ),
                );
              }
              return null;
            },
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
  onPressed: _abrirMenuCriacao,
  backgroundColor: Colors.white,   // fundo branco
  foregroundColor: Colors.green,   // ícone verde
  shape: const CircleBorder(),
  child: const Icon(Icons.add, size: 32),
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
                onPressed: () => _onNavTap(1),
              ),
              const SizedBox(width: 40), // espaço para o FAB
              IconButton(
                tooltip: 'Eventos',
                icon: const Icon(Icons.event),
                color: _selectedIndex == 2 ? Colors.white : Colors.white70,
                onPressed: () => _onNavTap(2),
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
