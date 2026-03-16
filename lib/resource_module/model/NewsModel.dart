class BulletinResponse {
  final int status;
  final List<Bulletin> data;
  final String message;

  BulletinResponse({
    required this.status,
    required this.data,
    required this.message,
  });

  // Factory constructor to create a BulletinResponse from JSON
  factory BulletinResponse.fromJson(Map<String, dynamic> json) {
    return BulletinResponse(
      status: json['status'],
      data: List<Bulletin>.from(json['data'].map((x) => Bulletin.fromJson(x))),
      message: json['message'],
    );
  }

  // Method to convert BulletinResponse object to JSON
  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'data': List<dynamic>.from(data.map((x) => x.toJson())),
      'message': message,
    };
  }
}

class Bulletin {
  final int? id;
  final String? title;
  final String? content;
  final int? userId;
  final String? publishNow;
  final String? date;
  final String? time;
  final String? createdAt;
  final String? updatedAt;

  Bulletin({
    required this.id,
    required this.title,
    required this.content,
    required this.userId,
    required this.publishNow,
    required this.date,
    this.time,
    required this.createdAt,
    required this.updatedAt,
  });

  // Factory constructor to create a Bulletin from JSON
  factory Bulletin.fromJson(Map<String, dynamic> json) {
    return Bulletin(
      id: json['id'],
      title: json['title'],
      content: json['content'],
      userId: json['user_id'],
      publishNow: json['publish_now'],
      date: json['date'],
      time: json['time'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }

  // Method to convert Bulletin object to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'user_id': userId,
      'publish_now': publishNow,
      'date': date,
      'time': time,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}
