import 'package:flutter/material.dart';
import 'package:glintup/data/models/edition_model.dart';
import 'package:glintup/features/edition/widgets/card_widget.dart';

/// Renders a vertical [PageView] of [CardWidget]s with smooth
/// scale transitions between cards.
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

  final List<EditionCardModel> cards;
  final ValueChanged<int> onCardChanged;
  final VoidCallback onLastCardSwiped;
  final int initialIndex;
  final Set<String> savedCardIds;
  final ValueChanged<String>? onSaveToggle;

  @override
  State<CardStackWidget> createState() => _CardStackWidgetState();
}

class _CardStackWidgetState extends State<CardStackWidget> {
  late final PageController _pageController;
  int _currentPage = 0;
  double _currentPageValue = 0.0;

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialIndex;
    _currentPageValue = widget.initialIndex.toDouble();
    _pageController = PageController(initialPage: widget.initialIndex);
    _pageController.addListener(_onPageScroll);
  }

  @override
  void dispose() {
    _pageController.removeListener(_onPageScroll);
    _pageController.dispose();
    super.dispose();
  }

  void _onPageScroll() {
    setState(() {
      _currentPageValue = _pageController.page ?? _currentPage.toDouble();
    });
  }

  void _onPageChanged(int index) {
    setState(() => _currentPage = index);
    widget.onCardChanged(index);
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    if (notification is OverscrollNotification) {
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

          // Scale animation: current card is full size, others slightly smaller
          final difference = (index - _currentPageValue).abs();
          final scale = 1.0 - (difference * 0.05).clamp(0.0, 0.15);
          final opacity = 1.0 - (difference * 0.3).clamp(0.0, 0.5);

          return Center(
            child: Transform.scale(
              scale: scale,
              child: Opacity(
                opacity: opacity,
                child: CardWidget(
                  card: card,
                  cardIndex: index,
                  isSaved: widget.savedCardIds.contains(card.id),
                  onSaveToggle: widget.onSaveToggle != null
                      ? () => widget.onSaveToggle!(card.id)
                      : null,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
