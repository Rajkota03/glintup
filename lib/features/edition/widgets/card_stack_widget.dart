import 'package:flutter/material.dart';
import 'package:glintup/data/models/edition_model.dart';
import 'package:glintup/data/models/card_model.dart';
import 'package:glintup/features/edition/widgets/card_widget.dart';

/// Renders a vertical [PageView] of [CardWidget]s.
///
/// Supports smooth vertical swiping with callbacks for when the
/// visible card changes and when the user swipes past the last card.
class CardStackWidget extends StatefulWidget {
  const CardStackWidget({
    super.key,
    required this.cards,
    required this.onCardChanged,
    required this.onLastCardSwiped,
    this.initialIndex = 0,
    this.savedCardIds = const {},
    this.onSaveToggle,
  });

  /// The ordered list of edition cards to display.
  final List<EditionCardModel> cards;

  /// Called whenever the visible card changes (passes the new index).
  final ValueChanged<int> onCardChanged;

  /// Called when the user attempts to swipe past the last card.
  final VoidCallback onLastCardSwiped;

  /// The initial page to show.
  final int initialIndex;

  /// Set of card IDs that the user has bookmarked.
  final Set<String> savedCardIds;

  /// Called when the user taps the bookmark icon on a card.
  final ValueChanged<String>? onSaveToggle;

  @override
  State<CardStackWidget> createState() => _CardStackWidgetState();
}

class _CardStackWidgetState extends State<CardStackWidget> {
  late final PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() => _currentPage = index);
    widget.onCardChanged(index);
  }

  /// Detects an over-scroll past the last page, which means the user
  /// swiped up on the final card.
  bool _handleScrollNotification(ScrollNotification notification) {
    if (notification is OverscrollNotification) {
      // Overscroll past the end (swipe up on last card)
      if (notification.overscroll > 0 &&
          _currentPage == widget.cards.length - 1) {
        widget.onLastCardSwiped();
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.cards.isEmpty) {
      return const SizedBox.shrink();
    }

    return NotificationListener<ScrollNotification>(
      onNotification: _handleScrollNotification,
      child: PageView.builder(
        controller: _pageController,
        scrollDirection: Axis.vertical,
        physics: const BouncingScrollPhysics(),
        itemCount: widget.cards.length,
        onPageChanged: _onPageChanged,
        itemBuilder: (context, index) {
          final editionCard = widget.cards[index];
          final card = editionCard.card;
          if (card == null) {
            return const Center(
              child: Text('Card content unavailable'),
            );
          }

          return Center(
            child: CardWidget(
              card: card,
              isSaved: widget.savedCardIds.contains(card.id),
              onSaveToggle: widget.onSaveToggle != null
                  ? () => widget.onSaveToggle!(card.id)
                  : null,
            ),
          );
        },
      ),
    );
  }
}
