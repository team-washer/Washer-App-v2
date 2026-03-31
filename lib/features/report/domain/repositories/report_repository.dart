abstract class ReportRepository {
  Future<void> createMalfunctionReport({
    required int machineId,
    required String description,
  });
}
