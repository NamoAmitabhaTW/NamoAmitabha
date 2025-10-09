enum AuthError {
  network,   
  cancelled, 
  failed,    
}

class AuthException implements Exception {
  final AuthError code;
  final String? message; 
  const AuthException(this.code, [this.message]);

  @override
  String toString() => 'AuthException($code, $message)';
}