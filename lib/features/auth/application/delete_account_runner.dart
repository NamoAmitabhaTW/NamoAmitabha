// lib/features/auth/application/delete_account_runner.dart
import 'package:amitabha/storage/application/storage_cleaner.dart';
import '../data/firebase_auth_repository.dart';
import '../data/firestore_user_repository.dart';
import 'auth_facade.dart';
import 'delete_account_usecase.dart';

class DeleteAccountRunner {
  static Future<void> run() async {
    final facade = AuthFacade(
      auth: FirebaseAuthRepository(),
      users: FirestoreUserRepository(),
    );
    final cleaner = StorageCleaner();
    final usecase = DeleteAccountUseCase(auth: facade, cleaner: cleaner);
    await usecase.call();
  }
}