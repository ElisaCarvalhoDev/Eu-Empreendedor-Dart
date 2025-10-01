import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.green, // muda para verde
        elevation: 6,
        centerTitle: true,
        // removi o shape para tirar os arredondados
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.calendar_month, color: Colors.white, size: 26),
            const SizedBox(width: 8),
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [Colors.white, Colors.greenAccent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ).createShader(bounds),
              child: const Text(
                "Calendário de Oportunidades",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white, // mantém para o gradiente funcionar
                  letterSpacing: 1.1,
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
            titleTextStyle: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
            leftChevronIcon: Icon(Icons.chevron_left, color: Colors.green),
            rightChevronIcon: Icon(Icons.chevron_right, color: Colors.green),
          ),
          calendarStyle: const CalendarStyle(
            todayDecoration:
            BoxDecoration(color: Colors.green, shape: BoxShape.circle),
            selectedDecoration: BoxDecoration(
                color: Colors.greenAccent, shape: BoxShape.circle),
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
                      margin:
                      const EdgeInsets.symmetric(horizontal: 1.5),
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: c,
                        shape: BoxShape.circle,
                      ),
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
    );
  }
}
