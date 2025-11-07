import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'dart:ui_web' as ui_web;

import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart'; // ✅ Needed for MediaType
import 'package:lottie/lottie.dart';
import 'package:lumora/config/ApiConfig.dart';
import 'package:lumora/homepage/HomePage.dart';
import 'UploadIngestion.dart';

class SubmissionAnimationPage extends StatefulWidget {
  final StartupFormData formData;
  final Uint8List? videoBytes;

  const SubmissionAnimationPage({
    super.key,
    required this.formData,
    required this.videoBytes,
  });

  @override
  State<SubmissionAnimationPage> createState() =>
      _SubmissionAnimationPageState();
}

class _SubmissionAnimationPageState extends State<SubmissionAnimationPage> {
  bool isLoading = true;
  bool isSuccess = false;
  bool _isUploading = false;
  bool? _uploadSuccess;
  String? errorMessage;
  String? rawResponseBody;

  // 🔹 Video upload state
  html.File? _pickedFile;
  Uint8List? _videoBytes;
  String? _videoUrl;
  Map<String, dynamic>? _analysisData;

  @override
  void initState() {
    super.initState();
    _submitToBackend();
  }

  /// Pick a video file from browser (Web-only)
  void pickVideo() async {
    if (!kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Video upload is only supported on Web right now.'),
        ),
      );
      return;
    }

    final uploadInput = html.FileUploadInputElement()..accept = 'video/*';
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

  /// Upload video and then call /v1/video/analyze
  Future<void> _uploadVideo() async {
    if (_pickedFile == null || _videoBytes == null) return;

    setState(() {
      _isUploading = true;
      _uploadSuccess = null;
      _analysisData = null;
    });

    final uploadUrl = Uri.parse("${ApiConfig.baseUrl}/v1/video/upload");
    final mimeType = _pickedFile!.type;

    final request =
        http.MultipartRequest('POST', uploadUrl)
          ..headers['X-API-Key'] = 'dev-secret'
          ..fields['startup_id'] = 'techventure-2024'
          ..fields['video_type'] = 'pitch'
          ..files.add(
            http.MultipartFile.fromBytes(
              'file',
              _videoBytes!,
              filename: _pickedFile!.name,
              contentType: MediaType.parse(mimeType),
            ),
          );

    try {
      debugPrint("📤 Uploading video to: $uploadUrl");
      final response = await request.send();
      final respStr = await response.stream.bytesToString();
      debugPrint("⬅️ Upload response: ${response.statusCode} $respStr");

      if (response.statusCode == 200) {
        final decoded = json.decode(respStr);
        final videoId = decoded['video_id'];
        debugPrint("✅ Video uploaded. Video ID: $videoId");

        // 🔹 Now call analyze
        final analyzeUrl = Uri.parse("${ApiConfig.baseUrl}/v1/video/analyze");
        debugPrint("📤 Calling analyze API...");
        final analyzeResponse = await http.post(
          analyzeUrl,
          headers: {
            'Content-Type': 'application/json',
            'X-API-Key': 'dev-secret',
          },
          body: json.encode({'video_id': videoId}),
        );

        debugPrint(
          "⬅️ Analyze response: ${analyzeResponse.statusCode} ${analyzeResponse.body}",
        );

        if (analyzeResponse.statusCode == 200) {
          final analyzeDecoded = json.decode(analyzeResponse.body);
          setState(() {
            _uploadSuccess = true;
            _analysisData = analyzeDecoded;
          });
        } else {
          setState(() {
            _uploadSuccess = false;
            _analysisData = {'error': analyzeResponse.body};
          });
        }
      } else {
        setState(() {
          _uploadSuccess = false;
          _analysisData = {'error': respStr};
        });
      }
    } catch (e) {
      debugPrint("❌ Upload/analyze failed: $e");
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

  // ===== Helper to parse numeric fields =====
  dynamic _tryParseNumber(String s) {
    if (s.isEmpty) return s;
    final i = int.tryParse(s.replaceAll(',', '').trim());
    if (i != null) return i;
    final d = double.tryParse(s.replaceAll(',', '').trim());
    if (d != null) return d;
    return s;
  }

  double _tryParseDouble(String s) {
    if (s.isEmpty) return 0.0;
    return double.tryParse(s.replaceAll(',', '').trim()) ?? 0.0;
  }

  // ===== Submit Form Data to Backend =====
  Future<void> _submitToBackend() async {
    setState(() {
      isLoading = true;
      isSuccess = false;
      errorMessage = null;
      rawResponseBody = null;
    });

    try {
      debugPrint(
        "Entered _submitToBackend with videoBytes length: "
        "${widget.videoBytes?.lengthInBytes ?? 0}",
      );
      final payload = {
        "startup_id":
            widget.formData.companyName.replaceAll(" ", "-").toLowerCase(),
        "responses": {
          "company_name": widget.formData.companyName,
          "founding_year":
              int.tryParse(widget.formData.foundingYear) ??
              widget.formData.foundingYear,
          "industry": widget.formData.industry,
          "business_model": widget.formData.businessModel,
          "company_description": widget.formData.companyDescription,
          "headquarters": widget.formData.headquarters,
          "target_markets": widget.formData.targetMarkets,
          "arr": _tryParseNumber(widget.formData.arr),
          "mrr": _tryParseNumber(widget.formData.mrr),
          "growth_rate": _tryParseNumber(widget.formData.growthRate),
          "gross_margin": _tryParseNumber(widget.formData.grossMargin),
          "burn_rate": _tryParseNumber(widget.formData.burnRate),
          "runway": _tryParseNumber(widget.formData.runway),
          "total_customers": _tryParseNumber(widget.formData.totalCustomers),
          "fortune_500_customers": _tryParseNumber(
            widget.formData.fortune500Customers,
          ),
          "churn_rate": _tryParseDouble(widget.formData.churnRate),
          "logo_retention": _tryParseNumber(widget.formData.logoRetention),
          "nrr": _tryParseNumber(widget.formData.nrr),
          "cac": _tryParseNumber(widget.formData.cac),
          "ltv": _tryParseNumber(widget.formData.ltv),
          "customer_concentration": _tryParseNumber(
            widget.formData.customerConcentration,
          ),
          "team_size": _tryParseNumber(widget.formData.teamSize),
          "founder_names": widget.formData.founders
              .map(
                (f) =>
                    "${f.name} - ${f.role} (${f.experience} yrs, Exit:${f.exitExperience})",
              )
              .join(", "),
          "founder_experience":
              widget.formData.founders.any(
                    (f) => f.exitExperience.toLowerCase() == "yes",
                  )
                  ? "Yes"
                  : "No",
          "team_from_faang": _tryParseNumber(widget.formData.teamFromFAANG),
          "technical_team": _tryParseNumber(widget.formData.technicalTeam),
          "funding_stage": widget.formData.fundingStage,
          "total_raised": _tryParseNumber(widget.formData.totalRaised),
          "last_valuation": _tryParseNumber(widget.formData.lastValuation),
          "current_ask": _tryParseNumber(widget.formData.currentAsk),
          "target_valuation": _tryParseNumber(widget.formData.targetValuation),
          "use_of_funds": widget.formData.useOfFunds,
          "exit_strategy": widget.formData.exitStrategy,
          "investor_names": widget.formData.investorNames,
          "product_stage": widget.formData.productStage,
          "competitive_advantage": widget.formData.competitiveAdvantage,
          "tam": _tryParseNumber(widget.formData.tam),
          "pitch_deck_url": widget.formData.pitchDeckUrl,
          "financial_model_url": widget.formData.financialModelUrl,
          "video_url": widget.formData.videoUrl,
        },
      };

      final url = Uri.parse("${ApiConfig.baseUrl}/v1/questionnaire/submit");
      debugPrint("➡️ POST $url");
      debugPrint(
        "Headers: ${{"X-API-Key": "dev-secret", "Content-Type": "application/json"}}",
      );
      debugPrint("Payload: ${jsonEncode(payload)}");

      final response = await http.post(
        url,
        headers: {
          "X-API-Key": "dev-secret",
          "Content-Type": "application/json",
        },
        body: jsonEncode(payload),
      );

      debugPrint("⬅️ Response Code: ${response.statusCode}");
      debugPrint("⬅️ Response Body: ${response.body}");

      rawResponseBody = response.body;

      if (response.statusCode == 200) {
        debugPrint("inside method **************");
        final body = jsonDecode(response.body);
        if (body is Map && body["success"] == true) {
          // ✅ Profile submitted, now upload video
          if (widget.videoBytes != null) {
            debugPrint(
              "[SubmissionAnimationPage::_submitToBackend] 📤 Starting video upload...",
            );

            _videoBytes = widget.videoBytes;
            _pickedFile = html.File(
              [widget.videoBytes!],
              widget.formData.videoUrl.isNotEmpty
                  ? widget.formData.videoUrl
                  : "uploaded_pitch.mp4",
              {'type': 'video/mp4'},
            );

            await _uploadVideo();
            if (_uploadSuccess == true) {
              setState(() {
                isLoading = false;
                isSuccess = true; // Both succeeded
              });
            } else {
              setState(() {
                isLoading = false;
                isSuccess = false;
                errorMessage =
                    "Profile submitted but video upload/analyze failed";
              });
            }
          } else {
            // No video provided
            setState(() {
              isLoading = false;
              isSuccess = true;
            });
          }
          return;
        }
      }

      // Profile failed
      setState(() {
        isLoading = false;
        isSuccess = false;
        errorMessage = response.body;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        isSuccess = false;
        errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget animationWidget;
    String message;

    if (isLoading) {
      animationWidget = Lottie.asset(
        "processing.json",
        width: 220,
        height: 220,
        repeat: true,
      );
      message = "Submitting your profile...";
    } else if (isSuccess) {
      animationWidget = Lottie.asset(
        "success.json",
        width: 220,
        height: 220,
        repeat: false,
      );
      message = "Startup Profile Submitted!";
    } else {
      animationWidget = Lottie.asset(
        "errorAnimation.json",
        width: 220,
        height: 220,
        repeat: false,
      );
      message = "Submission Failed";
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(backgroundColor: kAccent, title: const Text('Submission')),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                animationWidget,
                const SizedBox(height: 20),
                Text(
                  message,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                if (!isLoading && !isSuccess && errorMessage != null) ...[
                  Container(
                    constraints: const BoxConstraints(maxHeight: 200),
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.redAccent.shade100),
                    ),
                    child: SingleChildScrollView(
                      child: SelectableText(
                        rawResponseBody ?? errorMessage ?? 'Unknown error',
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                if (!isLoading)
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const LumoraHomePage(),
                        ),
                        (route) => false,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kAccent,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 14,
                      ),
                    ),
                    child: const Text(
                      'Done',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                if (isLoading) ...[
                  const SizedBox(height: 12),
                  const Text(
                    'Please wait while we submit. Do not close this page.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: Colors.black54),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
