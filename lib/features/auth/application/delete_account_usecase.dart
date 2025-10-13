/* // lib/features/auth/application/delete_account_usecase.dart
import 'package:amitabha/storage/application/storage_cleaner.dart';
import 'auth_facade.dart';

class DeleteAccountUseCase {
  final AuthFacade _auth;
  final StorageCleaner _cleaner;

  DeleteAccountUseCase({required AuthFacade auth, required StorageCleaner cleaner})
      : _auth = auth,
        _cleaner = cleaner;

  Future<void> call() async {
    await _auth.deleteAccountAndData();          
    await _cleaner.purgeAllLocal(keepModels: true); 
  }
} */