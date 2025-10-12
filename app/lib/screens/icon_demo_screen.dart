import 'package:flutter/material.dart';
import '../widgets/app_icon.dart';

class IconDemoScreen extends StatelessWidget {
  const IconDemoScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Finally Done - Icon Options'),
        backgroundColor: Colors.blue,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            const Text(
              'App Icon Concepts',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            
            // Concept 1: Simple Microphone + Check
            _buildConceptSection(
              'Concept 1: Microphone + Check',
              'Clean and simple - microphone with checkmark overlay',
              [
                _buildIconRow('Blue', const Concept1Icon(backgroundColor: Color(0xFF007AFF))),
                _buildIconRow('Green', const Concept1Icon(backgroundColor: Color(0xFF34C759))),
                _buildIconRow('Purple', const Concept1Icon(backgroundColor: Color(0xFF5856D6))),
                _buildIconRow('Orange', const Concept1Icon(backgroundColor: Color(0xFFFF9500))),
              ],
            ),
            
            const SizedBox(height: 30),
            
            // Concept 2: Voice Wave + Task List
            _buildConceptSection(
              'Concept 2: Voice Wave + Task List',
              'Voice waves with task list and completion checkmark',
              [
                _buildIconRow('Green', const Concept2Icon(backgroundColor: Color(0xFF34C759))),
                _buildIconRow('Blue', const Concept2Icon(backgroundColor: Color(0xFF007AFF))),
                _buildIconRow('Purple', const Concept2Icon(backgroundColor: Color(0xFF5856D6))),
                _buildIconRow('Orange', const Concept2Icon(backgroundColor: Color(0xFFFF9500))),
              ],
            ),
            
            const SizedBox(height: 30),
            
            // Concept 3: AI Chat Bubble
            _buildConceptSection(
              'Concept 3: AI Chat Bubble',
              'Speech bubble with AI sparkle and task completion',
              [
                _buildIconRow('Purple', const Concept3Icon(backgroundColor: Color(0xFF5856D6))),
                _buildIconRow('Blue', const Concept3Icon(backgroundColor: Color(0xFF007AFF))),
                _buildIconRow('Green', const Concept3Icon(backgroundColor: Color(0xFF34C759))),
                _buildIconRow('Orange', const Concept3Icon(backgroundColor: Color(0xFFFF9500))),
              ],
            ),
            
            const SizedBox(height: 30),
            
            // Concept 4: Command Center
            _buildConceptSection(
              'Concept 4: Command Center',
              'Dashboard/control panel with voice and success indicators',
              [
                _buildIconRow('Orange', const Concept4Icon(backgroundColor: Color(0xFFFF9500))),
                _buildIconRow('Blue', const Concept4Icon(backgroundColor: Color(0xFF007AFF))),
                _buildIconRow('Green', const Concept4Icon(backgroundColor: Color(0xFF34C759))),
                _buildIconRow('Purple', const Concept4Icon(backgroundColor: Color(0xFF5856D6))),
              ],
            ),
            
            const SizedBox(height: 30),
            
            // Original Complex Design
            _buildConceptSection(
              'Original: Complex Voice Waves',
              'Detailed voice waves with task list and checkmark',
              [
                _buildIconRow('Green', const FinallyDoneIcon(backgroundColor: Color(0xFF00C851))),
                _buildIconRow('Blue', AppIconVariants.blue()),
                _buildIconRow('Purple', AppIconVariants.purple()),
                _buildIconRow('Orange', AppIconVariants.orange()),
              ],
            ),
            
            const SizedBox(height: 30),
            
            // Size variants
            const Text(
              'Size Variants',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 15),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Column(
                  children: [
                    AppIconVariants.small(),
                    const SizedBox(height: 8),
                    const Text('32px', style: TextStyle(fontSize: 12)),
                  ],
                ),
                Column(
                  children: [
                    AppIconVariants.medium(),
                    const SizedBox(height: 8),
                    const Text('64px', style: TextStyle(fontSize: 12)),
                  ],
                ),
                Column(
                  children: [
                    AppIconVariants.large(),
                    const SizedBox(height: 8),
                    const Text('128px', style: TextStyle(fontSize: 12)),
                  ],
                ),
                Column(
                  children: [
                    AppIconVariants.xlarge(),
                    const SizedBox(height: 8),
                    const Text('256px', style: TextStyle(fontSize: 12)),
                  ],
                ),
              ],
            ),
            
            const SizedBox(height: 30),
            
            // Color variants
            const Text(
              'Color Variants',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 15),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Column(
                  children: [
                    AppIconVariants.blue(),
                    const SizedBox(height: 8),
                    const Text('Blue', style: TextStyle(fontSize: 12)),
                  ],
                ),
                Column(
                  children: [
                    const FinallyDoneIcon(), // Green (default)
                    const SizedBox(height: 8),
                    const Text('Green', style: TextStyle(fontSize: 12)),
                  ],
                ),
                Column(
                  children: [
                    AppIconVariants.purple(),
                    const SizedBox(height: 8),
                    const Text('Purple', style: TextStyle(fontSize: 12)),
                  ],
                ),
                Column(
                  children: [
                    AppIconVariants.orange(),
                    const SizedBox(height: 8),
                    const Text('Orange', style: TextStyle(fontSize: 12)),
                  ],
                ),
              ],
            ),
            
            const SizedBox(height: 30),
            
            // Usage instructions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'How to Use This Icon:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text('1. Choose your preferred color variant'),
                  const Text('2. The icon automatically scales to any size'),
                  const Text('3. Works perfectly for iOS and Android'),
                  const Text('4. No external dependencies required'),
                  const Text('5. Can be customized further if needed'),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      // TODO: Set as app icon
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Icon will be set as app icon'),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                    child: const Text(
                      'Use This Icon',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      // TODO: Customize icon
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Customization options coming soon'),
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                    child: const Text('Customize'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConceptSection(String title, String description, List<Widget> icons) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 20,
            runSpacing: 20,
            children: icons,
          ),
        ],
      ),
    );
  }

  Widget _buildIconRow(String title, Widget iconWidget) {
    return Column(
      children: [
        iconWidget,
        const SizedBox(height: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildIconSection(String title, String description, Widget icon) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: [
          Row(
            children: [
              icon,
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
