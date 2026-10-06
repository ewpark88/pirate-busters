import 'package:flutter/foundation.dart';
import 'package:pb_sim/pb_sim.dart';

/// 조선소 도구 (설계서 §13.6): 재질·선실·모듈 놓기, 지우기.
sealed class ShipTool {
  const ShipTool();
}

class MaterialTool extends ShipTool {
  const MaterialTool(this.material);
  final BlockMaterial material;
}

class CabinTool extends ShipTool {
  const CabinTool();
}

class ModuleTool extends ShipTool {
  const ModuleTool(this.kind);
  final ModuleKind kind;
}

class EraseTool extends ShipTool {
  const EraseTool();
}

/// 조선소 건조 탭의 편집 상태. 규칙 판정은 `pb_sim` 의 [buildProblem]·
/// [disconnectedBlocks]·[ShipStats] 가 하고, 여기서는 칸을 고치고 되돌리기만 한다.
class ShipyardModel extends ChangeNotifier {
  ShipyardModel({this.hull = HullSpec.sloop})
    : _materials = List.filled(hull.width * hull.height, null),
      _modules = List.filled(hull.width * hull.height, null);

  final HullSpec hull;

  /// 칸마다의 재질·모듈. 인덱스 = y × 폭 + x.
  final List<BlockMaterial?> _materials;
  final List<ModuleKind?> _modules;

  /// 선실 칸 인덱스(선실 슬롯 순서).
  final List<int> _cabins = [];

  final List<_Snapshot> _history = [];

  /// 한 번 누르기·끌기(한 획)가 바꾼 것은 되돌리기 한 번으로 돌린다.
  bool _strokeOpen = false;
  bool _strokeChanged = false;

  ShipTool _tool = const MaterialTool(BlockMaterial.oak);

  ShipTool get tool => _tool;

  /// 도구를 고른다. 설계도는 바뀌지 않으므로 되돌리기에 남기지 않는다.
  void selectTool(ShipTool tool) {
    _tool = tool;
    notifyListeners();
  }

  static const int _maxHistory = 50;

  int get width => hull.width;
  int get height => hull.height;

  BlockMaterial? materialAt(int x, int y) => _materials[y * width + x];
  ModuleKind? moduleAt(int x, int y) => _modules[y * width + x];

  /// 선실 슬롯 번호, 선실이 아니면 −1.
  int cabinSlotAt(int x, int y) => _cabins.indexOf(y * width + x);

  bool get canUndo => _history.isNotEmpty;

  List<BlockCell> get cells => [
    for (var i = 0; i < _materials.length; i++)
      if (_materials[i] case final m?) BlockCell(i % width, i ~/ width, m),
  ];

  List<CabinCell> get cabins => [
    for (final i in _cabins) CabinCell(i % width, i ~/ width),
  ];

  List<ModuleCell> get modules => [
    for (var i = 0; i < _modules.length; i++)
      if (_modules[i] case final k?) ModuleCell(i % width, i ~/ width, k),
  ];

  ShipStats get stats => ShipStats.of(hull, cells, modules);

  /// 규칙 문제(개발용 글), 없으면 null. 화면은 문제 글 대신 빨간 칸과 수치를 보인다.
  String? get problem =>
      buildProblem(hull, cells, cabins: cabins, modules: modules);

  bool get canSave => problem == null;

  /// 용골과 끊긴 블록 칸 인덱스.
  Set<int> get loose => {
    for (final c in disconnectedBlocks(hull, cells)) c.y * width + c.x,
  };

  /// 저장할 수 있으면 설계도, 아니면 null.
  Blueprint? toBlueprint() =>
      canSave ? Blueprint(hull, cells, cabins: cabins, modules: modules) : null;

  /// [b] 로 바꾼다(되돌리기 가능).
  void load(Blueprint b) {
    _remember();
    _materials.fillRange(0, _materials.length, null);
    _modules.fillRange(0, _modules.length, null);
    _cabins.clear();
    for (final c in b.cells) {
      _materials[c.y * width + c.x] = c.material;
    }
    for (final c in b.cabins) {
      _cabins.add(c.y * width + c.x);
    }
    for (final m in b.modules) {
      _modules[m.y * width + m.x] = m.kind;
    }
    notifyListeners();
  }

  /// 한 획 시작(누르기·끌기 시작). 끝은 [endStroke].
  void beginStroke() {
    _remember();
    _strokeOpen = true;
    _strokeChanged = false;
  }

  /// 획이 아무것도 바꾸지 않았으면 되돌리기 기록을 남기지 않는다.
  void endStroke() {
    if (_strokeOpen && !_strokeChanged) _history.removeLast();
    _strokeOpen = false;
  }

  /// 지금 도구를 ([x], [y]) 칸에 쓴다. 끌기 중이면 같은 획으로 친다.
  void apply(int x, int y) {
    // 선체 틀 밖에는 아무것도 놓지 않는다 (설계서 §3.4).
    if (!hull.inFrame(x, y)) return;
    if (!_strokeOpen) _remember();
    final i = y * width + x;
    final changed = switch (tool) {
      MaterialTool(:final material) => _setMaterial(i, material),
      CabinTool() => _toggleCabin(i),
      ModuleTool(:final kind) => _toggleModule(i, kind),
      EraseTool() => _erase(i),
    };
    if (_strokeOpen) {
      _strokeChanged |= changed;
    } else if (!changed) {
      _history.removeLast();
    }
    if (changed) notifyListeners();
  }

  /// 길게 눌러 지우기 (설계서 §13.6).
  void eraseAt(int x, int y) {
    if (x < 0 || y < 0 || x >= width || y >= height) return;
    _remember();
    if (_erase(y * width + x)) {
      notifyListeners();
    } else {
      _history.removeLast();
    }
  }

  void undo() {
    if (_history.isEmpty) return;
    final s = _history.removeLast();
    _materials.setAll(0, s.materials);
    _modules.setAll(0, s.modules);
    _cabins
      ..clear()
      ..addAll(s.cabins);
    notifyListeners();
  }

  bool _setMaterial(int i, BlockMaterial m) {
    if (_materials[i] == m) return false;
    _materials[i] = m;
    return true;
  }

  /// 블록 위에서만. 선실 슬롯이 다 차면 더 놓지 않는다. 선실을 빼면 선실 옵션도 뺀다.
  bool _toggleCabin(int i) {
    if (_materials[i] == null) return false;
    if (_cabins.remove(i)) {
      if (_modules[i]?.cabinOption ?? false) _modules[i] = null;
      return true;
    }
    if (_cabins.length >= hull.cabinSlots) return false;
    // 선실 칸에는 선실 옵션(포문·망루)만 둔다.
    if (!(_modules[i]?.cabinOption ?? true)) _modules[i] = null;
    _cabins.add(i);
    return true;
  }

  /// 블록 위에서만. 같은 모듈이면 뺀다. 선실 옵션은 선실 칸에만, 나머지는 선실 아닌 칸에만.
  bool _toggleModule(int i, ModuleKind kind) {
    if (_materials[i] == null) return false;
    if (_modules[i] == kind) {
      _modules[i] = null;
      return true;
    }
    if (kind.cabinOption != _cabins.contains(i)) return false;
    _modules[i] = kind;
    return true;
  }

  bool _erase(int i) {
    if (_materials[i] == null) return false;
    _materials[i] = null;
    _modules[i] = null;
    _cabins.remove(i);
    return true;
  }

  void _remember() {
    _history.add(
      _Snapshot(List.of(_materials), List.of(_modules), List.of(_cabins)),
    );
    if (_history.length > _maxHistory) _history.removeAt(0);
  }
}

class _Snapshot {
  _Snapshot(this.materials, this.modules, this.cabins);

  final List<BlockMaterial?> materials;
  final List<ModuleKind?> modules;
  final List<int> cabins;
}
