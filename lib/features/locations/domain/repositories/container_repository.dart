import '../../../../core/errors/result.dart';
import '../entities/storage_container.dart';

abstract class ContainerRepository {
  Stream<List<StorageContainer>> watchContainers({required String roomId});
  Stream<List<StorageContainer>> watchAllContainers();
  Future<Result<StorageContainer>> getContainer(String id);
  Stream<StorageContainer?> watchContainer(String id);
  Future<Result<StorageContainer>> createContainer(StorageContainer container);
  Future<Result<void>> deleteContainer(String id);
}
