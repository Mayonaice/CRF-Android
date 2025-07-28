# Perbaikan Error "Unsupported class file major version 61"

## Masalah yang Terjadi

Error baru yang muncul adalah:

```
Caused by: java.lang.IllegalArgumentException: Unsupported class file major version 61
```

Ini adalah error yang sangat spesifik dan menunjukkan adanya ketidakcocokan versi Java. **Class file major version 61** mengacu pada Java 17, sementara Gradle yang digunakan (7.0.2) hanya mendukung hingga Java 16.

## Solusi

### 1. Pastikan Menggunakan Java 11 untuk Build

Java 11 adalah versi yang paling stabil dan kompatibel dengan Gradle 7.0.2 yang kita gunakan.

#### Untuk Codemagic

Ubah konfigurasi di `codemagic.yaml`:

```yaml
environment:
  flutter: 3.16.9
  java: 11  # Gunakan Java 11, bukan Java 17
```

#### Untuk Build Lokal

Pastikan Java 11 digunakan untuk build:

```bash
# Di Windows, gunakan PowerShell untuk mengatur JAVA_HOME
$env:JAVA_HOME = "C:\Program Files\Java\jdk-11"
$env:PATH = "$env:JAVA_HOME\bin;$env:PATH"

# Verifikasi versi Java
java -version
# Seharusnya menampilkan Java 11.x.x
```

### 2. Alternatif: Upgrade Gradle untuk Mendukung Java 17

Jika tetap ingin menggunakan Java 17, maka Gradle juga harus diupgrade:

```properties
# android/gradle/wrapper/gradle-wrapper.properties
distributionUrl=https\://services.gradle.org/distributions/gradle-7.3-all.zip
```

```gradle
// android/build.gradle
ext.kotlin_version = '1.6.21'
classpath 'com.android.tools.build:gradle:7.2.0'
```

Namun, pendekatan ini berisiko memunculkan masalah kompatibilitas baru.

### 3. Solusi Paling Aman: Downgrade Flutter

Menggunakan Flutter versi yang lebih lama yang secara default menggunakan Java 11:

```bash
flutter version 3.10.0
flutter clean
flutter pub get
```

## Penjelasan Teknis

| Java Version | Class File Version | Gradle Support |
|--------------|-------------------|---------------|
| Java 8       | 52                | Semua versi Gradle |
| Java 11      | 55                | Gradle 5.0+ |
| Java 16      | 60                | Gradle 7.0+ |
| Java 17      | 61                | Gradle 7.3+ |

Error "Unsupported class file major version 61" terjadi karena:

1. **Flutter 3.32.5** (yang Anda gunakan) secara default menggunakan **Java 17**
2. **Gradle 7.0.2** (yang kita konfigurasi) hanya mendukung hingga **Java 16**

## Kesimpulan

Untuk mengatasi masalah ini, ada dua pendekatan yang bisa diambil:

1. **Pendekatan Konservatif (Direkomendasikan)**: Downgrade ke Java 11 dan tetap menggunakan Gradle 7.0.2
2. **Pendekatan Progresif**: Upgrade ke Gradle 7.3+ untuk mendukung Java 17

Pendekatan konservatif lebih direkomendasikan karena lebih kecil kemungkinannya memunculkan masalah baru. 