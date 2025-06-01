import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class ListPenerbanganPage extends StatefulWidget {
  final String asal;
  final String tujuan;
  final DateTime tanggal;
  final int jumlahPenumpang;

  const ListPenerbanganPage({
    super.key,
    required this.asal,
    required this.tujuan,
    required this.tanggal,
    required this.jumlahPenumpang,
  });

  @override
  State<ListPenerbanganPage> createState() => _ListPenerbanganPageState();
}

class _ListPenerbanganPageState extends State<ListPenerbanganPage> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> listPenerbangan = [];
  bool isLoading = true;

  // Filter waktu keberangkatan
  bool filter0006 = false;
  bool filter0612 = false;
  bool filter1218 = false;
  bool filter1824 = false;

  // Sorting option
  String sortBy = 'Harga Terendah';

  @override
  void initState() {
    super.initState();
    fetchPenerbangan();
  }

  Future<void> fetchPenerbangan() async {
    setState(() => isLoading = true);

    try {
      final tanggalMulai = widget.tanggal.toIso8601String().split('T')[0];
      final tanggalAkhir =
          widget.tanggal
              .add(const Duration(days: 1))
              .toIso8601String()
              .split('T')[0];

      final data = await supabase
          .from('JadwalPenerbangan')
          .select('''
            ID,
            KodePenerbangan,
            Maskapai:MaskapaiID (Nama),
            BandaraKeberangkatan:BandaraKeberangkatanID (Nama, KodeIATA),
            BandaraTujuan:BandaraTujuanID (Nama, KodeIATA),
            TanggalWaktuKeberangkatan,
            DurasiPenerbangan,
            HargaPerTiket
          ''')
          .eq('BandaraKeberangkatan.Nama', widget.asal)
          .eq('BandaraTujuan.Nama', widget.tujuan)
          .gte('TanggalWaktuKeberangkatan', tanggalMulai)
          .lt('TanggalWaktuKeberangkatan', tanggalAkhir);

      final list = (data as List).cast<Map<String, dynamic>>();

      // Filter waktu keberangkatan
      List<Map<String, dynamic>> filteredList =
          list.where((p) {
            final waktuBerangkat = DateTime.parse(
              p['TanggalWaktuKeberangkatan'],
            );
            final jam = waktuBerangkat.hour;
            if (!filter0006 && !filter0612 && !filter1218 && !filter1824)
              return true;
            if (filter0006 && (jam >= 0 && jam < 6)) return true;
            if (filter0612 && (jam >= 6 && jam < 12)) return true;
            if (filter1218 && (jam >= 12 && jam < 18)) return true;
            if (filter1824 && (jam >= 18 && jam < 24)) return true;
            return false;
          }).toList();

      // Sorting sesuai pilihan
      filteredList.sort((a, b) {
        final waktuBerangkatA = DateTime.parse(a['TanggalWaktuKeberangkatan']);
        final waktuBerangkatB = DateTime.parse(b['TanggalWaktuKeberangkatan']);
        final waktuSampaiA = waktuBerangkatA.add(
          Duration(minutes: a['DurasiPenerbangan']),
        );
        final waktuSampaiB = waktuBerangkatB.add(
          Duration(minutes: b['DurasiPenerbangan']),
        );
        final hargaA = a['HargaPerTiket'] as num;
        final hargaB = b['HargaPerTiket'] as num;
        final durasiA = a['DurasiPenerbangan'] as int;
        final durasiB = b['DurasiPenerbangan'] as int;

        switch (sortBy) {
          case 'Harga Terendah':
            return hargaA.compareTo(hargaB);
          case 'Keberangkatan Paling Awal':
            return waktuBerangkatA.compareTo(waktuBerangkatB);
          case 'Keberangkatan Paling Akhir':
            return waktuBerangkatB.compareTo(waktuBerangkatA);
          case 'Kedatangan Paling Awal':
            return waktuSampaiA.compareTo(waktuSampaiB);
          case 'Kedatangan Paling Akhir':
            return waktuSampaiB.compareTo(waktuSampaiA);
          case 'Durasi Tercepat':
            return durasiA.compareTo(durasiB);
          default:
            return hargaA.compareTo(hargaB);
        }
      });

      setState(() {
        listPenerbangan = filteredList;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error load data penerbangan: $e')),
      );
    }
  }

  void applyFilter() {
    fetchPenerbangan();
  }

  Widget buildFilterChips() {
    return Wrap(
      spacing: 8,
      children: [
        FilterChip(
          label: const Text('00:00 - 06:00'),
          selected: filter0006,
          onSelected: (val) => setState(() => filter0006 = val),
        ),
        FilterChip(
          label: const Text('06:00 - 12:00'),
          selected: filter0612,
          onSelected: (val) => setState(() => filter0612 = val),
        ),
        FilterChip(
          label: const Text('12:00 - 18:00'),
          selected: filter1218,
          onSelected: (val) => setState(() => filter1218 = val),
        ),
        FilterChip(
          label: const Text('18:00 - 24:00'),
          selected: filter1824,
          onSelected: (val) => setState(() => filter1824 = val),
        ),
      ],
    );
  }

  Widget buildSortDropdown() {
    return Row(
      children: [
        const Text('Urutkan:'),
        const SizedBox(width: 12),
        DropdownButton<String>(
          value: sortBy,
          items: const [
            DropdownMenuItem(
              value: 'Harga Terendah',
              child: Text('Harga Terendah'),
            ),
            DropdownMenuItem(
              value: 'Keberangkatan Paling Awal',
              child: Text('Keberangkatan Paling Awal'),
            ),
            DropdownMenuItem(
              value: 'Keberangkatan Paling Akhir',
              child: Text('Keberangkatan Paling Akhir'),
            ),
            DropdownMenuItem(
              value: 'Kedatangan Paling Awal',
              child: Text('Kedatangan Paling Awal'),
            ),
            DropdownMenuItem(
              value: 'Kedatangan Paling Akhir',
              child: Text('Kedatangan Paling Akhir'),
            ),
            DropdownMenuItem(
              value: 'Durasi Tercepat',
              child: Text('Durasi Tercepat'),
            ),
          ],
          onChanged: (value) => setState(() => sortBy = value!),
        ),
        const SizedBox(width: 20),
        ElevatedButton(
          onPressed: applyFilter,
          child: const Text('Terapkan Filter'),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('List Penerbangan')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info pencarian
            Text(
              'Dari ${widget.asal}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              'Ke ${widget.tujuan}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              'Tanggal: ${DateFormat('dd MMM yyyy').format(widget.tanggal)}',
            ),
            Text('Penumpang: ${widget.jumlahPenumpang}'),
            const SizedBox(height: 20),

            // Filter dan sort
            const Text('Waktu Keberangkatan:'),
            buildFilterChips(),
            const SizedBox(height: 12),
            buildSortDropdown(),
            const SizedBox(height: 12),

            // List penerbangan
            Expanded(
              child:
                  isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : listPenerbangan.isEmpty
                      ? const Center(
                        child: Text('Tidak ada penerbangan ditemukan'),
                      )
                      : ListView.builder(
                        itemCount: listPenerbangan.length,
                        itemBuilder: (context, index) {
                          final p = listPenerbangan[index];
                          final waktuBerangkat = DateTime.parse(
                            p['TanggalWaktuKeberangkatan'],
                          );
                          final waktuSampai = waktuBerangkat.add(
                            Duration(minutes: p['DurasiPenerbangan']),
                          );
                          final bandaraAsal = p['BandaraKeberangkatan'];
                          final bandaraTujuan = p['BandaraTujuan'];
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            child: ListTile(
                              title: Text(
                                '${p['KodePenerbangan']} - ${p['Maskapai']?['Nama'] ?? '-'}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Text(
                                  '${bandaraAsal?['Nama'] ?? '-'} (${bandaraAsal?['KodeIATA'] ?? '-'}) → '
                                  '${bandaraTujuan?['Nama'] ?? '-'} (${bandaraTujuan?['KodeIATA'] ?? '-'})\n'
                                  '${DateFormat('HH:mm').format(waktuBerangkat)} - ${DateFormat('HH:mm').format(waktuSampai)}',
                                ),
                              ),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'Rp ${p['HargaPerTiket'].toStringAsFixed(0)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue,
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pushNamed(
                                        context,
                                        '/belitiketform',
                                        arguments: {
                                          'jadwalID': p['ID'],
                                          'jumlahPenumpang':
                                              widget.jumlahPenumpang,
                                        },
                                      );
                                    },
                                    child: const Text('Beli Tiket'),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
            ),
          ],
        ),
      ),
    );
  }
}
