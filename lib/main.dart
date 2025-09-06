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
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const DudufHomePage(),
    );
  }
}

class DudufHomePage extends StatefulWidget {
  const DudufHomePage({super.key});

  @override
  State<DudufHomePage> createState() => _DudufHomePageState();
}

enum Mode { normalise, libre }

class _DudufHomePageState extends State<DudufHomePage> {
  Mode mode = Mode.normalise;

  String? selectedSerie;
  String? selectedTaille;
  String? selectedProfilLibre;
  String? selectedMatiere;

  double? longueur;
  double? largeur;
  double? epaisseur;
  double? diametre;

  final Map<String, Map<String, double>> poidsParMetre = {
    'HEA': {for (var i = 80; i <= 400; i += 20) '$i': i * 0.1},
    'HEB': {for (var i = 80; i <= 400; i += 20) '$i': i * 0.12},
    'IPE': {for (var i = 80; i <= 400; i += 20) '$i': i * 0.08},
    'IPN': {for (var i = 80; i <= 400; i += 20) '$i': i * 0.09},
    'UPN': {for (var i = 80; i <= 400; i += 20) '$i': i * 0.07},
    'UPE': {for (var i = 80; i <= 400; i += 20) '$i': i * 0.075},
  };

  final Map<String, double> densites = {
    'Acier': 7850,
    'Inox': 8000,
    'Aluminium': 2700,
    'Fonte': 7200,
  };

  final List<String> profilsLibres = [
    'Tube rond',
    'Tube carré',
    'Tube rectangulaire',
    'Carré plein',
    'Rectangle plein',
    'Rond plein',
    'Cornière',
    'T',
  ];

  double? poidsUnitaireKgM() {
    final densite = densites[selectedMatiere];
    if (densite == null) return null;

    if (mode == Mode.normalise) {
      if (selectedSerie == null || selectedTaille == null) return null;
      final kgmAcier = poidsParMetre[selectedSerie]![selectedTaille!];
      if (kgmAcier == null) return null; // sécurité null-safety
      return kgmAcier * (densite / 7850.0);
    } else {
      if (selectedProfilLibre == null) return null;
      switch (selectedProfilLibre) {
        case 'Tube rond':
          if (diametre == null || epaisseur == null) return null;
          final rExt = diametre! / 2;
          final rInt = rExt - epaisseur!;
          return (3.1416 * (rExt * rExt - rInt * rInt)) * densite / 1e6;
        case 'Tube carré':
          if (largeur == null || epaisseur == null) return null;
          final coteExt = largeur!;
          final coteInt = coteExt - 2 * epaisseur!;
          return ((coteExt * coteExt) - (coteInt * coteInt)) * densite / 1e6;
        case 'Tube rectangulaire':
          if (largeur == null || longueur == null || epaisseur == null) return null;
          final a = largeur!;
          final b = longueur!;
          final aInt = a - 2 * epaisseur!;
          final bInt = b - 2 * epaisseur!;
          return ((a * b) - (aInt * bInt)) * densite / 1e6;
        case 'Carré plein':
          if (largeur == null) return null;
          return (largeur! * largeur! * densite) / 1e6;
        case 'Rectangle plein':
          if (largeur == null || longueur == null) return null;
          return (largeur! * longueur! * densite) / 1e6;
        case 'Rond plein':
          if (diametre == null) return null;
          final r = diametre! / 2;
          return (3.1416 * r * r * densite) / 1e6;
        case 'Cornière':
          if (largeur == null || longueur == null || epaisseur == null) return null;
          final a = largeur!;
          final b = longueur!;
          return ((a + b - epaisseur!) * epaisseur! * densite) / 1e6;
        case 'T':
          if (largeur == null || longueur == null || epaisseur == null) return null;
          final a = largeur!;
          final b = longueur!;
          return ((a * epaisseur!) + ((b - epaisseur!) * epaisseur!)) * densite / 1e6;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final poidsUnitaire = poidsUnitaireKgM();
    return Scaffold(
      appBar: AppBar(title: const Text('Duduf Occas')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ToggleButtons(
              isSelected: [mode == Mode.normalise, mode == Mode.libre],
              onPressed: (index) {
                setState(() {
                  mode = index == 0 ? Mode.normalise : Mode.libre;
                  selectedSerie = null;
                  selectedTaille = null;
                  selectedProfilLibre = null;
                });
              },
              children: const [Text("Normalisé"), Text("Libre")],
            ),
            const SizedBox(height: 20),
            _buildMatiereDropdown(),
            const SizedBox(height: 20),
            if (mode == Mode.normalise) _normaliseCard(),
            if (mode == Mode.libre) _libreCard(),
            const SizedBox(height: 20),
            if (poidsUnitaire != null)
              Text(
                "Poids unitaire : ${poidsUnitaire.toStringAsFixed(2)} kg/m",
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMatiereDropdown() {
    return DropdownButtonFormField<String>(
      value: selectedMatiere,
      decoration: const InputDecoration(labelText: "Matière"),
      items: densites.keys.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
      onChanged: (val) => setState(() => selectedMatiere = val),
    );
  }

  Widget _normaliseCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              value: selectedSerie,
              decoration: const InputDecoration(labelText: "Série"),
              items: poidsParMetre.keys
                  .map((serie) => DropdownMenuItem(value: serie, child: Text(serie)))
                  .toList(),
              onChanged: (val) => setState(() {
                selectedSerie = val;
                selectedTaille = null;
              }),
            ),
            if (selectedSerie != null)
              DropdownButtonFormField<String>(
                value: selectedTaille,
                decoration: const InputDecoration(labelText: "Taille (mm)"),
                items: poidsParMetre[selectedSerie]!.keys
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (val) => setState(() => selectedTaille = val),
              ),
            if (selectedSerie != null && selectedTaille != null)
              Builder(builder: (context) {
                final base = poidsParMetre[selectedSerie]![selectedTaille!];
                final densite = densites[selectedMatiere];
                if (base == null || densite == null) return const SizedBox.shrink();
                final scaled = base * (densite / 7850.0);
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    'kg/m (acier): ${base.toStringAsFixed(2)} — '
                    'kg/m (matière sélectionnée): ${scaled.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _libreCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              value: selectedProfilLibre,
              decoration: const InputDecoration(labelText: "Profil"),
              items: profilsLibres
                  .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                  .toList(),
              onChanged: (val) => setState(() => selectedProfilLibre = val),
            ),
            if (selectedProfilLibre != null) ..._buildFieldsForProfil(selectedProfilLibre!),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildFieldsForProfil(String profil) {
    switch (profil) {
      case 'Tube rond':
        return [
          _numberField("Diamètre (mm)", (v) => diametre = v),
          _numberField("Épaisseur (mm)", (v) => epaisseur = v),
        ];
      case 'Tube carré':
        return [
          _numberField("Côté (mm)", (v) => largeur = v),
          _numberField("Épaisseur (mm)", (v) => epaisseur = v),
        ];
      case 'Tube rectangulaire':
        return [
          _numberField("Largeur (mm)", (v) => largeur = v),
          _numberField("Hauteur (mm)", (v) => longueur = v),
          _numberField("Épaisseur (mm)", (v) => epaisseur = v),
        ];
      case 'Carré plein':
        return [_numberField("Côté (mm)", (v) => largeur = v)];
      case 'Rectangle plein':
        return [
          _numberField("Largeur (mm)", (v) => largeur = v),
          _numberField("Hauteur (mm)", (v) => longueur = v),
        ];
      case 'Rond plein':
        return [_numberField("Diamètre (mm)", (v) => diametre = v)];
      case 'Cornière':
        return [
          _numberField("Largeur aile A (mm)", (v) => largeur = v),
          _numberField("Largeur aile B (mm)", (v) => longueur = v),
          _numberField("Épaisseur (mm)", (v) => epaisseur = v),
        ];
      case 'T':
        return [
          _numberField("Largeur semelle (mm)", (v) => largeur = v),
          _numberField("Hauteur âme (mm)", (v) => longueur = v),
          _numberField("Épaisseur (mm)", (v) => epaisseur = v),
        ];
      default:
        return [];
    }
  }

  Widget _numberField(String label, Function(double?) setter) {
    return TextFormField(
      decoration: InputDecoration(labelText: label),
      keyboardType: TextInputType.number,
      onChanged: (val) => setState(() => setter(double.tryParse(val))),
    );
  }
}
