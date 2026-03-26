import 'package:glintup/data/models/card_model.dart';
import 'package:glintup/data/models/edition_model.dart';
import 'package:glintup/data/models/topic_model.dart';
import 'package:glintup/data/models/user_stats_model.dart';
import 'package:glintup/features/explore/providers/explore_provider.dart';

/// Provides sample data so the app can render a full UI preview
/// even when Supabase tables do not exist yet.
class DemoData {
  DemoData._();

  // ── Sample Cards ─────────────────────────────────────────────

  static List<CardModel> getSampleCards() {
    final now = DateTime.now();
    return [
      // 1. QuickFact
      CardModel(
        id: 'demo-card-1',
        cardType: CardType.quickFact,
        status: CardStatus.published,
        title: 'Octopuses Have Three Hearts',
        subtitle: 'A circulatory marvel',
        body:
            'An octopus has three hearts: two branchial hearts pump blood through the gills, while a single systemic heart circulates it to the rest of the body. When an octopus swims, the systemic heart actually stops beating, which is why these creatures prefer crawling to swimming.',
        summary: 'Two hearts pump blood to the gills, one pumps it to the body.',
        topic: 'science',
        tags: ['biology', 'ocean', 'animals'],
        difficultyLevel: 1,
        estimatedReadSeconds: 30,
        createdAt: now,
        publishedAt: now,
      ),
      // 2. Insight
      CardModel(
        id: 'demo-card-2',
        cardType: CardType.insight,
        status: CardStatus.published,
        title: 'The 2-Minute Rule',
        subtitle: 'A productivity hack from James Clear',
        body:
            'If a task takes less than two minutes, do it immediately instead of adding it to your to-do list. This simple rule, popularised by James Clear in Atomic Habits, prevents small tasks from piling up and draining your mental energy. Over time, the habit of acting on tiny tasks builds momentum for tackling larger ones.',
        summary: 'Do any task that takes under two minutes right away.',
        topic: 'psychology',
        tags: ['productivity', 'habits', 'self-improvement'],
        difficultyLevel: 1,
        estimatedReadSeconds: 45,
        createdAt: now,
        publishedAt: now,
      ),
      // 3. Visual
      CardModel(
        id: 'demo-card-3',
        cardType: CardType.visual,
        status: CardStatus.published,
        title: 'The Scale of the Universe',
        subtitle: 'Putting cosmic distances in perspective',
        body:
            'If the Sun were a basketball, Earth would be a small peppercorn about 26 metres away. Jupiter would be a walnut at 135 metres, and the nearest star, Proxima Centauri, would be another basketball roughly 6,900 kilometres from the first. These comparisons help us grasp just how staggeringly empty space really is.',
        summary: 'A basketball-scale model that makes cosmic distances tangible.',
        topic: 'science',
        tags: ['astronomy', 'space', 'scale'],
        difficultyLevel: 2,
        estimatedReadSeconds: 45,
        createdAt: now,
        publishedAt: now,
      ),
      // 4. Story
      CardModel(
        id: 'demo-card-4',
        cardType: CardType.story,
        status: CardStatus.published,
        title: 'The Accidental Discovery of Penicillin',
        subtitle: 'How a forgotten petri dish changed medicine',
        body:
            'In September 1928, Scottish bacteriologist Alexander Fleming returned from holiday to find mould growing on a petri dish of Staphylococcus bacteria he had left by a window. Instead of discarding the contaminated sample, he noticed that the bacteria surrounding the mould had been destroyed. Fleming identified the mould as Penicillium notatum and published his findings, though it took another decade before Howard Florey and Ernst Boris Chain developed penicillin into a viable antibiotic. By the end of World War II, penicillin had saved countless lives and ushered in the modern era of antibiotics.',
        summary: 'A mouldy petri dish led to the antibiotic revolution.',
        topic: 'history',
        tags: ['medicine', 'discovery', 'science-history'],
        difficultyLevel: 2,
        estimatedReadSeconds: 120,
        createdAt: now,
        publishedAt: now,
      ),
      // 5. DeepRead
      CardModel(
        id: 'demo-card-5',
        cardType: CardType.deepRead,
        status: CardStatus.published,
        title: 'Why We Dream',
        subtitle: 'Exploring the science behind our nightly adventures',
        body:
            'Dreaming remains one of neuroscience\'s most fascinating puzzles. During REM sleep, the brain is almost as active as when we are awake, yet our voluntary muscles are temporarily paralysed. One leading theory, the activation-synthesis hypothesis, suggests that dreams result from the brain\'s attempt to make sense of random neural activity. Another perspective, the threat-simulation theory proposed by Antti Revonsuo, argues that dreaming evolved as a way to rehearse potentially dangerous situations in a safe environment.\n\nMore recent research points to dreams playing a role in memory consolidation. Studies show that people who sleep after learning a new skill perform better than those who stay awake, and the content of their dreams often reflects the learned material. Whatever their ultimate purpose, dreams offer a window into the unconscious processes that shape our waking lives.',
        summary: 'Theories range from random neural noise to evolutionary rehearsal.',
        topic: 'psychology',
        tags: ['neuroscience', 'sleep', 'cognition'],
        difficultyLevel: 3,
        estimatedReadSeconds: 180,
        createdAt: now,
        publishedAt: now,
      ),
      // 6. Question
      CardModel(
        id: 'demo-card-6',
        cardType: CardType.question,
        status: CardStatus.published,
        title: 'Ocean Exploration',
        subtitle: 'Test your knowledge',
        body: 'The ocean covers over 70% of the Earth\'s surface, yet most of it remains a mystery. Advances in submersible technology are slowly revealing what lies beneath, but the sheer depth and pressure make exploration extraordinarily challenging.',
        summary: 'How much of the ocean have we actually explored?',
        topic: 'science',
        tags: ['ocean', 'exploration', 'trivia'],
        difficultyLevel: 1,
        estimatedReadSeconds: 30,
        questionText: 'What percentage of the ocean has been explored?',
        answerOptions: [
          {'text': '5%', 'is_correct': true},
          {'text': '20%', 'is_correct': false},
          {'text': '50%', 'is_correct': false},
          {'text': '80%', 'is_correct': false},
        ],
        correctAnswerExplanation:
            'Only about 5% of the world\'s oceans have been explored and mapped. The remaining 95% remains unseen by human eyes, making the ocean floor less explored than the surface of Mars.',
        createdAt: now,
        publishedAt: now,
      ),
      // 7. Quote
      CardModel(
        id: 'demo-card-7',
        cardType: CardType.quote,
        status: CardStatus.published,
        title: 'On Doing Great Work',
        subtitle: 'Steve Jobs',
        body:
            '"The only way to do great work is to love what you do." — Steve Jobs. This sentiment, shared during his famous 2005 Stanford commencement address, encapsulates the idea that passion is the foundation of excellence. Jobs believed that enthusiasm sustains you through the inevitable setbacks of any meaningful endeavour.',
        summary: 'Passion as the foundation of excellence.',
        topic: 'technology',
        tags: ['motivation', 'career', 'leadership'],
        difficultyLevel: 1,
        estimatedReadSeconds: 30,
        createdAt: now,
        publishedAt: now,
      ),
      // 8. QuickFact
      CardModel(
        id: 'demo-card-8',
        cardType: CardType.quickFact,
        status: CardStatus.published,
        title: 'Honey Never Spoils',
        subtitle: 'Nature\'s eternal sweetener',
        body:
            'Archaeologists have found pots of honey in ancient Egyptian tombs that are over 3,000 years old and still perfectly edible. Honey\'s longevity comes from its low moisture content, acidic pH, and the natural production of hydrogen peroxide, all of which create an inhospitable environment for bacteria and microorganisms.',
        summary: '3,000-year-old honey from Egyptian tombs is still edible.',
        topic: 'history',
        tags: ['food', 'archaeology', 'chemistry'],
        difficultyLevel: 1,
        estimatedReadSeconds: 30,
        createdAt: now,
        publishedAt: now,
      ),
      // 9. Insight
      CardModel(
        id: 'demo-card-9',
        cardType: CardType.insight,
        status: CardStatus.published,
        title: 'The Dunning-Kruger Effect',
        subtitle: 'Why beginners overestimate their abilities',
        body:
            'The Dunning-Kruger effect is a cognitive bias in which people with limited competence in a domain tend to overestimate their own abilities. Conversely, experts often underestimate theirs, assuming that tasks they find easy are easy for everyone. First described by psychologists David Dunning and Justin Kruger in 1999, this effect highlights a fundamental paradox: the skills needed to produce correct responses are the same skills needed to recognise what a correct response looks like.',
        summary: 'Low skill leads to overconfidence; high skill leads to self-doubt.',
        topic: 'psychology',
        tags: ['cognitive-bias', 'learning', 'self-awareness'],
        difficultyLevel: 2,
        estimatedReadSeconds: 60,
        createdAt: now,
        publishedAt: now,
      ),
      // 10. Visual
      CardModel(
        id: 'demo-card-10',
        cardType: CardType.visual,
        status: CardStatus.published,
        title: 'How Deep Is the Ocean?',
        subtitle: 'The Mariana Trench and beyond',
        body:
            'The Mariana Trench, located in the western Pacific Ocean, reaches a maximum depth of nearly 11,000 metres at Challenger Deep. To put that in perspective, if you placed Mount Everest at the bottom of the trench, its peak would still be more than 2,000 metres underwater. The pressure at the bottom is over 1,000 times atmospheric pressure at sea level, yet life still thrives there in the form of tiny single-celled organisms called foraminifera.',
        summary: 'Challenger Deep is nearly 11 km below the surface.',
        topic: 'science',
        tags: ['ocean', 'geography', 'extremes'],
        difficultyLevel: 2,
        estimatedReadSeconds: 45,
        createdAt: now,
        publishedAt: now,
      ),
    ];
  }

  // ── Sample Edition ───────────────────────────────────────────

  static const String _editionId = 'demo-edition-1';

  static EditionModel getSampleEdition() {
    final now = DateTime.now();
    return EditionModel(
      id: _editionId,
      editionDate: now,
      editionNumber: 42,
      theme: 'Curiosity Corner',
      totalCards: 10,
      totalReadSeconds: 600,
      tier: 'free',
      status: 'published',
      createdAt: now,
      assembledAt: now,
    );
  }

  // ── Sample Edition Cards ─────────────────────────────────────

  static List<EditionCardModel> getSampleEditionCards() {
    final cards = getSampleCards();
    return List.generate(cards.length, (i) {
      String pacingRole;
      if (i == 0) {
        pacingRole = 'opener';
      } else if (i == cards.length - 1) {
        pacingRole = 'closer';
      } else {
        pacingRole = 'standard';
      }

      return EditionCardModel(
        id: 'demo-ec-${i + 1}',
        editionId: _editionId,
        cardId: cards[i].id,
        position: i,
        pacingRole: pacingRole,
        card: cards[i],
      );
    });
  }

  // ── Sample Topics ────────────────────────────────────────────

  static List<TopicModel> getSampleTopics() {
    return const [
      TopicModel(
        id: 'demo-topic-1',
        slug: 'science',
        displayName: 'Science',
        iconName: 'science',
        colorHex: '#3B82F6',
        sortOrder: 0,
      ),
      TopicModel(
        id: 'demo-topic-2',
        slug: 'history',
        displayName: 'History',
        iconName: 'history_edu',
        colorHex: '#F59E0B',
        sortOrder: 1,
      ),
      TopicModel(
        id: 'demo-topic-3',
        slug: 'psychology',
        displayName: 'Psychology',
        iconName: 'psychology',
        colorHex: '#8B5CF6',
        sortOrder: 2,
      ),
      TopicModel(
        id: 'demo-topic-4',
        slug: 'technology',
        displayName: 'Technology',
        iconName: 'computer',
        colorHex: '#10B981',
        sortOrder: 3,
      ),
      TopicModel(
        id: 'demo-topic-5',
        slug: 'arts',
        displayName: 'Arts',
        iconName: 'palette',
        colorHex: '#EC4899',
        sortOrder: 4,
      ),
      TopicModel(
        id: 'demo-topic-6',
        slug: 'business',
        displayName: 'Business',
        iconName: 'business',
        colorHex: '#6366F1',
        sortOrder: 5,
      ),
      TopicModel(
        id: 'demo-topic-7',
        slug: 'nature',
        displayName: 'Nature',
        iconName: 'eco',
        colorHex: '#22C55E',
        sortOrder: 6,
      ),
      TopicModel(
        id: 'demo-topic-8',
        slug: 'space',
        displayName: 'Space',
        iconName: 'rocket_launch',
        colorHex: '#1E3A5F',
        sortOrder: 7,
      ),
    ];
  }

  // ── Sample Rabbit Holes ──────────────────────────────────────

  static List<RabbitHoleModel> getSampleRabbitHoles() {
    return const [
      RabbitHoleModel(
        id: 'demo-rh-1',
        topic: 'science',
        title: 'The Quantum World',
        description:
            'From wave-particle duality to entanglement, explore the strange rules that govern the subatomic realm.',
        totalCards: 8,
        estimatedTimeMinutes: 12,
        difficultyLevel: 3,
      ),
      RabbitHoleModel(
        id: 'demo-rh-2',
        topic: 'history',
        title: 'Turning Points of the 20th Century',
        description:
            'Key moments that shaped the modern world, from world wars to the space race.',
        totalCards: 10,
        estimatedTimeMinutes: 15,
        difficultyLevel: 2,
      ),
      RabbitHoleModel(
        id: 'demo-rh-3',
        topic: 'psychology',
        title: 'Cognitive Biases 101',
        description:
            'Discover the mental shortcuts your brain uses and why they sometimes lead you astray.',
        totalCards: 6,
        estimatedTimeMinutes: 9,
        difficultyLevel: 2,
        isPremium: true,
      ),
    ];
  }

  // ── Sample User Stats ────────────────────────────────────────

  static UserStatsModel getSampleStats() {
    return UserStatsModel(
      id: 'demo-stats-1',
      userId: 'demo-user',
      currentStreak: 7,
      longestStreak: 14,
      lastCompletedDate: DateTime.now().subtract(const Duration(days: 1)),
      totalEditionsCompleted: 42,
      totalCardsRead: 420,
      totalTimeSeconds: 25200,
      totalCardsSaved: 38,
      cardsThisWeek: 35,
      cardsThisMonth: 120,
      xpPoints: 4200,
      level: 9,
      updatedAt: DateTime.now(),
    );
  }

  // ── Sample User Profile ──────────────────────────────────────

  static Map<String, dynamic> getSampleProfile() {
    return {
      'id': 'demo-user',
      'first_name': 'Demo User',
      'email': 'demo@glintup.app',
    };
  }
}
