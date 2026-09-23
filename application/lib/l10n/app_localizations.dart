import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_bn.dart';
import 'app_localizations_en.dart';
import 'app_localizations_gu.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_kn.dart';
import 'app_localizations_ml.dart';
import 'app_localizations_mr.dart';
import 'app_localizations_pa.dart';
import 'app_localizations_ta.dart';
import 'app_localizations_te.dart';

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

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
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
  static const List<Locale> supportedLocales = <Locale>[
    Locale('bn'),
    Locale('en'),
    Locale('gu'),
    Locale('hi'),
    Locale('kn'),
    Locale('ml'),
    Locale('mr'),
    Locale('pa'),
    Locale('ta'),
    Locale('te'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'MANDAP'**
  String get appTitle;

  /// No description provided for @truss.
  ///
  /// In en, this message translates to:
  /// **'Truss'**
  String get truss;

  /// No description provided for @member.
  ///
  /// In en, this message translates to:
  /// **'Member'**
  String get member;

  /// No description provided for @node.
  ///
  /// In en, this message translates to:
  /// **'Node'**
  String get node;

  /// No description provided for @span.
  ///
  /// In en, this message translates to:
  /// **'Span'**
  String get span;

  /// No description provided for @elevation.
  ///
  /// In en, this message translates to:
  /// **'Elevation'**
  String get elevation;

  /// No description provided for @width.
  ///
  /// In en, this message translates to:
  /// **'Width'**
  String get width;

  /// No description provided for @depth.
  ///
  /// In en, this message translates to:
  /// **'Depth'**
  String get depth;

  /// No description provided for @height.
  ///
  /// In en, this message translates to:
  /// **'Height'**
  String get height;

  /// No description provided for @grid.
  ///
  /// In en, this message translates to:
  /// **'Grid'**
  String get grid;

  /// No description provided for @snap.
  ///
  /// In en, this message translates to:
  /// **'Snap'**
  String get snap;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @boxTruss.
  ///
  /// In en, this message translates to:
  /// **'Box Truss'**
  String get boxTruss;

  /// No description provided for @singleTube.
  ///
  /// In en, this message translates to:
  /// **'Single Tube'**
  String get singleTube;

  /// No description provided for @centerControl.
  ///
  /// In en, this message translates to:
  /// **'Center Control'**
  String get centerControl;

  /// No description provided for @generateTruss.
  ///
  /// In en, this message translates to:
  /// **'Generate Truss'**
  String get generateTruss;

  /// No description provided for @bom.
  ///
  /// In en, this message translates to:
  /// **'BOM'**
  String get bom;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @sync.
  ///
  /// In en, this message translates to:
  /// **'Sync'**
  String get sync;

  /// No description provided for @newProject.
  ///
  /// In en, this message translates to:
  /// **'New Project'**
  String get newProject;

  /// No description provided for @projectName.
  ///
  /// In en, this message translates to:
  /// **'Project Name'**
  String get projectName;

  /// No description provided for @plotSize.
  ///
  /// In en, this message translates to:
  /// **'Plot Size'**
  String get plotSize;

  /// No description provided for @plotWidth.
  ///
  /// In en, this message translates to:
  /// **'Plot Width'**
  String get plotWidth;

  /// No description provided for @plotDepth.
  ///
  /// In en, this message translates to:
  /// **'Plot Depth'**
  String get plotDepth;

  /// No description provided for @trussDimensions.
  ///
  /// In en, this message translates to:
  /// **'Truss Dimensions'**
  String get trussDimensions;

  /// No description provided for @trussWidth.
  ///
  /// In en, this message translates to:
  /// **'Truss Width'**
  String get trussWidth;

  /// No description provided for @trussDepth.
  ///
  /// In en, this message translates to:
  /// **'Truss Depth'**
  String get trussDepth;

  /// No description provided for @towerHeight.
  ///
  /// In en, this message translates to:
  /// **'Tower Height'**
  String get towerHeight;

  /// No description provided for @roofConfiguration.
  ///
  /// In en, this message translates to:
  /// **'Roof Configuration'**
  String get roofConfiguration;

  /// No description provided for @points5.
  ///
  /// In en, this message translates to:
  /// **'5-Point'**
  String get points5;

  /// No description provided for @points6.
  ///
  /// In en, this message translates to:
  /// **'6-Point'**
  String get points6;

  /// No description provided for @select.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get select;

  /// No description provided for @pen.
  ///
  /// In en, this message translates to:
  /// **'Pen'**
  String get pen;

  /// No description provided for @addMember.
  ///
  /// In en, this message translates to:
  /// **'Add Member'**
  String get addMember;

  /// No description provided for @stretch.
  ///
  /// In en, this message translates to:
  /// **'Stretch'**
  String get stretch;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @undo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undo;

  /// No description provided for @redo.
  ///
  /// In en, this message translates to:
  /// **'Redo'**
  String get redo;

  /// No description provided for @reset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;

  /// No description provided for @saved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get saved;

  /// No description provided for @saving.
  ///
  /// In en, this message translates to:
  /// **'Saving...'**
  String get saving;

  /// No description provided for @offline.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get offline;

  /// No description provided for @conflict.
  ///
  /// In en, this message translates to:
  /// **'Conflict'**
  String get conflict;

  /// No description provided for @position.
  ///
  /// In en, this message translates to:
  /// **'Position'**
  String get position;

  /// No description provided for @start.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get start;

  /// No description provided for @end.
  ///
  /// In en, this message translates to:
  /// **'End'**
  String get end;

  /// No description provided for @length.
  ///
  /// In en, this message translates to:
  /// **'Length'**
  String get length;

  /// No description provided for @geometricLength.
  ///
  /// In en, this message translates to:
  /// **'Geometric Length'**
  String get geometricLength;

  /// No description provided for @inventoryRequirement.
  ///
  /// In en, this message translates to:
  /// **'Inventory Requirement'**
  String get inventoryRequirement;

  /// No description provided for @totalStructural.
  ///
  /// In en, this message translates to:
  /// **'Total Structural'**
  String get totalStructural;

  /// No description provided for @chooseWhatToDesign.
  ///
  /// In en, this message translates to:
  /// **'Choose what to design'**
  String get chooseWhatToDesign;

  /// No description provided for @selectModuleSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Select an independent structural module to begin your event layout'**
  String get selectModuleSubtitle;

  /// No description provided for @moduleTrussSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Structural Truss Design'**
  String get moduleTrussSubtitle;

  /// No description provided for @modulePoleSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Pole Calculator'**
  String get modulePoleSubtitle;

  /// No description provided for @moduleStageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Stage Calculator'**
  String get moduleStageSubtitle;

  /// No description provided for @moduleFlooringSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Carpet & Flooring Calculator'**
  String get moduleFlooringSubtitle;

  /// No description provided for @active.
  ///
  /// In en, this message translates to:
  /// **'ACTIVE'**
  String get active;

  /// No description provided for @open.
  ///
  /// In en, this message translates to:
  /// **'OPEN'**
  String get open;

  /// No description provided for @exitApp.
  ///
  /// In en, this message translates to:
  /// **'Exit MANDAP?'**
  String get exitApp;

  /// No description provided for @confirmExit.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to exit the application?'**
  String get confirmExit;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @exit.
  ///
  /// In en, this message translates to:
  /// **'Exit'**
  String get exit;

  /// No description provided for @pole.
  ///
  /// In en, this message translates to:
  /// **'Pole'**
  String get pole;

  /// No description provided for @pipe.
  ///
  /// In en, this message translates to:
  /// **'Pipe'**
  String get pipe;

  /// No description provided for @modulePipeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Pipe Calculator'**
  String get modulePipeSubtitle;

  /// No description provided for @createPipeStructure.
  ///
  /// In en, this message translates to:
  /// **'Create Pipe Structure'**
  String get createPipeStructure;

  /// No description provided for @stage.
  ///
  /// In en, this message translates to:
  /// **'Stage'**
  String get stage;

  /// No description provided for @flooring.
  ///
  /// In en, this message translates to:
  /// **'Flooring'**
  String get flooring;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @flooringCalculatorTitle.
  ///
  /// In en, this message translates to:
  /// **'Flooring Calculator'**
  String get flooringCalculatorTitle;

  /// No description provided for @flooringCalculatorSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Calculate total carpet requirement for your plot size.'**
  String get flooringCalculatorSubtitle;

  /// No description provided for @enterPlotSize.
  ///
  /// In en, this message translates to:
  /// **'1. Enter Plot Size'**
  String get enterPlotSize;

  /// No description provided for @lengthFt.
  ///
  /// In en, this message translates to:
  /// **'Length (ft)'**
  String get lengthFt;

  /// No description provided for @widthFt.
  ///
  /// In en, this message translates to:
  /// **'Width (ft)'**
  String get widthFt;

  /// No description provided for @enterCarpetSize.
  ///
  /// In en, this message translates to:
  /// **'2. Enter Carpet Size'**
  String get enterCarpetSize;

  /// No description provided for @carpetLengthFt.
  ///
  /// In en, this message translates to:
  /// **'Carpet Length (ft)'**
  String get carpetLengthFt;

  /// No description provided for @carpetWidthFt.
  ///
  /// In en, this message translates to:
  /// **'Carpet Width (ft)'**
  String get carpetWidthFt;

  /// No description provided for @calculateFlooring.
  ///
  /// In en, this message translates to:
  /// **'CALCULATE FLOORING'**
  String get calculateFlooring;

  /// No description provided for @totalCarpetsRequired.
  ///
  /// In en, this message translates to:
  /// **'Total Carpets Required'**
  String get totalCarpetsRequired;

  /// No description provided for @calculationDetails.
  ///
  /// In en, this message translates to:
  /// **'Calculation Details'**
  String get calculationDetails;

  /// No description provided for @plotDimensions.
  ///
  /// In en, this message translates to:
  /// **'Plot Dimensions'**
  String get plotDimensions;

  /// No description provided for @plotArea.
  ///
  /// In en, this message translates to:
  /// **'Plot Area'**
  String get plotArea;

  /// No description provided for @carpetDimensions.
  ///
  /// In en, this message translates to:
  /// **'Carpet Dimensions'**
  String get carpetDimensions;

  /// No description provided for @carpetArea.
  ///
  /// In en, this message translates to:
  /// **'Carpet Area'**
  String get carpetArea;

  /// No description provided for @carpetsAlongLength.
  ///
  /// In en, this message translates to:
  /// **'Carpets Along Length'**
  String get carpetsAlongLength;

  /// No description provided for @carpetsAlongWidth.
  ///
  /// In en, this message translates to:
  /// **'Carpets Along Width'**
  String get carpetsAlongWidth;

  /// No description provided for @totalCarpets.
  ///
  /// In en, this message translates to:
  /// **'Total Carpets'**
  String get totalCarpets;

  /// No description provided for @totalCoverage.
  ///
  /// In en, this message translates to:
  /// **'Total Coverage'**
  String get totalCoverage;

  /// No description provided for @extraCoverage.
  ///
  /// In en, this message translates to:
  /// **'Extra Coverage'**
  String get extraCoverage;

  /// No description provided for @stageCalculatorTitle.
  ///
  /// In en, this message translates to:
  /// **'Stage Calculator'**
  String get stageCalculatorTitle;

  /// No description provided for @stageCalculatorSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Calculate stage table requirements & 3D modular setup.'**
  String get stageCalculatorSubtitle;

  /// No description provided for @stageDimensions.
  ///
  /// In en, this message translates to:
  /// **'1. Stage Dimensions'**
  String get stageDimensions;

  /// No description provided for @tableDimensions.
  ///
  /// In en, this message translates to:
  /// **'2. Table Dimensions'**
  String get tableDimensions;

  /// No description provided for @heightFt.
  ///
  /// In en, this message translates to:
  /// **'Height (ft)'**
  String get heightFt;

  /// No description provided for @calculateStage.
  ///
  /// In en, this message translates to:
  /// **'CALCULATE STAGE'**
  String get calculateStage;

  /// No description provided for @stageRequirement.
  ///
  /// In en, this message translates to:
  /// **'Stage Requirement'**
  String get stageRequirement;

  /// No description provided for @stageTables.
  ///
  /// In en, this message translates to:
  /// **'STAGE TABLES'**
  String get stageTables;

  /// No description provided for @layoutBreakdown.
  ///
  /// In en, this message translates to:
  /// **'Layout Breakdown'**
  String get layoutBreakdown;

  /// No description provided for @gridLW.
  ///
  /// In en, this message translates to:
  /// **'Grid (L × W)'**
  String get gridLW;

  /// No description provided for @tableOrientation.
  ///
  /// In en, this message translates to:
  /// **'Table Orientation'**
  String get tableOrientation;

  /// No description provided for @coveredArea.
  ///
  /// In en, this message translates to:
  /// **'Covered Area'**
  String get coveredArea;

  /// No description provided for @stageHeight.
  ///
  /// In en, this message translates to:
  /// **'Stage Height'**
  String get stageHeight;

  /// No description provided for @poleCalculatorTitle.
  ///
  /// In en, this message translates to:
  /// **'Pole Calculator'**
  String get poleCalculatorTitle;

  /// No description provided for @poleCalculatorSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Calculate vertical poles & horizontal pipes required for plot.'**
  String get poleCalculatorSubtitle;

  /// No description provided for @gridSizeFt.
  ///
  /// In en, this message translates to:
  /// **'Grid Size (ft)'**
  String get gridSizeFt;

  /// No description provided for @calculatePoles.
  ///
  /// In en, this message translates to:
  /// **'CALCULATE POLES'**
  String get calculatePoles;

  /// No description provided for @poleRequirement.
  ///
  /// In en, this message translates to:
  /// **'POLE REQUIREMENT'**
  String get poleRequirement;

  /// No description provided for @verticalPoles.
  ///
  /// In en, this message translates to:
  /// **'VERTICAL POLES'**
  String get verticalPoles;

  /// No description provided for @horizontalPipes.
  ///
  /// In en, this message translates to:
  /// **'HORIZONTAL PIPES'**
  String get horizontalPipes;

  /// No description provided for @ceilingSections.
  ///
  /// In en, this message translates to:
  /// **'CEILING SECTIONS'**
  String get ceilingSections;

  /// No description provided for @gridBreakdown.
  ///
  /// In en, this message translates to:
  /// **'Grid Breakdown'**
  String get gridBreakdown;

  /// No description provided for @gridPoleUnit.
  ///
  /// In en, this message translates to:
  /// **'Grid Pole Unit'**
  String get gridPoleUnit;

  /// No description provided for @lengthBays.
  ///
  /// In en, this message translates to:
  /// **'Length Bays'**
  String get lengthBays;

  /// No description provided for @widthBays.
  ///
  /// In en, this message translates to:
  /// **'Width Bays'**
  String get widthBays;

  /// No description provided for @welcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get welcome;

  /// No description provided for @signInSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in with your phone number to access MANDAP'**
  String get signInSubtitle;

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneNumber;

  /// No description provided for @phoneNumberRequired.
  ///
  /// In en, this message translates to:
  /// **'Phone Number *'**
  String get phoneNumberRequired;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @passwordRequired.
  ///
  /// In en, this message translates to:
  /// **'Password *'**
  String get passwordRequired;

  /// No description provided for @fullNameOptional.
  ///
  /// In en, this message translates to:
  /// **'Full Name (optional)'**
  String get fullNameOptional;

  /// No description provided for @emailOptional.
  ///
  /// In en, this message translates to:
  /// **'Email (optional)'**
  String get emailOptional;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPassword;

  /// No description provided for @continueButton.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueButton;

  /// No description provided for @dontHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get dontHaveAccount;

  /// No description provided for @createOne.
  ///
  /// In en, this message translates to:
  /// **'Create one'**
  String get createOne;

  /// No description provided for @verifyPhone.
  ///
  /// In en, this message translates to:
  /// **'Verify Phone'**
  String get verifyPhone;

  /// No description provided for @otpSentTo.
  ///
  /// In en, this message translates to:
  /// **'We sent a 6-digit code to'**
  String get otpSentTo;

  /// No description provided for @otpLabel.
  ///
  /// In en, this message translates to:
  /// **'6-Digit OTP'**
  String get otpLabel;

  /// No description provided for @verifyAndSignIn.
  ///
  /// In en, this message translates to:
  /// **'Verify & Sign In'**
  String get verifyAndSignIn;

  /// No description provided for @changePhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Change phone number'**
  String get changePhoneNumber;

  /// No description provided for @joinMandap.
  ///
  /// In en, this message translates to:
  /// **'Join MANDAP'**
  String get joinMandap;

  /// No description provided for @joinSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your details to create a new account'**
  String get joinSubtitle;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get createAccount;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get alreadyHaveAccount;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signIn;

  /// No description provided for @accountCreated.
  ///
  /// In en, this message translates to:
  /// **'Account Created!'**
  String get accountCreated;

  /// No description provided for @accountCreatedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your account has been set up successfully.'**
  String get accountCreatedSubtitle;

  /// No description provided for @continueToSignIn.
  ///
  /// In en, this message translates to:
  /// **'Continue to Sign In'**
  String get continueToSignIn;

  /// No description provided for @designModules.
  ///
  /// In en, this message translates to:
  /// **'Design Modules'**
  String get designModules;

  /// No description provided for @myProjects.
  ///
  /// In en, this message translates to:
  /// **'My Projects'**
  String get myProjects;

  /// No description provided for @viewAllProjects.
  ///
  /// In en, this message translates to:
  /// **'View all saved layouts in My Projects'**
  String get viewAllProjects;

  /// No description provided for @poles.
  ///
  /// In en, this message translates to:
  /// **'Poles'**
  String get poles;

  /// No description provided for @upperPipes.
  ///
  /// In en, this message translates to:
  /// **'Upper Pipes'**
  String get upperPipes;

  /// No description provided for @totalPipes.
  ///
  /// In en, this message translates to:
  /// **'Total Pipes'**
  String get totalPipes;

  /// No description provided for @retrieve.
  ///
  /// In en, this message translates to:
  /// **'Retrieve'**
  String get retrieve;

  /// No description provided for @retrieveLayout.
  ///
  /// In en, this message translates to:
  /// **'Retrieve Layout'**
  String get retrieveLayout;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @noProjectsFound.
  ///
  /// In en, this message translates to:
  /// **'No projects found'**
  String get noProjectsFound;

  /// No description provided for @createNewProject.
  ///
  /// In en, this message translates to:
  /// **'Create New Project'**
  String get createNewProject;

  /// No description provided for @view2D.
  ///
  /// In en, this message translates to:
  /// **'2D'**
  String get view2D;

  /// No description provided for @view3D.
  ///
  /// In en, this message translates to:
  /// **'3D'**
  String get view3D;

  /// No description provided for @summary.
  ///
  /// In en, this message translates to:
  /// **'Summary'**
  String get summary;

  /// No description provided for @tools.
  ///
  /// In en, this message translates to:
  /// **'Tools'**
  String get tools;

  /// No description provided for @eraser.
  ///
  /// In en, this message translates to:
  /// **'Eraser'**
  String get eraser;

  /// No description provided for @drawTruss.
  ///
  /// In en, this message translates to:
  /// **'Draw Truss'**
  String get drawTruss;

  /// No description provided for @eraserTool.
  ///
  /// In en, this message translates to:
  /// **'Eraser Tool'**
  String get eraserTool;

  /// No description provided for @addPoleTool.
  ///
  /// In en, this message translates to:
  /// **'Add Pole Tool'**
  String get addPoleTool;

  /// No description provided for @createTruss.
  ///
  /// In en, this message translates to:
  /// **'CREATE TRUSS'**
  String get createTruss;

  /// No description provided for @enterPlotAndTrussSpec.
  ///
  /// In en, this message translates to:
  /// **'Enter plot & custom truss specifications'**
  String get enterPlotAndTrussSpec;

  /// No description provided for @plotSizeLengthWidth.
  ///
  /// In en, this message translates to:
  /// **'PLOT SIZE (Length / Width)'**
  String get plotSizeLengthWidth;

  /// No description provided for @selectOrWriteTrussSize.
  ///
  /// In en, this message translates to:
  /// **'SELECT OR WRITE TRUSS SIZE'**
  String get selectOrWriteTrussSize;

  /// No description provided for @custom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get custom;

  /// No description provided for @customTrussSizeWrite.
  ///
  /// In en, this message translates to:
  /// **'CUSTOM TRUSS SIZE (Write your value)'**
  String get customTrussSizeWrite;

  /// No description provided for @trussSizeLabel.
  ///
  /// In en, this message translates to:
  /// **'TRUSS SIZE'**
  String get trussSizeLabel;

  /// No description provided for @generateTrussButton.
  ///
  /// In en, this message translates to:
  /// **'GENERATE TRUSS'**
  String get generateTrussButton;

  /// No description provided for @designComplete.
  ///
  /// In en, this message translates to:
  /// **'Design Complete'**
  String get designComplete;

  /// No description provided for @trussAndPolesSummary.
  ///
  /// In en, this message translates to:
  /// **'Truss & Poles Summary'**
  String get trussAndPolesSummary;

  /// No description provided for @totalTrusses.
  ///
  /// In en, this message translates to:
  /// **'Total Trusses'**
  String get totalTrusses;

  /// No description provided for @totalSpan.
  ///
  /// In en, this message translates to:
  /// **'Total Span'**
  String get totalSpan;

  /// No description provided for @supportPoles.
  ///
  /// In en, this message translates to:
  /// **'Support Poles'**
  String get supportPoles;

  /// No description provided for @corner.
  ///
  /// In en, this message translates to:
  /// **'Corner'**
  String get corner;

  /// No description provided for @mid.
  ///
  /// In en, this message translates to:
  /// **'Mid'**
  String get mid;

  /// No description provided for @trussSizesUsed.
  ///
  /// In en, this message translates to:
  /// **'TRUSS SIZES USED'**
  String get trussSizesUsed;

  /// No description provided for @totalLength.
  ///
  /// In en, this message translates to:
  /// **'total length'**
  String get totalLength;

  /// No description provided for @gatesAndEntrances.
  ///
  /// In en, this message translates to:
  /// **'GATES & ENTRANCES'**
  String get gatesAndEntrances;

  /// No description provided for @gateOpening.
  ///
  /// In en, this message translates to:
  /// **'Gate Opening'**
  String get gateOpening;

  /// No description provided for @copy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copy;

  /// No description provided for @okDone.
  ///
  /// In en, this message translates to:
  /// **'OK / Done'**
  String get okDone;

  /// No description provided for @summaryCopied.
  ///
  /// In en, this message translates to:
  /// **'Summary copied to clipboard!'**
  String get summaryCopied;

  /// No description provided for @noTrussMembersDrawn.
  ///
  /// In en, this message translates to:
  /// **'No truss members drawn yet.'**
  String get noTrussMembersDrawn;

  /// No description provided for @trussEditorHint.
  ///
  /// In en, this message translates to:
  /// **'Use Pencil to draw or split truss. Use Eraser to remove truss. Tap center dot to create center cross.'**
  String get trussEditorHint;

  /// No description provided for @createStageStructure.
  ///
  /// In en, this message translates to:
  /// **'CREATE STAGE STRUCTURE'**
  String get createStageStructure;

  /// No description provided for @enterStageDimensionsAndTable.
  ///
  /// In en, this message translates to:
  /// **'Enter stage dimensions & table layout'**
  String get enterStageDimensionsAndTable;

  /// No description provided for @stageSizeLengthWidth.
  ///
  /// In en, this message translates to:
  /// **'STAGE SIZE (Length / Width)'**
  String get stageSizeLengthWidth;

  /// No description provided for @stageTableSizeLengthWidth.
  ///
  /// In en, this message translates to:
  /// **'STAGE TABLE SIZE (Length / Width)'**
  String get stageTableSizeLengthWidth;

  /// No description provided for @generateStageStructure.
  ///
  /// In en, this message translates to:
  /// **'GENERATE STAGE STRUCTURE'**
  String get generateStageStructure;

  /// No description provided for @stageComplete.
  ///
  /// In en, this message translates to:
  /// **'Stage Complete'**
  String get stageComplete;

  /// No description provided for @stageTablesSummary.
  ///
  /// In en, this message translates to:
  /// **'Stage Tables Summary'**
  String get stageTablesSummary;

  /// No description provided for @totalStageTables.
  ///
  /// In en, this message translates to:
  /// **'Total Stage Tables'**
  String get totalStageTables;

  /// No description provided for @totalSupportLegs.
  ///
  /// In en, this message translates to:
  /// **'Total Support Legs'**
  String get totalSupportLegs;

  /// No description provided for @tables.
  ///
  /// In en, this message translates to:
  /// **'Tables'**
  String get tables;

  /// No description provided for @legs.
  ///
  /// In en, this message translates to:
  /// **'Legs'**
  String get legs;

  /// No description provided for @enterPlotAndPipeSpec.
  ///
  /// In en, this message translates to:
  /// **'Enter plot & pipe size specifications'**
  String get enterPlotAndPipeSpec;

  /// No description provided for @pipeSizeLabel.
  ///
  /// In en, this message translates to:
  /// **'PIPE SIZE'**
  String get pipeSizeLabel;

  /// No description provided for @generatePipeStructure.
  ///
  /// In en, this message translates to:
  /// **'GENERATE PIPE STRUCTURE'**
  String get generatePipeStructure;

  /// No description provided for @polesSetupComplete.
  ///
  /// In en, this message translates to:
  /// **'Poles Setup Complete'**
  String get polesSetupComplete;

  /// No description provided for @polesAndPipesSummary.
  ///
  /// In en, this message translates to:
  /// **'Poles & Pipes Summary'**
  String get polesAndPipesSummary;

  /// No description provided for @totalVerticalPoles.
  ///
  /// In en, this message translates to:
  /// **'Total Vertical Poles'**
  String get totalVerticalPoles;

  /// No description provided for @totalHorizontalPipes.
  ///
  /// In en, this message translates to:
  /// **'Total Horizontal Pipes'**
  String get totalHorizontalPipes;

  /// No description provided for @createFlooringLayout.
  ///
  /// In en, this message translates to:
  /// **'CREATE FLOORING LAYOUT'**
  String get createFlooringLayout;

  /// No description provided for @enterPlotAndCarpetSpec.
  ///
  /// In en, this message translates to:
  /// **'Enter plot & carpet specifications'**
  String get enterPlotAndCarpetSpec;

  /// No description provided for @carpetSizeLengthWidth.
  ///
  /// In en, this message translates to:
  /// **'CARPET SIZE (Length / Width)'**
  String get carpetSizeLengthWidth;

  /// No description provided for @generateFlooringLayout.
  ///
  /// In en, this message translates to:
  /// **'GENERATE FLOORING LAYOUT'**
  String get generateFlooringLayout;

  /// No description provided for @flooringComplete.
  ///
  /// In en, this message translates to:
  /// **'Flooring Complete'**
  String get flooringComplete;

  /// No description provided for @carpetsAndFlooringSummary.
  ///
  /// In en, this message translates to:
  /// **'Carpets & Flooring Summary'**
  String get carpetsAndFlooringSummary;

  /// No description provided for @carpetRollsUnits.
  ///
  /// In en, this message translates to:
  /// **'Carpet Rolls / Units'**
  String get carpetRollsUnits;

  /// No description provided for @carpets.
  ///
  /// In en, this message translates to:
  /// **'Carpets'**
  String get carpets;

  /// No description provided for @totalFloorArea.
  ///
  /// In en, this message translates to:
  /// **'Total Floor Area'**
  String get totalFloorArea;

  /// No description provided for @centerCrossSupportRequired.
  ///
  /// In en, this message translates to:
  /// **'Center Cross Support Required'**
  String get centerCrossSupportRequired;

  /// No description provided for @centerCrossSupportDesc.
  ///
  /// In en, this message translates to:
  /// **'4 supporting perimeter poles are required before creating a center cross structure.'**
  String get centerCrossSupportDesc;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'bn',
    'en',
    'gu',
    'hi',
    'kn',
    'ml',
    'mr',
    'pa',
    'ta',
    'te',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'bn':
      return AppLocalizationsBn();
    case 'en':
      return AppLocalizationsEn();
    case 'gu':
      return AppLocalizationsGu();
    case 'hi':
      return AppLocalizationsHi();
    case 'kn':
      return AppLocalizationsKn();
    case 'ml':
      return AppLocalizationsMl();
    case 'mr':
      return AppLocalizationsMr();
    case 'pa':
      return AppLocalizationsPa();
    case 'ta':
      return AppLocalizationsTa();
    case 'te':
      return AppLocalizationsTe();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
