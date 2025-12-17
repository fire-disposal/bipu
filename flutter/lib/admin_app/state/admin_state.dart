import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bipupu_flutter/core/state/base_cubit.dart';

/// 管理端应用状态
class AdminState extends BaseState {
  const AdminState();
}

/// 管理端加载状态
class AdminLoadingState extends AdminState {
  const AdminLoadingState();
}

/// 管理端错误状态
class AdminErrorState extends AdminState {
  final String message;

  const AdminErrorState(this.message);
}

/// 管理端成功状态
class AdminSuccessState extends AdminState {
  const AdminSuccessState();
}

/// 管理端Cubit基类
abstract class AdminCubit<T extends AdminState> extends BaseCubit<T> {
  AdminCubit(T initialState) : super(initialState);
}

/// 管理端导航Cubit
class AdminNavigationCubit extends AdminCubit<AdminState> {
  AdminNavigationCubit() : super(const AdminState());

  int _selectedIndex = 0;

  int get selectedIndex => _selectedIndex;

  void changeIndex(int index) {
    _selectedIndex = index;
    safeEmit(const AdminSuccessState());
  }
}
