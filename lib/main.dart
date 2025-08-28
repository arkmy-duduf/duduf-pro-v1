// main.dart
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const DudufApp());
}

class DudufApp extends StatelessWidget {
  const DudufApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Duduf Occas',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
          isDense: true,
          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        ),
      ),
      home: const HomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  late final TabController _tab;

  Map<String, dynamic> prices = {};
  Map<String, dynamic> profiles = {};
  Map<String, dynamic> densities = {};
  List<dynamic> profilsLibres = [];

  String selectedType = 'Tube rond';
  String selectedMatiere = 'acier';

  final TextEditingController ctrlDiametre = TextEditingController();
  final TextEditingController ctrlLargeur  = TextEditingController();
  final TextEditingController ctrlHauteur  = TextEditingController();
  final TextEditingController ctrlEp       = TextEditingController();
  final TextEditingController ctrlLongueur = TextEditingController(text: '1');

  double poidsKg = 0.0;
  double prixEur = 0.0;

  // +25% (coché par défaut)
  bool connaisPatron = true;

  // Edition prix matière
  String selectedPrixMatiere = 'acier';
  final TextEditingController ctrlPrixMatiere = TextEditingController();

  bool loaded = false;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _loadAll();
  }

  Future<void> _loadAll() async {
    final pricesStr = await rootBundle.loadString('assets/prices.json');
    final profilesStr = await rootBundle.loadString('assets/profiles.json');
    final Map<String, dynamic> pricesJson = json.decode(pricesStr);
    final Map<String, dynamic> profilesJson = json.decode(profilesStr);

    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('saved_prices');
    Map<String, dynamic> effectivePrices = pricesJson;
    if (saved != null && saved.isNotEmpty) {
      try {
        final Map<String, dynamic> parsed = json.decode(saved);
        effectivePrices = {...pricesJson, ...parsed};
      } catch (_) {}
    }

    setState(() {
      prices = effectivePrices;
      profiles = profilesJson;
      densities = Map<String, dynamic>.from(profilesJson['densities'] ?? {});
      profilsLibres = List<dynamic>.from(profilesJson['profils_libres'] ?? [
        'Tube rond','Tube carré','Tube rectangle','Rond plein','Carré plein','Rectangle plein','Cornière','Plat'
      ]);

      if (prices.keys.isNotEmpty) {
        selectedMatiere = prices.keys.first;
        selectedPrixMatiere = selectedMatiere;
        ctrlPrixMatiere.text = _fmt(prices[selectedPrixMatiere] ?? 0);
      }
      loaded = true;
    });

    _recalc();
  }

  @override
  void dispose() {
    _tab.dispose();
    ctrlDiametre.dispose();
    ctrlLargeur.dispose();
    ctrlHauteur.dispose();
    ctrlEp.dispose();
    ctrlLongueur.dispose();
    ctrlPrixMatiere.dispose();
    super.dispose();
  }

  double _toDouble(TextEditingController c) {
    return double.tryParse(c.text.replaceAll(',', '.')) ?? 0.0;
  }

  double _areaTubeRond(double d, double e) {
    if (d <= 0 || e <= 0 || 2*e >= d) return 0;
    final ext = d * d;
    final intd = (d - 2*e) * (d - 2*e);
    return math.pi / 4.0 * (ext - intd);
  }

  double _areaTubeCarre(double a, double e) {
    if (a <= 0 || e <= 0 || 2*e >= a) return 0;
    final ext = a * a;
    final intd = (a - 2*e) * (a - 2*e);
    return ext - intd;
  }

  double _areaTubeRectangle(double l, double h, double e) {
    if (l <= 0 || h <= 0 || e <= 0 || 2*e >= l || 2*e >= h) return 0;
    final ext = l * h;
    final intd = (l - 2*e) * (h - 2*e);
    return ext - intd;
  }

  double _areaRondPlein(double d) {
    if (d <= 0) return 0;
    return math.pi / 4.0 * d * d;
  }

  double _areaCarrePlein(double a) {
    if (a <= 0) return 0;
    return a * a;
  }

  double _areaRectanglePlein(double l, double h) {
    if (l <= 0 || h <= 0) return 0;
    return l * h;
  }

  double _areaCorniere(double l, double h, double e) {
    if (l <= 0 || h <= 0 || e <= 0 || e > l || e > h) return 0;
    return e * (l + h - e);
  }

  double _areaPlat(double l, double e) {
    if (l <= 0 || e <= 0) return 0;
    return e * l;
  }

  double _poidsKg({
    required String type,
    required double d,
    required double l,
    required double h,
    required double e,
    required double longueurM,
    required double densite,
  }) {
    double areaMm2 = 0.0;
    switch (type) {
      case 'Tube rond':
        areaMm2 = _areaTubeRond(d, e);
        break;
      case 'Tube carré':
        areaMm2 = _areaTubeCarre(d, e);
        break;
      case 'Tube rectangle':
        areaMm2 = _areaTubeRectangle(l, h, e);
        break;
      case 'Rond plein':
        areaMm2 = _areaRondPlein(d);
        break;
      case 'Carré plein':
        areaMm2 = _areaCarrePlein(d);
        break;
      case 'Rectangle plein':
        areaMm2 = _areaRectanglePlein(l, h);
        break;
      case 'Cornière':
        areaMm2 = _areaCorniere(l, h, e);
        break;
      case 'Plat':
        areaMm2 = _areaPlat(l, e);
        break;
      default:
        areaMm2 = 0.0;
    }
    final areaM2 = areaMm2 * 1e-6;
    return areaM2 * longueurM * densite;
  }

  void _recalc() {
    final mat = selectedMatiere;
    final densite = (densities[mat] ?? 0).toDouble();
    final prixKg = (prices[mat] ?? 0).toDouble();

    final d = _toDouble(ctrlDiametre);
    final l = _toDouble(ctrlLargeur);
    final h = _toDouble(ctrlHauteur);
    final e = _toDouble(ctrlEp);
    final longM = _toDouble(ctrlLongueur);

    final pKg = _poidsKg(
      type: selectedType,
      d: d, l: l, h: h, e: e, longueurM: longM, densite: densite,
    );

    double prix = pKg * prixKg;
    if (connaisPatron) prix *= 1.25; // +25%

    setState(() {
      poidsKg = pKg;
      prixEur = prix;
    });
  }

  bool _needsD() => {'Tube rond', 'Rond plein', 'Carré plein', 'Tube carré'}.contains(selectedType);
  bool _needsL() => {'Tube rectangle', 'Rectangle plein', 'Cornière', 'Plat'}.contains(selectedType) || selectedType == 'Tube carré';
  bool _needsH() => {'Tube rectangle', 'Rectangle plein', 'Cornière'}.contains(selectedType);
  bool _needsE() => {'Tube rond', 'Tube carré', 'Tube rectangle', 'Cornière', 'Plat'}.contains(selectedType);

  Future<void> _savePrice() async {
    final v = double.tryParse(ctrlPrixMatiere.text.replaceAll(',', '.'));
    if (v == null) return;
    setState(() {
      prices[selectedPrixMatiere] = v;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('saved_prices', json.encode(prices));
    if (selectedPrixMatiere == selectedMatiere) _recalc();
  }

  String _fmt(num v, {int decimals = 3}) => v.toStringAsFixed(decimals).replaceAll('.', ',');

  @override
  Widget build(BuildContext context) {
    if (!loaded) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final matieres = prices.keys.toList();
    if (!matieres.contains(selectedMatiere) && matieres.isNotEmpty) {
      selectedMatiere = matieres.first;
    }
    if (!matieres.contains(selectedPrixMatiere) && matieres.isNotEmpty) {
      selectedPrixMatiere = matieres.first;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Duduf Occas'),
        bottom: TabBar(
          controller: _tab,
          tabs: const [Tab(text: 'Calcul'), Tab(text: 'Prix matières')],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: [_buildCalculTab(matieres), _buildPrixTab(matieres)],
      ),
    );
  }

  Widget _buildCalculTab(List<String> matieres) {
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        _label('Type'),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: selectedType,
          items: profilsLibres.map<DropdownMenuItem<String>>((e) {
            final s = e.toString();
            return DropdownMenuItem(value: s, child: Text(s));
          }).toList(),
          onChanged: (v) {
            if (v == null) return;
            setState(() => selectedType = v);
            _recalc();
          },
        ),
        const SizedBox(height: 14),

        _label('Matière'),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: selectedMatiere,
          items: matieres.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
          onChanged: (v) {
            if (v == null) return;
            setState(() => selectedMatiere = v);
            _recalc();
          },
        ),
        const SizedBox(height: 14),

        _label('Dimensions (mm)'),
        const SizedBox(height: 6),
        Wrap(
          spacing: 10, runSpacing: 10,
          children: [
            if (_needsD())
              SizedBox(
                width: 180,
                child: TextField(
                  controller: ctrlDiametre,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'D / côté A (mm)',
                    hintText: 'ex: 50',
                  ),
                  onChanged: (_) => _recalc(),
                ),
              ),
            if (_needsL())
              SizedBox(
                width: 180,
                child: TextField(
                  controller: ctrlLargeur,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: selectedType == 'Tube carré' ? 'Côté A (mm)' : 'Largeur L (mm)',
                    hintText: 'ex: 40',
                  ),
                  onChanged: (_) => _recalc(),
                ),
              ),
            if (_needsH())
              SizedBox(
                width: 180,
                child: TextField(
                  controller: ctrlHauteur,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Hauteur H (mm)',
                    hintText: 'ex: 30',
                  ),
                  onChanged: (_) => _recalc(),
                ),
              ),
            if (_needsE())
              SizedBox(
                width: 180,
                child: TextField(
                  controller: ctrlEp,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Épaisseur e (mm)',
                    hintText: 'ex: 3',
                  ),
                  onChanged: (_) => _recalc(),
                ),
              ),
          ],
        ),
        const SizedBox(height: 14),

        _label('Longueur (m)'),
        const SizedBox(height: 6),
        SizedBox(
          width: 180,
          child: TextField(
            controller: ctrlLongueur,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Longueur',
              hintText: 'ex: 1.2',
            ),
            onChanged: (_) => _recalc(),
          ),
        ),
        const SizedBox(height: 10),

        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          value: connaisPatron,
          onChanged: (v) { setState(() => connaisPatron = v ?? false); _recalc(); },
          title: const Text('Je connais le patron (+25%)'),
          controlAffinity: ListTileControlAffinity.leading,
        ),
        const SizedBox(height: 10),

        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _kv('Poids', '${_fmt(poidsKg, decimals: 3)} kg'),
                _kv('Prix', '${_fmt(prixEur, decimals: 2)} €'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPrixTab(List<String> matieres) {
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        _label('Matière'),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: selectedPrixMatiere,
          items: matieres.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
          onChanged: (v) {
            if (v == null) return;
            setState(() {
              selectedPrixMatiere = v;
              ctrlPrixMatiere.text = _fmt(prices[v] ?? 0, decimals: 3);
            });
          },
        ),
        const SizedBox(height: 14),
        _label('Prix €/kg'),
        const SizedBox(height: 6),
        SizedBox(
          width: 200,
          child: TextField(
            controller: ctrlPrixMatiere,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Prix €/kg',
              hintText: 'ex: 1.30',
            ),
          ),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: _savePrice,
          icon: const Icon(Icons.save),
          label: const Text('Enregistrer le prix'),
        ),
        const SizedBox(height: 12),
        const Text(
          'Ces prix sont enregistrés localement et pris en compte dans le calcul.',
          style: TextStyle(color: Colors.black54),
        ),
      ],
    );
  }

  Widget _label(String t) => Text(t, style: const TextStyle(fontWeight: FontWeight.w700));
  Widget _kv(String k, String v) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      children: [
        SizedBox(width: 140, child: Text(k, style: const TextStyle(fontWeight: FontWeight.w600))),
        Expanded(child: Text(v, textAlign: TextAlign.right)),
      ],
    ),
  );
}
