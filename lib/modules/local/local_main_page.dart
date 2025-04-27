import 'package:flutter/material.dart';
import '../../shared/models/user_model.dart';
import 'local_submission_page.dart';
import 'submission_history_page.dart';

class LocalMainPage extends StatefulWidget {
  final UserModel user;

  const LocalMainPage({
    Key? key,
    required this.user,
  }) : super(key: key);

  @override
  State<LocalMainPage> createState() => _LocalMainPageState();
}

class _LocalMainPageState extends State<LocalMainPage> {
  int _selectedIndex = 0;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      LocalSubmissionPage(user: widget.user),
      SubmissionHistoryPage(user: widget.user),
      _buildRedemptionPage(),
    ];
  }

  Widget _buildRedemptionPage() {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: const Color(0xFF2C2C2C),
        elevation: 0,
        title: const Text(
          'Redemption',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Container(
                  height: 120,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.blue[700]!,
                        Colors.blue[900]!,
                      ],
                    ),
                  ),
                  child: Center(
                    child: Image.network(
                      'https://picsum.photos/200', // Replace with actual S-Pay logo
                      height: 60,
                      color: Colors.white,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.payment,
                          size: 60,
                          color: Colors.white,
                        );
                      },
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'S-Pay Voucher',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Redeem your voucher for S-Pay credit',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, size: 20, color: Colors.grey[600]),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'You have 2 vouchers available for redemption',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            // TODO: Implement redemption logic
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Redemption feature coming soon!'),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue[700],
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Redeem Now',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        backgroundColor: Colors.white,
        elevation: 0,
        shadowColor: Colors.transparent,
        indicatorColor: const Color(0xFF2C2C2C).withOpacity(0.1),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.add_location_outlined),
            selectedIcon: Icon(Icons.add_location, color: Color(0xFF2C2C2C)),
            label: 'Submit',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history, color: Color(0xFF2C2C2C)),
            label: 'History',
          ),
          NavigationDestination(
            icon: Icon(Icons.redeem_outlined),
            selectedIcon: Icon(Icons.redeem, color: Color(0xFF2C2C2C)),
            label: 'Redemption',
          ),
        ],
      ),
    );
  }
} 