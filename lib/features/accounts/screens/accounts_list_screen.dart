import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/account.dart';
import '../providers/accounts_provider.dart';
import 'account_form_screen.dart';
import 'account_detail_screen.dart';

class AccountsListScreen extends ConsumerWidget {
  const AccountsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountsAsync = ref.watch(accountsNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('حساب‌ها'),
        elevation: 0,
      ),
      body: accountsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('خطا: $err')),
        data: (accounts) {
          if (accounts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.account_balance, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    'هیچ حسابی ثبت نشده است',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => _navigateToAddAccount(context),
                    icon: const Icon(Icons.add),
                    label: const Text('افزودن حساب'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: accounts.length,
            padding: const EdgeInsets.all(12),
            itemBuilder: (context, idx) {
              final account = accounts[idx];
              return AccountCard(
                account: account,
                onTap: () => _navigateToDetail(context, account),
                onEdit: () => _navigateToEdit(context, account),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToAddAccount(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _navigateToAddAccount(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const AccountFormScreen(account: null),
      ),
    );
  }

  void _navigateToDetail(BuildContext context, Account account) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AccountDetailScreen(account: account),
      ),
    );
  }

  void _navigateToEdit(BuildContext context, Account account) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AccountFormScreen(account: account),
      ),
    );
  }
}

class AccountCard extends StatelessWidget {
  final Account account;
  final VoidCallback onTap;
  final VoidCallback onEdit;

  const AccountCard({
    required this.account,
    required this.onTap,
    required this.onEdit,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: ListTile(
        onTap: onTap,
        leading: Icon(
          switch (account.type) {
            AccountType.bank => Icons.account_balance,
            AccountType.wallet => Icons.card_giftcard,
            AccountType.cash => Icons.attach_money,
          },
          size: 32,
        ),
        title: Text(account.displayName),
        subtitle: Text(account.typeLabel),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${account.balance.toStringAsFixed(0)} ریال',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }
}
