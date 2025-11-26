import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../models/user.dart';

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
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Navn',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: pinController,
                decoration: const InputDecoration(
                  labelText: 'PIN (4 cifre)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                maxLength: 4,
              ),
              const SizedBox(height: 16),
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
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuller'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isEmpty || pinController.text.length != 4) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Navn og PIN (4 cifre) er påkrævet')),
                );
                return;
              }

              // Check for duplicate PIN
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
            child: const Text('Tilføj'),
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
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Navn',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: pinController,
                decoration: const InputDecoration(
                  labelText: 'PIN (4 cifre)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                maxLength: 4,
              ),
              const SizedBox(height: 16),
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
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuller'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isEmpty || pinController.text.length != 4) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Navn og PIN (4 cifre) er påkrævet')),
                );
                return;
              }

              // Check for duplicate PIN (exclude current user)
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
            child: const Text('Gem'),
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
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuller'),
          ),
          ElevatedButton(
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
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Slet'),
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
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: _users.length,
              itemBuilder: (context, index) {
                final user = _users[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
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
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getRoleColor(user.role).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            _getRoleLabel(user.role),
                            style: TextStyle(
                              color: _getRoleColor(user.role),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'PIN: ${user.pin}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey[600],
                              ),
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
