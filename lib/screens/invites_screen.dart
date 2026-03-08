import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/friend_provider.dart';
import '../providers/auth_provider.dart';
import '../models/invite_model.dart';

/// Two-tab screen: Incoming friend requests | Outgoing friend requests.
/// Also includes a search bar to find users by email and send an invite.
class InvitesScreen extends StatefulWidget {
  const InvitesScreen({super.key});

  @override
  State<InvitesScreen> createState() => _InvitesScreenState();
}

class _InvitesScreenState extends State<InvitesScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _emailController = TextEditingController();

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
    // In production you would first look up the user's ID by email via a
    // search endpoint, then pass their ID to sendInvite.
    await context.read<FriendProvider>().sendInvite(email);
    _emailController.clear();
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Invite sent to $email')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Search bar ──────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    hintText: 'Search user by email…',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: _sendInvite,
                icon: const Icon(Icons.person_add),
                tooltip: 'Send invite',
              ),
            ],
          ),
        ),
        // ── Tab bar ─────────────────────────────────────────────────────────
        TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Incoming'),
            Tab(text: 'Outgoing'),
          ],
        ),
        // ── Tab views ───────────────────────────────────────────────────────
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _InviteList(type: InviteDirection.incoming),
              _InviteList(type: InviteDirection.outgoing),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Sub-widget for the list ────────────────────────────────────────────────────

class _InviteList extends StatelessWidget {
  final InviteDirection type;
  const _InviteList({required this.type});

  @override
  Widget build(BuildContext context) {
    return Consumer<FriendProvider>(
      builder: (ctx, fp, _) {
        if (fp.isLoadingInvites) {
          return const Center(child: CircularProgressIndicator());
        }
        final list = type == InviteDirection.incoming
            ? fp.incomingInvites
            : fp.outgoingInvites;

        if (list.isEmpty) {
          return Center(
            child: Text(
              type == InviteDirection.incoming
                  ? 'No incoming requests.'
                  : 'No outgoing requests.',
            ),
          );
        }

        return ListView.builder(
          itemCount: list.length,
          itemBuilder: (_, i) {
            final invite = list[i];
            return ListTile(
              leading: CircleAvatar(
                backgroundImage: invite.userAvatar != null
                    ? NetworkImage(invite.userAvatar!)
                    : null,
                child: invite.userAvatar == null
                    ? Text(invite.userName[0].toUpperCase())
                    : null,
              ),
              title: Text(invite.userName),
              subtitle: Text(invite.status.name),
              trailing: type == InviteDirection.incoming
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.check_circle,
                              color: Colors.green),
                          tooltip: 'Accept',
                          onPressed: () =>
                              ctx.read<FriendProvider>().acceptInvite(invite.userId),
                        ),
                        IconButton(
                          icon: const Icon(Icons.cancel, color: Colors.red),
                          tooltip: 'Decline',
                          onPressed: () =>
                              ctx.read<FriendProvider>().declineInvite(invite.userId),
                        ),
                      ],
                    )
                  : const Icon(Icons.schedule, color: Colors.grey),
            );
          },
        );
      },
    );
  }
}
