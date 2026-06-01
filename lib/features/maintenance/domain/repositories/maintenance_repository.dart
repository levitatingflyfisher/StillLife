import '../../../../core/errors/result.dart';
import '../entities/maintenance_log.dart';

abstract class MaintenanceRepository {
  Stream<List<MaintenanceLog>> watchAll();
  Stream<List<MaintenanceLog>> watchByItem(String itemId);
  Future<Result<List<MaintenanceLog>>> getUpcoming();
  Future<Result<MaintenanceLog>> create(MaintenanceLog log);
  Future<Result<MaintenanceLog>> update(MaintenanceLog log);
  Future<Result<void>> delete(String id);
}
