import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants.dart';
import '../providers/friend_provider.dart';
import '../providers/auth_provider.dart';
import '../models/invite_model.dart';

class InvitesScreen extends StatefulWidget {
  const InvitesScreen({super.key});

  @override
  State<InvitesScreen> createState() => _InvitesScreenState();
}

class _InvitesScreenState extends State<InvitesScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _emailController = TextEditingController();

  void _showSnackBar(String message, {required Color backgroundColor}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = context.read<AuthProvider>().user?.id ?? '';
      context.read<FriendProvider>().fetchInvites(userId);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendInvite() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) return;

    final auth = context.read<AuthProvider>();
    final friends = context.read<FriendProvider>();
    final success = await friends.sendInvite(
      email,
      currentUserId: auth.user?.id ?? '',
    );

    if (!mounted) return;

    if (success) {
      _emailController.clear();
      _showSnackBar(
        'Invite sent to $email',
        backgroundColor: const Color(AppConstants.primaryColor),
      );
    } else {
      _showSnackBar(
        friends.error ?? 'Failed to send invite.',
        backgroundColor: const Color(AppConstants.accentColor),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final inputFillColor = isDark
        ? Colors.white.withValues(alpha: 0.05)
        : scheme.primary.withValues(alpha: 0.06);
    final cardColor = isDark ? Colors.white.withValues(alpha: 0.03) : Colors.white;

    return Container(
      color: theme.scaffoldBackgroundColor,
      child: Column(
        children: [
          // ── Premium Search Bar ─────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: TextStyle(color: scheme.onSurface),
                    decoration: InputDecoration(
                      hintText: 'Enter email address...',
                      hintStyle: TextStyle(color: scheme.onSurfaceVariant),
                      prefixIcon: const Icon(Icons.alternate_email_rounded, color: Color(AppConstants.primaryColor)),
                      filled: true,
                      fillColor: inputFillColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(AppConstants.primaryColor), Color(AppConstants.accentColor)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: IconButton(
                    onPressed: _sendInvite,
                    icon: const Icon(Icons.add_rounded, color: Colors.white),
                    tooltip: 'Send Invite',
                  ),
                ),
              ],
            ),
          ),
          // ── Tab Bar ────────────────────────────────────────────────────────
          TabBar(
            controller: _tabController,
            indicatorColor: const Color(AppConstants.primaryColor),
            labelColor: const Color(AppConstants.primaryColor),
            unselectedLabelColor: scheme.onSurfaceVariant,
            indicatorSize: TabBarIndicatorSize.label,
            tabs: const [
              Tab(text: 'Incoming'),
              Tab(text: 'Outgoing'),
            ],
          ),
          // ── Tab View ───────────────────────────────────────────────────────
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _InviteList(type: InviteDirection.incoming, cardColor: cardColor),
                _InviteList(type: InviteDirection.outgoing, cardColor: cardColor),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InviteList extends StatelessWidget {
  final InviteDirection type;
  final Color cardColor;

  const _InviteList({required this.type, required this.cardColor});

  Future<void> _handleInviteAction(
    BuildContext context, {
    required Future<bool> Function(String currentUserId) action,
    required FriendProvider provider,
    required String successMessage,
  }) async {
    final currentUserId = context.read<AuthProvider>().user?.id ?? '';
    final success = await action(currentUserId);
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? successMessage : (provider.error ?? 'Request failed.')),
        backgroundColor: success ? Colors.green : const Color(AppConstants.accentColor),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Consumer<FriendProvider>(
      builder: (ctx, fp, _) {
        if (fp.isLoadingInvites) {
          return const Center(child: CircularProgressIndicator(color: Color(AppConstants.primaryColor)));
        }
        final list = type == InviteDirection.incoming ? fp.incomingInvites : fp.outgoingInvites;

        if (list.isEmpty) {
          return Center(
            child: Text(
              type == InviteDirection.incoming ? 'No incoming requests.' : 'No outgoing requests.',
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: list.length,
          itemBuilder: (_, i) {
            final invite = list[i];
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: CircleAvatar(
                  radius: 25,
                  backgroundColor: const Color(
                    AppConstants.primaryColor,
                  ).withValues(alpha: 0.2),
                  child: Text(invite.userName[0].toUpperCase(), style: const TextStyle(color: Color(AppConstants.primaryColor))),
                ),
                title: Text(invite.userName, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(invite.status.name, style: TextStyle(color: scheme.onSurfaceVariant)),
                trailing: type == InviteDirection.incoming
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.check_circle_rounded, color: Colors.green),
                            onPressed: () => _handleInviteAction(
                              ctx,
                              provider: ctx.read<FriendProvider>(),
                              action: (currentUserId) => ctx.read<FriendProvider>().acceptInvite(
                                invite.userId,
                                currentUserId: currentUserId,
                              ),
                              successMessage: 'Invite accepted.',
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.cancel_rounded, color: Color(AppConstants.accentColor)),
                            onPressed: () => _handleInviteAction(
                              ctx,
                              provider: ctx.read<FriendProvider>(),
                              action: (currentUserId) => ctx.read<FriendProvider>().declineInvite(
                                invite.userId,
                                currentUserId: currentUserId,
                              ),
                              successMessage: 'Invite declined.',
                            ),
                          ),
                        ],
                      )
                    : const Padding(
                        padding: EdgeInsets.only(right: 12.0),
                        child: Icon(Icons.hourglass_empty_rounded, color: Colors.grey),
                      ),
              ),
            );
          },
        );
      },
    );
  }
}
