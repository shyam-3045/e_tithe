class UserData {
  const UserData({
    required this.userTypeID,
    required this.userTypeName,
    required this.userID,
    required this.userName,
    required this.regionID,
    required this.regionName,
  });

  factory UserData.fromJson(Map<String, dynamic> json) {
    return UserData(
      userTypeID: json['userTypeID'] as int? ?? 0,
      userTypeName: json['userTypeName'] as String? ?? '',
      userID: json['userID'] as int? ?? 0,
      userName: json['userName'] as String? ?? '',
      regionID: json['regionID'] as int? ?? 0,
      regionName: json['regionName'] as String? ?? '',
    );
  }

  final int userTypeID;
  final String userTypeName;
  final int userID;
  final String userName;
  final int regionID;
  final String regionName;

  Map<String, dynamic> toJson() {
    return {
      'userTypeID': userTypeID,
      'userTypeName': userTypeName,
      'userID': userID,
      'userName': userName,
      'regionID': regionID,
      'regionName': regionName,
    };
  }
}
