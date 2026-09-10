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
