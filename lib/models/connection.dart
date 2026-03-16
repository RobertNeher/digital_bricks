class Connection {
  final String id;
  final String sourcePinId;
  final String targetPinId;

  Connection({
    required this.id,
    required this.sourcePinId,
    required this.targetPinId,
  });

  Map<String, dynamic> toJson() {
    return {'id': id, 'sourcePinId': sourcePinId, 'targetPinId': targetPinId};
  }

  factory Connection.fromJson(Map<String, dynamic> json) {
    return Connection(
      id: json['id'],
      sourcePinId: json['sourcePinId'],
      targetPinId: json['targetPinId'],
    );
  }
}
