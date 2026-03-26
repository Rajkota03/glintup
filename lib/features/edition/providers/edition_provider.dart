import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glintup/core/network/supabase_client.dart';
import 'package:glintup/core/demo/demo_data.dart';
import 'package:glintup/data/models/edition_model.dart';
import 'package:glintup/data/repositories/edition_repository.dart';

// ---------------------------------------------------------------------------
// Repository provider
// ---------------------------------------------------------------------------
final editionRepositoryProvider = Provider<EditionRepository>((ref) {
  return EditionRepository();
});

// ---------------------------------------------------------------------------
// Today's edition — tries Supabase, falls back to demo data on any error
// ---------------------------------------------------------------------------
final todayEditionProvider = FutureProvider.family<
    ({EditionModel? edition, List<EditionCardModel> cards}), String>(
  (ref, tier) async {
    try {
      final repo = ref.read(editionRepositoryProvider);
      final userId = SupabaseConfig.userId;

      // 1. Call the RPC function to assemble the edition (if needed).
      if (userId != null) {
        try {
          await SupabaseConfig.client.rpc('assemble_edition', params: {
            'p_user_id': userId,
            'p_tier': 'free',
          });
        } catch (_) {
          // RPC may not exist or may fail — we continue to fetch anyway.
        }
      }

      // 2. Fetch today's edition.
      final edition = await repo.getTodayEdition('free');
      if (edition == null) {
        // No edition for today — return demo data so the UI is never empty.
        return (
          edition: DemoData.getSampleEdition(),
          cards: DemoData.getSampleEditionCards(),
        );
      }

      // 3. Fetch edition cards.
      final cards = await repo.getEditionCards(edition.id);

      return (edition: edition, cards: cards);
    } catch (_) {
      // Supabase table missing, network error, etc. — show demo content.
      return (
        edition: DemoData.getSampleEdition(),
        cards: DemoData.getSampleEditionCards(),
      );
    }
  },
);

// ---------------------------------------------------------------------------
// Edition state
// ---------------------------------------------------------------------------
class EditionState {
  final EditionModel? edition;
  final List<EditionCardModel> cards;
  final int currentIndex;
  final bool isCompleted;
  final int totalTimeSeconds;
  final DateTime? startedAt;

  const EditionState({
    this.edition,
    this.cards = const [],
    this.currentIndex = 0,
    this.isCompleted = false,
    this.totalTimeSeconds = 0,
    this.startedAt,
  });

  int get totalCards => cards.length;

  EditionCardModel? get currentCard =>
      cards.isNotEmpty && currentIndex < cards.length
          ? cards[currentIndex]
          : null;

  double get progress =>
      totalCards > 0 ? (currentIndex + 1) / totalCards : 0.0;

  /// Unique topics across all cards in the edition.
  Set<String> get topics =>
      cards.map((c) => c.card?.topic ?? '').where((t) => t.isNotEmpty).toSet();

  EditionState copyWith({
    EditionModel? edition,
    List<EditionCardModel>? cards,
    int? currentIndex,
    bool? isCompleted,
    int? totalTimeSeconds,
    DateTime? startedAt,
  }) {
    return EditionState(
      edition: edition ?? this.edition,
      cards: cards ?? this.cards,
      currentIndex: currentIndex ?? this.currentIndex,
      isCompleted: isCompleted ?? this.isCompleted,
      totalTimeSeconds: totalTimeSeconds ?? this.totalTimeSeconds,
      startedAt: startedAt ?? this.startedAt,
    );
  }
}

// ---------------------------------------------------------------------------
// Edition state notifier
// ---------------------------------------------------------------------------
class EditionStateNotifier extends StateNotifier<EditionState> {
  EditionStateNotifier() : super(const EditionState());

  DateTime? _cardStartedAt;

  /// Loads an edition and its cards into state.
  void loadEdition(EditionModel edition, List<EditionCardModel> cards) {
    state = EditionState(
      edition: edition,
      cards: cards,
      currentIndex: 0,
      isCompleted: false,
      totalTimeSeconds: 0,
      startedAt: DateTime.now(),
    );
    _cardStartedAt = DateTime.now();
  }

  /// Advances to the next card.
  /// Returns `true` if there was a next card, `false` if we were on the last.
  bool nextCard() {
    _trackCardTime();
    if (state.currentIndex >= state.totalCards - 1) {
      return false; // already on last card
    }
    state = state.copyWith(currentIndex: state.currentIndex + 1);
    _cardStartedAt = DateTime.now();
    return true;
  }

  /// Goes back to the previous card.
  void previousCard() {
    _trackCardTime();
    if (state.currentIndex <= 0) return;
    state = state.copyWith(currentIndex: state.currentIndex - 1);
    _cardStartedAt = DateTime.now();
  }

  /// Marks the edition as completed.
  void markCompleted() {
    _trackCardTime();
    state = state.copyWith(isCompleted: true);
  }

  /// Manually add seconds to the total reading time.
  void addTime(int seconds) {
    state = state.copyWith(
      totalTimeSeconds: state.totalTimeSeconds + seconds,
    );
  }

  /// Sets the current index directly (used by PageView callbacks).
  void setIndex(int index) {
    if (index < 0 || index >= state.totalCards) return;
    _trackCardTime();
    state = state.copyWith(currentIndex: index);
    _cardStartedAt = DateTime.now();
  }

  /// Returns the number of seconds spent on the current card so far.
  int get currentCardElapsed {
    if (_cardStartedAt == null) return 0;
    return DateTime.now().difference(_cardStartedAt!).inSeconds;
  }

  // -- Private helpers -------------------------------------------------------

  void _trackCardTime() {
    if (_cardStartedAt == null) return;
    final elapsed = DateTime.now().difference(_cardStartedAt!).inSeconds;
    if (elapsed > 0) {
      state = state.copyWith(
        totalTimeSeconds: state.totalTimeSeconds + elapsed,
      );
    }
    _cardStartedAt = null;
  }
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------
final editionStateProvider =
    StateNotifierProvider<EditionStateNotifier, EditionState>((ref) {
  return EditionStateNotifier();
});
