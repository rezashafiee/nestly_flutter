# CI/CD mit Jenkins und Fastlane

Stand: 2026-06-02

Dieses Projekt hat jetzt eine Jenkins + Fastlane Grundkonfiguration:

- `Jenkinsfile`: Pipeline fuer Analyse, Tests, Debug APK, Android Release AAB, Google Play Upload und optional TestFlight.
- `Gemfile`: pinnt Fastlane ueber Bundler.
- `fastlane/Fastfile`: Android- und iOS-Lanes.
- `fastlane/Appfile`: Package-/Bundle-ID Defaults.
- `ci/jenkins/*`: Docker-Compose Setup fuer einen Jenkins Controller.
- `android/key.properties.example`: lokale Android Signing Vorlage.

## Empfehlung

Nutze Jenkins als Orchestrator und Fastlane als Delivery-Schicht. Das passt gut, wenn schon Jenkins-Erfahrung da ist, und Fastlane bleibt fuer Google Play / TestFlight sehr praktisch.

Wichtig: iOS-Builds brauchen macOS + Xcode. Eine normale Linux-VM kann Android bauen und Jenkins hosten, aber keine IPA fuer TestFlight erzeugen. Dafuer brauchst du einen Mac-Agent mit Jenkins-Label `macos`.

## Aktueller Projektstatus

Die App nutzt aktuell noch Beispiel-IDs:

- Android `applicationId`: `com.example.nestly`
- iOS Bundle ID: `com.example.nestly`

Vor echter Store-Auslieferung solltest du diese IDs auf deine eigene Domain/App-ID umstellen, z. B. `com.deinefirma.nestly`. Danach muessen Google Play App, Apple Bundle ID, Provisioning Profiles und Fastlane/Jenkins-Variablen dieselbe ID verwenden.

## Mindestanforderungen

Offizielle Jenkins-Docker-Doku nennt fuer Jenkins selbst sehr kleine Mindestwerte, empfiehlt aber fuer kleine Teams eher `4 GB+ RAM` und `50 GB+ Disk`. Fuer Flutter/Android ist praktisch mehr sinnvoll:

| Rolle | Empfehlung |
| --- | --- |
| Jenkins Controller only | 2 vCPU, 4 GB RAM, 50 GB Disk |
| Jenkins Controller + Android Builds auf derselben VM | 4 vCPU, 8-16 GB RAM, 100 GB Disk |
| Android Build Agent | 4 vCPU, 8-16 GB RAM, 100 GB Disk |
| iOS Build Agent | Mac mini / Mac VM, Xcode, Flutter, Ruby, 16 GB RAM empfohlen |

## Jenkins per Docker auf Ubuntu VM installieren

Ubuntu 24.04 LTS ist eine gute Wahl. Docker unterstuetzt laut offizieller Docker-Doku u. a. Ubuntu 24.04 LTS und 22.04 LTS.

```bash
sudo apt-get update
sudo apt-get install -y ca-certificates curl git

sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo usermod -aG docker "$USER"
newgrp docker

docker --version
docker compose version
```

Jenkins starten:

```bash
git clone <dein-repo-url> nestly
cd nestly
docker compose -f ci/jenkins/docker-compose.yml up -d --build
docker compose -f ci/jenkins/docker-compose.yml logs -f jenkins
```

Initiales Admin-Passwort holen:

```bash
docker compose -f ci/jenkins/docker-compose.yml exec jenkins \
  cat /var/jenkins_home/secrets/initialAdminPassword
```

Dann im Browser `http://<vm-ip>:8080` oeffnen, Jenkins entsperren und Admin-User anlegen.

## Jenkins Agents und Labels

Das `Jenkinsfile` erwartet diese Labels:

- `flutter-android`: Linux-Agent mit Flutter, Android SDK, Java 17+, Ruby und Bundler.
- `macos`: macOS-Agent mit Xcode, Flutter, Ruby und Bundler.

Fuer einen schnellen Start kannst du den Controller-Knoten als `flutter-android` labeln, besser ist aber ein separater Agent. iOS muss auf einem Mac laufen.

Android-Agent Tools:

```bash
flutter --version
flutter doctor -v
java -version
ruby --version
gem install bundler
```

macOS-Agent Tools:

```bash
xcode-select --install
sudo xcodebuild -license accept
flutter doctor -v
gem install bundler
```

## Jenkins Plugins

Das Docker-Image installiert die wichtigsten Plugins aus `ci/jenkins/plugins.txt`:

- Pipeline
- Git
- Credentials Binding
- Timestamper
- Pipeline Stage View
- SSH Build Agents
- Workspace Cleanup

Wenn Jenkins schon existiert, installiere diese Plugins manuell ueber `Manage Jenkins > Plugins`.

## Jenkins Job anlegen

Empfohlen: Multibranch Pipeline.

1. `New Item`
2. `Multibranch Pipeline`
3. Git Repository URL eintragen
4. Credentials fuer Git setzen, falls privat
5. Script Path: `Jenkinsfile`
6. Scan ausfuehren

Die Pipeline hat Parameter:

- `APP_VERSION_NAME`: sichtbare Version, z. B. `1.0.0`
- `APP_BUILD_NUMBER`: interner Build. Leer = Jenkins `BUILD_NUMBER`
- `BUILD_ANDROID_RELEASE`: signiertes Android AAB bauen
- `UPLOAD_ANDROID_PLAY`: Android AAB zu Google Play hochladen
- `ANDROID_PLAY_TRACK`: `internal`, `alpha`, `beta`, `production`
- `ANDROID_RELEASE_STATUS`: `completed`, `draft`, `inProgress`, `halted`
- `UPLOAD_IOS_TESTFLIGHT`: iOS IPA bauen und zu TestFlight hochladen
- `IOS_EXPORT_METHOD`: `app-store`, `ad-hoc`, `development`, `enterprise`

## Benoetigte Jenkins Credentials

Lege diese unter `Manage Jenkins > Credentials` an.

| Credential ID | Typ | Inhalt |
| --- | --- | --- |
| `android-upload-keystore` | Secret file | Android Upload Keystore, z. B. `.jks` |
| `android-keystore-password` | Secret text | Keystore Passwort |
| `android-key-alias` | Secret text | Key Alias, z. B. `upload` |
| `android-key-password` | Secret text | Key Passwort |
| `google-play-service-account-json` | Secret file | Google Play Service Account JSON |
| `app-store-connect-api-key-p8` | Secret file | App Store Connect API Key `.p8` |
| `app-store-connect-key-id` | Secret text | App Store Connect Key ID |
| `app-store-connect-issuer-id` | Secret text | App Store Connect Issuer ID |

Optional fuer Fastlane Match:

| Credential | Typ | Zweck |
| --- | --- | --- |
| `match-password` | Secret text | Passwort fuer verschluesseltes Signing Repo |
| Git SSH key | SSH username with private key | Zugriff auf Match Repo |

## Android Signing vorbereiten

Upload-Key lokal erzeugen:

```bash
keytool -genkeypair -v \
  -keystore android-upload-keystore.jks \
  -storetype JKS \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000 \
  -alias upload
```

Lokal kannst du `android/key.properties` aus der Vorlage erstellen:

```bash
cp android/key.properties.example android/key.properties
```

Diese Datei niemals committen. In Jenkins werden stattdessen die Credentials als Environment-Variablen gesetzt:

- `ANDROID_KEYSTORE_PATH`
- `ANDROID_KEYSTORE_PASSWORD`
- `ANDROID_KEY_ALIAS`
- `ANDROID_KEY_PASSWORD`

## Google Play vorbereiten

Du brauchst:

1. Google Play Developer Account
2. App in der Play Console mit passender Package ID
3. Play App Signing aktiviert
4. Service Account JSON fuer die Google Play Developer API
5. Berechtigungen fuer den Service Account auf die App, mindestens fuer Releases auf dem gewuenschten Track

Fastlane kann den Key testen:

```bash
export SUPPLY_JSON_KEY=/absolute/path/to/google-play-service-account.json
bundle exec fastlane android validate_play_key
```

Upload auf Internal Track:

```bash
export APP_VERSION_NAME=1.0.0
export APP_BUILD_NUMBER=1
export ANDROID_PACKAGE_NAME=com.example.nestly
export ANDROID_PLAY_TRACK=internal
export SUPPLY_JSON_KEY=/absolute/path/to/google-play-service-account.json
export ANDROID_KEYSTORE_PATH=/absolute/path/to/android-upload-keystore.jks
export ANDROID_KEYSTORE_PASSWORD=...
export ANDROID_KEY_ALIAS=upload
export ANDROID_KEY_PASSWORD=...
bundle exec fastlane android upload_play
```

## iOS / TestFlight vorbereiten

Du brauchst:

1. Apple Developer Program Membership
2. App Store Connect App mit passender Bundle ID
3. App Store Connect API Key `.p8`, Key ID und Issuer ID
4. Signing Setup auf dem Mac-Agent:
   - entweder Xcode Automatic Signing mit eingeloggtem Apple Developer Account
   - oder Fastlane Match mit Zertifikaten/Profiles in einem privaten Git Repo

TestFlight Upload:

```bash
export APP_VERSION_NAME=1.0.0
export APP_BUILD_NUMBER=1
export IOS_APP_IDENTIFIER=com.example.nestly
export IOS_EXPORT_METHOD=app-store
export APP_STORE_CONNECT_API_KEY_PATH=/absolute/path/to/AuthKey_ABC123DEFG.p8
export APP_STORE_CONNECT_KEY_ID=ABC123DEFG
export APP_STORE_CONNECT_ISSUER_ID=00000000-0000-0000-0000-000000000000
bundle exec fastlane ios upload_testflight
```

Wenn du Match nutzen willst:

```bash
export MATCH_GIT_URL=git@github.com:deine-org/ios-signing.git
export MATCH_TYPE=appstore
export MATCH_PASSWORD=...
bundle exec fastlane ios build_release
```

## Lokale Fastlane-Kommandos

```bash
bundle install
bundle exec fastlane android ci
bundle exec fastlane android build_debug
bundle exec fastlane android build_release
bundle exec fastlane android upload_play
bundle exec fastlane ios build_release
bundle exec fastlane ios upload_testflight
```

## Aktivierungsreihenfolge

1. App IDs von `com.example.nestly` auf echte IDs aendern.
2. Google Play App und Apple App Store Connect App erstellen.
3. Android Upload Keystore erzeugen und sicher ablegen.
4. Android Jenkins Credentials anlegen.
5. Google Play Service Account JSON erzeugen und als Jenkins Secret File ablegen.
6. Jenkins Controller per Docker starten.
7. Android Agent mit Label `flutter-android` bereitstellen.
8. Pipeline ohne Upload ausfuehren: nur CI/Debug APK.
9. `BUILD_ANDROID_RELEASE=true` testen.
10. `UPLOAD_ANDROID_PLAY=true` zuerst auf Track `internal` testen.
11. Mac-Agent mit Label `macos` einrichten.
12. Apple Signing und App Store Connect API Key einrichten.
13. `UPLOAD_IOS_TESTFLIGHT=true` testen.

## Hinweise und Risiken

- Store-Secrets nie committen. `.gitignore` ignoriert Keystores, `.p8`, `android/key.properties` und Fastlane-Ausgaben.
- Die Pipeline laedt nur hoch, wenn die Upload-Parameter aktiv gesetzt werden.
- Android Release-Builds brechen in Fastlane ab, wenn Signing-Secrets fehlen. Gradle faellt lokal weiterhin auf Debug-Signing zurueck, damit einfache lokale Builds nicht blockieren.
- iOS ist der empfindlichste Teil: Xcode-Version, Signing, Team ID und Provisioning Profile muessen zusammenpassen.
- Der aktuelle Android Build zeigt eine nicht-blockierende Flutter-Warnung, dass `image_picker_android` noch Kotlin Gradle Plugin selbst anwendet. Das ist aktuell kein Fehler, sollte aber bei zukuenftigen Flutter-Upgrades beobachtet werden.

## Quellen

- Jenkins Docker Installation: https://www.jenkins.io/doc/book/installing/docker/
- Jenkins Pipeline mit Docker: https://www.jenkins.io/doc/book/pipeline/docker/
- Docker Engine auf Ubuntu: https://docs.docker.com/engine/install/ubuntu/
- Flutter Android Deployment: https://docs.flutter.dev/deployment/android
- Flutter iOS Deployment: https://docs.flutter.dev/deployment/ios
- Fastlane Android Setup / Supply: https://docs.fastlane.tools/getting-started/android/setup/
- Fastlane `upload_to_play_store`: https://docs.fastlane.tools/actions/upload_to_play_store/
- Fastlane TestFlight / Pilot: https://docs.fastlane.tools/actions/pilot/
- Fastlane Match: https://docs.fastlane.tools/actions/match/
- Apple App Store Connect API Keys: https://developer.apple.com/help/app-store-connect/get-started/app-store-connect-api
