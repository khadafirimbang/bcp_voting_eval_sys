class Post {
final int postId;
final int studentNo;
final String title;
final String description;
final String? image;
final String username;
final int likeCount;
final int dislikeCount;
final String? userInteraction;

Post({
  required this.postId,
  required this.studentNo,
  required this.title,
  required this.description,
  this.image,
  required this.username,
  required this.likeCount,
  required this.dislikeCount,
  this.userInteraction,
});

factory Post.fromJson(Map<String, dynamic> json) {
  return Post(
    postId: json['post_id'],
    studentNo: json['studentno'],
    title: json['title'],
    description: json['description'],
    image: json['image'],
    username: json['username'],
    likeCount: int.parse(json['like_count'].toString()),
    dislikeCount: int.parse(json['dislike_count'].toString()),
    userInteraction: json['user_interaction'],
  );
}
}