import 'package:flutter/material.dart';
import 'package:survey_app/models/user_profile.dart';
import 'package:survey_app/utils/colors.dart';
import 'package:survey_app/widgets/button_widget.dart';
import 'package:survey_app/widgets/text_widget.dart';

class AccountManagementScreen extends StatefulWidget {
  const AccountManagementScreen({super.key});

  @override
  State<AccountManagementScreen> createState() =>
      _AccountManagementScreenState();
}

class _AccountManagementScreenState extends State<AccountManagementScreen> {
  // Sample user data
  final List<UserProfile> _users = [
    UserProfile(
      userId: 'user_001',
      name: 'John Doe',
      email: 'john.doe@example.com',
      age: 45,
      gender: 'Male',
      registrationDate: DateTime(2023, 1, 15),
      lastLogin: DateTime(2023, 6, 10),
      accountStatus: 'active',
    ),
    UserProfile(
      userId: 'user_002',
      name: 'Jane Smith',
      email: 'jane.smith@example.com',
      age: 38,
      gender: 'Female',
      registrationDate: DateTime(2023, 2, 20),
      lastLogin: DateTime(2023, 6, 12),
      accountStatus: 'active',
    ),
    UserProfile(
      userId: 'user_003',
      name: 'Robert Johnson',
      email: 'robert.j@example.com',
      age: 52,
      gender: 'Male',
      registrationDate: DateTime(2023, 3, 5),
      lastLogin: DateTime(2023, 6, 1),
      accountStatus: 'inactive',
    ),
    UserProfile(
      userId: 'user_004',
      name: 'Emily Davis',
      email: 'emily.davis@example.com',
      age: 29,
      gender: 'Female',
      registrationDate: DateTime(2023, 4, 18),
      lastLogin: DateTime(2023, 6, 11),
      accountStatus: 'active',
    ),
    UserProfile(
      userId: 'user_005',
      name: 'Michael Brown',
      email: 'michael.b@example.com',
      age: 35,
      gender: 'Male',
      registrationDate: DateTime(2023, 5, 30),
      lastLogin: DateTime(2023, 6, 5),
      accountStatus: 'active',
    ),
  ];

  String _searchQuery = '';
  String _statusFilter = 'all';

  List<UserProfile> get _filteredUsers {
    List<UserProfile> filtered = _users;

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((user) {
        return user.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            user.email.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }

    // Apply status filter
    if (_statusFilter != 'all') {
      filtered = filtered
          .where((user) => user.accountStatus == _statusFilter)
          .toList();
    }

    return filtered;
  }

  void _showUserDetails(UserProfile user) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return UserDetailsSheet(user: user);
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
            child: ListView.builder(
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
                        text: user.name.substring(0, 1).toUpperCase(),
                        fontSize: 18,
                        color: primary,
                        fontFamily: 'Bold',
                      ),
                    ),
                    title: TextWidget(
                      text: user.name,
                      fontSize: 16,
                      color: textPrimary,
                      fontFamily: 'Bold',
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextWidget(
                          text: user.email,
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
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: TextWidget(
                                text: user.accountStatus.capitalize(),
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

class UserDetailsSheet extends StatelessWidget {
  final UserProfile user;

  const UserDetailsSheet({super.key, required this.user});

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
                  text: user.name.substring(0, 1).toUpperCase(),
                  fontSize: 24,
                  color: primary,
                  fontFamily: 'Bold',
                ),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: TextWidget(
                text: user.name,
                fontSize: 20,
                color: textPrimary,
                fontFamily: 'Bold',
              ),
            ),
            const SizedBox(height: 4),
            Center(
              child: TextWidget(
                text: user.email,
                fontSize: 14,
                color: textLight,
              ),
            ),
            const SizedBox(height: 24),
            _buildDetailRow('User ID', user.userId),
            _buildDetailRow('Age', '${user.age} years'),
            _buildDetailRow('Gender', user.gender),
            _buildDetailRow('Registration Date',
                '${user.registrationDate.day}/${user.registrationDate.month}/${user.registrationDate.year}'),
            _buildDetailRow('Last Login',
                '${user.lastLogin.day}/${user.lastLogin.month}/${user.lastLogin.year}'),
            _buildDetailRow('Status', user.accountStatus.capitalize()),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ButtonWidget(
                  label: 'Edit',
                  onPressed: () {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: TextWidget(
                          text:
                              'Edit user functionality would be implemented here',
                          fontSize: 14,
                          color: textOnPrimary,
                        ),
                        backgroundColor: primary,
                      ),
                    );
                  },
                  width: 120,
                  height: 40,
                ),
                ButtonWidget(
                  label: user.accountStatus == 'active' ? 'Disable' : 'Enable',
                  onPressed: () {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: TextWidget(
                          text:
                              '${user.accountStatus == 'active' ? 'Disable' : 'Enable'} user functionality would be implemented here',
                          fontSize: 14,
                          color: textOnPrimary,
                        ),
                        backgroundColor: primary,
                      ),
                    );
                  },
                  color:
                      user.accountStatus == 'active' ? healthRed : healthGreen,
                  width: 120,
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
