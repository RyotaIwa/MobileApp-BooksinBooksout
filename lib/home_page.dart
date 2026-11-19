import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'book_api_controller.dart';
import 'book_firestore_controller.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final User? user = FirebaseAuth.instance.currentUser;

  int _selectedIndex = 0;
  final BookApiController _apiController = BookApiController();
  final BookFirestoreController _firestoreController =
      BookFirestoreController();
  List<BookActivity> _activity = [];
  bool _isLoadingActivity = true;
  String? _activityLoadError;

  @override
  void initState() {
    super.initState();
    _loadActivity();
  }

  Future<void> _loadActivity() async {
    setState(() {
      _isLoadingActivity = true;
      _activityLoadError = null;
    });

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw StateError('A signed-in user is required to load book data.');
      }
      await _firestoreController.ensureUserProfile(
        email: currentUser.email ?? '',
        displayName: currentUser.displayName,
      );
      final activities = await _firestoreController.getActivities();
      if (!mounted) return;
      setState(() {
        _activity = activities;
        _isLoadingActivity = false;
      });
    } catch (error) {
      debugPrint('Could not load book activities: $error');
      if (!mounted) return;
      setState(() {
        _activityLoadError = 'Could not load your books.';
        _isLoadingActivity = false;
      });
    }
  }

  void _openSection(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _recordBookAction(BookProduct product, String action) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$action book?'),
        content: Text(
          action == 'Buy'
              ? 'Add "${product.title}" to My Books?'
              : 'Add "${product.title}" to Rented Books?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Confirm $action'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      final activity = await _firestoreController.createActivity(
        product: product,
        action: action,
      );

      if (!mounted) return;

      setState(() {
        _activity.insert(0, activity);
      });

      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            action == 'Rent'
                ? 'Book added to Rented Books.'
                : 'Book added to My Books.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not add this book. Try again.')),
      );
      debugPrint('Could not create book action: $error');
    }
  }

  Future<void> _updateActivity(BookActivity entry) async {
    final isRental = entry.action == 'Rent';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isRental ? 'Stop renting?' : 'Mark as read?'),
        content: Text(
          isRental
              ? 'Return "${entry.product.title}" and move it to History?'
              : '"${entry.product.title}" will be moved to History.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(isRental ? 'Stop renting' : 'Mark as read'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final updatedStatus = entry.action == 'Rent' ? 'Returned' : 'Read';
    try {
      final updatedActivity = await _firestoreController.updateActivity(
        orderId: entry.orderId,
        collection: entry.collection,
        product: entry.product,
        action: entry.action,
        status: updatedStatus,
      );
      if (!mounted) return;

      setState(() {
        final index = _activity.indexOf(entry);
        if (index >= 0) {
          _activity[index] = updatedActivity;
        }
      });
      _showRequestMessage(
        entry.action == 'Rent' ? 'Book returned.' : 'Book marked as read.',
      );
    } catch (error) {
      _showRequestMessage('Could not update this book. Try again.');
      debugPrint('Could not update book action: $error');
    }
  }

  Future<void> _deleteActivity(BookActivity entry) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove book?'),
        content: Text('Remove "${entry.product.title}" from this list?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await _firestoreController.deleteActivity(
        orderId: entry.orderId,
        collection: entry.collection,
      );
      if (!mounted) return;
      setState(() {
        _activity.remove(entry);
      });
      _showRequestMessage('Book removed.');
    } catch (error) {
      _showRequestMessage('Could not remove this book. Try again.');
      debugPrint('Could not delete book action: $error');
    }
  }

  void _showRequestMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _buildShelf({
    required String title,
    required IconData icon,
    required List<BookActivity> entries,
    required String emptyMessage,
    required String actionLabel,
    bool showAction = true,
  }) {
    return _ContainedSection(
      title: title,
      icon: icon,
      child: Column(
        children: [
          if (_isLoadingActivity)
            const Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(),
            )
          else if (_activityLoadError != null)
            ListTile(
              leading: const Icon(Icons.cloud_off),
              title: Text(_activityLoadError!),
              trailing: IconButton(
                tooltip: 'Retry loading books',
                onPressed: _loadActivity,
                icon: const Icon(Icons.refresh),
              ),
            )
          else if (entries.isEmpty)
            ListTile(leading: Icon(icon), title: Text(emptyMessage))
          else
            ...entries.map(
              (entry) => ListTile(
                leading: Icon(
                  entry.action == 'Buy'
                      ? Icons.shopping_bag_outlined
                      : Icons.autorenew,
                ),
                title: Text(entry.product.title),
                subtitle: Text(
                  '${entry.action} · ${entry.product.author} · ${entry.status}',
                ),
                trailing: entry.action == 'Rent' && entry.status == 'Rented'
                    ? IconButton(
                        tooltip: 'Stop renting',
                        onPressed: () => _updateActivity(entry),
                        icon: const Icon(Icons.assignment_return_outlined),
                      )
                    : Wrap(
                        children: [
                          if (showAction)
                            IconButton(
                              tooltip: actionLabel,
                              onPressed: () => _updateActivity(entry),
                              icon: const Icon(Icons.check_circle_outline),
                            ),
                          IconButton(
                            tooltip: 'Remove book',
                            onPressed: () => _deleteActivity(entry),
                            icon: const Icon(Icons.delete_outline),
                          ),
                        ],
                      ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHistory() {
    return _buildShelf(
      title: 'History',
      icon: Icons.history,
      entries: _activity
          .where((entry) => entry.collection == 'reading_history')
          .toList(),
      emptyMessage: 'Books you buy or rent will appear here.',
      actionLabel: '',
      showAction: false,
    );
  }

  Widget _buildCatalog({
    required String title,
    required String description,
    required String initialQuery,
  }) {
    return BookSearchSection(
      key: ValueKey(_selectedIndex),
      title: title,
      description: description,
      initialQuery: initialQuery,
      apiController: _apiController,
      onAction: _recordBookAction,
    );
  }

  static const List<NavigationDrawerDestination> _destinations = [
    NavigationDrawerDestination(
      icon: Icon(Icons.dashboard_outlined),
      selectedIcon: Icon(Icons.dashboard),
      label: Text('Dashboard'),
    ),
    NavigationDrawerDestination(
      icon: Icon(Icons.menu_book_outlined),
      selectedIcon: Icon(Icons.menu_book),
      label: Text('Browse books'),
    ),
    NavigationDrawerDestination(
      icon: Icon(Icons.shopping_bag_outlined),
      selectedIcon: Icon(Icons.shopping_bag),
      label: Text('Buy books'),
    ),
    NavigationDrawerDestination(
      icon: Icon(Icons.autorenew_outlined),
      selectedIcon: Icon(Icons.autorenew),
      label: Text('Rent books'),
    ),
    NavigationDrawerDestination(
      icon: Icon(Icons.recommend_outlined),
      selectedIcon: Icon(Icons.recommend),
      label: Text('Recommendations'),
    ),
    NavigationDrawerDestination(
      icon: Icon(Icons.history),
      selectedIcon: Icon(Icons.history),
      label: Text('My Books'),
    ),
    NavigationDrawerDestination(
      icon: Icon(Icons.bookmark_border),
      selectedIcon: Icon(Icons.bookmark),
      label: Text('Rented Books'),
    ),
    NavigationDrawerDestination(
      icon: Icon(Icons.history_outlined),
      selectedIcon: Icon(Icons.history),
      label: Text('History'),
    ),
  ];

  String get _title {
    switch (_selectedIndex) {
      case 1:
        return 'Browse books';
      case 2:
        return 'Buy books';
      case 3:
        return 'Rent books';
      case 4:
        return 'Recommendations';
      case 5:
        return 'My Books';
      case 6:
        return 'Rented Books';
      case 7:
        return 'History';
      default:
        return 'Dashboard';
    }
  }

  Widget _buildContent() {
    // ========================================================
    // BROWSE BOOKS
    // ========================================================

    if (_selectedIndex == 1) {
      return _buildCatalog(
        title: 'Book collection',
        description: 'Search books from the online catalogue.',
        initialQuery: 'fiction',
      );
    }

    // ========================================================
    // BUY BOOKS
    // ========================================================

    if (_selectedIndex == 2) {
      return _buildCatalog(
        title: 'Books to buy',
        description: 'Explore books to add to your collection.',
        initialQuery: 'fiction',
      );
    }

    // ========================================================
    // RENT BOOKS
    // ========================================================

    if (_selectedIndex == 3) {
      return _buildCatalog(
        title: 'Books to rent',
        description: 'Find your next read to rent.',
        initialQuery: 'fiction',
      );
    }

    // ========================================================
    // RECOMMENDATIONS
    // ========================================================

    if (_selectedIndex == 4) {
      return _buildCatalog(
        title: 'Recommended for you',
        description: 'Discover popular books from the online catalog.',
        initialQuery: 'bestselling fiction',
      );
    }

    // ========================================================
    // MY BOOKS
    // ========================================================

    if (_selectedIndex == 5) {
      return _buildShelf(
        title: 'My Books',
        icon: Icons.menu_book,
        entries: _activity
            .where(
              (entry) => entry.action == 'Buy' && entry.status == 'To read',
            )
            .toList(),
        emptyMessage: 'Books you buy will be ready to read here.',
        actionLabel: 'Mark as read',
      );
    }

    if (_selectedIndex == 6) {
      return _buildShelf(
        title: 'Rented Books',
        icon: Icons.bookmark,
        entries: _activity
            .where(
              (entry) => entry.action == 'Rent' && entry.status == 'Rented',
            )
            .toList(),
        emptyMessage: 'Books you rent will appear here.',
        actionLabel: 'Return book',
      );
    }

    if (_selectedIndex == 7) {
      return _buildHistory();
    }

    // ========================================================
    // DASHBOARD
    // ========================================================

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Welcome back', style: Theme.of(context).textTheme.headlineMedium),

        const SizedBox(height: 8),

        Text(
          user?.email ?? 'Reader',
          style: Theme.of(context).textTheme.bodyLarge,
        ),

        const SizedBox(height: 24),

        Row(
          children: [
            Expanded(
              child: _ServiceCard(
                icon: Icons.autorenew,
                title: 'Rent a book',
                description: 'Read more for less.',
                onTap: () => _openSection(3),
              ),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: _ServiceCard(
                icon: Icons.shopping_bag,
                title: 'Buy a book',
                description: 'Own your next favourite read.',
                onTap: () => _openSection(2),
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        _ContainedSection(
          title: 'Recommended reading',
          icon: Icons.recommend,
          child: ListTile(
            onTap: () => _openSection(4),
            leading: const Icon(Icons.auto_stories),
            title: const Text('Popular picks for your next chapter'),
            subtitle: const Text('Explore book recommendations.'),
            trailing: const Icon(Icons.arrow_forward),
          ),
        ),

        const SizedBox(height: 20),

        _ContainedSection(
          title: 'Quick updates',
          icon: Icons.notifications_none,
          child: ListTile(
            onTap: () => _openSection(7),
            leading: const Icon(Icons.local_library_outlined),
            title: const Text('Your reading history'),
            subtitle: const Text('See books you have read or returned.'),
            trailing: const Icon(Icons.arrow_forward),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_title)),

      // ======================================================
      // NAVIGATION DRAWER
      // ======================================================
      drawer: NavigationDrawer(
        selectedIndex: _selectedIndex,

        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });

          Navigator.pop(context);
        },

        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 20, 16, 12),
            child: Text(
              'Bookin & Bookout',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),

          const Padding(
            padding: EdgeInsets.fromLTRB(28, 0, 16, 12),
            child: Text('Library products and services'),
          ),

          ..._destinations,

          const Divider(indent: 16, endIndent: 16),

          // ==================================================
          // SIGN OUT
          // ==================================================
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Sign out'),

            onTap: () async {
              Navigator.pop(context);

              await FirebaseAuth.instance.signOut();
            },
          ),
        ],
      ),

      // ======================================================
      // BODY
      // ======================================================
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: _buildContent(),
        ),
      ),

      // ======================================================
      // RENT BUTTON
      // ======================================================
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openSection(3),

        backgroundColor: Theme.of(context).colorScheme.primaryContainer,

        foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,

        icon: const Icon(Icons.autorenew),

        label: const Text('Rent a book'),

        tooltip: 'Rent a book',
      ),
    );
  }

  @override
  void dispose() {
    _apiController.close();
    super.dispose();
  }
}

// ==========================================================
// GOOGLE BOOKS SEARCH SECTION
// ==========================================================

class BookSearchSection extends StatefulWidget {
  final Future<List<BookProduct>> Function(String query)? loadProducts;
  final BookApiController? apiController;
  final String title;
  final String description;
  final String initialQuery;
  final Future<void> Function(BookProduct product, String action)? onAction;

  const BookSearchSection({
    super.key,
    this.loadProducts,
    this.apiController,
    this.title = 'Service Catalog',
    this.description = 'Browse books available to buy or rent.',
    this.initialQuery = 'fiction',
    this.onAction,
  });

  @override
  State<BookSearchSection> createState() => _BookSearchSectionState();
}

class _BookSearchSectionState extends State<BookSearchSection> {
  final TextEditingController _searchController = TextEditingController();
  late final BookApiController _apiController =
      widget.apiController ?? BookApiController();

  List<BookProduct> _products = [];

  bool _isLoading = false;

  String _errorMessage = '';

  String _filterQuery = '';

  List<BookProduct> get _filteredProducts =>
      _products.where((product) => product.matchesQuery(_filterQuery)).toList();

  @override
  void initState() {
    super.initState();

    // Automatically show books when Browse Books opens.
    _searchBooks(widget.initialQuery);
  }

  // ========================================================
  // SEARCH GOOGLE BOOKS
  // ========================================================

  Future<void> _searchBooks(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _filterQuery = '';
      });
      return;
    }

    FocusManager.instance.primaryFocus?.unfocus();

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final results = widget.loadProducts != null
          ? await widget.loadProducts!(query)
          : await _apiController.getBooks(query);

      if (!mounted) return;

      setState(() {
        _products = results;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _products = [];
        _isLoading = false;
        _errorMessage =
            'We could not load books. Check your connection and try again.';
      });
      debugPrint('Could not load catalog: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        // ====================================================
        // TITLE
        // ====================================================
        Text(widget.title, style: Theme.of(context).textTheme.headlineSmall),

        const SizedBox(height: 8),

        Text(widget.description, style: Theme.of(context).textTheme.bodyMedium),

        const SizedBox(height: 20),

        // ====================================================
        // SEARCH BAR
        // ====================================================
        TextField(
          controller: _searchController,

          textInputAction: TextInputAction.search,
          onChanged: (value) {
            setState(() {
              _filterQuery = value;
            });
          },

          onSubmitted: (value) {
            _searchBooks(value);
          },

          decoration: InputDecoration(
            hintText: 'Filter or search the catalog...',

            prefixIcon: const Icon(Icons.search),

            suffixIcon: IconButton(
              icon: const Icon(Icons.arrow_forward),

              onPressed: () {
                _searchBooks(_searchController.text);
              },
            ),

            filled: true,

            fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,

            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),

              borderSide: BorderSide.none,
            ),
          ),
        ),

        const SizedBox(height: 20),

        // ====================================================
        // LOADING
        // ====================================================
        if (_isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(30),

              child: CircularProgressIndicator(),
            ),
          )
        // ====================================================
        // ERROR
        // ====================================================
        else if (_errorMessage.isNotEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(20),

              child: Column(
                children: [
                  const Icon(Icons.cloud_off, size: 50),

                  const SizedBox(height: 10),

                  Text(_errorMessage, textAlign: TextAlign.center),

                  const SizedBox(height: 10),

                  FilledButton.icon(
                    onPressed: () {
                      _searchBooks(
                        _searchController.text.isEmpty
                            ? 'fiction'
                            : _searchController.text,
                      );
                    },

                    icon: const Icon(Icons.refresh),

                    label: const Text('Try again'),
                  ),
                ],
              ),
            ),
          )
        // ====================================================
        // NO BOOKS
        // ====================================================
        else if (_products.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(30),

              child: Text('No books found.'),
            ),
          )
        // ====================================================
        // PRODUCT RESULTS
        // ====================================================
        else
          _filteredProducts.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(30),
                  child: Center(child: Text('No matching products found.')),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        '${_filteredProducts.length} catalog '
                        '${_filteredProducts.length == 1 ? 'product' : 'products'}',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                    ),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _filteredProducts.length,
                      itemBuilder: (context, index) => BookCard(
                        product: _filteredProducts[index],
                        onAction: widget.onAction,
                      ),
                    ),
                  ],
                ),
      ],
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    if (widget.apiController == null) _apiController.close();

    super.dispose();
  }
}

// ==========================================================
// BOOK CARD
// ==========================================================

class BookCard extends StatelessWidget {
  final BookProduct product;
  final Future<void> Function(BookProduct product, String action)? onAction;

  const BookCard({super.key, required this.product, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),

      clipBehavior: Clip.antiAlias,

      child: InkWell(
        onTap: () {
          Navigator.push(
            context,

            MaterialPageRoute(
              builder: (context) => BookDetailsPage(
                title: product.title,
                author: product.author,
                description: product.description,
                imageUrl: product.imageUrl,
                onAction: onAction == null
                    ? null
                    : (action) => onAction!(product, action),
              ),
            ),
          );
        },

        child: Padding(
          padding: const EdgeInsets.all(12),

          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              // =================================================
              // BOOK COVER
              // =================================================
              ClipRRect(
                borderRadius: BorderRadius.circular(8),

                child: product.imageUrl != null
                    ? Image.network(
                        product.imageUrl!,

                        width: 90,
                        height: 130,

                        fit: BoxFit.cover,

                        errorBuilder: (context, error, stackTrace) {
                          return _BookPlaceholder(width: 90, height: 130);
                        },
                      )
                    : _BookPlaceholder(width: 90, height: 130),
              ),

              const SizedBox(width: 14),

              // =================================================
              // INFORMATION
              // =================================================
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    // TITLE
                    Text(
                      product.title,

                      maxLines: 2,

                      overflow: TextOverflow.ellipsis,

                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 6),

                    // AUTHOR
                    Text(
                      product.author,

                      maxLines: 2,

                      overflow: TextOverflow.ellipsis,

                      style: TextStyle(color: Colors.grey[700]),
                    ),

                    const SizedBox(height: 8),

                    // DESCRIPTION
                    Text(
                      product.description,

                      maxLines: 4,

                      overflow: TextOverflow.ellipsis,

                      style: TextStyle(color: Colors.grey[600], height: 1.3),
                    ),

                    const SizedBox(height: 8),

                    // DETAILS
                    Text(
                      'View Details →',

                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,

                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================================
// BOOK DETAILS PAGE
// ==========================================================

class BookDetailsPage extends StatelessWidget {
  final String title;
  final String author;
  final String description;
  final String? imageUrl;
  final Future<void> Function(String action)? onAction;

  const BookDetailsPage({
    super.key,
    required this.title,
    required this.author,
    required this.description,
    this.imageUrl,
    this.onAction,
  });

  Future<void> _performAction(BuildContext context, String action) async {
    final handler = onAction;
    if (handler == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Open the catalog from your account to $action books.'),
        ),
      );
      return;
    }

    await handler(action);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Book Details')),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,

          children: [
            // =================================================
            // COVER
            // =================================================
            if (imageUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),

                child: Image.network(
                  imageUrl!,

                  width: 180,
                  height: 260,

                  fit: BoxFit.cover,

                  errorBuilder: (context, error, stackTrace) {
                    return const _BookPlaceholder(width: 180, height: 260);
                  },
                ),
              )
            else
              const _BookPlaceholder(width: 180, height: 260),

            const SizedBox(height: 20),

            // =================================================
            // TITLE
            // =================================================
            Text(
              title,

              textAlign: TextAlign.center,

              style: const TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 8),

            // =================================================
            // AUTHOR
            // =================================================
            Text(
              'by $author',

              textAlign: TextAlign.center,

              style: TextStyle(fontSize: 16, color: Colors.grey[700]),
            ),

            const SizedBox(height: 25),

            // =================================================
            // DESCRIPTION
            // =================================================
            const Align(
              alignment: Alignment.centerLeft,

              child: Text(
                'Description',

                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),

            const SizedBox(height: 10),

            Align(
              alignment: Alignment.centerLeft,

              child: Text(
                description,

                style: const TextStyle(fontSize: 15, height: 1.5),
              ),
            ),

            const SizedBox(height: 30),

            // =================================================
            // RENT
            // =================================================
            SizedBox(
              width: double.infinity,

              child: ElevatedButton.icon(
                onPressed: () => _performAction(context, 'Rent'),

                icon: const Icon(Icons.autorenew),

                label: const Text('Rent Book'),
              ),
            ),

            const SizedBox(height: 10),

            // =================================================
            // BUY
            // =================================================
            SizedBox(
              width: double.infinity,

              child: OutlinedButton.icon(
                onPressed: () => _performAction(context, 'Buy'),

                icon: const Icon(Icons.shopping_bag),

                label: const Text('Buy Book'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================================
// BOOK IMAGE PLACEHOLDER
// ==========================================================

class _BookPlaceholder extends StatelessWidget {
  final double width;
  final double height;

  const _BookPlaceholder({required this.width, required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,

      color: Colors.deepPurple.shade100,

      child: const Icon(Icons.menu_book, size: 45, color: Colors.deepPurple),
    );
  }
}

// ==========================================================
// SERVICE CARD
// ==========================================================

class _ServiceCard extends StatelessWidget {
  const _ServiceCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,

      child: InkWell(
        onTap: onTap,

        child: Padding(
          padding: const EdgeInsets.all(16),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              Icon(icon, color: Theme.of(context).colorScheme.primary),

              const SizedBox(height: 16),

              Text(title, style: Theme.of(context).textTheme.titleMedium),

              const SizedBox(height: 6),

              Text(description),
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================================
// CONTAINED SECTION
// ==========================================================

class _ContainedSection extends StatelessWidget {
  const _ContainedSection({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),

            child: Row(
              children: [
                Icon(icon, color: Theme.of(context).colorScheme.primary),

                const SizedBox(width: 12),

                Text(title, style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
          ),

          child,
        ],
      ),
    );
  }
}
