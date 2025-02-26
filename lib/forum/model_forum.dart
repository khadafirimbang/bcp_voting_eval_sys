class Forum {
  final int id;
  final String title;
  final String content;
  final String authorName;
  final DateTime createdAt;
  final int totalLikes;
  final int totalDislikes;
  final String authorStudentNo;

  Forum({
    required this.id,
    required this.title,
    required this.content,
    required this.authorName,
    required this.createdAt,
    this.totalLikes = 0,
    this.totalDislikes = 0,
    required this.authorStudentNo
  });

  factory Forum.fromJson(Map<String, dynamic> json) {
    return Forum(
      id: json['id'],
      title: json['title'],
      content: json['content'],
      authorName: '${json['firstname']} ${json['lastname']}',
      createdAt: DateTime.parse(json['created_at']),
      totalLikes: json['total_likes'] ?? 0,
      totalDislikes: json['total_dislikes'] ?? 0,
      authorStudentNo: json['studentno'].toString(),
    );
  }
}

class Comment {
  final int id;
  final int forumId;
  final String studentNo;
  final String content;
  final String authorName;
  final DateTime createdAt;

  Comment({
    required this.id,
    required this.forumId,
    required this.studentNo,
    required this.content,
    required this.authorName,
    required this.createdAt,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      forumId: int.tryParse(json['forum_id']?.toString() ?? '0') ?? 0,
      studentNo: json['studentno']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      authorName: _formatAuthorName(json),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  // Helper method to handle name formatting
  static String _formatAuthorName(Map<String, dynamic> json) {
    // If full name is not available, fall back to studentno
    String authorName = json['author_name']?.toString() ?? json['studentno']?.toString() ?? '';
    
    // Optional: Capitalize each word
    return authorName.split(' ')
        .map((word) => word.isNotEmpty 
            ? word[0].toUpperCase() + word.substring(1).toLowerCase() 
            : '')
        .join(' ')
        .trim();
  }
}

