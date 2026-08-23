import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loginState = ref.watch(loginControllerProvider);
    
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    // Centralized custom design styles queried directly from theme extension
    final customTheme = theme.extension<FuturisticThemeExtension>()!;

    final bgColor = theme.scaffoldBackgroundColor;
    final cardColor = theme.colorScheme.surface;
    final borderColor = customTheme.borderColor;
    final textColor = theme.colorScheme.onSurface;
    final subTextColor = theme.colorScheme.onSurfaceVariant;
    final glowColor1 = customTheme.glowColor1;
    final glowColor2 = customTheme.glowColor2;
    final accentColor = customTheme.accentColor;
    final logoBg = customTheme.logoBg;

    // Watch loginState to display modern SnackBar messages on error
    ref.listen<AsyncValue<void>>(loginControllerProvider, (previous, next) {
      if (next is AsyncError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFFD32F2F),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Authentication Failed: ${next.error}',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          // Background Tech-glowing radial circles
          Positioned(
            top: -150,
            right: -100,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: glowColor1.withValues(alpha: isDark ? 0.12 : 0.08),
                    blurRadius: 120,
                    spreadRadius: 60,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: -150,
            left: -100,
            child: Container(
              width: 450,
              height: 450,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: glowColor2.withValues(alpha: isDark ? 0.12 : 0.08),
                    blurRadius: 140,
                    spreadRadius: 70,
                  ),
                ],
              ),
            ),
          ),
          
          // Main Content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // App Logo with Glowing Border
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: logoBg,
                          boxShadow: [
                            BoxShadow(
                              color: accentColor.withValues(alpha: isDark ? 0.3 : 0.15),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.account_balance_wallet_outlined,
                          size: 64,
                          color: accentColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    // Welcome Header Text
                    Text(
                      'TRANSACTION NOTE',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2.0,
                        foreground: Paint()
                          ..shader = LinearGradient(
                            colors: <Color>[accentColor, glowColor2],
                          ).createShader(const Rect.fromLTWH(0.0, 0.0, 200.0, 70.0)),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'SECURE FINANCIAL LEDGER',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: subTextColor,
                        fontSize: 12,
                        letterSpacing: 3.0,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 48),

                    // Glassmorphic Interactive Login Card
                    Container(
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        color: cardColor.withValues(alpha: isDark ? 0.85 : 0.95),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: borderColor.withValues(alpha: isDark ? 0.5 : 0.8),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Access Gateway',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: textColor,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Please sign in to establish connection',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: subTextColor,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Login / Authenticating State
                          if (loginState.isLoading) ...[
                            Center(
                              child: Column(
                                children: [
                                  SizedBox(
                                    height: 50,
                                    width: 50,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 3.5,
                                      valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  Text(
                                    'AUTHENTICATING SECURELY...',
                                    style: TextStyle(
                                      color: accentColor,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1.5,
                                      fontSize: 11,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Synchronizing credentials...',
                                    style: TextStyle(
                                      color: subTextColor,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ] else ...[
                            // Futuristic Tech Button
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: accentColor,
                                foregroundColor: isDark ? const Color(0xFF0F111A) : Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: isDark ? 8 : 4,
                                shadowColor: accentColor.withValues(alpha: 0.4),
                              ),
                              onPressed: () {
                                ref.read(loginControllerProvider.notifier).signInWithGoogle();
                              },
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isDark ? Colors.white : Colors.white.withValues(alpha: 0.2),
                                    ),
                                    child: Icon(
                                      Icons.g_mobiledata,
                                      color: isDark ? const Color(0xFF0F111A) : Colors.white,
                                      size: 18,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Text(
                                    'Sign In with Google',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                    
                    // Decors/Footer Info
                    Text(
                      'v1.0.0 • Encrypted Connection',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: subTextColor.withValues(alpha: 0.7),
                        fontSize: 10,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
