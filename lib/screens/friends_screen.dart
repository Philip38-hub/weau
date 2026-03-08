import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/friend_provider.dart';
import '../models/friend_model.dart';

/// Displays the user's current friends list and allows deletion.
class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    // Fetch friends when screen is first shown.
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<FriendProvider>().fetchFriends(),
    );
    _searchController.addListener(
      () => setState(() => _query = _searchController.text.trim().toLowerCase()),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<FriendModel> _filter(List<FriendModel> all) {
    if (_query.isEmpty) return all;
    return all.where((f) => f.name.toLowerCase().contains(_query)).toList();
  }

  Future<void> _confirmRemove(BuildContext ctx, FriendModel friend) async {
    final confirmed = await showDialog<bool>(
      context: ctx,
      builder: (_) => AlertDialog(
        title: const Text('Remove friend?'),
        content: Text('Remove ${friend.name} from your friends list?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Remove',
                  style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirmed == true && ctx.mounted) {
      ctx.read<FriendProvider>().removeFriend(friend.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FriendProvider>(
      builder: (ctx, fp, _) {
        if (fp.isLoadingFriends && fp.friends.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        final visible = _filter(fp.friends);
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search friends…',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            if (fp.error != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(fp.error!,
                    style: const TextStyle(color: Colors.red)),
              ),
            Expanded(
              child: visible.isEmpty
                  ? const Center(child: Text('No friends found.'))
                  : ListView.builder(
                      itemCount: visible.length,
                      itemBuilder: (_, i) {
                        final friend = visible[i];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundImage: friend.avatar != null
                                ? NetworkImage(friend.avatar!)
                                : null,
                            child: friend.avatar == null
                                ? Text(friend.name[0].toUpperCase())
                                : null,
                          ),
                          title: Text(friend.name),
                          subtitle: friend.lastSeen != null
                              ? Text('Last seen: ${friend.lastSeen}')
                              : null,
                          trailing: IconButton(
                            icon: const Icon(Icons.person_remove,
                                color: Colors.red),
                            onPressed: () => _confirmRemove(ctx, friend),
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
}
