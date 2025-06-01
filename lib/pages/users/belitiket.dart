import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BeliTiketFormPage extends StatefulWidget {
  final int jadwalID;
  final int jumlahPenumpang;

  const BeliTiketFormPage({
    super.key,
    required this.jadwalID,
    required this.jumlahPenumpang,
  });

  @override
  State<BeliTiketFormPage> createState() => _BeliTiketFormPageState();
}

class _BeliTiketFormPageState extends State<BeliTiketFormPage> {
  int? userID;
  final _currencyFormatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );
  final supabase = Supabase.instance.client;
  final _formKey = GlobalKey<FormState>();

  List<Map<String, String>> penumpangData = [];
  String kodePromo = '';
  Map<String, dynamic>? promoData;
  bool promoValid = false;
  String promoMessage = '';

  Map<String, dynamic>? jadwalData;
  bool isLoading = true;

  num totalHarga = 0;
  num diskon = 0;
  num totalBayar = 0;

  @override
  void initState() {
    super.initState();
    // Inisialisasi data penumpang kosong
    penumpangData = List.generate(
      widget.jumlahPenumpang,
      (index) => {'titel': 'Tuan', 'nama': ''},
    );
    loadJadwal();
  }

  Future<void> loadJadwal() async {
    setState(() => isLoading = true);
    try {
      final data =
          await supabase
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
              .eq('ID', widget.jadwalID)
              .single();

      setState(() {
        jadwalData = data;
        totalHarga = widget.jumlahPenumpang * (data['HargaPerTiket'] as num);
        totalBayar = totalHarga;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error load jadwal penerbangan: $e')),
      );
    }
  }

  Future<void> cekKodePromo() async {
    if (kodePromo.trim().isEmpty) {
      setState(() {
        promoValid = false;
        promoData = null;
        promoMessage = '';
        diskon = 0;
        totalBayar = totalHarga;
      });
      return;
    }

    try {
      final nowDate = DateTime.now();
      final nowStr = nowDate.toIso8601String().substring(0, 10); // YYYY-MM-DD

      final data =
          await supabase
              .from('KodePromo')
              .select('*')
              .eq('Kode', kodePromo.trim())
              .gte('BerlakuSampai', nowStr)
              .maybeSingle();

      if (data == null) {
        setState(() {
          promoValid = false;
          promoData = null;
          promoMessage = 'Kode promo tidak valid atau sudah expired';
          diskon = 0;
          totalBayar = totalHarga;
        });
      } else {
        final persentaseDiskon = (data['PersentaseDiskon'] ?? 0) as num;
        final maxDiskon = (data['MaksimumDiskon'] ?? 0) as num;

        // Hitung diskon dengan benar
        num hitungDiskon = totalHarga * persentaseDiskon / 100;

        // Batasi diskon maksimal
        if (hitungDiskon > maxDiskon) hitungDiskon = maxDiskon;

        setState(() {
          promoValid = true;
          promoData = data;
          promoMessage =
              'Diskon ${persentaseDiskon.toStringAsFixed(0)}% diterapkan, potongan maksimal ${_currencyFormatter.format(maxDiskon)}';
          diskon = hitungDiskon;
          totalBayar = totalHarga - diskon;
        });
      }
    } catch (e) {
      setState(() {
        promoValid = false;
        promoData = null;
        promoMessage = 'Error validasi kode promo: $e';
        diskon = 0;
        totalBayar = totalHarga;
      });
    }
  }

  Future<void> konfirmasiPembayaran() async {
    if (!_formKey.currentState!.validate()) return;

    _formKey.currentState!.save();

    setState(() => isLoading = true);

    try {
      // Insert TransaksiHeader dan ambil ID hasil insert
      final response =
          await supabase
              .from('TransaksiHeader')
              .insert({
                'AkunID': userID,
                'JadwalPenerbanganID': widget.jadwalID,
                'JumlahPenumpang': widget.jumlahPenumpang,
                'TotalHarga': totalHarga,
                'KodePromoID': promoValid ? promoData!['ID'] as int : null,
                'TanggalTransaksi': DateTime.now().toIso8601String(),
              })
              .select()
              .single();

      if (!response.containsKey('ID')) {
        throw 'Gagal membuat transaksi';
      }

      final transaksiID = response['ID'] as int;

      // Insert TransaksiDetail untuk tiap penumpang
      for (var p in penumpangData) {
        await supabase.from('TransaksiDetail').insert({
          'TransaksiHeaderID': transaksiID,
          'TitelPenumpang': p['titel'],
          'NamaLengkapPenumpang': p['nama'],
        });
      }

      setState(() => isLoading = false);

      // Kembali ke mainuser setelah sukses
      Navigator.popUntil(context, ModalRoute.withName('/mainuser'));
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal konfirmasi pembayaran: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading && jadwalData == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final tanggalKeberangkatan = DateTime.parse(
      jadwalData!['TanggalWaktuKeberangkatan'],
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Form Beli Tiket'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // Kembali ke List Penerbangan Form
            Navigator.pop(context);
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Form data penumpang (kiri)
            Expanded(
              flex: 2,
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    Text(
                      'Jumlah Penumpang: ${widget.jumlahPenumpang}',
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 12),
                    ...List.generate(widget.jumlahPenumpang, (index) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Penumpang ${index + 1}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          DropdownButtonFormField<String>(
                            value: penumpangData[index]['titel'],
                            decoration: const InputDecoration(
                              labelText: 'Titel',
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'Tuan',
                                child: Text('Tuan'),
                              ),
                              DropdownMenuItem(
                                value: 'Nyonya',
                                child: Text('Nyonya'),
                              ),
                            ],
                            onChanged: (val) {
                              setState(
                                () =>
                                    penumpangData[index]['titel'] =
                                        val ?? 'Tuan',
                              );
                            },
                            validator:
                                (value) =>
                                    (value == null || value.isEmpty)
                                        ? 'Titel wajib diisi'
                                        : null,
                          ),
                          TextFormField(
                            decoration: const InputDecoration(
                              labelText: 'Nama Lengkap',
                            ),
                            onSaved:
                                (val) =>
                                    penumpangData[index]['nama'] =
                                        val?.trim() ?? '',
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'Nama wajib diisi';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                        ],
                      );
                    }),
                    const SizedBox(height: 8),
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Kode Promo',
                      ),
                      onChanged: (val) => kodePromo = val.trim(),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: cekKodePromo,
                      child: const Text('Cek Kode Promo'),
                    ),
                    if (promoMessage.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          promoMessage,
                          style: TextStyle(
                            color: promoValid ? Colors.green : Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: konfirmasiPembayaran,
                      child: const Text('Konfirmasi Pembayaran'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 24),
            // Info penerbangan (kanan)
            Expanded(
              flex: 1,
              child: Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child:
                      jadwalData == null
                          ? const Center(
                            child: Text('Tidak ada data penerbangan'),
                          )
                          : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Detail Penerbangan',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                              const Divider(),
                              Text(
                                '${jadwalData!['BandaraKeberangkatan']['Nama']} (${jadwalData!['BandaraKeberangkatan']['KodeIATA']})',
                                style: const TextStyle(fontSize: 16),
                              ),
                              const Icon(Icons.arrow_downward),
                              Text(
                                '${jadwalData!['BandaraTujuan']['Nama']} (${jadwalData!['BandaraTujuan']['KodeIATA']})',
                                style: const TextStyle(fontSize: 16),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Maskapai: ${jadwalData!['Maskapai']['Nama']}',
                                style: const TextStyle(fontSize: 16),
                              ),
                              Text(
                                'Tanggal: ${DateFormat('dd MMM yyyy').format(tanggalKeberangkatan)}',
                                style: const TextStyle(fontSize: 16),
                              ),
                              Text(
                                'Waktu: ${DateFormat('HH:mm').format(tanggalKeberangkatan)}',
                                style: const TextStyle(fontSize: 16),
                              ),
                              Text(
                                'Jumlah Penumpang: ${widget.jumlahPenumpang}',
                                style: const TextStyle(fontSize: 16),
                              ),
                              const Divider(),
                              Text(
                                'Total Harga: ${_currencyFormatter.format(totalHarga)}',
                                style: const TextStyle(fontSize: 16),
                              ),
                              Text(
                                'Diskon: ${_currencyFormatter.format(diskon)}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.green,
                                ),
                              ),
                              Text(
                                'Total Bayar: ${_currencyFormatter.format(totalBayar)}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
