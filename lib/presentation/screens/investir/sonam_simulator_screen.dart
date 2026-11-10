// lib/presentation/screens/investir/sonam_simulator_screen.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import 'sonam_calc.dart';
import 'sonam_subscription_screen.dart';

class SonamSimulatorScreen extends StatefulWidget {
  const SonamSimulatorScreen({super.key});

  @override
  State<SonamSimulatorScreen> createState() => _SonamSimulatorScreenState();
}

class _SonamSimulatorScreenState extends State<SonamSimulatorScreen> {
  static const double _tauxAnnuel = 0.04;
  static const double _tauxFrais = 0.04;
  static const List<int> _dureesRapides = [5, 10, 15, 20, 30, 40];

  double _cotisation = 10000;
  double _duree = 5;

  // ───────────────────────── Calculs ─────────────────────────

  double get _totalVerse => _cotisation * _duree * 12;
  double get _frais => _totalVerse * _tauxFrais;
  double get _capitalGaranti =>
      SonamCalc.capitalGaranti(_cotisation, _duree.toInt());

  double get _interets => _capitalGaranti - (_totalVerse - _frais);

  String _formatMontant(double montant) {
    final s = montant.round().toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]} ',
        );
    return '$s FCFA';
  }

  // ───────────────────────── Build ─────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TAPAColors.background,
      appBar: AppBar(
        title: const Text(
          'Épargne SONAM',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        backgroundColor: TAPAColors.navy,
        foregroundColor: TAPAColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => context.go('/investir'),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeroCard(),
              const SizedBox(height: 20),
              _buildCotisationSection(),
              const SizedBox(height: 16),
              _buildDureeSection(),
              const SizedBox(height: 16),
              _buildSummaryCard(),
              const SizedBox(height: 20),
              _buildSubscribeButton(),
              const SizedBox(height: 12),
              _buildInfoNote(),
            ],
          ),
        ),
      ),
    );
  }

  // ───────────────────────── Carte principale ─────────────────────────

  Widget _buildHeroCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1A237E), Color(0xFF0D1444)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            // Cercles décoratifs (clippés par le ClipRRect → pas de débordement)
            Positioned(
              top: -40,
              right: -30,
              child: Container(
                width: 130,
                height: 130,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0x14FFFFFF),
                ),
              ),
            ),
            Positioned(
              bottom: -50,
              left: -40,
              child: Container(
                width: 120,
                height: 120,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0x0DFFFFFF),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: TAPAColors.gold.withAlpha(40),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.savings_outlined,
                          color: TAPAColors.gold,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Capital garanti à terme',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Color(0xB3FFFFFF),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        _formatMontant(_capitalGaranti),
                        maxLines: 1,
                        style: const TextStyle(
                          color: TAPAColors.gold,
                          fontSize: 34,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildHeroStat(
                          'Total versé',
                          _formatMontant(_totalVerse),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildHeroStat(
                          'Gain net',
                          '+ ${_formatMontant(_interets)}',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildChip(Icons.trending_up, 'Taux garanti 4 % / an'),
                      _buildChip(Icons.percent, 'Frais 4 %'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroStat(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0x1AFFFFFF),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Color(0x99FFFFFF), fontSize: 11),
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: double.infinity,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                maxLines: 1,
                style: const TextStyle(
                  color: TAPAColors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0x1AFFFFFF),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: TAPAColors.gold),
          const SizedBox(width: 5),
          Text(
            text,
            style: const TextStyle(
              color: Color(0xCCFFFFFF),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────── Sliders ─────────────────────────

  Widget _buildCotisationSection() {
    return _buildSliderCard(
      icon: Icons.payments_outlined,
      title: 'Cotisation mensuelle',
      value: _formatMontant(_cotisation),
      slider: Slider(
        value: _cotisation,
        min: 1000,
        max: 30000,
        divisions: 29,
        onChanged: (val) {
          setState(() {
            _cotisation = (val / 1000).round() * 1000.0;
          });
        },
      ),
      minLabel: '1 000 F',
      maxLabel: '30 000 F',
    );
  }

  Widget _buildDureeSection() {
    return _buildSliderCard(
      icon: Icons.calendar_month_outlined,
      title: 'Durée du contrat',
      value: '${_duree.toInt()} an${_duree > 1 ? 's' : ''}',
      slider: Slider(
        value: _duree,
        min: 1,
        max: 40,
        divisions: 39,
        onChanged: (val) {
          setState(() {
            _duree = val.roundToDouble();
          });
        },
      ),
      minLabel: '1 an',
      maxLabel: '40 ans',
      extra: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _dureesRapides.map((d) {
          final selected = _duree.toInt() == d;
          return GestureDetector(
            onTap: () => setState(() => _duree = d.toDouble()),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: selected ? TAPAColors.navy : TAPAColors.background,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: selected ? TAPAColors.navy : TAPAColors.border,
                ),
              ),
              child: Text(
                '$d ans',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: selected ? TAPAColors.white : TAPAColors.textSecond,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSliderCard({
    required IconData icon,
    required String title,
    required String value,
    required Widget slider,
    required String minLabel,
    required String maxLabel,
    Widget? extra,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: TAPAColors.navy),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: TAPAColors.navy,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: TAPAColors.gold.withAlpha(30),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      value,
                      maxLines: 1,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: TAPAColors.gold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 6,
              activeTrackColor: TAPAColors.gold,
              inactiveTrackColor: TAPAColors.border,
              thumbColor: TAPAColors.gold,
              overlayColor: TAPAColors.gold.withAlpha(35),
              activeTickMarkColor: Colors.transparent,
              inactiveTickMarkColor: Colors.transparent,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 11),
            ),
            child: slider,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  minLabel,
                  style: const TextStyle(
                      fontSize: 11, color: TAPAColors.textSecond),
                ),
                Text(
                  maxLabel,
                  style: const TextStyle(
                      fontSize: 11, color: TAPAColors.textSecond),
                ),
              ],
            ),
          ),
          if (extra != null) ...[
            const SizedBox(height: 12),
            extra,
          ],
        ],
      ),
    );
  }

  // ───────────────────────── Récapitulatif ─────────────────────────

  Widget _buildSummaryCard() {
    final net = _totalVerse - _frais;
    final total = net + (_interets > 0 ? _interets : 0);
    final ratioNet = total <= 0 ? 0.5 : net / total;
    final flexNet = (ratioNet * 1000).round().clamp(1, 999);
    final flexInt = 1000 - flexNet;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.receipt_long_outlined,
                  size: 18, color: TAPAColors.navy),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Détail de votre épargne',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: TAPAColors.navy,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Barre de répartition capital net / intérêts
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 10,
              child: Row(
                children: [
                  Expanded(
                    flex: flexNet,
                    child: Container(color: TAPAColors.navy),
                  ),
                  Expanded(
                    flex: flexInt,
                    child: Container(color: TAPAColors.gold),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Wrap(
            spacing: 14,
            runSpacing: 4,
            children: [
              _LegendDot(color: TAPAColors.navy, label: 'Capital net'),
              _LegendDot(color: TAPAColors.gold, label: 'Intérêts'),
            ],
          ),
          const SizedBox(height: 14),

          _buildDetailRow('Total versé', _formatMontant(_totalVerse)),
          _buildDetailRow(
            'Frais (4 %)',
            '- ${_formatMontant(_frais)}',
            isNegative: true,
          ),
          _buildDetailRow(
            'Intérêts générés',
            '+ ${_formatMontant(_interets)}',
            isPositive: true,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Divider(height: 1, color: TAPAColors.border),
          ),
          _buildDetailRow(
            'Capital garanti',
            _formatMontant(_capitalGaranti),
            isBold: true,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    String label,
    String value, {
    bool isNegative = false,
    bool isPositive = false,
    bool isBold = false,
  }) {
    Color valueColor = TAPAColors.navy;
    if (isNegative) valueColor = TAPAColors.red;
    if (isPositive) valueColor = TAPAColors.green;
    if (isBold) valueColor = TAPAColors.gold;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                color: isBold ? TAPAColors.navy : TAPAColors.textSecond,
                fontWeight: isBold ? FontWeight.w700 : FontWeight.normal,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 6,
            child: Align(
              alignment: Alignment.centerRight,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: Text(
                  value,
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: isBold ? 16 : 13,
                    fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
                    color: valueColor,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────── Bouton & note ─────────────────────────

  Widget _buildSubscribeButton() {
    return SizedBox(
      height: 56,
      child: ElevatedButton.icon(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => SonamSubscriptionScreen(
                cotisation: _cotisation,
                dureeAns: _duree.toInt(),
                capitalGaranti: _capitalGaranti,
              ),
            ),
          );
        },
        icon: const Icon(Icons.arrow_forward_rounded, size: 20),
        label: const Text(
          'Souscrire maintenant',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: TAPAColors.gold,
          foregroundColor: TAPAColors.navy,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoNote() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: TAPAColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: TAPAColors.border),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(top: 1),
            child: Icon(Icons.info_outline,
                size: 16, color: TAPAColors.textSecond),
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Sortie avant 12 mois : pénalité d\'un mois de cotisation. '
              'Après 12 mois : 0 frais de sortie.',
              style: TextStyle(
                fontSize: 11,
                height: 1.4,
                color: TAPAColors.textSecond,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────── Helpers ─────────────────────────

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: TAPAColors.surface,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: TAPAColors.border),
      boxShadow: const [
        BoxShadow(
          color: Color(0x0A000000),
          blurRadius: 10,
          offset: Offset(0, 4),
        ),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: TAPAColors.textSecond),
        ),
      ],
    );
  }
}
