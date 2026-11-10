// lib/screens/profile/change_pin_screen.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../services/db_service_mysql.dart';

class ChangePinScreen extends StatefulWidget {
  const ChangePinScreen({super.key});
  @override
  State<ChangePinScreen> createState() => _ChangePinScreenState();
}

class _ChangePinScreenState extends State<ChangePinScreen> {
  final DBService _db = DBService();
  String _ancien = '';
  String _nouveau = '';
  String _confirm = '';
  int _step = 0;
  bool _error = false;
  String _errorMsg = '';
  bool _isLoading = false;

  void _press(String d) {
    if (_isLoading) return;
    setState(() => _error = false);
    if (_step == 0 && _ancien.length < 4) {
      setState(() => _ancien += d);
      if (_ancien.length == 4) {
        Future.delayed(const Duration(milliseconds: 200), _validateAncien);
      }
    } else if (_step == 1 && _nouveau.length < 4) {
      setState(() => _nouveau += d);
      if (_nouveau.length == 4) {
        Future.delayed(
            const Duration(milliseconds: 200), () => setState(() => _step = 2));
      }
    } else if (_step == 2 && _confirm.length < 4) {
      setState(() => _confirm += d);
      if (_confirm.length == 4) {
        Future.delayed(const Duration(milliseconds: 200), _validerNouveau);
      }
    }
  }

  void _delete() {
    if (_isLoading) return;
    if (_step == 0 && _ancien.isNotEmpty) {
      setState(() => _ancien = _ancien.substring(0, _ancien.length - 1));
    } else if (_step == 1 && _nouveau.isNotEmpty) {
      setState(() => _nouveau = _nouveau.substring(0, _nouveau.length - 1));
    } else if (_step == 2 && _confirm.isNotEmpty) {
      setState(() => _confirm = _confirm.substring(0, _confirm.length - 1));
    }
  }

  // ✅ CORRIGÉ : utilise async/await
  Future<void> _validateAncien() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      final isValid = await _db.verifyPin(_ancien);

      if (isValid) {
        setState(() {
          _step = 1;
          _isLoading = false;
          _error = false;
        });
      } else {
        setState(() {
          _ancien = '';
          _error = true;
          _errorMsg = 'Code incorrect. Réessaie.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _ancien = '';
        _error = true;
        _errorMsg = 'Erreur: ${e.toString().replaceAll('Exception: ', '')}';
        _isLoading = false;
      });
    }
  }

  Future<void> _validerNouveau() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    if (_nouveau != _confirm) {
      setState(() {
        _nouveau = '';
        _confirm = '';
        _step = 1;
        _error = true;
        _errorMsg = 'Les codes ne correspondent pas.';
        _isLoading = false;
      });
      return;
    }

    try {
      await _db.savePin(_nouveau);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PIN modifié avec succès !'),
            backgroundColor: TAPAColors.green,
          ),
        );
        context.pop();
      }
    } catch (e) {
      setState(() {
        _error = true;
        _errorMsg = 'Erreur: ${e.toString().replaceAll('Exception: ', '')}';
        _isLoading = false;
      });
    }
  }

  String get _currentPin {
    if (_step == 0) return _ancien;
    if (_step == 1) return _nouveau;
    return _confirm;
  }

  String get _title {
    if (_step == 0) return 'Entre ton ancien code';
    if (_step == 1) return 'Choisis ton nouveau code';
    return 'Confirme ton nouveau code';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TAPAColors.navy,
      appBar: AppBar(
          backgroundColor: TAPAColors.navy,
          foregroundColor: TAPAColors.white,
          title: const Text('Changer mon PIN')),
      body: SafeArea(
        child: Column(children: [
          const SizedBox(height: 30),
          Text(_title,
              style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: TAPAColors.white)),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                    value: (_step + 1) / 3,
                    backgroundColor: Colors.white12,
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(TAPAColors.gold))),
          ),
          if (_error) ...[
            const SizedBox(height: 8),
            Text(_errorMsg,
                style: const TextStyle(color: TAPAColors.red, fontSize: 12)),
          ],
          if (_isLoading) ...[
            const SizedBox(height: 8),
            const CircularProgressIndicator(
              color: TAPAColors.gold,
              strokeWidth: 2,
            ),
          ],
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
                4,
                (i) => Container(
                      margin: const EdgeInsets.symmetric(horizontal: 10),
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: i < _currentPin.length
                              ? TAPAColors.gold
                              : Colors.transparent,
                          border: Border.all(
                              color: i < _currentPin.length
                                  ? TAPAColors.gold
                                  : Colors.white38,
                              width: 2)),
                    )),
          ),
          const SizedBox(height: 40),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 1.8,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12),
                itemCount: 12,
                itemBuilder: (ctx, i) {
                  if (i == 9) return const SizedBox();
                  if (i == 11) {
                    return GestureDetector(
                        onTap: _delete,
                        child: Container(
                            decoration: BoxDecoration(
                                color: Colors.white10,
                                borderRadius: BorderRadius.circular(12)),
                            child: const Icon(Icons.backspace_outlined,
                                color: Colors.white60, size: 22)));
                  }
                  final d = i == 10 ? '0' : '${i + 1}';
                  return GestureDetector(
                      onTap: () => _press(d),
                      child: Container(
                          decoration: BoxDecoration(
                              color: Colors.white10,
                              borderRadius: BorderRadius.circular(12)),
                          child: Center(
                              child: Text(d,
                                  style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w500,
                                      color: TAPAColors.white)))));
                }),
          ),
        ]),
      ),
    );
  }
}
