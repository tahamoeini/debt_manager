import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/account.dart';
import '../providers/accounts_provider.dart';

class AccountFormScreen extends ConsumerStatefulWidget {
  final Account? account;

  const AccountFormScreen({this.account, Key? key}) : super(key: key);

  @override
  ConsumerState<AccountFormScreen> createState() => _AccountFormScreenState();
}

class _AccountFormScreenState extends ConsumerState<AccountFormScreen> {
  late TextEditingController _nameCtrl;
  late TextEditingController _notesCtrl;
  late TextEditingController _balanceCtrl;
  late AccountType _selectedType;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.account?.name ?? '');
    _notesCtrl =
        TextEditingController(text: widget.account?.notes ?? '');
    _balanceCtrl = TextEditingController(
      text: widget.account?.balance.toStringAsFixed(0) ?? '0',
    );
    _selectedType = widget.account?.type ?? AccountType.cash;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _notesCtrl.dispose();
    _balanceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.account != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'ویرایش حساب' : 'افزودن حساب'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Name
            TextField(
              controller: _nameCtrl,
              decoration: InputDecoration(
                labelText: 'نام حساب',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Type
            DropdownButtonFormField<AccountType>(
              value: _selectedType,
              decoration: InputDecoration(
                labelText: 'نوع حساب',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: AccountType.values
                  .map((type) => DropdownMenuItem(
                        value: type,
                        child: Text(
                          switch (type) {
                            AccountType.bank => '🏦 حساب بانکی',
                            AccountType.wallet => '👜 کیف پول',
                            AccountType.cash => '💵 نقد',
                          },
                        ),
                      ))
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedType = value);
                }
              },
            ),
            const SizedBox(height: 16),

            // Balance
            TextField(
              controller: _balanceCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'موجودی (ریال)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Notes
            TextField(
              controller: _notesCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'یادداشت‌ها',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Save button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _save,
                child: Text(isEditing ? 'ذخیره' : 'افزودن'),
              ),
            ),

            if (isEditing) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _delete,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                  ),
                  child: const Text('حذف'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _save() {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('نام حساب الزامی است')),
      );
      return;
    }

    final balance = double.tryParse(_balanceCtrl.text) ?? 0;
    final now = DateTime.now().toIso8601String();

    if (widget.account == null) {
      // Create new account
      final account = Account(
        id: 0, // Will be assigned by DB
        name: name,
        type: _selectedType,
        balance: balance,
        notes: _notesCtrl.text.isEmpty ? null : _notesCtrl.text,
        createdAt: now,
      );
      ref.read(accountsNotifierProvider.notifier).addAccount(account);
    } else {
      // Update existing account
      final account = widget.account!.copyWith(
        name: name,
        type: _selectedType,
        balance: balance,
        notes: _notesCtrl.text.isEmpty ? null : _notesCtrl.text,
      );
      ref.read(accountsNotifierProvider.notifier).updateAccount(account);
    }

    Navigator.pop(context);
  }

  void _delete() {
    if (widget.account == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف حساب'),
        content: const Text('آیا مطمئن هستید؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('انصراف'),
          ),
          TextButton(
            onPressed: () {
              ref
                  .read(accountsNotifierProvider.notifier)
                  .deleteAccount(widget.account!.id);
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('حذف', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
