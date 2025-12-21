class LoginResponse {
  bool success;
  String? error;
  String? role;
  String? userId;
  String? userName; // <--- add this
  String? email;    // optional, useful for passing to dashboard
  String? phone;
  String? bloodGroup;
  String? allergies;
  String? profilePictureUrl;

  LoginResponse({
    required this.success,
    this.error,
    this.role,
    this.userId,
    this.userName,
    this.email,
    this.phone,
    this.bloodGroup,
    this.allergies,
    this.profilePictureUrl,
  });
}
