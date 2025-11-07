import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_maps/maps.dart';

class WorldMap extends StatelessWidget {
  final List<Map<String, dynamic>> data;
  const WorldMap({super.key, required this.data});

  // Sample risk data for demonstration
  static final List<Map<String, dynamic>> sampleData = [
    {"code": "USA", "name": "United States", "risk": 25}, // Low risk (green)
    {"code": "CHN", "name": "China", "risk": 45}, // Medium risk (yellow)
    {"code": "RUS", "name": "Russia", "risk": 75}, // High risk (red)
    {"code": "GBR", "name": "United Kingdom", "risk": 30},
    {"code": "DEU", "name": "Germany", "risk": 20},
    {"code": "IND", "name": "India", "risk": 55},
  ];

  @override
  Widget build(BuildContext context) {
    // Use provided data or fall back to sample data if empty
    final mapData = data.isEmpty ? sampleData : data;
    final MapShapeSource dataSource = MapShapeSource.asset(
      'world_map.json',
      shapeDataField: 'ISO_A3',
      dataCount: mapData.length,
      primaryValueMapper: (int index) => mapData[index]['code'],
      shapeColorValueMapper: (int index) => mapData[index]['risk'],
      shapeColorMappers: const <MapColorMapper>[
        MapColorMapper(from: 0, to: 30, color: Colors.green, text: 'Low'),
        MapColorMapper(from: 31, to: 60, color: Colors.orange, text: 'Medium'),
        MapColorMapper(from: 61, to: 100, color: Colors.red, text: 'High'),
      ],
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SfMaps(
        layers: <MapLayer>[
          MapShapeLayer(
            source: dataSource,
            strokeColor: Colors.white,
            strokeWidth: 0.5,
            legend: const MapLegend(MapElement.shape),
            shapeTooltipBuilder: (BuildContext context, int index) {
              final mapItem = mapData[index];
              return Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  "${mapItem['name']} (Risk: ${mapItem['risk']})",
                  style: const TextStyle(color: Colors.black),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
