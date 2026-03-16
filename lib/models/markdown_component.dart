import 'logic_component.dart';

class MarkdownComponent extends LogicComponent {
  String text;
  bool isEditing = false;

  MarkdownComponent({
    super.id,
    required super.position,
    this.text = "",
  }) : super(name: 'MD', type: ComponentType.markdownText);

  @override
  void evaluate() {
    // Passive
  }

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json['text'] = text;
    return json;
  }
}
