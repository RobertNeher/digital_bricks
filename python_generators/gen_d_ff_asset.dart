import 'dart:convert';
import 'dart:io';

void main() {
  final components = [
    {
      "id": "in-d",
      "name": "D",
      "type": 12,
      "position_dx": 100.0,
      "position_dy": 100.0,
      "inputs": [],
      "outputs": [{"id": "in-d-out-0", "componentId": "in-d", "type": 1, "value": false}],
      "label": "D"
    },
    {
      "id": "in-clk",
      "name": "CLK",
      "type": 12,
      "position_dx": 100.0,
      "position_dy": 150.0,
      "inputs": [],
      "outputs": [{"id": "in-clk-out-0", "componentId": "in-clk", "type": 1, "value": false}],
      "label": "CLK"
    },
    {
      "id": "ff-0",
      "name": "D-FF",
      "type": 17, // dFlipFlop index
      "position_dx": 300.0,
      "position_dy": 100.0,
      "inputs": [
        {"id": "ff-0-in-0", "componentId": "ff-0", "type": 0, "label": "D", "value": false},
        {"id": "ff-0-in-1", "componentId": "ff-0", "type": 0, "label": ">", "value": false}
      ],
      "outputs": [
        {"id": "ff-0-out-0", "componentId": "ff-0", "type": 1, "label": "Q", "value": false},
        {"id": "ff-0-out-1", "componentId": "ff-0", "type": 1, "label": "Q̅", "value": false}
      ]
    },
    {
      "id": "out-q",
      "name": "Q",
      "type": 13,
      "position_dx": 500.0,
      "position_dy": 100.0,
      "inputs": [{"id": "out-q-in-0", "componentId": "out-q", "type": 0, "value": false}],
      "outputs": [],
      "label": "Q"
    },
    {
      "id": "out-qbar",
      "name": "/Q",
      "type": 13,
      "position_dx": 500.0,
      "position_dy": 150.0,
      "inputs": [{"id": "out-qbar-in-0", "componentId": "out-qbar", "type": 0, "value": false}],
      "outputs": [],
      "label": "/Q"
    }
  ];

  final connections = [
    {"id": "c1", "sourcePinId": "in-d-out-0", "targetPinId": "ff-0-in-0"},
    {"id": "c2", "sourcePinId": "in-clk-out-0", "targetPinId": "ff-0-in-1"},
    {"id": "c3", "sourcePinId": "ff-0-out-0", "targetPinId": "out-q-in-0"},
    {"id": "c4", "sourcePinId": "ff-0-out-1", "targetPinId": "out-qbar-in-0"}
  ];

  final data = {
    "components": components,
    "connections": connections
  };

  File('assets/D Flip Flop.json').writeAsStringSync(jsonEncode(data));
  print("Created assets/D Flip Flop.json");
}
