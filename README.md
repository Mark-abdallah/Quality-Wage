# Quality — Daily Wage App

Offline Android app (Flutter) for a light‑current construction company to record daily wages, view technician/project reports, manage lists, and import/export an Excel file matching `Quality Attendance.xlsx`.

- **Bilingual:** Arabic (RTL) / English (LTR) with an in‑app language toggle.
- **Offline:** all data stored locally in SQLite.
- **Excel:** export/import `.xlsx` with sheets `Data entry`, `Tech Report`, `Project Report`, `Data Base`.

---

## Get the APK (no local install needed) — via GitHub Actions

1. Create a new repository on GitHub (e.g. `quality-wage-app`).
2. Upload the contents of this `quality_wage_app` folder to the repo (including the `.github` folder). Easiest ways:
   - **GitHub website:** "Add file → Upload files", drag the folder contents, commit.
   - **Git CLI:**
     ```bash
     git init
     git add .
     git commit -m "Quality wage app"
     git branch -M main
     git remote add origin https://github.com/<you>/quality-wage-app.git
     git push -u origin main
     ```
3. On GitHub open the **Actions** tab. The **Build Android APK** workflow runs automatically on push (or click **Run workflow**).
4. When it finishes (green check), open the run → **Artifacts** → download **Quality-APK** (`Quality.apk`).

### Install on Android
1. Copy `Quality.apk` to the phone.
2. Open it; when prompted, allow **Install from unknown sources** for your file manager/browser.
3. Tap **Install**.

---

## Using the app
- **Entries:** add daily records (Date, Project, Technician, Salary, Down payment). `Rest = Salary − Down payment` is computed automatically. Tap a row to edit, long‑press to delete. Filter by date range and search.
- **Reports:** per‑technician (Total, Rest) and per‑project (Total), respecting the date filter.
- **Lists:** add / rename / remove Projects and Technicians (used as dropdowns).
- **Import / Export:** export all data to `.xlsx` (and share it), or import from an `.xlsx` of the same layout (import replaces current data after confirmation).

---

## دليل سريع (بالعربية)
- **السجلات:** أضف سجل يومي (التاريخ، المشروع، الفني، الراتب، المقدم). يُحسب **الباقي = الراتب − المقدم** تلقائيًا. اضغط على السجل للتعديل، واضغط مطولًا للحذف. يمكنك التصفية بالتاريخ والبحث.
- **التقارير:** تقرير لكل فني (الإجمالي والباقي) وتقرير لكل مشروع (الإجمالي).
- **القوائم:** إضافة/إعادة تسمية/حذف المشاريع والفنيين.
- **استيراد/تصدير:** تصدير كل البيانات إلى ملف إكسل ومشاركته، أو استيراد ملف إكسل بنفس الصيغة (الاستيراد يستبدل البيانات الحالية بعد التأكيد).

---

## Build locally (optional)
Requires Flutter SDK + Android SDK + JDK 17.
```bash
flutter create --org com.quality --platforms=android .
flutter pub get
flutter build apk --release
# APK: build/app/outputs/flutter-apk/app-release.apk
```

## Notes
- The `android/` folder is regenerated automatically during the build (see `.github/workflows/build-apk.yml`), so it is not committed.
- The app is seeded with the projects and technicians found in the original workbook; edit them anytime in **Lists**.
- Replace the placeholder "Q" logo later if you want a custom icon.
