import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import '../../models/recipe.dart';
import '../../models/instruction_model.dart';
import 'recipe_detail_page.dart';

class StepByStepCookingPage extends StatefulWidget {
  final Recipe recipe;

  const StepByStepCookingPage({Key? key, required this.recipe})
      : super(key: key);

  @override
  _StepByStepCookingPageState createState() => _StepByStepCookingPageState();
}

class _StepByStepCookingPageState extends State<StepByStepCookingPage> {
  int currentStep = 0;
  late stt.SpeechToText _speechToText;
  bool _speechEnabled = false;
  bool _isListening = false;
  String _lastWords = '';
  bool _isProcessingCommand = false;

  Map<int, VideoPlayerController?> videoControllers = {};
  Map<int, ChewieController?> chewieControllers = {};

  @override
  void initState() {
    super.initState();
    _speechToText = stt.SpeechToText();
    _initSpeech();
    _initializeVideoControllers();
  }

  void _initSpeech() async {
    _speechEnabled = await _speechToText.initialize(
      onStatus: (val) => setState(() {}),
      onError: (val) => setState(() {}),
    );
    setState(() {});
  }

  Future<void> _initializeVideoControllers() async {
    for (int i = 0; i < widget.recipe.instructions.length; i++) {
      final instruction = widget.recipe.instructions[i];
      VideoPlayerController? controller;

      if (instruction.videoUrl != null && instruction.videoUrl!.isNotEmpty) {
        controller =
            VideoPlayerController.networkUrl(Uri.parse(instruction.videoUrl!));
      }

      if (controller != null) {
        await controller.initialize();
        videoControllers[i] = controller;

        chewieControllers[i] = ChewieController(
          videoPlayerController: controller,
          aspectRatio: controller.value.aspectRatio,
          autoPlay: false,
          looping: true,
          showControls: true,
        );
      }
    }
    setState(() {});
  }

  void _startListening() async {
    await _speechToText.listen(onResult: _onSpeechResult);
    setState(() {
      _isListening = true;
    });
  }

  void _stopListening() async {
    await _speechToText.stop();
    setState(() {
      _isListening = false;
    });
  }

  void _onSpeechResult(dynamic result) {
    final words = result.recognizedWords?.toLowerCase() ?? '';
    setState(() {
      _lastWords = words;
    });

    // Prevent multiple triggers
    if (_isProcessingCommand) return;

    // Get last 1–2 words only for matching
    final lastWords =
        words.split(' ').reversed.take(2).toList().reversed.join(' ');
    print('Last spoken: $lastWords');

    if (lastWords.contains('back') || lastWords.contains('previous')) {
      _handleVoiceCommand(_previousStep);
    } else if (lastWords.contains('repeat') || lastWords.contains('again')) {
      _handleVoiceCommand(_repeatStep);
    } else if (lastWords.contains('next') ||
        lastWords.contains('ok') ||
        lastWords.contains('continue')) {
      _handleVoiceCommand(_nextStep);
    }
  }

  void _handleVoiceCommand(Function command) {
    _isProcessingCommand = true;
    command();

    // Allow another command after 1.5 seconds
    Future.delayed(Duration(seconds: 2), () {
      _isProcessingCommand = false;
    });
  }

  void _nextStep() {
    if (currentStep < widget.recipe.instructions.length - 1) {
      setState(() {
        currentStep++;
      });
      _playCurrentStepVideo();
    }
  }

  void _previousStep() {
    if (currentStep > 0) {
      setState(() {
        currentStep--;
      });
      _playCurrentStepVideo();
    }
  }

  void _repeatStep() {
    _playCurrentStepVideo();
  }

  void _playCurrentStepVideo() {
    final controller = chewieControllers[currentStep];
    if (controller != null) {
      controller.videoPlayerController.seekTo(Duration.zero);
      controller.play();
    }
  }

  void _Finish() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
          builder: (_) =>
              RecipeDetailPage(recipe: widget.recipe, fromFinishCooking: true)),
    );
  }

  @override
  void dispose() {
    for (final controller in videoControllers.values) {
      controller?.dispose();
    }
    for (final controller in chewieControllers.values) {
      controller?.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final instruction = widget.recipe.instructions[currentStep];
    final hasVideo = chewieControllers[currentStep] != null;
    bool showLoading = false;

    if (hasVideo == false) {
      showLoading = true;
      Future.delayed(Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            showLoading = false;
          });
        }
      });
    }
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text(
          'Step ${currentStep + 1} of ${widget.recipe.instructions.length}',
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back,
              color: Theme.of(context).colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isListening ? Icons.mic : Icons.mic_none,
              color: _isListening
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurface,
            ),
            onPressed: _speechEnabled
                ? (_isListening ? _stopListening : _startListening)
                : null,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Video Player Section
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                color: Colors.black,
                child: hasVideo == true
                    ? Chewie(controller: chewieControllers[currentStep]!)
                    : showLoading
                        ? Center(
                            child: CircularProgressIndicator(
                                color: Theme.of(context).colorScheme.onSurface))
                        : Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [Colors.grey[800]!, Colors.grey[900]!],
                              ),
                            ),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.video_library_outlined,
                                    size: 80,
                                    color: Colors.grey[400],
                                  ),
                                  SizedBox(height: 16),
                                  Text(
                                    'No video available for this step',
                                    style: TextStyle(
                                      color: Colors.grey[400],
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
              ),
            ),

            // Instruction Text Section
            Expanded(
              flex: 2,
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Step ${currentStep + 1}',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                    SizedBox(height: 12),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Text(
                          instruction.description,
                          style: TextStyle(
                            fontSize: 18,
                            height: 1.5,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ),

                    // Voice Command Instructions
                    if (_speechEnabled)
                      Container(
                        padding: EdgeInsets.all(12),
                        margin: EdgeInsets.only(top: 12),
                        decoration: BoxDecoration(
                          color:
                              Theme.of(context).colorScheme.secondaryContainer,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSecondaryContainer!),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.mic,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSecondaryContainer,
                                size: 20),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Say "OK", "Next", "Back", or "Repeat"',
                                style: TextStyle(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSecondaryContainer,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Control Buttons
            Container(
              padding: EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Previous Button
                  ElevatedButton.icon(
                    onPressed: currentStep > 0 ? _previousStep : null,
                    icon: Icon(Icons.skip_previous),
                    label: Text('Previous'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.error,
                      foregroundColor: Theme.of(context).colorScheme.onError,
                      padding:
                          EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                  ),

                  // Repeat Button
                  ElevatedButton.icon(
                    onPressed: _repeatStep,
                    icon: Icon(Icons.replay),
                    label: Text('Repeat'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.secondary,
                      foregroundColor:
                          Theme.of(context).colorScheme.onSecondary,
                      padding:
                          EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                  ),

                  // Next Button & Finish Button
                  ElevatedButton.icon(
                    onPressed:
                        currentStep < widget.recipe.instructions.length - 1
                            ? _nextStep
                            : _Finish,
                    icon: Icon(Icons.skip_next),
                    label: currentStep < widget.recipe.instructions.length - 1
                        ? Text('Next')
                        : Text('Finish'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      padding:
                          EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
