class Workspace {
  final String id;
  final String name;
  final String role;

  const Workspace({required this.id, required this.name, required this.role});

  factory Workspace.fromJson(Map<String, dynamic> json) => Workspace(
    id: json['_id'] ?? json['id'] ?? '',
    name: json['name'] ?? 'Workspace',
    role: json['role'] ?? 'member',
  );
}
