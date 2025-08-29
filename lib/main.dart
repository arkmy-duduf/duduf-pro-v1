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
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Duduf Occas',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFB86B21)),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

/// Données chargées depuis les JSON.
class AppData {
  final Map<String, double> densitiesKgM3; // acier, inox, aluminium, fonte…
  final Map<String, double> pricesPerKg;   // € / kg
  final Map<String, Map<String, dynamic>> families; // HEA/HEB/IPE/UPN/UPE

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
    for (final key in ['HEA','HEB','IPE','UPN','UPE','IPN']) {
      if (profiles.containsKey(key)) {
        // chaque profil = { "poids_m": <num>, ... }
        final raw = profiles[key] as Map<String, dynamic>;
        // on s’assure d’avoir un Map<String, Map<String,dynamic>>
        fams[key] = raw.map((k, v) => MapEntry(k.toString(), v as Map<String, dynamic>));
      }
    }

    final pricesMap = (prices as Map)
        .map((k, v) => MapEntry(k.toString(), (v as num).toDouble()));

    return AppData(
      densitiesKgM3: densities,
      pricesPerKg: pricesMap,
      families: fams,
    );
  }
}

enum Mode { normalise, libre }

class ShapeDef {
  final String id;
  final String name;
  final List<DimField> fields; // mm
  const ShapeDef({required this.id, required this.name, required this.fields});
}

class DimField {
  final String key;
  final String label;
  const DimField(this.key, this.label);
}

// Profils « libres » (dimensions en mm)
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
    fields: [DimField('l_ext','Largeur (mm)'), DimField('h_ext','Hauteur (mm)'), DimField('e','Épaisseur (mm)')],
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

  // ✅ bouton « Je connais le patron » (décoché par défaut)
  bool _knowBoss = false;

  double? weightKg;
  double? totalPrice;

  @override
  void initState() {
    super.initState();
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
        final poidsM = (prof['poids_m'] as num).toDouble(); // kg/m
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
    var price = kg * priceKg;

    // ✅ maj +25% si checkbox cochée
    if (_knowBoss) price *= 1.25;

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
              Align(
                alignment: Alignment.centerLeft,
                child: FilledButton.icon(
                  onPressed: _recalc,
                  icon: const Icon(Icons.calculate),
                  label: const Text('Calculer'),
                ),
              ),
              const SizedBox(height: 8),
              // ✅ la checkbox « Je connais le patron » (décochée par défaut)
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                title: const Text('Je connais le patron (+25%)'),
                value: _knowBoss,
                onChanged: (val) {
                  setState(() => _knowBoss = val ?? false);
                  _recalc();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
