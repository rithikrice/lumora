import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:html' as html;
import 'package:lumora/config/ApiConfig.dart';

class ProfileHeader extends StatelessWidget {
  final Map<String, dynamic>? data;

  const ProfileHeader({super.key, this.data});

  @override
  Widget build(BuildContext context) {
    // Colors (kept same as original)
    const Color kAccent1 = Color(0xFFFF6B2C);
    const Color kAccent2 = Color.fromARGB(255, 62, 44, 255);
    const Color kCard = Colors.white;
    const Color kTextPrimary = Color(0xFF0D1724);
    const Color kTextSecondary = Color(0xFF6B7280);

    // Use provided data or fallback to dummy
    final name = data?['name'] ?? 'StellarPay';
    final pitch =
        data?['pitch'] ?? 'Democratizing cross-border payments for SMBs';
    final meta = data?['meta'] ?? 'Fintech • Series A • India';
    final founded = data?['founded'] ?? '2019';
    final revenue = data?['revenue'] ?? '\$12M ARR';
    final funding = data?['funding'] ?? '\$22M';
    final runway = data?['runway'] ?? '18 months';

    return Card(
      color: kCard,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Logo
            CircleAvatar(
              radius: 40,
              backgroundColor: kAccent1.withOpacity(0.2),
              child: Icon(
                data?['founding_team'] ?? Icons.business,
                color: kAccent1,
                size: 35,
              ),
            ),
            const SizedBox(width: 20),

            // Info section
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: GoogleFonts.inter(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: kTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    pitch,
                    style: GoogleFonts.inter(
                      color: kTextSecondary,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    meta,
                    style: GoogleFonts.inter(
                      color: kTextSecondary,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 15),
                  Wrap(
                    spacing: 25,
                    runSpacing: 8,
                    children: [
                      _InfoStat(label: "Founded", value: founded),
                      _InfoStat(label: "Revenue", value: revenue),
                      _InfoStat(label: "Funding Raised", value: funding),
                      _InfoStat(label: "Runway", value: runway),
                    ],
                  ),
                ],
              ),
            ),

            // Action Buttons
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                ElevatedButton(
                  onPressed: () async {
                    try {
                      final url = Uri.parse('${ApiConfig.baseUrl}/v1/export');
                      final response = await http.post(
                        url,
                        headers: {
                          'Content-Type': 'application/json',
                          'X-API-Key': 'dev-secret',
                        },
                        body: jsonEncode({
                          'startup_id':
                              data?['startup_id'] ??
                              'test-pitch-deck-1761378955',
                          'format': 'gdoc',
                          'include_evidence': true,
                          'include_appendix': true,
                        }),
                      );

                      // Check if backend returned the file directly
                      if (response.statusCode == 200) {
                        // Try to detect if it's JSON or file bytes
                        final contentType =
                            response.headers['content-type'] ?? '';

                        if (contentType.contains('application/json')) {
                          // It's JSON (e.g. export success message, not file)
                          final responseData = jsonDecode(response.body);
                          if (responseData['success'] == true) {
                            throw Exception(
                              "The API returned metadata, not file bytes. The backend may not be configured to stream the file in this mode.",
                            );
                          } else {
                            throw Exception(
                              responseData['message'] ?? 'Unknown export error',
                            );
                          }
                        } else {
                          // It's a downloadable file stream — save to disk (web)
                          final blob = html.Blob([response.bodyBytes]);
                          final fileName =
                              'report_${data?['startup_id'] ?? 'export'}.html';
                          final url = html.Url.createObjectUrlFromBlob(blob);

                          final anchor =
                              html.AnchorElement(href: url)
                                ..download = fileName
                                ..click();

                          html.Url.revokeObjectUrl(url);

                          if (context.mounted) {
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  title: Row(
                                    children: [
                                      Icon(
                                        Icons.check_circle,
                                        color: Colors.green,
                                        size: 24,
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        'Success!',
                                        style: GoogleFonts.poppins(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  content: Text(
                                    'Your report has been downloaded successfully.',
                                    style: GoogleFonts.inter(fontSize: 16),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed:
                                          () => Navigator.of(context).pop(),
                                      child: Text(
                                        'OK',
                                        style: GoogleFonts.inter(
                                          color: Colors.green,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            );
                          }
                        }
                      } else {
                        throw Exception(
                          'Export failed: ${response.statusCode}',
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Export failed: ${e.toString()}'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },

                  style: ElevatedButton.styleFrom(
                    backgroundColor: kAccent1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 14,
                    ),
                  ),
                  child: Text(
                    "Export PDF",
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      color: kCard,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kAccent2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 14,
                    ),
                  ),
                  child: Text(
                    "Generate Term Sheet",
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      color: kCard,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoStat extends StatelessWidget {
  final String label;
  final String value;
  const _InfoStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    const Color kTextPrimary = Color(0xFF0D1724);
    const Color kTextSecondary = Color(0xFF6B7280);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            color: kTextSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: kTextPrimary,
          ),
        ),
      ],
    );
  }
}
