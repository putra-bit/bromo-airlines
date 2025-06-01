import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class TiketSayaPage extends StatefulWidget {
  final int userId;
  const TiketSayaPage({super.key, required this.userId});

  @override
  State<TiketSayaPage> createState() => _TiketSayaPageState();
}

class _TiketSayaPageState extends State<TiketSayaPage> {
  final supabase = Supabase.instance.client;
  bool isLoading = false;
  String errorMessage = '';
  List<Map<String, dynamic>> tiketList = [];

  int? userId;

  @override
  void initState() {
    super.initState();
    loadTiketSaya();
  }

  Future<void> loadTiketSaya() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final List response = await supabase
          .from('TransaksiHeader')
          .select('''
        ID,
        JadwalPenerbangan: JadwalPenerbanganID (
          KodePenerbangan,
          Maskapai: MaskapaiID (
            Nama
          ),
          BandaraKeberangkatan: BandaraKeberangkatanID (
            Nama
          ),
          BandaraTujuan: BandaraTujuanID (
            Nama
          ),
          TanggalWaktuKeberangkatan,
          DurasiPenerbangan,
          PerubahanStatusJadwalPenerbangan (
            WaktuPerubahanTerjadi,
            PerkiraanDurasiDelay,
            StatusPenerbangan: StatusPenerbanganID (
              Nama
            )
          )
        )
      ''')
          .eq('AkunID', widget.userId)
          .order('TanggalTransaksi', ascending: false);

      List<Map<String, dynamic>> tempTiketList = [];

      for (final tiket in response) {
        final perubahanList =
            (tiket['JadwalPenerbangan']?['PerubahanStatusJadwalPenerbangan']
                as List?) ??
            [];

        perubahanList.sort((a, b) {
          final aDate = DateTime.parse(a['WaktuPerubahanTerjadi']);
          final bDate = DateTime.parse(b['WaktuPerubahanTerjadi']);
          return bDate.compareTo(aDate);
        });

        final statusTerbaru =
            perubahanList.isNotEmpty ? perubahanList.first : null;

        tempTiketList.add({
          'ID': tiket['ID'],
          'KodePenerbangan': tiket['JadwalPenerbangan']['KodePenerbangan'],
          'NamaMaskapai': tiket['JadwalPenerbangan']['Maskapai']['Nama'],
          'BandaraKeberangkatan':
              tiket['JadwalPenerbangan']['BandaraKeberangkatan']['Nama'],
          'BandaraTujuan': tiket['JadwalPenerbangan']['BandaraTujuan']['Nama'],
          'TanggalWaktuKeberangkatan':
              tiket['JadwalPenerbangan']['TanggalWaktuKeberangkatan'],
          'DurasiPenerbangan': tiket['JadwalPenerbangan']['DurasiPenerbangan'],
          'StatusTerbaru': statusTerbaru,
        });
      }

      setState(() {
        tiketList = tempTiketList;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Gagal memuat tiket: $e';
        isLoading = false;
      });
    }
  }

  String formatTanggal(DateTime dt) {
    return DateFormat('dd MMM yyyy').format(dt);
  }

  String formatWaktu(DateTime dt) {
    return DateFormat('HH:mm').format(dt);
  }

  String formatDurasiDelay(int totalMenit) {
    final jam = totalMenit ~/ 60;
    final menit = totalMenit % 60;
    return 'Delay (selama ±${jam.toString().padLeft(2, '0')} jam ${menit.toString().padLeft(2, '0')} menit)';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tiket Saya'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : errorMessage.isNotEmpty
              ? Center(child: Text(errorMessage))
              : tiketList.isEmpty
              ? const Center(child: Text('Belum ada tiket aktif.'))
              : ListView.builder(
                itemCount: tiketList.length,
                itemBuilder: (context, index) {
                  final tiket = tiketList[index];

                  final tanggalWaktuKeberangkatan = DateTime.parse(
                    tiket['TanggalWaktuKeberangkatan'],
                  );

                  final status = tiket['StatusTerbaru'];
                  String statusTampil = 'Sesuai Jadwal';
                  if (status != null) {
                    final namaStatus =
                        (status['StatusPenerbangan']?['Nama'] ?? '').toString();
                    if (namaStatus.toLowerCase() == 'delay') {
                      final durasiDelay = status['PerkiraanDurasiDelay'];
                      if (durasiDelay != null && durasiDelay is int) {
                        statusTampil = formatDurasiDelay(durasiDelay);
                      } else {
                        statusTampil = 'Delay';
                      }
                    } else {
                      statusTampil = namaStatus;
                    }
                  }

                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Kode Penerbangan: ${tiket['KodePenerbangan']}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text('Maskapai: ${tiket['NamaMaskapai']}'),
                          const SizedBox(height: 4),
                          Text(
                            'Bandara Keberangkatan: ${tiket['BandaraKeberangkatan']}',
                          ),
                          const SizedBox(height: 4),
                          Text('Bandara Tujuan: ${tiket['BandaraTujuan']}'),
                          const SizedBox(height: 4),
                          Text(
                            'Tanggal Keberangkatan: ${formatTanggal(tanggalWaktuKeberangkatan)}',
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Waktu Keberangkatan: ${formatWaktu(tanggalWaktuKeberangkatan)}',
                          ),
                          const SizedBox(height: 4),
                          Text('Status Terakhir: $statusTampil'),
                        ],
                      ),
                    ),
                  );
                },
              ),
    );
  }
}
