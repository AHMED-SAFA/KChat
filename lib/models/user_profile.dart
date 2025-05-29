class UserProfile {
  String? name;
  String? profileImageUrl;
  String? userId;

  UserProfile({
    required this.name,
    required this.userId,
    required this.profileImageUrl,
  });

  UserProfile.fromJson(Map<String, dynamic> json) {
    profileImageUrl = json['profileImageUrl'];
    userId = json['userId'];
    name = json['name'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['name'] = name;
    data['proImageUrl'] = profileImageUrl;
    data['uId'] = userId;
    return data;
  }
}
