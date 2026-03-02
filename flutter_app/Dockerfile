# Flutter Docker Image for Building Android APK
FROM ubuntu:22.04

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV ANDROID_SDK_ROOT=/opt/android-sdk
ENV FLUTTER_ROOT=/opt/flutter
ENV PATH="$FLUTTER_ROOT/bin:$ANDROID_SDK_ROOT/cmdline-tools/latest/bin:$ANDROID_SDK_ROOT/platform-tools:$PATH"

# Install dependencies
RUN apt-get update && apt-get install -y \
    curl \
    git \
    unzip \
    xz-utils \
    zip \
    libglu1-mesa \
    openjdk-11-jdk \
    wget \
    && rm -rf /var/lib/apt/lists/*

# Set JAVA_HOME
ENV JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64

# Install Android SDK
RUN mkdir -p $ANDROID_SDK_ROOT/cmdline-tools && \
    cd $ANDROID_SDK_ROOT/cmdline-tools && \
    wget https://dl.google.com/android/repository/commandlinetools-linux-9477386_latest.zip && \
    unzip commandlinetools-linux-9477386_latest.zip && \
    mv cmdline-tools latest && \
    rm commandlinetools-linux-9477386_latest.zip

# Accept Android SDK licenses
RUN yes | sdkmanager --licenses

# Install Android SDK components
RUN sdkmanager "platform-tools" "platforms;android-33" "build-tools;33.0.0"

# Install Flutter
RUN cd /opt && \
    wget https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.16.5-stable.tar.xz && \
    tar xf flutter_linux_3.16.5-stable.tar.xz && \
    rm flutter_linux_3.16.5-stable.tar.xz

# Pre-download Flutter dependencies
RUN flutter precache

# Set working directory
WORKDIR /app

# Copy pubspec files
COPY pubspec.yaml pubspec.lock ./

# Get Flutter dependencies
RUN flutter pub get

# Copy the rest of the app
COPY . .

# Build the app
RUN flutter build apk --release

# Create a final stage with just the APK
FROM alpine:latest
WORKDIR /output
COPY --from=0 /app/build/app/outputs/flutter-apk/app-release.apk ./fertility-services-app.apk

# Command to copy APK to host
CMD ["cp", "fertility-services-app.apk", "/output/"]
