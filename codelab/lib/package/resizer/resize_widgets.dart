import 'package:flutter/material.dart';
import 'dart:async';

/// The callback argument type of [ResizableWidget.onResized].
typedef OnResizedFunc = void Function(List<WidgetSizeInfo> infoList);

/// Holds resizable widgets as children.
/// Users can resize the internal widgets by dragging.
class ResizableWidget extends StatefulWidget {
  /// Resizable widget list.
  final List<Widget> children;

  /// Sets the default [children] width or height as percentages.
  ///
  /// If you set this value,
  /// the length of [percentages] must match the one of [children],
  /// and the sum of [percentages] must be equal to 1.
  ///
  /// If this value is [null], [children] will be split into the same size.
  final List<double>? percentages;

  /// When set to true, creates horizontal separators.
  @Deprecated('Use [isHorizontalSeparator] instead')
  final bool isColumnChildren;

  /// When set to true, creates horizontal separators.
  final bool isHorizontalSeparator;

  /// When set to true, Smart-Hide-Function is disabled.
  ///
  /// Smart-Hide-Function is that users can hide / show the both ends widgets
  /// by double-clicking the separators.
  final bool isDisabledSmartHide;

  /// Separator size.
  final double separatorSize;

  /// Separator color.
  final Color separatorColor;

  /// Callback of the resizing event.
  /// You can get the size and percentage of the internal widgets.
  ///
  /// Note that [onResized] is called every frame when resizing [children].
  final OnResizedFunc? onResized;

  /// Creates [ResizableWidget].
  ResizableWidget({
    Key? key,
    required this.children,
    this.percentages,
    @Deprecated('Use [isHorizontalSeparator] instead')
    this.isColumnChildren = false,
    this.isHorizontalSeparator = false,
    this.isDisabledSmartHide = false,
    this.separatorSize = 4,
    this.separatorColor = Colors.white12,
    this.onResized,
  }) : super(key: key) {
    assert(children.isNotEmpty);
    assert(percentages == null || percentages!.length == children.length);
    assert(percentages == null ||
        percentages!.reduce((value, element) => value + element) == 1);
  }

  @override
  _ResizableWidgetState createState() => _ResizableWidgetState();
}

class _ResizableWidgetState extends State<ResizableWidget> {
  late ResizableWidgetArgsInfo _info;
  late ResizableWidgetController _controller;

  @override
  void initState() {
    super.initState();

    _info = ResizableWidgetArgsInfo(widget);
    _controller = ResizableWidgetController(_info);
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      _controller.setSizeIfNeeded(constraints);
      return StreamBuilder(
        stream: _controller.eventStream.stream,
        builder: (context, snapshot) => _info.isHorizontalSeparator
            ? Column(
            children: _controller.children.map(_buildChild).toList())
            : Row(children: _controller.children.map(_buildChild).toList()),
      );
    },
  );

  Widget _buildChild(ResizableWidgetChildData child) {
    if (child.widget is Separator) {
      return child.widget;
    }

    return SizedBox(
      width: _info.isHorizontalSeparator ? double.infinity : child.size,
      height: _info.isHorizontalSeparator ? child.size : double.infinity,
      child: child.widget,
    );
  }
}
class ResizableWidgetArgsInfo {
  final List<Widget> children;
  final List<double>? percentages;
  final bool isHorizontalSeparator;
  final bool isDisabledSmartHide;
  final double separatorSize;
  final Color separatorColor;
  final OnResizedFunc? onResized;

  ResizableWidgetArgsInfo(ResizableWidget widget)
      : children = widget.children,
        percentages = widget.percentages,
        isHorizontalSeparator =
        // TODO: delete the deprecated member on the next minor update.
        // ignore: deprecated_member_use_from_same_package
        widget.isHorizontalSeparator || widget.isColumnChildren,
        isDisabledSmartHide = widget.isDisabledSmartHide,
        separatorSize = widget.separatorSize,
        separatorColor = widget.separatorColor,
        onResized = widget.onResized;
}
class ResizableWidgetChildData {
  final Widget widget;
  double? size;
  double? percentage;
  double? defaultPercentage;
  double? hidingPercentage;
  ResizableWidgetChildData(this.widget, this.percentage);
}

class ResizableWidgetController {
  final eventStream = StreamController<Object>();
  final ResizableWidgetModel _model;
  List<ResizableWidgetChildData> get children => _model.children;

  ResizableWidgetController(ResizableWidgetArgsInfo info)
      : _model = ResizableWidgetModel(info) {
    _model.init(_separatorFactory);
  }

  void setSizeIfNeeded(BoxConstraints constraints) {
    _model.setSizeIfNeeded(constraints);
    _model.callOnResized();
  }

  void resize(int separatorIndex, Offset offset) {
    _model.resize(separatorIndex, offset);

    eventStream.add(this);
    _model.callOnResized();
  }

  void tryHideOrShow(int separatorIndex) {
    final result = _model.tryHideOrShow(separatorIndex);

    if (result) {
      eventStream.add(this);
      _model.callOnResized();
    }
  }

  Widget _separatorFactory(SeparatorArgsBasicInfo basicInfo) {
    return Separator(SeparatorArgsInfo(this, basicInfo));
  }
}

typedef SeparatorFactory = Widget Function(SeparatorArgsBasicInfo basicInfo);

class ResizableWidgetModel {
  final ResizableWidgetArgsInfo _info;
  final children = <ResizableWidgetChildData>[];
  double? maxSize;
  double? get maxSizeWithoutSeparators => maxSize == null
      ? null
      : maxSize! - (children.length ~/ 2) * _info.separatorSize;

  ResizableWidgetModel(this._info);

  void init(SeparatorFactory separatorFactory) {
    final originalChildren = _info.children;
    final size = originalChildren.length;
    final originalPercentages =
        _info.percentages ?? List.filled(size, 1 / size);
    for (var i = 0; i < size - 1; i++) {
      children.add(ResizableWidgetChildData(
          originalChildren[i], originalPercentages[i]));
      children.add(ResizableWidgetChildData(
          separatorFactory.call(SeparatorArgsBasicInfo(
            2 * i + 1,
            _info.isHorizontalSeparator,
            _info.isDisabledSmartHide,
            _info.separatorSize,
            _info.separatorColor,
          )),
          null));
    }
    children.add(ResizableWidgetChildData(
        originalChildren[size - 1], originalPercentages[size - 1]));
  }

  void setSizeIfNeeded(BoxConstraints constraints) {
    final max = _info.isHorizontalSeparator
        ? constraints.maxHeight
        : constraints.maxWidth;
    var isMaxSizeChanged = maxSize == null || maxSize! != max;
    if (!isMaxSizeChanged || children.isEmpty) {
      return;
    }

    maxSize = max;
    final remain = maxSizeWithoutSeparators!;

    for (var c in children) {
      if (c.widget is Separator) {
        c.percentage = 0;
        c.size = _info.separatorSize;
      } else {
        c.size = remain * c.percentage!;
        c.defaultPercentage = c.percentage;
      }
    }
  }

  void resize(int separatorIndex, Offset offset) {
    final leftSize = _resizeImpl(separatorIndex - 1, offset);
    final rightSize = _resizeImpl(separatorIndex + 1, offset * (-1));

    if (leftSize < 0) {
      _resizeImpl(
          separatorIndex - 1,
          _info.isHorizontalSeparator
              ? Offset(0, -leftSize)
              : Offset(-leftSize, 0));
      _resizeImpl(
          separatorIndex + 1,
          _info.isHorizontalSeparator
              ? Offset(0, leftSize)
              : Offset(leftSize, 0));
    }
    if (rightSize < 0) {
      _resizeImpl(
          separatorIndex - 1,
          _info.isHorizontalSeparator
              ? Offset(0, rightSize)
              : Offset(rightSize, 0));
      _resizeImpl(
          separatorIndex + 1,
          _info.isHorizontalSeparator
              ? Offset(0, -rightSize)
              : Offset(-rightSize, 0));
    }
  }

  void callOnResized() {
    _info.onResized?.call(children
        .where((x) => x.widget is! Separator)
        .map((x) => WidgetSizeInfo(x.size!, x.percentage!))
        .toList());
  }

  bool tryHideOrShow(int separatorIndex) {
    if (_info.isDisabledSmartHide) {
      return false;
    }

    final isLeft = separatorIndex == 1;
    final isRight = separatorIndex == children.length - 2;
    if (!isLeft && !isRight) {
      // valid only for both ends.
      return false;
    }

    final target = children[isLeft ? 0 : children.length - 1];
    final size = target.size!;
    final coefficient = isLeft ? 1 : -1;
    if (_isNearlyZero(size)) {
      // show
      final offsetScala =
          maxSize! * (target.hidingPercentage ?? target.defaultPercentage!) -
              size;
      final offset = _info.isHorizontalSeparator
          ? Offset(0, offsetScala * coefficient)
          : Offset(offsetScala * coefficient, 0);
      resize(separatorIndex, offset);
    } else {
      // hide
      target.hidingPercentage = target.percentage!;
      final offsetScala = maxSize! * target.hidingPercentage!;
      final offset = _info.isHorizontalSeparator
          ? Offset(0, -offsetScala * coefficient)
          : Offset(-offsetScala * coefficient, 0);
      resize(separatorIndex, offset);
    }

    return true;
  }

  double _resizeImpl(int widgetIndex, Offset offset) {
    final size = children[widgetIndex].size ?? 0;
    children[widgetIndex].size =
        size + (_info.isHorizontalSeparator ? offset.dy : offset.dx);
    children[widgetIndex].percentage =
        children[widgetIndex].size! / maxSizeWithoutSeparators!;
    return children[widgetIndex].size!;
  }

  bool _isNearlyZero(double size) {
    return size < 2;
  }
}

class Separator extends StatefulWidget {
  final SeparatorArgsInfo info;

  const Separator(
      this.info, {
        Key? key,
      }) : super(key: key);

  @override
  _SeparatorState createState() => _SeparatorState();
}

class _SeparatorState extends State<Separator> {
  late SeparatorArgsInfo _info;
  late SeparatorController _controller;

  @override
  void initState() {
    super.initState();

    _info = widget.info;
    _controller =
        SeparatorController(widget.info.index, widget.info.parentController);
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
    child: MouseRegion(
      cursor: _info.isHorizontalSeparator
          ? SystemMouseCursors.resizeRow
          : SystemMouseCursors.resizeColumn,
      child: SizedBox(
        width: _info.isHorizontalSeparator ? double.infinity : _info.size,
        height: _info.isHorizontalSeparator ? _info.size : double.infinity,
        child: Container(color: _info.color),
      ),
    ),
    onPanUpdate: (details) => _controller.onPanUpdate(details, context),
    onDoubleTap: () => _controller.onDoubleTap(),
  );
}
class SeparatorArgsInfo extends SeparatorArgsBasicInfo {
  final ResizableWidgetController parentController;

  SeparatorArgsInfo(this.parentController, SeparatorArgsBasicInfo basicInfo)
      : super.clone(basicInfo);
}

class SeparatorArgsBasicInfo {
  final int index;
  final bool isHorizontalSeparator;
  final bool isDisabledSmartHide;
  final double size;
  final Color color;

  const SeparatorArgsBasicInfo(this.index, this.isHorizontalSeparator,
      this.isDisabledSmartHide, this.size, this.color);

  SeparatorArgsBasicInfo.clone(SeparatorArgsBasicInfo info)
      : index = info.index,
        isHorizontalSeparator = info.isHorizontalSeparator,
        isDisabledSmartHide = info.isDisabledSmartHide,
        size = info.size,
        color = info.color;
}
class SeparatorController {
  final int _index;
  final ResizableWidgetController _parentController;

  const SeparatorController(this._index, this._parentController);

  void onPanUpdate(DragUpdateDetails details, BuildContext context) {
    _parentController.resize(_index, details.delta);
  }

  void onDoubleTap() {
    _parentController.tryHideOrShow(_index);
  }
}
/// Information about an internal widget size of [ResizableWidget].
class WidgetSizeInfo {
  /// The actual pixel size.
  ///
  /// If the app window size is changed, this value will be also changed.
  final double size;

  /// The size percentage among the [ResizableWidget] children.
  ///
  /// Even if the app window size is changed, this value will not be changed
  /// because the ratio of the internal widgets will be maintained.
  final double percentage;

  /// Creates [WidgetSizeInfo].
  const WidgetSizeInfo(this.size, this.percentage);
}