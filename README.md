
<div align="center">


<pre>
                                 
                                 
               ,----,    ,--,    
             .'   .' \ ,--.'|    
           ,----,'    ||  | :    
     .---. |    :  .  ;:  : '    
   /.  ./| ;    |.'  / |  ' |    
 .-' . ' | `----'/  ;  '  | |    
/___/ \: |   /  ;  /   |  | :    
.   \  ' .  ;  /  /-,  '  : |__  
 \   \   ' /  /  /.`|  |  | '.'| 
  \   \  ./__;      :  ;  :    ; 
   \   \ |   :    .'   |  ,   /  
    '---";   | .'       ---`-'   
         `---'                   
                                 
  </pre>

  <h1>V2L - V2Ray Scraper UI</h1>

  <p>
    یک ابزار دسکتاپ مینیمال و چند-سکویی برای استخراج و تست کانفیگ‌های V2Ray از کانال‌های تلگرام، با یک رابط کاربری زیبا و مدرن تحت وب.
  </p>
  <p>
    <i>A minimal, cross-platform desktop tool to scrape and test V2Ray configurations from Telegram channels, served via a slick local web UI.</i>
  </p>

  <!-- Badges -->
  <p>
    <a href="https://github.com/arshiacomplus/V2rayExtractor-local/releases/latest"><img src="https://img.shields.io/github/v/release/arshiacomplus/V2rayExtractor-local?style=for-the-badge&logo=github" alt="Latest Release"></a>
    <a href="https://github.com/arshiacomplus/V2rayExtractor-local/releases"><img src="https://img.shields.io/github/downloads/arshiacomplus/V2rayExtractor-local/total?style=for-the-badge&logo=github" alt="Total Downloads"></a>
    <!-- این بچ به صورت خودکار لایسنس را از فایل LICENSE ریپازیتوری شما می‌خواند -->
    <a href="https://github.com/arshiacomplus/V2rayExtractor-local/blob/main/LICENSE"><img src="https://img.shields.io/github/license/arshiacomplus/V2rayExtractor-local?style=for-the-badge" alt="License: GPL-3.0"></a>
  </p>

</div>

---

![V2L Screenshot](screenshot.png)
<!-- TODO: یک اسکرین‌شات از رابط کاربری برنامه بگیر و لینک بالا را جایگزین کن -->

## ✨ ویژگی‌ها (Features)

- **چند-سکویی:** به صورت یک فایل اجرایی واحد برای ویندوز، لینوکس (x64) و ترموکس (ARM64) ارائه می‌شود.
- **بدون نیاز به نصب:** نیازی به نصب پایتون، گیت یا وابستگی‌های دیگر برای کاربران نهایی نیست. (بجز ترموکس)
- **رابط کاربری زیبا:** یک UI مدرن و زیبا با استایل Glassmorphism که به صورت محلی روی مرورگر شما اجرا می‌شود.
- **استخراج خودکار:** لینک کانال‌های تلگرام را وارد کنید تا کانفیگ‌ها به صورت خودکار استخراج شوند.
- **تست کانفیگ:** تمام کانفیگ‌های پیدا شده برای اطمینان از سالم بودن تست می‌شوند.
- **نصب با یک خط دستور:** یک اسکریپت نصب هوشمند تمام کارها را برای شما انجام می‌دهد.

## 🚀 نصب (Installation)

برای نصب، فقط کافیست دستور مربوط به سیستم‌عامل خود را در ترمینال اجرا کنید.

---

### 🐧 لینوکس، ترموکس و 🍎 مک

این دستور به صورت خودکار معماری پردازنده شما (Intel/AMD یا ARM) را تشخیص داده و نسخه صحیح را نصب می‌کند.

```bash
bash -c "$(curl -sL https://raw.githubusercontent.com/arshiacomplus/V2rayExtractor-local/main/install.sh)"
```
این اسکریپت ممکن است برای کپی کردن فایل به /usr/local/bin از شما رمز عبور (sudo) بخواهد.

💻 ویندوز

ترمینال PowerShell را باز کرده و دستور زیر را اجرا کنید:
```batch
Set-ExecutionPolicy Bypass -Scope Process -Force; iex ((New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/arshiacomplus/V2rayExtractor-local/main/install.ps1'))
```

مهم: بعد از اتمام نصب، باید یک پنجره ترمینال جدید باز کنید تا بتوانید از دستور جدید استفاده کنید.

💡 استفاده (Usage)

بعد از نصب موفقیت‌آمیز، فقط کافیست در هر ترمینالی دستور زیر را تایپ کنید:

```bash
v2l
```

برای حذف کردنش:
```batch
$InstallDir = "$env:APPDATA\V2L_CLI"; if (Test-Path $InstallDir) { Write-Host "Uninstalling V2L..."; Write-Host "1. Removing from user PATH..."; $userPath = (Get-ItemProperty -Path 'HKCU:\Environment' -Name 'Path').Path; $newPath = ($userPath -split ';' | Where-Object { $_ -ne $InstallDir -and $_ -ne "" }) -join ';'; Set-ItemProperty -Path 'HKCU:\Environment' -Name 'Path' -Value $newPath; Write-Host "2. Deleting installation directory: $InstallDir"; Remove-Item -Path $InstallDir -Recurse -Force; Write-Host "Uninstallation complete! Please open a new terminal for changes to take effect." } else { Write-Host "V2L is not installed. Nothing to do." }
```

این دستور:

یک سرور وب محلی را اجرا می‌کند.

به صورت خودکار مرورگر پیش‌فرض شما را در آدرس http://127.0.0.1:8000 باز می‌کند.

حالا می‌توانید از رابط کاربری گرافیکی برای استخراج و تست کانفیگ‌ها استفاده کنید!

👨‍💻 برای توسعه‌دهندگان (Building from Source)

اگر می‌خواهید پروژه را به صورت دستی اجرا یا توسعه دهید:

کلون کردن ریپازیتوری:

```bash
git clone https://github.com/arshiacomplus/V2rayExtractor-local.git
cd V2rayExtractor-local
```
نصب وابستگی‌ها:

```sh
pip install -r requirements.txt
```

اجرای برنامه:

```sh
python main.py
```

فرآیند بیلد خودکار در فایل .github/workflows/build_release.yml تعریف شده است.

📄 لایسنس (License)

این پروژه تحت لایسنس عمومی همگانی گنو نسخه ۳ (GPL-3.0) منتشر شده است. برای جزئیات بیشتر به فایل LICENSE مراجعه کنید.

<div align="center">
ساخته شده با ❤️ توسط <a href="https://github.com/arshiacomplus">arshiacomplus</a>
</div>
