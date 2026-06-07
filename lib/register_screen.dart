import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'providers/user_provider.dart';
import 'main.dart';
import 'dashboard_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _selectedGender;
  DateTime? _selectedDOB;

  @override
  void dispose() {
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime(2000, 1, 1),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF3366FF),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );
    if (date != null) {
      setState(() => _selectedDOB = date);
    }
  }

  void _register() async {
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      _showSnackBar('Harap isi semua field yang wajib');
      return;
    }
    if (password != confirmPassword) {
      _showSnackBar('Password tidak cocok');
      return;
    }
    if (password.length < 6) {
      _showSnackBar('Password minimal 6 karakter');
      return;
    }

    final userProvider = context.read<UserProvider>();
    final success = await userProvider.register(
      namaLengkap: email.split('@').first, // Default name from email
      email: email,
      password: password,
      noHp: phone.isNotEmpty ? phone : null,
      tanggalLahir: _selectedDOB,
      jenisKelamin: _selectedGender,
    );

    if (mounted) {
      if (success) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const DashboardScreen()),
          (route) => false,
        );
      } else {
        _showSnackBar(userProvider.errorMessage ?? 'Gagal mendaftar');
      }
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFE11D48),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFE8F0FE), Color(0xFFF3F4F9)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 40,
                    offset: const Offset(0, 20),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Gradient top bar
                  Container(
                    height: 8,
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF3366FF), Color(0xFF8B5CF6)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(24),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32.0,
                      vertical: 40.0,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Header
                        Text(
                          'My Wallet',
                          style: GoogleFonts.poppins(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: Colors.black87,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Create your financial atelier',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 40),

                        // Email field
                        _buildLabel('Email'),
                        _buildTextField(
                          controller: _emailController,
                          icon: Icons.email_outlined,
                          hint: 'name@example.com',
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 24),

                        // No HP field
                        _buildLabel('No HP'),
                        _buildTextField(
                          controller: _phoneController,
                          icon: Icons.phone_iphone,
                          hint: '+62 812 3456 7890',
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 24),

                        // Gender & DOB row
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Gender
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildLabel('Jenis Kelamin'),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF5F6F8),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                    ),
                                    child: DropdownButtonHideUnderline(
                                      child: DropdownButton<String>(
                                        value: _selectedGender,
                                        hint: Text(
                                          'Pilih',
                                          style: GoogleFonts.inter(
                                            fontSize: 14,
                                            color: Colors.grey.shade400,
                                          ),
                                        ),
                                        isExpanded: true,
                                        icon: Icon(
                                          Icons.expand_more,
                                          color: Colors.grey.shade500,
                                        ),
                                        style: GoogleFonts.inter(
                                          fontSize: 14,
                                          color: Colors.black87,
                                        ),
                                        items: const [
                                          DropdownMenuItem(
                                            value: 'Pria',
                                            child: Text('Pria'),
                                          ),
                                          DropdownMenuItem(
                                            value: 'Wanita',
                                            child: Text('Wanita'),
                                          ),
                                        ],
                                        onChanged: (val) {
                                          setState(
                                            () => _selectedGender = val,
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            // DOB
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildLabel('Tanggal Lahir'),
                                  GestureDetector(
                                    onTap: _pickDate,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 15,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF5F6F8),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              _selectedDOB != null
                                                  ? '${_selectedDOB!.day}/${_selectedDOB!.month}/${_selectedDOB!.year}'
                                                  : 'dd/mm/yyyy',
                                              style: GoogleFonts.inter(
                                                fontSize: 14,
                                                color: _selectedDOB != null
                                                    ? Colors.black87
                                                    : Colors.grey.shade400,
                                              ),
                                            ),
                                          ),
                                          Icon(
                                            Icons.calendar_today,
                                            size: 18,
                                            color: Colors.grey.shade500,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Password field
                        _buildLabel('Password'),
                        _buildTextField(
                          controller: _passwordController,
                          icon: Icons.lock_outline,
                          hint: '••••••••',
                          isPassword: true,
                          obscure: _obscurePassword,
                          onToggleObscure: () {
                            setState(
                              () => _obscurePassword = !_obscurePassword,
                            );
                          },
                        ),
                        const SizedBox(height: 24),

                        // Confirm Password field
                        _buildLabel('Ulangi Password'),
                        _buildTextField(
                          controller: _confirmPasswordController,
                          icon: Icons.lock_reset,
                          hint: '••••••••',
                          isPassword: true,
                          obscure: _obscureConfirmPassword,
                          onToggleObscure: () {
                            setState(
                              () =>
                                  _obscureConfirmPassword =
                                      !_obscureConfirmPassword,
                            );
                          },
                        ),
                        const SizedBox(height: 32),

                        // Submit button
                        Consumer<UserProvider>(
                          builder: (context, userProvider, _) {
                            return Container(
                              width: double.infinity,
                              height: 56,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF3366FF),
                                    Color(0xFF8B5CF6),
                                  ],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
                                borderRadius: BorderRadius.circular(28),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(
                                      0xFF3366FF,
                                    ).withOpacity(0.2),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                onPressed: userProvider.isLoading
                                    ? null
                                    : _register,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(28),
                                  ),
                                ),
                                child: userProvider.isLoading
                                    ? const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : Text(
                                        'Buat Akun',
                                        style: GoogleFonts.poppins(
                                          fontSize: 16,
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 32),

                        // Login link
                        GestureDetector(
                          onTap: () {
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(
                                builder: (_) => const LoginScreen(),
                              ),
                            );
                          },
                          child: Text(
                            'Sudah buat akun? Login',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF3366FF),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          width: 48,
                          height: 1,
                          color: Colors.grey.shade200,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.help_outline,
                              color: Colors.grey.shade600,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Pusat Bantuan',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          text,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required IconData icon,
    required String hint,
    TextInputType? keyboardType,
    bool isPassword = false,
    bool obscure = false,
    VoidCallback? onToggleObscure,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF5F6F8),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword && obscure,
        keyboardType: keyboardType,
        style: GoogleFonts.inter(
          fontSize: 14,
          letterSpacing: isPassword ? 2.0 : 0,
        ),
        decoration: InputDecoration(
          border: InputBorder.none,
          prefixIcon: Icon(icon, color: Colors.grey.shade500, size: 20),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    obscure ? Icons.visibility_off : Icons.visibility,
                    color: Colors.grey.shade500,
                    size: 20,
                  ),
                  onPressed: onToggleObscure,
                )
              : null,
          hintText: hint,
          hintStyle: GoogleFonts.inter(
            color: Colors.grey.shade400,
            fontSize: 14,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }
}
