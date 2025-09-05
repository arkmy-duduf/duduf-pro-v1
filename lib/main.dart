<<<<<<< HEAD
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const DudufApp());
}

class DudufApp extends StatelessWidget {
  const DudufApp({super.key});
=======
import 'dart:math' as math;
import 'package:flutter/material.dart';

void main() {
  runApp(const DudufOccasApp());
}

class DudufOccasApp extends StatelessWidget {
  const DudufOccasApp({super.key});

>>>>>>> 3ddf32c (first commit duduf occas)
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Duduf Occas',
      theme: ThemeData(
<<<<<<< HEAD
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFB86B21)),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

class AppData {
  final Map<String, double> densitiesKgM3;
  final Map<String, double> pricesPerKg;
  final Map<String, Map<String, dynamic>> families;

  AppData({
    required this.densitiesKgM3,
    required this.pricesPerKg,
    required this.families,
  });

  static Future<AppData> load() async {
    final profilesStr = await rootBundle.loadString('assets/profiles.json');
    final pricesStr   = await rootBundle.loadString('assets/prices.json');
    final profiles = json.decode(profilesStr) as Map<String, dynamic>;
    final prices   = json.decode(pricesStr)   as Map<String, dynamic>;

    final densities = (profiles['densities'] as Map)
        .map((k, v) => MapEntry(k.toString(), (v as num).toDouble()));

    final fams = <String, Map<String, dynamic>>{};
    for (final key in ['HEA','HEB','IPE','UPN','UPE']) {
      if (profiles.containsKey(key)) {
        fams[key] = (profiles[key] as Map<String, dynamic>);
      }
    }

    final pricesMap = (prices as Map)
        .map((k, v) => MapEntry(k.toString(), (v as num).toDouble()));

    return AppData(
      densitiesKgM3: densities,
      pricesPerKg: pricesMap,
      families: fams,
=======
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0EA5E9)),
        useMaterial3: true,
      ),
      home: const DudufHome(),
      debugShowCheckedModeBanner: false,
>>>>>>> 3ddf32c (first commit duduf occas)
    );
  }
}

enum Mode { normalise, libre }
<<<<<<< HEAD

class ShapeDef {
  final String id;
  final String name;
  final List<DimField> fields;
  const ShapeDef({required this.id, required this.name, required this.fields});
}

class DimField {
  final String key;
  final String label;
  const DimField(this.key, this.label);
}

const List<ShapeDef> kShapes = [
  ShapeDef(
    id: 'tube_rond',
    name: 'Tube rond',
    fields: [DimField('d_ext','Ø extérieur (mm)'), DimField('e','Épaisseur (mm)')],
  ),
  ShapeDef(
    id: 'tube_carre',
    name: 'Tube carré',
    fields: [DimField('c_ext','Côté ext. (mm)'), DimField('e','Épaisseur (mm)')],
  ),
  ShapeDef(
    id: 'tube_rect',
    name: 'Tube rectangulaire',
    fields: [DimField('l_ext','Largeur ext. (mm)'), DimField('h_ext','Hauteur ext. (mm)'), DimField('e','Épaisseur (mm)')],
  ),
  ShapeDef(
    id: 'rond_plein',
    name: 'Rond plein',
    fields: [DimField('d','Diamètre (mm)')],
  ),
  ShapeDef(
    id: 'carre_plein',
    name: 'Carré plein',
    fields: [DimField('c','Côté (mm)')],
  ),
  ShapeDef(
    id: 'rectangle_plein',
    name: 'Rectangle plein',
    fields: [DimField('l','Largeur (mm)'), DimField('h','Hauteur (mm)')],
  ),
  ShapeDef(
    id: 'plat',
    name: 'Plat',
    fields: [DimField('l','Largeur (mm)'), DimField('e','Épaisseur (mm)')],
  ),
  ShapeDef(
    id: 'corniere_egale',
    name: 'Cornière égale',
    fields: [DimField('a','Aile (mm)'), DimField('e','Épaisseur (mm)')],
  ),
  ShapeDef(
    id: 'corniere_inegale',
    name: 'Cornière inégale',
    fields: [DimField('a1','Aile 1 (mm)'), DimField('a2','Aile 2 (mm)'), DimField('e','Épaisseur (mm)')],
  ),
];

double _areaForShape(String id, Map<String, double> mm) {
  switch (id) {
    case 'tube_rond':
      final dExt = mm['d_ext'] ?? 0;
      final e = mm['e'] ?? 0;
      final rExt = dExt / 2.0;
      final rInt = max(0.0, rExt - e);
      return pi * (rExt * rExt - rInt * rInt);
    case 'tube_carre':
      final cExt = mm['c_ext'] ?? 0;
      final e = mm['e'] ?? 0;
      final cInt = max(0.0, cExt - 2 * e);
      return cExt * cExt - cInt * cInt;
    case 'tube_rect':
      final lExt = mm['l_ext'] ?? 0;
      final hExt = mm['h_ext'] ?? 0;
      final e = mm['e'] ?? 0;
      final lInt = max(0.0, lExt - 2 * e);
      final hInt = max(0.0, hExt - 2 * e);
      return lExt * hExt - lInt * hInt;
    case 'rond_plein':
      final d = mm['d'] ?? 0;
      return pi * pow(d / 2.0, 2);
    case 'carre_plein':
      final c = mm['c'] ?? 0;
      return c * c;
    case 'rectangle_plein':
      final l = mm['l'] ?? 0;
      final h = mm['h'] ?? 0;
      return l * h;
    case 'plat':
      final l = mm['l'] ?? 0;
      final e = mm['e'] ?? 0;
      return l * e;
    case 'corniere_egale':
      final a = mm['a'] ?? 0;
      final e = mm['e'] ?? 0;
      return 2 * a * e - e * e;
    case 'corniere_inegale':
      final a1 = mm['a1'] ?? 0;
      final a2 = mm['a2'] ?? 0;
      final e = mm['e'] ?? 0;
      return a1 * e + a2 * e - e * e;
    default:
      return 0.0;
  }
}

double _mm2ToM2(double mm2) => mm2 / 1e6;
double calcWeightKgFromArea(double areaM2, double lengthM, double densityKgM3) {
  return areaM2 * lengthM * densityKgM3;
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  AppData? data;

  Mode mode = Mode.libre;
  double lengthM = 1.0;
  String materialKey = 'acier';
  String? familyKey;
  String? profileKey;
  ShapeDef shape = kShapes.first;
  final Map<String, TextEditingController> shapeCtrls = {};
  double? weightKg;
  double? totalPrice;

  // <-- AJOUT du bouton "Je connais le patron"
  bool knowsBoss = false;
=======
enum Serie { HEA, HEB, IPE, IPN, UPN, UPE }
enum LibreProfil {
  tubeRond,
  tubeCarre,
  tubeRect,
  carrePlein,
  rectPlein,
  rondPlein,
  corniereEgale,
  corniereInEgale,
  te,
  plat,
}
enum Matiere { acier, inox, aluminium, fonte, cuivre, laiton }

class DudufHome extends StatefulWidget {
  const DudufHome({super.key});
  @override
  State<DudufHome> createState() => _DudufHomeState();
}

class _DudufHomeState extends State<DudufHome> {
  Mode mode = Mode.normalise;
  Serie serie = Serie.IPE;
  String? selectedTaille;
  double longueurM = 1.0;
  int quantite = 1;
  Matiere matiere = Matiere.acier;
  double densite = 7850.0;

  LibreProfil libre = LibreProfil.tubeRond;

  // dimensions par défaut
  double dExt = 100, ep = 5, cote = 100, larg = 100, haut = 50, dPlein = 30, aile = 50, aile2 = 30;

  // kg/m acier (7850 kg/m3)
  static const Map<Serie, Map<String, double>> poidsParMetre = {
    Serie.IPE: {'80': 6.00,'100': 8.10,'120': 10.4,'140': 12.9,'160': 15.8,'180': 18.8,'200': 22.4,'220': 26.2,'240': 30.7,'270': 36.1,'300': 42.2,'330': 49.1,'360': 57.1,'400': 66.3},
    Serie.HEA: {'100': 17.0,'120': 20.3,'140': 25.1,'160': 31.0,'180': 36.2,'200': 43.1,'220': 51.5,'240': 61.5,'260': 69.5,'280': 77.8,'300': 90.0,'320': 99.5,'340': 107,'360': 114,'400': 127},
    Serie.HEB: {'100': 20.8,'120': 27.2,'140': 34.4,'160': 43.4,'180': 52.2,'200': 62.5,'220': 72.8,'240': 84.8,'260': 94.8,'280': 105,'300': 119,'320': 129,'340': 137,'360': 145,'400': 158},
    Serie.IPN: {'80': 5.94,'100': 8.35,'120': 11.10,'140': 14.30,'160': 17.90,'180': 21.90,'200': 26.20,'220': 31.10,'240': 36.20,'260': 41.90,'280': 47.90,'300': 54.20,'320': 61.00,'340': 68.00,'360': 76.10,'380': 84.00,'400': 92.40},
    Serie.UPN: {'80': 8.82,'100': 10.8,'120': 13.6,'140': 16.3,'160': 19.2,'180': 22.4,'200': 25.7,'220': 30.0,'240': 33.8,'260': 38.6,'280': 42.7,'300': 47.0,'320': 60.6,'350': 61.8,'380': 64.3,'400': 73.2},
    Serie.UPE: {'80': 7.90,'100': 9.82,'120': 12.1,'140': 14.5,'160': 17.0,'180': 19.7,'200': 22.8,'220': 26.6,'240': 30.2,'270': 35.2,'300': 44.4,'330': 53.2,'360': 61.2,'400': 72.2},
  };

  static const Map<Matiere, double> densites = {
    Matiere.acier: 7850.0, Matiere.inox: 8000.0, Matiere.aluminium: 2700.0, Matiere.fonte: 7200.0, Matiere.cuivre: 8960.0, Matiere.laiton: 8500.0,
  };

  void _applyMatiere(Matiere m) => setState(() { matiere = m; densite = densites[m] ?? densite; });

  List<String> taillesDisponibles(Serie s) {
    final list = poidsParMetre[s]!.keys.toList()..sort((a,b)=>int.parse(a).compareTo(int.parse(b)));
    return list;
  }

  double? poidsUnitaireKgM() {
    if (mode == Mode.normalise) {
      if (selectedTaille == null) return null;
      final kgmAcier = poidsParMetre[serie]![selectedTaille!];
      return kgmAcier * (densite / 7850.0);
    } else {
      final aireMm2 = switch (libre) {
        LibreProfil.tubeRond => _aireTubeRond(dExt, ep),
        LibreProfil.tubeCarre => _aireTubeCarre(cote, ep),
        LibreProfil.tubeRect => _aireTubeRect(larg, haut, ep),
        LibreProfil.carrePlein => cote * cote,
        LibreProfil.rectPlein => larg * haut,
        LibreProfil.rondPlein => math.pi * math.pow(dPlein, 2) / 4.0,
        LibreProfil.corniereEgale => _aireCorniereEgale(aile, ep),
        LibreProfil.corniereInEgale => _aireCorniereInegale(aile, aile2, ep),
        LibreProfil.te => _aireTe(aile, haut, ep),
        LibreProfil.plat => larg * ep,
      };
      final aireM2 = aireMm2 * 1e-6;
      return densite * aireM2;
    }
  }

  double _aireTubeRond(double dExtMm, double epMm) {
    final dInt=(dExtMm-2*epMm).clamp(0,double.maxFinite);
    return math.pi*(math.pow(dExtMm,2)-math.pow(dInt,2))/4.0;
  }
  double _aireTubeCarre(double coteMm,double epMm){
    final inter=(coteMm-2*epMm).clamp(0,double.maxFinite);
    return coteMm*coteMm - inter*inter;
  }
  double _aireTubeRect(double largMm,double hautMm,double epMm){
    final li=(largMm-2*epMm).clamp(0,double.maxFinite);
    final hi=(hautMm-2*epMm).clamp(0,double.maxFinite);
    return largMm*hautMm - li*hi;
  }
  double _aireCorniereEgale(double a,double e)=>2*a*e - e*e;
  double _aireCorniereInegale(double a1,double a2,double e)=>a1*e + a2*e - e*e;
  double _aireTe(double a,double h,double e)=>a*e + (h-e)*e;

  double totalPoidsKg() {
    final pUM = poidsUnitaireKgM();
    if (pUM==null) return 0;
    return pUM * longueurM * quantite;
  }
>>>>>>> 3ddf32c (first commit duduf occas)

  @override
  void initState() {
    super.initState();
<<<<<<< HEAD
    _load();
    for (final f in kShapes) {
      for (final d in f.fields) {
        shapeCtrls.putIfAbsent('${f.id}:${d.key}', () => TextEditingController());
      }
    }
  }

  Future<void> _load() async {
    final d = await AppData.load();
    setState(() {
      data = d;
      materialKey = d.pricesPerKg.keys.contains('acier') ? 'acier' : d.pricesPerKg.keys.first;
      familyKey = d.families.keys.first;
      profileKey = d.families[familyKey]!.keys.first;
    });
  }

  void _recalc() {
    if (data == null) return;
    double kg = 0.0;

    if (mode == Mode.normalise) {
      if (familyKey != null && profileKey != null) {
        final fam = data!.families[familyKey]!;
        final prof = fam[profileKey] as Map<String, dynamic>;
        final poidsM = (prof['poids_m'] as num).toDouble();
        kg = poidsM * lengthM;
      }
    } else {
      final inputs = <String, double>{};
      for (final f in shape.fields) {
        final ctrl = shapeCtrls['${shape.id}:${f.key}']!;
        final v = double.tryParse(ctrl.text.replaceAll(',', '.')) ?? 0.0;
        inputs[f.key] = v;
      }
      final areaMm2 = _areaForShape(shape.id, inputs);
      final areaM2 = _mm2ToM2(areaMm2);
      final density = data!.densitiesKgM3[materialKey] ?? 7850.0;
      kg = calcWeightKgFromArea(areaM2, lengthM, density);
    }

    final priceKg = data!.pricesPerKg[materialKey] ?? 0.0;
    double price = kg * priceKg;

    // <-- application du +25% si le bouton est coché
    if (knowsBoss) {
      price *= 1.25;
    }

    setState(() {
      weightKg = kg;
      totalPrice = price;
    });
  }

  Widget _buildNumberField(TextEditingController ctrl, String hint) {
    return SizedBox(
      width: 160,
      child: TextField(
        controller: ctrl,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText: hint,
          border: const OutlineInputBorder(),
          isDense: true,
        ),
        onChanged: (_) => _recalc(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final d = data;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Duduf Occas'),
        centerTitle: true,
      ),
      body: d == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SegmentedButton<Mode>(
                    segments: const [
                      ButtonSegment(value: Mode.libre, label: Text('Profil libre')),
                      ButtonSegment(value: Mode.normalise, label: Text('Profil normalisé')),
                    ],
                    selected: {mode},
                    onSelectionChanged: (s) {
                      setState(() => mode = s.first);
                      _recalc();
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Text('Matériau: '),
                      const SizedBox(width: 8),
                      DropdownButton<String>(
                        value: materialKey,
                        items: d.pricesPerKg.keys
                            .map((k) => DropdownMenuItem(value: k, child: Text(k)))
                            .toList(),
                        onChanged: (v) {
                          if (v == null) return;
                          setState(() => materialKey = v);
                          _recalc();
                        },
                      ),
                      const SizedBox(width: 24),
                      SizedBox(
                        width: 200,
                        child: TextField(
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(
                            isDense: true,
                            border: OutlineInputBorder(),
                            labelText: 'Longueur (m)',
                          ),
                          onChanged: (t) {
                            setState(() {
                              lengthM = double.tryParse(t.replaceAll(',', '.')) ?? 0.0;
                            });
                            _recalc();
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (mode == Mode.normalise)
                    _buildNormaliseUI(d)
                  else
                    _buildLibreUI(),
                  const SizedBox(height: 24),
                  _buildResultCard(d),
                ],
              ),
            ),
    );
  }

  Widget _buildNormaliseUI(AppData d) {
    final fams = d.families;
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          runSpacing: 12,
          spacing: 16,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            const Text('Famille:'),
            DropdownButton<String>(
              value: familyKey,
              items: fams.keys.map((f) => DropdownMenuItem(value: f, child: Text(f))).toList(),
              onChanged: (v) {
                if (v == null) return;
                setState(() {
                  familyKey = v;
                  profileKey = fams[v]!.keys.first;
                });
                _recalc();
              },
            ),
            const SizedBox(width: 12),
            const Text('Profil:'),
            DropdownButton<String>(
              value: profileKey,
              items: fams[familyKey]!.keys
                  .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                  .toList(),
              onChanged: (v) {
                if (v == null) return;
                setState(() => profileKey = v);
                _recalc();
              },
            ),
            Builder(
              builder: (context) {
                final prof = fams[familyKey]![profileKey] as Map<String, dynamic>;
                final w = (prof['poids_m'] as num).toDouble();
                return Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Text('Poids linéique: ${w.toStringAsFixed(2)} kg/m',
                      style: Theme.of(context).textTheme.bodyMedium),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLibreUI() {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButton<ShapeDef>(
              value: shape,
              items: kShapes.map((s) => DropdownMenuItem(value: s, child: Text(s.name))).toList(),
              onChanged: (v) {
                if (v == null) return;
                setState(() => shape = v);
              },
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: shape.fields.map((f) {
                final ctrl = shapeCtrls['${shape.id}:${f.key}']!;
                return _buildNumberField(ctrl, f.label);
              }).toList(),
            ),
            const SizedBox(height: 8),
            Text(
              'Unités: dimensions en mm. La longueur est en m.',
              style: Theme.of(context).textTheme.bodySmall,
            )
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard(AppData d) {
    final priceKg = d.pricesPerKg[materialKey] ?? 0.0;
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerHigh,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: DefaultTextStyle(
          style: Theme.of(context).textTheme.titleMedium!,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Résultats'),
              const SizedBox(height: 8),
              Text('Poids total: ${weightKg == null ? '—' : '${weightKg!.toStringAsFixed(2)} kg'}'),
              Text('Prix au kg (${materialKey}): ${priceKg.toStringAsFixed(2)} €'),
              Text('Prix total estimé: ${totalPrice == null ? '—' : '${totalPrice!.toStringAsFixed(2)} €'}'),
              const SizedBox(height: 12),

              // <-- Checkbox ajoutée
              CheckboxListTile(
                value: knowsBoss,
                onChanged: (v) {
                  setState(() => knowsBoss = v ?? false);
                  _recalc();
                },
                title: const Text('Je connais le patron (+25%)'),
                controlAffinity: ListTileControlAffinity.leading,
                dense: true,
                contentPadding: EdgeInsets.zero,
              ),

              Align(
                alignment: Alignment.centerLeft,
                child: FilledButton.icon(
                  onPressed: _recalc,
                  icon: const Icon(Icons.calculate),
                  label: const Text('Calculer'),
                ),
              ),
=======
    selectedTaille = taillesDisponibles(serie).first;
    _applyMatiere(matiere);
  }

  @override
  Widget build(BuildContext context) => DefaultTabController(
    length: 3,
    child: Scaffold(
      appBar: AppBar(
        title: const Text('Duduf Occas – Calcul poids ferraille'),
        bottom: const TabBar(tabs: [
          Tab(text: 'Profil'),
          Tab(text: 'Matière'),
          Tab(text: 'Résultats')
        ]),
      ),
      body: TabBarView(children: [
        _profilTab(),
        _matiereTab(),
        _resultatsTab(),
      ]),
    ),
  );

  Widget _profilTab() => SingleChildScrollView(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _modeSelector(),
        const SizedBox(height: 12),
        if (mode==Mode.normalise) _normaliseCard() else _libreCard(),
        const SizedBox(height: 16),
        _longueurEtQte(),
      ],
    ),
  );

  Widget _matiereTab() => SingleChildScrollView(
    padding: const EdgeInsets.all(16),
    child: Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(spacing: 12, runSpacing: 12, children: [
          DropdownButton<Matiere>(
            value: matiere,
            items: Matiere.values.map((m)=>DropdownMenuItem(value:m,child:Text(m.name))).toList(),
            onChanged: (v)=>_applyMatiere(v!),
          ),
          SizedBox(
            width: 220,
            child: TextFormField(
              initialValue: densite.toStringAsFixed(0),
              decoration: const InputDecoration(labelText: 'Densité (kg/m³)'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (v)=>setState(()=>densite = double.tryParse(v.replaceAll(',', '.')) ?? densite),
            ),
          ),
        ]),
      ),
    ),
  );

  Widget _resultatsTab() {
    final pUM = poidsUnitaireKgM(), total = totalPoidsKg();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Résultats', style: TextStyle(fontWeight: FontWeight.w700)),
              Text('Poids unitaire : ${pUM?.toStringAsFixed(2) ?? '—'} kg/m'),
              Text('Longueur : ${longueurM.toStringAsFixed(2)} m'),
              Text('Quantité : $quantite'),
              Text('Matière : ${matiere.name} (densité $densite kg/m³)'),
              Text('Total : ${total.toStringAsFixed(2)} kg'),
>>>>>>> 3ddf32c (first commit duduf occas)
            ],
          ),
        ),
      ),
    );
  }
<<<<<<< HEAD
=======

  Widget _modeSelector() => SegmentedButton<Mode>(
    segments: const [
      ButtonSegment(value: Mode.normalise, label: Text('Profils normalisés')),
      ButtonSegment(value: Mode.libre, label: Text('Profils libres')),
    ],
    selected: {mode},
    onSelectionChanged: (s)=>setState(()=>mode=s.first),
  );

  Widget _normaliseCard() {
    final tailles = taillesDisponibles(serie);
    if (!tailles.contains(selectedTaille)) selectedTaille = tailles.first;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Série et taille'),
          DropdownButton<Serie>(
            value: serie,
            items: Serie.values.map((s)=>DropdownMenuItem(value:s,child:Text(s.name))).toList(),
            onChanged: (v)=>setState(() {
              serie=v!;
              selectedTaille=taillesDisponibles(serie).first;
            }),
          ),
          DropdownButton<String>(
            value: selectedTaille,
            items: tailles.map((t)=>DropdownMenuItem(value:t,child:Text(t))).toList(),
            onChanged: (v)=>setState(()=>selectedTaille=v),
          ),
        ]),
      ),
    );
  }

  Widget _libreCard() => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Profil libre'),
        DropdownButton<LibreProfil>(
          value: libre,
          items: LibreProfil.values.map((p)=>DropdownMenuItem(value:p,child:Text(p.name))).toList(),
          onChanged: (v)=>setState(()=>libre=v!),
        ),
        const SizedBox(height: 8),
        _libreInputs(),
      ]),
    ),
  );

  Widget _mmField(String label,double value,void Function(double) onChanged) => SizedBox(
    width: 220,
    child: TextFormField(
      initialValue: value.toStringAsFixed(1),
      decoration: InputDecoration(labelText: label, suffixText: 'mm'),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      onChanged: (v)=>setState(()=>onChanged(double.tryParse(v.replaceAll(',', '.')) ?? value)),
    ),
  );

  Widget _longueurEtQte() => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Wrap(spacing: 12, runSpacing: 12, children: [
        SizedBox(
          width: 220,
          child: TextFormField(
            initialValue: longueurM.toStringAsFixed(2),
            decoration: const InputDecoration(labelText: 'Longueur (m)'),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (v)=>setState(()=>longueurM = double.tryParse(v.replaceAll(',', '.')) ?? longueurM),
          ),
        ),
        SizedBox(
          width: 180,
          child: TextFormField(
            initialValue: quantite.toString(),
            decoration: const InputDecoration(labelText: 'Quantité (barres)'),
            keyboardType: TextInputType.number,
            onChanged: (v)=>setState(()=>quantite = int.tryParse(v) ?? quantite),
          ),
        ),
      ]),
    ),
  );

  Widget _libreInputs() {
    switch (libre) {
      case LibreProfil.tubeRond: return Wrap(children:[_mmField('Ø ext (mm)',dExt,(v)=>dExt=v),_mmField('Épaisseur (mm)',ep,(v)=>ep=v)]);
      case LibreProfil.tubeCarre: return Wrap(children:[_mmField('Côté (mm)',cote,(v)=>cote=v),_mmField('Épaisseur (mm)',ep,(v)=>ep=v)]);
      case LibreProfil.tubeRect: return Wrap(children:[_mmField('Largeur (mm)',larg,(v)=>larg=v),_mmField('Hauteur (mm)',haut,(v)=>haut=v),_mmField('Épaisseur (mm)',ep,(v)=>ep=v)]);
      case LibreProfil.carrePlein: return _mmField('Côté (mm)',cote,(v)=>cote=v);
      case LibreProfil.rectPlein: return Wrap(children:[_mmField('Largeur (mm)',larg,(v)=>larg=v),_mmField('Hauteur (mm)',haut,(v)=>haut=v)]);
      case LibreProfil.rondPlein: return _mmField('Ø (mm)',dPlein,(v)=>dPlein=v);
      case LibreProfil.corniereEgale: return Wrap(children:[_mmField('Aile (mm)',aile,(v)=>aile=v),_mmField('Épaisseur (mm)',ep,(v)=>ep=v)]);
      case LibreProfil.corniereInEgale: return Wrap(children:[_mmField('Aile 1 (mm)',aile,(v)=>aile=v),_mmField('Aile 2 (mm)',aile2,(v)=>aile2=v),_mmField('Épaisseur (mm)',ep,(v)=>ep=v)]);
      case LibreProfil.te: return Wrap(children:[_mmField('Largeur aile (mm)',aile,(v)=>aile=v),_mmField('Hauteur (mm)',haut,(v)=>haut=v),_mmField('Épaisseur (mm)',ep,(v)=>ep=v)]);
      case LibreProfil.plat: return Wrap(children:[_mmField('Largeur (mm)',larg,(v)=>larg=v),_mmField('Épaisseur (mm)',ep,(v)=>ep=v)]);
    }
  }
>>>>>>> 3ddf32c (first commit duduf occas)
}
