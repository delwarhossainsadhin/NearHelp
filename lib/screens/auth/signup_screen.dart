import 'package:flutter/material.dart';
import '../../main.dart';
import '../../services/auth_service.dart';
import 'login_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  String _selectedRole = 'customer';
  bool _isLoading = false;
  bool _obscurePassword = true;

  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final error = await _authService.signUp(
      name: _nameController.text.trim(),
      email: _emailController.text.trim().toLowerCase(),
      password: _passwordController.text,
      phone: _phoneController.text.trim(),
      role: _selectedRole,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (error == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Welcome! Account created 🚀'), backgroundColor: Colors.green),
      );
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const AuthWrapper()),
        (route) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.redAccent),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0F0F) : const Color(0xFFF8F9FA),
      body: Stack(
        children: [

          Positioned(
            top: -20,
            right: -60,
            child: Transform.rotate(
              angle: -0.5,
              child: Column(
                children: List.generate(5, (index) => Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  height: 6,
                  width: 250,
                  decoration: BoxDecoration(
                    color: Colors.greenAccent.withOpacity(isDark ? 0.1 : 0.2),

                    borderRadius: BorderRadius.circular(10),
                  ),
                )),
              ),
            ),
          ),


          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_ios_new_rounded),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Create\nAccount',
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.w900,
                        height: 1.1,
                        letterSpacing: -1.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('Join NearHelp to get started', style: TextStyle(color: Colors.grey[600], fontSize: 16)),

                    const SizedBox(height: 35),


                    const Text('I want to...', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _buildModernRoleCard('customer', 'Find Help', Icons.person_search_rounded, theme),
                        const SizedBox(width: 15),
                        _buildModernRoleCard('provider', 'Provide Service', Icons.handyman_rounded, theme),
                      ],
                    ),

                    const SizedBox(height: 30),


                    _buildUltraField(
                      controller: _nameController,
                      hint: 'Full Name',
                      icon: Icons.person_outline_rounded,
                      isDark: isDark,
                      validator: (v) => v!.isEmpty ? 'Name required' : null,
                    ),
                    const SizedBox(height: 16),
                    _buildUltraField(
                      controller: _emailController,
                      hint: 'Email Address',
                      icon: Icons.alternate_email_rounded,
                      isDark: isDark,
                      type: TextInputType.emailAddress,
                      validator: (v) => !v!.contains('@') ? 'Invalid email' : null,
                    ),
                    const SizedBox(height: 16),
                    _buildUltraField(
                      controller: _phoneController,
                      hint: 'Phone Number',
                      icon: Icons.phone_enabled_outlined,
                      isDark: isDark,
                      type: TextInputType.phone,
                      validator: (v) => v!.isEmpty ? 'Phone required' : null,
                    ),
                    const SizedBox(height: 16),
                    _buildUltraField(
                      controller: _passwordController,
                      hint: 'Password',
                      icon: Icons.lock_open_rounded,
                      isDark: isDark,
                      isPassword: true,
                      obscureText: _obscurePassword,
                      onToggle: () => setState(() => _obscurePassword = !_obscurePassword),
                      validator: (v) => v!.length < 6 ? 'Min. 6 characters' : null,
                    ),

                    const SizedBox(height: 40),


                    GestureDetector(
                      onTap: _isLoading ? null : _handleSignup,
                      child: Container(
                        width: double.infinity,
                        height: 62,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              theme.colorScheme.primary,
                              theme.colorScheme.primary.withOpacity(0.8),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: [
                            BoxShadow(
                              color: theme.colorScheme.primary.withOpacity(0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Center(
                          child: _isLoading
                              ? const SizedBox(height: 25, width: 25, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                              : const Text(
                            'Sign Up',
                            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),
                    Center(
                      child: TextButton(
                        onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen())),
                        child: RichText(
                          text: TextSpan(
                            text: "Already have an account? ",
                            style: TextStyle(color: Colors.grey[600]),
                            children: [
                              TextSpan(
                                text: "Login",
                                style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildModernRoleCard(String role, String title, IconData icon, ThemeData theme) {
    bool isSelected = _selectedRole == role;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedRole = role),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(vertical: 22),
          decoration: BoxDecoration(
            color: isSelected ? theme.colorScheme.primary : Colors.white,
            borderRadius: BorderRadius.circular(26),
            boxShadow: [
              BoxShadow(
                color: isSelected ? theme.colorScheme.primary.withOpacity(0.3) : Colors.black.withOpacity(0.04),
                blurRadius: 15,
                offset: const Offset(0, 8),
              )
            ],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white.withOpacity(0.2) : theme.colorScheme.primary.withOpacity(0.06),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: isSelected ? Colors.white : theme.colorScheme.primary, size: 26),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildUltraField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required bool isDark,
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? onToggle,
    TextInputType type = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword ? obscureText : false,
        keyboardType: type,
        validator: validator,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey[400], fontWeight: FontWeight.normal),
          prefixIcon: Icon(icon, size: 20, color: Colors.grey[500]),
          suffixIcon: isPassword
              ? IconButton(icon: Icon(obscureText ? Icons.visibility_off_rounded : Icons.visibility_rounded, size: 18, color: Colors.grey[500]), onPressed: onToggle)
              : null,
          filled: true,
          fillColor: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(22), borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(22), borderSide: BorderSide(color: Colors.black.withOpacity(0.01))),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(22), borderSide: BorderSide(color: Theme.of(context).colorScheme.primary.withOpacity(0.3))),
        ),
      ),
    );
  }
}