import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:glintup/core/constants/app_colors.dart';
import 'package:glintup/core/constants/app_constants.dart';
import 'package:glintup/core/network/supabase_client.dart';

/// A single topic option displayed in the selection grid.
class _Topic {
  const _Topic({
    required this.name,
    required this.icon,
    required this.color,
  });

  final String name;
  final IconData icon;
  final Color color;
}

const _availableTopics = <_Topic>[
  _Topic(name: 'Science', icon: Icons.science, color: AppColors.science),
  _Topic(name: 'History', icon: Icons.history_edu, color: AppColors.history),
  _Topic(name: 'Psychology', icon: Icons.psychology, color: AppColors.psychology),
  _Topic(name: 'Technology', icon: Icons.memory, color: AppColors.technology),
  _Topic(name: 'Arts', icon: Icons.palette, color: AppColors.arts),
  _Topic(name: 'Business', icon: Icons.business_center, color: AppColors.business),
  _Topic(name: 'Nature', icon: Icons.eco, color: AppColors.nature),
  _Topic(name: 'Space', icon: Icons.rocket_launch, color: AppColors.space),
];

class TopicSelectionScreen extends ConsumerStatefulWidget {
  const TopicSelectionScreen({super.key});

  @override
  ConsumerState<TopicSelectionScreen> createState() =>
      _TopicSelectionScreenState();
}

class _TopicSelectionScreenState extends ConsumerState<TopicSelectionScreen> {
  final Set<String> _selectedTopics = {};
  bool _isSaving = false;

  bool get _canContinue =>
      _selectedTopics.length >= AppConstants.minTopicsToSelect;

  void _toggleTopic(String topicName) {
    setState(() {
      if (_selectedTopics.contains(topicName)) {
        _selectedTopics.remove(topicName);
      } else if (_selectedTopics.length < AppConstants.maxTopicsToSelect) {
        _selectedTopics.add(topicName);
      }
    });
  }

  Future<void> _saveAndContinue() async {
    if (!_canContinue || _isSaving) return;

    setState(() => _isSaving = true);

    try {
      final userId = SupabaseConfig.userId;
      if (userId == null) throw Exception('User not authenticated');

      final topicsList = _selectedTopics.toList();

      // Save preferred topics to profiles table.
      await SupabaseConfig.client.from('profiles').upsert({
        'id': userId,
        'preferred_topics': topicsList,
      });

      // Save individual topic rows to user_interests table.
      final interestRows = topicsList
          .map((topic) => {
                'user_id': userId,
                'topic': topic.toLowerCase(),
              })
          .toList();

      await SupabaseConfig.client.from('user_interests').upsert(interestRows);

      if (!mounted) return;

      context.go('/onboarding/notifications');
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceAll('Exception: ', ''),
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 32),

              // Heading
              Text(
                'What interests you?',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Pick at least ${AppConstants.minTopicsToSelect} topics',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),

              const SizedBox(height: 32),

              // Topic grid
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.only(bottom: 16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.9,
                  ),
                  itemCount: _availableTopics.length,
                  itemBuilder: (context, index) {
                    final topic = _availableTopics[index];
                    final isSelected = _selectedTopics.contains(topic.name);

                    return _TopicCard(
                      topic: topic,
                      isSelected: isSelected,
                      onTap: () => _toggleTopic(topic.name),
                    );
                  },
                ),
              ),

              // Continue button
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _canContinue && !_isSaving
                      ? _saveAndContinue
                      : null,
                  child: _isSaving
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          _canContinue
                              ? 'Continue'
                              : 'Select ${AppConstants.minTopicsToSelect - _selectedTopics.length} more',
                        ),
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Topic card widget
// ---------------------------------------------------------------------------

class _TopicCard extends StatelessWidget {
  const _TopicCard({
    required this.topic,
    required this.isSelected,
    required this.onTap,
  });

  final _Topic topic;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected
              ? topic.color.withValues(alpha: 0.12)
              : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? topic.color : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Stack(
          children: [
            // Checkmark badge
            if (isSelected)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: topic.color,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    size: 14,
                    color: Colors.white,
                  ),
                ),
              ),

            // Content
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    topic.icon,
                    size: 36,
                    color: isSelected ? topic.color : AppColors.textMuted,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    topic.name,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: isSelected
                              ? topic.color
                              : AppColors.textSecondary,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w400,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
