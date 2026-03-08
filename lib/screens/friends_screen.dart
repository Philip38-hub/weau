import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants.dart';
import '../providers/friend_provider.dart';
import '../models/friend_model.dart';

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

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(AppConstants.backgroundColor),
      ),
      child: Consumer<FriendProvider>(
        builder: (ctx, fp, _) {
          final visible = _filter(fp.friends);
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Search friends...',
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                    prefixIcon: const Icon(Icons.search_rounded, color: Color(AppConstants.primaryColor)),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.05),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              Expanded(
                child: fp.isLoadingFriends && fp.friends.isEmpty
                    ? const Center(child: CircularProgressIndicator(color: Color(AppConstants.primaryColor)))
                    : visible.isEmpty
                        ? Center(
                            child: Text(
                              'No friends found.',
                              style: TextStyle(color: Colors.white.withOpacity(0.5)),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: visible.length,
                            itemBuilder: (_, i) {
                              final friend = visible[i];
                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.03),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  leading: CircleAvatar(
                                    radius: 25,
                                    backgroundColor: const Color(AppConstants.primaryColor).withOpacity(0.2),
                                    backgroundImage: friend.avatar != null ? NetworkImage(friend.avatar!) : null,
                                    child: friend.avatar == null
                                        ? Text(
                                            friend.name[0].toUpperCase(),
                                            style: const TextStyle(color: Color(AppConstants.primaryColor), fontWeight: FontWeight.bold),
                                          )
                                        : null,
                                  ),
                                  title: Text(
                                    friend.name,
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                                  ),
                                  subtitle: friend.lastSeen != null
                                      ? Text(
                                          'Last seen: ${friend.lastSeen}',
                                          style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12),
                                        )
                                      : null,
                                  trailing: IconButton(
                                    icon: const Icon(Icons.person_remove_rounded, color: Color(AppConstants.accentColor)),
                                    onPressed: () => _confirmRemove(ctx, friend),
                                  ),
                                ),
                              );
                            },
                          ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _confirmRemove(BuildContext ctx, FriendModel friend) async {
    final confirmed = await showDialog<bool>(
      context: ctx,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(AppConstants.secondaryColor),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Remove friend?'),
        content: Text('Remove ${friend.name} from your friends list?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove', style: TextStyle(color: Color(AppConstants.accentColor))),
          ),
        ],
      ),
    );
    if (confirmed == true && ctx.mounted) {
      ctx.read<FriendProvider>().removeFriend(friend.id);
    }
  }
}
