import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:survey_app/models/user_profile.dart';
import 'package:survey_app/services/auth_service.dart';
import 'package:survey_app/services/admin_service.dart';
import 'package:survey_app/utils/colors.dart';
import 'package:survey_app/widgets/button_widget.dart';
import 'package:survey_app/widgets/text_widget.dart';
import 'package:fluttertoast/fluttertoast.dart';

class AccountManagementScreen extends StatefulWidget {
  const AccountManagementScreen({super.key});

  @override
  State<AccountManagementScreen> createState() =>
      _AccountManagementScreenState();
}

class _AccountManagementScreenState extends State<AccountManagementScreen> {
  final AuthService _authService = AuthService();
  final AdminService _adminService = AdminService();

  List<UserProfile> _users = [];
  List<UserProfile> _filteredUsers = [];
  bool _isLoading = true;

  String _searchQuery = '';
  String _statusFilter = 'all';

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  void _loadUsers() {
    setState(() {
      _isLoading = true;
    });

    // Listen to users stream
    _adminService.getAllUsers().listen((users) {
      setState(() {
        _users = users;
        _applyFilters();
        _isLoading = false;
      });
    }, onError: (error) {
      print(error);
      if (mounted) {
        Fluttertoast.showToast(
          msg: 'Failed to load users',
          backgroundColor: healthRed,
          textColor: Colors.white,
        );
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  void _applyFilters() {
    List<UserProfile> filtered = _users;

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((user) {
        final name = user.name.toLowerCase();
        final email = user.email.toLowerCase();
        final search = _searchQuery.toLowerCase();
        return name.contains(search) || email.contains(search);
      }).toList();
    }

    // Apply status filter
    if (_statusFilter != 'all') {
      filtered = filtered
          .where((user) => user.accountStatus == _statusFilter)
          .toList();
    }

    setState(() {
      _filteredUsers = filtered;
    });
  }

  void _showUserDetails(UserProfile user) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return UserDetailsSheet(
          user: user,
          onUserUpdated: (updatedUser) {
            setState(() {
              final index =
                  _users.indexWhere((u) => u.userId == updatedUser.userId);
              if (index != -1) {
                _users[index] = updatedUser;
                _applyFilters();
              }
            });
          },
          onUserStatusChanged: (updatedUser) async {
            try {
              await _adminService.updateUserAccountStatus(
                updatedUser.userId,
                updatedUser.accountStatus,
              );

              setState(() {
                final index =
                    _users.indexWhere((u) => u.userId == updatedUser.userId);
                if (index != -1) {
                  _users[index] = updatedUser;
                  _applyFilters();
                }
              });

              if (mounted) {
                Fluttertoast.showToast(
                  msg: 'User ${updatedUser.accountStatus}d successfully',
                  backgroundColor: updatedUser.accountStatus == 'active'
                      ? healthGreen
                      : healthRed,
                  textColor: Colors.white,
                );
              }
            } catch (e) {
              if (mounted) {
                Fluttertoast.showToast(
                  msg: 'Failed to update user status',
                  backgroundColor: healthRed,
                  textColor: Colors.white,
                );
              }
            }
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Search and filter section
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Search field
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'Search by name or email',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                        _applyFilters();
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  // Status filter
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        TextWidget(
                          text: 'Filter by status:',
                          fontSize: 14,
                          color: textPrimary,
                        ),
                        const SizedBox(width: 16),
                        ChoiceChip(
                          label: TextWidget(
                            text: 'All',
                            fontSize: 12,
                            color: _statusFilter == 'all'
                                ? Colors.white
                                : textPrimary,
                          ),
                          selected: _statusFilter == 'all',
                          selectedColor: primary,
                          onSelected: (selected) {
                            setState(() {
                              _statusFilter = selected ? 'all' : _statusFilter;
                              _applyFilters();
                            });
                          },
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: TextWidget(
                            text: 'Active',
                            fontSize: 12,
                            color: _statusFilter == 'active'
                                ? Colors.white
                                : textPrimary,
                          ),
                          selected: _statusFilter == 'active',
                          selectedColor: primary,
                          onSelected: (selected) {
                            setState(() {
                              _statusFilter =
                                  selected ? 'active' : _statusFilter;
                              _applyFilters();
                            });
                          },
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: TextWidget(
                            text: 'Inactive',
                            fontSize: 12,
                            color: _statusFilter == 'inactive'
                                ? Colors.white
                                : textPrimary,
                          ),
                          selected: _statusFilter == 'inactive',
                          selectedColor: primary,
                          onSelected: (selected) {
                            setState(() {
                              _statusFilter =
                                  selected ? 'inactive' : _statusFilter;
                              _applyFilters();
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // User list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: primary))
                : _filteredUsers.isEmpty
                    ? Center(
                        child: TextWidget(
                          text: 'No users found',
                          fontSize: 16,
                          color: textLight,
                        ),
                      )
                    : ListView.builder(
                        itemCount: _filteredUsers.length,
                        itemBuilder: (context, index) {
                          final user = _filteredUsers[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(16),
                              leading: CircleAvatar(
                                backgroundColor: primary.withOpacity(0.1),
                                child: TextWidget(
                                  text: user.name.isNotEmpty
                                      ? user.name.substring(0, 1).toUpperCase()
                                      : 'U',
                                  fontSize: 18,
                                  color: primary,
                                  fontFamily: 'Bold',
                                ),
                              ),
                              title: TextWidget(
                                text: user.name.isNotEmpty
                                    ? user.name
                                    : 'Unknown',
                                fontSize: 16,
                                color: textPrimary,
                                fontFamily: 'Bold',
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  TextWidget(
                                    text: user.email.isNotEmpty
                                        ? user.email
                                        : 'No email',
                                    fontSize: 14,
                                    color: textLight,
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: user.accountStatus == 'active'
                                              ? healthGreen.withOpacity(0.1)
                                              : Colors.grey.withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: TextWidget(
                                          text: user.accountStatus.isNotEmpty
                                              ? user.accountStatus.capitalize()
                                              : 'Unknown',
                                          fontSize: 12,
                                          color: user.accountStatus == 'active'
                                              ? healthGreen
                                              : Colors.grey,
                                          fontFamily: 'Medium',
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      TextWidget(
                                        text: '${user.age} years',
                                        fontSize: 12,
                                        color: textLight,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.more_vert),
                                onPressed: () => _showUserDetails(user),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class UserDetailsSheet extends StatefulWidget {
  final UserProfile user;
  final Function(UserProfile) onUserUpdated;
  final Function(UserProfile) onUserStatusChanged;

  const UserDetailsSheet({
    super.key,
    required this.user,
    required this.onUserUpdated,
    required this.onUserStatusChanged,
  });

  @override
  State<UserDetailsSheet> createState() => _UserDetailsSheetState();
}

class _UserDetailsSheetState extends State<UserDetailsSheet> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _ageController;
  late String _gender;
  late String _accountStatus;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.name);
    _emailController = TextEditingController(text: widget.user.email);
    _ageController = TextEditingController(text: widget.user.age.toString());
    _gender = widget.user.gender;
    _accountStatus = widget.user.accountStatus;
  }

  @override
  void dispose() {
    // Only dispose the controllers used in this widget
    _nameController.dispose();
    _emailController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  void _editUser() {
    // Create new controllers for the dialog
    final nameController = TextEditingController(text: widget.user.name);
    final emailController = TextEditingController(text: widget.user.email);
    final ageController =
        TextEditingController(text: widget.user.age.toString());
    String gender = widget.user.gender;

    // Show edit dialog using root navigator to avoid context issues
    showDialog(
      context: context,
      useRootNavigator: true, // Use root navigator to avoid context issues
      builder: (BuildContext context) {
        return AlertDialog(
          title: TextWidget(
            text: 'Edit User',
            fontSize: 20,
            color: textPrimary,
            fontFamily: 'Bold',
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Name',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: ageController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Age',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                // Dispose controllers and close dialog
                nameController.dispose();
                emailController.dispose();
                ageController.dispose();
                Navigator.of(context).pop();
              },
              child: TextWidget(
                text: 'Cancel',
                fontSize: 16,
                color: textLight,
              ),
            ),
            ElevatedButton(
              onPressed: () {
                // Validate inputs
                if (nameController.text.isEmpty ||
                    emailController.text.isEmpty ||
                    ageController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: TextWidget(
                        text: 'Please fill all fields',
                        fontSize: 14,
                        color: textOnPrimary,
                      ),
                      backgroundColor: healthRed,
                    ),
                  );
                  return;
                }

                // Update user
                final updatedUser = UserProfile(
                  userId: widget.user.userId,
                  name: nameController.text,
                  email: emailController.text,
                  age: int.parse(ageController.text),
                  gender: gender,
                  registrationDate: widget.user.registrationDate,
                  lastLogin: widget.user.lastLogin,
                  accountStatus: widget.user.accountStatus,
                );

                // Dispose controllers
                nameController.dispose();
                emailController.dispose();
                ageController.dispose();

                // Close dialog
                Navigator.of(context).pop();

                // Close the bottom sheet
                Navigator.of(context, rootNavigator: true).pop();

                // Notify parent
                widget.onUserUpdated(updatedUser);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: TextWidget(
                      text: 'User updated successfully',
                      fontSize: 14,
                      color: textOnPrimary,
                    ),
                    backgroundColor: healthGreen,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: TextWidget(
                text: 'Save',
                fontSize: 16,
                color: Colors.white,
              ),
            ),
          ],
        );
      },
    );
  }

  void _toggleUserStatus() {
    // Toggle status
    final newStatus = _accountStatus == 'active' ? 'inactive' : 'active';
    final updatedUser = UserProfile(
      userId: widget.user.userId,
      name: widget.user.name,
      email: widget.user.email,
      age: widget.user.age,
      gender: widget.user.gender,
      registrationDate: widget.user.registrationDate,
      lastLogin: widget.user.lastLogin,
      accountStatus: newStatus,
    );

    widget.onUserStatusChanged(updatedUser);

    // Close the bottom sheet using root navigator
    Navigator.of(context, rootNavigator: true).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: TextWidget(
          text: 'User ${newStatus}d successfully',
          fontSize: 14,
          color: textOnPrimary,
        ),
        backgroundColor: newStatus == 'active' ? healthGreen : healthRed,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: CircleAvatar(
                radius: 30,
                backgroundColor: primary.withOpacity(0.1),
                child: TextWidget(
                  text: widget.user.name.substring(0, 1).toUpperCase(),
                  fontSize: 24,
                  color: primary,
                  fontFamily: 'Bold',
                ),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: TextWidget(
                text: widget.user.name,
                fontSize: 20,
                color: textPrimary,
                fontFamily: 'Bold',
              ),
            ),
            const SizedBox(height: 4),
            Center(
              child: TextWidget(
                text: widget.user.email,
                fontSize: 14,
                color: textLight,
              ),
            ),
            const SizedBox(height: 24),
            _buildDetailRow('User ID', widget.user.userId),
            _buildDetailRow('Age', '${widget.user.age} years'),
            _buildDetailRow('Gender', widget.user.gender),
            _buildDetailRow('Registration Date',
                '${widget.user.registrationDate.day}/${widget.user.registrationDate.month}/${widget.user.registrationDate.year}'),
            _buildDetailRow('Last Login',
                '${widget.user.lastLogin.day}/${widget.user.lastLogin.month}/${widget.user.lastLogin.year}'),
            _buildDetailRow('Status', widget.user.accountStatus.capitalize()),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ButtonWidget(
                  label: _accountStatus == 'active' ? 'Disable' : 'Enable',
                  onPressed: _toggleUserStatus,
                  color: _accountStatus == 'active' ? healthRed : healthGreen,
                  width: 300,
                  height: 40,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: TextWidget(
              text: label,
              fontSize: 14,
              color: textLight,
            ),
          ),
          TextWidget(
            text: ':',
            fontSize: 14,
            color: textLight,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextWidget(
              text: value,
              fontSize: 14,
              color: textPrimary,
              fontFamily: 'Medium',
            ),
          ),
        ],
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }
}
