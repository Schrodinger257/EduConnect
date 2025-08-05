import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/search_service.dart';
import '../widgets/post.dart';
import '../widgets/course.dart';
import '../widgets/search_user_card.dart';
import '../widgets/highlighted_text.dart';
import '../modules/post.dart';
import '../modules/course.dart';
import '../modules/user.dart';
import '../screens/course_item_screen.dart';
import '../screens/comments_screen.dart';

class SearchResultsWidget extends ConsumerWidget {
  final SearchResults results;
  final VoidCallback onRetry;

  const SearchResultsWidget({
    super.key,
    required this.results,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (results.isEmpty) {
      return _buildEmptyResults(context);
    }

    return RefreshIndicator(
      onRefresh: () async => onRetry(),
      color: Theme.of(context).primaryColor,
      child: CustomScrollView(
        slivers: [
          if (results.posts.isNotEmpty) ...[
            _buildSectionHeader(context, 'Posts', results.posts.length),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _buildPostCard(context, results.posts[index]),
                childCount: results.posts.length,
              ),
            ),
          ],
          if (results.courses.isNotEmpty) ...[
            _buildSectionHeader(context, 'Courses', results.courses.length),
            SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.75,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) => _buildCourseCard(context, results.courses[index]),
                childCount: results.courses.length,
              ),
            ),
          ],
          if (results.users.isNotEmpty) ...[
            _buildSectionHeader(context, 'Users', results.users.length),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => SearchUserCard(
                  user: results.users[index],
                  query: results.query,
                ),
                childCount: results.users.length,
              ),
            ),
          ],
          // Add some bottom padding
          const SliverToBoxAdapter(
            child: SizedBox(height: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, int count) {
    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
        child: Row(
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).shadowColor,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPostCard(BuildContext context, Post post) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          // Navigate to post comments
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => StreamCommentsScreen(post: post),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Post content with highlighting
              HighlightedText(
                text: post.content,
                query: results.query,
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).shadowColor,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              
              // Tags with highlighting
              if (post.hasTags)
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: post.tags.map((tag) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: HighlightedText(
                      text: tag,
                      query: results.query,
                      style: TextStyle(
                        fontSize: 10,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  )).toList(),
                ),
              
              const SizedBox(height: 12),
              
              // Post stats
              Row(
                children: [
                  Icon(
                    Icons.thumb_up_outlined,
                    size: 16,
                    color: Theme.of(context).shadowColor.withOpacity(0.6),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${post.likeCount}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).shadowColor.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    Icons.comment_outlined,
                    size: 16,
                    color: Theme.of(context).shadowColor.withOpacity(0.6),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${post.commentCount}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).shadowColor.withOpacity(0.6),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    post.formattedTimestamp,
                    style: TextStyle(
                      fontSize: 10,
                      color: Theme.of(context).shadowColor.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCourseCard(BuildContext context, Course course) {
    return Card(
      margin: const EdgeInsets.all(4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          // Navigate to course details
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => CourseItemScreen(courseId: course.id),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  color: Theme.of(context).shadowColor.withOpacity(0.1),
                  image: course.hasImage
                      ? DecorationImage(
                          image: NetworkImage(course.imageUrl!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: !course.hasImage
                    ? Icon(
                        Icons.school,
                        size: 40,
                        color: Theme.of(context).shadowColor.withOpacity(0.3),
                      )
                    : null,
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Course title with highlighting
                    HighlightedText(
                      text: course.title,
                      query: results.query,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Theme.of(context).shadowColor,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    
                    // Course description with highlighting
                    HighlightedText(
                      text: course.descriptionPreview,
                      query: results.query,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).shadowColor.withOpacity(0.7),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Icon(
                          Icons.people,
                          size: 12,
                          color: Theme.of(context).primaryColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${course.enrolledStudents.length}',
                          style: TextStyle(
                            fontSize: 10,
                            color: Theme.of(context).primaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyResults(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Theme.of(context).shadowColor.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No Results Found',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).shadowColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your search terms or filters',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).shadowColor.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}