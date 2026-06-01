import '../../../../core/errors/result.dart';
import '../entities/property.dart';

abstract class PropertyRepository {
  Stream<List<Property>> watchProperties();
  Future<Result<Property>> getProperty(String id);
  Future<Result<Property>> createProperty(Property property);
  Future<Result<Property>> updateProperty(Property property);
  Future<Result<void>> deleteProperty(String id);
}
