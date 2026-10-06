/**
 * HaberCiM - Ege Ajans AI Medya Asistanı Web Client
 * Geliştiren: Dr. Kemal ŞİMŞEK (Bilgisayar Mühendisi)
 */

// Varsayılan Model Listesi (Google Gemini Resmi API Modelleri)
const DEFAULT_MODELS = [
  { id: 'gemini-2.5-flash', name: 'Gemini 2.5 Flash', desc: 'Hızlı, doğru ve güçlü model (Varsayılan & Önerilen)', isCustom: false },
  { id: 'gemini-3.8-flash', name: 'Gemini 3.8 Flash', desc: 'Yeni nesil ultra hızlı model', isCustom: false },
  { id: 'gemini-3.1-pro-preview', name: 'Gemini 3.1 Pro Preview', desc: 'Gelişmiş editoryal denetim ve muhakeme', isCustom: false },
  { id: 'gemini-3-flash-preview', name: 'Gemini 3 Flash Preview', desc: 'Multimodal ve ses önizleme modeli', isCustom: false },
  { id: 'gemini-2.0-flash', name: 'Gemini 2.0 Flash', desc: 'Hızlı ve kararlı temel üretim modeli', isCustom: false },
  { id: 'gemini-3.8-live', name: 'Gemini 3.8 Live', desc: 'Canlı akış ve ses/metin modeli', isCustom: false },
  { id: 'gemini-3.8-live-extended-thinking', name: 'Gemini 3.8 Live (Extended Thinking)', desc: 'Genişletilmiş düşünce ve analiz', isCustom: false }
];

// Model İsim Kontrolü & Temizleme
function sanitizeModelId(modelId) {
  if (!modelId) return 'gemini-2.5-flash';
  if (modelId === 'gemini-2.5-pro' || modelId === 'gemini-1.5-pro' || modelId === 'gemini-1.5-flash') return 'gemini-2.5-flash';
  if (modelId === 'gemini-pro') return 'gemini-2.5-flash';
  return modelId;
}

let storedModuleModels = {};
try {
  storedModuleModels = JSON.parse(localStorage.getItem('habercim_module_models') || '{}');
} catch (e) {
  storedModuleModels = {};
}

// Uygulama Durumu (State)
const AppState = {
  apiKey: localStorage.getItem('habercim_api_key') || '',
  rectorName: localStorage.getItem('habercim_rector_name') || 'Prof. Dr. Musa ALCI',
  models: DEFAULT_MODELS,
  moduleModels: {
    global: sanitizeModelId(storedModuleModels.global || 'gemini-2.5-flash'),
    audio: sanitizeModelId(storedModuleModels.audio || 'gemini-2.5-flash'),
    news: sanitizeModelId(storedModuleModels.news || 'gemini-2.5-flash'),
    tv: sanitizeModelId(storedModuleModels.tv || 'gemini-2.5-flash'),
    editorial: sanitizeModelId(storedModuleModels.editorial || 'gemini-2.5-flash')
  },
  currentView: 'dashboard',
  recording: {
    isRecording: false,
    mediaRecorder: null,
    audioChunks: [],
    timerInterval: null,
    seconds: 0,
    audioBlob: null,
    audioBase64: null,
    audioMime: 'audio/mp4'
  },
  prompter: {
    isPlaying: false,
    isMirrored: false,
    isSpeaking: false,
    speed: 2,
    fontSize: 28,
    scrollInterval: null,
    countdown: 0,
    text: '',
    title: ''
  }
};

// Başlangıç
document.addEventListener('DOMContentLoaded', () => {
  initUI();
  setupEventListeners();
  checkApiKeyStatus();
  renderModelDropdowns();
  renderModelManagementList();
});

// UI Başlatma
function initUI() {
  document.getElementById('rector-name-display').innerText = AppState.rectorName;
  document.getElementById('settings-rector-name').value = AppState.rectorName;
  document.getElementById('settings-api-key').value = AppState.apiKey;
  
  if (AppState.apiKey) {
    document.getElementById('api-key-banner').classList.add('hidden');
  } else {
    document.getElementById('api-key-banner').classList.remove('hidden');
  }
}

// Görünüm Değiştirici (Tab Switcher)
function switchView(viewName) {
  AppState.currentView = viewName;
  const views = ['dashboard', 'audio', 'news', 'tv', 'editorial', 'settings'];
  
  views.forEach(v => {
    const el = document.getElementById(`view-${v}`);
    if (el) {
      if (v === viewName) {
        el.classList.remove('hidden');
        window.scrollTo({ top: 0, behavior: 'smooth' });
      } else {
        el.classList.add('hidden');
      }
    }
  });

  // Nav aktiflik durumu
  document.querySelectorAll('.nav-link').forEach(btn => {
    if (btn.dataset.view === viewName) {
      btn.classList.add('bg-white/20', 'text-white');
    } else {
      btn.classList.remove('bg-white/20', 'text-white');
    }
  });
}

// API Anahtarı Durumu Kontrolü
function checkApiKeyStatus() {
  const banner = document.getElementById('api-key-banner');
  if (AppState.apiKey && AppState.apiKey.trim().length > 5) {
    banner.classList.add('hidden');
  } else {
    banner.classList.remove('hidden');
  }
}

// Bildirim Göster (Toast)
function showToast(message, type = 'info') {
  const toastContainer = document.getElementById('toast-container');
  const toast = document.createElement('div');
  
  let bg = 'bg-[#003366] text-white';
  let icon = 'fa-info-circle';
  if (type === 'success') { bg = 'bg-emerald-600 text-white'; icon = 'fa-check-circle'; }
  if (type === 'error') { bg = 'bg-rose-600 text-white'; icon = 'fa-exclamation-circle'; }
  if (type === 'warning') { bg = 'bg-amber-600 text-white'; icon = 'fa-triangle-exclamation'; }

  toast.className = `flex items-center gap-3 px-4 py-3 rounded-xl shadow-lg ${bg} transform transition-all duration-300 translate-y-2 opacity-0 text-sm font-medium`;
  toast.innerHTML = `<i class="fa-solid ${icon}"></i> <span>${message}</span>`;
  
  toastContainer.appendChild(toast);
  setTimeout(() => {
    toast.classList.remove('translate-y-2', 'opacity-0');
  }, 10);

  setTimeout(() => {
    toast.classList.add('translate-y-2', 'opacity-0');
    setTimeout(() => toast.remove(), 300);
  }, 3500);
}

// ---------------------------------------------------------
// MODEL YÖNETİMİ & CRUD
// ---------------------------------------------------------
function renderModelDropdowns() {
  const selects = ['audio-model-select', 'news-model-select', 'tv-model-select', 'editorial-model-select', 'settings-global-model', 'settings-audio-model', 'settings-news-model', 'settings-tv-model', 'settings-editorial-model'];
  
  selects.forEach(id => {
    const el = document.getElementById(id);
    if (!el) return;
    
    const moduleKey = id.split('-')[0].replace('settings', '') || 'global';
    const currentVal = AppState.moduleModels[moduleKey] || AppState.moduleModels.global || 'gemini-2.5-flash';
    
    el.innerHTML = AppState.models.map(m => `
      <option value="${m.id}" ${m.id === currentVal ? 'selected' : ''}>
        ${m.name} ${m.isCustom ? '(Özel)' : ''}
      </option>
    `).join('');
  });
}

function renderModelManagementList() {
  const listEl = document.getElementById('model-management-list');
  if (!listEl) return;

  listEl.innerHTML = AppState.models.map((m, idx) => `
    <div class="flex items-center justify-between p-3 rounded-xl border border-slate-200 bg-white hover:border-slate-300 transition">
      <div class="flex items-center gap-3">
        <div class="w-8 h-8 rounded-lg flex items-center justify-center ${m.isCustom ? 'bg-amber-100 text-amber-700' : 'bg-cyan-100 text-[#003366]'}">
          <i class="fa-solid ${m.isCustom ? 'fa-puzzle-piece' : 'fa-brain'} text-sm"></i>
        </div>
        <div>
          <div class="text-sm font-semibold text-slate-800">${m.name}</div>
          <div class="text-xs text-slate-500 font-mono">${m.id} &bull; ${m.desc || ''}</div>
        </div>
      </div>
      <div class="flex items-center gap-1">
        <button onclick="editModelDialog('${m.id}')" class="p-2 text-slate-400 hover:text-[#003366] transition" title="Düzenle">
          <i class="fa-solid fa-pen-to-square"></i>
        </button>
        <button onclick="deleteModel('${m.id}')" class="p-2 text-slate-400 hover:text-red-600 transition" title="Sil">
          <i class="fa-solid fa-trash"></i>
        </button>
      </div>
    </div>
  `).join('');
}

function openAddModelModal(existingModel = null) {
  const modal = document.getElementById('model-modal');
  const title = document.getElementById('model-modal-title');
  const idInput = document.getElementById('modal-model-id');
  const nameInput = document.getElementById('modal-model-name');
  const descInput = document.getElementById('modal-model-desc');

  if (existingModel) {
    title.innerText = 'Modeli Düzenle';
    idInput.value = existingModel.id;
    idInput.disabled = true;
    nameInput.value = existingModel.name;
    descInput.value = existingModel.desc || '';
  } else {
    title.innerText = 'Yeni Gemini Modeli Ekle';
    idInput.value = '';
    idInput.disabled = false;
    nameInput.value = '';
    descInput.value = '';
  }

  modal.classList.remove('hidden');
}

function closeModelModal() {
  document.getElementById('model-modal').classList.add('hidden');
}

function saveModelFromModal() {
  const id = document.getElementById('modal-model-id').value.trim();
  const name = document.getElementById('modal-model-name').value.trim() || id;
  const desc = document.getElementById('modal-model-desc').value.trim();

  if (!id) {
    showToast('Lütfen geçerli bir Model ID girin.', 'warning');
    return;
  }

  const idx = AppState.models.findIndex(m => m.id === id);
  if (idx >= 0) {
    AppState.models[idx] = { ...AppState.models[idx], name, desc };
    showToast(`'${name}' modeli güncellendi.`, 'success');
  } else {
    AppState.models.push({ id, name, desc, isCustom: true });
    showToast(`'${name}' modeli eklendi.`, 'success');
  }

  localStorage.setItem('habercim_models_v2', JSON.stringify(AppState.models));
  renderModelDropdowns();
  renderModelManagementList();
  closeModelModal();
}

function editModelDialog(modelId) {
  const model = AppState.models.find(m => m.id === modelId);
  if (model) openAddModelModal(model);
}

function deleteModel(modelId) {
  if (confirm(`'${modelId}' modelini silmek istediğinize emin misiniz?`)) {
    AppState.models = AppState.models.filter(m => m.id !== modelId);
    localStorage.setItem('habercim_models_v2', JSON.stringify(AppState.models));
    renderModelDropdowns();
    renderModelManagementList();
    showToast('Model silindi.', 'info');
  }
}

function resetModelsToDefault() {
  if (confirm('Tüm modeller fabrika ayarlarına sıfırlanacak. Onaylıyor musunuz?')) {
    AppState.models = JSON.parse(JSON.stringify(DEFAULT_MODELS));
    localStorage.removeItem('habercim_models_v2');
    renderModelDropdowns();
    renderModelManagementList();
    showToast('Modeller varsayılana sıfırlandı.', 'success');
  }
}

async function fetchRemoteModels() {
  if (!AppState.apiKey) {
    showToast('Lütfen önce bir API anahtarı kaydedin.', 'warning');
    return;
  }

  const btn = document.getElementById('btn-fetch-models');
  btn.disabled = true;
  btn.innerHTML = '<i class="fa-solid fa-spinner fa-spin"></i> Çekiliyor...';

  try {
    const res = await fetch('/api/fetch-models', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ api_key: AppState.apiKey })
    });
    const data = await res.json();
    if (data.success && data.models) {
      let added = 0;
      data.models.forEach(mId => {
        if (!AppState.models.some(m => m.id === mId)) {
          AppState.models.push({
            id: mId,
            name: mId.replace(/-/g, ' ').toUpperCase(),
            desc: 'Google API üzerinden otomatik eklendi',
            isCustom: true
          });
          added++;
        }
      });
      localStorage.setItem('habercim_models_v2', JSON.stringify(AppState.models));
      renderModelDropdowns();
      renderModelManagementList();
      showToast(`${added} yeni model hesabınızdan başarıyla çekildi!`, 'success');
    } else {
      showToast(data.error || 'Modeller alınamadı.', 'error');
    }
  } catch (e) {
    showToast(`Hata: ${e.message}`, 'error');
  } finally {
    btn.disabled = false;
    btn.innerHTML = '<i class="fa-solid fa-cloud-arrow-down"></i> Modelleri Çek';
  }
}

// ---------------------------------------------------------
// AYARLARI KAYDETME
// ---------------------------------------------------------
async function saveSettings() {
  const key = document.getElementById('settings-api-key').value.trim();
  const rector = document.getElementById('settings-rector-name').value.trim();

  AppState.apiKey = key;
  AppState.rectorName = rector || 'Prof. Dr. Musa ALCI';

  AppState.moduleModels = {
    global: document.getElementById('settings-global-model').value,
    audio: document.getElementById('settings-audio-model').value,
    news: document.getElementById('settings-news-model').value,
    tv: document.getElementById('settings-tv-model').value,
    editorial: document.getElementById('settings-editorial-model').value
  };

  localStorage.setItem('habercim_api_key', AppState.apiKey);
  localStorage.setItem('habercim_rector_name', AppState.rectorName);
  localStorage.setItem('habercim_module_models', JSON.stringify(AppState.moduleModels));

  document.getElementById('rector-name-display').innerText = AppState.rectorName;
  checkApiKeyStatus();
  renderModelDropdowns();
  showToast('Tüm ayarlar başarıyla kaydedildi!', 'success');
}

async function testApiKey() {
  const key = document.getElementById('settings-api-key').value.trim();
  if (!key) {
    showToast('Lütfen bir API anahtarı girin.', 'warning');
    return;
  }

  const btn = document.getElementById('btn-test-key');
  btn.disabled = true;
  btn.innerHTML = '<i class="fa-solid fa-spinner fa-spin"></i> Test Ediliyor...';

  try {
    const res = await fetch('/api/validate-key', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ api_key: key })
    });
    const data = await res.json();
    if (data.valid) {
      showToast('✅ Gemini API Anahtarı geçerli ve Gemini 2.5 Flash ile kullanıma hazır!', 'success');
    } else {
      showToast(`❌ ${data.message}`, 'error');
    }
  } catch (e) {
    showToast(`Test hatası: ${e.message}`, 'error');
  } finally {
    btn.disabled = false;
    btn.innerHTML = '<i class="fa-solid fa-circle-check"></i> Bağlantıyı Test Et';
  }
}

// ---------------------------------------------------------
// 1. SES ÇÖZÜMLEME MODÜLÜ (Web Audio API & Dosya Yükleme)
// ---------------------------------------------------------
async function toggleLiveRecording() {
  const btn = document.getElementById('record-btn');
  const timerText = document.getElementById('record-timer');
  const statusText = document.getElementById('record-status');
  const audioPreview = document.getElementById('audio-preview-container');

  if (AppState.recording.isRecording) {
    // Kaydı Durdur
    AppState.recording.mediaRecorder.stop();
    clearInterval(AppState.recording.timerInterval);
    AppState.recording.isRecording = false;

    btn.classList.remove('recording-pulse', 'bg-red-600');
    btn.classList.add('bg-[#003366]');
    btn.innerHTML = '<i class="fa-solid fa-microphone text-3xl text-white"></i>';
    statusText.innerText = 'Kayıt Tamamlandı';
  } else {
    // Kaydı Başlat
    try {
      const stream = await navigator.mediaDevices.getUserMedia({ audio: true });
      AppState.recording.audioChunks = [];
      AppState.recording.mediaRecorder = new MediaRecorder(stream);
      AppState.recording.seconds = 0;

      AppState.recording.mediaRecorder.ondataavailable = e => {
        if (e.data.size > 0) AppState.recording.audioChunks.push(e.data);
      };

      AppState.recording.mediaRecorder.onstop = () => {
        AppState.recording.audioBlob = new Blob(AppState.recording.audioChunks, { type: 'audio/mp4' });
        const audioUrl = URL.createObjectURL(AppState.recording.audioBlob);
        document.getElementById('audio-playback').src = audioUrl;
        audioPreview.classList.remove('hidden');

        // Base64 dönüştür
        const reader = new FileReader();
        reader.readAsDataURL(AppState.recording.audioBlob);
        reader.onloadend = () => {
          AppState.recording.audioBase64 = reader.result;
        };

        // Stream parçalarını kapat
        stream.getTracks().forEach(track => track.stop());
      };

      AppState.recording.mediaRecorder.start();
      AppState.recording.isRecording = true;

      btn.classList.remove('bg-[#003366]');
      btn.classList.add('recording-pulse', 'bg-red-600');
      btn.innerHTML = '<i class="fa-solid fa-stop text-3xl text-white"></i>';
      statusText.innerText = 'Kayıt Yapılıyor... (Durdurmak için dokunun)';

      AppState.recording.timerInterval = setInterval(() => {
        AppState.recording.seconds++;
        const mins = Math.floor(AppState.recording.seconds / 60).toString().padStart(2, '0');
        const secs = (AppState.recording.seconds % 60).toString().padStart(2, '0');
        timerText.innerText = `${mins}:${secs}`;
      }, 1000);

    } catch (err) {
      showToast('Mikrofon erişim izni alınamadı: ' + err.message, 'error');
    }
  }
}

function handleAudioFileUpload(e) {
  const file = e.target.files[0];
  if (!file) return;

  AppState.recording.audioBlob = file;
  AppState.recording.audioMime = file.type || 'audio/mp4';

  const audioUrl = URL.createObjectURL(file);
  document.getElementById('audio-playback').src = audioUrl;
  document.getElementById('audio-file-name').innerText = file.name;
  document.getElementById('audio-preview-container').classList.remove('hidden');

  const reader = new FileReader();
  reader.readAsDataURL(file);
  reader.onloadend = () => {
    AppState.recording.audioBase64 = reader.result;
  };
}

function clearRecordedAudio() {
  AppState.recording.audioBlob = null;
  AppState.recording.audioBase64 = null;
  document.getElementById('audio-preview-container').classList.add('hidden');
  document.getElementById('audio-playback').src = '';
  document.getElementById('audio-file-input').value = '';
  document.getElementById('record-timer').innerText = '00:00';
  document.getElementById('record-status').innerText = 'Canlı Kayıt İçin Dokunun';
}

async function processAudioTranscription() {
  if (!AppState.apiKey) {
    showToast('Lütfen önce Ayarlar bölümünden Gemini API Anahtarınızı girin.', 'warning');
    switchView('settings');
    return;
  }

  if (!AppState.recording.audioBase64 && !AppState.recording.audioBlob) {
    showToast('Lütfen önce bir ses kaydedin veya ses dosyası yükleyin.', 'warning');
    return;
  }

  const btn = document.getElementById('btn-process-audio');
  const resultContainer = document.getElementById('audio-result-container');
  const resultText = document.getElementById('audio-result-text');
  const model = document.getElementById('audio-model-select').value;

  btn.disabled = true;
  btn.innerHTML = '<i class="fa-solid fa-spinner fa-spin"></i> Gemini AI Sesi Çözümlüyor...';
  resultContainer.classList.add('hidden');

  try {
    const formData = new FormData();
    formData.append('api_key', AppState.apiKey);
    formData.append('model', model);
    formData.append('audio_base64', AppState.recording.audioBase64);
    formData.append('mime_type', AppState.recording.audioMime);

    const res = await fetch('/api/transcribe-audio', {
      method: 'POST',
      body: formData
    });

    const data = await res.json();
    if (data.success) {
      resultText.innerHTML = marked.parse(data.text);
      document.getElementById('audio-raw-text').value = data.text;
      document.getElementById('audio-used-model').innerText = `Model: ${data.used_model}`;
      resultContainer.classList.remove('hidden');
      showToast('Ses çözümleme başarıyla tamamlandı!', 'success');
      resultContainer.scrollIntoView({ behavior: 'smooth' });
    } else {
      showToast(data.error || 'Çözümleme başarısız oldu.', 'error');
    }
  } catch (err) {
    showToast(`Bağlantı hatası: ${err.message}`, 'error');
  } finally {
    btn.disabled = false;
    btn.innerHTML = '<i class="fa-solid fa-bolt"></i> Çözümlemeyi Başlat';
  }
}

// ---------------------------------------------------------
// 2. HABER YAZARI MODÜLÜ
// ---------------------------------------------------------
function applyNewsTemplate(type) {
  const templates = {
    tubitak: 'Ege Üniversitesi Fen Fakültesi Kimya Bölümü öğretim üyelerinin hazırladığı kanser araştırmaları projesi TÜBİTAK 1001 programı kapsamında 3.5 milyon TL destek almaya hak kazandı.',
    akademik: 'Ege Üniversitesi MÖTBE Kültür Merkezinde 2026-2027 Akademik Yılı Açılış Töreni gerçekleştirildi. Törende araştırma üniversitesi hedefleri ve yeni projeler paylaşıldı.',
    green: 'Ege Üniversitesi, GreenMetric dünya yeşil kampüs sıralamasında Türkiye birinciliğini korudu. Güneş enerjisi ve sıfır atık projeleri sergilendi.'
  };

  if (templates[type]) {
    document.getElementById('news-raw-text').value = templates[type];
    showToast('Şablon yüklendi.', 'info');
  }
}

function handleImageUpload(e) {
  const file = e.target.files[0];
  if (!file) return;

  const reader = new FileReader();
  reader.onload = () => {
    document.getElementById('news-image-preview').src = reader.result;
    document.getElementById('news-image-container').classList.remove('hidden');
    window._newsImageBase64 = reader.result;
    window._newsImageMime = file.type || 'image/jpeg';
  };
  reader.readAsDataURL(file);
}

function clearNewsImage() {
  window._newsImageBase64 = null;
  window._newsImageMime = null;
  document.getElementById('news-image-container').classList.add('hidden');
  document.getElementById('news-image-input').value = '';
}

async function generateNews() {
  if (!AppState.apiKey) {
    showToast('Lütfen önce Ayarlar bölümünden Gemini API Anahtarınızı girin.', 'warning');
    switchView('settings');
    return;
  }

  const rawText = document.getElementById('news-raw-text').value.trim();
  const url = document.getElementById('news-url').value.trim();
  const model = document.getElementById('news-model-select').value;

  if (!rawText && !window._newsImageBase64) {
    showToast('Lütfen ham haber notu girin veya bir fotoğraf yükleyin.', 'warning');
    return;
  }

  const btn = document.getElementById('btn-generate-news');
  const resultContainer = document.getElementById('news-result-container');
  const resultText = document.getElementById('news-result-text');

  btn.disabled = true;
  btn.innerHTML = '<i class="fa-solid fa-spinner fa-spin"></i> Ege Ajans Formatında Yazılıyor...';
  resultContainer.classList.add('hidden');

  try {
    const res = await fetch('/api/generate-news', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        api_key: AppState.apiKey,
        raw_text: rawText,
        reference_url: url,
        rector_name: AppState.rectorName,
        model: model,
        image_base64: window._newsImageBase64 || null,
        image_mime_type: window._newsImageMime || null
      })
    });

    const data = await res.json();
    if (data.success) {
      resultText.innerHTML = marked.parse(data.text);
      document.getElementById('news-raw-result').value = data.text;
      document.getElementById('news-used-model').innerText = `Model: ${data.used_model}`;
      resultContainer.classList.remove('hidden');
      showToast('Ege Ajans kurumsal haberi hazırlandı!', 'success');
      resultContainer.scrollIntoView({ behavior: 'smooth' });
    } else {
      showToast(data.error || 'Haber üretilemedi.', 'error');
    }
  } catch (err) {
    showToast(`Hata: ${err.message}`, 'error');
  } finally {
    btn.disabled = false;
    btn.innerHTML = '<i class="fa-solid fa-newspaper"></i> 📰 Haberi Oluştur (Ege Ajans Formatı)';
  }
}

// ---------------------------------------------------------
// 3. TV HABER FORMATI & PROMPTER
// ---------------------------------------------------------
async function convertToTvFormat() {
  if (!AppState.apiKey) {
    showToast('Lütfen önce Ayarlar bölümünden Gemini API Anahtarınızı girin.', 'warning');
    switchView('settings');
    return;
  }

  const text = document.getElementById('tv-raw-text').value.trim();
  const hasVideo = document.getElementById('tv-has-video').checked;
  const model = document.getElementById('tv-model-select').value;

  if (!text) {
    showToast('Lütfen TV formatına dönüştürülecek haber metnini girin.', 'warning');
    return;
  }

  const btn = document.getElementById('btn-convert-tv');
  const resultContainer = document.getElementById('tv-result-container');
  const resultText = document.getElementById('tv-result-text');

  btn.disabled = true;
  btn.innerHTML = '<i class="fa-solid fa-spinner fa-spin"></i> TV Formatına Dönüştürülüyor...';
  resultContainer.classList.add('hidden');

  try {
    const res = await fetch('/api/convert-tv', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        api_key: AppState.apiKey,
        news_text: text,
        has_video: hasVideo,
        model: model
      })
    });

    const data = await res.json();
    if (data.success) {
      resultText.innerText = data.text;
      document.getElementById('tv-raw-result').value = data.text;
      document.getElementById('tv-used-model').innerText = `Model: ${data.used_model}`;
      resultContainer.classList.remove('hidden');
      showToast('TV Bülten metni hazır!', 'success');
      resultContainer.scrollIntoView({ behavior: 'smooth' });
    } else {
      showToast(data.error || 'Dönüştürme başarısız oldu.', 'error');
    }
  } catch (err) {
    showToast(`Hata: ${err.message}`, 'error');
  } finally {
    btn.disabled = false;
    btn.innerHTML = '<i class="fa-solid fa-tv"></i> 📺 TV Bülten Formatına Dönüştür';
  }
}

// ---------------------------------------------------------
// 4. EDİTORYAL DENETİM MODÜLÜ
// ---------------------------------------------------------
async function checkEditorial() {
  if (!AppState.apiKey) {
    showToast('Lütfen önce Ayarlar bölümünden Gemini API Anahtarınızı girin.', 'warning');
    switchView('settings');
    return;
  }

  const text = document.getElementById('editorial-raw-text').value.trim();
  const model = document.getElementById('editorial-model-select').value;

  if (!text) {
    showToast('Lütfen denetlenecek haber metnini girin.', 'warning');
    return;
  }

  const btn = document.getElementById('btn-check-editorial');
  const resultContainer = document.getElementById('editorial-result-container');

  btn.disabled = true;
  btn.innerHTML = '<i class="fa-solid fa-spinner fa-spin"></i> Editoryal Denetim Yapılıyor...';
  resultContainer.classList.add('hidden');

  try {
    const res = await fetch('/api/check-editorial', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        api_key: AppState.apiKey,
        news_text: text,
        rector_name: AppState.rectorName,
        model: model
      })
    });

    const data = await res.json();
    if (data.success && data.structured) {
      document.getElementById('editorial-report-text').innerHTML = marked.parse(data.structured.report);
      document.getElementById('editorial-edited-text').innerHTML = marked.parse(data.structured.edited_text);
      document.getElementById('editorial-changelog-text').innerHTML = marked.parse(data.structured.changelog);

      document.getElementById('editorial-raw-report').value = data.structured.report;
      document.getElementById('editorial-raw-edited').value = data.structured.edited_text;
      document.getElementById('editorial-raw-changelog').value = data.structured.changelog;

      document.getElementById('editorial-used-model').innerText = `Model: ${data.used_model}`;
      resultContainer.classList.remove('hidden');
      showToast('Editoryal denetim tamamlandı!', 'success');
      resultContainer.scrollIntoView({ behavior: 'smooth' });
    } else {
      showToast(data.error || 'Denetim başarısız oldu.', 'error');
    }
  } catch (err) {
    showToast(`Hata: ${err.message}`, 'error');
  } finally {
    btn.disabled = false;
    btn.innerHTML = '<i class="fa-solid fa-fact-check"></i> 🔍 Haberi Titizlikle Denetle';
  }
}

// ---------------------------------------------------------
// TELEPROMPTER & SESLENDİRME (TTS)
// ---------------------------------------------------------
function openTeleprompter(textId, title = 'Spiker Teleprompter') {
  const text = document.getElementById(textId).value || document.getElementById(textId).innerText;
  if (!text) {
    showToast('Prompter için metin bulunamadı.', 'warning');
    return;
  }

  AppState.prompter.text = text;
  AppState.prompter.title = title;

  const modal = document.getElementById('prompter-modal');
  document.getElementById('prompter-title').innerText = title;
  document.getElementById('prompter-content').innerText = text;
  document.getElementById('prompter-content').style.fontSize = `${AppState.prompter.fontSize}px`;

  modal.classList.remove('hidden');
}

function closeTeleprompter() {
  stopPrompterScroll();
  stopPrompterSpeech();
  document.getElementById('prompter-modal').classList.add('hidden');
}

function togglePrompterScroll() {
  if (AppState.prompter.isPlaying) {
    stopPrompterScroll();
  } else {
    startPrompterCountdown();
  }
}

function startPrompterCountdown() {
  let count = 3;
  const overlay = document.getElementById('prompter-countdown');
  overlay.innerText = count;
  overlay.classList.remove('hidden');

  const timer = setInterval(() => {
    count--;
    if (count > 0) {
      overlay.innerText = count;
    } else {
      clearInterval(timer);
      overlay.classList.add('hidden');
      startPrompterScroll();
    }
  }, 1000);
}

function startPrompterScroll() {
  AppState.prompter.isPlaying = true;
  document.getElementById('btn-prompter-play').innerHTML = '<i class="fa-solid fa-pause"></i> Durdur';
  document.getElementById('btn-prompter-play').classList.remove('bg-[#00A3E0]');
  document.getElementById('btn-prompter-play').classList.add('bg-rose-600');

  const container = document.getElementById('prompter-scroll-container');
  clearInterval(AppState.prompter.scrollInterval);

  AppState.prompter.scrollInterval = setInterval(() => {
    container.scrollTop += AppState.prompter.speed * 0.8;
    if (container.scrollTop + container.clientHeight >= container.scrollHeight) {
      stopPrompterScroll();
    }
  }, 30);
}

function stopPrompterScroll() {
  AppState.prompter.isPlaying = false;
  clearInterval(AppState.prompter.scrollInterval);
  document.getElementById('btn-prompter-play').innerHTML = '<i class="fa-solid fa-play"></i> Kaydır';
  document.getElementById('btn-prompter-play').classList.remove('bg-rose-600');
  document.getElementById('btn-prompter-play').classList.add('bg-[#00A3E0]');
}

function resetPrompterScroll() {
  stopPrompterScroll();
  stopPrompterSpeech();
  document.getElementById('prompter-scroll-container').scrollTop = 0;
}

function togglePrompterMirror() {
  AppState.prompter.isMirrored = !AppState.prompter.isMirrored;
  const content = document.getElementById('prompter-content');
  if (AppState.prompter.isMirrored) {
    content.classList.add('prompter-mirror');
  } else {
    content.classList.remove('prompter-mirror');
  }
}

function changePrompterFontSize(delta) {
  AppState.prompter.fontSize = Math.max(18, Math.min(54, AppState.prompter.fontSize + delta));
  document.getElementById('prompter-content').style.fontSize = `${AppState.prompter.fontSize}px`;
}

function changePrompterSpeed(delta) {
  AppState.prompter.speed = Math.max(0.5, Math.min(10, AppState.prompter.speed + delta));
  document.getElementById('prompter-speed-label').innerText = `${AppState.prompter.speed.toFixed(1)}x`;
}

// Web SpeechSynthesis TTS
function togglePrompterSpeech() {
  if (AppState.prompter.isSpeaking) {
    stopPrompterSpeech();
  } else {
    startPrompterSpeech();
  }
}

function startPrompterSpeech() {
  if (!('speechSynthesis' in window)) {
    showToast('Tarayıcınız sesli okuma özelliğini desteklemiyor.', 'warning');
    return;
  }

  window.speechSynthesis.cancel();

  const cleanText = AppState.prompter.text
    .replace(/KJ:/g, '')
    .replace(/CAM:/g, '')
    .replace(/SES:/g, '')
    .replace(/\*\*/g, '')
    .replace(/#/g, '');

  const utterance = new SpeechSynthesisUtterance(cleanText);
  utterance.lang = 'tr-TR';
  utterance.rate = 0.95;

  utterance.onend = () => stopPrompterSpeech();
  utterance.onerror = () => stopPrompterSpeech();

  window.speechSynthesis.speak(utterance);
  AppState.prompter.isSpeaking = true;

  const btn = document.getElementById('btn-prompter-tts');
  btn.innerHTML = '<i class="fa-solid fa-volume-xmark"></i> Sustur';
  btn.classList.add('bg-emerald-700');
}

function stopPrompterSpeech() {
  if ('speechSynthesis' in window) {
    window.speechSynthesis.cancel();
  }
  AppState.prompter.isSpeaking = false;
  const btn = document.getElementById('btn-prompter-tts');
  if (btn) {
    btn.innerHTML = '<i class="fa-solid fa-volume-high"></i> Seslendir (TTS)';
    btn.classList.remove('bg-emerald-700');
  }
}

// ---------------------------------------------------------
// YARDIMCI EYLEMLER (Kopyalama & Word Export)
// ---------------------------------------------------------
function copyToClipboard(elementId, label = 'Metin') {
  const el = document.getElementById(elementId);
  const text = el.value || el.innerText;
  
  navigator.clipboard.writeText(text).then(() => {
    showToast(`${label} panoya kopyalandı!`, 'success');
  }).catch(() => {
    showToast('Kopyalama başarısız oldu.', 'error');
  });
}

async function exportDocx(elementId, defaultTitle = 'HaberCiM_Belge', isTv = false) {
  const el = document.getElementById(elementId);
  const text = el.value || el.innerText;

  if (!text) {
    showToast('İndirilecek metin bulunamadı.', 'warning');
    return;
  }

  showToast('Word (.docx) belgesi hazırlanıyor...', 'info');

  try {
    const res = await fetch('/api/export-docx', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        title: defaultTitle,
        content: text,
        is_tv: isTv
      })
    });

    if (res.ok) {
      const blob = await res.blob();
      const url = window.URL.createObjectURL(blob);
      const a = document.createElement('a');
      a.href = url;
      a.download = `${defaultTitle.replace(/\s+/g, '_')}.docx`;
      document.body.appendChild(a);
      a.click();
      a.remove();
      window.URL.revokeObjectURL(url);
      showToast('Word belgesi indirildi!', 'success');
    } else {
      showToast('Word belgesi oluşturulamadı.', 'error');
    }
  } catch (err) {
    showToast(`İndirme hatası: ${err.message}`, 'error');
  }
}

function setupEventListeners() {
  ['audio-model-select', 'news-model-select', 'tv-model-select', 'editorial-model-select'].forEach(id => {
    const el = document.getElementById(id);
    if (el) {
      el.addEventListener('change', (e) => {
        const mod = id.split('-')[0];
        AppState.moduleModels[mod] = e.target.value;
        localStorage.setItem('habercim_module_models', JSON.stringify(AppState.moduleModels));
      });
    }
  });
}
