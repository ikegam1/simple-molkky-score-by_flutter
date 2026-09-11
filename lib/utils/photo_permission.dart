/// 写真ライブラリへの保存エラーを、プラットフォーム非依存の形で扱うための入口。
///
/// ネイティブ版は `gal` パッケージを使うが、`gal` は Web をサポートしないため
/// 直接 import すると Web ビルドが壊れる。image_downloader と同じ方式で
/// 条件付き export する。
export 'photo_permission_stub.dart'
    if (dart.library.html) 'photo_permission_web.dart'
    show isPhotoAccessDenied, openPhotoSettings, describePhotoSaveError;
