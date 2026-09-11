/// Web はブラウザのダウンロード機能を使うため、写真ライブラリの権限は存在しない。
bool isPhotoAccessDenied(Object error) => false;

Future<void> openPhotoSettings() async {}

String describePhotoSaveError(Object error) => '$error';
