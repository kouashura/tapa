import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../theme/app_theme.dart';

class GuideScreen extends StatelessWidget {
  const GuideScreen({super.key});

  static const List<Map<String, dynamic>> _sections = [
    {
      'numero': '01',
      'titre': 'Bienvenue dans TAPA Budget',
      'contenu': [
        'TAPA Budget est votre application de gestion financiere personnelle conçue pour l Afrique de l Ouest.',
        'Elle vous permet de suivre vos revenus et depenses, gerer vos portefeuilles mobile money, planifier votre budget et atteindre vos objectifs financiers.',
        '✅ Simple a utiliser',
        '✅ Adapte au contexte africain (Wave, Orange Money, MTN MoMo...)',
        '✅ Vos donnees restent sur votre telephone',
        '✅ Rapports PDF partageables',
      ],
    },
    {
      'numero': '02',
      'titre': 'PREMIERE ETAPE : Configurez vos portefeuilles',
      'contenu': [
        '⚠️ AVANT TOUT, configurez vos portefeuilles !',
        'C est la premiere chose a faire apres votre inscription.',
        'Comment faire :',
        '1. Allez dans PROFIL (icone personne en bas a droite)',
        '2. Appuyez sur MES PORTEFEUILLES',
        '3. Appuyez sur + pour ajouter un portefeuille',
        '4. Choisissez le type : Cash, Wave, Orange Money, MTN MoMo, Banque...',
        '5. Entrez votre solde actuel',
        '6. Appuyez sur ENREGISTRER',
        '💡 Conseil : Ajoutez tous vos comptes pour une vue complete de votre argent.',
      ],
    },
    {
      'numero': '03',
      'titre': 'DEUXIEME ETAPE : Creez vos categories',
      'contenu': [
        'Les categories vous permettent de classer vos depenses et revenus.',
        'Comment creer vos categories :',
        '1. Allez dans PROFIL',
        '2. Appuyez sur MES CATEGORIES',
        '3. Onglet DEPENSES : ajoutez vos categories de depenses',
        '   Ex : Repas, Transport, Loyer, Ecole, Sante...',
        '4. Onglet REVENUS : ajoutez vos categories de revenus',
        '   Ex : Salaire, Business, Tontine, Vente...',
        '5. Appuyez sur + AJOUTER pour chaque categorie',
        '💡 Conseil : Creez des categories qui correspondent a votre vie quotidienne.',
      ],
    },
    {
      'numero': '04',
      'titre': 'Ajouter une transaction',
      'contenu': [
        'Pour enregistrer une depense ou un revenu :',
        '1. Sur l ecran Accueil, appuyez sur + AJOUTER',
        '2. Choisissez DEPENSE ou REVENU',
        '3. Entrez le montant avec le pave numerique',
        '4. Choisissez la CATEGORIE',
        '5. Choisissez le PORTEFEUILLE utilise',
        '6. Ajoutez une NOTE si necessaire (facultatif)',
        '7. Appuyez sur ENREGISTRER',
        '⚠️ Important : Le solde du portefeuille sera automatiquement mis a jour.',
        '💡 3 facons d ajouter : manuellement, par dictee vocale, ou en scannant un recu.',
      ],
    },
    {
      'numero': '05',
      'titre': 'Scanner un recu',
      'contenu': [
        'TAPA Budget peut lire automatiquement vos recus !',
        'Comment faire :',
        '1. Sur l Accueil, appuyez sur le bouton VERT (icone scanner)',
        '2. Choisissez PRENDRE UNE PHOTO ou GALERIE',
        '3. Photographiez votre recu',
        '4. L application detecte automatiquement le montant',
        '5. Verifiez et completez les informations',
        '6. Appuyez sur ENREGISTRER',
        '💡 Conseil : Assurez-vous que le recu est bien eclaire.',
      ],
    },
    {
      'numero': '06',
      'titre': 'Dictee vocale',
      'contenu': [
        'Enregistrez vos transactions en parlant !',
        'Comment faire :',
        '1. Sur l Accueil, appuyez sur le bouton OR (icone micro)',
        '2. Appuyez sur le micro et parlez clairement',
        '3. Exemples de phrases :',
        '   "Depense 2000 pour le repas"',
        '   "Recu 50000 de salaire"',
        '   "Paye 5000 pour le transport"',
        '4. L application detecte le montant et la categorie',
        '5. Verifiez et modifiez si necessaire',
        '6. Appuyez sur ENREGISTRER',
      ],
    },
    {
      'numero': '07',
      'titre': 'Budget Previsionnel',
      'contenu': [
        'Planifiez vos revenus et depenses a l avance !',
        'Comment creer votre budget :',
        '1. Appuyez sur BUDGET dans la barre du bas',
        '2. Appuyez sur CREER LE BUDGET',
        '3. Section REVENUS PREVUS : ajoutez vos revenus attendus',
        '4. Section DEPENSES PREVUES : ajoutez vos depenses planifiees',
        '5. Suivez votre progression en temps reel',
        'Les jauges vous montrent :',
        '🟢 Vert : vous etes dans les limites',
        '🔴 Rouge : vous avez depasse le budget',
        '💡 Conseil : Creez votre budget en debut de mois.',
      ],
    },
    {
      'numero': '08',
      'titre': 'Gestion des Dettes',
      'contenu': [
        'Suivez vos remboursements facilement !',
        'Comment ajouter une dette :',
        '1. Appuyez sur DETTES dans la barre du bas',
        '2. Appuyez sur + (en haut a droite)',
        '3. Remplissez le formulaire',
        '4. Pour rembourser : appuyez sur REMBOURSER',
        '5. Entrez le montant et le portefeuille utilise',
        '⚠️ Une dette non remboursee depuis 1 mois affiche une alerte.',
      ],
    },
    {
      'numero': '09',
      'titre': 'Rapports PDF',
      'contenu': [
        'Generez et partagez vos rapports financiers !',
        'Types de rapports disponibles :',
        '📅 Rapport journalier : transactions du jour',
        '📆 Rapport hebdomadaire : bilan de la semaine',
        '📊 Rapport mensuel : bilan complet du mois',
        'Comment generer un rapport :',
        '1. Allez dans PROFIL',
        '2. Appuyez sur RAPPORTS FINANCIERS PDF',
        '3. Choisissez le type de rapport',
        '4. Partagez par WhatsApp ou enregistrez',
      ],
    },
    {
      'numero': '10',
      'titre': 'Score TAPA',
      'contenu': [
        'Votre score de sante financiere sur 100 points !',
        'Calcule sur 5 criteres :',
        '💰 Revenus (20 pts) : regularite des revenus',
        '🛒 Depenses (20 pts) : controle des depenses',
        '🏦 Epargne (20 pts) : objectifs actifs',
        '💳 Dettes (20 pts) : remboursements a jour',
        '📱 Regularite (20 pts) : utilisation de l app',
        'Niveaux :',
        '🟢 80-100 : Excellent',
        '🔵 60-79 : Bon',
        '🟡 40-59 : Moyen',
        '🔴 0-39 : Insuffisant',
        '💡 Exportez votre Score PDF pour votre banque.',
      ],
    },
    {
      'numero': '11',
      'titre': 'Conseils pour bien demarrer',
      'contenu': [
        '✅ Etape 1 : Configurez vos portefeuilles avec vos soldes actuels',
        '✅ Etape 2 : Creez vos categories de depenses et revenus',
        '✅ Etape 3 : Enregistrez TOUTES vos transactions chaque jour',
        '✅ Etape 4 : Creez votre budget previsionnel en debut de mois',
        '✅ Etape 5 : Consultez vos rapports chaque semaine',
        '✅ Etape 6 : Epargnez au moins 10% de vos revenus',
        '⚠️ Les comptes mobile money ne peuvent pas etre negatifs',
        '⚠️ Seul votre compte Banque peut etre a decouvert',
        '📞 Support WhatsApp : +225 01 60 25 41 02',
      ],
    },
  ];

  Future<void> _telechargerGuide(BuildContext context) async {
    try {
      final pdf = pw.Document();

      pdf.addPage(pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (ctx) => pw.Container(
          color: PdfColors.blueGrey900,
          child: pw.Center(child: pw.Column(
            mainAxisAlignment: pw.MainAxisAlignment.center,
            children: [
              pw.Text('TAPA Budget',
                style: pw.TextStyle(fontSize: 48,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.amber)),
              pw.SizedBox(height: 16),
              pw.Text('Guide Pratique d Utilisation',
                style: pw.TextStyle(fontSize: 24,
                  color: PdfColors.white)),
              pw.SizedBox(height: 48),
              pw.Text('Support : +225 01 60 25 41 02',
                style: pw.TextStyle(fontSize: 14,
                  color: PdfColors.grey400)),
            ])))));

      for (final section in _sections) {
        pdf.addPage(pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          build: (ctx) => [
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                color: PdfColors.blueGrey800,
                borderRadius: pw.BorderRadius.circular(8)),
              child: pw.Text(
                section['numero'] + ' — ' + section['titre'],
                style: pw.TextStyle(fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white))),
            pw.SizedBox(height: 20),
            ...(section['contenu'] as List<String>).map((ligne) =>
              pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 10),
                child: pw.Text(ligne,
                  style: pw.TextStyle(fontSize: 14,
                    lineSpacing: 4,
                    color: PdfColors.blueGrey900)))),
            pw.SizedBox(height: 20),
            pw.Divider(),
            pw.Text('TAPA Budget — Guide Pratique | +225 01 60 25 41 02',
              style: pw.TextStyle(fontSize: 9, color: PdfColors.grey500)),
          ]));
      }

      await Printing.sharePdf(
        bytes: await pdf.save(),
        filename: 'Guide_TAPA_Budget.pdf');
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: \$e'),
            backgroundColor: TAPAColors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TAPAColors.background,
      appBar: AppBar(
        title: const Text('Guide d utilisation'),
        backgroundColor: TAPAColors.navy,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => context.pop()),
        actions: [
          IconButton(
            icon: const Icon(Icons.download_outlined,
              color: TAPAColors.gold),
            onPressed: () => _telechargerGuide(context)),
        ]),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _sections.length + 1,
        itemBuilder: (ctx, i) {
          if (i == 0) {
            return Container(
              margin: const EdgeInsets.only(bottom: 20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: TAPAColors.navy,
                borderRadius: BorderRadius.circular(16)),
              child: Column(children: [
                const Text('📖',
                  style: TextStyle(fontSize: 40)),
                const SizedBox(height: 12),
                const Text('Guide Pratique',
                  style: TextStyle(fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: TAPAColors.white)),
                const Text('TAPA Budget',
                  style: TextStyle(fontSize: 16,
                    color: TAPAColors.gold,
                    fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                const Text(
                  'Apprenez a utiliser TAPA Budget efficacement',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13,
                    color: Colors.white60)),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => _telechargerGuide(context),
                  icon: const Icon(Icons.download,
                    color: TAPAColors.navy),
                  label: const Text(
                    'Telecharger le guide PDF',
                    style: TextStyle(
                      color: TAPAColors.navy,
                      fontWeight: FontWeight.w700)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: TAPAColors.gold)),
              ]));
          }
          final section = _sections[i - 1];
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: TAPAColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: TAPAColors.border, width: 0.5)),
            child: ExpansionTile(
              leading: Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: TAPAColors.navy,
                  borderRadius: BorderRadius.circular(8)),
                child: Center(child: Text(
                  section['numero'] as String,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: TAPAColors.gold)))),
              title: Text(
                section['titre'] as String,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: TAPAColors.navy)),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    16, 0, 16, 16),
                  child: Column(
                    crossAxisAlignment:
                      CrossAxisAlignment.start,
                    children: (section['contenu']
                        as List<String>).map((ligne) =>
                      Padding(
                        padding: const EdgeInsets.only(
                          bottom: 8),
                        child: Text(ligne,
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.6,
                            color: ligne.startsWith('⚠️')
                              ? TAPAColors.red
                              : ligne.startsWith('💡')
                                ? const Color(0xFF996600)
                                : TAPAColors.navy)))).toList())),
              ]));
        }));
  }
}
