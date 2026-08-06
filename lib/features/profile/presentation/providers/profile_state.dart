import 'package:equatable/equatable.dart';

import '../../domain/entities/profile_entity.dart';

enum ProfileStatus { initial, loading, loaded, failure }

/// Immutable state for the profile page and its mutations.
class ProfileState extends Equatable {
  const ProfileState._({
    required this.status,
    this.profile,
    this.errorMessage,
    this.isMutating = false,
  });

  const ProfileState.initial() : this._(status: ProfileStatus.initial);

  const ProfileState.loading() : this._(status: ProfileStatus.loading);

  const ProfileState.loaded(ProfileEntity profile, {bool isMutating = false})
    : this._(
        status: ProfileStatus.loaded,
        profile: profile,
        isMutating: isMutating,
      );

  const ProfileState.failure(String message, {ProfileEntity? profile})
    : this._(
        status: ProfileStatus.failure,
        errorMessage: message,
        profile: profile,
      );

  final ProfileStatus status;
  final ProfileEntity? profile;
  final String? errorMessage;

  /// True while an update/upload request is in flight.
  final bool isMutating;

  @override
  List<Object?> get props => [status, profile, errorMessage, isMutating];
}
