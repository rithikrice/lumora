// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';

// import 'package:lumora/config/ApiConfig.dart';

// class AIChatScreen extends StatefulWidget {
//   final String startupId;

//   const AIChatScreen({super.key, required this.startupId});

//   @override
//   State<AIChatScreen> createState() => _AIChatScreenState();
// }

// class _AIChatScreenState extends State<AIChatScreen> {
//   final TextEditingController _controller = TextEditingController();
//   final ScrollController _scrollController = ScrollController();
//   bool _isLoading = false;

//   final List<Map<String, dynamic>> _messages = [
//     {
//       "sender": "Lumora AI",
//       "message":
//           "👋 Hi there! I'm Lumora — your personal startup assistant. How can I help you today?",
//       "isUser": false,
//     },
//   ];

//   Future<void> _sendMessage() async {
//     final text = _controller.text.trim();
//     if (text.isEmpty) return;

//     setState(() {
//       _messages.add({"sender": "You", "message": text, "isUser": true});
//       _controller.clear();
//       _isLoading = true;
//     });

//     _scrollToBottom();

//     try {
//       final url = Uri.parse("${ApiConfig.baseUrl}/v1/ask");
//       final payload = {
//         "startup_id": widget.startupId,
//         "question": text,
//         "max_chunks": 10,
//       };

//       final response = await http.post(
//         url,
//         headers: {
//           'accept': 'application/json',
//           "Content-Type": "application/json",
//           'X-API-Key': 'dev-secret',
//         },
//         body: jsonEncode(payload),
//       );

//       if (response.statusCode == 200) {
//         final data = jsonDecode(response.body);
//         final answer =
//             (data["answer"] as List?)?.join("\n") ?? "No answer found.";
//         final evidence = data["evidence"] as List? ?? [];
//         final confidence = data["confidence"] as double? ?? 0.0;

//         // Format evidence with confidence scores
//         final formattedEvidence =
//             evidence.map((e) {
//               final snippet = e["snippet"] as String;
//               final type = e["type"] as String;
//               final itemConfidence = e["confidence"] as double? ?? 0.0;
//               final location = e["location"] as String?;

//               return {
//                 "text": "• $snippet",
//                 "meta":
//                     "${type.toUpperCase()}${location != null ? ' ($location)' : ''} · ${(itemConfidence * 100).toInt()}% confidence",
//                 "confidence": itemConfidence,
//               };
//             }).toList();

//         setState(() {
//           _messages.add({
//             "sender": "Lumora AI",
//             "message": answer,
//             "isUser": false,
//             "confidence": confidence,
//             "evidence": formattedEvidence,
//           });
//         });
//       } else {
//         setState(() {
//           _messages.add({
//             "sender": "Lumora AI",
//             "message":
//                 "I encountered an error while processing your request. Please try again.",
//             "isUser": false,
//             "isError": true,
//           });
//         });
//       }
//     } catch (e) {
//       setState(() {
//         _messages.add({
//           "sender": "Lumora AI",
//           "message": "Something went wrong. Please try again.",
//           "isUser": false,
//           "isError": true,
//         });
//       });
//     } finally {
//       setState(() => _isLoading = false);
//       _scrollToBottom();
//     }
//   }

//   void _scrollToBottom() {
//     Future.delayed(const Duration(milliseconds: 300), () {
//       if (_scrollController.hasClients) {
//         _scrollController.animateTo(
//           _scrollController.position.maxScrollExtent,
//           duration: const Duration(milliseconds: 300),
//           curve: Curves.easeOut,
//         );
//       }
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     const Color kAccent = Color.fromARGB(255, 218, 67, 3);

//     return Scaffold(
//       resizeToAvoidBottomInset: true,
//       backgroundColor: const Color(0xFFF7F8FA),
//       appBar: AppBar(
//         leading: BackButton(color: Colors.black),
//         backgroundColor: Colors.white,
//         elevation: 0,
//         title: ShaderMask(
//           shaderCallback:
//               (bounds) => const LinearGradient(
//                 colors: [kAccent, Color.fromARGB(255, 247, 83, 34)],
//               ).createShader(bounds),
//           child: Text(
//             'Lumora',
//             style: GoogleFonts.poppins(
//               textStyle: const TextStyle(
//                 fontSize: 40,
//                 fontWeight: FontWeight.w800,
//                 letterSpacing: -0.5,
//                 color: Colors.white,
//               ),
//             ),
//           ),
//         ),
//         centerTitle: true,
//       ),
//       body: SafeArea(
//         child: Padding(
//           padding: const EdgeInsets.all(12),
//           child: Card(
//             elevation: 6,
//             shadowColor: Colors.black26,
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(20),
//             ),
//             child: Container(
//               decoration: const BoxDecoration(
//                 gradient: LinearGradient(
//                   colors: [Color(0xFFFFFFFF), Color(0xFFFDF1EB)],
//                   begin: Alignment.topLeft,
//                   end: Alignment.bottomRight,
//                 ),
//                 borderRadius: BorderRadius.all(Radius.circular(20)),
//               ),
//               child: Column(
//                 children: [
//                   // ==== Chat List ====
//                   Expanded(
//                     child: ListView.builder(
//                       controller: _scrollController,
//                       padding: const EdgeInsets.symmetric(
//                         horizontal: 16,
//                         vertical: 12,
//                       ),
//                       itemCount: _messages.length,
//                       itemBuilder: (context, index) {
//                         final msg = _messages[index];
//                         return Align(
//                           alignment:
//                               msg["isUser"]
//                                   ? Alignment.centerRight
//                                   : Alignment.centerLeft,
//                           child: Padding(
//                             padding: const EdgeInsets.symmetric(vertical: 6),
//                             child: Row(
//                               mainAxisAlignment:
//                                   msg["isUser"]
//                                       ? MainAxisAlignment.end
//                                       : MainAxisAlignment.start,
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: [
//                                 if (!msg["isUser"]) ...[
//                                   const CircleAvatar(radius: 18),
//                                   const SizedBox(width: 8),
//                                 ],
//                                 Flexible(
//                                   child: Container(
//                                     padding: const EdgeInsets.symmetric(
//                                       horizontal: 14,
//                                       vertical: 12,
//                                     ),
//                                     decoration: BoxDecoration(
//                                       color:
//                                           msg["isUser"]
//                                               ? Colors.blue.shade50
//                                               : Colors.white,
//                                       borderRadius: BorderRadius.only(
//                                         topLeft: const Radius.circular(18),
//                                         topRight: const Radius.circular(18),
//                                         bottomLeft: Radius.circular(
//                                           msg["isUser"] ? 18 : 4,
//                                         ),
//                                         bottomRight: Radius.circular(
//                                           msg["isUser"] ? 4 : 18,
//                                         ),
//                                       ),
//                                       boxShadow: [
//                                         BoxShadow(
//                                           color: Colors.black12,
//                                           blurRadius: 4,
//                                           offset: const Offset(1, 2),
//                                         ),
//                                       ],
//                                     ),
//                                     child: Column(
//                                       crossAxisAlignment:
//                                           CrossAxisAlignment.start,
//                                       children: [
//                                         // Message text
//                                         Text(
//                                           msg["message"],
//                                           style: const TextStyle(
//                                             fontSize: 15,
//                                             height: 1.4,
//                                           ),
//                                         ),

//                                         // Confidence score
//                                         if (!msg["isUser"] &&
//                                             msg["confidence"] != null) ...[
//                                           const SizedBox(height: 8),
//                                           Row(
//                                             children: [
//                                               Icon(
//                                                 Icons.psychology,
//                                                 size: 16,
//                                                 color: Theme.of(
//                                                   context,
//                                                 ).primaryColor.withOpacity(0.7),
//                                               ),
//                                               const SizedBox(width: 4),
//                                               Text(
//                                                 "Confidence: ${(msg["confidence"] * 100).toInt()}%",
//                                                 style: TextStyle(
//                                                   fontSize: 13,
//                                                   color: Theme.of(context)
//                                                       .primaryColor
//                                                       .withOpacity(0.7),
//                                                 ),
//                                               ),
//                                             ],
//                                           ),
//                                         ],

//                                         // Evidence section
//                                         if (!msg["isUser"] &&
//                                             msg["evidence"] != null &&
//                                             (msg["evidence"] as List)
//                                                 .isNotEmpty) ...[
//                                           const SizedBox(height: 12),
//                                           Text(
//                                             "Sources:",
//                                             style: TextStyle(
//                                               fontSize: 13,
//                                               fontWeight: FontWeight.w600,
//                                               color: Colors.grey[700],
//                                             ),
//                                           ),
//                                           const SizedBox(height: 8),
//                                           ...((msg["evidence"] as List).map(
//                                             (e) => Column(
//                                               crossAxisAlignment:
//                                                   CrossAxisAlignment.start,
//                                               children: [
//                                                 Text(
//                                                   e["text"],
//                                                   style: const TextStyle(
//                                                     fontSize: 14,
//                                                     height: 1.4,
//                                                   ),
//                                                 ),
//                                                 Padding(
//                                                   padding:
//                                                       const EdgeInsets.only(
//                                                         left: 12,
//                                                         top: 4,
//                                                         bottom: 8,
//                                                       ),
//                                                   child: Text(
//                                                     e["meta"],
//                                                     style: TextStyle(
//                                                       fontSize: 12,
//                                                       color: Colors.grey[600],
//                                                     ),
//                                                   ),
//                                                 ),
//                                               ],
//                                             ),
//                                           )),
//                                         ],
//                                       ],
//                                     ),
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                         );
//                       },
//                     ),
//                   ),

//                   if (_isLoading)
//                     const Padding(
//                       padding: EdgeInsets.all(12),
//                       child: Align(
//                         alignment: Alignment.centerLeft,
//                         child: Text(
//                           "💭 Thinking...",
//                           style: TextStyle(color: Colors.grey, fontSize: 14),
//                         ),
//                       ),
//                     ),

//                   // ==== Input Area ====
//                   Container(
//                     padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
//                     decoration: BoxDecoration(
//                       color: Colors.white.withOpacity(0.9),
//                       borderRadius: const BorderRadius.vertical(
//                         bottom: Radius.circular(20),
//                       ),
//                       border: Border(
//                         top: BorderSide(color: Colors.grey.shade200),
//                       ),
//                     ),
//                     child: Column(
//                       children: [
//                         Row(
//                           children: [
//                             Expanded(
//                               child: TextField(
//                                 controller: _controller,
//                                 decoration: InputDecoration(
//                                   hintText: "Ask me about this startup...",
//                                   hintStyle: const TextStyle(
//                                     color: Colors.grey,
//                                   ),
//                                   filled: true,
//                                   fillColor: Colors.grey.shade100,
//                                   contentPadding: const EdgeInsets.symmetric(
//                                     horizontal: 16,
//                                     vertical: 14,
//                                   ),
//                                   border: OutlineInputBorder(
//                                     borderRadius: BorderRadius.circular(30),
//                                     borderSide: BorderSide.none,
//                                   ),
//                                 ),
//                                 onChanged: (_) => setState(() {}),
//                                 onSubmitted: (_) => _sendMessage(),
//                               ),
//                             ),
//                             const SizedBox(width: 10),
//                             IconButton(
//                               icon: Icon(
//                                 Icons.send,
//                                 size: 26,
//                                 color:
//                                     _controller.text.trim().isEmpty
//                                         ? Colors.grey.shade400
//                                         : const Color(0xFFF36B21),
//                               ),
//                               onPressed:
//                                   _controller.text.trim().isEmpty
//                                       ? null
//                                       : _sendMessage,
//                             ),
//                           ],
//                         ),
//                         const SizedBox(height: 4),
//                         const Text(
//                           "Powered by Flash2.5",
//                           style: TextStyle(fontSize: 12, color: Colors.grey),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
