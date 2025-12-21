import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/database_service.dart';
import '../constants/roles_and_features.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../widgets/ui/ska_button.dart';
import '../widgets/ui/ska_card.dart';

class RolePermissionsScreen extends StatefulWidget {
  const RolePermissionsScreen({super.key});

  @override
  State<RolePermissionsScreen> createState() => _RolePermissionsScreenState();
}

class _RolePermissionsScreenState extends State<RolePermissionsScreen> {
  final _dbService = DatabaseService();
  late List<User> _users;
  String _selectedRole = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  void _loadUsers() {
    setState(() {
      _users = _dbService.getAllUsers().toList();
      _isLoading = false;
    });
  }

  Future<void> _updateUserFeatures(User user, List<String> newFeatures) async {
    final updatedUser = User(
      id: user.id,
      name: user.name,
      pin: user.pin,
      role: user.role,
      enabledFeatures: newFeatures,
      createdAt: user.createdAt,
    );

    await _dbService.updateUser(updatedUser);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${user.name}s tilladelser opdateret')),
      );
    }

    _loadUsers();
  }

  void _showUserPermissionsDialog(User user) {
    final enabledFeatures = List<String>.from(user.enabledFeatures ?? []);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${user.name} - Tilladelser'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.blue50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Rolle: ${AppRoles.labels[user.role]}',
                        style: AppTypography.smSemibold,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Vaelg hvilke funktioner denne bruger skal have adgang til:',
                        style: AppTypography.xs.copyWith(color: AppColors.mutedForeground),
                      ),
                    ],
                  ),
                ),
              ),
              ...AppFeatures.all.map((feature) {
                return CheckboxListTile(
                  value: enabledFeatures.contains(feature),
                  onChanged: (value) {
                    setState(() {
                      if (value == true) {
                        enabledFeatures.add(feature);
                      } else {
                        enabledFeatures.remove(feature);
                      }
                    });
                  },
                  title: Text(AppFeatures.labels[feature] ?? feature),
                  subtitle: Text(
                    AppFeatures.descriptions[feature] ?? '',
                    style: const TextStyle(fontSize: 12),
                  ),
                  contentPadding: EdgeInsets.zero,
                );
              }).toList(),
            ],
          ),
        ),
        actions: [
          SkaButton(
            onPressed: () => Navigator.pop(context),
            variant: ButtonVariant.ghost,
            text: 'Afbryd',
          ),
          SkaButton(
            onPressed: () {
              _updateUserFeatures(user, enabledFeatures);
              Navigator.pop(context);
            },
            variant: ButtonVariant.primary,
            text: 'Gem',
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Roller & Tilladelser'),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Role filter tabs
          Padding(
            padding: AppSpacing.p6,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  FilterChip(
                    label: const Text('Alle'),
                    selected: _selectedRole.isEmpty,
                    onSelected: (selected) {
                      setState(() {
                        _selectedRole = '';
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                  ...AppRoles.all.map((role) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: FilterChip(
                        label: Text(AppRoles.labels[role] ?? role),
                        selected: _selectedRole == role,
                        onSelected: (selected) {
                          setState(() {
                            _selectedRole = selected ? role : '';
                          });
                        },
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ),
          // Users list
          Expanded(
            child: Builder(
              builder: (context) {
                final filteredUsers = _selectedRole.isEmpty
                    ? _users
                    : _users.where((u) => u.role == _selectedRole).toList();

                if (filteredUsers.isEmpty) {
                  return Center(
                    child: Text('Ingen brugere fundet for rolle: $_selectedRole'),
                  );
                }

                return ListView.builder(
                  itemCount: filteredUsers.length,
                  itemBuilder: (context, index) {
                    final user = filteredUsers[index];
                    final enabledCount = user.enabledFeatures?.length ?? 0;
                    final totalFeatures = AppFeatures.all.length;

                    return SkaCard(
                      padding: EdgeInsets.zero,
                      child: ListTile(
                        leading: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: _getRoleColor(user.role),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              user.name[0].toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                              ),
                            ),
                          ),
                        ),
                        title: Text(user.name),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Rolle: ${AppRoles.labels[user.role]}',
                              style: const TextStyle(fontSize: 12),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Tilladelser: $enabledCount/$totalFeatures',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => _showUserPermissionsDialog(user),
                        ),
                        onTap: () => _showUserPermissionsDialog(user),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          // Role defaults section
          Padding(
            padding: AppSpacing.p6,
            child: SkaCard(
              padding: EdgeInsets.zero,
              child: ExpansionTile(
                title: const Text('Standardtilladelser pr. rolle'),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: AppRoles.all.map((role) {
                        final defaultFeatures = AppFeatures.getDefaultFeaturesForRole(role);
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppRoles.labels[role] ?? role,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                children: defaultFeatures
                                    .map((feature) => Chip(
                                          label: Text(
                                            AppFeatures.labels[feature] ?? feature,
                                          ),
                                        ))
                                    .toList(),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'admin':
        return AppColors.error;
      case 'bogholder':
        return AppColors.success;
      case 'tekniker':
      default:
        return AppColors.primary;
    }
  }
}
