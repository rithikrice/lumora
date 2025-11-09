import 'dart:ui';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lumora/upload/UploadIngestion.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:lumora/config/ApiConfig.dart';

class DocumentUploadScreen extends StatefulWidget {
  const DocumentUploadScreen({super.key});

  @override
  State<DocumentUploadScreen> createState() => _DocumentUploadScreenState();
}

class _DocumentUploadScreenState extends State<DocumentUploadScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isDragging = false;
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  String? _errorMessage;
  PlatformFile? _selectedFile;
  StartupFormData formData = StartupFormData();

  // --- Refined Theme Colors ---
  final Color kAccent = const Color(0xFFF35B04);
  final Color kBackgroundTop = const Color(0xFFF6F7FA);
  final Color kBackgroundBottom = const Color(0xFFEFF1F5);
  final Color kCard = Colors.white;
  static const Color kTextPrimary = Color(0xFF1B1F27);
  static const Color kTextSecondary = Color(0xFF6B7280);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _setDefaultValues();
  }

  void _setDefaultValues() {
    formData.companyName = "Cashvisory";
    formData.foundingYear = "2021";
    formData.industry = "Fintech";
    formData.businessModel = "B2B SaaS";
    formData.companyDescription =
        "AI-driven financial wellness platform helping users optimize savings, investments, and taxes.";
    formData.headquarters = "Bengaluru, India";
    formData.targetMarkets = "India, Southeast Asia";

    formData.productStage = "Launched";
    formData.competitiveAdvantage =
        "Proprietary AI scoring model and deep integrations with major banks.";
    formData.tam = "2150000000";

    formData.arr = "2000000";
    formData.mrr = "180000";
    formData.growthRate = "120";
    formData.grossMargin = "82";
    formData.burnRate = "50000";
    formData.runway = "18";

    formData.totalCustomers = "1200";
    formData.fortune500Customers = "3";
    formData.churnRate = "5";
    formData.logoRetention = "95";
    formData.nrr = "125";
    formData.cac = "300";
    formData.ltv = "1200";
    formData.customerConcentration = "15";

    formData.teamSize = "3";
    formData.founders = [
      Founder()
        ..name = "Sumalata Kamat"
        ..role = "CEO"
        ..experience = "10"
        ..exitExperience = "Yes",
      Founder()
        ..name = "Divya Krishna"
        ..role = "CTO"
        ..experience = "8"
        ..exitExperience = "No",
      Founder()
        ..name = "Karthik Chandrashekhar"
        ..role = "CFO"
        ..experience = "12"
        ..exitExperience = "Yes",
    ];

    formData.teamFromFAANG = "2";
    formData.technicalTeam = "70";

    formData.fundingStage = "Seed";
    formData.totalRaised = "1800000";
    formData.lastValuation = "7200000";
    formData.currentAsk = "1500000";
    formData.targetValuation = "10000000";
    formData.useOfFunds =
        "Team expansion, go-to-market, and AI model training.";
    formData.exitStrategy = "IPO or strategic acquisition by fintech major.";
    formData.investorNames = "Gradient Ventures, Blume Capital";

    formData.pitchDeckUrl =
        "https://storage.googleapis.com/lumora-datasets/pitchdeck/cashvisory-sep-2025.pdf";
    formData.financialModelUrl =
        "https://storage.googleapis.com/lumora-datasets/models/cashvisory-finmodel.xlsx";
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: false,
      );

      if (result != null) {
        final file = result.files.first;
        if (file.size > 50 * 1024 * 1024) {
          // 50MB in bytes
          setState(() {
            _errorMessage = 'File size exceeds 50MB limit';
            _selectedFile = null;
          });
          return;
        }
        setState(() {
          _selectedFile = file;
          _errorMessage = null;
          _startUpload(file);
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error picking file: ${e.toString()}';
      });
    }
  }

  Future<void> _startUpload(PlatformFile file) async {
    setState(() {
      _isUploading = true;
      _uploadProgress = 0;
    });

    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/v1/pitch-deck/upload');

      // Create multipart request
      final request =
          http.MultipartRequest('POST', url)
            ..headers.addAll({
              'accept': 'application/json',
              'X-API-Key': 'dev-secret',
            })
            ..fields['startup_id'] =
                'shametha the great'; // You might want to make this configurable

      // Add file data - handling both web and native platforms
      if (file.bytes != null) {
        // Web platform
        request.files.add(
          http.MultipartFile.fromBytes(
            'file',
            file.bytes!,
            filename: file.name,
          ),
        );
      } else if (file.path != null) {
        // Native platforms
        request.files.add(
          await http.MultipartFile.fromPath(
            'file',
            file.path!,
            filename: file.name,
          ),
        );
      }

      // Send request and show progress
      setState(() => _uploadProgress = 0.3);

      final streamedResponse = await request.send();
      setState(() => _uploadProgress = 0.6);

      // Handle response
      final responseBody = await streamedResponse.stream.bytesToString();
      setState(() => _uploadProgress = 0.9);

      if (streamedResponse.statusCode == 200) {
        final responseData = jsonDecode(responseBody);
        print('Upload successful: $responseData');
        setState(() {
          _isUploading = false;
          _uploadProgress = 1.0;
        });
      } else {
        throw Exception(
          'Upload failed with status: ${streamedResponse.statusCode}, body: $responseBody',
        );
      }
    } catch (e) {
      print('Upload error: $e');
      setState(() {
        _isUploading = false;
        _errorMessage = 'Upload failed: ${e.toString()}';
      });
    }
  }

  void _handleFileDrop(dynamic data) {
    _pickFile(); // For web, we'll use the file picker as a fallback
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundTop,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 20),
            _buildTabBar(),
            const SizedBox(height: 28),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildUploadTab(),
                  StartupRegistrationForm(initialFormData: formData),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- HEADER ---
  Widget _buildHeader() {
    return Container(
      color: kAccent,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Row(
          children: [
            _circleButton(
              icon: Icons.arrow_back_rounded,
              onPressed: () => Navigator.pop(context),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Add New Startup",
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Upload documents or fill questionnaire",
                  style: GoogleFonts.inter(fontSize: 14, color: Colors.white),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --- TAB BAR ---
  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
          color: kAccent,
          borderRadius: BorderRadius.circular(12),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: kTextPrimary.withOpacity(0.7),
        labelStyle: GoogleFonts.poppins(
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
        tabs: const [
          Tab(icon: Icon(Icons.upload_rounded), text: "Upload Documents"),
          Tab(icon: Icon(Icons.edit_note_rounded), text: "Manual Entry"),
        ],
      ),
    );
  }

  // --- UPLOAD TAB ---
  Widget _buildUploadTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDragDropBox(),
          const SizedBox(height: 40),
          Text(
            "What gets extracted:",
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: kTextPrimary,
            ),
          ),
          const SizedBox(height: 20),
          Wrap(
            runSpacing: 18,
            spacing: 18,
            children: [
              _buildExtractionType(
                icon: Icons.text_fields_rounded,
                title: "All Text",
                description: "Every word from every slide",
              ),
              _buildExtractionType(
                icon: Icons.bar_chart_rounded,
                title: "Charts & Graphs",
                description: "Visual data with market vision",
              ),
              _buildExtractionType(
                icon: Icons.attach_money_rounded,
                title: "Metrics",
                description: "ARR, growth, customer count",
              ),
              _buildExtractionType(
                icon: Icons.auto_awesome_rounded,
                title: "AI Summary",
                description: "Instant smart analysis ",
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- DRAG & DROP BOX ---
  Widget _buildDragDropBox() {
    return DragTarget<String>(
      onWillAccept: (data) {
        setState(() => _isDragging = true);
        return true;
      },
      onAccept: (data) {
        setState(() => _isDragging = false);
        _handleFileDrop(data);
      },
      onLeave: (data) => setState(() => _isDragging = false),
      builder: (context, candidateData, rejectedData) {
        return GestureDetector(
          onTap: _isUploading ? null : _pickFile,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: 260,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: _isDragging ? kAccent : Colors.grey.shade300,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_isUploading) ...[
                    SizedBox(
                      width: 48,
                      height: 48,
                      child: CircularProgressIndicator(
                        value: _uploadProgress,
                        strokeWidth: 3,
                        valueColor: AlwaysStoppedAnimation<Color>(kAccent),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Uploading... ${(_uploadProgress * 100).toInt()}%',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: kTextSecondary,
                      ),
                    ),
                  ] else ...[
                    AnimatedScale(
                      scale: _isDragging ? 1.1 : 1.0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        _selectedFile != null
                            ? Icons.check_circle
                            : Icons.cloud_upload_rounded,
                        size: 64,
                        color:
                            _selectedFile != null
                                ? Colors.green
                                : (_isDragging
                                    ? kAccent
                                    : Colors.grey.shade500),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      _selectedFile != null
                          ? _selectedFile!.name
                          : "Drag & Drop PDF here",
                      style: GoogleFonts.poppins(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: kTextPrimary,
                      ),
                    ),
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        _errorMessage!,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Colors.red,
                        ),
                      ),
                    ] else ...[
                      const SizedBox(height: 8),
                      Text(
                        _selectedFile != null
                            ? "File ready for processing"
                            : "or click to browse",
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: kTextSecondary,
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Text(
                      "PDF only • Max 50MB",
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: kTextSecondary.withOpacity(0.6),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // --- EXTRACTION CARD ---
  Widget _buildExtractionType({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: 292,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: kAccent.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            padding: const EdgeInsets.all(10),
            child: Icon(icon, color: kAccent, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: kTextPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: GoogleFonts.inter(fontSize: 13, color: kTextSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- CIRCLE BUTTON ---
  Widget _circleButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(50),
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.07),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, color: kAccent, size: 24),
      ),
    );
  }
}
