# Mengatasi Error Konflik Resource Icon

## Masalah

Saat build APK di Codemagic, muncul error:

```
ERROR:[mipmap-hdpi-v4/ic_launcher] /Users/builder/clone/android/app/src/main/res/mipmap-hdpi/ic_launcher.xml [mipmap-hdpi-v4/ic_launcher] /Users/builder/clone/android/app/src/main/res/mipmap-hdpi/ic_launcher.png: Resource and asset merger: Duplicate resources

FAILURE: Build failed with an exception.

* What went wrong:
Execution failed for task ':app:mergeDebugResources'.
> [mipmap-hdpi-v4/ic_launcher] /Users/builder/clone/android/app/src/main/res/mipmap-hdpi/ic_launcher.xml [mipmap-hdpi-v4/ic_launcher] /Users/builder/clone/android/app/src/main/res/mipmap-hdpi/ic_launcher.png: Error: Duplicate resources
```

## Penyebab

Masalah ini terjadi karena:

1. Ada file icon dengan nama yang sama dalam format berbeda:
   - `ic_launcher.xml` (Vector Drawable / Adaptive Icon)
   - `ic_launcher.png` (Bitmap Icon)

2. Android build system tidak bisa menangani kedua file dengan nama sama dan akan menghasilkan error "Duplicate resources"

## Solusi

### 1. Perbaikan di Codemagic

File `codemagic.yaml` sudah diperbarui untuk menghapus semua file XML icon sebelum build:

```yaml
- name: Fix Resource Conflicts
  script: |
    # Hapus semua file XML ic_launcher untuk mencegah konflik dengan PNG
    find android/app/src/main/res/mipmap-*/ic_launcher.xml -delete || true
    find $CM_BUILD_DIR/android/app/src/main/res/mipmap-*/ic_launcher.xml -delete || true
    echo "Removed conflicting XML launcher icons"
```

### 2. Perbaikan Lokal (Build di Komputer Sendiri)

#### Windows

Jalankan di PowerShell:

```powershell
Get-ChildItem -Path "android\app\src\main\res" -Recurse -Filter "ic_launcher.xml" | Remove-Item -Force
```

#### macOS / Linux

Jalankan di Terminal:

```bash
find android/app/src/main/res -name "ic_launcher.xml" -delete
```

### 3. Solusi Permanen

1. **Gunakan Icon Generator dengan Benar**:
   
   ```dart
   flutter_launcher_icons:
     android: true
     ios: true
     remove_alpha_ios: true
     image_path: "assets/images/app_icon.png"
     # Pastikan menggunakan adaptive_icon untuk Android modern
     adaptive_icon_background: "#ffffff"
     adaptive_icon_foreground: "assets/images/app_icon.png"
   ```

2. **Bersihkan Resource Secara Manual**:
   - Periksa folder `android/app/src/main/res/mipmap-*`
   - Pastikan hanya ada satu jenis format file icon per folder

## Mengapa Terjadi?

Konflik ini sering terjadi ketika:

1. Menggunakan tools yang berbeda untuk generate icon (flutter_launcher_icons, Android Studio, dll)
2. Mengupgrade project dari format lama ke baru (adaptive icons)
3. Menggabungkan konfigurasi yang bertentangan

## Cara Kerja Adaptive Icons

Android modern (API 26+) menggunakan sistem Adaptive Icons yang terdiri dari:
- Background layer (warna solid atau image)
- Foreground layer (logo/icon utama)

Sistem ini menggunakan format XML untuk menggabungkan keduanya, tapi saat mencoba menggunakan PNG dan XML bersamaan dengan nama file yang sama, terjadilah konflik. 