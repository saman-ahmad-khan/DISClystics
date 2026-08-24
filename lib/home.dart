import 'package:DISClystics/previous_results_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'profile_setup_screen.dart';
import 'QuestionScreen.dart';
import 'package:easy_localization/easy_localization.dart';

enum MenuAction { editProfile,changelang, logout }
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void _onMenuSelect(MenuAction action) async {
    switch (action) {
      case MenuAction.editProfile:
        _navigateToProfile();
        break;
      case MenuAction.changelang:
        _navigateTolanguage(context);
        break;
      case MenuAction.logout:
        await _logout();
        break;
    }
  }

  Future<void> _logout() async {
    await _auth.signOut();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  void _navigateToProfile() {
    final user = _auth.currentUser;
    if (user != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProfileSetupScreen(
            userId: user.uid,
            isEditing: true,
          ),
        ),
      );
    }
  }

  void _navigateTolanguage(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('select_language'.tr()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text('english'.tr()),
              onTap: () {
                context.setLocale(const Locale('en'));
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: Text('urdu'.tr()),
              onTap: () {
                context.setLocale(const Locale('ur'));
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildProfileAvatar(String? imageUrl) {
    return CircleAvatar(
      radius: 24,
      backgroundColor: Colors.white.withOpacity(0.2),
      child: ClipOval(
        child: SizedBox(
          width: 48,
          height: 48,
          child: imageUrl != null && imageUrl.isNotEmpty
              ? CachedNetworkImage(
            imageUrl: imageUrl,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              color: Colors.white24,
              child: const CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            ),
            errorWidget: (context, url, error) {
              print('Error_loading_profile_image'.tr() + ': $error');
              return const Icon(Icons.error, color: Colors.white);
            },
          )
              : const Icon(Icons.person, color: Colors.white, size: 28),
        ),
      ),
    );
  }

  Widget _buildProfileMenuButton(String? imageUrl) {
    return PopupMenuButton<MenuAction>(
      onSelected: _onMenuSelect,
      itemBuilder: (context) => [
         PopupMenuItem<MenuAction>(
          value: MenuAction.editProfile,
          child: ListTile(
            leading: Icon(Icons.edit, color: Color(0xFF712F7E)),
            title: Text('edit_profile'.tr()),
          ),
        ),
        PopupMenuItem<MenuAction>(
          value: MenuAction.changelang,
          child: ListTile(
            leading: Icon(Icons.language, color: Color(0xFF712F7E)),
            title: Text('language'.tr()),
          ),
        ),

         PopupMenuItem<MenuAction>(
          value: MenuAction.logout,
          child: ListTile(
            leading: Icon(Icons.logout, color: Color(0xFF712F7E)),
            title: Text('logout'.tr()),
          ),
        ),
      ],
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: _buildProfileAvatar(imageUrl),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      offset: const Offset(0, 50),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    if (user == null) {
      return Scaffold(
        body: Center(child: Text('User_not_authenticated'.tr())),
      );
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: _firestore.collection('users').doc(user.uid).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return Scaffold(body: Center(child: Text('User_data_not_found'.tr())));
        }

        final userData = snapshot.data!.data() as Map<String, dynamic>;
        final profileImageUrl = userData['profilePicture'] as String?;
        final age = userData['age'];
        final occupation = userData['occupation'];
        final name = userData['name'] ?? 'User';

        return Scaffold(
          appBar: AppBar(
            backgroundColor: const Color(0xFF712F7E),
            elevation: 0,
            title:  Text(
              'home'.tr(),
              style: TextStyle(color: Colors.white),
            ),
            leading: _buildProfileMenuButton(profileImageUrl),
          ),
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF712F7E), Color(0xFFF15B28)],
              ),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        constraints: const BoxConstraints(maxWidth: 600),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            const SizedBox(height: 30),
                            _buildAnimatedTitle(),
                            const SizedBox(height: 10),
                            _buildSubtitle(),
                            const SizedBox(height: 40),
                            _buildMainCard(context, constraints, name, age, occupation),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildAnimatedTitle() {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 500),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: Text(
        'DISC_Personality_Test'.tr(),
        style: TextStyle(
          color: Colors.white,
          fontSize: 32,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildSubtitle() {
    return  Text(
      'discover_behavior'.tr(),
      style: TextStyle(
        color: Colors.white70,
        fontSize: 18,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildMainCard(BuildContext context, BoxConstraints constraints,
      String name, dynamic age, String? occupation) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
      elevation: 10,
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${'welcome'.tr()} $name',
              style: const TextStyle(
                color: Color(0xFF712F7E),
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),

            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                if (age != null) _buildInfoChip(Icons.cake, 'Age: $age'),
                if (occupation != null) _buildInfoChip(Icons.work, occupation),
                _buildInfoChip(Icons.email, _auth.currentUser?.email ?? ''),
              ],
            ),
            const SizedBox(height: 40),
            _buildStartButton(context),
            const SizedBox(height: 25),
            _buildPreviousResultsLink(),
          ],
        ),
      ),
    );
  }

  Widget _buildStartButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFF15B28).withOpacity(0.4),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const QuestionScreen(),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF15B28),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              elevation: 0,
            ),
            child: Text(
              'start_assessment'.tr(),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPreviousResultsLink() {
    final userId = _auth.currentUser?.uid ?? '';
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PreviousResultsScreen(userId: userId),
          ),
        );
      },
      hoverColor: Colors.transparent,
      splashColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: const Color(0xFF712F7E).withOpacity(0.3),
              width: 1,
            ),
          ),
        ),
        child:  Text(
          'view_previous_results'.tr(),
          style: TextStyle(
            color: Color(0xFF712F7E),
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF712F7E).withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: const Color(0xFF712F7E)),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(
              color: Color(0xFF712F7E),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}