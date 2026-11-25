class AuthResponse {
  const AuthResponse({
    required this.token,
    required this.email,
    this.nombre,
  });

  final String token;
  final String email;
  final String? nombre;

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      token: json['token'] as String,
      email: json['email'] as String,
      nombre: json['nombre'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'token': token,
      'email': email,
      'nombre': nombre,
    };
  }
}
