import 'dart:math' as math;
import 'package:flutter/material.dart';

void main() {
  runApp(const DudufOccasApp());
}

class DudufOccasApp extends StatelessWidget {
  const DudufOccasApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Duduf Occas',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0EA5E9)),
        useMaterial3: true,
      ),
      home: const DudufHome(),
      debugShowCheckedModeBanner: false,
    );
  }
}

enum Mode { normalise, libre }
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

  @override
  void initState() {
    super.initState();
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
            ],
          ),
        ),
      ),
    );
  }

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
}
