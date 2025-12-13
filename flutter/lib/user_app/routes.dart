import 'package:go_router/go_router.dart';

import 'pages/auth/login_page.dart';
import 'pages/auth/register_page.dart';
import 'pages/auth/forgot_password_page.dart';
import 'pages/auth/change_password_page.dart';
import 'pages/auth/device_binding_page.dart';
import 'pages/auth/user_agreement_page.dart';

import 'pages/profile/profile_home_page.dart';
import 'pages/profile/edit_profile_page.dart';
import 'pages/profile/privacy_settings_page.dart';

import 'pages/message/message_list_page.dart';
import 'pages/message/message_detail_page.dart';
import 'pages/message/voice_input_page.dart';
import 'pages/message/export_print_page.dart';

import 'pages/cosmos_comm/cosmos_comm_settings_page.dart';
import 'pages/cosmos_comm/daily_fortune_page.dart';

import 'pages/device/device_scan_page.dart';
import 'pages/device/device_detail_page.dart';

import 'pages/home/home_page.dart';

final GoRouter router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomePage(),
      routes: [
        GoRoute(path: 'login', builder: (context, state) => const LoginPage()),
        GoRoute(
          path: 'register',
          builder: (context, state) => const RegisterPage(),
        ),
        GoRoute(
          path: 'forgot-password',
          builder: (context, state) => const ForgotPasswordPage(),
        ),
        GoRoute(
          path: 'change-password',
          builder: (context, state) => const ChangePasswordPage(),
        ),
        GoRoute(
          path: 'device-binding',
          builder: (context, state) => const DeviceBindingPage(),
        ),
        GoRoute(
          path: 'user-agreement',
          builder: (context, state) => const UserAgreementPage(),
        ),
        GoRoute(
          path: 'profile',
          builder: (context, state) => const ProfileHomePage(),
        ),
        GoRoute(
          path: 'edit-profile',
          builder: (context, state) => const EditProfilePage(),
        ),
        GoRoute(
          path: 'privacy-settings',
          builder: (context, state) => const PrivacySettingsPage(),
        ),
        GoRoute(
          path: 'messages',
          builder: (context, state) => const MessageListPage(),
        ),
        GoRoute(
          path: 'message-detail',
          builder: (context, state) => const MessageDetailPage(),
        ),
        GoRoute(
          path: 'voice-input',
          builder: (context, state) => const VoiceInputPage(),
        ),
        GoRoute(
          path: 'export-print',
          builder: (context, state) => const ExportPrintPage(),
        ),
        GoRoute(
          path: 'cosmos-comm-settings',
          builder: (context, state) => const CosmosCommSettingsPage(),
        ),
        GoRoute(
          path: 'daily-fortune',
          builder: (context, state) => const DailyFortunePage(),
        ),
        GoRoute(
          path: 'device-scan',
          builder: (context, state) => const DeviceScanPage(),
        ),
        GoRoute(
          path: 'device-detail',
          builder: (context, state) => const DeviceDetailPage(),
        ),
      ],
    ),
  ],
);
