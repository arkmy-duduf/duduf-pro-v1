import 'dart:math' as math;
import 'package:flutter/material.dart';

void main() => runApp(const DudufOccasApp());

class DudufOccasApp extends StatelessWidget {
  const DudufOccasApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Duduf Occas',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0EA5E9)),
        useMaterial3: true,
        inputDecorationTheme: const InputDecorationTheme(border: OutlineInputBorder()),
      ),
      home: const DudufHomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

enum Mode { normalise, libre }

class DudufHomePage extends StatefulWidget {
  const DudufHomePage({super.key});
  @override
  State<DudufHomePage> createState() => _DudufHomePageState();
}

class _DudufHomePageState extends State<DudufHomePage> {
  // Navigation
  int _navIndex = 0;

  // Mode
  Mode mode = Mode.normalise;

  // Normalisés
  String? selectedSerie;
  String? selectedTaille;

  // Libres
  String? selectedProfilLibre;
  // Dimensions (mm)
  double dExt = 100, ep = 5, cote = 100, larg = 100, haut = 50, dPlein = 30, aile = 50, aile2 = 40;

  // Matière
  String? selectedMatiere = 'Acier';
  final Map<String, double> densites = {
    'Acier': 7850,
    'Inox': 8000,
    'Aluminium': 2700,
    'Fonte': 7200,
    'Cuivre': 8960,
    'Laiton': 8500,
  };

  // Longueur & quantité (communs)
  double longueurM = 1.0;
  int quantite = 1;

  // Table kg/m acier (≈ EN 10365 usuelles)
  final Map<String, Map<String, double>> poidsParMetre = {
    'HEA': {
      '100': 17.0, '120': 20.3, '140': 25.1, '160': 31.0, '180': 36.2,
      '200': 43.1, '220': 51.5, '240': 61.5, '260': 69.5, '280': 77.8,
      '300': 90.0, '320': 99.5, '340': 107.0, '360': 114.0, '400': 127.0,
    },
    'HEB': {
      '100': 20.8, '120': 27.2, '140': 34.4, '160': 43.4, '180': 52.2,
      '200': 62.5, '220': 72.8, '240': 84.8, '260': 94.8, '280': 105.0,
      '300': 119.0, '320': 129.0, '340': 137.0, '360': 145.0, '400': 158.0,
    },
    'IPE': {
      '80': 6.00, '100': 8.10, '120': 10.4, '140': 12.9, '160': 15.8,
      '180': 18.8, '200': 22.4, '220': 26.2, '240': 30.7, '270': 36.1,
      '300': 42.2, '330': 49.1, '360': 57.1, '400': 66.3,
    },
    'IPN': {
      '80': 5.94, '100': 8.35, '120': 11.10, '140': 14.30, '160': 17.90,
      '180': 21.90, '200': 26.20, '220': 31.10, '240': 36.20, '260': 41.90,
      '280': 47.90, '300': 54.20, '320': 61.00, '340': 68.00, '360': 76.10,
      '380': 84.00, '400': 92.40,
    },
    'UPN': {
      '80': 8.82, '100': 10.8, '120': 13.6, '140': 16.3, '160': 19.2,
      '180': 22.4, '200': 25.7, '220': 30.0, '240': 33.8, '260': 38.6,
      '280': 42.7, '300': 47.0, '320': 60.6, '350': 61.8, '380': 64.3,
      '400': 73.2,
    },
    'UPE': {
      '80': 7.90, '100': 9.82, '120': 12.1, '140': 14.5, '160': 17.0,
      '180': 19.7, '200': 22.8, '220': 26.6, '240': 30.2, '270': 35.2,
      '300': 44.4, '330': 53.2, '360': 61.2, '400': 72.2,
    },
  };

  final List<String> profilsLibres = [
    'Tube rond',
    'Tube carré',
    'Tube rectangulaire',
    'Carré plein',
    'Rectangle plein',
    'Rond plein',
    'Cornière égale',
    'Cornière inégale',
    'T',
    'Plat',
  ];

  // ======== CALCULS ========
  double? _densiteSel() => densites[selectedMatiere];

  double? poidsUnitaireKgM() {
    final densite = _densiteSel();
    if (densite == null) return null;

    if (mode == Mode.normalise) {
      if (selectedSerie == null || selectedTaille == null) return null;
      final kgmAcier = poidsParMetre[selectedSerie!]![selectedTaille!];
      if (kgmAcier == null) return null;
      return kgmAcier * (densite / 7850.0);
    } else {
      // Profils libres: aire (mm²) -> m² -> kg/m
      final aireMm2 = switch (selectedProfilLibre) {
        'Tube rond' => _aireTubeRond(dExt, ep),
        'Tube carré' => _aireTubeCarre(cote, ep),
        'Tube rectangulaire' => _aireTubeRect(larg, haut, ep),
        'Carré plein' => cote * cote,
        'Rectangle plein' => larg * haut,
        'Rond plein' => math.pi * math.pow(dPlein, 2) / 4.0,
        'Cornière égale' => _aireCorniereEgale(aile, ep),
        'Cornière inégale' => _aireCorniereInegale(aile, aile2, ep),
        'T' => _aireTe(aile, haut, ep),
        'Plat' => larg * ep,
        _ => null,
      };
      if (aireMm2 == null) return null;
      final aireM2 = aireMm2 * 1e-6;
      return densite * aireM2;
    }
  }

  double? poidsTotalKg() {
    final pu = poidsUnitaireKgM();
    if (pu == null) return null;
    return pu * longueurM * quantite;
  }

  // Aires (mm²) sécurisées (clamp)
  double _aireTubeRond(double D, double t) {
    final dInt = (D - 2 * t).clamp(0, double.infinity);
    return math.pi * (math.pow(D, 2) - math.pow(dInt, 2)) / 4.0;
    // Option coins arrondis ignorée pour simplicité (écart faible)
  }

  double _aireTubeCarre(double a, double t) {
    final ai = (a - 2 * t).clamp(0, double.infinity);
    return a * a - ai * ai;
  }

  double _aireTubeRect(double a, double b, double t) {
    final ai = (a - 2 * t).clamp(0, double.infinity);
    final bi = (b - 2 * t).clamp(0, double.infinity);
    return a * b - ai * bi;
  }

  double _aireCorniereEgale(double a, double t) => (2 * a - t).clamp(0, double.infinity) * t;
  double _aireCorniereInegale(double a1, double a2, double t) => (a1 + a2 - t).clamp(0, double.infinity) * t;
  double _aireTe(double aile, double h, double t) => (aile * t + (h - t).clamp(0, double.infinity) * t);

  // ======== UI ========
  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      _pageCalcul(context),
      _pageMatiere(context),
      _pageResultats(context),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Duduf Occas'), centerTitle: true),
      body: AnimatedSwitcher(duration: const Duration(milliseconds: 200), child: pages[_navIndex]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _navIndex,
        onDestinationSelected: (i) => setState(() => _navIndex = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.straighten), label: 'Calcul'),
          NavigationDestination(icon: Icon(Icons.category), label: 'Matière'),
          NavigationDestination(icon: Icon(Icons.summarize), label: 'Résultats'),
        ],
      ),
    );
  }

  Widget _pageCalcul(BuildContext context) {
    final pu = poidsUnitaireKgM();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        // Choix mode
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SegmentedButton<Mode>(
              segments: const [
                ButtonSegment(value: Mode.normalise, label: Text('Normalisé'), icon: Icon(Icons.account_tree)),
                ButtonSegment(value: Mode.libre, label: Text('Libre'), icon: Icon(Icons.tune)),
              ],
              selected: {mode},
              onSelectionChanged: (s) => setState(() {
                mode = s.first;
                // reset spécifiques
                selectedSerie = null;
                selectedTaille = null;
                selectedProfilLibre = null;
              }),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Bloc profil
        if (mode == Mode.normalise) _normaliseCard() else _libreCard(),
        const SizedBox(height: 12),

        // Longueur & quantité (communs à TOUT)
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(spacing: 12, runSpacing: 12, children: [
              _numField(
                label: 'Longueur (m)',
                initial: longueurM.toStringAsFixed(2),
                onChanged: (v) => setState(() => longueurM = _toDouble(v, longueurM)),
              ),
              _intField(
                label: 'Quantité',
                initial: quantite.toString(),
                onChanged: (v) => setState(() => quantite = _toInt(v, quantite)),
              ),
            ]),
          ),
        ),

        const SizedBox(height: 12),
        if (pu != null) _ResultBadge(title: 'Poids unitaire', value: '${pu.toStringAsFixed(2)} kg/m', icon: Icons.scale),
      ]),
    );
  }

  Widget _pageMatiere(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            DropdownButtonFormField<String>(
              value: selectedMatiere,
              decoration: const InputDecoration(labelText: 'Matière'),
              items: densites.keys.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
              onChanged: (v) => setState(() => selectedMatiere = v),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('Densités (kg/m³)'),
              subtitle: Text(densites.entries.map((e) => '${e.key}: ${e.value.toStringAsFixed(0)}').join(' · ')),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _pageResultats(BuildContext context) {
    final pu = poidsUnitaireKgM();
    final total = poidsTotalKg();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              const Text('Récapitulatif', style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Wrap(spacing: 8, runSpacing: 8, children: [
                Chip(label: Text('Mode: ${mode == Mode.normalise ? 'Normalisé' : 'Libre'}')),
                if (mode == Mode.normalise && selectedSerie != null && selectedTaille != null)
                  Chip(label: Text('${selectedSerie!} ${selectedTaille!}')),
                if (mode == Mode.libre && selectedProfilLibre != null) Chip(label: Text(selectedProfilLibre!)),
                Chip(label: Text('Matière: ${selectedMatiere ?? '—'}')),
                Chip(label: Text('Longueur: ${longueurM.toStringAsFixed(2)} m')),
                Chip(label: Text('Quantité: $quantite')),
              ]),
              const SizedBox(height: 16),
              if (pu != null) _HeroTotal(value: '${pu.toStringAsFixed(2)} kg/m', caption: 'Poids unitaire'),
              const SizedBox(height: 8),
              if (total != null) _HeroTotal(value: '${total.toStringAsFixed(2)} kg', caption: 'Poids total'),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: (total ?? 0) <= 0
                    ? null
                    : () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Total copié: ${total!.toStringAsFixed(2)} kg (à venir)')),
                        );
                      },
                icon: const Icon(Icons.share),
                label: const Text('Partager'),
              ),
            ]),
          ),
        ),
      ]),
    );
  }

  // ======== WIDGETS FONCTIONNELS ========
  Widget _normaliseCard() {
    final series = poidsParMetre.keys.toList()..sort();
    final tailles = (selectedSerie == null)
        ? <String>[]
        : (poidsParMetre[selectedSerie!]!.keys.toList()
          ..sort((a, b) => int.parse(a).compareTo(int.parse(b))));

    // Calcul preview
    double? base, scaled;
    final densite = _densiteSel();
    if (selectedSerie != null && selectedTaille != null) {
      base = poidsParMetre[selectedSerie!]![selectedTaille!];
      if (base != null && densite != null) {
        scaled = base * (densite / 7850.0);
      }
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          DropdownButtonFormField<String>(
            value: selectedSerie,
            decoration: const InputDecoration(labelText: 'Série'),
            items: series.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
            onChanged: (v) => setState(() {
              selectedSerie = v;
              selectedTaille = null;
            }),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: selectedTaille,
            decoration: const InputDecoration(labelText: 'Taille (mm)'),
            items: tailles.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
            onChanged: (v) => setState(() => selectedTaille = v),
          ),
          if (base != null && scaled != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'kg/m (acier): ${base.toStringAsFixed(2)} — '
                'kg/m (${selectedMatiere ?? 'matière'}): ${scaled.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ),
        ]),
      ),
    );
  }

  Widget _libreCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          DropdownButtonFormField<String>(
            value: selectedProfilLibre,
            decoration: const InputDecoration(labelText: 'Profil libre'),
            items: profilsLibres.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
            onChanged: (v) => setState(() => selectedProfilLibre = v),
          ),
          const SizedBox(height: 12),
          if (selectedProfilLibre != null) _libreInputs(),
        ]),
      ),
    );
  }

  Widget _libreInputs() {
    // champs dimensionnels en mm
    switch (selectedProfilLibre) {
      case 'Tube rond':
        return _wrapFields([
          _mmField('Ø extérieur (mm)', dExt, (v) => dExt = v),
          _mmField('Épaisseur (mm)', ep, (v) => ep = v),
        ]);
      case 'Tube carré':
        return _wrapFields([
          _mmField('Côté (mm)', cote, (v) => cote = v),
          _mmField('Épaisseur (mm)', ep, (v) => ep = v),
        ]);
      case 'Tube rectangulaire':
        return _wrapFields([
          _mmField('Largeur (mm)', larg, (v) => larg = v),
          _mmField('Hauteur (mm)', haut, (v) => haut = v),
          _mmField('Épaisseur (mm)', ep, (v) => ep = v),
        ]);
      case 'Carré plein':
        return _wrapFields([_mmField('Côté (mm)', cote, (v) => cote = v)]);
      case 'Rectangle plein':
        return _wrapFields([
          _mmField('Largeur (mm)', larg, (v) => larg = v),
          _mmField('Hauteur (mm)', haut, (v) => haut = v),
        ]);
      case 'Rond plein':
        return _wrapFields([_mmField('Ø (mm)', dPlein, (v) => dPlein = v)]);
      case 'Cornière égale':
        return _wrapFields([
          _mmField('Aile (mm)', aile, (v) => aile = v),
          _mmField('Épaisseur (mm)', ep, (v) => ep = v),
        ]);
      case 'Cornière inégale':
        return _wrapFields([
          _mmField('Aile 1 (mm)', aile, (v) => aile = v),
          _mmField('Aile 2 (mm)', aile2, (v) => aile2 = v),
          _mmField('Épaisseur (mm)', ep, (v) => ep = v),
        ]);
      case 'T':
        return _wrapFields([
          _mmField('Largeur aile (mm)', aile, (v) => aile = v),
          _mmField('Hauteur (mm)', haut, (v) => haut = v),
          _mmField('Épaisseur (mm)', ep, (v) => ep = v),
        ]);
      case 'Plat':
        return _wrapFields([
          _mmField('Largeur (mm)', larg, (v) => larg = v),
          _mmField('Épaisseur (mm)', ep, (v) => ep = v),
        ]);
      default:
        return const SizedBox.shrink();
    }
  }

  // ======== Helpers UI ========
  Widget _wrapFields(List<Widget> children) =>
      Wrap(spacing: 12, runSpacing: 12, children: children);

  Widget _mmField(String label, double value, void Function(double) onChanged) {
    return SizedBox(
      width: 220,
      child: TextFormField(
        initialValue: value.toStringAsFixed(1),
        decoration: InputDecoration(labelText: label, suffixText: 'mm'),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        onChanged: (v) => setState(() => onChanged(_toDouble(v, value))),
      ),
    );
  }

  Widget _numField({required String label, required String initial, required void Function(String) onChanged}) {
    return SizedBox(
      width: 220,
      child: TextFormField(
        initialValue: initial,
        decoration: InputDecoration(labelText: label),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        onChanged: onChanged,
      ),
    );
  }

  Widget _intField({required String label, required String initial, required void Function(String) onChanged}) {
    return SizedBox(
      width: 160,
      child: TextFormField(
        initialValue: initial,
        decoration: InputDecoration(labelText: label),
        keyboardType: TextInputType.number,
        onChanged: onChanged,
      ),
    );
  }

  double _toDouble(String s, double fallback) =>
      double.tryParse(s.replaceAll(',', '.')) ?? fallback;
  int _toInt(String s, int fallback) => int.tryParse(s) ?? fallback;
}

// ======== Widgets décoratifs ========
class _ResultBadge extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  const _ResultBadge({required this.title, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(color: cs.primaryContainer, borderRadius: BorderRadius.circular(16)),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(children: [
        Icon(icon, size: 28, color: cs.onPrimaryContainer),
        const SizedBox(width: 12),
        Expanded(child: Text(title, style: TextStyle(color: cs.onPrimaryContainer))),
        Text(value, style: TextStyle(fontWeight: FontWeight.w700, color: cs.onPrimaryContainer)),
      ]),
    );
  }
}

class _HeroTotal extends StatelessWidget {
  final String value;
  final String caption;
  const _HeroTotal({required this.value, required this.caption});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [cs.primary, cs.secondary]),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Text(value, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 6),
          Text(caption, style: const TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }
}
