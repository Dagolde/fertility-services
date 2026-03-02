import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../core/models/user_model.dart';

class MainNavigation extends StatefulWidget {
  final Widget child;

  const MainNavigation({
    super.key,
    required this.child,
  });

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  final List<NavigationItem> _navigationItems = [
    NavigationItem(
      icon: Icons.home_outlined,
      activeIcon: Icons.home,
      label: 'Home',
      route: '/',
    ),
    NavigationItem(
      icon: Icons.local_hospital_outlined,
      activeIcon: Icons.local_hospital,
      label: 'Hospitals',
      route: '/hospitals',
    ),
    NavigationItem(
      icon: Icons.account_balance_wallet_outlined,
      activeIcon: Icons.account_balance_wallet,
      label: 'Wallet',
      route: '/wallet',
    ),
    NavigationItem(
      icon: Icons.calendar_today_outlined,
      activeIcon: Icons.calendar_today,
      label: 'Appointments',
      route: '/appointments',
    ),
    NavigationItem(
      icon: Icons.message_outlined,
      activeIcon: Icons.message,
      label: 'Messages',
      route: '/messages',
    ),
    NavigationItem(
      icon: Icons.person_outline,
      activeIcon: Icons.person,
      label: 'Profile',
      route: '/profile',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.currentUser;
        
        return Scaffold(
          body: widget.child,
          bottomNavigationBar: _buildBottomNavigationBar(context, user),
          floatingActionButton: _buildFloatingActionButton(context, user),
          floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        );
      },
    );
  }

  Widget _buildBottomNavigationBar(BuildContext context, User? user) {
    final theme = Theme.of(context);
    
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _getCurrentIndex(context),
        onTap: (index) => _onItemTapped(context, index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: theme.colorScheme.surface,
        selectedItemColor: theme.primaryColor,
        unselectedItemColor: theme.textTheme.bodySmall?.color,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        elevation: 0,
        items: _navigationItems.map((item) {
          final isSelected = _navigationItems[_getCurrentIndex(context)] == item;
          return BottomNavigationBarItem(
            icon: _buildNavIcon(item.icon, isSelected, false),
            activeIcon: _buildNavIcon(item.activeIcon, isSelected, true),
            label: item.label,
          );
        }).toList(),
      ),
    );
  }

  Widget _buildNavIcon(IconData icon, bool isSelected, bool isActive) {
    return Container(
      padding: const EdgeInsets.all(4),
      child: Icon(
        icon,
        size: 24,
      ),
    );
  }

  Widget? _buildFloatingActionButton(BuildContext context, User? user) {
    final currentRoute = GoRouterState.of(context).uri.toString();
    
    // Show FAB only on specific screens
    if (currentRoute == '/appointments') {
      return FloatingActionButton(
        onPressed: () => context.push('/appointments/book'),
        tooltip: 'Book Appointment',
        child: const Icon(Icons.add),
      );
    } else if (currentRoute == '/messages') {
      return FloatingActionButton(
        onPressed: () => _showNewMessageDialog(context),
        tooltip: 'New Message',
        child: const Icon(Icons.edit),
      );
    }
    
    return null;
  }

  int _getCurrentIndex(BuildContext context) {
    final currentRoute = GoRouterState.of(context).uri.toString();
    
    for (int i = 0; i < _navigationItems.length; i++) {
      if (currentRoute.startsWith(_navigationItems[i].route)) {
        return i;
      }
    }
    
    return 0;
  }

  void _onItemTapped(BuildContext context, int index) {
    final currentRoute = GoRouterState.of(context).uri.toString();
    final targetRoute = _navigationItems[index].route;
    
    // Always navigate to the target route, even if we're on the same tab
    // This ensures users can return to main screens from sub-screens
    context.go(targetRoute);
  }

  void _showNewMessageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const NewMessageDialog(),
    );
  }
}

class NavigationItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String route;

  NavigationItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.route,
  });
}

class NewMessageDialog extends StatefulWidget {
  const NewMessageDialog({super.key});

  @override
  State<NewMessageDialog> createState() => _NewMessageDialogState();
}

class _NewMessageDialogState extends State<NewMessageDialog> {
  final TextEditingController _searchController = TextEditingController();
  List<User> _searchResults = [];
  bool _isSearching = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('New Message'),
      content: SizedBox(
        width: 300,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Search users...',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: _onSearchChanged,
            ),
            const SizedBox(height: 16),
            if (_isSearching)
              const CircularProgressIndicator()
            else if (_searchResults.isNotEmpty)
              SizedBox(
                height: 200,
                child: ListView.builder(
                  itemCount: _searchResults.length,
                  itemBuilder: (context, index) {
                    final user = _searchResults[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: user.profilePicture != null
                            ? NetworkImage(user.profilePicture!)
                            : null,
                        child: user.profilePicture == null
                            ? Text(user.firstName[0].toUpperCase())
                            : null,
                      ),
                      title: Text(user.fullName),
                      subtitle: Text(user.userTypeLabel),
                      onTap: () => _startConversation(user),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ],
    );
  }

  void _onSearchChanged(String query) {
    if (query.isEmpty) {
      setState(() {
        _searchResults.clear();
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    // TODO: Implement user search
    // For now, just simulate search
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _isSearching = false;
          _searchResults = []; // Add actual search results here
        });
      }
    });
  }

  void _startConversation(User user) {
    Navigator.of(context).pop();
    context.push('/messages/chat/${user.id}?userName=${user.fullName}');
  }
}

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool centerTitle;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double elevation;
  final PreferredSizeWidget? bottom;

  const CustomAppBar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.centerTitle = true,
    this.backgroundColor,
    this.foregroundColor,
    this.elevation = 0,
    this.bottom,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return AppBar(
      title: Text(title),
      actions: actions,
      leading: leading,
      centerTitle: centerTitle,
      backgroundColor: backgroundColor ?? theme.colorScheme.surface,
      foregroundColor: foregroundColor ?? theme.textTheme.titleLarge?.color,
      elevation: elevation,
      bottom: bottom,
      systemOverlayStyle: theme.brightness == Brightness.light
          ? SystemUiOverlayStyle.dark
          : SystemUiOverlayStyle.light,
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(
    kToolbarHeight + (bottom?.preferredSize.height ?? 0),
  );
}

class CustomSliverAppBar extends StatelessWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool centerTitle;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double expandedHeight;
  final Widget? flexibleSpace;
  final bool pinned;
  final bool floating;
  final bool snap;

  const CustomSliverAppBar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.centerTitle = true,
    this.backgroundColor,
    this.foregroundColor,
    this.expandedHeight = 200,
    this.flexibleSpace,
    this.pinned = true,
    this.floating = false,
    this.snap = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return SliverAppBar(
      title: Text(title),
      actions: actions,
      leading: leading,
      centerTitle: centerTitle,
      backgroundColor: backgroundColor ?? theme.primaryColor,
      foregroundColor: foregroundColor ?? Colors.white,
      expandedHeight: expandedHeight,
      flexibleSpace: flexibleSpace,
      pinned: pinned,
      floating: floating,
      snap: snap,
    );
  }
}

class TabBarWidget extends StatelessWidget implements PreferredSizeWidget {
  final List<Tab> tabs;
  final TabController? controller;
  final Color? indicatorColor;
  final Color? labelColor;
  final Color? unselectedLabelColor;

  const TabBarWidget({
    super.key,
    required this.tabs,
    this.controller,
    this.indicatorColor,
    this.labelColor,
    this.unselectedLabelColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return TabBar(
      tabs: tabs,
      controller: controller,
      indicatorColor: indicatorColor ?? theme.primaryColor,
      labelColor: labelColor ?? theme.primaryColor,
      unselectedLabelColor: unselectedLabelColor ?? theme.textTheme.bodySmall?.color,
      indicatorWeight: 3,
      labelStyle: const TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 14,
      ),
      unselectedLabelStyle: const TextStyle(
        fontWeight: FontWeight.normal,
        fontSize: 14,
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kTextTabBarHeight);
}
