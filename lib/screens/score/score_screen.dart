import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../services/db_service_mysql.dart';
import '../../services/score_service.dart';
import '../../services/pdf_service.dart';

class ScoreScreen extends StatefulWidget {
  const ScoreScreen({super.key});

  @override
  State<ScoreScreen> createState() => _ScoreScreenState();
}

class _ScoreScreenState extends State<ScoreScreen> {
  late Future<ScoreTAPA> _scoreFuture;

  @override
  void initState() {
    super.initState();
    final db = DBService();
    _scoreFuture = ScoreService.calculer(db);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TAPAColors.background,
      appBar: AppBar(
        title: const Text('Score TAPA'),
        backgroundColor: TAPAColors.navy,
        foregroundColor: TAPAColors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => context.pop(),
        ),
      ),
      body: FutureBuilder<ScoreTAPA>(
        future: _scoreFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: TAPAColors.red),
                  const SizedBox(height: 16),
                  Text('Erreur: ${snapshot.error}'),
                ],
              ),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: Text('Aucune donnée'));
          }

          final score = snapshot.data!;
          return _buildScoreContent(score);
        },
      ),
    );
  }

  Widget _buildScoreContent(ScoreTAPA score) {
    Color scoreColor;
    if (score.scoreTotal >= 80) scoreColor = TAPAColors.green;
    else if (score.scoreTotal >= 60) scoreColor = Colors.blue;
    else if (score.scoreTotal >= 40) scoreColor = TAPAColors.amber;
    else if (score.scoreTotal >= 20) scoreColor = Colors.orange;
    else scoreColor = TAPAColors.red;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Score principal
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: TAPAColors.navy,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              Text(
                '${score.emoji} Score TAPA',
                style: const TextStyle(fontSize: 14, color: Colors.white60),
              ),
              const SizedBox(height: 16),
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 140,
                    height: 140,
                    child: CircularProgressIndicator(
                      value: score.scoreTotal / 100,
                      strokeWidth: 12,
                      backgroundColor: Colors.white12,
                      valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
                    ),
                  ),
                  Column(
                    children: [
                      Text(
                        '${score.scoreTotal}',
                        style: TextStyle(
                          fontSize: 42,
                          fontWeight: FontWeight.w800,
                          color: scoreColor,
                        ),
                      ),
                      const Text(
                        '/100',
                        style: TextStyle(fontSize: 14, color: Colors.white54),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                decoration: BoxDecoration(
                  color: scoreColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: scoreColor),
                ),
                child: Text(
                  score.niveau,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: scoreColor,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Score basé sur vos habitudes financières dans TAPA Budget.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white38,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Détail par critère
        const Text(
          'DÉTAIL PAR CRITÈRE',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: TAPAColors.textSecond,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 10),
        _criterCard('Revenus', score.scoreRevenus, 20, Icons.trending_up, TAPAColors.green),
        _criterCard('Dépenses', score.scoreDepenses, 20, Icons.shopping_cart_outlined, TAPAColors.red),
        _criterCard('Épargne', score.scoreEpargne, 20, Icons.savings_outlined, Colors.blue),
        _criterCard('Dettes', score.scoreDettes, 20, Icons.credit_card_outlined, TAPAColors.amber),
        _criterCard('Régularité', score.scoreRegularite, 20, Icons.calendar_today_outlined, TAPAColors.purple),

        const SizedBox(height: 20),

        // Points forts
        if (score.pointsForts.isNotEmpty) ...[
          const Text(
            'VOS POINTS FORTS',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: TAPAColors.textSecond,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 10),
          ...score.pointsForts.map((p) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: TAPAColors.greenLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Text('✅', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    p,
                    style: const TextStyle(
                      fontSize: 13,
                      color: TAPAColors.green,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          )),
          const SizedBox(height: 16),
        ],

        // Conseils
        if (score.conseils.isNotEmpty) ...[
          const Text(
            'COMMENT AMÉLIORER VOTRE SCORE',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: TAPAColors.textSecond,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 10),
          ...score.conseils.map((c) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: TAPAColors.goldLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Text('💡', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    c,
                    style: const TextStyle(
                      fontSize: 13,
                      color: TAPAColors.navy,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          )),
          const SizedBox(height: 16),
        ],

        // Note importante
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: TAPAColors.background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: TAPAColors.border),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '⚠️ Note importante',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: TAPAColors.navy,
                ),
              ),
              SizedBox(height: 6),
              Text(
                'Ce score est basé sur vos données auto-déclarées. Il est fourni à titre éducatif pour vous aider à améliorer vos habitudes financières.',
                style: TextStyle(
                  fontSize: 12,
                  color: TAPAColors.textSecond,
                  height: 1.6,
                ),
              ),
            ],
          ),
        ),

        // Bouton export PDF
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () async {
              final db = DBService();
              await PdfService.rapportScore(db);
            },
            icon: const Icon(Icons.picture_as_pdf, color: TAPAColors.gold),
            label: const Text(
              'Exporter mon Score PDF',
              style: TextStyle(color: TAPAColors.gold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: TAPAColors.navy,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Partagez ce document avec votre banque ou microfinance.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11,
            color: TAPAColors.textSecond,
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _criterCard(String label, int score, int max, IconData icon, Color color) {
    final pct = score / max;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: TAPAColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: TAPAColors.border, width: 0.5),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: TAPAColors.navy,
                  ),
                ),
              ),
              Text(
                '$score/$max',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 6,
              backgroundColor: TAPAColors.border,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }
}
