import 'package:flutter/material.dart';

/// Entry point of the application.
void main() {
  runApp(const MyApp());
}

/// [Widget] building the [MaterialApp].
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Dock(
                iconDataStringMap: const {
                  "Contacts": Icons.person,
                  "Messages": Icons.message,
                  "Call": Icons.call,
                  "Camera": Icons.camera,
                  "Gallery": Icons.photo,
                },
                builder: (iconData, iconName) {
                  return GestureDetector(
                    onTap: () {
                      debugPrint(iconName);
                    },
                    child: Container(
                      constraints: const BoxConstraints(minWidth: 48),
                      height: 48,
                      margin: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.primaries[
                            iconData.hashCode % Colors.primaries.length],
                      ),
                      child: Center(
                        child: Icon(iconData, color: Colors.white),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class Dock extends StatefulWidget {
  const Dock({
    super.key,
    required this.builder,
    required this.iconDataStringMap,
  });

  final Widget Function(IconData, String) builder;
  final Map<String, IconData> iconDataStringMap;

  @override
  State<Dock> createState() => _DockState();
}

class _DockState extends State<Dock> with TickerProviderStateMixin {
  bool _isDragging = false;
  String? _draggingIconName;
  late List<MapEntry<String, IconData>> _items;
  late List<AnimationController> _scaleControllers;
  late List<Animation<double>> _scaleAnimations;

  Offset _tooltipOffset = Offset.zero;

  @override
  void initState() {
    super.initState();
    _items = widget.iconDataStringMap.entries.toList();
    _scaleControllers = List.generate(
      _items.length,
      (index) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 300),
      ),
    );

    _scaleAnimations = _scaleControllers
        .map(
          (controller) => Tween<double>(begin: 1.0, end: 1.2).animate(
            CurvedAnimation(parent: controller, curve: Curves.easeInOut),
          ),
        )
        .toList();
  }

  @override
  void dispose() {
    for (var controller in _scaleControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: Colors.black12,
          ),
          padding: const EdgeInsets.all(4),
          width: _isDragging ? 270 : 330,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: _items
                  .asMap()
                  .map((index, entry) {
                    return MapEntry(
                      index,
                      Draggable<IconData>(
                        data: entry.value,
                        feedback: Material(
                          color: Colors.transparent,
                          child: Transform.scale(
                            scale: 1.2,
                            child: widget.builder(entry.value, entry.key),
                          ),
                        ),
                        childWhenDragging: const Opacity(opacity: 0.3),
                        child: MouseRegion(
                          onEnter: (_) {
                            if (!_isDragging) {
                              _scaleControllers[index].forward();
                            }
                          },
                          onExit: (_) {
                            if (!_isDragging) {
                              _scaleControllers[index].reverse();
                            }
                          },
                          child: _isDragging
                              ? widget.builder(entry.value, entry.key)
                              : Row(
                                  children: [
                                    Tooltip(
                                      preferBelow: false,
                                      message: entry.key,
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade700,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                            color: Colors.white, width: 2),
                                      ),
                                      child: AnimatedBuilder(
                                        animation: _scaleAnimations[index],
                                        builder: (context, child) {
                                          return Transform.scale(
                                            scale:
                                                _scaleAnimations[index].value,
                                            child: widget.builder(
                                                entry.value, entry.key),
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                        onDragStarted: () {
                          setState(() {
                            _isDragging = true;
                            _draggingIconName = entry.key;
                          });
                        },
                        onDragUpdate: (details) {
                          setState(() {
                            _tooltipOffset = details.globalPosition;
                          });
                        },
                        onDragEnd: (details) {
                          setState(() {
                            _isDragging = false;
                            _draggingIconName = null;

                            final RenderBox renderBox =
                                context.findRenderObject() as RenderBox;
                            final position =
                                renderBox.localToGlobal(Offset.zero);
                            final dropPosition =
                                details.offset.dx - position.dx;

                            int indexToInsert = 0;
                            double minDistance = double.infinity;
                            for (int i = 0; i < _items.length; i++) {
                              const itemWidth = 48.0;
                              final itemOffset = i * (itemWidth + 16.0);

                              final distance =
                                  (dropPosition - itemOffset).abs();
                              if (distance < minDistance) {
                                minDistance = distance;
                                indexToInsert =
                                    i + (dropPosition > itemOffset ? 1 : 0);
                              }
                            }
                            _items.insert(indexToInsert,
                                _items.removeAt(_items.indexOf(entry)));
                          });
                        },
                      ),
                    );
                  })
                  .values
                  .toList(),
            ),
          ),
        ),
      ],
    );
  }
}
