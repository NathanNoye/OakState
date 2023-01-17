import 'package:flutter/widgets.dart';
import 'package:get_it/get_it.dart';
import 'package:provider/provider.dart';

enum ViewState { idle, busy, error, success }

extension ViewStateExt on ViewState {
  bool get isIdle => this == ViewState.idle;
  bool get isNotIdle => this != ViewState.idle;
  bool get isBusy => this == ViewState.busy;
  bool get hasError => this == ViewState.error;
  bool get isSuccess => this == ViewState.success;
}

class BaseManager extends ChangeNotifier {
  ViewState _state = ViewState.idle;

  ViewState get state => _state;

  /// Covers the main four states: idle, busy, error, and success
  void setState(ViewState viewState) {
    _state = viewState;
    try {
      notifyListeners();
    } catch (exception) {
      rethrow;
    }
  }

  void rebuildWidgets() {
    notifyListeners();
  }
}

class BaseView<T extends BaseManager> extends StatefulWidget {
  final Widget Function(BuildContext context, T viewmodel, Widget? child)
      builder;

  final Function(T)? afterLayout;
  final Function(T)? beforeLayout;
  final Function(T)? onDispose;
  final Function(T)? onResumed;
  final Function(T)? onInactive;
  final Function(T)? onPaused;
  final Function(T)? onDetached;
  final Function(T)? onResumeFromBackground;

  const BaseView({
    required this.builder,
    this.afterLayout,
    this.beforeLayout,
    this.onDispose,
    this.onResumed,
    this.onInactive,
    this.onPaused,
    this.onDetached,
    this.onResumeFromBackground,
  });

  @override
  _BaseViewState<T> createState() => _BaseViewState<T>();
}

class _BaseViewState<T extends BaseManager> extends State<BaseView<T>>
    with WidgetsBindingObserver {
  T viewmodel = locator<T>();
  bool triggerFunctionAfterResumeFromBackground = false;

  @override
  void initState() {
    if (widget.beforeLayout != null) {
      widget.beforeLayout!(viewmodel);
      WidgetsBinding.instance.addObserver(this);
    }

    if (widget.afterLayout != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        widget.afterLayout!(viewmodel);
      });
    }
    super.initState();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.resumed:
        if (widget.onResumed != null) {
          widget.onResumed!(viewmodel);
        }
        if (widget.onResumeFromBackground != null &&
            triggerFunctionAfterResumeFromBackground) {
          widget.onResumeFromBackground!(viewmodel);
          triggerFunctionAfterResumeFromBackground = false;
        }
        break;
      case AppLifecycleState.inactive:
        if (widget.onInactive != null) {
          widget.onInactive!(viewmodel);
        }
        break;
      case AppLifecycleState.paused:
        if (widget.onPaused != null) {
          widget.onPaused!(viewmodel);
        }

        if (widget.onResumeFromBackground != null) {
          triggerFunctionAfterResumeFromBackground = true;
        }
        break;
      case AppLifecycleState.detached:
        if (widget.onDetached != null) {
          widget.onDetached!(viewmodel);
        }
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    locator<BuildContextService>().setContext(context);
    return ChangeNotifierProvider<T>.value(
        value: viewmodel, child: Consumer<T>(builder: widget.builder));
  }

  @override
  void dispose() {
    if (widget.onDispose != null) {
      widget.onDispose!(viewmodel);
    }

    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}

class BuildContextService {
  late BuildContext _context;

  BuildContext get context => _context;

  setContext(BuildContext context) {
    _context = context;
  }
}

GetIt locator = GetIt.instance;

Future<void> setupLocator(Function(dynamic) registerCallback) async {
  locator.registerLazySingleton(() => BuildContextService());
  await registerCallback(dynamic);

  await locator.allReady();
}
