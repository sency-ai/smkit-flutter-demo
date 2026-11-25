import 'package:flutter_smkit/smkit.dart';

/// Message to show for an error thrown by flutter_smkit (or anything else).
String smkitErrorText(Object error) {
  return switch (error) {
    AuthKeyNotAcceptedException(:final message) =>
      'SMKit did not accept the auth key${message == null ? '.' : ': $message'}\n'
          'Check SMKIT_AUTH_KEY in AuthKey.local.properties.',
    SmKitNotConfiguredException() =>
      'SMKit is not configured yet. Wait for configuration to finish.',
    UnableToStartCameraException(:final message) =>
      'The camera could not be started${message == null ? '.' : ': $message'}',
    SmKitSessionError(:final message, :final code) => message ?? code,
    _ => '$error',
  };
}
