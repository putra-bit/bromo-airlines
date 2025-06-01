import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MasterBandaraPage extends StatefulWidget {
  @override
  _MasterBandaraPageState createState() => _MasterBandaraPageState();
}

class _MasterBandaraPageState extends State<MasterBandaraPage> {
  final supabase = Supabase.instance.client;
  final _formKey = GlobalKey<FormState>();

  final TextEditingController namaController = TextEditingController();
  final TextEditingController kodeIATAController = TextEditingController();
  final TextEditingController kotaController = TextEditingController();
  final TextEditingController terminalController = TextEditingController();
  final TextEditingController alamatController = TextEditingController();

  int? selectedNegaraId;
  int? editingId;

  void clearForm() {
    namaController.clear();
    kodeIATAController.clear();
    kotaController.clear();
    terminalController.clear();
    alamatController.clear();
    selectedNegaraId = null;
    editingId = null;
  }

  void loadBandaraToForm(Map bandara) {
    namaController.text = bandara['Nama'];
    kodeIATAController.text = bandara['KodeIATA'];
    kotaController.text = bandara['Kota'];
    terminalController.text = bandara['JumlahTerminal'].toString();
    alamatController.text = bandara['Alamat'];
    selectedNegaraId = bandara['NegaraID'];
    editingId = bandara['ID'];
  }

  Future<List<dynamic>> getNegara() async {
    return await supabase.from('Negara').select();
  }

  Future<List<dynamic>> getBandara() async {
    return await supabase
        .from('Bandara')
        .select('*, Negara(Nama)')
        .order('Nama');
  }

  Future<void> saveBandara() async {
    if (_formKey.currentState!.validate()) {
      final data = {
        'Nama': namaController.text.trim(),
        'KodeIATA': kodeIATAController.text.trim().toUpperCase(),
        'Kota': kotaController.text.trim(),
        'NegaraID': selectedNegaraId,
        'JumlahTerminal': int.parse(terminalController.text),
        'Alamat': alamatController.text.trim(),
      };

      final cekNama = await supabase
          .from('Bandara')
          .select()
          .ilike('Nama', namaController.text.trim())
          .neq('ID', editingId ?? -1);
      if (cekNama.isNotEmpty) {
        _showSnackBar('Nama bandara sudah ada');
        return;
      }

      final cekIATA = await supabase
          .from('Bandara')
          .select()
          .eq('KodeIATA', kodeIATAController.text.trim().toUpperCase())
          .neq('ID', editingId ?? -1);
      if (cekIATA.isNotEmpty) {
        _showSnackBar('Kode IATA sudah digunakan');
        return;
      }

      if (editingId == null) {
        await supabase.from('Bandara').insert(data);
        _showSnackBar('Bandara ditambahkan');
      } else {
        await supabase.from('Bandara').update(data).eq('ID', editingId!);
        _showSnackBar('Bandara diperbarui');
      }

      clearForm();
      setState(() {});
    }
  }

  Future<void> deleteBandara(int id, String nama) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => Dialog(
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
                boxShadow: [
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
                  Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.orange,
                    size: 48,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Konfirmasi',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Hapus bandara "$nama"?',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16),
                  ),
                  SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.grey[700],
                        ),
                        onPressed: () => Navigator.pop(context, false),
                        child: Text('Batal'),
                      ),
                      SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () => Navigator.pop(context, true),
                        child: Text('Hapus'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
    );
    if (confirm == true) {
      await supabase.from('Bandara').delete().eq('ID', id);
      _showSnackBar('Bandara dihapus');
      setState(() {});
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Master Bandara')),
      body: FutureBuilder<List>(
        future: getNegara(),
        builder: (context, snapshotNegara) {
          if (!snapshotNegara.hasData) {
            return Center(child: CircularProgressIndicator());
          }
          final negaraList = snapshotNegara.data!;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                // KIRI: Form
                Expanded(
                  flex: 2,
                  child: SingleChildScrollView(
                    child: Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                editingId == null
                                    ? 'Tambah Bandara'
                                    : 'Edit Bandara',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              SizedBox(height: 16),
                              Wrap(
                                spacing: 12,
                                runSpacing: 12,
                                children: [
                                  _buildTextField(namaController, 'Nama'),
                                  _buildTextField(
                                    kodeIATAController,
                                    'Kode IATA',
                                  ),
                                  _buildTextField(kotaController, 'Kota'),
                                  _buildTextField(
                                    terminalController,
                                    'Jumlah Terminal',
                                    isNumber: true,
                                  ),
                                  DropdownButtonFormField<int>(
                                    value: selectedNegaraId,
                                    items:
                                        negaraList.map<DropdownMenuItem<int>>((
                                          negara,
                                        ) {
                                          return DropdownMenuItem(
                                            value: negara['ID'],
                                            child: Text(negara['Nama']),
                                          );
                                        }).toList(),
                                    onChanged:
                                        (val) => setState(
                                          () => selectedNegaraId = val,
                                        ),
                                    decoration: InputDecoration(
                                      labelText: 'Negara',
                                      border: OutlineInputBorder(),
                                    ),
                                    validator:
                                        (val) =>
                                            val == null
                                                ? 'Wajib dipilih'
                                                : null,
                                  ),
                                  _buildTextField(
                                    alamatController,
                                    'Alamat',
                                    maxLines: 2,
                                  ),
                                ],
                              ),
                              SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  OutlinedButton(
                                    onPressed: clearForm,
                                    child: Text('Batal'),
                                  ),
                                  SizedBox(width: 8),
                                  ElevatedButton(
                                    onPressed: saveBandara,
                                    child: Text(
                                      editingId == null
                                          ? 'Simpan'
                                          : 'Simpan Perubahan',
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                SizedBox(width: 16),

                // KANAN: Data Table
                Expanded(
                  flex: 3,
                  child: Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: FutureBuilder<List>(
                        future: getBandara(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return Center(
                              child: Padding(
                                padding: EdgeInsets.all(32),
                                child: CircularProgressIndicator(),
                              ),
                            );
                          }
                          final list = snapshot.data!;
                          return SingleChildScrollView(
                            scrollDirection: Axis.vertical,
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: DataTable(
                                columns: const [
                                  DataColumn(label: Text('Nama')),
                                  DataColumn(label: Text('Kode')),
                                  DataColumn(label: Text('Kota')),
                                  DataColumn(label: Text('Negara')),
                                  DataColumn(label: Text('Terminal')),
                                  DataColumn(label: Text('Alamat')),
                                  DataColumn(label: Text('Aksi')),
                                ],
                                rows:
                                    list.map((b) {
                                      return DataRow(
                                        cells: [
                                          DataCell(Text(b['Nama'])),
                                          DataCell(Text(b['KodeIATA'])),
                                          DataCell(Text(b['Kota'])),
                                          DataCell(
                                            Text(b['Negara']['Nama'] ?? ''),
                                          ),
                                          DataCell(
                                            Text(
                                              b['JumlahTerminal'].toString(),
                                            ),
                                          ),
                                          DataCell(Text(b['Alamat'])),
                                          DataCell(
                                            Row(
                                              children: [
                                                IconButton(
                                                  icon: Icon(
                                                    Icons.edit,
                                                    color: Colors.blue,
                                                  ),
                                                  onPressed:
                                                      () => setState(
                                                        () => loadBandaraToForm(
                                                          b,
                                                        ),
                                                      ),
                                                ),
                                                IconButton(
                                                  icon: Icon(
                                                    Icons.delete,
                                                    color: Colors.red,
                                                  ),
                                                  onPressed:
                                                      () => deleteBandara(
                                                        b['ID'],
                                                        b['Nama'],
                                                      ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      );
                                    }).toList(),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    bool isNumber = false,
    int maxLines = 1,
  }) {
    return SizedBox(
      width: 300,
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
        ),
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        validator: (val) {
          if (val == null || val.isEmpty) return 'Wajib diisi';
          if (label == 'Jumlah Terminal') {
            final n = int.tryParse(val);
            if (n == null || n < 1) return 'Minimal 1';
          }
          if (label == 'Kode IATA' && val.length != 3) return 'Harus 3 huruf';
          return null;
        },
      ),
    );
  }
}
