import 'package:flutter/material.dart';
import '../../models/exercise.dart';
import '../../services/exercise_service.dart';
import '../../services/calories_service.dart';
import '../trainer/trainer_landing_page.dart';
import '../user/user_landing_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'package:numberpicker/numberpicker.dart';

class ExerciseModulePage extends StatelessWidget {
  final ExerciseService _exerciseService = ExerciseService();
  final bool isTrainer;

  ExerciseModulePage({
    super.key,
    required this.isTrainer,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A2468),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'All Exercises',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF212E83),
              const Color(0xFF1A2468),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Exercise Directory',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Browse all exercises grouped by body part',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 32),
                Expanded(
                  child: FutureBuilder<Map<String, List<dynamic>>>(
                    future: _exerciseService.fetchExercisesForAllBodyParts(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: Colors.white,
                          ),
                        );
                      }
                      if (snapshot.hasError) {
                        return Center(
                          child: Text(
                            'Error loading exercises: ${snapshot.error}',
                            style: const TextStyle(color: Colors.white),
                          ),
                        );
                      }
                      final exercisesByBodyPart = snapshot.data ?? {};
                      if (exercisesByBodyPart.isEmpty) {
                        return const Center(
                          child: Text(
                            'No exercises found',
                            style: TextStyle(color: Colors.white),
                          ),
                        );
                      }
                      return ListView.builder(
                        itemCount: exercisesByBodyPart.length,
                        itemBuilder: (context, index) {
                          final bodyPart = exercisesByBodyPart.keys.elementAt(index);
                          final exercises = exercisesByBodyPart[bodyPart] ?? [];
                          if (exercises.isEmpty) return const SizedBox.shrink();
                          
                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Theme(
                              data: Theme.of(context).copyWith(
                                dividerColor: Colors.transparent,
                                unselectedWidgetColor: Colors.white70,
                                colorScheme: ColorScheme.dark(
                                  primary: Colors.blue.shade100,
                                ),
                              ),
                              child: ExpansionTile(
                                leading: Icon(
                                  _getBodyPartIcon(bodyPart),
                                  color: Colors.white,
                                  size: 24,
                                ),
                                title: Text(
                                  _formatBodyPartName(bodyPart),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Text(
                                  '${exercises.length} exercises',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.7),
                                    fontSize: 14,
                                  ),
                                ),
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      children: exercises.map((exercise) {
                                        return Container(
                                          margin: const EdgeInsets.only(bottom: 12),
                                          padding: const EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(0.05),
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(
                                              color: Colors.white.withOpacity(0.1),
                                            ),
                                          ),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: InkWell(
                                                      onTap: () {
                                                        Navigator.push(
                                                          context,
                                                          MaterialPageRoute(
                                                            builder: (context) => ExerciseDetailPage(
                                                              exercise: exercise,
                                                              bodyPart: bodyPart,
                                                            ),
                                                          ),
                                                        );
                                                      },
                                                      child: Row(
                                                        children: [
                                                          Expanded(
                                                            child: Text(
                                                              exercise['name'] ?? 'Unknown Exercise',
                                                              style: const TextStyle(
                                                                color: Colors.white,
                                                                fontSize: 16,
                                                                fontWeight: FontWeight.bold,
                                                              ),
                                                            ),
                                                          ),
                                                          Container(
                                                            padding: const EdgeInsets.all(4),
                                                            decoration: BoxDecoration(
                                                              color: Colors.blue.withOpacity(0.1),
                                                              borderRadius: BorderRadius.circular(8),
                                                            ),
                                                            child: Icon(
                                                              Icons.info_outline,
                                                              color: Colors.blue.withOpacity(0.8),
                                                              size: 16,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                  IconButton(
                                                    icon: const Icon(
                                                      Icons.add_circle_outline,
                                                      color: Colors.blue,
                                                    ),
                                                    onPressed: () {
                                                      Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                          builder: (context) => ExerciseCategoryPage(
                                                            bodyPart: bodyPart,
                                                            isTrainer: isTrainer,
                                                            selectedExercise: exercise['name'],
                                                          ),
                                                        ),
                                                      );
                                                    },
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 8),
                                              if (exercise['target'] != null) ...[
                                                Text(
                                                  'Target: ${exercise['target']}',
                                                  style: TextStyle(
                                                    color: Colors.white.withOpacity(0.8),
                                                    fontSize: 14,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                              ],
                                              if (exercise['equipment'] != null) ...[
                                                Text(
                                                  'Equipment: ${exercise['equipment']}',
                                                  style: TextStyle(
                                                    color: Colors.white.withOpacity(0.8),
                                                    fontSize: 14,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                              ],
                                              if (_getInstructions(exercise) != 'No instructions available for this exercise.') ...[
                                                InkWell(
                                                  onTap: () {
                                                    Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder: (context) => ExerciseDetailPage(
                                                          exercise: exercise,
                                                          bodyPart: bodyPart,
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                  child: Row(
                                                    children: [
                                                      Expanded(
                                                        child: Text(
                                                          'Instructions: ${_getInstructions(exercise)}',
                                                          style: TextStyle(
                                                            color: Colors.blue.withOpacity(0.8),
                                                            fontSize: 12,
                                                            decoration: TextDecoration.underline,
                                                          ),
                                                          maxLines: 2,
                                                          overflow: TextOverflow.ellipsis,
                                                        ),
                                                      ),
                                                      Icon(
                                                        Icons.arrow_forward_ios,
                                                        color: Colors.blue.withOpacity(0.8),
                                                        size: 12,
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getBodyPartIcon(String bodyPart) {
    switch (bodyPart.toLowerCase()) {
      case 'chest':
        return Icons.fitness_center;
      case 'back':
        return Icons.accessibility_new;
      case 'upper arms':
      case 'lower arms':
        return Icons.fitness_center;
      case 'upper legs':
      case 'lower legs':
        return Icons.directions_run;
      case 'shoulders':
        return Icons.fitness_center;
      case 'waist':
        return Icons.accessibility;
      case 'cardio':
        return Icons.favorite;
      case 'neck':
        return Icons.accessibility_new;
      default:
        return Icons.fitness_center;
    }
  }

  String _formatBodyPartName(String bodyPart) {
    switch (bodyPart.toLowerCase()) {
      case 'upper arms':
        return 'Upper Arms';
      case 'lower arms':
        return 'Lower Arms';
      case 'upper legs':
        return 'Upper Legs';
      case 'lower legs':
        return 'Lower Legs';
      case 'shoulders':
        return 'Shoulders';
      case 'waist':
        return 'Core/Waist';
      case 'cardio':
        return 'Cardio';
      case 'chest':
        return 'Chest';
      case 'back':
        return 'Back';
      case 'neck':
        return 'Neck';
      default:
        return bodyPart.split(' ').map((word) => 
          word[0].toUpperCase() + word.substring(1)
        ).join(' ');
    }
  }

  String _getInstructions(dynamic exercise) {
    // Check multiple possible field names for instructions
    final possibleFields = [
      'instructions',
      'instruction',
      'description',
      'desc',
      'steps',
      'how_to',
      'howTo',
      'method',
      'technique',
      'procedure'
    ];
    
    for (String field in possibleFields) {
      if (exercise[field] != null && exercise[field].toString().isNotEmpty) {
        print('✅ Found instructions in field: $field');
        String instructions = exercise[field].toString();
        return _cleanInstructions(instructions);
      }
    }
    
    print('❌ No instructions found in any field');
    return 'No instructions available for this exercise.';
  }

  String _cleanInstructions(String instructions) {
    // Remove leading and trailing brackets
    String cleaned = instructions.trim();
    
    // Remove opening bracket at the start
    if (cleaned.startsWith('[')) {
      cleaned = cleaned.substring(1);
    }
    
    // Remove closing bracket at the end
    if (cleaned.endsWith(']')) {
      cleaned = cleaned.substring(0, cleaned.length - 1);
    }
    
    // Remove leading commas and spaces
    cleaned = cleaned.replaceAll(RegExp(r'^[,\s]+'), '');
    
    // Remove trailing commas and spaces
    cleaned = cleaned.replaceAll(RegExp(r'[,\s]+$'), '');
    
    // Replace multiple commas with periods for better readability
    cleaned = cleaned.replaceAll(RegExp(r',\s*,'), '. ');
    cleaned = cleaned.replaceAll(RegExp(r',\s*$'), '.');
    
    // Add period at the end if it doesn't have one
    if (!cleaned.endsWith('.') && !cleaned.endsWith('!') && !cleaned.endsWith('?')) {
      cleaned += '.';
    }
    
    return cleaned.trim();
  }
}

class ExerciseCategoryPage extends StatefulWidget {
  final String bodyPart;
  final ExerciseService _exerciseService = ExerciseService();
  final CaloriesService _caloriesService = CaloriesService();
  final bool isTrainer;
  final String? selectedExercise;

  ExerciseCategoryPage({
    super.key, 
    required this.bodyPart,
    required this.isTrainer,
    this.selectedExercise,
  });

  @override
  State<ExerciseCategoryPage> createState() => _ExerciseCategoryPageState();
}

class _ExerciseCategoryPageState extends State<ExerciseCategoryPage> {
  final ExerciseService _exerciseService = ExerciseService();
  final CaloriesService _caloriesService = CaloriesService();
  String _selectedIntensity = 'Low';
  double _duration = 30;
  final bool _showExercises = false;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isTimerRunning = false;
  int _remainingSeconds = 0;
  Timer? _timer;
  int _selectedMinutes = 30;
  final List<int> _presetDurations = [5, 10, 15, 20, 30, 45, 60];
  String? _selectedExercise;
  
  // New variables for sets and reps
  int _numberOfSets = 3;
  int _repsPerSet = 5; // Initialize to match Low intensity (5 reps)
  int _totalReps = 15; // Calculated: 3 sets × 5 reps = 15 total reps
  int _currentEstimatedCalories = 0; // Real-time calorie estimate

  @override
  void initState() {
    super.initState();
    _remainingSeconds = _selectedMinutes * 60;
    _selectedExercise = widget.selectedExercise;
    _calculateTotalReps();
    // Initialize calories after a short delay to ensure all variables are set
    Future.delayed(const Duration(milliseconds: 100), () {
      _updateCurrentCalories();
    });
  }

  void _calculateTotalReps() {
    setState(() {
      _totalReps = _numberOfSets * _repsPerSet;
      // Debug: Print the calculation
      print('🧮 Total reps calculation: $_numberOfSets × $_repsPerSet = $_totalReps');
      // Update current calories
      _updateCurrentCalories();
    });
  }

  void _updateCurrentCalories() async {
    try {
      int baseCalories = 0;
      if (_selectedExercise != null) {
        try {
          baseCalories = await _caloriesService.calculateCaloriesBurned(
            _selectedExercise!,
            widget.bodyPart,
            _duration.round(),
            _selectedIntensity,
          );
        } catch (e) {
          baseCalories = _calculateCaloriesBurned(_duration.round(), _selectedIntensity);
        }
      } else {
        baseCalories = _calculateCaloriesBurned(_duration.round(), _selectedIntensity);
      }
      
      setState(() {
        _currentEstimatedCalories = _calculateCaloriesWithVolume(baseCalories, _numberOfSets, _repsPerSet);
      });
    } catch (e) {
      print('Error updating current calories: $e');
    }
  }

  String _getRepRangeForDisplay(String intensity) {
    switch (intensity.toLowerCase()) {
      case 'low':
        return '3-6';
      case 'medium':
        return '6-10';
      case 'high':
        return '10-15';
      default:
        return '6-10';
    }
  }

  void _updateRepsBasedOnIntensity(String intensity) {
    setState(() {
      _selectedIntensity = intensity;
      // Set recommended reps per set based on intensity (using middle of range)
      switch (intensity.toLowerCase()) {
        case 'low':
          _repsPerSet = 5; // Middle of 3-6 range
          break;
        case 'medium':
          _repsPerSet = 8; // Middle of 6-10 range
          break;
        case 'high':
          _repsPerSet = 13; // Middle of 10-15 range
          break;
        default:
          _repsPerSet = 8;
      }
      _calculateTotalReps();
      
      // Debug: Print the calculation
      print('🔄 Intensity changed to: $intensity');
      print('   Reps per set: $_repsPerSet');
      print('   Number of sets: $_numberOfSets');
      print('   Total reps: $_totalReps');
      print('   Calculation: $_numberOfSets × $_repsPerSet = $_totalReps');
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _showMinutesInputDialog() async {
    if (_isTimerRunning) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please stop the timer before changing the duration'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final TextEditingController controller = TextEditingController(
      text: _selectedMinutes.toString(),
    );

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A2468),
        title: const Text(
          'Set Exercise Duration',
          style: TextStyle(color: Colors.white),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Quick Select',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _presetDurations.map((minutes) {
                  final isSelected = minutes == _selectedMinutes;
                  return InkWell(
                    onTap: () {
                      setState(() {
                        _selectedMinutes = minutes;
                        _remainingSeconds = minutes * 60;
                      });
                      Navigator.pop(context);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.blue : Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? Colors.blue : Colors.white24,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        '$minutes min',
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.white70,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              const Text(
                'Custom Duration',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              NumberPicker(
                value: _selectedMinutes,
                minValue: 1,
                maxValue: 120,
                itemHeight: 40,
                itemWidth: 60,
                axis: Axis.horizontal,
                textStyle: const TextStyle(color: Colors.white54, fontSize: 20),
                selectedTextStyle: const TextStyle(color: Colors.blue, fontSize: 28, fontWeight: FontWeight.bold),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: Colors.blue.withOpacity(0.4)),
                    bottom: BorderSide(color: Colors.blue.withOpacity(0.4)),
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    _selectedMinutes = value;
                    _remainingSeconds = value * 60;
                  });
                },
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        labelText: 'Minutes',
                        labelStyle: const TextStyle(color: Colors.white70),
                        enabledBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: Colors.white24),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: Colors.blue),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        suffixText: 'min',
                        suffixStyle: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 18),
                        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                      ),
                      autofocus: true,
                      onSubmitted: (value) {
                        final minutes = int.tryParse(value);
                        if (minutes != null && minutes > 0) {
                          setState(() {
                            _selectedMinutes = minutes;
                            _remainingSeconds = minutes * 60;
                          });
                          Navigator.pop(context);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please enter a valid number of minutes'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    onPressed: () {
                      final minutes = int.tryParse(controller.text);
                      if (minutes != null && minutes > 0) {
                        setState(() {
                          _selectedMinutes = minutes;
                          _remainingSeconds = minutes * 60;
                        });
                        Navigator.pop(context);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please enter a valid number of minutes'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.check_circle, color: Colors.blue, size: 32),
                    tooltip: 'Set Duration',
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white24),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.blue, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'You can scroll, type, or tap a preset to set your workout duration (e.g. 12 for 12 minutes).',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
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
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white70),
            ),
          ),
        ],
      ),
    );
  }

  void _startTimer() {
    if (_remainingSeconds <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please set a valid duration first'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isTimerRunning = true;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
        } else {
          _timer?.cancel();
          _isTimerRunning = false;
          _showTimerCompleteDialog();
        }
      });
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    setState(() {
      _isTimerRunning = false;
    });
  }

  void _resetTimer() {
    _timer?.cancel();
    setState(() {
      _isTimerRunning = false;
      _remainingSeconds = _selectedMinutes * 60;
    });
  }

  void _showTimerCompleteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A2468),
        title: const Text(
          'Exercise Complete!',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Great job! You\'ve completed your exercise session.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _handleContinue();
            },
            child: const Text(
              'Continue',
              style: TextStyle(color: Colors.blue),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(int seconds) {
    final minutes = (seconds / 60).floor();
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  Widget _buildTimer() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Exercise Timer',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                onPressed: _showMinutesInputDialog,
                icon: const Icon(Icons.timer, color: Colors.white),
                tooltip: 'Set Duration',
              ),
            ],
          ),
          const SizedBox(height: 16),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                height: 120,
                width: 120,
                child: CircularProgressIndicator(
                  value: _isTimerRunning ? _remainingSeconds / (_selectedMinutes * 60) : 1.0,
                  backgroundColor: Colors.white.withOpacity(0.1),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _isTimerRunning ? Colors.blue : Colors.white.withOpacity(0.3),
                  ),
                  strokeWidth: 8,
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _formatTime(_remainingSeconds),
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    '${_selectedMinutes} min',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: _isTimerRunning ? _stopTimer : _startTimer,
                icon: Icon(_isTimerRunning ? Icons.stop : Icons.play_arrow),
                label: Text(_isTimerRunning ? 'Stop' : 'Start'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isTimerRunning ? Colors.red : Colors.green,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: _resetTimer,
                icon: const Icon(Icons.refresh),
                label: const Text('Reset'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _saveExerciseData() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No user logged in'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Get user data to check user type
      final userRef = widget.isTrainer 
          ? _firestore.collection('trainer').doc(user.uid)
          : _firestore.collection('users').doc(user.uid);
      
      final userData = await userRef.get();

      if (!userData.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User profile not found'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final lastWorkout = userData.data()?['lastWorkout'] as Timestamp?;
      int currentStreak = userData.data()?['workoutStreak'] ?? 0;

      // Calculate calories burned using the enhanced Calories Service
      int estimatedCalories = 0;
      if (_selectedExercise != null) {
        try {
          // Use the enhanced calorie calculation method
          int baseCalories = await _caloriesService.calculateCaloriesBurned(
            _selectedExercise!,
            widget.bodyPart,
            _duration.round(),
            _selectedIntensity,
          );
          // Apply volume-based adjustment
          estimatedCalories = _calculateCaloriesWithVolume(baseCalories, _numberOfSets, _repsPerSet);
        } catch (e) {
          print('Error calculating calories: $e');
          // Fallback to basic calculation if API fails
          int baseCalories = _calculateCaloriesBurned(_duration.round(), _selectedIntensity);
          estimatedCalories = _calculateCaloriesWithVolume(baseCalories, _numberOfSets, _repsPerSet);
        }
      } else {
        // Fallback to basic calculation if no exercise selected
        int baseCalories = _calculateCaloriesBurned(_duration.round(), _selectedIntensity);
        estimatedCalories = _calculateCaloriesWithVolume(baseCalories, _numberOfSets, _repsPerSet);
      }

      // Update streak based on last workout
      if (lastWorkout != null) {
        final lastWorkoutDate = lastWorkout.toDate();
        final difference = now.difference(lastWorkoutDate);

        if (difference.inDays == 0) {
          // Already worked out today, keep streak
        } else if (difference.inDays == 1) {
          // Consecutive day, increase streak
          currentStreak++;
        } else {
          // Streak broken, reset to 1
          currentStreak = 1;
        }
      } else {
        // First workout ever
        currentStreak = 1;
      }

      // Get today's calories
      final dailyCaloriesRef = userRef.collection('daily_calories').doc(today.toIso8601String());
      final dailyCaloriesDoc = await dailyCaloriesRef.get();
      int todayCalories = 0;
      
      if (dailyCaloriesDoc.exists) {
        final data = dailyCaloriesDoc.data();
        if (data != null && data.containsKey('calories')) {
          todayCalories = (data['calories'] as num).toInt();
        }
      }

      // Update today's calories
      await dailyCaloriesRef.set({
        'date': today,
        'calories': todayCalories + estimatedCalories,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Add to calories history
      await userRef.collection('calories_history').add({
        'date': today,
        'calories': estimatedCalories,
        'exercise': _selectedExercise ?? 'General Exercise',
        'category': widget.bodyPart,
        'intensity': _selectedIntensity,
        'duration': _duration.round(),
        'timestamp': FieldValue.serverTimestamp(),
      });

      final exerciseData = {
        'userId': user.uid,
        'userName': userData.data()?['name'] ?? 'Unknown',
        'category': widget.bodyPart,
        'exercise': _selectedExercise ?? 'General Exercise',
        'intensity': _selectedIntensity,
        'duration': _duration.round(),
        'sets': _numberOfSets,
        'repsPerSet': _repsPerSet,
        'totalReps': _totalReps,
        'timestamp': FieldValue.serverTimestamp(),
        'caloriesBurned': estimatedCalories,
      };

      // Update user document with new workout data
      await userRef.update({
        'lastWorkout': FieldValue.serverTimestamp(),
        'workoutStreak': currentStreak,
        'totalCaloriesBurned': FieldValue.increment(estimatedCalories),
      });

      // Store workout in user's workouts collection
      await userRef.collection('workouts').add(exerciseData);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Exercise completed! $_numberOfSets sets × $_repsPerSet reps = $_totalReps total reps. Calories burned: $estimatedCalories'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('Error saving exercise data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving exercise data: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  int _calculateCaloriesBurned(int duration, String intensity) {
    // Use body part-specific calculation for better accuracy
    return _caloriesService.calculateCaloriesWithBodyPartAdjustment(
      'General Exercise',
      widget.bodyPart,
      duration,
      intensity,
    );
  }

  int _calculateCaloriesWithVolume(int baseCalories, int sets, int repsPerSet) {
    // Calculate workout volume factor
    int totalReps = sets * repsPerSet;
    
    // Base volume multiplier (more reps = more calories)
    double volumeMultiplier = 1.0;
    
    // Adjust multiplier based on total reps
    if (totalReps <= 15) {
      volumeMultiplier = 1.0; // Light volume
    } else if (totalReps <= 30) {
      volumeMultiplier = 1.2; // Moderate volume
    } else if (totalReps <= 50) {
      volumeMultiplier = 1.4; // High volume
    } else if (totalReps <= 80) {
      volumeMultiplier = 1.6; // Very high volume
    } else {
      volumeMultiplier = 1.8; // Extreme volume
    }
    
    // Additional sets multiplier (more sets = more rest periods, but more work)
    double setsMultiplier = 1.0 + (sets - 1) * 0.1; // Each additional set adds 10%
    
    // Calculate final calories
    int finalCalories = (baseCalories * volumeMultiplier * setsMultiplier).round();
    
    // Debug: Print the calculation
    print('🔥 Calorie calculation with volume:');
    print('   Base calories: $baseCalories');
    print('   Sets: $sets, Reps per set: $repsPerSet');
    print('   Total reps: $totalReps');
    print('   Volume multiplier: $volumeMultiplier');
    print('   Sets multiplier: $setsMultiplier');
    print('   Final calories: $finalCalories');
    
    return finalCalories;
  }

  void _handleContinue() async {
    // First save the exercise data
    await _saveExerciseData();

    // Then navigate to the appropriate landing page
    if (widget.isTrainer) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => TrainerLandingPage(),
        ),
        (route) => false,
      );
    } else {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => UserLandingPage(),
        ),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A2468),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          widget.bodyPart,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          // Cache management button
          IconButton(
            icon: const Icon(Icons.cached, color: Colors.white),
            onPressed: () => _showCacheOptions(),
            tooltip: 'Cache Options',
          ),
          // Test button to verify API usage
          IconButton(
            icon: const Icon(Icons.bug_report, color: Colors.white),
            onPressed: () => _testAPIUsage(),
            tooltip: 'Test API Usage',
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF212E83),
              const Color(0xFF1A2468),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!_showExercises) ...[
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Select Intensity',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(child: _buildIntensityButton('Low', _selectedIntensity == 'Low')),
                            const SizedBox(width: 8),
                            Expanded(child: _buildIntensityButton('Medium', _selectedIntensity == 'Medium')),
                            const SizedBox(width: 8),
                            Expanded(child: _buildIntensityButton('High', _selectedIntensity == 'High')),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 15,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Select Duration',
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Text(
                                    '${_duration.round()} min',
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),
                              Slider(
                                value: _duration,
                                min: 1,
                                max: 120,
                                divisions: 119,
                                activeColor: Colors.blue,
                                inactiveColor: Colors.white.withOpacity(0.3),
                                onChanged: (value) {
                                  setState(() {
                                    _duration = value;
                                  });
                                  // Update calories when duration changes
                                  _updateCurrentCalories();
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        // Sets and Reps Section
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 15,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.purple.withOpacity(0.3),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.fitness_center,
                                      color: Colors.purple,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  const Text(
                                    'Sets & Reps',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              
                              // Number of Sets
                              Row(
                                children: [
                                  Expanded(
                                    flex: 1,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          'Number of Sets',
                                          style: TextStyle(
                                            color: Colors.white.withOpacity(0.8),
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 8),
                                        Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(color: Colors.white.withOpacity(0.2)),
                                          ),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              IconButton(
                                                onPressed: () {
                                                  if (_numberOfSets > 1) {
                                                    setState(() {
                                                      _numberOfSets--;
                                                      _calculateTotalReps();
                                                    });
                                                  }
                                                },
                                                icon: const Icon(Icons.remove, color: Colors.white, size: 18),
                                                padding: const EdgeInsets.all(2),
                                                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                                              ),
                                              Text(
                                                '$_numberOfSets',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 22,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              IconButton(
                                                onPressed: () {
                                                  setState(() {
                                                    _numberOfSets++;
                                                    _calculateTotalReps();
                                                  });
                                                },
                                                icon: const Icon(Icons.add, color: Colors.white, size: 18),
                                                padding: const EdgeInsets.all(2),
                                                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  
                                  // Reps per Set
                                  Expanded(
                                    flex: 1,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                'Reps per Set',
                                                style: TextStyle(
                                                  color: Colors.white.withOpacity(0.8),
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            const SizedBox(width: 2),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
                                              decoration: BoxDecoration(
                                                color: Colors.blue.withOpacity(0.3),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                'Auto',
                                                style: TextStyle(
                                                  color: Colors.blue,
                                                  fontSize: 8,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Based on intensity level',
                                          style: TextStyle(
                                            color: Colors.white.withOpacity(0.6),
                                            fontSize: 12,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 8),
                                        Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: Colors.blue.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(color: Colors.blue.withOpacity(0.3)),
                                          ),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.auto_awesome,
                                                color: Colors.blue,
                                                size: 14,
                                              ),
                                              const SizedBox(width: 4),
                                              Flexible(
                                                child: Text(
                                                  '${_getRepRangeForDisplay(_selectedIntensity)}',
                                                  style: const TextStyle(
                                                    color: Colors.blue,
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              
                              const SizedBox(height: 20),
                              
                              // Total Reps Display
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.green.withOpacity(0.4)),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.calculate,
                                      color: Colors.green,
                                      size: 24,
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Total Reps',
                                            style: TextStyle(
                                              color: Colors.green.withOpacity(0.8),
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          Text(
                                            '$_totalReps',
                                            style: const TextStyle(
                                              color: Colors.green,
                                              fontSize: 28,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Flexible(
                                      child: Text(
                                        '$_numberOfSets × $_repsPerSet',
                                        style: TextStyle(
                                          color: Colors.green.withOpacity(0.8),
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              
                              const SizedBox(height: 20),
                              
                              // Calories Display
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.orange.withOpacity(0.4)),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.local_fire_department,
                                      color: Colors.orange,
                                      size: 24,
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Estimated Calories',
                                            style: TextStyle(
                                              color: Colors.orange.withOpacity(0.8),
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          Text(
                                            '$_currentEstimatedCalories',
                                            style: const TextStyle(
                                              color: Colors.orange,
                                              fontSize: 28,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Flexible(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            'Volume: $_totalReps reps',
                                            style: TextStyle(
                                              color: Colors.orange.withOpacity(0.8),
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          Text(
                                            'Duration: ${_duration.round()} min',
                                            style: TextStyle(
                                              color: Colors.orange.withOpacity(0.8),
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        _buildTimer(),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _handleContinue,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Continue',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else
                  _buildExerciseList(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIntensityButton(String title, bool isSelected) {
    IconData getIntensityIcon(String intensity) {
      switch (intensity.toLowerCase()) {
        case 'low':
          return Icons.trending_down;
        case 'medium':
          return Icons.trending_flat;
        case 'high':
          return Icons.trending_up;
        default:
          return Icons.trending_flat;
      }
    }

    String getRepRange(String intensity) {
      switch (intensity.toLowerCase()) {
        case 'low':
          return '3-6 reps';
        case 'medium':
          return '6-10 reps';
        case 'high':
          return '10-15 reps';
        default:
          return '6-10 reps';
      }
    }

    return InkWell(
      onTap: () {
        _updateRepsBasedOnIntensity(title);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.withOpacity(0.3) : Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.white.withOpacity(0.2),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected ? Colors.blue.withOpacity(0.2) : Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                getIntensityIcon(title),
                color: isSelected ? Colors.blue : Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.blue : Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              getRepRange(title),
              style: TextStyle(
                color: isSelected ? Colors.blue.withOpacity(0.8) : Colors.white.withOpacity(0.7),
                fontSize: 12,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExerciseList() {
    return FutureBuilder<List<dynamic>>(
      future: _exerciseService.fetchExercisesByBodyPart(widget.bodyPart),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error: ${snapshot.error}',
              style: const TextStyle(color: Colors.white),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.white),
          );
        }

        final exercises = snapshot.data ?? [];

        if (exercises.isEmpty) {
          return const Center(
            child: Text(
              'No exercises found for this body part',
              style: TextStyle(color: Colors.white),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(24),
          itemCount: exercises.length,
          itemBuilder: (context, index) {
            final exercise = exercises[index];
            final isSelected = _selectedExercise == exercise['name'];
            
            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: isSelected ? Colors.blue.withOpacity(0.2) : Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
                border: isSelected ? Border.all(color: Colors.blue, width: 2) : null,
              ),
              child: Theme(
                data: Theme.of(context).copyWith(
                  dividerColor: Colors.transparent,
                  unselectedWidgetColor: Colors.white70,
                  colorScheme: ColorScheme.dark(
                    primary: Colors.blue.shade100,
                  ),
                ),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _selectedExercise = exercise['name'];
                    });
                  },
                  child: ExpansionTile(
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            exercise['name'] ?? 'Unknown Exercise',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        if (isSelected)
                          const Icon(
                            Icons.check_circle,
                            color: Colors.blue,
                          ),
                      ],
                    ),
                    subtitle: Text(
                      _getInstructions(exercise),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 14,
                      ),
                    ),
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildInfoRow('Equipment', exercise['equipment'] ?? 'Unknown'),
                            const SizedBox(height: 12),
                            _buildInfoRow('Target Muscle', exercise['target'] ?? 'Unknown'),
                            const SizedBox(height: 12),
                            _buildInfoRow('Intensity', _selectedIntensity),
                            const SizedBox(height: 12),
                            _buildInfoRow('Duration', '${_duration.round()} minutes'),
                            const SizedBox(height: 12),
                            _buildInfoRow('Sets', '$_numberOfSets'),
                            const SizedBox(height: 12),
                            _buildInfoRow('Reps per Set', '$_repsPerSet'),
                            const SizedBox(height: 12),
                            _buildInfoRow('Total Reps', '$_totalReps'),
                            const SizedBox(height: 16),
                            const Text(
                              'Instructions:',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _getInstructions(exercise),
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 16,
                                height: 1.6,
                              ),
                            ),
                            if (exercise['gifUrl'] != null) ...[
                              const SizedBox(height: 16),
                              const Text(
                                'Exercise Demo:',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Image.network(
                                exercise['gifUrl'],
                                height: 200,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            ],
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => ExerciseDetailPage(
                                            exercise: exercise,
                                            bodyPart: widget.bodyPart,
                                          ),
                                        ),
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: const Text(
                                      'View Full Details',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () {
                                      setState(() {
                                        _selectedExercise = exercise['name'];
                                      });
                                      Navigator.pop(context);
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue,
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: const Text(
                                      'Select Exercise',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
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
            );
          },
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      children: [
        Text(
          '$label: ',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  String _getInstructions(dynamic exercise) {
    // Check multiple possible field names for instructions
    final possibleFields = [
      'instructions',
      'instruction',
      'description',
      'desc',
      'steps',
      'how_to',
      'howTo',
      'method',
      'technique',
      'procedure'
    ];
    
    for (String field in possibleFields) {
      if (exercise[field] != null && exercise[field].toString().isNotEmpty) {
        print('✅ Found instructions in field: $field');
        String instructions = exercise[field].toString();
        return _cleanInstructions(instructions);
      }
    }
    
    print('❌ No instructions found in any field');
    return 'No instructions available for this exercise.';
  }

  String _cleanInstructions(String instructions) {
    // Remove leading and trailing brackets
    String cleaned = instructions.trim();
    
    // Remove opening bracket at the start
    if (cleaned.startsWith('[')) {
      cleaned = cleaned.substring(1);
    }
    
    // Remove closing bracket at the end
    if (cleaned.endsWith(']')) {
      cleaned = cleaned.substring(0, cleaned.length - 1);
    }
    
    // Remove leading commas and spaces
    cleaned = cleaned.replaceAll(RegExp(r'^[,\s]+'), '');
    
    // Remove trailing commas and spaces
    cleaned = cleaned.replaceAll(RegExp(r'[,\s]+$'), '');
    
    // Replace multiple commas with periods for better readability
    cleaned = cleaned.replaceAll(RegExp(r',\s*,'), '. ');
    cleaned = cleaned.replaceAll(RegExp(r',\s*$'), '.');
    
    // Add period at the end if it doesn't have one
    if (!cleaned.endsWith('.') && !cleaned.endsWith('!') && !cleaned.endsWith('?')) {
      cleaned += '.';
    }
    
    return cleaned.trim();
  }

  Future<void> _showCacheOptions() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A2468),
          title: const Text(
            'Cache Management',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: const Text(
            'Manage cached exercise data for faster loading.',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _clearCache();
              },
              child: const Text(
                'Clear Cache',
                style: TextStyle(color: Colors.red),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _preloadData();
              },
              child: const Text(
                'Preload Data',
                style: TextStyle(color: Colors.blue),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.white70),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _clearCache() async {
    try {
      await _exerciseService.clearCache();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cache cleared successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error clearing cache: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _preloadData() async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Preloading exercise data...'),
          backgroundColor: Colors.blue,
        ),
      );
      
      await _exerciseService.preloadAllExercises();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Exercise data preloaded successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error preloading data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _testAPIUsage() async {
    try {
      // First, run API diagnosis
      print('\n🔍 Running API Diagnosis...');
      final diagnosis = await _caloriesService.diagnoseAPI();
      
      // Show diagnosis results
      String message = '';
      Color backgroundColor = Colors.green;
      
      if (diagnosis['api_key_valid'] && diagnosis['endpoint_accessible']) {
        message = '✅ API is working perfectly! All calculations will use the API.';
        backgroundColor = Colors.green;
      } else if (diagnosis['error_details'].contains('not subscribed')) {
        message = '⚠️ API key valid but no subscription. Using enhanced fallback calculations.';
        backgroundColor = Colors.orange;
      } else if (!diagnosis['api_key_valid']) {
        message = '❌ API key issue: ${diagnosis['error_details']}';
        backgroundColor = Colors.red;
      } else {
        message = '⚠️ API not accessible. Using enhanced fallback calculations.';
        backgroundColor = Colors.orange;
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: backgroundColor,
          duration: const Duration(seconds: 5),
        ),
      );
      
      if (!diagnosis['api_key_valid']) {
        return;
      }

      // If API is working, test all body parts
      final user = _auth.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No user logged in'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final userRef = widget.isTrainer 
          ? _firestore.collection('trainer').doc(user.uid)
          : _firestore.collection('users').doc(user.uid);
      
      final userData = await userRef.get();

      if (!userData.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User profile not found'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Test API usage for all body parts
      final allBodyParts = [
        'Chest', 'Back', 'Shoulders', 'Upper Arms', 'Lower Arms', 'Upper Legs', 'Lower Legs', 'Waist', 'Cardio', 'Neck'
      ];

      int apiSuccessCount = 0;
      int fallbackCount = 0;

      for (final bodyPart in allBodyParts) {
        print('\n🧪 Testing API for $bodyPart...');
        try {
          final estimatedCalories = await _caloriesService.calculateCaloriesBurned(
            'General Exercise', // Use a generic exercise name for testing
            bodyPart,
            _duration.round(),
            _selectedIntensity,
          );
          print('✅ API Result for $bodyPart: $estimatedCalories calories burned');
          apiSuccessCount++;
        } catch (e) {
          print('❌ API failed for $bodyPart: $e');
          fallbackCount++;
        }
      }

      final successRate = (apiSuccessCount / allBodyParts.length) * 100;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('API Test Complete: $apiSuccessCount/${allBodyParts.length} successful (${successRate.toStringAsFixed(1)}%)'),
          backgroundColor: successRate > 80 ? Colors.green : Colors.orange,
          duration: const Duration(seconds: 3),
        ),
      );

    } catch (e) {
      print('Error during API testing: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error during API testing: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
} 

class ExerciseDetailPage extends StatelessWidget {
  final Map<String, dynamic> exercise;
  final String bodyPart;

  const ExerciseDetailPage({
    super.key,
    required this.exercise,
    required this.bodyPart,
  });

  @override
  Widget build(BuildContext context) {
    // Debug: Print the exercise data to see what we're working with
    print('🔍 ExerciseDetailPage - Exercise data:');
    exercise.forEach((key, value) {
      print('   $key: $value');
    });
    
    // Check specifically for instructions
    print('🔍 Instructions check:');
    print('   instructions field: ${exercise['instructions']}');
    print('   instructions type: ${exercise['instructions'].runtimeType}');
    print('   instructions is null: ${exercise['instructions'] == null}');
    print('   instructions is empty: ${exercise['instructions']?.toString().isEmpty}');
    
    return Scaffold(
      backgroundColor: const Color(0xFF1A2468),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          exercise['name'] ?? 'Exercise Details',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF212E83),
              const Color(0xFF1A2468),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Exercise Image/GIF
                if (exercise['gifUrl'] != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.3)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.play_circle_outline,
                                color: Colors.red,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            const Text(
                              'Exercise Demo',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Container(
                          width: double.infinity,
                          height: 400,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 15,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.network(
                              exercise['gifUrl'],
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.white.withOpacity(0.1),
                                  child: const Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.fitness_center,
                                          size: 80,
                                          color: Colors.white54,
                                        ),
                                        SizedBox(height: 16),
                                        Text(
                                          'Demo not available',
                                          style: TextStyle(
                                            color: Colors.white54,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
                
                // Exercise Name
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.3)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _formatExerciseName(exercise['name']),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          height: 1.2,
                        ),
                        overflow: TextOverflow.visible,
                        softWrap: true,
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(color: Colors.blue.withOpacity(0.6)),
                        ),
                        child: Text(
                          _formatBodyPartName(bodyPart),
                          style: const TextStyle(
                            color: Colors.blue,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                
                // Exercise Details
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.3)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.info_outline,
                              color: Colors.blue,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Text(
                            'Exercise Details',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _buildDetailSection(
                        'Target Muscle',
                        _formatField(exercise['target'], 'Not specified'),
                        Icons.fitness_center,
                      ),
                      const SizedBox(height: 16),
                      _buildDetailSection(
                        'Equipment',
                        _formatField(exercise['equipment'], 'No equipment needed'),
                        Icons.sports_gymnastics,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                
                // Instructions Section
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.3)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(12),
                              ),
                            child: const Icon(
                              Icons.article,
                              color: Colors.green,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Text(
                            'Exercise Instructions',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white.withOpacity(0.2)),
                        ),
                        child: Text(
                          _getInstructions(exercise),
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.95),
                            fontSize: 16,
                            height: 1.6,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.visible,
                          softWrap: true,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                
                // Secondary Muscles (if available)
                if (exercise['secondaryMuscles'] != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.3)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.purple.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.fitness_center,
                                color: Colors.purple,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            const Text(
                              'Secondary Muscles',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white.withOpacity(0.2)),
                          ),
                          child: Text(
                            _formatSecondaryMuscles(exercise['secondaryMuscles']),
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.95),
                              fontSize: 16,
                              height: 1.6,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.visible,
                            softWrap: true,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
                
                // Instructions Steps (if available)
                if (_getInstructions(exercise) != 'No instructions available for this exercise.') ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.3)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.format_list_numbered,
                                color: Colors.orange,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            const Text(
                              'Step-by-Step Instructions',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        _buildInstructionsSteps(_getInstructions(exercise)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailSection(String title, String content, IconData icon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: Colors.blue,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  content,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionsSteps(String instructions) {
    // Ensure instructions is a string
    if (instructions is! String) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: Text(
          'Instructions format not supported.',
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 16,
            height: 1.6,
          ),
        ),
      );
    }

    // Split instructions into steps if they contain numbered steps
    List<String> steps = [];
    
    if (instructions.contains('1.')) {
      // Split by numbered steps
      final regex = RegExp(r'\d+\.');
      final parts = instructions.split(regex);
      for (int i = 1; i < parts.length; i++) {
        if (parts[i].trim().isNotEmpty) {
          // Clean up the step text by removing unwanted characters
          String cleanStep = parts[i].trim();
          // Remove leading brackets, commas, and other unwanted characters
          cleanStep = cleanStep.replaceAll(RegExp(r'^[\[,\s]+'), '');
          // Remove trailing brackets, commas, and other unwanted characters
          cleanStep = cleanStep.replaceAll(RegExp(r'[\]\s,]+$'), '');
          // Remove any remaining unwanted characters at the start
          cleanStep = cleanStep.replaceAll(RegExp(r'^[\[,\s]+'), '');
          
          if (cleanStep.isNotEmpty) {
            steps.add('${i}.${cleanStep}');
          }
        }
      }
    } else {
      // Split by sentences or periods
      steps = instructions.split('.')
          .where((step) => step.trim().isNotEmpty)
          .map((step) {
            // Clean up each step
            String cleanStep = step.trim();
            // Remove leading brackets, commas, and other unwanted characters
            cleanStep = cleanStep.replaceAll(RegExp(r'^[\[,\s]+'), '');
            // Remove trailing brackets, commas, and other unwanted characters
            cleanStep = cleanStep.replaceAll(RegExp(r'[\]\s,]+$'), '');
            return cleanStep;
          })
          .where((step) => step.isNotEmpty)
          .toList();
    }

    if (steps.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: Text(
          instructions,
          style: TextStyle(
            color: Colors.white.withOpacity(0.95),
            fontSize: 18,
            height: 1.7,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }
    
    return Column(
      children: steps.asMap().entries.map((entry) {
        final index = entry.key;
        final step = entry.value;
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.orange.withOpacity(0.8),
                      Colors.orange.withOpacity(0.6),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.orange.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  step,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.95),
                    fontSize: 18,
                    height: 1.6,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  String _formatBodyPartName(String bodyPart) {
    switch (bodyPart.toLowerCase()) {
      case 'upper arms':
        return 'Upper Arms';
      case 'lower arms':
        return 'Lower Arms';
      case 'upper legs':
        return 'Upper Legs';
      case 'lower legs':
        return 'Lower Legs';
      case 'shoulders':
        return 'Shoulders';
      case 'waist':
        return 'Core/Waist';
      case 'cardio':
        return 'Cardio';
      case 'chest':
        return 'Chest';
      case 'back':
        return 'Back';
      case 'neck':
        return 'Neck';
      default:
        return bodyPart.split(' ').map((word) => 
          word[0].toUpperCase() + word.substring(1)
        ).join(' ');
    }
  }

  String _formatSecondaryMuscles(dynamic secondaryMuscles) {
    if (secondaryMuscles == null) {
      return 'No secondary muscles specified.';
    }
    if (secondaryMuscles is String) {
      return secondaryMuscles;
    }
    if (secondaryMuscles is List) {
      return secondaryMuscles.join(', ');
    }
    return 'Unknown secondary muscles format.';
  }

  String _formatExerciseName(dynamic name) {
    if (name == null) {
      return 'Unknown Exercise';
    }
    if (name is String) {
      // Truncate very long names to prevent overflow
      if (name.length > 50) {
        return name.substring(0, 47) + '...';
      }
      return name;
    }
    return 'Unknown Exercise';
  }

  String _formatField(dynamic field, String fallback) {
    if (field == null) {
      return fallback;
    }
    if (field is String) {
      return field;
    }
    return fallback;
  }

  String _cleanInstructions(String instructions) {
    // Remove leading and trailing brackets
    String cleaned = instructions.trim();
    
    // Remove opening bracket at the start
    if (cleaned.startsWith('[')) {
      cleaned = cleaned.substring(1);
    }
    
    // Remove closing bracket at the end
    if (cleaned.endsWith(']')) {
      cleaned = cleaned.substring(0, cleaned.length - 1);
    }
    
    // Remove leading commas and spaces
    cleaned = cleaned.replaceAll(RegExp(r'^[,\s]+'), '');
    
    // Remove trailing commas and spaces
    cleaned = cleaned.replaceAll(RegExp(r'[,\s]+$'), '');
    
    // Replace multiple commas with periods for better readability
    cleaned = cleaned.replaceAll(RegExp(r',\s*,'), '. ');
    cleaned = cleaned.replaceAll(RegExp(r',\s*$'), '.');
    
    // Add period at the end if it doesn't have one
    if (!cleaned.endsWith('.') && !cleaned.endsWith('!') && !cleaned.endsWith('?')) {
      cleaned += '.';
    }
    
    return cleaned.trim();
  }

  String _getInstructions(dynamic exercise) {
    // Check multiple possible field names for instructions
    final possibleFields = [
      'instructions',
      'instruction',
      'description',
      'desc',
      'steps',
      'how_to',
      'howTo',
      'method',
      'technique',
      'procedure'
    ];
    
    for (String field in possibleFields) {
      if (exercise[field] != null && exercise[field].toString().isNotEmpty) {
        print('✅ Found instructions in field: $field');
        String instructions = exercise[field].toString();
        return _cleanInstructions(instructions);
      }
    }
    
    print('❌ No instructions found in any field');
    return 'No instructions available for this exercise.';
  }
} 