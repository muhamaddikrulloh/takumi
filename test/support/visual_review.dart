// Preview entry point: real presentation widgets, isolated in-memory data.
// flutter run -t test/support/visual_review.dart --dart-define=SCENE=home
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:task_track/core/constants/app_theme.dart';
import 'package:task_track/core/providers/connectivity_provider.dart';
import 'package:task_track/core/providers/core_providers.dart';
import 'package:task_track/features/auth/providers/auth_provider.dart';
import 'package:task_track/features/auth/presentation/login_screen.dart';
import 'package:task_track/features/auth/presentation/register_screen.dart';
import 'package:task_track/features/auth/presentation/reset_password_screen.dart';
import 'package:task_track/features/auth/presentation/email_verification_screen.dart';
import 'package:task_track/features/calendar/presentation/calendar_screen.dart';
import 'package:task_track/features/home/presentation/home_screen.dart';
import 'package:task_track/features/profile/domain/profile.dart';
import 'package:task_track/features/profile/presentation/profile_screen.dart';
import 'package:task_track/features/profile/presentation/profile_setup_screen.dart';
import 'package:task_track/features/profile/presentation/profile_identity_modal.dart';
import 'package:task_track/features/profile/providers/profile_provider.dart';
import 'package:task_track/features/tasks/domain/task.dart';
import 'package:task_track/features/tasks/domain/task_status.dart';
import 'package:task_track/features/tasks/presentation/tasks_screen.dart';
import 'package:task_track/features/tasks/presentation/modals/task_form_modal.dart';
import 'package:task_track/features/tasks/presentation/modals/task_detail_modal.dart';
import 'package:task_track/features/tasks/providers/task_provider.dart';
import 'package:task_track/shared/widgets/bottom_nav_bar.dart';
import 'package:task_track/shared/widgets/notification_sheet.dart';
import 'package:task_track/shared/widgets/app_feedback.dart';
import 'package:task_track/shared/widgets/action_confirmation_dialog.dart';

const reviewProfile = Profile(
  displayName: 'Nadia Putri',
  email: 'nadia@example.com',
  institution: 'Universitas Indonesia',
  major: 'Informatika',
  avatarId: 'avatar_06',
  setupComplete: true,
);

final reviewTasks = List.generate(6, (i) {
  final now = DateTime.now();
  return Task(
    id: 'preview-$i',
    title: [
      'Rancangan antarmuka aplikasi',
      'Laporan praktikum basis data',
      'Presentasi algoritma',
      'Analisis sistem informasi',
      'Latihan statistika',
      'Proposal proyek semester',
    ][i],
    subject: [
      'Interaksi Manusia & Komputer',
      'Basis Data',
      'Algoritma',
      'Sistem Informasi',
      'Statistika',
      'Rekayasa Perangkat Lunak',
    ][i],
    description: 'Selesaikan rancangan dan dokumentasikan hasil evaluasi sebelum pengumpulan.',
    deadline: now.add(Duration(hours: i == 0 ? 5 : 28 + i * 12)),
    status: TaskStatus.values[i % 3],
    createdAt: now,
    updatedAt: now,
  );
});

class _ReviewTasks extends TaskListNotifier {
  @override
  Future<List<Task>> build() async => reviewTasks;
}

class _ReviewProfile extends ProfileNotifier {
  @override
  Future<Profile> build() async => reviewProfile;
}

Future<SharedPreferences> reviewPreferences() async {
  SharedPreferences.setMockInitialValues({'locale': 'id'});
  return SharedPreferences.getInstance();
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await reviewPreferences();
  runApp(
    ReviewApp(
      prefs: prefs,
      scene: const String.fromEnvironment('SCENE', defaultValue: 'home'),
    ),
  );
}

class ReviewApp extends StatelessWidget {
  const ReviewApp({
    super.key,
    required this.prefs,
    required this.scene,
    this.theme,
  });
  final SharedPreferences prefs;
  final String scene;
  final ThemeData? theme;

  @override
  Widget build(BuildContext context) => ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      authStateProvider.overrideWith((ref) => Stream.value(null)),
      connectivityProvider.overrideWith((ref) => Stream.value(true)),
      profileProvider.overrideWith(_ReviewProfile.new),
      profileGateProvider.overrideWith((ref) async => reviewProfile),
      taskListProvider.overrideWith(_ReviewTasks.new),
    ],
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: theme ?? AppTheme.darkTheme,
      locale: const Locale('id'),
      supportedLocales: const [Locale('id'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: _ReviewScene(scene: scene),
    ),
  );
}

class _ReviewScene extends StatefulWidget {
  const _ReviewScene({required this.scene});
  final String scene;
  @override
  State<_ReviewScene> createState() => _ReviewSceneState();
}

class _ReviewSceneState extends State<_ReviewScene> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      switch (widget.scene) {
        case 'form':
          TaskFormModal.show(context, task: reviewTasks.first);
        case 'detail':
          TaskDetailModal.show(context, reviewTasks.first);
        case 'notifications':
          NotificationSheet.show(context);
        case 'feedback':
          AppFeedback.show(
            context,
            message: 'Tugas berhasil ditambahkan.',
            type: AppFeedbackType.success,
            aboveNavigation: true,
          );
        case 'confirmation':
          ActionConfirmationDialog.show(
            context,
            icon: Icons.delete_outline,
            title: 'Hapus tugas?',
            description: 'Tindakan ini tidak dapat dibatalkan.',
            actionLabel: 'Hapus',
            cancelLabel: 'Batal',
          );
        case 'identity':
          ProfileIdentityModal.show(context, reviewProfile);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final child = switch (widget.scene) {
      'tasks' => const TasksScreen(),
      'calendar' => const CalendarScreen(),
      'profile' => const ProfileScreen(),
      'login' => const LoginScreen(),
      'register' => const RegisterScreen(),
      'reset' => const ResetPasswordScreen(),
      'verification' => const EmailVerificationScreen(),
      'setup' => const ProfileSetupScreen(initialProfile: reviewProfile),
      _ => const HomeScreen(),
    };
    if ([
      'login',
      'register',
      'reset',
      'verification',
      'setup',
    ].contains(widget.scene)) {
      return child;
    }
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          Positioned.fill(child: child),
          Positioned(
            left: 16,
            right: 16,
            bottom: MediaQuery.viewPaddingOf(context).bottom + 16,
            child: BottomNavBar(
              currentIndex: [
                'home',
                'tasks',
                'calendar',
                'profile',
              ].indexOf(widget.scene).clamp(0, 3),
              onTap: (_) {},
              onFabPressed: () => TaskFormModal.show(context),
            ),
          ),
        ],
      ),
    );
  }
}
