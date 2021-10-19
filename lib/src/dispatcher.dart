import 'dart:async';

import 'handler.dart';
import 'record.dart';

class Dispatcher {
  Dispatcher() : _controller = StreamController.broadcast();

  final StreamController<Record> _controller;

  final Set<Handler> _handlers = {};

  final List<Record> _records = [];

  void registerHandler(Handler handler) {
    _handlers.add(handler);
    handler.subscribe(_controller.stream);
  }

  void unregisterHandler(Handler handler) {
    _handlers.remove(handler);
    handler.destroy();
  }

  void add(Record record) {
    if (_records.length > 10000) {
      _records.removeAt(0);
    }
    _records.add(record);
    if (_controller.hasListener) {
      _controller.add(record);
    }
  }

  Future<void> destroy() async {
    for (Handler handler in _handlers) {
      handler.destroy();
    }
    _handlers.clear();
    await _controller.close();
  }
}
