class UserDTO {
  final int? id;
  final String? manv;
  final String? email;
  final String? role;
  final bool? isActive;

  const UserDTO({
    this.id,
    this.manv,
    this.email,
    this.role,
    this.isActive,
  });

  factory UserDTO.fromJson(
    Map<String, dynamic> json,
  ) {
    final dynamic rawId =
        json['id'] ?? json['Id'];

    final dynamic rawIsActive =
        json['isActive'] ??
        json['IsActive'];

    return UserDTO(
      id: rawId is int
          ? rawId
          : int.tryParse(
              rawId?.toString() ?? '',
            ),
      manv:
          (json['manv'] ?? json['Manv'])
              ?.toString(),
      email:
          (json['email'] ?? json['Email'])
              ?.toString(),
      role:
          (json['role'] ?? json['Role'])
              ?.toString(),
      isActive: rawIsActive is bool
          ? rawIsActive
          : rawIsActive
                  ?.toString()
                  .toLowerCase() ==
              'true',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'manv': manv,
      'email': email,
      'role': role,
      'isActive': isActive,
    };
  }
}

class AuthData {
  final String? token;
  final String? refreshToken;
  final String? expiresAt;
  final UserDTO? user;

  const AuthData({
    this.token,
    this.refreshToken,
    this.expiresAt,
    this.user,
  });

  factory AuthData.fromJson(
    Map<String, dynamic> json,
  ) {
    final dynamic rawUser =
        json['userDTO'] ??
        json['userDto'] ??
        json['user'];

    UserDTO? parsedUser;

    if (rawUser is Map<String, dynamic>) {
      parsedUser =
          UserDTO.fromJson(rawUser);
    } else if (rawUser is Map) {
      parsedUser = UserDTO.fromJson(
        Map<String, dynamic>.from(rawUser),
      );
    }

    return AuthData(
      token:
          (json['accessToken'] ??
                  json['token'])
              ?.toString(),
      refreshToken:
          json['refreshToken']?.toString(),
      expiresAt:
          json['expiresAt']?.toString(),
      user: parsedUser,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'accessToken': token,
      'refreshToken': refreshToken,
      'expiresAt': expiresAt,
      'user': user?.toJson(),
    };
  }
}