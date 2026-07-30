import 'package:equatable/equatable.dart';

/// Entidad de dominio que representa a un Usuario del sistema.
class User extends Equatable {
  final int? id;
  final String username;
  final String passwordHash;
  final DateTime createdAt;

  const User({
    this.id,
    required this.username,
    required this.passwordHash,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, username, passwordHash, createdAt];
}
