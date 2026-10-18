package id.takumi.app

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    private var notificationPermissionRequestStarted = false

    override fun onPostResume() {
        super.onPostResume()
        if (
            Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU ||
                notificationPermissionRequestStarted ||
                checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) ==
                PackageManager.PERMISSION_GRANTED
        ) {
            return
        }

        val preferences = getSharedPreferences(
            notificationPermissionPreferences,
            Context.MODE_PRIVATE,
        )
        if (preferences.getBoolean(notificationPermissionRequestedKey, false)) {
            return
        }

        notificationPermissionRequestStarted = true
        preferences.edit().putBoolean(notificationPermissionRequestedKey, true).apply()
        requestPermissions(
            arrayOf(Manifest.permission.POST_NOTIFICATIONS),
            notificationPermissionRequestCode,
        )
    }

    private companion object {
        const val notificationPermissionRequestCode = 1001
        const val notificationPermissionPreferences = "notification_permission"
        const val notificationPermissionRequestedKey = "requested"
    }
}
