// Copyright 2013 The Flutter Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of '../google_maps_flutter_web.dart';

/// The `PolygonController` class wraps a [gmaps.Polygon] and its `onTap` behavior.
class PolygonController {
  /// Creates a `PolygonController` that wraps a [gmaps.Polygon] object and its `onTap` behavior.
  PolygonController({
    required gmaps.Polygon polygon,
    bool consumeTapEvents = false,
    VoidCallback? onTap,
    void Function(List<gmaps.LatLng> path)? onEdited,
  }) : _polygon = polygon,
       _consumeTapEvents = consumeTapEvents {
    if (onTap != null) {
      _subscriptions.add(
        polygon.onClick.listen((gmaps.PolyMouseEvent event) {
          onTap.call();
        }),
      );
    }
    if (onEdited != null) {
      _listenToPathEdits(polygon, onEdited);
    }
  }

  gmaps.Polygon? _polygon;

  final bool _consumeTapEvents;

  final List<StreamSubscription<dynamic>> _subscriptions =
      <StreamSubscription<dynamic>>[];

  /// Returns the wrapped [gmaps.Polygon]. Only used for testing.
  @visibleForTesting
  gmaps.Polygon? get polygon => _polygon;

  /// Returns `true` if this Controller will use its own `onTap` handler to consume events.
  bool get consumeTapEvents => _consumeTapEvents;

  List<gmaps.LatLng> _readPath(gmaps.Polygon polygon) {
    final gmaps.MVCArray<gmaps.LatLng> path = polygon.path;
    final points = <gmaps.LatLng>[];
    for (int i = 0; i < path.length.toInt(); i++) {
      points.add(path.getAt(i));
    }
    return points;
  }

  void _listenToPathEdits(
    gmaps.Polygon polygon,
    void Function(List<gmaps.LatLng> path) onEdited,
  ) {
    void emitCurrentPath() {
      onEdited(_readPath(polygon));
    }

    _subscriptions.add(polygon.path.onSetAt.listen((_) => emitCurrentPath()));
    _subscriptions
        .add(polygon.path.onInsertAt.listen((_) => emitCurrentPath()));
    _subscriptions
        .add(polygon.path.onRemoveAt.listen((_) => emitCurrentPath()));
  }

  /// Updates the options of the wrapped [gmaps.Polygon] object.
  ///
  /// This cannot be called after [remove].
  void update(gmaps.PolygonOptions options) {
    assert(_polygon != null, 'Cannot `update` Polygon after calling `remove`.');
    _polygon!.options = options;
  }

  /// Disposes of the currently wrapped [gmaps.Polygon].
  void remove() {
    if (_polygon != null) {
      _polygon!.visible = false;
      _polygon!.map = null;
      _polygon = null;
      for (final StreamSubscription<dynamic> sub in _subscriptions) {
        sub.cancel();
      }
      _subscriptions.clear();
    }
  }
}
