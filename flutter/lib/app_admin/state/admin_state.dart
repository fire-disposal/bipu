/// 管理端状态管理
library;

import 'package:flutter_bloc/flutter_bloc.dart';

/// 管理端导航状态
class AdminNavigationState {
  final int selectedIndex;

  const AdminNavigationState({this.selectedIndex = 0});

  AdminNavigationState copyWith({int? selectedIndex}) {
    return AdminNavigationState(
      selectedIndex: selectedIndex ?? this.selectedIndex,
    );
  }
}

/// 管理端导航Cubit
class AdminNavigationCubit extends Cubit<AdminNavigationState> {
  AdminNavigationCubit() : super(const AdminNavigationState());

  void changeIndex(int index) {
    emit(state.copyWith(selectedIndex: index));
  }

  int get selectedIndex => state.selectedIndex;
}
