import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/admin_service.dart';
import '../../models/admin_model.dart';
import '../../models/user_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../login_page.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final AdminService _adminService = AdminService();
  Map<String, dynamic> _analytics = {};
  AdminModel? _currentAdmin;
  int _selectedIndex = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    print('[ADMIN_DASHBOARD] _loadData started.');
    setState(() => _isLoading = true);
    try {
      final analytics = await _adminService.getAnalytics();
      print('[ADMIN_DASHBOARD] Analytics data received: $analytics'); // More detailed log

      final admin = await _adminService.getCurrentAdmin();
      print('[ADMIN_DASHBOARD] Current admin received: ${admin?.name}');
      
      if (mounted) {
        setState(() {
          _analytics = analytics;
          _currentAdmin = admin;
          _isLoading = false;
        });
        print('[ADMIN_DASHBOARD] State updated with new data.');
      }
    } catch (e) {
      print('[ADMIN_DASHBOARD] Error loading admin data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _signOut() async {
    try {
      await FirebaseAuth.instance.signOut();
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error signing out')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A2468),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF212E83),
              const Color(0xFF1A2468),
            ],
          ),
        ),
        child: SafeArea(
          bottom: false,  // Don't add padding at the bottom
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: Colors.white))
              : Column(
                  children: [
                    // Admin Header
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(
                              Icons.admin_panel_settings,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Admin Dashboard',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                if (_currentAdmin != null)
                                  Text(
                                    _currentAdmin!.name,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.blue.shade100,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: _signOut,
                            icon: const Icon(Icons.logout_rounded),
                            color: Colors.red.shade300,
                            iconSize: 24,
                          ),
                        ],
                      ),
                    ),
                    // Main Content
                    Expanded(
                      child: IndexedStack(
                        index: _selectedIndex,
                        children: [
                          SingleChildScrollView(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: _buildOverview(),
                          ),
                          _buildUsersList(),
                          _buildTrainersList(),
                          _buildPaymentsPage(),
                          _buildAnnouncementsPage(),
                          _buildSettingsPage(),
                        ],
                      ),
                    ),
                    // Bottom Navigation
                    Theme(
                      data: Theme.of(context).copyWith(
                        navigationBarTheme: NavigationBarThemeData(
                          labelTextStyle: MaterialStateProperty.all(
                            const TextStyle(fontSize: 12, height: 1.0),
                          ),
                        ),
                      ),
                      child: NavigationBar(
                        height: 60,
                        backgroundColor: Colors.white.withOpacity(0.1),
                        selectedIndex: _selectedIndex,
                        onDestinationSelected: (index) => setState(() => _selectedIndex = index),
                        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
                        destinations: const [
                          NavigationDestination(
                            icon: Icon(Icons.dashboard_outlined, size: 24),
                            selectedIcon: Icon(Icons.dashboard, size: 24),
                            label: 'Overview',
                          ),
                          NavigationDestination(
                            icon: Icon(Icons.people_outline, size: 24),
                            selectedIcon: Icon(Icons.people, size: 24),
                            label: 'Users',
                          ),
                          NavigationDestination(
                            icon: Icon(Icons.fitness_center_outlined, size: 24),
                            selectedIcon: Icon(Icons.fitness_center, size: 24),
                            label: 'Trainers',
                          ),
                          NavigationDestination(
                            icon: Icon(Icons.payment_outlined, size: 24),
                            selectedIcon: Icon(Icons.payment, size: 24),
                            label: 'Payments',
                          ),
                          NavigationDestination(
                            icon: Icon(Icons.campaign_outlined, size: 24),
                            selectedIcon: Icon(Icons.campaign, size: 24),
                            label: 'Announce',
                          ),
                          NavigationDestination(
                            icon: Icon(Icons.settings_outlined, size: 24),
                            selectedIcon: Icon(Icons.settings, size: 24),
                            label: 'Settings',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color iconColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.blue.shade100,
                ),
              ),
              Icon(icon, color: iconColor, size: 20),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverview() {
    print('[ADMIN_DASHBOARD] Building overview with analytics: $_analytics'); // More detailed log
    final totalTrainers = _analytics['totalTrainers']?.toString() ?? '0';
    print('[ADMIN_DASHBOARD] Total trainers to display: $totalTrainers');

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Total Users',
                _analytics['totalUsers']?.toString() ?? '0',
                Icons.people_outline,
                Colors.blue.shade300,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Total Trainers',
                totalTrainers,
                Icons.fitness_center,
                Colors.green.shade300,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Active Bookings',
                _analytics['activeBookings']?.toString() ?? '0',
                Icons.calendar_today_outlined,
                Colors.orange.shade300,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Revenue',
                '\$${_analytics["revenue"]?.toString() ?? "0"}',
                Icons.attach_money_outlined,
                Colors.purple.shade300,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildUsersList() {
    return StreamBuilder<List<UserModel>>(
      stream: _adminService.getAllUsers(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Colors.white));
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error: ${snapshot.error}',
              style: const TextStyle(color: Colors.white),
            ),
          );
        }

        final users = snapshot.data ?? [];

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user = users[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                leading: CircleAvatar(
                  backgroundColor: Colors.blue.shade300,
                  child: Text(
                    user.name[0].toUpperCase(),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                title: Text(
                  user.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  user.email,
                  style: TextStyle(color: Colors.blue.shade100),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Switch(
                      value: user.isActive,
                      onChanged: (value) => _adminService.updateUserStatus(user.id, value),
                      activeColor: Colors.green.shade300,
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () => _showDeleteConfirmationDialog(
                        context: context,
                        itemName: user.name,
                        onConfirm: () => _adminService.deleteUser(user.id),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTrainersList() {
    return StreamBuilder<List<UserModel>>(
      stream: _adminService.getAllTrainers(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Colors.white));
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error: ${snapshot.error}',
              style: const TextStyle(color: Colors.white),
            ),
          );
        }

        final trainers = snapshot.data ?? [];
        print(
            '[ADMIN_DASHBOARD] Building trainer list with ${trainers.length} trainers.'); // Debug log

        return Column(
          children: [
            // Trainers List
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: trainers.length,
                itemBuilder: (context, index) {
                  final trainer = trainers[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      leading: CircleAvatar(
                        backgroundColor: Colors.green.shade300,
                        child: Text(
                          trainer.name[0].toUpperCase(),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      title: Text(
                        trainer.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        trainer.email,
                        style: TextStyle(color: Colors.blue.shade100),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.verified_user),
                            onPressed: () => _adminService.updateTrainerVerification(
                              trainer.id,
                              !trainer.isVerified,
                            ),
                            color: trainer.isVerified
                                ? Colors.green.shade300
                                : Colors.grey,
                          ),
                          Switch(
                            value: trainer.isActive,
                            onChanged: (value) =>
                                _adminService.updateUserStatus(trainer.id, value),
                            activeColor: Colors.green.shade300,
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                            onPressed: () => _showDeleteConfirmationDialog(
                              context: context,
                              itemName: trainer.name,
                              onConfirm: () => _adminService.deleteTrainer(trainer.id),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPaymentsPage() {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const TabBar(
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              indicatorColor: Colors.white,
              tabs: [
                Tab(text: 'Pending Payments'),
                Tab(text: 'Payment History'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildPendingPayments(),
                _buildPaymentHistory(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingPayments() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _adminService.getPendingEscrowPayments(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Colors.white));
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error: ${snapshot.error}',
              style: const TextStyle(color: Colors.white),
            ),
          );
        }

        final payments = snapshot.data ?? [];

        if (payments.isEmpty) {
          return const Center(
            child: Text(
              'No pending payments',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: payments.length,
          itemBuilder: (context, index) {
            final payment = payments[index];
            final amount = payment['amount']?.toDouble() ?? 0.0;
            final userName = payment['userName'] ?? 'Unknown User';
            final trainerName = payment['trainerName'] ?? 'Unknown Trainer';
            final bookingDateTime = payment['formattedDateTime'] ?? 'Unknown Date';
            final createdAt = payment['createdAt'] as Timestamp?;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                title: Text(
                  'RM ${amount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    Text(
                      'User: $userName',
                      style: TextStyle(color: Colors.blue.shade100),
                    ),
                    Text(
                      'Trainer: $trainerName',
                      style: TextStyle(color: Colors.blue.shade100),
                    ),
                    Text(
                      'Session: $bookingDateTime',
                      style: TextStyle(color: Colors.blue.shade100),
                    ),
                    if (createdAt != null)
                      Text(
                        'Held since: ${_formatDate(createdAt.toDate())}',
                        style: TextStyle(color: Colors.blue.shade100, fontSize: 12),
                      ),
                  ],
                ),
                trailing: ElevatedButton(
                  onPressed: () => _showReleasePaymentDialog(payment),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Release'),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPaymentHistory() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _adminService.getAllEscrowPayments(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Colors.white));
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error: ${snapshot.error}',
              style: const TextStyle(color: Colors.white),
            ),
          );
        }

        final payments = snapshot.data ?? [];

        if (payments.isEmpty) {
          return const Center(
            child: Text(
              'No payment history',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: payments.length,
          itemBuilder: (context, index) {
            final payment = payments[index];
            final amount = payment['amount']?.toDouble() ?? 0.0;
            final userName = payment['userName'] ?? 'Unknown User';
            final trainerName = payment['trainerName'] ?? 'Unknown Trainer';
            final status = payment['adminStatus'] ?? 'unknown';
            final createdAt = payment['createdAt'] as Timestamp?;
            final releasedAt = payment['releasedAt'] as Timestamp?;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                title: Row(
                  children: [
                    Text(
                      'RM ${amount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: status == 'released' 
                            ? Colors.green.withOpacity(0.2)
                            : Colors.orange.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        status.toUpperCase(),
                        style: TextStyle(
                          color: status == 'released' ? Colors.green : Colors.orange,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    Text(
                      'User: $userName',
                      style: TextStyle(color: Colors.blue.shade100),
                    ),
                    Text(
                      'Trainer: $trainerName',
                      style: TextStyle(color: Colors.blue.shade100),
                    ),
                    if (createdAt != null)
                      Text(
                        'Created: ${_formatDate(createdAt.toDate())}',
                        style: TextStyle(color: Colors.blue.shade100, fontSize: 12),
                      ),
                    if (releasedAt != null)
                      Text(
                        'Released: ${_formatDate(releasedAt.toDate())}',
                        style: TextStyle(color: Colors.green.shade100, fontSize: 12),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showReleasePaymentDialog(Map<String, dynamic> payment) {
    final amount = payment['amount']?.toDouble() ?? 0.0;
    final userName = payment['userName'] ?? 'Unknown User';
    final trainerName = payment['trainerName'] ?? 'Unknown Trainer';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF212E83),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Release Payment',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to release RM ${amount.toStringAsFixed(2)} to $trainerName for the session with $userName?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade700,
              foregroundColor: Colors.white,
            ),
            child: const Text('Release Payment'),
            onPressed: () async {
              try {
                await _adminService.releasePaymentToTrainer(payment['id']);
                if (!mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Payment released to $trainerName'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                if (!mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error releasing payment: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildSettingsPage() {
    final nameController = TextEditingController(
      text: _currentAdmin?.name ?? '',
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Profile Settings',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade100,
                  ),
                ),
                const SizedBox(height: 20),
                // Name Change Field
                TextField(
                  controller: nameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Admin Name',
                    labelStyle: TextStyle(color: Colors.blue.shade100),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.blue.shade200),
                    ),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.1),
                  ),
                ),
                const SizedBox(height: 16),
                // Save Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      try {
                        await _adminService.updateAdminName(nameController.text.trim());
                        if (!mounted) return;
                        
                        // Refresh admin data
                        final admin = await _adminService.getCurrentAdmin();
                        setState(() {
                          _currentAdmin = admin;
                        });

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Name updated successfully'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      } catch (e) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error updating name: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Save Changes',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // System Settings Section
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'System Settings',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade100,
                  ),
                ),
                const SizedBox(height: 20),
                // Add more system settings here
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmationDialog({
    required BuildContext context,
    required String itemName,
    required VoidCallback onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF212E83),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Confirm Deletion',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Are you sure you want to delete "$itemName"? This action cannot be undone.',
            style: const TextStyle(color: Colors.white70),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              style: TextButton.styleFrom(
                backgroundColor: Colors.red.withOpacity(0.8),
              ),
              child: const Text('Delete', style: TextStyle(color: Colors.white)),
              onPressed: () {
                onConfirm();
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('"$itemName" has been deleted.'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildAnnouncementsPage() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.campaign, color: Colors.white, size: 100),
          const SizedBox(height: 20),
          const Text(
            'Send announcements to users and trainers.',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => _showSendAnnouncementDialog(),
            icon: const Icon(Icons.send),
            label: const Text('New Announcement'),
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: Colors.blue,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showSendAnnouncementDialog() async {
    final titleController = TextEditingController();
    final messageController = TextEditingController();
    String targetAudience = 'everyone'; // Default value

    return showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Send New Announcement'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(labelText: 'Title'),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: messageController,
                      decoration: const InputDecoration(labelText: 'Message'),
                      maxLines: 4,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: targetAudience,
                      decoration: const InputDecoration(labelText: 'Target Audience'),
                      items: const [
                        DropdownMenuItem(
                          value: 'everyone',
                          child: Text('Everyone'),
                        ),
                        DropdownMenuItem(
                          value: 'users_only',
                          child: Text('Users Only'),
                        ),
                        DropdownMenuItem(
                          value: 'trainers_only',
                          child: Text('Trainers Only'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() {
                            targetAudience = value;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (titleController.text.isNotEmpty && messageController.text.isNotEmpty) {
                      try {
                        await _adminService.sendAnnouncement(
                          title: titleController.text,
                          message: messageController.text,
                          audience: targetAudience,
                        );
                        if (mounted) {
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Announcement sent successfully!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error sending announcement: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Title and message cannot be empty.'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                    }
                  },
                  child: const Text('Send'),
                ),
              ],
            );
          },
        );
      },
    );
  }
} 