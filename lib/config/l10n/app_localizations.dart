import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('en')];

  /// Application name
  ///
  /// In en, this message translates to:
  /// **'C-AlgoVisualizer'**
  String get appName;

  /// Full browser/app title
  ///
  /// In en, this message translates to:
  /// **'C-AlgoVisualizer | Learn C & Algorithms Visually'**
  String get appTitle;

  /// Welcome heading
  ///
  /// In en, this message translates to:
  /// **'Welcome to C-AlgoVisualizer'**
  String get welcome;

  /// App subtitle / tagline
  ///
  /// In en, this message translates to:
  /// **'Learn C programming and algorithms with interactive visualizations'**
  String get subtitle;

  /// Editor tab/screen label
  ///
  /// In en, this message translates to:
  /// **'Editor'**
  String get editor;

  /// Editor placeholder hint
  ///
  /// In en, this message translates to:
  /// **'Write your C code here'**
  String get editorHint;

  /// Visualizer panel label
  ///
  /// In en, this message translates to:
  /// **'Visualizer'**
  String get visualizer;

  /// Curriculum nav label
  ///
  /// In en, this message translates to:
  /// **'Curriculum'**
  String get curriculum;

  /// No description provided for @courses.
  ///
  /// In en, this message translates to:
  /// **'Courses'**
  String get courses;

  /// No description provided for @lessons.
  ///
  /// In en, this message translates to:
  /// **'Lessons'**
  String get lessons;

  /// No description provided for @run.
  ///
  /// In en, this message translates to:
  /// **'Run'**
  String get run;

  /// No description provided for @runCode.
  ///
  /// In en, this message translates to:
  /// **'Run Code'**
  String get runCode;

  /// No description provided for @stop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get stop;

  /// No description provided for @reset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @step.
  ///
  /// In en, this message translates to:
  /// **'Step'**
  String get step;

  /// No description provided for @stepBy.
  ///
  /// In en, this message translates to:
  /// **'Step By Step'**
  String get stepBy;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @previous.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get previous;

  /// No description provided for @play.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get play;

  /// No description provided for @pause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get pause;

  /// Current step counter
  ///
  /// In en, this message translates to:
  /// **'Step {count}'**
  String stepCount(int count);

  /// No description provided for @variables.
  ///
  /// In en, this message translates to:
  /// **'Variables'**
  String get variables;

  /// No description provided for @stack.
  ///
  /// In en, this message translates to:
  /// **'Stack'**
  String get stack;

  /// No description provided for @heap.
  ///
  /// In en, this message translates to:
  /// **'Heap'**
  String get heap;

  /// No description provided for @memory.
  ///
  /// In en, this message translates to:
  /// **'Memory'**
  String get memory;

  /// No description provided for @output.
  ///
  /// In en, this message translates to:
  /// **'Output'**
  String get output;

  /// No description provided for @console.
  ///
  /// In en, this message translates to:
  /// **'Console'**
  String get console;

  /// No description provided for @input.
  ///
  /// In en, this message translates to:
  /// **'Input'**
  String get input;

  /// No description provided for @stdin.
  ///
  /// In en, this message translates to:
  /// **'Standard Input'**
  String get stdin;

  /// No description provided for @stdout.
  ///
  /// In en, this message translates to:
  /// **'Standard Output'**
  String get stdout;

  /// No description provided for @stderr.
  ///
  /// In en, this message translates to:
  /// **'Standard Error'**
  String get stderr;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @warning.
  ///
  /// In en, this message translates to:
  /// **'Warning'**
  String get warning;

  /// No description provided for @success.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get success;

  /// No description provided for @info.
  ///
  /// In en, this message translates to:
  /// **'Info'**
  String get info;

  /// No description provided for @errorOccurred.
  ///
  /// In en, this message translates to:
  /// **'An error occurred'**
  String get errorOccurred;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get tryAgain;

  /// No description provided for @goBack.
  ///
  /// In en, this message translates to:
  /// **'Go Back'**
  String get goBack;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @initializing.
  ///
  /// In en, this message translates to:
  /// **'Initializing...'**
  String get initializing;

  /// No description provided for @executing.
  ///
  /// In en, this message translates to:
  /// **'Executing...'**
  String get executing;

  /// No description provided for @compiling.
  ///
  /// In en, this message translates to:
  /// **'Compiling...'**
  String get compiling;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkMode;

  /// No description provided for @lightMode.
  ///
  /// In en, this message translates to:
  /// **'Light Mode'**
  String get lightMode;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @fontSize.
  ///
  /// In en, this message translates to:
  /// **'Font Size'**
  String get fontSize;

  /// No description provided for @fontSizeSmall.
  ///
  /// In en, this message translates to:
  /// **'Small'**
  String get fontSizeSmall;

  /// No description provided for @fontSizeMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get fontSizeMedium;

  /// No description provided for @fontSizeLarge.
  ///
  /// In en, this message translates to:
  /// **'Large'**
  String get fontSizeLarge;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @aboutText.
  ///
  /// In en, this message translates to:
  /// **'C-AlgoVisualizer is an educational platform for learning C programming and algorithms with interactive visualizations.'**
  String get aboutText;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String version(String version);

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @saved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get saved;

  /// No description provided for @saveProgress.
  ///
  /// In en, this message translates to:
  /// **'Save Progress'**
  String get saveProgress;

  /// No description provided for @saveSuccess.
  ///
  /// In en, this message translates to:
  /// **'Progress saved successfully'**
  String get saveSuccess;

  /// No description provided for @saveFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to save progress'**
  String get saveFailed;

  /// No description provided for @unsavedChanges.
  ///
  /// In en, this message translates to:
  /// **'You have unsaved changes'**
  String get unsavedChanges;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signIn;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get signOut;

  /// No description provided for @linkGoogle.
  ///
  /// In en, this message translates to:
  /// **'Link with Google'**
  String get linkGoogle;

  /// No description provided for @unlinkGoogle.
  ///
  /// In en, this message translates to:
  /// **'Unlink Google Account'**
  String get unlinkGoogle;

  /// No description provided for @anonymousUser.
  ///
  /// In en, this message translates to:
  /// **'Anonymous User'**
  String get anonymousUser;

  /// No description provided for @syncData.
  ///
  /// In en, this message translates to:
  /// **'Sync Data'**
  String get syncData;

  /// No description provided for @noData.
  ///
  /// In en, this message translates to:
  /// **'No data available'**
  String get noData;

  /// No description provided for @noResults.
  ///
  /// In en, this message translates to:
  /// **'No results found'**
  String get noResults;

  /// No description provided for @empty.
  ///
  /// In en, this message translates to:
  /// **'Empty'**
  String get empty;

  /// No description provided for @emptyState.
  ///
  /// In en, this message translates to:
  /// **'Nothing here yet'**
  String get emptyState;

  /// No description provided for @confirmAction.
  ///
  /// In en, this message translates to:
  /// **'Confirm Action'**
  String get confirmAction;

  /// No description provided for @areYouSure.
  ///
  /// In en, this message translates to:
  /// **'Are you sure?'**
  String get areYouSure;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @deleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this?'**
  String get deleteConfirm;

  /// No description provided for @curriculumTitle.
  ///
  /// In en, this message translates to:
  /// **'Curriculum'**
  String get curriculumTitle;

  /// No description provided for @curriculumSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Master C programming with our structured learning path'**
  String get curriculumSubtitle;

  /// No description provided for @module.
  ///
  /// In en, this message translates to:
  /// **'Module'**
  String get module;

  /// No description provided for @moduleCount.
  ///
  /// In en, this message translates to:
  /// **'{count} modules'**
  String moduleCount(int count);

  /// No description provided for @difficulty.
  ///
  /// In en, this message translates to:
  /// **'Difficulty'**
  String get difficulty;

  /// No description provided for @difficultyBeginner.
  ///
  /// In en, this message translates to:
  /// **'Beginner'**
  String get difficultyBeginner;

  /// No description provided for @difficultyIntermediate.
  ///
  /// In en, this message translates to:
  /// **'Intermediate'**
  String get difficultyIntermediate;

  /// No description provided for @difficultyAdvanced.
  ///
  /// In en, this message translates to:
  /// **'Advanced'**
  String get difficultyAdvanced;

  /// No description provided for @progress.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get progress;

  /// No description provided for @completion.
  ///
  /// In en, this message translates to:
  /// **'Completion'**
  String get completion;

  /// No description provided for @lessonsCompleted.
  ///
  /// In en, this message translates to:
  /// **'{completed}/{total} lessons completed'**
  String lessonsCompleted(int completed, int total);

  /// No description provided for @syntaxError.
  ///
  /// In en, this message translates to:
  /// **'Syntax Error'**
  String get syntaxError;

  /// No description provided for @runtimeError.
  ///
  /// In en, this message translates to:
  /// **'Runtime Error'**
  String get runtimeError;

  /// No description provided for @compilationError.
  ///
  /// In en, this message translates to:
  /// **'Compilation Error'**
  String get compilationError;

  /// No description provided for @segmentationFault.
  ///
  /// In en, this message translates to:
  /// **'Segmentation Fault'**
  String get segmentationFault;

  /// No description provided for @codeSyntax.
  ///
  /// In en, this message translates to:
  /// **'Code Syntax'**
  String get codeSyntax;

  /// No description provided for @codeCompletion.
  ///
  /// In en, this message translates to:
  /// **'Code Completion'**
  String get codeCompletion;

  /// No description provided for @autoIndent.
  ///
  /// In en, this message translates to:
  /// **'Auto Indent'**
  String get autoIndent;

  /// No description provided for @lineNumbers.
  ///
  /// In en, this message translates to:
  /// **'Line Numbers'**
  String get lineNumbers;

  /// No description provided for @highlightSyntax.
  ///
  /// In en, this message translates to:
  /// **'Syntax Highlighting'**
  String get highlightSyntax;

  /// No description provided for @wordWrap.
  ///
  /// In en, this message translates to:
  /// **'Word Wrap'**
  String get wordWrap;

  /// No description provided for @cModule.
  ///
  /// In en, this message translates to:
  /// **'C Module'**
  String get cModule;

  /// No description provided for @basicModule.
  ///
  /// In en, this message translates to:
  /// **'Basics'**
  String get basicModule;

  /// No description provided for @variablesModule.
  ///
  /// In en, this message translates to:
  /// **'Variables & Types'**
  String get variablesModule;

  /// No description provided for @operatorsModule.
  ///
  /// In en, this message translates to:
  /// **'Operators'**
  String get operatorsModule;

  /// No description provided for @controlFlowModule.
  ///
  /// In en, this message translates to:
  /// **'Control Flow'**
  String get controlFlowModule;

  /// No description provided for @functionsModule.
  ///
  /// In en, this message translates to:
  /// **'Functions'**
  String get functionsModule;

  /// No description provided for @arraysModule.
  ///
  /// In en, this message translates to:
  /// **'Arrays & Strings'**
  String get arraysModule;

  /// No description provided for @pointersModule.
  ///
  /// In en, this message translates to:
  /// **'Pointers'**
  String get pointersModule;

  /// No description provided for @dynamicMemoryModule.
  ///
  /// In en, this message translates to:
  /// **'Dynamic Memory'**
  String get dynamicMemoryModule;

  /// No description provided for @structsModule.
  ///
  /// In en, this message translates to:
  /// **'Structs & Unions'**
  String get structsModule;

  /// No description provided for @fileIOModule.
  ///
  /// In en, this message translates to:
  /// **'File I/O'**
  String get fileIOModule;

  /// No description provided for @advancedModule.
  ///
  /// In en, this message translates to:
  /// **'Advanced Topics'**
  String get advancedModule;

  /// No description provided for @sortingVisualizer.
  ///
  /// In en, this message translates to:
  /// **'Sorting Visualizer'**
  String get sortingVisualizer;

  /// No description provided for @arrayLength.
  ///
  /// In en, this message translates to:
  /// **'Array Length'**
  String get arrayLength;

  /// No description provided for @arrayLengthHint.
  ///
  /// In en, this message translates to:
  /// **'Enter array length (1-100)'**
  String get arrayLengthHint;

  /// No description provided for @speed.
  ///
  /// In en, this message translates to:
  /// **'Speed'**
  String get speed;

  /// No description provided for @speedSlow.
  ///
  /// In en, this message translates to:
  /// **'Slow'**
  String get speedSlow;

  /// No description provided for @speedMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get speedMedium;

  /// No description provided for @speedFast.
  ///
  /// In en, this message translates to:
  /// **'Fast'**
  String get speedFast;

  /// No description provided for @bubbleSort.
  ///
  /// In en, this message translates to:
  /// **'Bubble Sort'**
  String get bubbleSort;

  /// No description provided for @selectionSort.
  ///
  /// In en, this message translates to:
  /// **'Selection Sort'**
  String get selectionSort;

  /// No description provided for @insertionSort.
  ///
  /// In en, this message translates to:
  /// **'Insertion Sort'**
  String get insertionSort;

  /// No description provided for @mergeSort.
  ///
  /// In en, this message translates to:
  /// **'Merge Sort'**
  String get mergeSort;

  /// No description provided for @quickSort.
  ///
  /// In en, this message translates to:
  /// **'Quick Sort'**
  String get quickSort;

  /// No description provided for @networkError.
  ///
  /// In en, this message translates to:
  /// **'Network Error'**
  String get networkError;

  /// No description provided for @offlineMode.
  ///
  /// In en, this message translates to:
  /// **'Offline Mode'**
  String get offlineMode;

  /// No description provided for @syncPending.
  ///
  /// In en, this message translates to:
  /// **'Sync Pending'**
  String get syncPending;

  /// No description provided for @lastSyncedAt.
  ///
  /// In en, this message translates to:
  /// **'Last synced at {time}'**
  String lastSyncedAt(String time);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
