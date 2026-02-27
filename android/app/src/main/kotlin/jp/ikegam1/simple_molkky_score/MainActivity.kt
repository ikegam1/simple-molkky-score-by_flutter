package jp.ikegam1.simple_molkky_score

import android.os.Bundle
import androidx.core.view.WindowCompat
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Android 15 / SDK 35 向けのエッジツーエッジ表示を有効化
        WindowCompat.setDecorFitsSystemWindows(window, false)
    }
}
