import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class Mainuser extends StatefulWidget {
  const Mainuser({super.key});

  @override
  State<Mainuser> createState() => _MainuserState();
}

class _MainuserState extends State<Mainuser> {
  final supabase = Supabase.instance.client;

  final _fromcontroller = TextEditingController();
  final _tocontroller = TextEditingController();
  final _pessagercontroller = TextEditingController(text: '1');
  DateTime? _keberangkatan;

  List<String> _namaBandara = [];
  String? namaUser;
  int? userID;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final arg = ModalRoute.of(context)?.settings.arguments;
    if (arg != null && arg is Map) {
      setState(() {
        namaUser = arg['nama'] as String?;
        userID = arg['userId'] as int?;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    ambilBandara();
  }

  Future<void> ambilBandara() async {
    final response = await supabase.from('Bandara').select('Nama');
    setState(() {
      _namaBandara = List<String>.from(response.map((b) => b['Nama']));
    });
  }

  Widget labelWithIcon(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 18),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }

  Future<void> logout() async {
    final confirm = await showDialog(
      context: context,
      builder:
          (_) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            elevation: 0,
            backgroundColor: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 20,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.orange,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Konfirmasi',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Kembali ke menu login?',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.grey,
                        ),
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Batal'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Keluar'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
    );
    if (confirm == true) {
      Navigator.pushReplacementNamed(context, '/loginpage');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(250),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 25),
          color: const Color.fromRGBO(24, 93, 169, 1),
          child: Row(
            children: [
              Image.asset(
                'lib/images/logoaly.png',
                height: 150,
                fit: BoxFit.contain,
              ),
              const Spacer(),
              IconButton(
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    '/tiketsaya',
                    arguments: {'userId': userID},
                  );
                },
                icon: const Icon(
                  Icons.airplane_ticket,
                  color: Colors.white,
                  size: 40,
                ),
              ),
              const SizedBox(width: 15),
              IconButton(
                onPressed: () {
                  logout();
                },
                icon: const Icon(Icons.logout, color: Colors.white, size: 40),
              ),
            ],
          ),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 25),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Halo!',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Mau terbang ke mana hari ini, ${namaUser ?? 'Tuan/Nyonya'}?',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 25),

              // Row dengan 2 kolom
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Kolom kiri - Asal
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        labelWithIcon(Icons.flight_takeoff, 'Berangkat Dari'),
                        const SizedBox(height: 6),
                        Autocomplete<String>(
                          optionsBuilder: (TextEditingValue textEditingValue) {
                            if (textEditingValue.text.isEmpty) {
                              return const Iterable<String>.empty();
                            }
                            return _namaBandara.where((option) {
                              final isNotSameAsTujuan =
                                  option != _tocontroller.text;
                              final containsQuery = option
                                  .toLowerCase()
                                  .contains(
                                    textEditingValue.text.toLowerCase(),
                                  );
                              return isNotSameAsTujuan && containsQuery;
                            });
                          },
                          fieldViewBuilder: (
                            context,
                            controller,
                            focusNode,
                            onEditingComplete,
                          ) {
                            controller.text = _fromcontroller.text;
                            controller.selection = _fromcontroller.selection;
                            return TextField(
                              controller: controller,
                              focusNode: focusNode,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                              onChanged: (value) {
                                setState(() {
                                  _fromcontroller.text = value;
                                  _fromcontroller.selection =
                                      controller.selection;
                                });
                              },
                            );
                          },
                          onSelected: (selection) {
                            setState(() {
                              _fromcontroller.text = selection;
                            });
                          },
                        ),
                        const SizedBox(height: 15),

                        labelWithIcon(
                          Icons.calendar_today,
                          'Tanggal Berangkat',
                        ),
                        const SizedBox(height: 6),
                        InkWell(
                          onTap: () async {
                            final initialDate =
                                (_keberangkatan == null ||
                                        _keberangkatan!.isBefore(
                                          DateTime(2023, 1, 1),
                                        ))
                                    ? DateTime(2023, 1, 1)
                                    : _keberangkatan!;

                            final picked = await showDatePicker(
                              context: context,
                              initialDate: initialDate,
                              firstDate: DateTime(2023, 1, 1),
                              lastDate: DateTime(2025, 12, 31),
                            );

                            if (picked != null) {
                              setState(() {
                                _keberangkatan = picked;
                              });
                            }
                          },
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              isDense: true,
                              suffixIcon: Icon(Icons.arrow_drop_down),
                            ),
                            child: Text(
                              _keberangkatan == null
                                  ? 'Pilih tanggal'
                                  : DateFormat(
                                    'EEEE, dd MMMM yyyy',
                                    'id',
                                  ).format(_keberangkatan!),
                              style: TextStyle(
                                color:
                                    _keberangkatan == null
                                        ? Colors.grey
                                        : Colors.black,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 40),

                  // Kolom kanan - Tujuan
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        labelWithIcon(Icons.flight_land, 'Tujuan'),
                        const SizedBox(height: 6),
                        Autocomplete<String>(
                          optionsBuilder: (TextEditingValue textEditingValue) {
                            if (textEditingValue.text.isEmpty) {
                              return const Iterable<String>.empty();
                            }
                            return _namaBandara.where((option) {
                              final isNotSameAsAsal =
                                  option != _fromcontroller.text;
                              final containsQuery = option
                                  .toLowerCase()
                                  .contains(
                                    textEditingValue.text.toLowerCase(),
                                  );
                              return isNotSameAsAsal && containsQuery;
                            });
                          },
                          fieldViewBuilder: (
                            context,
                            controller,
                            focusNode,
                            onEditingComplete,
                          ) {
                            controller.text = _tocontroller.text;
                            controller.selection = _tocontroller.selection;
                            return TextField(
                              controller: controller,
                              focusNode: focusNode,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                              onChanged: (value) {
                                setState(() {
                                  _tocontroller.text = value;
                                  _tocontroller.selection =
                                      controller.selection;
                                });
                              },
                            );
                          },
                          onSelected: (selection) {
                            setState(() {
                              _tocontroller.text = selection;
                            });
                          },
                        ),
                        const SizedBox(height: 15),

                        labelWithIcon(Icons.person, 'Jumlah Penumpang'),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _pessagercontroller,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          onChanged: (value) {
                            final val = int.tryParse(value);
                            if (val == null || val < 1) {
                              _pessagercontroller.text = '1';
                              _pessagercontroller.selection =
                                  const TextSelection.collapsed(offset: 1);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    if (_fromcontroller.text.isEmpty ||
                        _tocontroller.text.isEmpty ||
                        _keberangkatan == null ||
                        int.tryParse(_pessagercontroller.text) == null ||
                        int.parse(_pessagercontroller.text) < 1 ||
                        _fromcontroller.text == _tocontroller.text) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Mohon isi semua data dengan benar dan tujuan tidak boleh sama dengan asal',
                          ),
                        ),
                      );
                      return;
                    }

                    Navigator.pushNamed(
                      context,
                      '/listpenerbanganform',
                      arguments: {
                        'asal': _fromcontroller.text,
                        'tujuan': _tocontroller.text,
                        'tanggal': _keberangkatan,
                        'jumlahPenumpang': int.parse(_pessagercontroller.text),
                        'userID': userID,
                      },
                    );
                  },
                  child: const Text(
                    'Cari Penerbangan',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
