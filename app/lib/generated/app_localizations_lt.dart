// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Lithuanian (`lt`).
class AppLocalizationsLt extends AppLocalizations {
  AppLocalizationsLt([String locale = 'lt']) : super(locale);

  @override
  String get appTitle => 'Finally Done';

  @override
  String get settings => 'Nustatymai';

  @override
  String get home => 'Pagrindinis';

  @override
  String get missionControl => 'Misijos valdymas';

  @override
  String get tasks => 'Užduotys';

  @override
  String get profile => 'Profilis';

  @override
  String get name => 'Vardas';

  @override
  String get speechRecognition => 'Kalbos atpažinimas';

  @override
  String get engine => 'Variklis';

  @override
  String get autoIosGemini => 'Automatinis (iOS + Gemini)';

  @override
  String get iosNative => 'iOS natūralus';

  @override
  String get geminiPro => 'Gemini Pro';

  @override
  String get confidenceThreshold => 'Pasitikėjimo slenkstis';

  @override
  String get confidenceThresholdDescription =>
      'Užduotys žemiau šio slenksčio reikalaus rankinio peržiūrėjimo.';

  @override
  String get preferences => 'Nustatymai';

  @override
  String get hapticFeedback => 'Haptinis atsiliepimas';

  @override
  String get soundEffects => 'Garso efektai';

  @override
  String get connectedServices => 'Prijungtos paslaugos';

  @override
  String get googleAccount => 'Google paskyra';

  @override
  String get connectToGoogle =>
      'Prisijunkite, kad pasiektumėte Užduotis, Kalendorių ir Gmail';

  @override
  String get openingGoogleSignIn => 'Atidaromas Google prisijungimas...';

  @override
  String signedInAs(String email) {
    return 'Prisijungęs kaip: $email';
  }

  @override
  String get doYouWantToSignOut => 'Ar norite atsijungti?';

  @override
  String get cancel => 'Atšaukti';

  @override
  String get signOut => 'Atsijungti';

  @override
  String get signedOutFromGoogle => 'Atsijungta nuo Google';

  @override
  String connectedAs(String email) {
    return 'Prisijungta kaip: $email';
  }

  @override
  String get googleSignInFailed => 'Google prisijungimas nepavyko';

  @override
  String get googleSignInNotConfigured =>
      'Google prisijungimas nėra tinkamai sukonfigūruotas. Susisiekite su palaikymu arba patikrinkite savo konfigūraciją.';

  @override
  String get ok => 'Gerai';

  @override
  String error(String message) {
    return 'Klaida: $message';
  }

  @override
  String get pleaseConnectToGoogleFirst =>
      'Pirmiausia prisijunkite prie Google';

  @override
  String disconnectService(String service) {
    return 'Atsijungti nuo $service?';
  }

  @override
  String disconnectServiceConfirmation(String service) {
    return 'Ar tikrai norite atsijungti nuo $service?';
  }

  @override
  String get disconnect => 'Atsijungti';

  @override
  String serviceDisconnected(String service) {
    return '$service atsijungta';
  }

  @override
  String serviceIntegration(String service) {
    return '$service integracija';
  }

  @override
  String connectToServiceDescription(String service) {
    return 'Prisijunkite prie $service, kad sinchronizuotumėte savo duomenis.';
  }

  @override
  String get connect => 'Prisijungti';

  @override
  String get done => 'Baigta';

  @override
  String get invalidCommandDeleted => 'Netinkama užduotis (ištrinta)';

  @override
  String get goToSettings => 'Eiti į nustatymus';

  @override
  String get comingSoon => 'Netrukus';

  @override
  String get googleTasks => 'Google užduotys';

  @override
  String get loadingTasks => 'Kraunamos užduotys...';

  @override
  String get processing => 'Apdorojama';

  @override
  String get completed => 'Baigta';

  @override
  String get review => 'Peržiūra';

  @override
  String get taskCompleted => 'Užduotis baigta!';

  @override
  String errorCompletingTask(String error) {
    return 'Klaida baigiant užduotį: $error';
  }

  @override
  String get tryAgain => 'Bandyti dar kartą';

  @override
  String get refresh => 'Atnaujinti';

  @override
  String get audioFileNotFound => 'Garso failas nerastas';

  @override
  String get playingAudio => 'Groja garso failas...';

  @override
  String get audioPlaybackStarted => 'Garso atkūrimas pradėtas';

  @override
  String errorPlayingAudio(String error) {
    return 'Klaida grojant garso failą: $error';
  }

  @override
  String get commandDeletedSuccessfully => 'Komanda sėkmingai ištrinta';

  @override
  String errorDeletingCommand(String error) {
    return 'Klaida trinant komandą: $error';
  }

  @override
  String photoCounter(int current, int total) {
    return 'Nuotrauka $current iš $total';
  }

  @override
  String get failedToLoadImage => 'Nepavyko įkelti nuotraukos';

  @override
  String confidencePercentage(int percentage) {
    return '$percentage%';
  }

  @override
  String errorGeneric(String error) {
    return 'Klaida: $error';
  }

  @override
  String get appDescription =>
      'Dirbtinio intelekto pagrindu veikianti asmeninio organizavimo programa, kuri padeda fiksuoti ir organizuoti užduotis, įvykius ir užrašus per balso komandas.';

  @override
  String get helpAndSupport => 'Pagalba ir palaikymas';

  @override
  String get helpAndSupportMessage =>
      'Pagalbai ir palaikymui susisiekite su mumis el. paštu support@finallydone.app';

  @override
  String get close => 'Uždaryti';

  @override
  String get customize => 'Tinkinti';

  @override
  String get iconWillBeSetAsAppIcon =>
      'Piktograma bus nustatyta kaip programos piktograma';

  @override
  String get customizationOptionsComingSoon => 'Tinkinimo parinktys netrukus';

  @override
  String get chooseColorVariant =>
      '1. Pasirinkite pageidaujamą spalvos variantą';

  @override
  String get iconScalesAutomatically =>
      '2. Piktograma automatiškai keičia dydį';

  @override
  String get worksOnAllPlatforms => '3. Puikiai veikia iOS ir Android';

  @override
  String get noExternalDependencies => '4. Nereikia išorinių priklausomybių';

  @override
  String get canBeCustomizedFurther =>
      '5. Galima toliau tinkinti pagal poreikius';

  @override
  String get blue => 'Mėlyna';

  @override
  String get green => 'Žalia';

  @override
  String get purple => 'Violetinė';

  @override
  String get orange => 'Oranžinė';

  @override
  String get size32px => '32px';

  @override
  String get size64px => '64px';

  @override
  String get size128px => '128px';

  @override
  String get size256px => '256px';

  @override
  String get enterYourName => 'Įveskite savo vardą';

  @override
  String get chooseSpeechEngine =>
      'Pasirinkite pageidaujamą kalbos atpažinimo variklį';

  @override
  String get hapticFeedbackDescription => 'Vibruoti paspaudus mygtukus';

  @override
  String get soundEffectsDescription => 'Grojti sėkmės/klaidos garsus';
}
