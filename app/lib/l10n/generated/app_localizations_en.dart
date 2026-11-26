// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'AETHERA';

  @override
  String get welcomeTitle => 'Grow smarter. Farm better.';

  @override
  String get welcomeSubtitle => 'Your intelligent agricultural companion.';

  @override
  String get dashboardTitle => 'Your farm at a glance';

  @override
  String get dashboardSubtitle =>
      'Everything you need to grow with confidence.';

  @override
  String get greeting => 'Welcome back!';

  @override
  String get language => 'Language';

  @override
  String get theme => 'Appearance';

  @override
  String get settings => 'Settings';

  @override
  String get light => 'Light';

  @override
  String get dark => 'Dark';

  @override
  String get system => 'System';

  @override
  String get english => 'English';

  @override
  String get french => 'French';

  @override
  String get arabic => 'Arabic';

  @override
  String get assistant => 'AI Assistant';

  @override
  String get diagnosis => 'Crop Diagnosis';

  @override
  String get irrigation => 'Smart Irrigation';

  @override
  String get community => 'Community';

  @override
  String get profile => 'My Profile';

  @override
  String get weather => 'Weather';

  @override
  String get soilMoisture => 'Soil Moisture';

  @override
  String get preferences => 'Application Preferences';

  @override
  String get chooseLanguage => 'Choose your language';

  @override
  String get chooseTheme => 'Choose your appearance';

  @override
  String get backToHome => 'Back to home';

  @override
  String get home => 'Home';

  @override
  String get farms => 'Farms';

  @override
  String get messages => 'Messages';

  @override
  String get collapseSidebar => 'Collapse sidebar';

  @override
  String get expandSidebar => 'Expand sidebar';

  @override
  String get openNavigation => 'Open navigation';

  @override
  String get account => 'Account';

  @override
  String get managePersonalDetails => 'Manage your personal details';

  @override
  String get manageAccountPreferences =>
      'Manage your AETHERA account and preferences.';

  @override
  String get farmerAccount => 'Farmer account';

  @override
  String get personalInformation => 'Personal information';

  @override
  String get personalInformationMessage =>
      'Your farmer account information will appear here.';

  @override
  String get helpSupport => 'Help and support';

  @override
  String get helpSupportMessage =>
      'For assistance with AETHERA, please contact our support team.';

  @override
  String get logout => 'Log out';

  @override
  String get logoutQuestion => 'Log out?';

  @override
  String get logoutConfirmation => 'Are you sure you want to log out?';

  @override
  String get close => 'Close';

  @override
  String get cancel => 'Cancel';

  @override
  String get addFarm => 'Add a farm';

  @override
  String get farmName => 'Farm name *';

  @override
  String get location => 'Location *';

  @override
  String get areaHectares => 'Area in hectares';

  @override
  String get soilType => 'Soil type';

  @override
  String get irrigationType => 'Irrigation type';

  @override
  String get saveFarm => 'Save farm';

  @override
  String get farmAdded => 'Farm added successfully!';

  @override
  String get farmLoadError =>
      'Could not load farms. Please check your connection.';

  @override
  String farmSaveError(String error) {
    return 'Could not save farm: $error';
  }

  @override
  String get noFarms => 'No farms added yet';

  @override
  String get addFirstFarm => 'Tap Add farm to register your first farm.';

  @override
  String get yourFarms => 'Your farms';

  @override
  String get manageFarms => 'Manage your land and agricultural activities.';

  @override
  String get tryAgain => 'Try again';

  @override
  String get enterTwoChars => 'Please enter at least 2 characters.';

  @override
  String get enterPositiveNumber => 'Enter a number greater than zero.';

  @override
  String get notSpecified => 'Not specified';

  @override
  String get area => 'Area';

  @override
  String get save => 'Save';

  @override
  String get chooseFarm => 'Choose a farm';

  @override
  String get locationExample => 'e.g. Sousse, Tunisia';

  @override
  String get areaExample => 'e.g. 5.5';

  @override
  String get soilExample => 'e.g. Clay, sandy, loamy';

  @override
  String get irrigationExample => 'e.g. Drip, sprinkler';

  @override
  String get hectares => 'hectares';

  @override
  String get fieldIntelligence => 'AETHERA FIELD INTELLIGENCE';

  @override
  String get fieldTagline => 'Make every field decision count.';

  @override
  String get fieldDescription =>
      'Ask about irrigation, crop symptoms and farm care.';

  @override
  String get exploreTools => 'Explore your tools';

  @override
  String get talkToAethera => 'Talk to AETHERA';

  @override
  String get voiceAssistantDescription =>
      'Press and hold the microphone to speak in Tunisian Derja.';

  @override
  String get voiceTitle => 'Agricultural assistant';

  @override
  String get voiceListening => 'Listening… speak now';

  @override
  String get voiceSpeaking => 'AETHERA is responding…';

  @override
  String get voiceWelcome => 'Welcome to AETHERA';

  @override
  String get voiceListeningHint => 'Release the microphone when you finish.';

  @override
  String get voiceInstruction => 'Press and hold the microphone to speak.';

  @override
  String get voicePressHold => 'PRESS & HOLD';

  @override
  String get voiceInputHint => 'Or type your question here…';

  @override
  String get voiceAsk => 'Ask AETHERA';

  @override
  String get voiceQuestion => 'Your question';

  @override
  String get voiceNoQuestion => 'No question recorded yet.';

  @override
  String get voiceAnswer => 'Answer';

  @override
  String get voiceStopAudio => 'Stop audio';

  @override
  String get voiceListenAnswer => 'Listen to answer';

  @override
  String get voiceDisclaimer =>
      'These suggestions are preliminary. For unclear diseases or pests, consult an agricultural expert before treatment.';

  @override
  String get voiceSpeechUnavailable =>
      'Speech recognition is unavailable. You can type your question instead.';

  @override
  String get voiceMicError => 'The microphone could not be started.';

  @override
  String get voiceAudioError =>
      'Audio playback failed. You can read the answer instead.';

  @override
  String get voiceAnswerWater =>
      'Check soil moisture before watering. Avoid overwatering and consider the crop, soil type and weather.';

  @override
  String get voiceAnswerYellow =>
      'Yellow leaves can result from too much or too little water, or nutrient deficiency. Check soil moisture and whether older or newer leaves are affected. A precise diagnosis may require a photo and expert review.';

  @override
  String get voiceAnswerPest =>
      'If you suspect a disease or insect, photograph the plant and affected leaves. Do not apply pesticides before identifying the problem. Ask an agricultural expert to review the image.';

  @override
  String get voiceAnswerTomato =>
      'For tomatoes, monitor soil moisture and avoid overwatering. Check leaves and fruit for disease symptoms and consult an expert if symptoms appear.';

  @override
  String get voiceAnswerOlive =>
      'For olive trees, monitor leaves, soil and weather. Water needs depend on tree age, soil type and growth stage.';

  @override
  String get voiceAnswerGeneral =>
      'I received your question. I can provide general guidance about irrigation, crops and common symptoms. Personalized AI advice requires connecting an AI service. You can also contact an agricultural expert through the community.';

  @override
  String get weatherFarmTitle => 'Weather for your farm';

  @override
  String get weatherSearchHint => 'Search a town or region';

  @override
  String get weatherChooseLocation => 'Choose your farm location';

  @override
  String get weatherSearchDescription =>
      'Search for the town or region where your farm is located to see its live forecast.';

  @override
  String get weatherFeelsLike => 'Feels like';

  @override
  String get weatherNextHours => 'Next hours';

  @override
  String get weatherOutlook => '7-day outlook';

  @override
  String get weatherChanges => 'Notable changes';

  @override
  String get weatherNoChanges =>
      'No notable changes detected in the next 24 hours.';

  @override
  String get weatherSource =>
      'Weather data: Open-Meteo. Forecasts are estimates, not guarantees.';

  @override
  String get weatherRain => 'Rain';

  @override
  String get weatherHumidity => 'Humidity';

  @override
  String get weatherWind => 'Wind';

  @override
  String get weatherRainNow => 'Rain now';

  @override
  String get weatherWindDirection => 'Wind direction';

  @override
  String get weatherSunrise => 'Sunrise';

  @override
  String get weatherSunset => 'Sunset';

  @override
  String get weatherUv => 'UV max today';

  @override
  String get weatherSelectedLocation => 'Selected location';

  @override
  String get weatherLoadError =>
      'Weather could not be loaded. Check the API connection and location.';

  @override
  String get weatherRainProbability => 'rain';

  @override
  String get weatherOutlookSubtitle =>
      'Forecasts and changing field conditions.';

  @override
  String get diagnosisSubtitle => 'Capture a crop photo for assessment.';

  @override
  String get irrigationSubtitle => 'Review irrigation controls and schedules.';

  @override
  String get authGoogleError => 'Google sign-in failed. Please try again.';

  @override
  String get authAcceptTerms => 'Please accept the terms and privacy policy.';

  @override
  String get authEmailVerified => 'Email verified! Please sign in.';

  @override
  String get authCodeSent => 'Verification code sent to your email.';

  @override
  String get authNewCodeSent => 'A new code has been sent.';

  @override
  String get communityRefresh => 'Refresh feed';

  @override
  String get communitySearch => 'Search by name...';

  @override
  String get communityAsk => 'Ask';

  @override
  String get communityRemovePhoto => 'Remove photo';

  @override
  String get communityAddPhoto => 'Add photo';

  @override
  String get communityAccept => 'Accept';

  @override
  String get communityDecline => 'Decline';

  @override
  String get communityRetry => 'Retry';

  @override
  String get communityConnectionSent => 'Connection request sent to';

  @override
  String get communityImageError => 'Could not select image';

  @override
  String get communityPostTooLong => 'Posts cannot exceed 5000 characters.';

  @override
  String get communityPostPublished => 'Your post was published.';

  @override
  String get messageTooLong => 'Messages cannot exceed 5000 characters.';

  @override
  String get messageHint => 'Write a message...';

  @override
  String get messageRetry => 'Try again';

  @override
  String get expertQueueTitle => 'Diagnosis review queue';

  @override
  String get expertPhotoUnavailable => 'Photo unavailable';

  @override
  String get expertRefresh => 'Refresh queue';

  @override
  String get expertCancel => 'Cancel';

  @override
  String get expertReject => 'Reject';

  @override
  String get expertValidate => 'Validate';

  @override
  String get expertLogoutQuestion => 'Log out?';

  @override
  String get irrigationRetry => 'Try again';

  @override
  String get irrigationRefresh => 'Refresh devices';

  @override
  String get irrigationTitle => 'Smart Irrigation';

  @override
  String get irrigationLoadFarmsError => 'Could not load your farms.';

  @override
  String get irrigationNoFarms => 'No farms yet';

  @override
  String get irrigationAddFarmFirst =>
      'Add a farm first to view its irrigation devices.';

  @override
  String get irrigationSelectFarm => 'Select farm';

  @override
  String get irrigationConnectedDevices => 'Connected devices';

  @override
  String get irrigationLoadDevicesError => 'Could not load irrigation devices.';

  @override
  String get irrigationNoDevices => 'No devices connected';

  @override
  String get irrigationNoDevicesDescription =>
      'There are no registered devices for this farm yet.';

  @override
  String get irrigationInfo =>
      'Device readings are shown when available. Watering controls and scheduling are not currently supported by the connected API.';

  @override
  String get irrigationMonitorFarm => 'Monitor your farm';

  @override
  String get irrigationMonitorDescription =>
      'View connected irrigation devices and their latest readings.';

  @override
  String get irrigationDevice => 'Irrigation device';

  @override
  String get irrigationRegistered => 'Registered';

  @override
  String get irrigationDeviceIdUnavailable => 'Device ID unavailable';

  @override
  String get irrigationLatestReading => 'Latest reading';

  @override
  String get irrigationDeviceIdUnreadable =>
      'This device does not have a readable ID.';

  @override
  String get irrigationReadingUnavailable =>
      'Latest reading is currently unavailable.';

  @override
  String get irrigationNoReadings =>
      'No readings have been recorded for this device yet.';

  @override
  String get dashboardOperations => 'Farm operations';

  @override
  String get dashboardDevices => 'Registered devices';

  @override
  String get dashboardViewIrrigation => 'View irrigation';

  @override
  String get dashboardNoDevices => 'No devices registered for this farm.';

  @override
  String get dashboardDeviceLoadError => 'Could not load device status.';

  @override
  String get dashboardActive => 'Active';

  @override
  String get dashboardInactive => 'Inactive';

  @override
  String get dashboardLatestMoisture => 'Latest soil moisture';

  @override
  String get dashboardNoReading => 'No sensor reading yet';

  @override
  String dashboardReadingTime(String time) {
    return 'Recorded $time';
  }

  @override
  String get dashboardSimulated => 'Simulated reading';

  @override
  String get dashboardWeatherAction => 'Open weather forecast';

  @override
  String get dashboardFarmProfile => 'Farm profile';

  @override
  String get dashboardAlerts => 'Farm alerts';

  @override
  String get dashboardNoAlerts =>
      'No active alerts. Sensor conditions will appear here when thresholds are reached.';

  @override
  String get dashboardAcknowledge => 'Acknowledge';

  @override
  String get dashboardOnline => 'Online';

  @override
  String get dashboardStale => 'Stale';

  @override
  String get dashboardUnknown => 'Unknown';

  @override
  String get dashboardDisabled => 'Disabled';

  @override
  String get weatherLocationSaved => 'Farm location saved.';
}
