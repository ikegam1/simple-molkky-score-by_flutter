import 'package:gal/gal.dart';

/// 保存エラーが「写真へのアクセス拒否」かどうか。
bool isPhotoAccessDenied(Object error) =>
    error is GalException && error.type == GalExceptionType.accessDenied;

/// OS の設定アプリ (写真のアクセス許可画面) を開く。
Future<void> openPhotoSettings() => Gal.open();

/// 保存エラーの説明文。ユーザーに出す想定。
String describePhotoSaveError(Object error) =>
    error is GalException ? error.type.message : '$error';
