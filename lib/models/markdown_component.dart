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

  static const String defaultTemplate = """*Double click to edit*:

# 7400 #

## Features ##
Quadruple 2-Input Positive-NAND Gates

|     |     |
| --- | --- |
| Number of channels | 4 |
| Inputs per channel | 2 |

## Documentation ##
[7400](https://www.ti.com/document-viewer/sn7400/datasheet)

##  Applications ##

## Description ##


## PIN Layout ##
![]()

## Truth Table ##
| A | B | Y |
|---|---|---|
| 0 | 0 | 1 |
""";

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json['text'] = text;
    return json;
  }
}
