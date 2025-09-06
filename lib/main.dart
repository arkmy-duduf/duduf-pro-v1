import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() => runApp(const DudufOccasApp());

class DudufOccasApp extends StatelessWidget {
  const DudufOccasApp({super.key});
  @override
  Widget build(BuildContext context) {
    // Palette “métal industriel”
    const steel = Color(0xFF2B2F36); // gris anthracite
    const steelDark = Color(0xFF1F2329);
    const steelLight = Color(0xFF3A3F47);
    const accent = Color(0xFFFF8C1A); // orange chaud “atelier”

    final colorScheme = ColorScheme.fromSeed(
      seedColor: accent,
      brightness: Brightness.dark,
      primary: accent,
      onPrimary: Colors.black,
      surface: steel,
      onSurface: Colors.white,
      secondary: steelLight,
    );

    return MaterialApp(
      title: 'Duduf Occas',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: colorScheme,
        scaffoldBackgroundColor: steelDark,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.white.withOpacity(0.12)),
            borderRadius: const BorderRadius.all(Radius.circular(12)),
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.white.withOpacity(0.12)),
            borderRadius: const BorderRadius.all(Radius.circular(12)),
          ),
          focusedBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: accent, width: 1.5),
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
          filled: true,
          fillColor: steel.withOpacity(0.6),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          labelStyle: TextStyle(color: Colors.white.withOpacity(0.9)),
        ),
        cardTheme: CardTheme(
          color: steel.withOpacity(0.8),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: const BorderRadius.all(Radius.circular(16)),
            side: BorderSide(color: Colors.white.withOpacity(0.08)),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: ButtonStyle(
            backgroundColor: const WidgetStatePropertyAll(accent),
            foregroundColor: const WidgetStatePropertyAll(Colors.black),
            shape: WidgetStatePropertyAll(
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            padding: const WidgetStatePropertyAll(
              EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ),
        iconButtonTheme: IconButtonThemeData(
          style: ButtonStyle(
            backgroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.pressed)) {
                return accent.withOpacity(0.2);
              }
              return Colors.white.withOpacity(0.06);
            }),
            foregroundColor: const WidgetStatePropertyAll(Colors.white),
            shape: WidgetStatePropertyAll(
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        navigationBarTheme: NavigationBarThemeData(
          height: 70,
          backgroundColor: steel,
          indicatorColor: accent.withOpacity(0.15),
          labelTextStyle: const WidgetStatePropertyAll(
            TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ),
      home: const DudufHomePage(),
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
  int _navIndex = 0;
  Mode mode = Mode.normalise;

  // Sélections
  String? selectedSerie;
  String? selectedTaille;
  String? selectedProfilLibre;
  String? selectedMatiere = 'Acier';

  // Valeurs numériques (stock)
  double dExt = 100, ep = 5, cote = 100, larg = 100, haut = 50, dPlein = 30, aile = 50, aile2 = 40;
  double longueurM = 1.0;
  int quantite = 1;

  // Controllers (champs libres + sélection auto)
  final _lenCtrl = TextEditingController(text: '1');
  final _qtyCtrl = TextEditingController(text: '1');
  final _prixCtrl = TextEditingController();

  final _dExtCtrl = TextEditingController(text: '100');
  final _epCtrl = TextEditingController(text: '5');
  final _coteCtrl = TextEditingController(text: '100');
  final _largCtrl = TextEditingController(text: '100');
  final _hautCtrl = TextEditingController(text: '50');
  final _dPleinCtrl = TextEditingController(text: '30');
  final _aileCtrl = TextEditingController(text: '50');
  final _aile2Ctrl = TextEditingController(text: '40');

  // Filtre simple pour chiffres + , .
  final List<TextInputFormatter> _numFormatters = [
    FilteringTextInputFormatter.allow(RegExp(r'[0-9\.,]')),
  ];

  // Tables normalisées (kg/m acier ≈ EN 10365 usuelles)
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

  // Profils libres disponibles
  final List<String> profilsLibres = [
    'Tube rond', 'Tube carré', 'Tube rectangulaire',
    'Carré plein', 'Rectangle plein', 'Rond plein',
    'Cornière égale', 'Cornière inégale', 'T', 'Plat',
  ];

  // Densités kg/m3
  final Map<String, double> densites = {
    'Acier': 7850, 'Inox': 8000, 'Aluminium': 2700, 'Fonte': 7200, 'Cuivre': 8960, 'Laiton': 8500,
  };

  // Prix €/kg (éditables)
  final Map<String, double> prixKg = {
    'Acier': 1.30, 'Aluminium': 5.00, 'Inox': 5.00, 'Fonte': 2.00,
  };

  @override
  void initState() {
    super.initState();
    // Longueur
    _lenCtrl.addListener(() {
      final v = _parseD(_lenCtrl.text, longueurM);
      if (v != longueurM) setState(() => longueurM = v);
    });
    // Quantité
    _qtyCtrl.addListener(() {
      final iv = int.tryParse(_qtyCtrl.text.replaceAll(RegExp(r'[^0-9]'), ''));
      if (iv != null && iv > 0 && iv != quantite) setState(() => quantite = iv);
    });

    // Profils libres
    _bind(_dExtCtrl, (v) => dExt = v, dExt);
    _bind(_epCtrl, (v) => ep = v, ep);
    _bind(_coteCtrl, (v) => cote = v, cote);
    _bind(_largCtrl, (v) => larg = v, larg);
    _bind(_hautCtrl, (v) => haut = v, haut);
    _bind(_dPleinCtrl, (v) => dPlein = v, dPlein);
    _bind(_aileCtrl, (v) => aile = v, aile);
    _bind(_aile2Ctrl, (v) => aile2 = v, aile2);

    // Tarif (€/kg)
    _syncPrixCtrlWithMatiere();
    _prixCtrl.addListener(() {
      final v = _parseD(_prixCtrl.text, prixKg[selectedMatiere] ?? 0);
      if (selectedMatiere != null) {
        setState(() {
          prixKg[selectedMatiere!] = v;
        });
      }
    });
  }

  void _bind(TextEditingController c, void Function(double) setVal, double initial) {
    c.addListener(() {
      final v = _parseD(c.text, initial);
      if (!mounted) return;
      setState(() => setVal(v));
    });
  }

  // ======== CALCULS ========
  double? _densiteSel() => selectedMatiere == null ? null : densites[selectedMatiere!];
  double? _prixKgSel() => selectedMatiere == null ? null : prixKg[selectedMatiere!];

  double? poidsUnitaireKgM() {
    final densite = _densiteSel();
    if (densite == null) return null;

    if (mode == Mode.normalise) {
      if (selectedSerie == null || selectedTaille == null) return null;
      final kgmAcier = poidsParMetre[selectedSerie!]?[selectedTaille!];
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
      final aireM2 = aireMm2 * 1e-6; // mm² -> m²
      return densite * aireM2; // kg/m
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

  // Aires (mm²) avec sécurité
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
    return Container(
      // Fond acier “brossé” simple (dégradé)
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1A1D22), Color(0xFF0F1114)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          toolbarHeight: 68,
          title: Image.asset(
            'assets/logo.png',
            height: 34,
            fit: BoxFit.contain,
          ),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
        ),
        body: IndexedStack(index: _navIndex, children: pages),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _navIndex,
          onDestinationSelected: (i) => setState(() => _navIndex = i),
          destinations: const [
            NavigationDestination(icon: Icon(Icons.straighten), label: 'Calcul'),
            NavigationDestination(icon: Icon(Icons.category), label: 'Matière'),
            NavigationDestination(icon: Icon(Icons.summarize), label: 'Résultats'),
          ],
        ),
      ),
    );
  }

  Widget _pageCalcul(BuildContext context) {
    final pu = poidsUnitaireKgM();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
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
          SectionCard(title: 'Profil normalisé', children: [_normaliseCardInner()])
        else
          SectionCard(title: 'Profil libre', children: [_libreCardInner(), const SizedBox(height: 8), _libreInputs()]),
        const SizedBox(height: 12),
        SectionCard(
          title: 'Longueur & quantité',
          children: [
            Wrap(spacing: 12, runSpacing: 12, crossAxisAlignment: WrapCrossAlignment.center, children: [
              _freeNumField(label: 'Longueur', unit: 'm', controller: _lenCtrl),
              _quantityField(),
            ]),
          ],
        ),
        if (pu != null)
          _ResultBadge(title: 'Poids unitaire', value: '${pu.toStringAsFixed(2)} kg/m', icon: Icons.scale),
      ]),
    );
  }

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

    return Column(children: [
      DropdownButtonFormField<String>(
        value: selectedSerie,
        decoration: const InputDecoration(labelText: 'Série'),
        items: series.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
        onChanged: (v) => setState(() { selectedSerie = v; selectedTaille = null; }),
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
    ]);
  }

  Widget _libreCardInner() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      DropdownButtonFormField<String>(
        value: selectedProfilLibre,
        decoration: const InputDecoration(labelText: 'Profil libre'),
        items: profilsLibres.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
        onChanged: (v) => setState(() => selectedProfilLibre = v),
      ),
    ]);
  }

  Widget _libreInputs() {
    if (selectedProfilLibre == null) return const SizedBox.shrink();
    switch (selectedProfilLibre) {
      case 'Tube rond':
        return _wrapFields([
          _freeNumField(label: 'Ø extérieur', unit: 'mm', controller: _dExtCtrl),
          _freeNumField(label: 'Épaisseur', unit: 'mm', controller: _epCtrl),
        ]);
      case 'Tube carré':
        return _wrapFields([
          _freeNumField(label: 'Côté', unit: 'mm', controller: _coteCtrl),
          _freeNumField(label: 'Épaisseur', unit: 'mm', controller: _epCtrl),
        ]);
      case 'Tube rectangulaire':
        return _wrapFields([
          _freeNumField(label: 'Largeur', unit: 'mm', controller: _largCtrl),
          _freeNumField(label: 'Hauteur', unit: 'mm', controller: _hautCtrl),
          _freeNumField(label: 'Épaisseur', unit: 'mm', controller: _epCtrl),
        ]);
      case 'Carré plein':
        return _wrapFields([
          _freeNumField(label: 'Côté', unit: 'mm', controller: _coteCtrl),
        ]);
      case 'Rectangle plein':
        return _wrapFields([
          _freeNumField(label: 'Largeur', unit: 'mm', controller: _largCtrl),
          _freeNumField(label: 'Hauteur', unit: 'mm', controller: _hautCtrl),
        ]);
      case 'Rond plein':
        return _wrapFields([
          _freeNumField(label: 'Ø', unit: 'mm', controller: _dPleinCtrl),
        ]);
      case 'Cornière égale':
        return _wrapFields([
          _freeNumField(label: 'Aile', unit: 'mm', controller: _aileCtrl),
          _freeNumField(label: 'Épaisseur', unit: 'mm', controller: _epCtrl),
        ]);
      case 'Cornière inégale':
        return _wrapFields([
          _freeNumField(label: 'Aile 1', unit: 'mm', controller: _aileCtrl),
          _freeNumField(label: 'Aile 2', unit: 'mm', controller: _aile2Ctrl),
          _freeNumField(label: 'Épaisseur', unit: 'mm', controller: _epCtrl),
        ]);
      case 'T':
        return _wrapFields([
          _freeNumField(label: 'Largeur aile', unit: 'mm', controller: _aileCtrl),
          _freeNumField(label: 'Hauteur', unit: 'mm', controller: _hautCtrl),
          _freeNumField(label: 'Épaisseur', unit: 'mm', controller: _epCtrl),
        ]);
      case 'Plat':
        return _wrapFields([
          _freeNumField(label: 'Largeur', unit: 'mm', controller: _largCtrl),
          _freeNumField(label: 'Épaisseur', unit: 'mm', controller: _epCtrl),
        ]);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _pageMatiere(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        SectionCard(
          title: 'Matière',
          children: [
            DropdownButtonFormField<String>(
              value: selectedMatiere,
              decoration: const InputDecoration(labelText: 'Matière'),
              items: densites.keys.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
              onChanged: (v) => setState(() {
                selectedMatiere = v;
                _syncPrixCtrlWithMatiere();
              }),
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
          children: [
            Row(children: [
              Expanded(
                child: TextFormField(
                  controller: _prixCtrl,
                  inputFormatters: _numFormatters,
                  decoration: const InputDecoration(labelText: 'Tarif (€/kg)', prefixIcon: Icon(Icons.euro)),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onTap: () => _selectAll(_prixCtrl),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.tonal(
                onPressed: (selectedMatiere == null)
                    ? null
                    : () {
                        const defaults = {'Acier': 1.30, 'Aluminium': 5.00, 'Inox': 5.00, 'Fonte': 2.00};
                        final def = defaults[selectedMatiere];
                        if (def != null) {
                          setState(() {
                            prixKg[selectedMatiere!] = def;
                            _prixCtrl.text = def.toString();
                          });
                        }
                      },
                child: const Text('Par défaut'),
              ),
            ]),
          ],
        ),
      ]),
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
      child: Column(children: [
        SectionCard(
          title: 'Récapitulatif',
          children: [
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
          ],
        ),
      ]),
    );
  }

  // ======== Helpers ========
  Widget _wrapFields(List<Widget> children) =>
      Wrap(spacing: 12, runSpacing: 12, children: children);

  // Champ numérique “libre” avec sélection auto au focus
  Widget _freeNumField({
    required String label,
    required String unit,
    required TextEditingController controller,
  }) {
    return SizedBox(
      width: 220,
      child: TextFormField(
        controller: controller,
        inputFormatters: _numFormatters,
        decoration: InputDecoration(labelText: label, suffixText: unit),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        onTap: () => _selectAll(controller),
      ),
    );
  }

  // Zone quantité avec select-all + boutons
  Widget _quantityField() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton.outlined(
          onPressed: () {
            final v = (quantite - 1).clamp(1, 999999);
            setState(() {
              quantite = v;
              _qtyCtrl.text = '$v';
              _selectAll(_qtyCtrl);
            });
          },
          icon: const Icon(Icons.remove),
        ),
        SizedBox(
          width: 90,
          child: TextFormField(
            controller: _qtyCtrl,
            decoration: const InputDecoration(labelText: 'Qté'),
            keyboardType: TextInputType.number,
            onTap: () => _selectAll(_qtyCtrl),
          ),
        ),
        IconButton.filled(
          onPressed: () {
            final v = (quantite + 1).clamp(1, 999999);
            setState(() {
              quantite = v;
              _qtyCtrl.text = '$v';
              _selectAll(_qtyCtrl);
            });
          },
          icon: const Icon(Icons.add),
        ),
      ],
    );
  }

  void _selectAll(TextEditingController c) {
    c.selection = TextSelection(baseOffset: 0, extentOffset: c.text.length);
  }

  double _parseD(String s, double fallback) {
    final v = double.tryParse(s.replaceAll(',', '.'));
    return v == null || v.isNaN || v.isInfinite ? fallback : v;
  }

  void _syncPrixCtrlWithMatiere() {
    final mat = selectedMatiere;
    if (mat != null) {
      final v = prixKg[mat] ?? 0;
      _prixCtrl.text = v.toString();
      _selectAll(_prixCtrl);
    } else {
      _prixCtrl.text = '';
    }
  }

  @override
  void dispose() {
    _lenCtrl.dispose();
    _qtyCtrl.dispose();
    _prixCtrl.dispose();
    _dExtCtrl.dispose();
    _epCtrl.dispose();
    _coteCtrl.dispose();
    _largCtrl.dispose();
    _hautCtrl.dispose();
    _dPleinCtrl.dispose();
    _aileCtrl.dispose();
    _aile2Ctrl.dispose();
    super.dispose();
  }
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
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(children: [
        Icon(icon, size: 28, color: cs.primary),
        const SizedBox(width: 12),
        Expanded(child: Text(title)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
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
        gradient: LinearGradient(colors: [cs.primary, cs.primary.withOpacity(0.6)]),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Text(value, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.black)),
          const SizedBox(height: 6),
          Text(caption, style: const TextStyle(color: Colors.black87)),
        ],
      ),
    );
  }
}

class SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const SectionCard({super.key, required this.title, required this.children});
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          ...children,
        ]),
      ),
    );
  }
}
