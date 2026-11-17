import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_theme.dart';
import '../../providers/admin/admin_provider.dart';

class AdminUserDetailScreen extends ConsumerWidget {
  final String userId;

  const AdminUserDetailScreen({super.key, required this.userId});

  Future<void> _refresh(WidgetRef ref) async {
    ref.invalidate(adminUserDetailsProvider(userId));
    await ref.read(adminUserDetailsProvider(userId).future);
  }

  Future<void> _contactWhatsApp(BuildContext context, String phone) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanPhone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aucun numero de telephone disponible.')),
      );
      return;
    }
    final uri = Uri.parse('https://wa.me/$cleanPhone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Impossible d'ouvrir WhatsApp.")),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncData = ref.watch(adminUserDetailsProvider(userId));

    return Scaffold(
      backgroundColor: TAPAColors.background,
      appBar: AppBar(
        title: const Text('Details Utilisateur'),
        backgroundColor: TAPAColors.navy,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: asyncData.isLoading ? null : () => _refresh(ref),
          ),
        ],
      ),
      body: asyncData.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Erreur de chargement'),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: () => _refresh(ref),
                icon: const Icon(Icons.refresh),
                label: const Text('Reessayer'),
              ),
            ],
          ),
        ),
        data: (data) {
          if (data == null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Utilisateur introuvable'),
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: () => _refresh(ref),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reessayer'),
                  ),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () => _refresh(ref),
            child: _buildContent(context, data),
          );
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, Map<String, dynamic> data) {
    final user = _asMap(data['user']);
    final mainWallet = data['mainWallet'];
    final wallets = _asList(data['wallets']);
    final transactions = _asList(data['transactions']);
    final sonamContracts = _asList(data['sonamContracts']);
    final souscriptions = _asList(data['souscriptions']);

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        _ProfileCard(
          user: user,
          fallbackId: userId,
          onContact: () => _contactWhatsApp(context, _str(user['phoneNumber'])),
        ),
        const SizedBox(height: 24),
        if (mainWallet is Map) ...[
          const _SectionTitle('Wallet TAPA'),
          _MainWalletCard(wallet: _asMap(mainWallet)),
          const SizedBox(height: 24),
        ],
        const _SectionTitle('Portefeuilles (Sources)'),
        if (wallets.isEmpty)
          const _EmptyState(
            icon: Icons.info_outline,
            message: 'Aucun portefeuille externe configure.',
          )
        else
          ...wallets.map((w) => _WalletCard(wallet: _asMap(w))),
        const SizedBox(height: 24),
        const _SectionTitle('Dernieres transactions'),
        if (transactions.isEmpty)
          const _EmptyState(
            icon: Icons.receipt_long_outlined,
            message: 'Aucune transaction enregistree.',
          )
        else
          ...transactions.map((t) => _TransactionCard(tx: _asMap(t))),
        const SizedBox(height: 24),
        const _SectionTitle('Contrats SONAM'),
        if (sonamContracts.isEmpty)
          const _EmptyState(
            icon: Icons.description_outlined,
            message: 'Aucun contrat SONAM.',
          )
        else
          ...sonamContracts.map((c) => _SonamContractCard(contract: _asMap(c))),
        const SizedBox(height: 24),
        const _SectionTitle('Souscriptions'),
        if (souscriptions.isEmpty)
          const _EmptyState(
            icon: Icons.assignment_outlined,
            message: 'Aucune souscription.',
          )
        else
          ...souscriptions.map((s) => _SouscriptionCard(sub: _asMap(s))),
      ],
    );
  }
}

Map<String, dynamic> _asMap(dynamic value) =>
    value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};

List<dynamic> _asList(dynamic value) => value is List ? value : <dynamic>[];

String _str(dynamic value, [String fallback = '']) {
  final s = value?.toString().trim() ?? '';
  return s.isEmpty ? fallback : s;
}

num _num(dynamic value) =>
    value is num ? value : (num.tryParse(value?.toString() ?? '') ?? 0);

String _formatFcfa(num amount) {
  final digits = amount.round().abs().toString();
  final grouped = digits.replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => ' ',
  );
  return '${amount < 0 ? '-' : ''}$grouped FCFA';
}

String _formatDate(dynamic value) {
  final date = DateTime.tryParse(value?.toString() ?? '')?.toLocal();
  if (date == null) return 'Date inconnue';
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(date.day)}/${two(date.month)}/${date.year} '
      '${two(date.hour)}:${two(date.minute)}';
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: TAPAColors.navy,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  const _EmptyState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey.shade400, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final Map<String, dynamic> user;
  final String fallbackId;
  final VoidCallback onContact;

  const _ProfileCard({
    required this.user,
    required this.fallbackId,
    required this.onContact,
  });

  @override
  Widget build(BuildContext context) {
    final prenom = _str(user['prenom']);
    final initial = prenom.isEmpty ? 'U' : prenom.substring(0, 1).toUpperCase();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: TAPAColors.navy.withOpacity(0.1),
            child: Text(
              initial,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: TAPAColors.navy,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _str(prenom, 'Sans prenom'),
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: TAPAColors.navy,
            ),
          ),
          const SizedBox(height: 8),
          _InfoRow(
            icon: Icons.email_outlined,
            text: _str(user['email'], "Pas d'email"),
          ),
          const SizedBox(height: 4),
          _InfoRow(
            icon: Icons.phone_outlined,
            text: _str(user['phoneNumber'], 'Pas de telephone'),
          ),
          const SizedBox(height: 4),
          _InfoRow(
            icon: Icons.fingerprint,
            text: 'ID: ${_str(user['id'], fallbackId)}',
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onContact,
              icon: const Icon(Icons.chat_bubble_outline),
              label: const Text('Contacter sur WhatsApp'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF25D366),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            text,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            style: const TextStyle(color: Colors.grey, fontSize: 14),
          ),
        ),
      ],
    );
  }
}

class _MainWalletCard extends StatelessWidget {
  final Map<String, dynamic> wallet;
  const _MainWalletCard({required this.wallet});

  @override
  Widget build(BuildContext context) {
    final solde = _num(wallet['solde'] ?? wallet['balance']);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [TAPAColors.navy, Color(0xFF152A47)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Solde disponible',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          Text(
            _formatFcfa(solde),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _WalletCard extends StatelessWidget {
  final Map<String, dynamic> wallet;
  const _WalletCard({required this.wallet});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _str(wallet['nom'], 'Portefeuille'),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _str(wallet['type'], 'Type inconnu'),
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            _formatFcfa(_num(wallet['solde'])),
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 18,
              color: TAPAColors.navy,
            ),
          ),
        ],
      ),
    );
  }
}

class _TransactionCard extends StatelessWidget {
  final Map<String, dynamic> tx;
  const _TransactionCard({required this.tx});

  @override
  Widget build(BuildContext context) {
    final amount = _num(tx['amount']);
    final isDebit = tx['type'] == 'debit' || amount < 0;
    final color = isDebit ? Colors.red : Colors.green;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _str(tx['description'], 'Transaction'),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  _formatDate(tx['createdAt']),
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '${isDebit ? '-' : '+'}${_formatFcfa(amount.abs())}',
            style: TextStyle(fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }
}

class _SonamContractCard extends StatelessWidget {
  final Map<String, dynamic> contract;
  const _SonamContractCard({required this.contract});

  @override
  Widget build(BuildContext context) {
    final assure = _asMap(contract['assure']);
    final statut = _str(contract['statut'], 'Inconnu');
    final statutColor = statut == 'Actif' ? Colors.green : Colors.orange;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  _str(contract['produit'], 'N/A'),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: TAPAColors.navy,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: statutColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  statut,
                  style: TextStyle(
                    color: statutColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Police: ${_str(contract['policeCode'], 'N/A')}',
            style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
          ),
          Text(
            'Assure: ${_str(assure['nom_prenoms'], 'Inconnu')}',
            style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
          ),
          const SizedBox(height: 8),
          Text(
            'Total verse: ${_formatFcfa(_num(contract['totalVerse']))}',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _SouscriptionCard extends StatelessWidget {
  final Map<String, dynamic> sub;
  const _SouscriptionCard({required this.sub});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Text(
        _str(sub['statut'], 'Souscription'),
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }
}
