import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../models/user.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../widgets/ui/ska_badge.dart';
import '../widgets/ui/ska_button.dart';
import '../widgets/ui/ska_card.dart';
import '../widgets/ui/ska_input.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final _dbService = DatabaseService();
  late List<User> _users;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  void _loadUsers() {
    setState(() {
      _users = _dbService.getAllUsers();
      _users.sort((a, b) => a.name.compareTo(b.name));
    });
  }

  void _showAddUserDialog() {
    final nameController = TextEditingController();
    final pinController = TextEditingController();
    String selectedRole = 'tekniker';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tilføj ny bruger'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SkaInput(
                label: 'Navn',
                controller: nameController,
              ),
              const SizedBox(height: AppSpacing.s4),
              SkaInput(
                label: 'PIN (4 cifre)',
                controller: pinController,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: AppSpacing.s4),
              StatefulBuilder(
                builder: (context, setDialogState) => DropdownButtonFormField<String>(
                  initialValue: selectedRole,
                  decoration: const InputDecoration(
                    labelText: 'Rolle',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'tekniker', child: Text('Tekniker')),
                    DropdownMenuItem(value: 'admin', child: Text('Admin')),
                    DropdownMenuItem(value: 'bogholder', child: Text('Bogholder')),
                  ],
                  onChanged: (value) {
                    setDialogState(() => selectedRole = value ?? 'tekniker');
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          SkaButton(
            onPressed: () => Navigator.pop(context),
            variant: ButtonVariant.ghost,
            text: 'Annuller',
          ),
          SkaButton(
            onPressed: () async {
              if (nameController.text.isEmpty || pinController.text.length != 4) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Navn og PIN (4 cifre) er påkrævet')),
                );
                return;
              }

              final existingUserWithPin = _users.where((u) => u.pin == pinController.text).toList();
              if (existingUserWithPin.isNotEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('PIN ${pinController.text} er allerede i brug af ${existingUserWithPin.first.name}')),
                );
                return;
              }

              final newUser = User(
                id: 'user_${DateTime.now().millisecondsSinceEpoch}',
                name: nameController.text,
                pin: pinController.text,
                role: selectedRole,
                createdAt: DateTime.now().toIso8601String(),
              );

              await _dbService.addUser(newUser);
              if (mounted) {
                Navigator.pop(context);
                _loadUsers();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Bruger tilføjet')),
                );
              }
            },
            variant: ButtonVariant.primary,
            text: 'Tilføj',
          ),
        ],
      ),
    );
  }

  void _showEditUserDialog(User user) {
    final nameController = TextEditingController(text: user.name);
    final pinController = TextEditingController(text: user.pin);
    String selectedRole = user.role;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rediger bruger'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SkaInput(
                label: 'Navn',
                controller: nameController,
              ),
              const SizedBox(height: AppSpacing.s4),
              SkaInput(
                label: 'PIN (4 cifre)',
                controller: pinController,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: AppSpacing.s4),
              StatefulBuilder(
                builder: (context, setDialogState) => DropdownButtonFormField<String>(
                  initialValue: selectedRole,
                  decoration: const InputDecoration(
                    labelText: 'Rolle',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'tekniker', child: Text('Tekniker')),
                    DropdownMenuItem(value: 'admin', child: Text('Admin')),
                    DropdownMenuItem(value: 'bogholder', child: Text('Bogholder')),
                  ],
                  onChanged: (value) {
                    setDialogState(() => selectedRole = value ?? 'tekniker');
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          SkaButton(
            onPressed: () => Navigator.pop(context),
            variant: ButtonVariant.ghost,
            text: 'Annuller',
          ),
          SkaButton(
            onPressed: () async {
              if (nameController.text.isEmpty || pinController.text.length != 4) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Navn og PIN (4 cifre) er påkrævet')),
                );
                return;
              }

              final existingUserWithPin = _users.where((u) => u.pin == pinController.text && u.id != user.id).toList();
              if (existingUserWithPin.isNotEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('PIN ${pinController.text} er allerede i brug af ${existingUserWithPin.first.name}')),
                );
                return;
              }

              final updatedUser = User(
                id: user.id,
                name: nameController.text,
                pin: pinController.text,
                role: selectedRole,
                createdAt: user.createdAt,
              );

              await _dbService.addUser(updatedUser);
              if (mounted) {
                Navigator.pop(context);
                _loadUsers();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Bruger opdateret')),
                );
              }
            },
            variant: ButtonVariant.primary,
            text: 'Gem',
          ),
        ],
      ),
    );
  }

  void _deleteUser(User user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Slet bruger'),
        content: Text('Er du sikker på at du vil slette ${user.name}?'),
        actions: [
          SkaButton(
            onPressed: () => Navigator.pop(context),
            variant: ButtonVariant.ghost,
            text: 'Annuller',
          ),
          SkaButton(
            onPressed: () async {
              await _dbService.deleteUser(user.id);
              if (mounted) {
                Navigator.pop(context);
                _loadUsers();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Bruger slettet')),
                );
              }
            },
            variant: ButtonVariant.destructive,
            text: 'Slet',
          ),
        ],
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'admin':
        return Colors.red;
      case 'bogholder':
        return Colors.purple;
      default:
        return Colors.blue;
    }
  }

  String _getRoleLabel(String role) {
    switch (role) {
      case 'admin':
        return 'Admin';
      case 'bogholder':
        return 'Bogholder';
      default:
        return 'Tekniker';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Brugeradministration'),
        elevation: 0,
      ),
      body: _users.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Ingen brugere',
                    style: AppTypography.lgSemibold.copyWith(
                      color: AppColors.mutedForeground,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: AppSpacing.p4,
              itemCount: _users.length,
              itemBuilder: (context, index) {
                final user = _users[index];
                return SkaCard(
                  padding: EdgeInsets.zero,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _getRoleColor(user.role).withValues(alpha: 0.2),
                      child: Text(
                        user.name[0].toUpperCase(),
                        style: TextStyle(
                          color: _getRoleColor(user.role),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(user.name),
                    subtitle: Row(
                      children: [
                        SkaBadge(
                          text: _getRoleLabel(user.role),
                          variant: BadgeVariant.secondary,
                          small: true,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'PIN: ${user.pin}',
                          style: AppTypography.xs.copyWith(color: AppColors.mutedForeground),
                        ),
                      ],
                    ),
                    trailing: PopupMenuButton(
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          child: const Text('Rediger'),
                          onTap: () => Future.delayed(
                            const Duration(milliseconds: 300),
                            () => _showEditUserDialog(user),
                          ),
                        ),
                        PopupMenuItem(
                          child: const Text('Slet', style: TextStyle(color: Colors.red)),
                          onTap: () => Future.delayed(
                            const Duration(milliseconds: 300),
                            () => _deleteUser(user),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddUserDialog,
        tooltip: 'Tilføj bruger',
        child: const Icon(Icons.add),
      ),
    );
  }
}
