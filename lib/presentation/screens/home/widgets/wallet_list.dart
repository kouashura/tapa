// lib/presentation/screens/home/widgets/wallet_list.dart

import 'package:flutter/material.dart';
import '../../../../../data/models/models.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../core/theme/app_theme.dart';

/// Liste des portefeuilles avec filtres par catégorie
class WalletList extends StatefulWidget {
  final List<WalletModel> wallets;
  final String monnaie;
  final bool soldeVisible;
  final VoidCallback onRefresh;

  const WalletList({
    super.key,
    required this.wallets,
    required this.monnaie,
    required this.soldeVisible,
    required this.onRefresh,
  });

  @override
  State<WalletList> createState() => _WalletListState();
}

class _WalletListState extends State<WalletList> {
  String _categorieSelectionnee = 'Tous';

  static const List<String> _categoriesConnues = [
    'Banque',
    'Cash',
    'MTN',
    'Orange',
    'Wave',
  ];

  String _categorieDe(WalletModel w) {
    final nom = w.nom.toLowerCase();
    for (final c in _categoriesConnues) {
      if (nom.contains(c.toLowerCase())) return c;
    }
    return 'Autres';
  }

  @override
  Widget build(BuildContext context) {
    final isSmall = MediaQuery.of(context).size.width < 360;
    final cardWidth = isSmall ? 140.0 : 172.0;

    final categoriesPresentes = _categoriesConnues
        .where((c) => widget.wallets.any((w) => _categorieDe(w) == c))
        .toList();
    final aDesAutres = widget.wallets.any((w) => _categorieDe(w) == 'Autres');
    final onglets = ['Tous', ...categoriesPresentes, if (aDesAutres) 'Autres'];

    if (!onglets.contains(_categorieSelectionnee)) {
      _categorieSelectionnee = 'Tous';
    }

    final walletsFiltres = _categorieSelectionnee == 'Tous'
        ? widget.wallets
        : widget.wallets
            .where((w) => _categorieDe(w) == _categorieSelectionnee)
            .toList();

    final Map<String, int> comptesParOnglet = {
      for (final o in onglets)
        o: o == 'Tous'
            ? widget.wallets.length
            : widget.wallets.where((w) => _categorieDe(w) == o).length,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Titre
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
          child: Row(
            children: [
              Text(
                'Mes portefeuilles',
                style: TextStyle(
                  fontSize: isSmall ? 15.0 : 17.0,
                  fontWeight: FontWeight.w800,
                  color: TAPAColors.navy,
                ),
              ),
              const Spacer(),
              Text(
                '${widget.wallets.length}',
                style: const TextStyle(
                  fontSize: 12,
                  color: TAPAColors.textSecond,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),

        // Filtres
        if (onglets.length > 1)
          SizedBox(
            height: 42,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: onglets.length,
              itemBuilder: (ctx, i) => _ongletCategorie(
                onglets[i],
                _categorieSelectionnee == onglets[i],
                comptesParOnglet[onglets[i]] ?? 0,
              ),
            ),
          ),
        if (onglets.length > 1) const SizedBox(height: 10),

        // Liste des portefeuilles
        SizedBox(
          height: 72,
          child: walletsFiltres.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Center(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Aucun portefeuille',
                        style: TextStyle(
                          color: TAPAColors.textSecond,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                )
              : ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: walletsFiltres.length,
                  itemBuilder: (ctx, i) => _walletCard(
                    walletsFiltres[i],
                    widget.monnaie,
                    cardWidth,
                    isSmall,
                  ),
                ),
        ),
      ],
    );
  }

  Widget _ongletCategorie(String label, bool selected, int count) {
    final Color couleur = _couleurCategorie(label);
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => setState(() => _categorieSelectionnee = label),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.only(left: 6, right: 12, top: 4, bottom: 4),
          decoration: BoxDecoration(
            gradient: selected
                ? const LinearGradient(
                    colors: [TAPAColors.navy, Color(0xFF1A2B4A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: selected ? null : TAPAColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? TAPAColors.navy : TAPAColors.border,
              width: 1,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: TAPAColors.navy.withOpacity(0.28),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: selected
                      ? TAPAColors.gold.withOpacity(0.18)
                      : couleur.withOpacity(0.14),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _iconeCategorie(label),
                  size: 12,
                  color: selected ? TAPAColors.gold : couleur,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: selected ? TAPAColors.gold : TAPAColors.navy,
                ),
              ),
              if (count > 0) ...[
                const SizedBox(width: 6),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: selected
                        ? Colors.white.withOpacity(0.14)
                        : couleur.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$count',
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      color: selected ? Colors.white70 : couleur,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  IconData _iconeCategorie(String label) {
    switch (label) {
      case 'Tous':
        return Icons.apps_rounded;
      case 'Banque':
        return Icons.account_balance_rounded;
      case 'Cash':
        return Icons.payments_rounded;
      case 'MTN':
        return Icons.sim_card_rounded;
      case 'Orange':
        return Icons.wifi_tethering_rounded;
      case 'Wave':
        return Icons.waves_rounded;
      default:
        return Icons.more_horiz_rounded;
    }
  }

  Color _couleurCategorie(String label) {
    switch (label) {
      case 'Tous':
        return TAPAColors.navy;
      case 'Banque':
        return TAPAColors.navy;
      case 'Cash':
        return TAPAColors.green;
      case 'MTN':
        return const Color(0xFFFFCC00);
      case 'Orange':
        return const Color(0xFFFF7900);
      case 'Wave':
        return const Color(0xFF1DC8F2);
      default:
        return TAPAColors.purple;
    }
  }

  Widget _walletCard(
      WalletModel w, String monnaie, double cardWidth, bool isSmall) {
    final bool isMtn = w.nom.toLowerCase().contains('mtn');
    final bool isOrange = w.nom.toLowerCase().contains('orange');

    return GestureDetector(
      onLongPress: () => _modifierSolde(w, monnaie),
      child: Container(
        width: cardWidth,
        margin: const EdgeInsets.only(right: 10, left: 4),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isMtn
              ? const Color(0xFFFFCC00).withOpacity(0.15)
              : isOrange
                  ? const Color(0xFFFF7900).withOpacity(0.15)
                  : TAPAColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: w.estPresqueVide
                ? TAPAColors.red
                : isMtn
                    ? const Color(0xFFFFCC00).withOpacity(0.5)
                    : isOrange
                        ? const Color(0xFFFF7900).withOpacity(0.5)
                        : TAPAColors.border,
            width: w.estPresqueVide ? 1.5 : (isMtn || isOrange ? 1.5 : 0.5),
          ),
          boxShadow: [
            BoxShadow(
              color: (isMtn
                      ? const Color(0xFFFFCC00)
                      : isOrange
                          ? const Color(0xFFFF7900)
                          : TAPAColors.navy)
                  .withOpacity(isMtn || isOrange ? 0.12 : 0.04),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isMtn
                    ? const Color(0xFFFFCC00)
                    : isOrange
                        ? const Color(0xFFFF7900)
                        : TAPAColors.goldLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: isMtn
                    ? const Text(
                        'MTN',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF003366),
                        ),
                      )
                    : isOrange
                        ? const Text(
                            'OR',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            w.emoji,
                            style: TextStyle(fontSize: isSmall ? 14 : 17),
                          ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    w.nom,
                    style: TextStyle(
                      fontSize: 10,
                      color: isMtn || isOrange
                          ? TAPAColors.navy
                          : TAPAColors.textSecond,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  const SizedBox(height: 1),
                  Text(
                    widget.soldeVisible
                        ? Fmt.montant(w.solde, monnaie: monnaie)
                        : '•••',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: w.estPresqueVide
                          ? TAPAColors.red
                          : isMtn
                              ? const Color(0xFF003366)
                              : isOrange
                                  ? const Color(0xFFCC5500)
                                  : TAPAColors.navy,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ],
              ),
            ),
            if (w.estPresqueVide)
              const Icon(Icons.warning_rounded, size: 12, color: TAPAColors.red)
            else
              const Icon(Icons.edit_outlined,
                  size: 11, color: TAPAColors.textHint),
          ],
        ),
      ),
    );
  }

  void _modifierSolde(WalletModel w, String monnaie) {
    final ctrl = TextEditingController(text: w.solde.round().toString());
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          decoration: const BoxDecoration(
            color: TAPAColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: TAPAColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: TAPAColors.goldLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child:
                          Text(w.emoji, style: const TextStyle(fontSize: 20)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Modifier ${w.nom}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: TAPAColors.navy,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              TextField(
                controller: ctrl,
                keyboardType: TextInputType.number,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'Nouveau solde',
                  suffixText: monnaie,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // TODO: Implémenter la mise à jour du solde
                    Navigator.pop(ctx);
                    widget.onRefresh();
                  },
                  child: const Text('Enregistrer'),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text(
                  'Annuler',
                  style: TextStyle(color: TAPAColors.textSecond),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
