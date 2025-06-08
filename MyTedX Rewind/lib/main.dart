import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mytedx/models/talk.dart';
import 'package:mytedx/models/watchNextResponse.dart'; // This import seems unused in main.dart
import 'package:mytedx/pages/favoritesPage.dart';
import 'package:mytedx/pages/talk_detail_page.dart';
import 'dart:convert';

import 'package:mytedx/talk_repository.dart';
import 'package:mytedx/favorites_service.dart'; // Import the FavoritesService

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MyTEDx Rewind',
      theme: ThemeData(
        primarySwatch: Colors.red,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
        ),
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, this.title = 'MyTEDx Rewind'});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with TickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  late Future<List<Talk>> _talks; // This variable seems unused
  List<Talk> _allTalks = [];
  List<Talk> _filteredTalks = [];
  Set<String> _favoriteTalkSlugs = {}; // To store slugs of favorite talks
  bool _isLoading = true;
  bool _isTextSearching = false; // For text field search
  bool _isTagSearching = false; // For "Smart Search" tag search
  String _currentSearchQuery = '';
  String _currentSearchTag = '';
  int page = 1; // This variable seems unused
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late AnimationController _searchAnimationController;
  late Animation<double> _searchScaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _searchAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _searchScaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _searchAnimationController, curve: Curves.elasticOut),
    );

    _loadAllTalks();
    _loadFavoritesStatus(); // Load favorite status initially
    _animationController.forward();
    _searchAnimationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchAnimationController.dispose();
    _controller.dispose();
    super.dispose();
  }

  // New method to load favorite status
  void _loadFavoritesStatus() async {
    try {
      final favorites = await FavoritesService.getFavorites();
      setState(() {
        _favoriteTalkSlugs = favorites.map((talk) => talk.slug).toSet();
      });
      print('✅ Loaded ${favorites.length} favorite talks slugs.');
    } catch (e) {
      print('❌ Error loading favorite slugs: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading favorites status.'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  // Function to toggle favorite status
  void _toggleFavorite(Talk talk) async {
    final isCurrentlyFavorite = _favoriteTalkSlugs.contains(talk.slug);
    bool success;

    if (isCurrentlyFavorite) {
      success = await FavoritesService.removeFromFavorites(talk.slug);
      if (success) {
        setState(() {
          _favoriteTalkSlugs.remove(talk.slug);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${talk.title} removed from favorites!'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to remove ${talk.title} from favorites.'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } else {
      success = await FavoritesService.addToFavorites(talk.slug);
      if (success) {
        setState(() {
          _favoriteTalkSlugs.add(talk.slug);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${talk.title} added to favorites! ✨'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add ${talk.title} to favorites.'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _loadAllTalks() async {
    setState(() {
      _isLoading = true;
    });

    try {
      print('🚀 Starting to load all talks...');
      final talks = await getAllTalks();
      print('✅ Loaded ${talks.length} talks successfully');

      setState(() {
        _allTalks = talks;
        _filteredTalks = talks;
        _isLoading = false;
      });

      if (talks.isEmpty) {
        print('⚠️  No talks received - loading mock data for testing');
        _loadMockData();
      }
    } catch (e) {
      print('❌ Error loading talks: $e');
      setState(() {
        _isLoading = false;
      });

      // Load mock data for testing if API fails
      _loadMockData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Using offline data. Check console for API details.'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: _loadAllTalks,
            ),
          ),
        );
      }
    }
    _loadFavoritesStatus(); // Also refresh favorite status after loading talks
  }

  void _loadMockData() {
    // Temporary mock data for testing UI
    final mockTalks = [
      Talk(
        title: "The power of believing that you can improve",
        slug: "mock-1",
        details: "Mock talk for testing",
        mainSpeaker: "Carol Dweck",
        url: "https://www.ted.com/talks/carol_dweck_the_power_of_believing_that_you_can_improve",
        keyPhrases: ["growth mindset", "improvement", "learning"],
      ),
      Talk(
        title: "Your body language may shape who you are",
        slug: "mock-2",
        details: "Mock talk for testing",
        mainSpeaker: "Amy Cuddy",
        url: "https://www.ted.com/talks/amy_cuddy_your_body_language_may_shape_who_you_are",
        keyPhrases: ["body language", "confidence", "posture"],
      ),
      Talk(
        title: "How to speak so that people want to listen",
        slug: "mock-3",
        details: "Mock talk for testing",
        mainSpeaker: "Julian Treasure",
        url: "https://www.ted.com/talks/julian_treasure_how_to_speak_so_that_people_want_to_listen",
        keyPhrases: ["communication", "speaking", "listening"],
      ),
      Talk(
        title: "The magic of thinking big dreams",
        slug: "mock-4",
        details: "Discover the enchanted world of limitless possibilities",
        mainSpeaker: "Maya Stardust",
        url: "https://www.ted.com/talks/maya_stardust_magic_thinking_big",
        keyPhrases: ["dreams", "magic", "possibilities", "imagination"],
      ),
      Talk(
        title: "Journey through the realm of creativity",
        slug: "mock-5",
        details: "An epic adventure into the creative mind",
        mainSpeaker: "Phoenix Wright",
        url: "https://www.ted.com/talks/phoenix_wright_creativity_realm",
        keyPhrases: ["creativity", "adventure", "imagination", "innovation"],
      ),
    ];

    setState(() {
      _allTalks = mockTalks;
      _filteredTalks = mockTalks;
      _isLoading = false;
    });
  }

  void _filterTalks(String query) {
    setState(() {
      _currentSearchQuery = query;
      if (query.isEmpty) {
        _filteredTalks = _allTalks;
        _isTextSearching = false;
        _isTagSearching = false;
        _currentSearchTag = '';
      } else {
        _isTextSearching = true;
        _isTagSearching = false;
        _currentSearchTag = '';
        _filteredTalks = _allTalks.where((talk) {
          return talk.title.toLowerCase().contains(query.toLowerCase()) ||
              talk.mainSpeaker.toLowerCase().contains(query.toLowerCase()) ||
              talk.keyPhrases.any((phrase) =>
                  phrase.toLowerCase().contains(query.toLowerCase()));
        }).toList();
      }
    });
  }

  void _getTalksByTag() async {
    if (_controller.text.isEmpty) return;

    setState(() {
      _isLoading = true;
      _isTagSearching = true;
      _isTextSearching = false;
      _currentSearchTag = _controller.text;
    });

    try {
      final talks = await getTalksByTag(_controller.text, 1);
      setState(() {
        _filteredTalks = talks;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error searching talks: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _clearSearch() {
    _controller.clear();
    setState(() {
      _filteredTalks = _allTalks;
      _isTextSearching = false;
      _isTagSearching = false;
      _currentSearchQuery = '';
      _currentSearchTag = '';
    });
    FocusScope.of(context).unfocus();
  }

  void _goHome() {
    _controller.clear();
    setState(() {
      _filteredTalks = _allTalks;
      _isTextSearching = false;
      _isTagSearching = false;
      _currentSearchQuery = '';
      _currentSearchTag = '';
    });
    FocusScope.of(context).unfocus();
  }

  // Modified to refresh favorites when returning from FavoritesPage
  void _navigateToFavorites() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const FavoritesPage(),
      ),
    );
    // Refresh favorite status when returning from favorites page
    _loadFavoritesStatus();
  }

  bool get _isAnySearchActive => _isTextSearching || _isTagSearching;

  String get _getStatusText {
    if (_isTagSearching) {
      return "Magical results for \"${_currentSearchTag}\"";
    } else if (_isTextSearching) {
      return "Enchanted search results";
    } else {
      return "Explore amazing talks";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Enhanced App Bar with Search and Favorites Button
          SliverAppBar(
            expandedHeight: 140,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: Colors.red,
            actions: [
              // Favorites Button in AppBar (kept for consistency, but moved to action row)
              IconButton(
                onPressed: _navigateToFavorites,
                icon: const Icon(Icons.favorite),
                tooltip: 'My Favorites',
              ),
              if (_isAnySearchActive)
                IconButton(
                  onPressed: _goHome,
                  icon: const Icon(Icons.home),
                  tooltip: 'Return to Explore',
                ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                _isAnySearchActive ? 'Search Results' : 'MyTEDx Rewind',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.red.shade400,
                      Colors.red.shade700,
                    ],
                  ),
                ),
                child: Center(
                  child: Icon(
                    _isAnySearchActive ? Icons.search : Icons.auto_stories,
                    size: 60,
                    color: Colors.white.withOpacity(0.3),
                  ),
                ),
              ),
            ),
          ),

          // Search Bar Section
          SliverToBoxAdapter(
            child: AnimatedBuilder(
              animation: _searchScaleAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _searchScaleAnimation.value,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.red.withOpacity(0.1),
                                blurRadius: 20,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: _controller,
                            onChanged: _filterTalks,
                            decoration: InputDecoration(
                              hintText: 'Search magical talks, speakers, or mystical topics...',
                              hintStyle: TextStyle(color: Colors.grey.shade500),
                              prefixIcon: const Icon(Icons.search, color: Colors.red),
                              suffixIcon: _controller.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear, color: Colors.grey),
                                      onPressed: _clearSearch,
                                    )
                                  : null,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 16,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _getTalksByTag,
                                icon: const Icon(Icons.auto_awesome, size: 18),
                                label: const Text('Enchanted Search'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Favorites Button in the action row
                            ElevatedButton.icon(
                              onPressed: _navigateToFavorites,
                              icon: const Icon(Icons.favorite, size: 18),
                              label: const Text('Favorites'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.purple.shade600,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                              ),
                            ),
                            const SizedBox(width: 12),
                            if (_isAnySearchActive)
                              ElevatedButton.icon(
                                onPressed: _goHome,
                                icon: const Icon(Icons.explore, size: 18),
                                label: const Text('Explore'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange.shade600,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                ),
                              )
                            else
                              ElevatedButton.icon(
                                onPressed: _loadAllTalks,
                                icon: const Icon(Icons.refresh, size: 18),
                                label: const Text('Refresh'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.grey.shade600,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Stats Section with Fantasy Touch
          if (!_isLoading)
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _isAnySearchActive
                        ? [Colors.purple.shade50, Colors.purple.shade100]
                        : [Colors.red.shade50, Colors.red.shade100],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _isAnySearchActive
                        ? Colors.purple.shade200
                        : Colors.red.shade200,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _isAnySearchActive ? Icons.search : Icons.auto_stories,
                      color: _isAnySearchActive
                          ? Colors.purple.shade700
                          : Colors.red.shade700,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "${_filteredTalks.length} ${_isAnySearchActive ? 'enchanted' : 'magical'} talks ${_isAnySearchActive ? 'discovered' : 'awaiting'}",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: _isAnySearchActive
                                  ? Colors.purple.shade700
                                  : Colors.red.shade700,
                            ),
                          ),
                          Text(
                            _getStatusText,
                            style: TextStyle(
                              fontSize: 12,
                              color: _isAnySearchActive
                                  ? Colors.purple.shade600
                                  : Colors.red.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_isAnySearchActive)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.purple.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '✨ FILTERED',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.purple.shade700,
                          ),
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '🔮 EXPLORE',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange.shade700,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

          // Talks List
          if (_isLoading)
            const SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Colors.red),
                    SizedBox(height: 16),
                    Text(
                      '✨ Summoning amazing talks...',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else if (_filteredTalks.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _isAnySearchActive ? Icons.search_off : Icons.auto_stories_outlined,
                      size: 80,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _isAnySearchActive ? 'No magical talks found' : 'No talks in the realm',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isAnySearchActive
                          ? 'Try different mystical keywords or use Enchanted Search'
                          : 'Pull to refresh or check your magical connection',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                      ),
                    ),
                    if (_isAnySearchActive) ...[
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _goHome,
                        icon: const Icon(Icons.explore),
                        label: const Text('Return to Explore'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple.shade600,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final talk = _filteredTalks[index];
                  // Check if the current talk is a favorite
                  final isFavorite = _favoriteTalkSlugs.contains(talk.slug);

                  return FadeTransition(
                    opacity: _fadeAnimation,
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      child: Card(
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => TalkDetailPage(
                                  talkId: talk.slug,
                                  initialTalk: talk,
                                ),
                              ),
                            ).then((_) {
                              // When returning from TalkDetailPage, refresh favorites status
                              _loadFavoritesStatus();
                            });
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: _isAnySearchActive
                                          ? [Colors.purple.shade300, Colors.purple.shade500]
                                          : [Colors.red.shade300, Colors.red.shade500],
                                    ),
                                    borderRadius: BorderRadius.circular(25),
                                  ),
                                  child: Icon(
                                    _isAnySearchActive ? Icons.auto_awesome : Icons.play_arrow,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        talk.title,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.person,
                                            size: 14,
                                            color: Colors.grey.shade600,
                                          ),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              talk.mainSpeaker,
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.grey.shade600,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      if (talk.keyPhrases.isNotEmpty)
                                        Wrap(
                                          spacing: 6,
                                          runSpacing: 4,
                                          children: talk.keyPhrases
                                              .take(3)
                                              .map((phrase) => Container(
                                                    padding: const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 2,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: _isAnySearchActive
                                                          ? Colors.purple.shade100
                                                          : Colors.red.shade100,
                                                      borderRadius: BorderRadius.circular(10),
                                                    ),
                                                    child: Text(
                                                      phrase,
                                                      style: TextStyle(
                                                        fontSize: 10,
                                                        color: _isAnySearchActive
                                                            ? Colors.purple.shade700
                                                            : Colors.red.shade700,
                                                        fontWeight: FontWeight.w500,
                                                      ),
                                                    ),
                                                  ))
                                              .toList(),
                                        ),
                                    ],
                                  ),
                                ),
                                // Favorite Button
                                IconButton(
                                  icon: Icon(
                                    isFavorite ? Icons.favorite : Icons.favorite_border,
                                    color: isFavorite ? Colors.red : Colors.grey,
                                    size: 24,
                                  ),
                                  onPressed: () => _toggleFavorite(talk),
                                  tooltip: isFavorite ? 'Remove from Favorites' : 'Add to Favorites',
                                ),
                                Icon(
                                  Icons.arrow_forward_ios,
                                  size: 16,
                                  color: Colors.grey.shade400,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
                childCount: _filteredTalks.length,
              ),
            ),
        ],
      ),
    );
  }
}