def prepareRubyBundle() {
    sh '''
        set -eu
        ruby --version
        gem --version
        bundle config set path vendor/bundle
        bundle install --jobs 4 --retry 3
    '''
}

def withReleaseBuildEnvironment(body) {
    def resolvedBuildNumber = params.APP_BUILD_NUMBER?.trim() ?: env.BUILD_NUMBER
    withEnv([
        "APP_VERSION_NAME=${params.APP_VERSION_NAME}",
        "APP_BUILD_NUMBER=${resolvedBuildNumber}",
        "ANDROID_PLAY_TRACK=${params.ANDROID_PLAY_TRACK}",
        "ANDROID_RELEASE_STATUS=${params.ANDROID_RELEASE_STATUS}",
        "IOS_EXPORT_METHOD=${params.IOS_EXPORT_METHOD}"
    ]) {
        body()
    }
}

pipeline {
    agent none

    options {
        timestamps()
        disableConcurrentBuilds()
        buildDiscarder(logRotator(numToKeepStr: '20', artifactNumToKeepStr: '10'))
    }

    parameters {
        string(name: 'APP_VERSION_NAME', defaultValue: '1.0.0', description: 'Public app version, for example 1.0.0.')
        string(name: 'APP_BUILD_NUMBER', defaultValue: '', description: 'Internal build number. Empty uses Jenkins BUILD_NUMBER.')
        booleanParam(name: 'BUILD_ANDROID_RELEASE', defaultValue: false, description: 'Build a signed Android AAB.')
        booleanParam(name: 'UPLOAD_ANDROID_PLAY', defaultValue: false, description: 'Upload the Android AAB to Google Play.')
        choice(name: 'ANDROID_PLAY_TRACK', choices: ['internal', 'alpha', 'beta', 'production'], description: 'Google Play target track.')
        choice(name: 'ANDROID_RELEASE_STATUS', choices: ['completed', 'draft', 'inProgress', 'halted'], description: 'Google Play release status.')
        booleanParam(name: 'UPLOAD_IOS_TESTFLIGHT', defaultValue: false, description: 'Build iOS IPA on a macOS agent and upload to TestFlight.')
        choice(name: 'IOS_EXPORT_METHOD', choices: ['app-store', 'ad-hoc', 'development', 'enterprise'], description: 'Flutter IPA export method.')
    }

    stages {
        stage('Flutter CI') {
            agent { label 'flutter-android' }
            steps {
                checkout scm
                sh 'flutter --version'
                sh 'flutter pub get'
                sh 'flutter analyze'
                sh 'flutter test'
                sh 'flutter build apk --debug'
            }
            post {
                always {
                    archiveArtifacts artifacts: 'build/app/outputs/flutter-apk/*.apk', allowEmptyArchive: true
                }
            }
        }

        stage('Android Release AAB') {
            agent { label 'flutter-android' }
            when {
                expression { params.BUILD_ANDROID_RELEASE && !params.UPLOAD_ANDROID_PLAY }
            }
            steps {
                checkout scm
                prepareRubyBundle()
                withCredentials([
                    file(credentialsId: 'android-upload-keystore', variable: 'ANDROID_KEYSTORE_PATH'),
                    string(credentialsId: 'android-keystore-password', variable: 'ANDROID_KEYSTORE_PASSWORD'),
                    string(credentialsId: 'android-key-alias', variable: 'ANDROID_KEY_ALIAS'),
                    string(credentialsId: 'android-key-password', variable: 'ANDROID_KEY_PASSWORD')
                ]) {
                    withReleaseBuildEnvironment {
                        sh 'bundle exec fastlane android build_release'
                    }
                }
            }
            post {
                always {
                    archiveArtifacts artifacts: 'build/app/outputs/bundle/release/*.aab', allowEmptyArchive: true
                }
            }
        }

        stage('Android Google Play Upload') {
            agent { label 'flutter-android' }
            when {
                expression { params.UPLOAD_ANDROID_PLAY }
            }
            steps {
                checkout scm
                prepareRubyBundle()
                withCredentials([
                    file(credentialsId: 'android-upload-keystore', variable: 'ANDROID_KEYSTORE_PATH'),
                    string(credentialsId: 'android-keystore-password', variable: 'ANDROID_KEYSTORE_PASSWORD'),
                    string(credentialsId: 'android-key-alias', variable: 'ANDROID_KEY_ALIAS'),
                    string(credentialsId: 'android-key-password', variable: 'ANDROID_KEY_PASSWORD'),
                    file(credentialsId: 'google-play-service-account-json', variable: 'SUPPLY_JSON_KEY')
                ]) {
                    withReleaseBuildEnvironment {
                        sh 'bundle exec fastlane android upload_play'
                    }
                }
            }
            post {
                always {
                    archiveArtifacts artifacts: 'build/app/outputs/bundle/release/*.aab', allowEmptyArchive: true
                }
            }
        }

        stage('iOS TestFlight Upload') {
            agent { label 'macos' }
            when {
                expression { params.UPLOAD_IOS_TESTFLIGHT }
            }
            steps {
                checkout scm
                prepareRubyBundle()
                withCredentials([
                    file(credentialsId: 'app-store-connect-api-key-p8', variable: 'APP_STORE_CONNECT_API_KEY_PATH'),
                    string(credentialsId: 'app-store-connect-key-id', variable: 'APP_STORE_CONNECT_KEY_ID'),
                    string(credentialsId: 'app-store-connect-issuer-id', variable: 'APP_STORE_CONNECT_ISSUER_ID')
                ]) {
                    withReleaseBuildEnvironment {
                        sh 'bundle exec fastlane ios upload_testflight'
                    }
                }
            }
            post {
                always {
                    archiveArtifacts artifacts: 'build/ios/ipa/*.ipa', allowEmptyArchive: true
                }
            }
        }
    }
}
