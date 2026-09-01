// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'C-AlgoVisualizer';

  @override
  String get appTitle => 'C-AlgoVisualizer | Learn C & Algorithms Visually';

  @override
  String get welcome => 'Welcome to C-AlgoVisualizer';

  @override
  String get subtitle =>
      'Learn C programming and algorithms with interactive visualizations';

  @override
  String get editor => 'Editor';

  @override
  String get editorHint => 'Write your C code here';

  @override
  String get visualizer => 'Visualizer';

  @override
  String get curriculum => 'Curriculum';

  @override
  String get courses => 'Courses';

  @override
  String get lessons => 'Lessons';

  @override
  String get run => 'Run';

  @override
  String get runCode => 'Run Code';

  @override
  String get stop => 'Stop';

  @override
  String get reset => 'Reset';

  @override
  String get clear => 'Clear';

  @override
  String get step => 'Step';

  @override
  String get stepBy => 'Step By Step';

  @override
  String get next => 'Next';

  @override
  String get previous => 'Previous';

  @override
  String get play => 'Play';

  @override
  String get pause => 'Pause';

  @override
  String stepCount(int count) {
    return 'Step $count';
  }

  @override
  String get variables => 'Variables';

  @override
  String get stack => 'Stack';

  @override
  String get heap => 'Heap';

  @override
  String get memory => 'Memory';

  @override
  String get output => 'Output';

  @override
  String get console => 'Console';

  @override
  String get input => 'Input';

  @override
  String get stdin => 'Standard Input';

  @override
  String get stdout => 'Standard Output';

  @override
  String get stderr => 'Standard Error';

  @override
  String get error => 'Error';

  @override
  String get warning => 'Warning';

  @override
  String get success => 'Success';

  @override
  String get info => 'Info';

  @override
  String get errorOccurred => 'An error occurred';

  @override
  String get tryAgain => 'Try Again';

  @override
  String get goBack => 'Go Back';

  @override
  String get loading => 'Loading...';

  @override
  String get initializing => 'Initializing...';

  @override
  String get executing => 'Executing...';

  @override
  String get compiling => 'Compiling...';

  @override
  String get settings => 'Settings';

  @override
  String get theme => 'Theme';

  @override
  String get darkMode => 'Dark Mode';

  @override
  String get lightMode => 'Light Mode';

  @override
  String get language => 'Language';

  @override
  String get fontSize => 'Font Size';

  @override
  String get fontSizeSmall => 'Small';

  @override
  String get fontSizeMedium => 'Medium';

  @override
  String get fontSizeLarge => 'Large';

  @override
  String get about => 'About';

  @override
  String get aboutText =>
      'C-AlgoVisualizer is an educational platform for learning C programming and algorithms with interactive visualizations.';

  @override
  String version(String version) {
    return 'Version $version';
  }

  @override
  String get save => 'Save';

  @override
  String get saved => 'Saved';

  @override
  String get saveProgress => 'Save Progress';

  @override
  String get saveSuccess => 'Progress saved successfully';

  @override
  String get saveFailed => 'Failed to save progress';

  @override
  String get unsavedChanges => 'You have unsaved changes';

  @override
  String get login => 'Login';

  @override
  String get logout => 'Logout';

  @override
  String get signIn => 'Sign In';

  @override
  String get signOut => 'Sign Out';

  @override
  String get linkGoogle => 'Link with Google';

  @override
  String get unlinkGoogle => 'Unlink Google Account';

  @override
  String get anonymousUser => 'Anonymous User';

  @override
  String get syncData => 'Sync Data';

  @override
  String get noData => 'No data available';

  @override
  String get noResults => 'No results found';

  @override
  String get empty => 'Empty';

  @override
  String get emptyState => 'Nothing here yet';

  @override
  String get confirmAction => 'Confirm Action';

  @override
  String get areYouSure => 'Are you sure?';

  @override
  String get confirm => 'Confirm';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get deleteConfirm => 'Are you sure you want to delete this?';

  @override
  String get curriculumTitle => 'Curriculum';

  @override
  String get curriculumSubtitle =>
      'Master C programming with our structured learning path';

  @override
  String get module => 'Module';

  @override
  String moduleCount(int count) {
    return '$count modules';
  }

  @override
  String get difficulty => 'Difficulty';

  @override
  String get difficultyBeginner => 'Beginner';

  @override
  String get difficultyIntermediate => 'Intermediate';

  @override
  String get difficultyAdvanced => 'Advanced';

  @override
  String get progress => 'Progress';

  @override
  String get completion => 'Completion';

  @override
  String lessonsCompleted(int completed, int total) {
    return '$completed/$total lessons completed';
  }

  @override
  String get syntaxError => 'Syntax Error';

  @override
  String get runtimeError => 'Runtime Error';

  @override
  String get compilationError => 'Compilation Error';

  @override
  String get segmentationFault => 'Segmentation Fault';

  @override
  String get codeSyntax => 'Code Syntax';

  @override
  String get codeCompletion => 'Code Completion';

  @override
  String get autoIndent => 'Auto Indent';

  @override
  String get lineNumbers => 'Line Numbers';

  @override
  String get highlightSyntax => 'Syntax Highlighting';

  @override
  String get wordWrap => 'Word Wrap';

  @override
  String get cModule => 'C Module';

  @override
  String get basicModule => 'Basics';

  @override
  String get variablesModule => 'Variables & Types';

  @override
  String get operatorsModule => 'Operators';

  @override
  String get controlFlowModule => 'Control Flow';

  @override
  String get functionsModule => 'Functions';

  @override
  String get arraysModule => 'Arrays & Strings';

  @override
  String get pointersModule => 'Pointers';

  @override
  String get dynamicMemoryModule => 'Dynamic Memory';

  @override
  String get structsModule => 'Structs & Unions';

  @override
  String get fileIOModule => 'File I/O';

  @override
  String get advancedModule => 'Advanced Topics';

  @override
  String get sortingVisualizer => 'Sorting Visualizer';

  @override
  String get arrayLength => 'Array Length';

  @override
  String get arrayLengthHint => 'Enter array length (1-100)';

  @override
  String get speed => 'Speed';

  @override
  String get speedSlow => 'Slow';

  @override
  String get speedMedium => 'Medium';

  @override
  String get speedFast => 'Fast';

  @override
  String get bubbleSort => 'Bubble Sort';

  @override
  String get selectionSort => 'Selection Sort';

  @override
  String get insertionSort => 'Insertion Sort';

  @override
  String get mergeSort => 'Merge Sort';

  @override
  String get quickSort => 'Quick Sort';

  @override
  String get networkError => 'Network Error';

  @override
  String get offlineMode => 'Offline Mode';

  @override
  String get syncPending => 'Sync Pending';

  @override
  String lastSyncedAt(String time) {
    return 'Last synced at $time';
  }
}
