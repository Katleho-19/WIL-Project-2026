class DocumentRequest {
  const DocumentRequest({required this.type, required this.status});

  final String type; // 'Proof of Payment', 'Birth Certificate', ...
  final String status; // Requested | Submitted | Cancelled

  bool get isOpen => status == 'Requested';

  factory DocumentRequest.fromMap(Map<String, dynamic> m) => DocumentRequest(
    type: (m['document_type'] ?? '') as String,
    status: (m['status'] ?? 'Requested') as String,
  );
}
