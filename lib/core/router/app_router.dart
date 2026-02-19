import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/language_selection_screen.dart';
import '../../features/auth/presentation/screens/profile_completion_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/record/presentation/screens/record_screen.dart';
import '../../features/map/presentation/screens/map_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/admin/presentation/screens/admin_dashboard_screen.dart';
import '../../features/discussion/screens/ask_question_screen.dart';
import '../../features/discussion/screens/discussion_detail_screen.dart';
import '../../features/discussion/screens/add_solution_screen.dart';
import '../../features/ai_insight/presentation/screens/ai_insight_screen.dart';
import '../../features/climate/presentation/screens/climate_screen.dart';
import '../../features/voice/presentation/screens/voice_interaction_screen.dart';
import '../../features/chat/presentation/screens/chat_interaction_screen.dart';
import '../widgets/app_shell.dart';

/// GoRouter configuration for the app.
final appRouter = GoRouter(
  initialLocation: '/splash',
  // Handle Supabase OAuth callback deep link — redirect to splash
  // so the auth code is processed by Supabase in the background.
  redirect: (context, state) {
    final uri = state.uri;
    
    // Check for custom scheme deep link (Android/iOS)
    if (uri.scheme == 'io.supabase.gramgyan' && uri.host == 'login-callback') {
      return '/splash';
    }

    // Check for path-based redirect (Web/Deep Link fallback)
    if (uri.path.startsWith('/login-callback')) {
      return '/splash';
    }
    
    return null;
  },
  routes: [
    // ── Splash ──
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashScreen(),
    ),

    // ── Login ──
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),

    // ── Profile Completion (first-time user) ──
    GoRoute(
      path: '/complete-profile',
      builder: (context, state) => const ProfileCompletionScreen(),
    ),

    // ── Language Selection ──
    GoRoute(
      path: '/language',
      builder: (context, state) => const LanguageSelectionScreen(),
    ),

    // ── Main App Shell with Bottom Navigation ──
    ShellRoute(
      builder: (context, state, child) => AppShell(child: child),
      routes: [
        GoRoute(
          path: '/home',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: HomeScreen(),
          ),
        ),
        GoRoute(
          path: '/map',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: MapScreen(),
          ),
        ),
        GoRoute(
          path: '/profile',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: ProfileScreen(),
          ),
        ),
        GoRoute(
          path: '/admin',
          builder: (context, state) => const AdminDashboardScreen(),
        ),
      ],
    ),

    // ── Record (full screen, outside shell) ──
    GoRoute(
      path: '/record',
      pageBuilder: (context, state) => CustomTransitionPage(
        child: const RecordScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 1),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            )),
            child: child,
          );
        },
      ),
    ),

    // ── Ask Question (full screen, outside shell) ──
    GoRoute(
      path: '/ask-question',
      pageBuilder: (context, state) => CustomTransitionPage(
        child: const AskQuestionScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 1),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            )),
            child: child,
          );
        },
      ),
    ),

    // ── Discussion Detail (full screen, outside shell) ──
    GoRoute(
      path: '/discussion/:id',
      pageBuilder: (context, state) {
        final id = state.pathParameters['id']!;
        return CustomTransitionPage(
          child: DiscussionDetailScreen(questionId: id),
          transitionsBuilder:
              (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1, 0),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              )),
              child: child,
            );
          },
        );
      },
    ),

    // ── Add Solution (full screen, outside shell) ──
    GoRoute(
      path: '/add-solution/:questionId',
      pageBuilder: (context, state) {
        final questionId = state.pathParameters['questionId']!;
        return CustomTransitionPage(
          child: AddSolutionScreen(questionId: questionId),
          transitionsBuilder:
              (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 1),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              )),
              child: child,
            );
          },
        );
      },
    ),

    // ── AI Insight (full screen, outside shell) ──
    GoRoute(
      path: '/ai-insight/:questionId',
      pageBuilder: (context, state) {
        final questionId = state.pathParameters['questionId']!;
        return CustomTransitionPage(
          child: AiInsightScreen(questionId: questionId),
          transitionsBuilder:
              (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1, 0),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              )),
              child: child,
            );
          },
        );
      },
    ),

    // ── Climate Screen (full screen) ──
    GoRoute(
      path: '/climate',
      pageBuilder: (context, state) => CustomTransitionPage(
        child: const ClimateScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 1),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            )),
            child: child,
          );
        },
      ),
    ),

    // ── Voice Interaction (full screen) ──
    GoRoute(
      path: '/voice-interaction',
      pageBuilder: (context, state) => CustomTransitionPage(
        child: const VoiceInteractionScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    ),

    // ── Chat Interaction (full screen) ──
    GoRoute(
      path: '/chat',
      pageBuilder: (context, state) => CustomTransitionPage(
        child: const ChatInteractionScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
             // Slide up from bottom
            position: Tween<Offset>(
              begin: const Offset(0, 1),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            )),
            child: child,
          );
        },
      ),
    ),
  ],
);
