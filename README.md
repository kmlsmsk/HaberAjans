# 🎙️ HaberCiM - Ege Üniversitesi Ege Ajans Yapay Zeka Haber Üretim & Ses Çözümleme Platformu

**Geliştirici:** Dr. Kemal ŞİMŞEK (Bilgisayar Mühendisi)  
**Tasarım & Mimari:** Ege Üniversitesi Kurumsal Kimliğine Uygun Full-Stack Web Uygulaması  

---

## 🌟 Özellikler ve Modüller

1. **🎙️ Ses Çözümleme (Transkripsiyon):**
   - Tarayıcı üzerinden **canlı mikrofon kaydı** veya MP3/WAV/M4A ses dosyası yükleme.
   - Google Gemini yapay zeka modelleri ile tam doğrulukta deşifre ve imla düzeltme.
   - Formatlı **Word (.docx)** çıktısı alma.

2. **📰 Ege Ajans Haber Yazarı:**
   - Ham notlar, taslak metin, referans web bağlantısı ve fotoğraf/belge yükleme desteği (Multimodal).
   - Ege Üniversitesi resmi basın bülteni formatına tam uyum (`İZMİR (Ege Ajans) -`, Rektör demeci, 5N1K ve Ters Piramit kuralı).
   - Tek tıkla haber oluşturma ve Word (.docx) raporu indirme.

3. **📺 TV Haber Formatı & Teleprompter:**
   - Haberleri televizyon bülteni formatına çevirme (KJ, CAM, SES etiketleri, yıldızsız/temiz metin).
   - **Video / Röportaj Var / Yok** seçeneğine göre dinamik kurgu.
   - Stüdyo tipi **Canlı Teleprompter** (Ayna modu, hız ayarı, tam ekran).
   - **Türkçe Sesli Okuma (TTS):** Tarayıcı üzerinden spiker provası için seslendirme motoru.

4. **✍️ Dil, Üslup & Editoryal Denetim:**
   - Haber metnini TDK kuralları, 5N1K, Ege Ajans üslubu ve etik ilkelere göre denetler.
   - **3 Ayrı Kopyalanabilir Panel:**
     - 📊 *Denetim Raporu & 100 Üzerinden Puan*
     - ✍️ *Düzeltilmiş ve Yayına Hazır Nihai Metin*
     - 📝 *Yapılan Değişiklikler ve İyileştirme Maddeleri*

5. **⚙️ Gemini Model Yönetimi (CRUD):**
   - `gemini-2.5-flash`, `gemini-2.5-pro`, `gemini-3.8-flash`, `gemini-3.8-live` vb. modelleri dinamik ekleme, düzenleme ve silme.
   - Modüllere özel varsayılan model atama.
   - API Key yerel tarayıcı hafızasında (LocalStorage) güvenle saklanır.

---

## 🚀 Yerel Olarak Çalıştırma

```bash
# 1. Bağımlılıkları yükleyin
pip install -r requirements.txt

# 2. Uygulamayı başlatın
uvicorn app:app --reload --port 8000
```
Tarayıcınızda `http://localhost:8000` adresini açınız.

---

## 🌐 Render.com Üzerinde Canlıya Alma (Deploy) Rehberi

### Adım 1: GitHub Deposuna Yükleme
```bash
git init
git add .
git commit -m "feat: HaberCiM Web App ready for Render"
git branch -M main
git remote add origin https://github.com/KULLANICI_ADINIZ/HaberCiM.git
git push -u origin main
```

### Adım 2: Render.com'da Yayınlama
1. [Render.com](https://render.com) adresine giriş yapın.
2. **New +** butonuna basıp **Web Service** seçeneğini seçin.
3. GitHub deponuzu bağlayın.
4. Yapılandırma ayarları:
   - **Name:** `habercim`
   - **Runtime:** `Python 3`
   - **Build Command:** `pip install -r requirements.txt`
   - **Start Command:** `uvicorn app:app --host 0.0.0.0 --port $PORT`
   - **Instance Type:** `Free`
5. **Create Web Service** butonuna tıklayın! Birkaç dakika içinde `https://habercim.onrender.com` gibi canlı bir bağlantı elde edeceksiniz.

---

## 👨‍💻 Künye
- **Proje:** HaberCiM - Ege Ajans Akıllı Haber Platformu
- **Geliştirici:** Dr. Kemal ŞİMŞEK (Bilgisayar Mühendisi)
- **Telif Hakları:** © 2026
