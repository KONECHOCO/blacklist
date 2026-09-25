/// Build-time configuration (Codemagic passes these with --dart-define).
const apiBase = String.fromEnvironment('API_BASE', defaultValue: 'https://blacklist.ikonetsolutions.com');

const unityGameIdIOS = String.fromEnvironment('UNITY_GAME_ID_IOS');
const unityGameIdAndroid = String.fromEnvironment('UNITY_GAME_ID_ANDROID');
const admobBannerIOS = String.fromEnvironment('ADMOB_BANNER_IOS');
const admobBannerAndroid = String.fromEnvironment('ADMOB_BANNER_ANDROID');

/// Store screenshots: no ads, no store calls, demo data.
const screenshotMode = bool.fromEnvironment('SCREENSHOT_MODE');

const removeAdsProductId = 'com.konechoco.blacklist.removeads';
const privacyUrl = 'https://konechoco.github.io/blacklist/privacy-policy.html';
const supportUrl = 'https://konechoco.github.io/blacklist/support.html';
const removalUrl = '$apiBase/remove';
