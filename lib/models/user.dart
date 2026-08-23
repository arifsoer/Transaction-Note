class AppUser {
  final String uid;
  final String name;
  final String email;
  final String photoUrl;
  final DateTime createdAt;
  final int? periodStartDay;

  AppUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.photoUrl,
    required this.createdAt,
    this.periodStartDay,
  });

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      uid: map['uid'],
      name: map['name'],
      email: map['email'],
      photoUrl: map['photoUrl'],
      createdAt: map['createdAt'].toDate(),
      periodStartDay: map['periodStartDay'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'photoUrl': photoUrl,
      'createdAt': createdAt,
      if (periodStartDay != null) 'periodStartDay': periodStartDay,
    };
  }
}
