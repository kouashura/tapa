import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../providers/admin/admin_provider.dart';

class AdminUsersListScreen extends ConsumerStatefulWidget {
  const AdminUsersListScreen({super.key});

  @override
  ConsumerState<AdminUsersListScreen> createState() =>
      _AdminUsersListScreenState();
}

class _AdminUsersListScreenState extends ConsumerState<AdminUsersListScreen> {
  final TextEditingController _searchController = TextEditingController();

  String get _query => _searchController.text.trim().toLowerCase();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _filtered(List<Map<String, dynamic>> users) {
    final q = _query;
    if (q.isEmpty) return users;
    return users.where((u) {
      return _str(u['prenom']).toLowerCase().contains(q) ||
          _str(u['email']).toLowerCase().contains(q) ||
          _str(u['phoneNumber']).toLowerCase().contains(q);
    }).toList();
  }

  Future<void> _refresh() async {
    ref.invalidate(adminUsersProvider);
    await ref.read(adminUsersProvider.future);
  }

  void _onSearchChanged(String _) => setState(() {});

  void _clearSearch() {
    _searchController.clear();
    setState(() {});
  }

  void _openUser(Map<String, dynamic> user) {
    final id = _str(user['id']);
    if (id.isEmpty) return;
    context.push('/admin/users/$id');
  }

  @override
  Widget build(BuildContext context) {
    final asyncUsers = ref.watch(adminUsersProvider);

    return Scaffold(
      backgroundColor: TAPAColors.background,
      body: Column(
        children: [
          _buildHeader(asyncUsers),
          Expanded(child: _buildBody(asyncUsers)),
        ],
      ),
    );
  }

  Widget _buildHeader(AsyncValue<List<Map<String, dynamic>>> asyncUsers) {
    return Container(
      decoration: const BoxDecoration(
        color: TAPAColors.navy,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 4, 8, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                    color: Colors.white,
                    tooltip: 'Retour',
                    onPressed: () => context.pop(),
                  ),
                  const Expanded(
                    child: Text(
                      'Utilisateurs',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded),
                    color: Colors.white,
                    tooltip: 'Actualiser',
                    onPressed: asyncUsers.isLoading ? null : _refresh,
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 8, 0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: _buildCountPill(asyncUsers),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 16, 8, 0),
                child: _buildSearchField(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCountPill(AsyncValue<List<Map<String, dynamic>>> asyncUsers) {
    final total = asyncUsers.maybeWhen(
      data: (users) => users.length,
      orElse: () => 0,
    );
    final shown = asyncUsers.maybeWhen(
      data: (users) => _filtered(users).length,
      orElse: () => 0,
    );
    final plural = total > 1 ? 's' : '';

    final String label;
    if (asyncUsers.isLoading) {
      label = 'Chargement...';
    } else if (_query.isNotEmpty) {
      label = '$shown sur $total utilisateur$plural';
    } else {
      label = '$total utilisateur$plural inscrit$plural';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.people_alt_rounded, size: 15, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: _onSearchChanged,
        textInputAction: TextInputAction.search,
        style: const TextStyle(fontSize: 15),
        decoration: InputDecoration(
          hintText: 'Nom, email ou telephone',
          hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
          prefixIcon: Icon(Icons.search_rounded, color: Colors.grey.shade600),
          suffixIcon: _searchController.text.isEmpty
              ? null
              : IconButton(
                  icon: Icon(Icons.close_rounded, color: Colors.grey.shade600),
                  tooltip: 'Effacer',
                  onPressed: _clearSearch,
                ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  Widget _buildBody(AsyncValue<List<Map<String, dynamic>>> asyncUsers) {
    return asyncUsers.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: TAPAColors.navy),
      ),
      error: (e, _) => _StateMessage(
        icon: Icons.cloud_off_rounded,
        title: 'Chargement impossible',
        message: 'Verifiez votre connexion puis reessayez.',
        actionLabel: 'Reessayer',
        onAction: _refresh,
      ),
      data: (users) {
        final filtered = _filtered(users);
        if (filtered.isEmpty) {
          final searching = _query.isNotEmpty;
          return _StateMessage(
            icon: searching ? Icons.search_off_rounded : Icons.people_outline,
            title: searching ? 'Aucun resultat' : 'Aucun utilisateur',
            message: searching
                ? 'Essayez un autre nom, email ou numero.'
                : 'Les utilisateurs inscrits apparaitront ici.',
          );
        }
        return RefreshIndicator(
          color: TAPAColors.navy,
          onRefresh: _refresh,
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
            itemCount: filtered.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final user = filtered[index];
              return _UserCard(user: user, onTap: () => _openUser(user));
            },
          ),
        );
      },
    );
  }
}

String _str(dynamic value) => value?.toString().trim() ?? '';

class _StateMessage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _StateMessage({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: TAPAColors.navy.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 40, color: TAPAColors.navy),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: TAPAColors.navy,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.refresh_rounded),
                label: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  final Map<String, dynamic> user;
  final VoidCallback onTap;

  const _UserCard({required this.user, required this.onTap});

  static const List<Color> _avatarColors = [
    Color(0xFF3B6FD4),
    Color(0xFF0F9D8A),
    Color(0xFFE08A1E),
    Color(0xFF8E5CD9),
    Color(0xFFD9534F),
    Color(0xFF2E8B57),
  ];

  Color _avatarColor(String key) {
    final sum = key.codeUnits.fold<int>(0, (acc, c) => acc + c);
    return _avatarColors[sum % _avatarColors.length];
  }

  @override
  Widget build(BuildContext context) {
    final name = _str(user['prenom']);
    final email = _str(user['email']);
    final phone = _str(user['phoneNumber']);
    final color = _avatarColor(name.isNotEmpty ? name : email);
    final initial = name.isEmpty ? '?' : name.substring(0, 1).toUpperCase();

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  initial,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name.isEmpty ? 'Sans prenom' : name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: name.isEmpty
                            ? Colors.grey.shade500
                            : TAPAColors.navy,
                      ),
                    ),
                    const SizedBox(height: 6),
                    _InfoRow(
                      icon: Icons.mail_outline_rounded,
                      text: email.isEmpty ? "Pas d'email" : email,
                      muted: email.isEmpty,
                    ),
                    const SizedBox(height: 3),
                    _InfoRow(
                      icon: Icons.phone_outlined,
                      text: phone.isEmpty ? 'Pas de telephone' : phone,
                      muted: phone.isEmpty,
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool muted;

  const _InfoRow({
    required this.icon,
    required this.text,
    this.muted = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = muted ? Colors.grey.shade400 : Colors.grey.shade700;
    return Row(
      children: [
        Icon(icon, size: 15, color: Colors.grey.shade500),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 13, color: color),
          ),
        ),
      ],
    );
  }
}
