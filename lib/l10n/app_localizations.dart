import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ms.dart';
import 'app_localizations_ta.dart';
import 'app_localizations_zh.dart';

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
    Locale('en'),
    Locale('ms'),
    Locale('ta'),
    Locale('zh'),
  ];

  /// Heat Map
  ///
  /// In en, this message translates to:
  /// **'Heat Map'**
  String get heatMap;

  /// Time
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get time;

  /// Low
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get low;

  /// Medium
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get medium;

  /// High
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get high;

  /// Note
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get note;

  /// Remove
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// Delete
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// Cancel
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Home button
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// Report Incident button
  ///
  /// In en, this message translates to:
  /// **'Report Incident'**
  String get navReportIncident;

  /// Profile button
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// Upcoming Scheduled Maintenance
  ///
  /// In en, this message translates to:
  /// **'Upcoming Scheduled Maintenance'**
  String get spUpcomingMaintenance;

  /// Singpass page welcome
  ///
  /// In en, this message translates to:
  /// **'Welcome to Singpass'**
  String get spWelcome;

  /// Your trusted digital identity
  ///
  /// In en, this message translates to:
  /// **'Your trusted digital identity'**
  String get spYourTrustedDigitalIdentity;

  /// Tap QR code to log in Singpass
  ///
  /// In en, this message translates to:
  /// **'Tap QR code\nto log in with Singpass app'**
  String get spTapQrToLogin;

  /// Don't have Singpass app
  ///
  /// In en, this message translates to:
  /// **'Don\'t have Singpass app'**
  String get spNoSingpass;

  /// Download now
  ///
  /// In en, this message translates to:
  /// **'Download now'**
  String get spDownloadNow;

  /// Text for report now button
  ///
  /// In en, this message translates to:
  /// **'Report Now!'**
  String get homeReportNow;

  /// Observation Checkpoints
  ///
  /// In en, this message translates to:
  /// **'Observation Checkpoints'**
  String get homeObservationCheckpoints;

  /// Not yet logged status for Observation Checkpoints
  ///
  /// In en, this message translates to:
  /// **'Not yet logged'**
  String get homeObservationNotLogged;

  /// Captured status for Observation Checkpoints
  ///
  /// In en, this message translates to:
  /// **'Captured'**
  String get homeObservationCaptured;

  /// Predictive Analysis
  ///
  /// In en, this message translates to:
  /// **'Predictive Analysis'**
  String get homePredictiveAnalysis;

  /// Recent Reports
  ///
  /// In en, this message translates to:
  /// **'Recent Reports'**
  String get homeRecentReports;

  /// Incident Details
  ///
  /// In en, this message translates to:
  /// **'Incident Details'**
  String get homeIncidentDetails;

  /// Flag Incident
  ///
  /// In en, this message translates to:
  /// **'Flag Incident'**
  String get flagIncident;

  /// Reason label
  ///
  /// In en, this message translates to:
  /// **'Reason'**
  String get flagLabelReason;

  /// Additional Details placeholder
  ///
  /// In en, this message translates to:
  /// **'Additional Details (optional)'**
  String get flagLabelAdditional;

  /// Submit flagging button text
  ///
  /// In en, this message translates to:
  /// **'Submit Flagging'**
  String get flagSubmit;

  /// Flagged Misreporting
  ///
  /// In en, this message translates to:
  /// **'Misreporting'**
  String get flagTypeMisreporting;

  /// Flagged Offensive Content
  ///
  /// In en, this message translates to:
  /// **'Offensive Content'**
  String get flagTypeOffensiveContent;

  /// Flagged Spam
  ///
  /// In en, this message translates to:
  /// **'Spam'**
  String get flagTypeSpam;

  /// Flagged Incorrect Location
  ///
  /// In en, this message translates to:
  /// **'Incorrect Location'**
  String get flagTypeIncorrectLocation;

  /// Flagged Other
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get flagTypeOther;

  /// Report Submitted
  ///
  /// In en, this message translates to:
  /// **'Report Submitted'**
  String get flagReportSubmitted;

  /// Report success message
  ///
  /// In en, this message translates to:
  /// **'Your report has been successfully sent'**
  String get flagReportSuccess;

  /// Report thank you message
  ///
  /// In en, this message translates to:
  /// **'Thank you for helping us improve community safety'**
  String get flagReportThankYou;

  /// Heat Map page bar title
  ///
  /// In en, this message translates to:
  /// **'Heat Map Analysis'**
  String get hmBarTitle;

  /// Type option All
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get hmTypeAll;

  /// Type option Fire
  ///
  /// In en, this message translates to:
  /// **'Fire'**
  String get hmTypeFire;

  /// Type option Crime
  ///
  /// In en, this message translates to:
  /// **'Crime'**
  String get hmTypeCrime;

  /// Type option Accident
  ///
  /// In en, this message translates to:
  /// **'Accident'**
  String get hmTypeAccident;

  /// Duration option Day
  ///
  /// In en, this message translates to:
  /// **'Day'**
  String get hmDurationDay;

  /// Duration option Week
  ///
  /// In en, this message translates to:
  /// **'Week'**
  String get hmDurationWeek;

  /// Duration option Month
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get hmDurationMonth;

  /// Duration option Day
  ///
  /// In en, this message translates to:
  /// **'High Risk'**
  String get hmHighRisk;

  /// Duration option Week
  ///
  /// In en, this message translates to:
  /// **'Medium Risk'**
  String get hmMediumRisk;

  /// Duration option Month
  ///
  /// In en, this message translates to:
  /// **'Low Risk'**
  String get hmLowRisk;

  /// Safety Statistics
  ///
  /// In en, this message translates to:
  /// **'Safety Statistics'**
  String get hmSafetyStatistics;

  /// AI Safety Score
  ///
  /// In en, this message translates to:
  /// **'AI Safety Score'**
  String get hmAISafetyScore;

  /// Recent Incidents
  ///
  /// In en, this message translates to:
  /// **'Recent Incidents'**
  String get hmRecentIncidents;

  /// Severity
  ///
  /// In en, this message translates to:
  /// **'Severity'**
  String get hmSeverity;

  /// Report Incidents page bar title
  ///
  /// In en, this message translates to:
  /// **'Report Incidents'**
  String get riBarTitle;

  /// Incident Type
  ///
  /// In en, this message translates to:
  /// **'Incident Type'**
  String get riIncidentType;

  /// Flood
  ///
  /// In en, this message translates to:
  /// **'Flood'**
  String get riFlood;

  /// Earthquake
  ///
  /// In en, this message translates to:
  /// **'Earthquake'**
  String get riEarthquake;

  /// Landslide
  ///
  /// In en, this message translates to:
  /// **'Landslide'**
  String get riLandslide;

  /// Storm
  ///
  /// In en, this message translates to:
  /// **'Storm'**
  String get riStorm;

  /// Other
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get riOther;

  /// Current Location
  ///
  /// In en, this message translates to:
  /// **'Current Location'**
  String get riCurrentLocation;

  /// Get Current Location
  ///
  /// In en, this message translates to:
  /// **'Get Current Location'**
  String get riGetCurrentLocation;

  /// No Location Found
  ///
  /// In en, this message translates to:
  /// **'No Location Found'**
  String get riNoLocation;

  /// Incident Title
  ///
  /// In en, this message translates to:
  /// **'Incident Title'**
  String get riIncidentTitle;

  /// Prompt of incident title
  ///
  /// In en, this message translates to:
  /// **'Brief title of the incident'**
  String get riIncidentTitlePrompt;

  /// Incident Description
  ///
  /// In en, this message translates to:
  /// **'Incident Description'**
  String get riIncidentDescription;

  /// Prompt of incident description
  ///
  /// In en, this message translates to:
  /// **'Detailed description of what happened'**
  String get riIncidentDescriptionPrompt;

  /// Upload Evidence
  ///
  /// In en, this message translates to:
  /// **'Upload Evidence (Images)'**
  String get riUploadEvidence;

  /// Take Photo
  ///
  /// In en, this message translates to:
  /// **'Take Photo'**
  String get riTakePhoto;

  /// From Gallery
  ///
  /// In en, this message translates to:
  /// **'From Gallery'**
  String get riFromGallery;

  /// Image added and count message
  ///
  /// In en, this message translates to:
  /// **'Image added. Total images'**
  String get riImageAddedTotal;

  /// Failed to pick image
  ///
  /// In en, this message translates to:
  /// **'Failed to pick image'**
  String get riImagePickFailed;

  /// Camera error
  ///
  /// In en, this message translates to:
  /// **'Camera error'**
  String get riCameraError;

  /// Location permissions denied
  ///
  /// In en, this message translates to:
  /// **'Location permissions are denied'**
  String get riLocationDenied;

  /// Location permissions permanently denied
  ///
  /// In en, this message translates to:
  /// **'Location permissions are permanently denied'**
  String get riLocationPermDenied;

  /// Failed to get location
  ///
  /// In en, this message translates to:
  /// **'Failed to get location'**
  String get riGetLocationFailed;

  /// Fill all required fields failure message
  ///
  /// In en, this message translates to:
  /// **'Please fill out all required fields'**
  String get riFillAllFieldsMsg;

  /// Get your current location failure message
  ///
  /// In en, this message translates to:
  /// **'Please get your current location'**
  String get riGetCurrentLocationMsg;

  /// Select an incident type failure message
  ///
  /// In en, this message translates to:
  /// **'Please select an incident type'**
  String get riSelectIncidentTypeMsg;

  /// Specify the incident type failure message
  ///
  /// In en, this message translates to:
  /// **'Please specify the incident type'**
  String get riSpecifyIncidentTypeMsg;

  /// Upload at least one image failure message
  ///
  /// In en, this message translates to:
  /// **'Please upload at least one image'**
  String get riUploadMin1ImageMsg;

  /// Incident reported successfully
  ///
  /// In en, this message translates to:
  /// **'Incident reported successfully'**
  String get riReportSubmittedSuccess;

  /// Failed to submit report
  ///
  /// In en, this message translates to:
  /// **'Failed to submit report'**
  String get riSubmitFailed;

  /// Getting location loading text
  ///
  /// In en, this message translates to:
  /// **'Getting location'**
  String get riGetLocationLoading;

  /// Submit Report button text
  ///
  /// In en, this message translates to:
  /// **'SUBMIT REPORT'**
  String get riSubmitReportBtnText;

  /// False Report Warning
  ///
  /// In en, this message translates to:
  /// **'False reports may result in penalties'**
  String get riFalseReportWarning;

  /// Error taking photo
  ///
  /// In en, this message translates to:
  /// **'Error taking photo'**
  String get riPhotoTakingErr;

  /// Recent Incidents page bar title
  ///
  /// In en, this message translates to:
  /// **'Recent Incidents'**
  String get reiBarTitle;

  /// Failed to load incidents
  ///
  /// In en, this message translates to:
  /// **'Failed to load incidents'**
  String get reiLoadIncidentsFailed;

  /// No incidents reported text
  ///
  /// In en, this message translates to:
  /// **'No incidents reported yet'**
  String get reiPageEmpty;

  /// <number> user(s) verified this report
  ///
  /// In en, this message translates to:
  /// **' user(s) verified this report'**
  String get reiUsersVerifiedIncident;

  /// Incident Details page bar title
  ///
  /// In en, this message translates to:
  /// **'Incident Details'**
  String get idBarTitle;

  /// Open map failed message
  ///
  /// In en, this message translates to:
  /// **'Could not open map'**
  String get idOpenMapFailed;

  /// verification
  ///
  /// In en, this message translates to:
  /// **'verification'**
  String get idVerification;

  /// Pending verification
  ///
  /// In en, this message translates to:
  /// **'Pending verification'**
  String get idPendingVerification;

  /// Incident Image
  ///
  /// In en, this message translates to:
  /// **'Incident Image'**
  String get idIncidentImage;

  /// Location
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get idLocation;

  /// Date Reported
  ///
  /// In en, this message translates to:
  /// **'Date Reported'**
  String get idDateReported;

  /// Type
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get idType;

  /// Description
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get idDescription;

  /// Location Map
  ///
  /// In en, this message translates to:
  /// **'Location Map'**
  String get idLocationMap;

  /// Open in Maps
  ///
  /// In en, this message translates to:
  /// **'Open in Maps'**
  String get idOpenInMaps;

  /// Mark as Unverified
  ///
  /// In en, this message translates to:
  /// **'Mark as Unverified'**
  String get idMarkUnverified;

  /// Mark as Verified
  ///
  /// In en, this message translates to:
  /// **'Mark as Verified'**
  String get idMarkVerified;

  /// Error updating status
  ///
  /// In en, this message translates to:
  /// **'Error updating status'**
  String get idUpdatingStatusError;

  /// Delete Incident
  ///
  /// In en, this message translates to:
  /// **'Delete Incident'**
  String get idDeleteIncident;

  /// Confirmation message when deleting a incident report
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this incident report'**
  String get idDeleteIncidentConfirmation;

  /// Incident deleted successfully
  ///
  /// In en, this message translates to:
  /// **'Incident deleted successfully'**
  String get idDeleteIncidentSuccess;

  /// Error deleting incident
  ///
  /// In en, this message translates to:
  /// **'Error deleting incident'**
  String get idDeleteIncidentError;

  /// Recent Reports page bar title
  ///
  /// In en, this message translates to:
  /// **'Recent Reports'**
  String get rrBarTitle;

  /// Profile page bar title
  ///
  /// In en, this message translates to:
  /// **'My Profile'**
  String get profileBarTitle;

  /// Email label
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get profileEmail;

  /// Phone label
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get profilePhone;

  /// My Reports
  ///
  /// In en, this message translates to:
  /// **'My Reports'**
  String get profileMyReports;

  /// Profile page upload image note
  ///
  /// In en, this message translates to:
  /// **'For best results, upload a clear image in JPG or PNG format, not exceeding 5MB in size.'**
  String get profileUploadImageNote;

  /// Language page bar title
  ///
  /// In en, this message translates to:
  /// **'Select language'**
  String get languagePageBarTitle;

  /// Language page header
  ///
  /// In en, this message translates to:
  /// **'Choose your preferred language'**
  String get languagePageHeading;
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
      <String>['en', 'ms', 'ta', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ms':
      return AppLocalizationsMs();
    case 'ta':
      return AppLocalizationsTa();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
