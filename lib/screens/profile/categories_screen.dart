// lib/screens/profile/categories_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../services/db_service_mysql.dart';
import '../../core/utils/logger.dart';

class CategoriesScreen extends ConsumerStatefulWidget {
  const CategoriesScreen({super.key});

  @override
  ConsumerState<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends ConsumerState<CategoriesScreen>
    with SingleTickerProviderStateMixin {

  late TabController _tabController;
  final TextEditingController _nomCtrl = TextEditingController();
  final TextEditingController _emojiCtrl = TextEditingController();
  final DBService _db = DBService();
  List<Map<String, dynamic>> _categories = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _chargerCategories();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nomCtrl.dispose();
    _emojiCtrl.dispose();
    super.dispose();
  }

  Future<void> _chargerCategories() async {
    setState(() => _loading = true);
    try {
      _categories = _db.getCategories();
      Logger.info('📂 Catégories chargées: ${_categories.length}');
    } catch (e) {
      Logger.error('❌ Erreur chargement catégories: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  List<Map<String, dynamic>> get _filteredCategories {
    final type = _tabController.index == 0 ? 'depense' : 'revenu';
    return _categories.where((c) =>
    c['type'] == type || c['type'] == 'dépense'
    ).toList();
  }

  void _showAjoutDialog() {
    _nomCtrl.clear();
    _emojiCtrl.clear();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Container(
            decoration: const BoxDecoration(
              color: TAPAColors.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: TAPAColors.border,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const Text(
                  'Nouvelle catégorie',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: TAPAColors.navy,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _tabController.index == 0 ? 'Catégorie de dépense' : 'Catégorie de revenu',
                  style: const TextStyle(
                    fontSize: 13,
                    color: TAPAColors.textSecond,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _nomCtrl,
                  textCapitalization: TextCapitalization.words,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Nom de la catégorie *',
                    hintText: 'Ex: Transport, Nourriture...',
                    prefixIcon: Icon(Icons.label_outline),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _emojiCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Émoji (optionnel)',
                    hintText: 'Ex: 🚗, 🍽️...',
                    prefixIcon: Icon(Icons.emoji_emotions_outlined),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: TAPAColors.background,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Text(
                        'Aperçu: ',
                        style: TextStyle(
                          fontSize: 12,
                          color: TAPAColors.textSecond,
                        ),
                      ),
                      Text(
                        '${_emojiCtrl.text.isNotEmpty ? _emojiCtrl.text : '📌'} ${_nomCtrl.text.isNotEmpty ? _nomCtrl.text : 'Nom de la catégorie'}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text('Annuler'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          // ✅ APPEL DIRECT À LA MÉTHODE D'AJOUT
                          await _ajouterCategorie(ctx);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: TAPAColors.navy,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text(
                          'Ajouter',
                          style: TextStyle(color: TAPAColors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // ✅ MÉTHODE AJOUTER CATÉGORIE - COMPLÈTEMENT CORRIGÉE
  // ==========================================================
  Future<void> _ajouterCategorie(BuildContext context) async {
    final nom = _nomCtrl.text.trim();

    // ✅ CORRECTION: Vérifier mounted avant d'utiliser context
    if (!mounted) return;

    if (nom.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez entrer un nom'),
          backgroundColor: TAPAColors.red,
        ),
      );
      return;
    }

    final emoji = _emojiCtrl.text.trim().isEmpty ? '📌' : _emojiCtrl.text.trim();
    final type = _tabController.index == 0 ? 'depense' : 'revenu';

    // ✅ CORRECTION: Vérifier mounted avant d'utiliser context
    if (!mounted) return;

    final existe = _categories.any((c) =>
    c['label']?.toLowerCase() == nom.toLowerCase() && c['type'] == type
    );

    if (existe) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('La catégorie "$nom" existe déjà'),
          backgroundColor: TAPAColors.red,
        ),
      );
      return;
    }

    try {
      final nouvelleCategorie = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'label': nom,
        'emoji': emoji,
        'type': type,
        'isDefault': false,
      };

      Logger.info('📝 Ajout catégorie: $nouvelleCategorie');
      await _db.addCategory(nouvelleCategorie);
      await _chargerCategories();

      // ✅ CORRECTION: Vérifier mounted après chaque await
      if (!mounted) return;
      Navigator.pop(context);

      // ✅ CORRECTION: Vérifier mounted avant d'utiliser context
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Catégorie "$nom" ajoutée !'),
          backgroundColor: TAPAColors.green,
        ),
      );
    } catch (e) {
      // ✅ CORRECTION: Vérifier mounted avant d'utiliser context
      if (!mounted) return;
      Logger.error('❌ Erreur ajout catégorie: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Erreur: ${e.toString().replaceAll('Exception: ', '')}'),
          backgroundColor: TAPAColors.red,
        ),
      );
    }
  }

  // ==========================================================
  // SUPPRIMER CATÉGORIE - AVEC VÉRIFICATION mounted
  // ==========================================================
  Future<void> _supprimerCategorie(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer ?'),
        content: const Text('Cette catégorie sera supprimée.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Supprimer',
              style: TextStyle(color: TAPAColors.red),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _db.deleteCategory(id);
        await _chargerCategories();

        // ✅ CORRECTION: Vérifier mounted avant d'utiliser context
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Catégorie supprimée'),
            backgroundColor: TAPAColors.green,
          ),
        );
      } catch (e) {
        // ✅ CORRECTION: Vérifier mounted avant d'utiliser context
        if (!mounted) return;
        Logger.error('❌ Erreur suppression catégorie: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: TAPAColors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cats = _filteredCategories;

    return Scaffold(
      backgroundColor: TAPAColors.background,
      appBar: AppBar(
        title: const Text('Mes catégories'),
        backgroundColor: TAPAColors.navy,
        foregroundColor: TAPAColors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: TAPAColors.gold),
            onPressed: _showAjoutDialog,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Dépenses'),
            Tab(text: 'Revenus'),
          ],
          indicatorColor: TAPAColors.gold,
          labelColor: TAPAColors.gold,
          unselectedLabelColor: Colors.white54,
          onTap: (_) => setState(() {}),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : cats.isEmpty
          ? _buildEmptyState()
          : _buildCategoryList(cats),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.category_outlined,
            size: 60,
            color: TAPAColors.textHint,
          ),
          const SizedBox(height: 16),
          const Text(
            'Aucune catégorie',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: TAPAColors.navy,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _tabController.index == 0
                ? 'Ajoutez des catégories de dépenses'
                : 'Ajoutez des catégories de revenus',
            style: const TextStyle(color: TAPAColors.textSecond),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _showAjoutDialog,
            icon: const Icon(Icons.add, color: TAPAColors.gold),
            label: const Text('Ajouter une catégorie'),
            style: ElevatedButton.styleFrom(
              backgroundColor: TAPAColors.navy,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryList(List<Map<String, dynamic>> cats) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: cats.length,
      itemBuilder: (ctx, i) {
        final c = cats[i];
        final isDefault = c['isDefault'] == true;

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: TAPAColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDefault ? TAPAColors.gold.withOpacity(0.3) : TAPAColors.border,
              width: isDefault ? 1.5 : 0.5,
            ),
          ),
          child: Row(
            children: [
              Text(
                c['emoji'] ?? '📌',
                style: const TextStyle(fontSize: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      c['label'] ?? '',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: TAPAColors.navy,
                      ),
                    ),
                    if (isDefault)
                      Text(
                        'Défaut',
                        style: TextStyle(
                          fontSize: 10,
                          color: TAPAColors.gold,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ),
              if (!isDefault)
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    color: TAPAColors.textHint,
                    size: 20,
                  ),
                  onPressed: () => _supprimerCategorie(c['id'] as String),
                ),
            ],
          ),
        );
      },
    );
  }
}