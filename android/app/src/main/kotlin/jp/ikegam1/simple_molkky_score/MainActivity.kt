package jp.ikegam1.simple_molkky_score

import android.os.Bundle
import androidx.activity.enableEdgeToEdge
import io.flutter.embedding.android.FlutterFragmentActivity

class MainActivity : FlutterFragmentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Android 15 / SDK 35 向けのエッジツーエッジ表示を有効化
        enableEdgeToEdge()
    }
}
