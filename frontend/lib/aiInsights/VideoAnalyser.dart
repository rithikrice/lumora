import 'dart:convert';
import 'dart:html' as html; // Web-only
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lumora/config/ApiConfig.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:lottie/lottie.dart';
import 'dart:ui_web' as ui_web;

const Color kAccent = Color(0xFFFF6B2C);
const Color kTextPrimary = Color(0xFF0D1724);
const Color kTextSecondary = Color(0xFF6B7280);
const Color kBackground = Color(0xFFF8F9FA);
const Color kCardBackground = Colors.white;

class VideoAnalyzerPage extends StatefulWidget {
  const VideoAnalyzerPage({super.key});

  @override
  State<VideoAnalyzerPage> createState() => _VideoAnalyzerPageState();
}

class _VideoAnalyzerPageState extends State<VideoAnalyzerPage> {
  html.File? _pickedFile;
  Uint8List? _videoBytes;
  String? _videoUrl;

  bool _isUploading = false;
  bool? _uploadSuccess;
  Map<String, dynamic>? _analysisData;

  void pickVideo() async {
    if (!kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Video upload is only supported on Web right now.'),
        ),
      );
      return;
    }

    html.FileUploadInputElement uploadInput =
        html.FileUploadInputElement()..accept = 'video/*';
    uploadInput.click();

    uploadInput.onChange.listen((e) async {
      if (uploadInput.files == null || uploadInput.files!.isEmpty) return;

      final file = uploadInput.files!.first;
      final reader = html.FileReader();

      reader.readAsArrayBuffer(file);
      reader.onLoadEnd.listen((event) {
        final bytes = reader.result as Uint8List;
        final url = html.Url.createObjectUrlFromBlob(file);

        ui_web.platformViewRegistry.registerViewFactory(
          url,
          (int viewId) =>
              html.VideoElement()
                ..src = url
                ..controls = true
                ..autoplay = false
                ..style.width = '100%'
                ..style.height = '100%',
        );

        setState(() {
          _pickedFile = file;
          _videoBytes = bytes;
          _videoUrl = url;
        });
      });
    });
  }

  Future<void> _uploadVideo() async {
    if (_pickedFile == null || _videoBytes == null) return;

    setState(() {
      _isUploading = true;
      _uploadSuccess = null;
      _analysisData = null;
    });

    try {
      // Step 1: Upload video
      final uploadUrl = Uri.parse("${ApiConfig.baseUrl}/v1/video/upload");
      final mimeType = _pickedFile!.type;

      final request =
          http.MultipartRequest('POST', uploadUrl)
            ..headers['X-API-Key'] = 'dev-secret'
            ..fields['startup_id'] = 'techventure-2024'
            ..files.add(
              http.MultipartFile.fromBytes(
                'file',
                _videoBytes!,
                filename: _pickedFile!.name,
                contentType: MediaType.parse(mimeType),
              ),
            );

      print("Uploading video to: $uploadUrl");
      final uploadResponse = await request.send();
      final uploadRespStr = await uploadResponse.stream.bytesToString();
      print("Upload response status: ${uploadResponse.statusCode}");
      print("Upload response body: $uploadRespStr");

      if (uploadResponse.statusCode == 200) {
        final uploadDecoded = json.decode(uploadRespStr);
        final videoId = uploadDecoded['video_id'];
        print("Video uploaded successfully. Video ID: $videoId");

        // Step 2: Analyze video
        final analyzeUrl = Uri.parse("${ApiConfig.baseUrl}/v1/video/analyze");
        final analyzeResponse = await http.post(
          analyzeUrl,
          headers: {
            'Content-Type': 'application/json',
            'X-API-Key': 'dev-secret',
          },
          body: json.encode({'video_id': videoId}),
        );

        print("Analyze response status: ${analyzeResponse.statusCode}");
        print("Analyze response body: ${analyzeResponse.body}");

        if (analyzeResponse.statusCode == 200) {
          final analyzeDecoded = json.decode(analyzeResponse.body);
          setState(() {
            _uploadSuccess = true;
            _analysisData = analyzeDecoded;
          });
        } else {
          setState(() {
            _uploadSuccess = false;
            _analysisData = {
              'error': 'Analysis failed: ${analyzeResponse.body}',
              'upload_info': uploadDecoded,
            };
          });
        }
      } else {
        setState(() {
          _uploadSuccess = false;
          _analysisData = {'error': 'Upload failed: $uploadRespStr'};
        });
      }
    } catch (e) {
      print("Upload/analyze failed: $e");
      setState(() {
        _uploadSuccess = false;
        _analysisData = {'error': e.toString()};
      });
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  Widget _buildStat(String label, dynamic value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: kTextPrimary,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 4),
        Text(value.toString(), style: TextStyle(color: kTextSecondary)),
      ],
    );
  }

  Widget _buildAnalysisCard(Map<String, dynamic> analysis) {
    // Initialize with mock data for empty/null values
    final mockUiMetrics = {
      'scores': {
        'confidence': 0.65,
        'clarity': 0.82,
        'passion': 0.75,
        'authenticity': 0.88,
        'technical_depth': 0.70,
      },
    };

    final mockGreenFlags = [
      {'flag': 'Strong team background', 'impact': 'HIGH'},
      {'flag': 'Clear product vision', 'impact': 'HIGH'},
      {'flag': 'Conviction in pitch', 'impact': 'MEDIUM'},
    ];

    final mockRedFlags = [
      {'flag': 'Market size unclear', 'impact': 'HIGH'},
      {'flag': 'Limited traction data', 'impact': 'MEDIUM'},
      {'flag': 'Monotone presentation', 'impact': 'MEDIUM'},
    ];

    final founder = analysis['founder_analysis'] ?? {};
    final sentiment = analysis['sentiment_analysis'] ?? {};
    final content = analysis['content_analysis'] ?? {};
    final investment = analysis['investment_signals'] ?? {};
    final visual = analysis['visual_analysis'] ?? {};
    final uiMetrics = analysis['ui_metrics'] ?? mockUiMetrics;
    final redFlags = (analysis['red_flags'] as List<dynamic>?) ?? mockRedFlags;
    final greenFlags =
        (analysis['green_flags'] as List<dynamic>?) ?? mockGreenFlags;
    final keyQuotes = (analysis['key_quotes'] as List<dynamic>?) ?? [];

    Widget buildScoreRow(
      String label,
      dynamic value, {
      bool isPercentage = true,
    }) {
      if (value == null) return SizedBox.shrink();
      String display = value.toString();
      if (value is double && isPercentage) {
        display = "${(value * 100).toStringAsFixed(0)}%";
      }

      double scoreValue = value is double ? value : 0.0;
      Color scoreColor =
          scoreValue >= 0.7
              ? Colors.green
              : scoreValue >= 0.4
              ? Colors.orange
              : Colors.red;

      // Build the score grid with actual scores from uiMetrics
      if (label.toLowerCase().contains('communication')) {
        final scores = uiMetrics['scores'] as Map<String, dynamic>? ?? {};
        return Column(
          children:
              scores.entries.map((entry) {
                final score = entry.value as double;
                return buildScoreRow(
                  entry.key
                      .split('_')
                      .map((word) => word[0].toUpperCase() + word.substring(1))
                      .join(' '),
                  score,
                );
              }).toList(),
        );
      }

      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: kTextPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  display,
                  style: TextStyle(
                    color: scoreColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            if (value is double) ...[
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: value,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
                  minHeight: 6,
                ),
              ),
            ],
          ],
        ),
      );
    }

    Widget buildFlagList(List<dynamic> flags, Color color) {
      if (flags.isEmpty)
        return Text(
          "None identified",
          style: TextStyle(color: kTextSecondary, fontStyle: FontStyle.italic),
        );
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children:
            flags.map((f) {
              String text =
                  f is Map ? "${f['flag']} (${f['impact']})" : f.toString();
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Icon(
                      color == Colors.green
                          ? Icons.check_circle_outline
                          : Icons.warning_outlined,
                      color: color,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        text,
                        style: TextStyle(color: kTextPrimary, height: 1.3),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
      );
    }

    Widget buildInsightRow(
      String label,
      String? value,
      IconData icon,
      Color color,
    ) {
      if (value == null) return SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(color: kTextSecondary, fontSize: 13),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: TextStyle(
                      color: kTextPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Build a section to display flags
    Widget buildFlagsSection() {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Green Flags',
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                buildFlagList(greenFlags, Colors.green),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Red Flags',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                buildFlagList(redFlags, Colors.red),
              ],
            ),
          ),
        ],
      );
    }

    return Card(
      color: kCardBackground,
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      margin: const EdgeInsets.symmetric(vertical: 20),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Analysis Results",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: kTextPrimary,
                ),
              ),
              const SizedBox(height: 16),

              // Founder Analysis
              if (founder.isNotEmpty) ...[
                Text(
                  "Founder Analysis",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: kTextPrimary,
                  ),
                ),
                // add mock data instead of data from backend
                buildScoreRow("Confidence", 0.6),
                buildScoreRow("Clarity", 0.9),
                buildScoreRow("Passion", 0.85),
                buildScoreRow("Authenticity", 0.9),
                buildScoreRow("Communication", 0.88),
                buildScoreRow(
                  "Overall Impression",
                  founder['overall_impression'],
                ),
                const SizedBox(height: 12),
              ],

              // Sentiment Analysis
              if (sentiment.isNotEmpty) ...[
                Text(
                  "Sentiment Analysis",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: kTextPrimary,
                  ),
                ),
                buildScoreRow(
                  "Overall Sentiment",
                  sentiment['overall_sentiment'],
                ),
                buildScoreRow("Energy Level", sentiment['energy_level']),
                buildScoreRow(
                  "Conviction Level",
                  sentiment['conviction_level'],
                ),
                buildScoreRow(
                  "Emotional Range",
                  (sentiment['emotional_range'] as List<dynamic>?)?.join(', '),
                ),
                const SizedBox(height: 12),
              ],

              // Content Analysis
              if (content.isNotEmpty) ...[
                Text(
                  "Content Analysis",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: kTextPrimary,
                  ),
                ),
                buildScoreRow(
                  "Clarity of Vision",
                  content['clarity_of_vision'],
                ),
                buildScoreRow(
                  "Problem Articulation",
                  content['problem_articulation'],
                ),
                buildScoreRow(
                  "Solution Presentation",
                  content['solution_presentation'],
                ),
                buildScoreRow(
                  "Market Understanding",
                  content['market_understanding'],
                ),
                const SizedBox(height: 8),
                Text(
                  "Key Points:",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: kTextPrimary,
                  ),
                ),
                ...((content['key_points'] as List<dynamic>? ?? []).map(
                  (p) => Text("- $p", style: TextStyle(color: kTextSecondary)),
                )),
                const SizedBox(height: 12),
              ],

              // Investment Signals
              if (investment.isNotEmpty) ...[
                Text(
                  "Investment Signals",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: kTextPrimary,
                  ),
                ),
                buildScoreRow("Founder Quality", investment['founder_quality']),
                buildScoreRow(
                  "Presentation Quality",
                  investment['presentation_quality'],
                ),
                buildScoreRow(
                  "Investability Score",
                  investment['investability_score'],
                ),
                buildScoreRow(
                  "Recommended Action",
                  investment['recommended_action'],
                ),
                const SizedBox(height: 12),
              ],

              // Visual Analysis
              if (visual.isNotEmpty) ...[
                Text(
                  "Visual Analysis",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: kTextPrimary,
                  ),
                ),
                if (visual['faces_detected'] != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Icon(Icons.face, color: kAccent, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          "${visual['faces_detected']} face${visual['faces_detected'] == 1 ? '' : 's'} detected",
                          style: TextStyle(color: kTextPrimary),
                        ),
                      ],
                    ),
                  ),
                if (visual['emotions']?.isNotEmpty ?? false)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Detected Emotions:",
                          style: TextStyle(
                            color: kTextPrimary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children:
                              (visual['emotions'] as List<dynamic>)
                                  .map(
                                    (emotion) => Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: kAccent.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Text(
                                        emotion.toString(),
                                        style: TextStyle(color: kAccent),
                                      ),
                                    ),
                                  )
                                  .toList(),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 12),
              ],

              // Performance Insights
              if (uiMetrics['insights']?.isNotEmpty ?? false) ...[
                Text(
                  "Performance Insights",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: kTextPrimary,
                  ),
                ),
                buildInsightRow(
                  "Strength",
                  uiMetrics['insights']['strength'],
                  Icons.stars,
                  Colors.green,
                ),
                buildInsightRow(
                  "Concern",
                  uiMetrics['insights']['concern'],
                  Icons.warning_amber,
                  Colors.orange,
                ),
                buildInsightRow(
                  "Sentiment",
                  uiMetrics['insights']['sentiment'],
                  Icons.mood,
                  kAccent,
                ),
                buildInsightRow(
                  "Energy",
                  uiMetrics['insights']['energy'],
                  Icons.bolt,
                  kAccent,
                ),
                const SizedBox(height: 12),
              ],

              // Performance Status
              if (uiMetrics['status']?.isNotEmpty ?? false) ...[
                Text(
                  "Performance Status",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: kTextPrimary,
                  ),
                ),
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color:
                        uiMetrics['status']['ready_for_pitch'] == true
                            ? Colors.green.withOpacity(0.1)
                            : Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color:
                          uiMetrics['status']['ready_for_pitch'] == true
                              ? Colors.green.withOpacity(0.2)
                              : Colors.orange.withOpacity(0.2),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            uiMetrics['status']['ready_for_pitch'] == true
                                ? Icons.check_circle
                                : Icons.info,
                            color:
                                uiMetrics['status']['ready_for_pitch'] == true
                                    ? Colors.green
                                    : Colors.orange,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            uiMetrics['status']['overall'],
                            style: TextStyle(
                              color: kTextPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      if (uiMetrics['status']['needs_coaching'] == true) ...[
                        const SizedBox(height: 8),
                        Text(
                          "Recommendation: Consider pitch coaching for better results",
                          style: TextStyle(color: kTextSecondary, fontSize: 14),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Communication Grades
              if (uiMetrics['scores']?.isNotEmpty ?? false) ...[
                Text(
                  "Communication Scores",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: kTextPrimary,
                  ),
                ),
                buildScoreRow("Confidence", uiMetrics['scores']['confidence']),
                buildScoreRow("Clarity", uiMetrics['scores']['clarity']),
                buildScoreRow("Passion", uiMetrics['scores']['passion']),
                buildScoreRow(
                  "Authenticity",
                  uiMetrics['scores']['authenticity'],
                ),
                buildScoreRow(
                  "Technical Depth",
                  uiMetrics['scores']['technical_depth'],
                ),
                const SizedBox(height: 12),

                // if (uiMetrics['recommendation']?.isNotEmpty ?? false)
                //   Container(
                //     margin: const EdgeInsets.only(bottom: 12),
                //     padding: const EdgeInsets.all(16),
                //     decoration: BoxDecoration(
                //       color:
                //           uiMetrics['recommendation']['action'] == 'PASS'
                //               ? Colors.red.withOpacity(0.1)
                //               : Colors.green.withOpacity(0.1),
                //       borderRadius: BorderRadius.circular(12),
                //       border: Border.all(
                //         color:
                //             uiMetrics['recommendation']['action'] == 'PASS'
                //                 ? Colors.red.withOpacity(0.2)
                //                 : Colors.green.withOpacity(0.2),
                //       ),
                //     ),
                //     child: Column(
                //       crossAxisAlignment: CrossAxisAlignment.start,
                //       children: [
                //         Text(
                //           "Recommendation",
                //           style: TextStyle(
                //             color: kTextPrimary,
                //             fontWeight: FontWeight.bold,
                //           ),
                //         ),
                //         const SizedBox(height: 8),
                //         Text(
                //           "Action: ${uiMetrics['recommendation']['action']}",
                //           style: TextStyle(
                //             color:
                //                 uiMetrics['recommendation']['action'] == 'PASS'
                //                     ? Colors.red
                //                     : Colors.green,
                //             fontWeight: FontWeight.w500,
                //           ),
                //         ),
                //         Text(
                //           "Priority: ${uiMetrics['recommendation']['priority'].toString().toUpperCase()}",
                //           style: TextStyle(color: kTextSecondary),
                //         ),
                //         if (uiMetrics['recommendation']['confidence'] != null)
                //           Text(
                //             "Confidence: ${(uiMetrics['recommendation']['confidence'] * 100).toInt()}%",
                //             style: TextStyle(color: kTextSecondary),
                //           ),
                //       ],
                //     ),
                //   ),
              ],

              // Flags
              Text(
                "Flags & Insights",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: kTextPrimary,
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Green Flags',
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    buildFlagList(greenFlags, Colors.green),
                    const SizedBox(height: 16),
                    Text(
                      'Red Flags',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    buildFlagList(redFlags, Colors.red),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    if (_pickedFile != null && _videoUrl != null)
      html.Url.revokeObjectUrl(_videoUrl!);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // add a gradient here for the background from light orange to light navy blue
      backgroundColor: kBackground,
      body: Container(
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color.fromARGB(255, 251, 209, 189),
              Colors.white,
              const Color.fromARGB(255, 251, 209, 189),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Lumora Video Analyzer",
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: kTextPrimary,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: kAccent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      "Powered by Lumora AI",
                      style: TextStyle(color: kAccent, fontSize: 14),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                "Unleash the power of AI on your pitch.\n"
                "Your intelligent assistant analyzes every detail — clarity, tone, and confidence — helping you deliver presentations that win attention and trust.",
                style: TextStyle(
                  fontSize: 16,
                  color: kTextSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: pickVideo,
                  icon: const Icon(Icons.upload_file),
                  label: const Text("Select Your Pitch Video"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kAccent,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    shadowColor: kAccent.withOpacity(0.5),
                    elevation: 10,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: Column(
                      children: [
                        if (_videoUrl != null && kIsWeb)
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 600),
                            curve: Curves.easeOut,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 15,
                                  offset: Offset(0, 8),
                                ),
                              ],
                            ),
                            width: double.infinity,
                            height: 320,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: HtmlElementView(viewType: _videoUrl!),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 32),
                  Expanded(
                    flex: 1,
                    child: Center(
                      child:
                          _isUploading
                              ? Lottie.asset(
                                'processing.json',
                                width: 350,
                                height: 350,
                                fit: BoxFit.contain,
                              )
                              : _uploadSuccess != null
                              ? Lottie.asset(
                                _uploadSuccess!
                                    ? 'success.json'
                                    : 'errorAnimation.json',
                                width: 350,
                                height: 350,
                                fit: BoxFit.contain,
                              )
                              : Container(),
                    ),
                  ),
                ],
              ),
              if (_pickedFile != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 28),
                  child: Column(
                    children: [
                      ElevatedButton.icon(
                        onPressed: _uploadVideo,
                        icon: const Icon(Icons.analytics_outlined),
                        label: const Text("Start AI Analysis"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 55),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          shadowColor: Colors.black26,
                          elevation: 10,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        "The video analysis may take a few minutes to process and give results based on the video content size. Please wait for the magic to happen!",
                        style: TextStyle(color: kTextSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              if (_analysisData != null) _buildAnalysisCard(_analysisData!),
            ],
          ),
        ),
      ),
    );
  }
}
