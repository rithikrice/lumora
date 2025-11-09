import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:lottie/lottie.dart';
import 'package:lumora/config/ApiConfig.dart';
import 'package:lumora/homepage/HomePage.dart';
import 'Animation.dart'; // Use your corrected Animation.dart

// ===== Theme Constants =====
const Color primaryColour = Color(0xFFF7F8F9);
const Color kAccent = Color(0xFFFF6B2C);
const Color kText = Color(0xFF120101);
const double kCardRadius = 14.0;

Uint8List? pickedVideoBytes;

// ===== Models =====
class Founder {
  String name = '';
  String role = '';
  String experience = '';
  String exitExperience = '';
}

class StartupFormData {
  // Company Overview
  String companyName = 'Finion';
  String foundingYear = '2023';
  String industry = 'SaaS';
  String businessModel = 'B2B SaaS';
  String companyDescription =
      'A cutting-edge fintech startup revolutionizing payments.';
  String headquarters = 'Bengaluru, India';
  String targetMarkets = 'India, Southeast Asia';

  // Product & Market
  String productStage = 'Launched';
  String competitiveAdvantage = 'We Rock AI-driven fraud detection.';
  String tam = '200000';

  // Financial Metrics
  String arr = '23545';
  String mrr = '342';
  String growthRate = '12';
  String grossMargin = '12';
  String burnRate = '34';
  String runway = '55';

  // Customer Metrics
  String totalCustomers = '43235667';
  String fortune500Customers = '1234';
  String churnRate = '34';
  String logoRetention = '45';
  String nrr = '56';
  String cac = '56';
  String ltv = '87';
  String customerConcentration = '9';

  // Team & Founders
  String teamSize = '';
  List<Founder> founders = [];
  String teamFromFAANG = '1312';
  String technicalTeam = '21';

  // Funding & Investment
  String fundingStage = 'Pre-seed';
  String totalRaised = '12354';
  String lastValuation = '4568';
  String currentAsk = '76865';
  String targetValuation = '2346';
  String useOfFunds = '321';
  String exitStrategy = '';
  String investorNames = '';

  // Additional Context
  String pitchDeckUrl = 'https://example.com/pitchdeck.pdf';
  String financialModelUrl = 'https://example.com/financialmodel.xlsx';

  // Video URL
  String videoUrl = '';
}

// ===== Multi-step Form =====
class StartupRegistrationForm extends StatefulWidget {
  final StartupFormData? initialFormData;
  const StartupRegistrationForm({super.key, this.initialFormData});

  @override
  State<StartupRegistrationForm> createState() =>
      _StartupRegistrationFormState();
}

class _StartupRegistrationFormState extends State<StartupRegistrationForm> {
  int currentPage = 0;
  late StartupFormData formData;
  final PageController pageController = PageController();

  @override
  void initState() {
    super.initState();
    formData = widget.initialFormData ?? StartupFormData();
  }

  void nextPage() {
    if (!_validatePage(currentPage)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all mandatory fields before proceeding.'),
        ),
      );
      return;
    }
    if (currentPage < 3) {
      setState(() => currentPage++);
      pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void previousPage() {
    if (currentPage > 0) {
      setState(() => currentPage--);
      pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void pickVideo() async {
    if (!kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Video upload is only supported on Web right now.'),
        ),
      );
      return;
    }

    final result = await FilePicker.platform.pickFiles(
      type: FileType.video,
      allowMultiple: false,
    );

    if (result != null && result.files.single.bytes != null) {
      final fileBytes = result.files.single.bytes!;
      final fileName = result.files.single.name;

      if (fileBytes.lengthInBytes > 10 * 1024 * 1024) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Video must be less than 10 MB')),
        );
        return;
      }

      setState(() {
        formData.videoUrl = fileName;
        pickedVideoBytes = fileBytes;
        debugPrint(
          "pickVideo set pickedVideoBytes with ${fileBytes.lengthInBytes} bytes",
        );
      });
    }
  }

  Widget _buildVideoPicker() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Video URL / Upload (Max 10 MB)',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.upload_file),
                label: const Text(' Select Video '),
                style: ElevatedButton.styleFrom(backgroundColor: kAccent),
                onPressed: pickVideo,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  formData.videoUrl.isEmpty
                      ? 'No video selected'
                      : formData.videoUrl,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Note: Video must be less than 10 MB.',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  bool _validatePage(int page) {
    switch (page) {
      case 0:
        return formData.companyName.isNotEmpty &&
            formData.foundingYear.isNotEmpty &&
            formData.companyDescription.isNotEmpty &&
            formData.headquarters.isNotEmpty &&
            formData.targetMarkets.isNotEmpty &&
            formData.productStage.isNotEmpty &&
            formData.competitiveAdvantage.isNotEmpty &&
            formData.tam.isNotEmpty;
      case 1:
        return formData.arr.isNotEmpty &&
            formData.mrr.isNotEmpty &&
            formData.growthRate.isNotEmpty &&
            formData.grossMargin.isNotEmpty &&
            formData.burnRate.isNotEmpty &&
            formData.runway.isNotEmpty &&
            formData.totalCustomers.isNotEmpty &&
            formData.fortune500Customers.isNotEmpty &&
            formData.churnRate.isNotEmpty &&
            formData.logoRetention.isNotEmpty &&
            formData.nrr.isNotEmpty &&
            formData.cac.isNotEmpty &&
            formData.ltv.isNotEmpty &&
            formData.customerConcentration.isNotEmpty;
      case 2:
        if (formData.teamSize.isEmpty) return false;
        for (var f in formData.founders) {
          if (f.name.isEmpty ||
              f.role.isEmpty ||
              f.experience.isEmpty ||
              f.exitExperience.isEmpty) {
            return false;
          }
        }
        if (formData.fundingStage.isEmpty ||
            formData.totalRaised.isEmpty ||
            formData.lastValuation.isEmpty ||
            formData.currentAsk.isEmpty ||
            formData.targetValuation.isEmpty ||
            formData.useOfFunds.isEmpty ||
            formData.exitStrategy.isEmpty ||
            formData.investorNames.isEmpty) {
          return false;
        }
        if (formData.pitchDeckUrl.isEmpty ||
            formData.financialModelUrl.isEmpty) {
          return false;
        }
        return true;
      case 3:
        return true;
      default:
        return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryColour,

      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildPage1(),
                  _buildPage2(),
                  _buildPage3(),
                  _buildPreviewPage(),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(4.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (currentPage > 0)
                    Row(
                      children: [
                        ElevatedButton(
                          onPressed: previousPage,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kAccent,
                          ),
                          child: const Text(
                            'Back',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                    ),
                  currentPage < 3
                      ? ElevatedButton(
                        onPressed: nextPage,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kAccent,
                        ),
                        child: const Text(
                          'Next',
                          style: TextStyle(color: Colors.white),
                        ),
                      )
                      : Container(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===== Pages & Helpers =====
  // _buildPage1(), _buildPage2(), _buildPage3(), _buildPreviewPage(),
  // _buildStepHeader(), _buildTextField(), _buildDropdown(),
  // _buildPreviewSection(), _buildPreviewRow()
  // All remain same as

  // ===== Page 1: Company Overview + Product & Market =====
  Widget _buildPage1() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepHeader(1, 'Company Overview', Icons.business),
          _buildTextField('Company Name', (v) => formData.companyName = v),
          _buildTextField('Founding Year', (v) => formData.foundingYear = v),
          _buildDropdown(
            'Industry',
            [
              'SaaS',
              'Fintech',
              'Healthcare',
              'E-commerce',
              'AI/ML',
              'Marketplace',
              'Hardware',
              'Other',
            ],
            formData.industry,
            (v) => setState(() => formData.industry = v),
          ),
          _buildDropdown(
            'Business Model',
            [
              'B2B SaaS',
              'B2C Subscription',
              'Marketplace',
              'Transaction-based',
              'Enterprise',
              'Freemium',
              'Other',
            ],
            formData.businessModel,
            (v) => setState(() => formData.businessModel = v),
          ),
          _buildTextField(
            'Company Description',
            (v) => formData.companyDescription = v,
          ),
          _buildTextField('Headquarters', (v) => formData.headquarters = v),
          _buildTextField(
            'Target Markets (comma-separated)',
            (v) => formData.targetMarkets = v,
          ),
          const SizedBox(height: 24),
          _buildStepHeader(2, 'Product & Market', Icons.widgets),
          _buildDropdown(
            'Product Stage',
            ['Idea', 'MVP', 'Beta', 'Launched', 'Growing', 'Scaling'],
            formData.productStage,
            (v) => setState(() => formData.productStage = v),
          ),
          _buildTextField(
            'Competitive Advantage',
            (v) => formData.competitiveAdvantage = v,
          ),
          _buildTextField(
            'Total Addressable Market (TAM) in USD',
            (v) => formData.tam = v,
          ),
        ],
      ),
    );
  }

  // ===== Page 2: Financial Metrics + Customer Metrics =====
  Widget _buildPage2() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepHeader(3, 'Financial Metrics', Icons.attach_money),
          _buildTextField(
            'Annual Recurring Revenue (ARR)',
            (v) => formData.arr = v,
          ),
          _buildTextField(
            'Monthly Recurring Revenue (MRR)',
            (v) => formData.mrr = v,
          ),
          _buildTextField(
            'Year-over-Year Growth Rate (%)',
            (v) => formData.growthRate = v,
          ),
          _buildTextField('Gross Margin (%)', (v) => formData.grossMargin = v),
          _buildTextField('Monthly Burn Rate', (v) => formData.burnRate = v),
          _buildTextField('Runway (months)', (v) => formData.runway = v),
          const SizedBox(height: 24),
          _buildStepHeader(4, 'Customer Metrics', Icons.people),
          _buildTextField(
            'Total Paying Customers',
            (v) => formData.totalCustomers = v,
          ),
          _buildTextField(
            'Fortune 500 Customers',
            (v) => formData.fortune500Customers = v,
          ),
          _buildTextField(
            'Monthly Churn Rate (%)',
            (v) => formData.churnRate = v,
          ),
          _buildTextField(
            'Annual Logo Retention (%)',
            (v) => formData.logoRetention = v,
          ),
          _buildTextField(
            'Net Revenue Retention (NRR %)',
            (v) => formData.nrr = v,
          ),
          _buildTextField(
            'Customer Acquisition Cost (CAC)',
            (v) => formData.cac = v,
          ),
          _buildTextField(
            'Customer Lifetime Value (LTV)',
            (v) => formData.ltv = v,
          ),
          _buildTextField(
            'Top 10 Customers Revenue Concentration (%)',
            (v) => formData.customerConcentration = v,
          ),
        ],
      ),
    );
  }

  // ===== Helper for section headers =====
  Widget _buildStepHeader(int step, String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: kAccent,
            child: Text(
              '$step',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Icon(icon, color: kAccent),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const Expanded(child: Divider(thickness: 1, indent: 12)),
        ],
      ),
    );
  }

  // ===== Generic Text Field Builder =====
  Widget _buildTextField(String label, ValueChanged<String> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(kCardRadius),
          ),
        ),
      ),
    );
  }

  // ===== Generic Dropdown Builder =====
  Widget _buildDropdown(
    String label,
    List<String> options,
    String value,
    ValueChanged<String> onChanged, // keep this as non-nullable
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(kCardRadius),
          ),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: value,
            isExpanded: true,
            onChanged: (String? v) {
              if (v != null) {
                onChanged(v); // call your original non-nullable callback
              }
            },
            items:
                options
                    .map((o) => DropdownMenuItem(value: o, child: Text(o)))
                    .toList(),
          ),
        ),
      ),
    );
  }

  // ===== Page 3: Team & Founders + Funding & Investment =====
  Widget _buildPage3() {
    int teamCount = int.tryParse(formData.teamSize) ?? 0;
    // Only adjust founders list if team size changed
    if (formData.founders.length != teamCount) {
      final existing = formData.founders;
      formData.founders = List.generate(teamCount, (i) {
        if (i < existing.length) return existing[i];
        return Founder();
      });
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepHeader(5, 'Team & Founders', Icons.group),
          _buildTextField('Team Size', (v) {
            setState(() {
              formData.teamSize = v;
              int count = int.tryParse(v) ?? 0;
              final existing = formData.founders;
              formData.founders = List.generate(count, (i) {
                if (i < existing.length) return existing[i];
                return Founder();
              });
            });
          }),
          const SizedBox(height: 12),
          ...formData.founders.asMap().entries.map((entry) {
            int idx = entry.key;
            Founder f = entry.value;
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(kCardRadius),
              ),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Founder ${idx + 1}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    _buildTextField('Name', (v) => f.name = v),
                    _buildTextField('Role', (v) => f.role = v),
                    _buildTextField(
                      'Experience (yrs)',
                      (v) => f.experience = v,
                    ),
                    _buildDropdown(
                      'Exit Experience',
                      ['Yes', 'No'],
                      f.exitExperience.isEmpty ? 'No' : f.exitExperience,
                      (v) => setState(() => f.exitExperience = v),
                    ),
                  ],
                ),
              ),
            );
          }),

          const SizedBox(height: 24),
          _buildStepHeader(
            6,
            'Funding & Investment',
            Icons.account_balance_wallet,
          ),
          _buildDropdown(
            'Funding Stage',
            [
              'Pre-seed',
              'Seed',
              'Series A',
              'Series B',
              'Series C+',
              'Bootstrapped',
            ],
            formData.fundingStage,
            (v) => setState(() => formData.fundingStage = v),
          ),
          _buildTextField(
            'Total Raised (USD)',
            (v) => formData.totalRaised = v,
          ),
          _buildTextField(
            'Last Valuation (USD)',
            (v) => formData.lastValuation = v,
          ),
          _buildTextField('Current Ask (USD)', (v) => formData.currentAsk = v),
          _buildTextField(
            'Target Valuation (USD)',
            (v) => formData.targetValuation = v,
          ),
          _buildTextField('Use of Funds', (v) => formData.useOfFunds = v),
          _buildTextField('Exit Strategy', (v) => formData.exitStrategy = v),
          _buildTextField('Investor Names', (v) => formData.investorNames = v),
          const SizedBox(height: 24),
          _buildStepHeader(
            7,
            'Additional Context & Media',
            Icons.insert_drive_file,
          ),
          _buildTextField('Pitch Deck URL', (v) => formData.pitchDeckUrl = v),
          _buildTextField(
            'Financial Model URL',
            (v) => formData.financialModelUrl = v,
          ),
          _buildVideoPicker(),
        ],
      ),
    );
  }

  // ===== Page 4: Preview + Submit =====
  Widget _buildPreviewPage() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Preview Your Startup Profile',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          ),
          const SizedBox(height: 16),
          _buildPreviewSection('Company Overview', [
            _buildPreviewRow('Company Name', formData.companyName),
            _buildPreviewRow('Founding Year', formData.foundingYear),
            _buildPreviewRow('Industry', formData.industry),
            _buildPreviewRow('Business Model', formData.businessModel),
            _buildPreviewRow(
              'Company Description',
              formData.companyDescription,
            ),
            _buildPreviewRow('Headquarters', formData.headquarters),
            _buildPreviewRow('Target Markets', formData.targetMarkets),
          ]),
          _buildPreviewSection('Product & Market', [
            _buildPreviewRow('Product Stage', formData.productStage),
            _buildPreviewRow(
              'Competitive Advantage',
              formData.competitiveAdvantage,
            ),
            _buildPreviewRow('Total Addressable Market (TAM)', formData.tam),
          ]),
          _buildPreviewSection('Financial Metrics', [
            _buildPreviewRow('ARR', formData.arr),
            _buildPreviewRow('MRR', formData.mrr),
            _buildPreviewRow('Growth Rate (%)', formData.growthRate),
            _buildPreviewRow('Gross Margin (%)', formData.grossMargin),
            _buildPreviewRow('Burn Rate', formData.burnRate),
            _buildPreviewRow('Runway (months)', formData.runway),
          ]),
          _buildPreviewSection('Customer Metrics', [
            _buildPreviewRow('Total Customers', formData.totalCustomers),
            _buildPreviewRow(
              'Fortune 500 Customers',
              formData.fortune500Customers,
            ),
            _buildPreviewRow('Churn Rate (%)', formData.churnRate),
            _buildPreviewRow('Logo Retention (%)', formData.logoRetention),
            _buildPreviewRow('Net Revenue Retention (NRR %)', formData.nrr),
            _buildPreviewRow('CAC', formData.cac),
            _buildPreviewRow('LTV', formData.ltv),
            _buildPreviewRow(
              'Top 10 Customers Revenue (%)',
              formData.customerConcentration,
            ),
          ]),
          _buildPreviewSection('Team & Founders', [
            _buildPreviewRow('Team Size', formData.teamSize),
            _buildPreviewRow(
              'Team from FAANG/Top Tech',
              formData.teamFromFAANG,
            ),
            _buildPreviewRow('Technical Team (%)', formData.technicalTeam),
            const SizedBox(height: 8),
            // Add each founder
            ...formData.founders.asMap().entries.map((entry) {
              int idx = entry.key;
              Founder f = entry.value;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Founder ${idx + 1}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  _buildPreviewRow('Name', f.name),
                  _buildPreviewRow('Role', f.role),
                  _buildPreviewRow('Experience (yrs)', f.experience),
                  _buildPreviewRow('Exit Experience', f.exitExperience),
                  const SizedBox(height: 8),
                ],
              );
            }).toList(),
          ]),
          _buildPreviewSection('Funding & Investment', [
            _buildPreviewRow('Funding Stage', formData.fundingStage),
            _buildPreviewRow('Total Raised (USD)', formData.totalRaised),
            _buildPreviewRow('Last Valuation (USD)', formData.lastValuation),
            _buildPreviewRow('Current Ask (USD)', formData.currentAsk),
            _buildPreviewRow(
              'Target Valuation (USD)',
              formData.targetValuation,
            ),
            _buildPreviewRow('Use of Funds', formData.useOfFunds),
            _buildPreviewRow('Exit Strategy', formData.exitStrategy),
            _buildPreviewRow('Investor Names', formData.investorNames),
          ]),
          _buildPreviewSection('Additional Context & Media', [
            _buildPreviewRow('Pitch Deck URL', formData.pitchDeckUrl),
            _buildPreviewRow('Financial Model URL', formData.financialModelUrl),
            _buildPreviewRow('Video URL', formData.videoUrl),
          ]),
          const SizedBox(height: 24),

          // SubmissionAnimationPage(
          //   formData: formData,
          //   videoBytes: pickedVideoBytes,
          // ),
          Center(
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (_) => SubmissionAnimationPage(
                          formData: formData,
                          videoBytes: pickedVideoBytes,
                        ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: kAccent,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
              child: const Text(
                'Submit Startup Profile',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ===== Preview Section Builder =====
  Widget _buildPreviewSection(String title, List<Widget> children) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(kCardRadius),
      ),
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  // ===== Preview Row Builder =====
  Widget _buildPreviewRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 180,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value.isEmpty ? '—' : value)),
        ],
      ),
    );
  }
}

// // ===== Submit Button With Backend Integration =====
// class SubmitButtonWithAnimation extends StatefulWidget {
//   final StartupFormData formData;
//   final Uint8List? videoBytes;

//   const SubmitButtonWithAnimation({
//     super.key,
//     required this.formData,
//     required this.videoBytes,
//   });

//   @override
//   State<SubmitButtonWithAnimation> createState() =>
//       _SubmitButtonWithAnimationState();
// }

// class _SubmitButtonWithAnimationState extends State<SubmitButtonWithAnimation> {
//   bool loading = false;

//   Future<void> _openAnimationAndSubmit() async {
//     setState(() => loading = true);

//     try {
//       Navigator.push(
//         context,
//         MaterialPageRoute(
//           builder:
//               (_) => SubmissionAnimationPage(
//                 formData: widget.formData,
//                 videoBytes: widget.videoBytes,
//               ),
//         ),
//       );
//     } finally {
//       setState(() => loading = false);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Center(
//       child: ElevatedButton(
//         onPressed: loading ? null : _openAnimationAndSubmit,
//         style: ElevatedButton.styleFrom(
//           backgroundColor: kAccent,
//           padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
//         ),
//         child:
//             loading
//                 ? const SizedBox(
//                   width: 20,
//                   height: 20,
//                   child: CircularProgressIndicator(
//                     color: Colors.white,
//                     strokeWidth: 2,
//                   ),
//                 )
//                 : const Text(
//                   'Submit Profile',
//                   style: TextStyle(
//                     fontSize: 16,
//                     fontWeight: FontWeight.bold,
//                     color: Colors.white,
//                   ),
//                 ),
//       ),
//     );
//   }
// }
