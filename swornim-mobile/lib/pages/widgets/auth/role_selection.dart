import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class RoleSelection extends StatelessWidget {
  final Map<String, Map<String, dynamic>> userRoles;
  final String selectedRole;
  final Function(String) onRoleChanged;

  const RoleSelection({
    super.key,
    required this.userRoles,
    required this.selectedRole,
    required this.onRoleChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'I am a...',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 16),
        
        // Dynamically generate rows of role cards, two per row
        Column(
          children: [
            for (int i = 0; i < userRoles.keys.length; i += 2)
              Row(
                children: [
                  Expanded(child: _buildRoleCard(userRoles.keys.elementAt(i))),
                  const SizedBox(width: 12),
                  if (i + 1 < userRoles.keys.length)
                    Expanded(child: _buildRoleCard(userRoles.keys.elementAt(i + 1)))
                  else
                    Expanded(child: Container()),
                ],
              ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Description container
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                userRoles[selectedRole]!['color'].withOpacity(0.08),
                userRoles[selectedRole]!['color'].withOpacity(0.03),
              ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: userRoles[selectedRole]!['color'].withOpacity(0.25),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: userRoles[selectedRole]!['color'].withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.info_outline,
                  size: 16,
                  color: userRoles[selectedRole]!['color'],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  userRoles[selectedRole]!['description'],
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: userRoles[selectedRole]!['color'].withOpacity(0.9),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRoleCard(String roleKey) {
    Map<String, dynamic> role = userRoles[roleKey]!;
    bool isSelected = selectedRole == roleKey;
    
    return GestureDetector(
      onTap: () => onRoleChanged(roleKey),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        height: 70,
        decoration: BoxDecoration(
          gradient: isSelected 
            ? LinearGradient(
                colors: [
                  role['color'].withOpacity(0.12),
                  role['color'].withOpacity(0.06),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : LinearGradient(
                colors: [
                  Colors.white,
                  Colors.grey.shade50,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? role['color'] : const Color(0xFFE5E7EB),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: role['color'].withOpacity(0.15),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ] : [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: isSelected 
                    ? role['color'].withOpacity(0.15)
                    : Colors.grey.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  role['icon'],
                  color: isSelected ? role['color'] : const Color(0xFF6B7280),
                  size: 18,
                ),
              ),
              
              const SizedBox(height: 4),
              
              Flexible(
                child: Text(
                  role['title'],
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                    color: isSelected ? role['color'] : const Color(0xFF6B7280),
                    height: 1.1,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}