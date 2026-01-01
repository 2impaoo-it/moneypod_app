import 'package:flutter_bloc/flutter_bloc.dart';

class SettingsCubit extends Cubit<bool> {
  // Trạng thái true: Hiển thị số dư
  // Trạng thái false: Ẩn số dư (******)
  SettingsCubit() : super(true);

  void toggleBalanceVisibility() => emit(!state);
}
