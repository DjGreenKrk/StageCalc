import '../domain/entities/project_models.dart';

abstract class ProjectRepository {
  Future<List<Project>> getProjects();

  Future<void> saveProject(Project project);
}
