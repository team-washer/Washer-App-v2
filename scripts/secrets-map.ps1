# Shared secret-name <-> file-path mapping used by secrets-push.ps1 / secrets-pull.ps1
# Add a new line here whenever a new secret file needs to be managed.

$SecretMap = [ordered]@{
    "ENV_DEVELOPMENT"               = ".env.development"
    "ENV_PRODUCTION"                = ".env.production"
    "ANDROID_GOOGLE_SERVICES_JSON"  = "android/app/google-services.json"
    "IOS_GOOGLE_SERVICE_INFO_PLIST" = "ios/Runner/GoogleService-Info.plist"
    "ANDROID_UPLOAD_KEYSTORE_JKS"   = "android/upload-keystore.jks"
    "ANDROID_KEY_PROPERTIES"        = "android/key.properties"
}
