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
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2563EB),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        visualDensity: VisualDensity.standard,
        appBarTheme: const AppBarTheme(centerTitle: true),
        navigationBarTheme: const NavigationBarThemeData(
          height: 70,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          indicatorShape: StadiumBorder(),
        ),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
          filled: true,
          fillColor: Color(0xFFF7F8FA),
          contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
        cardTheme: const CardTheme(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: ButtonStyle(
            shape: WidgetStatePropertyAll(
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            padding: const WidgetStatePropertyAll(
              EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ),
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

  // Prix €/kg (modifiable)
  final Map<String, double> prixKg = {
    'Acier': 1.30,
    'Aluminium': 5.00,
    'Inox': 5.00,
    'Fonte': 2.00,
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
  double? _prixKgSel() => selectedMatiere == null ? null : prixKg[selectedMatiere!];

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

  double? prixTotalEuro() {
    final tot = poidsTotalKg();
    final pKg = _prixKgSel();
    if (tot == null || pKg == null) return null;
    return tot * pKg;
  }

  // Aires (mm²) sécurisées (clamp)
  double _aireTubeRond(double D, double t) {
    final dInt = (D - 2 * t).clamp(0, double.infinity);
    return math.pi * (math.pow(D, 2) - math.pow(dInt, 2)) / 4.0;
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
      appBar: AppBar(
        title: const Text('Duduf Occas'),
        actions: const [SizedBox(width: 8)],
      ),
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

  // ======== PAGES ========
  Widget _pageCalcul(BuildContext context) {
    final pu = poidsUnitaireKgM();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          SectionCard(
            title: 'Mode de calcul',
            children: [
              SegmentedButton<Mode>(
                segments: const [
                  ButtonSegment(value: Mode.normalise, label: Text('Normalisé'), icon: Icon(Icons.account_tree)),
                  ButtonSegment(value: Mode.libre, label: Text('Libre'), icon: Icon(Icons.tune)),
                ],
                selected: {mode},
                onSelectionChanged: (s) => setState(() {
                  mode = s.first;
                  selectedSerie = null;
                  selectedTaille = null;
                  selectedProfilLibre = null;
                }),
              ),
            ],
          ),

          const SizedBox(height: 12),

          if (mode == Mode.normalise)
            SectionCard(
              title: 'Profil normalisé',
              subtitle: 'Choisis la série et la taille',
              children: [_normaliseCardInner()],
            )
          else
            SectionCard(
              title: 'Profil libre',
              subtitle: 'Renseigne les dimensions (en mm)',
              children: [_libreCardInner()],
            ),

          const SizedBox(height: 12),

          SectionCard(
            title: 'Longueur & quantité',
            children: [
              Wrap(
                spacing: 12,
                runSpacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  LabeledNumberField(
                    label: 'Longueur',
                    unit: 'm',
                    value: longueurM,
                    icon: Icons.straighten,
                    onChanged: (v) => setState(() => longueurM = v.clamp(0.01, 9999)),
                  ),
                  QuantityStepper(
                    value: quantite,
                    onChanged: (v) => setState(() => quantite = v.clamp(1, 9999)),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 12),
          if (pu != null) _ResultBadge(title: 'Poids unitaire', value: '${pu.toStringAsFixed(2)} kg/m', icon: Icons.scale),
        ],
      ),
    );
  }

  Widget _pageMatiere(BuildContext context) {
    final pKg = _prixKgSel();
    final controller = TextEditingController(text: pKg != null ? pKg.toStringAsFixed(2) : '');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          SectionCard(
            title: 'Matière',
            subtitle: 'Densité et tarif appliqués aux calculs',
            children: [
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
            ],
          ),
          const SizedBox(height: 12),
          SectionCard(
            title: 'Tarif €/kg',
            subtitle: 'Modifie le prix de la matière sélectionnée',
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: controller,
                      decoration: const InputDecoration(
                        labelText: 'Tarif (€/kg)',
                        prefixIcon: Icon(Icons.euro),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      onChanged: (v) {
                        final val = double.tryParse(v.replaceAll(',', '.'));
                        if (selectedMatiere != null && val != null) {
                          setState(() {
                            prixKg[selectedMatiere!] = val;
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.tonal(
                    onPressed: (selectedMatiere == null)
                        ? null
                        : () {
                            final defaults = {
                              'Acier': 1.30,
                              'Aluminium': 5.00,
                              'Inox': 5.00,
                              'Fonte': 2.00,
                            };
                            if (defaults.containsKey(selectedMatiere)) {
                              setState(() {
                                prixKg[selectedMatiere!] = defaults[selectedMatiere]!;
                              });
                              controller.text = defaults[selectedMatiere]!.toStringAsFixed(2);
                            }
                          },
                    child: const Text('Par défaut'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: const Icon(Icons.price_change),
                title: const Text('Récap tarifs'),
                subtitle: Text(
                  ['Acier', 'Aluminium', 'Inox', 'Fonte']
                      .map((k) => '$k: ${prixKg[k]?.toStringAsFixed(2) ?? '—'} €')
                      .join(' · '),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _pageResultats(BuildContext context) {
    final pu = poidsUnitaireKgM();
    final total = poidsTotalKg();
    final prixKgSel = _prixKgSel();
    final prixTotal = prixTotalEuro();

    String fmtKg(num v) => v.toStringAsFixed(2);
    String fmtEur(num v) => '${v.toStringAsFixed(2)} €';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          SectionCard(
            title: 'Récapitulatif',
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  Chip(label: Text('Mode: ${mode == Mode.normalise ? 'Normalisé' : 'Libre'}')),
                  if (mode == Mode.normalise && selectedSerie != null && selectedTaille != null)
                    Chip(label: Text('${selectedSerie!} ${selectedTaille!}')),
                  if (mode == Mode.libre && selectedProfilLibre != null) Chip(label: Text(selectedProfilLibre!)),
                  Chip(label: Text('Matière: ${selectedMatiere ?? '—'}')),
                  Chip(label: Text('Longueur: ${longueurM.toStringAsFixed(2)} m')),
                  Chip(label: Text('Quantité: $quantite')),
                ],
              ),
              const SizedBox(height: 16),
              if (pu != null) _HeroTotal(value: '${fmtKg(pu)} kg/m', caption: 'Poids unitaire'),
              const SizedBox(height: 8),
              if (total != null) _HeroTotal(value: '${fmtKg(total)} kg', caption: 'Poids total'),
            ],
          ),
          const SizedBox(height: 12),
          SectionCard(
            title: 'Prix',
            children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('Tarif matière (€/kg)'),
                Text(prixKgSel != null ? fmtEur(prixKgSel) : '—'),
              ]),
              const SizedBox(height: 6),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('Prix total', style: TextStyle(fontWeight: FontWeight.w700)),
                Text(prixTotal != null ? fmtEur(prixTotal) : '—',
                    style: const TextStyle(fontWeight: FontWeight.w700)),
              ]),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: (total ?? 0) <= 0
                    ? null
                    : () {
                        final msg = StringBuffer()
                          ..writeln('Duduf Occas — Récap')
                          ..writeln('Matière: ${selectedMatiere ?? '—'}')
                          ..writeln('Poids unitaire: ${pu != null ? fmtKg(pu) : '—'} kg/m')
                          ..writeln('Longueur: ${longueurM.toStringAsFixed(2)} m')
                          ..writeln('Quantité: $quantite')
                          ..writeln('Poids total: ${total != null ? fmtKg(total) : '—'} kg')
                          ..writeln('Tarif: ${prixKgSel != null ? fmtEur(prixKgSel!) : '—'} / kg')
                          ..writeln('Prix total: ${prixTotal != null ? fmtEur(prixTotal!) : '—'}');
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('À partager plus tard:\n${msg.toString()}')),
                        );
                      },
                icon: const Icon(Icons.share),
                label: const Text('Partager'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ======== BLOCS UI DÉCO/UX ========
  Widget _normaliseCardInner() {
    final series = poidsParMetre.keys.toList()..sort();
    final tailles = (selectedSerie == null)
        ? <String>[]
        : (poidsParMetre[selectedSerie!]!.keys.toList()
          ..sort((a, b) => int.parse(a).compareTo(int.parse(b))));

    double? base, scaled;
    final densite = _densiteSel();
    if (selectedSerie != null && selectedTaille != null) {
      base = poidsParMetre[selectedSerie!]![selectedTaille!];
      if (base != null && densite != null) {
        scaled = base * (densite / 7850.0);
      }
    }

    return Column(
      children: [
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
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('kg/m (acier)'),
                Text(base.toStringAsFixed(2)),
              ],
            ),
          ),
        if (scaled != null)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('kg/m (${selectedMatiere ?? 'matière'})'),
              Text(scaled.toStringAsFixed(2), style: const TextStyle(fontWeight: FontWeight.w700)),
            ],
          ),
      ],
    );
  }

  Widget _libreCardInner() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          value: selectedProfilLibre,
          decoration: const InputDecoration(labelText: 'Profil libre'),
          items: profilsLibres.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
          onChanged: (v) => setState(() => selectedProfilLibre = v),
        ),
        const SizedBox(height: 12),
        if (selectedProfilLibre != null) _libreInputs(),
      ],
    );
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

// ======== Widgets UX supplémentaires ========
class SectionCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget> children;
  const SectionCard({super.key, required this.title, this.subtitle, required this.children});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      surfaceTintColor: cs.primary,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(subtitle!, style: TextStyle(color: Colors.grey[700])),
            ],
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}

class QuantityStepper extends StatelessWidget {
  final int value;
  final void Function(int) onChanged;
  const QuantityStepper({super.key, required this.value, required this.onChanged});
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton.outlined(
          onPressed: () => onChanged(value > 1 ? value - 1 : 1),
          icon: const Icon(Icons.remove),
        ),
        SizedBox(
          width: 80,
          child: TextFormField(
            textAlign: TextAlign.center,
            initialValue: value.toString(),
            keyboardType: TextInputType.number,
            onChanged: (v) => onChanged(int.tryParse(v) ?? value),
          ),
        ),
        IconButton.filled(
          onPressed: () => onChanged(value + 1),
          icon: const Icon(Icons.add),
        ),
      ],
    );
  }
}

class LabeledNumberField extends StatelessWidget {
  final String label;
  final String unit;
  final double value;
  final IconData? icon;
  final void Function(double) onChanged;
  const LabeledNumberField({
    super.key,
    required this.label,
    required this.unit,
    required this.value,
    required this.onChanged,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: TextFormField(
        initialValue: value.toStringAsFixed(2),
        decoration: InputDecoration(
          labelText: label,
          suffixText: unit,
          prefixIcon: icon != null ? Icon(icon) : null,
        ),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        onChanged: (v) => onChanged(double.tryParse(v.replaceAll(',', '.')) ?? value),
      ),
    );
  }
}
