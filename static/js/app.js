/**
 * HaberCiM - Akıllı Haber Üretim & AI Medya Asistanı Web Client
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

// Model İsim Kontrolü
function sanitizeModelId(modelId) {
  if (!modelId) return 'gemini-2.5-flash';
  if (modelId === 'gemini-2.5-pro' || modelId === 'gemini-1.5-pro' || modelId === 'gemini-1.5-flash') return 'gemini-2.5-flash';
  if (modelId === 'gemini-pro') return 'gemini-2.5-flash';
  return modelId.replace('models/', '').trim();
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
  universityName: localStorage.getItem('habercim_university_name') || 'XXXX Üniversitesi',
  agencyName: localStorage.getItem('habercim_agency_name') || 'XXX Ajans',
  rectorName: localStorage.getItem('habercim_rector_name') || 'Prof. Dr. XXXX YYYY',
  cityName: localStorage.getItem('habercim_city_name') || 'İZMİR',
  portalUrl: localStorage.getItem('habercim_portal_url') || 'www.xxxajans.com',
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
    title: '',
    ttsRate: 1.0,
    ttsPitch: 1.0,
    ttsVolume: 1.0,
    selectedVoiceURI: null,
    availableVoices: []
  }
};

// Başlangıç
document.addEventListener('DOMContentLoaded', () => {
  initUI();
  setupEventListeners();
  checkApiKeyStatus();
  renderModelDropdowns();
  renderModelManagementList();
  initTtsVoices();
});

// UI Başlatma ve Dinamik Parametreleri Yerleştirme
function initUI() {
  // Kurumsal Parametreleri Ekrana Yaz
  document.getElementById('nav-agency-badge').innerText = AppState.agencyName;
  document.getElementById('nav-university-sub').innerText = `${AppState.universityName} Medya Masası`;
  document.getElementById('hero-university-badge').innerText = `${AppState.universityName} • ${AppState.agencyName}`;
  document.getElementById('dash-university-name').innerText = AppState.universityName;
  document.getElementById('rector-name-display').innerText = AppState.rectorName;
  document.getElementById('footer-inst-text').innerText = `${AppState.universityName} • ${AppState.agencyName}`;

  // Ayarlar Form Alanlarını Doldur
  document.getElementById('settings-api-key').value = AppState.apiKey;
  document.getElementById('settings-university-name').value = AppState.universityName;
  document.getElementById('settings-agency-name').value = AppState.agencyName;
  document.getElementById('settings-rector-name').value = AppState.rectorName;
  document.getElementById('settings-city-name').value = AppState.cityName;
  document.getElementById('settings-portal-url').value = AppState.portalUrl;

  // Banner Durumu
  if (AppState.apiKey && AppState.apiKey.trim().length > 5) {
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

  const cleanId = id.replace('models/', '').trim();
  const idx = AppState.models.findIndex(m => m.id === cleanId);
  if (idx >= 0) {
    AppState.models[idx] = { ...AppState.models[idx], name, desc };
    showToast(`'${name}' modeli güncellendi.`, 'success');
  } else {
    AppState.models.push({ id: cleanId, name, desc, isCustom: true });
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
        const cleanM = mId.replace('models/', '').trim();
        if (!AppState.models.some(m => m.id === cleanM)) {
          AppState.models.push({
            id: cleanM,
            name: cleanM.replace(/-/g, ' ').toUpperCase(),
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
  const uni = document.getElementById('settings-university-name').value.trim() || 'XXXX Üniversitesi';
  const agency = document.getElementById('settings-agency-name').value.trim() || 'XXX Ajans';
  const rector = document.getElementById('settings-rector-name').value.trim() || 'Prof. Dr. XXXX YYYY';
  const city = document.getElementById('settings-city-name').value.trim() || 'İZMİR';
  const portal = document.getElementById('settings-portal-url').value.trim() || 'www.xxxajans.com';

  AppState.apiKey = key;
  AppState.universityName = uni;
  AppState.agencyName = agency;
  AppState.rectorName = rector;
  AppState.cityName = city;
  AppState.portalUrl = portal;

  AppState.moduleModels = {
    global: document.getElementById('settings-global-model').value,
    audio: document.getElementById('settings-audio-model').value,
    news: document.getElementById('settings-news-model').value,
    tv: document.getElementById('settings-tv-model').value,
    editorial: document.getElementById('settings-editorial-model').value
  };

  localStorage.setItem('habercim_api_key', AppState.apiKey);
  localStorage.setItem('habercim_university_name', AppState.universityName);
  localStorage.setItem('habercim_agency_name', AppState.agencyName);
  localStorage.setItem('habercim_rector_name', AppState.rectorName);
  localStorage.setItem('habercim_city_name', AppState.cityName);
  localStorage.setItem('habercim_portal_url', AppState.portalUrl);
  localStorage.setItem('habercim_module_models', JSON.stringify(AppState.moduleModels));

  initUI();
  renderModelDropdowns();
  showToast('Tüm kurumsal parametreler ve ayarlar kaydedildi!', 'success');
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
      btn.classList.add('bg-red-600', 'recording-pulse');
      btn.innerHTML = '<i class="fa-solid fa-stop text-3xl text-white"></i>';
      statusText.innerText = 'Canlı Ses Kaydediliyor (Durdurmak için dokunun)...';

      AppState.recording.timerInterval = setInterval(() => {
        AppState.recording.seconds++;
        const mins = String(Math.floor(AppState.recording.seconds / 60)).padStart(2, '0');
        const secs = String(AppState.recording.seconds % 60).padStart(2, '0');
        timerText.innerText = `${mins}:${secs}`;
      }, 1000);

    } catch (err) {
      showToast(`Mikrofon erişim hatası: ${err.message}`, 'error');
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

  showToast(`'${file.name}' ses dosyası yüklendi.`, 'success');
}

function clearRecordedAudio() {
  AppState.recording.audioBlob = null;
  AppState.recording.audioBase64 = null;
  document.getElementById('audio-playback').src = '';
  document.getElementById('audio-preview-container').classList.add('hidden');
  document.getElementById('audio-file-input').value = '';
  document.getElementById('record-timer').innerText = '00:00';
  document.getElementById('record-status').innerText = 'Canlı Kayıt İçin Dokunun';
  showToast('Ses temizlendi.', 'info');
}

async function processAudioTranscription() {
  if (!AppState.apiKey) {
    showToast('Lütfen önce Ayarlar bölümünden Gemini API Anahtarınızı girin.', 'warning');
    switchView('settings');
    return;
  }

  if (!AppState.recording.audioBase64) {
    showToast('Lütfen önce canlı ses kaydedin veya bir ses dosyası yükleyin.', 'warning');
    return;
  }

  const model = document.getElementById('audio-model-select').value;
  const btn = document.getElementById('btn-process-audio');
  const resultContainer = document.getElementById('audio-result-container');
  const resultText = document.getElementById('audio-result-text');

  btn.disabled = true;
  btn.innerHTML = '<i class="fa-solid fa-spinner fa-spin"></i> Yapay Zeka Çözümlüyor...';
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
    tubitak: `${AppState.universityName} Kimya Bölümü öğretim üyelerinin hazırladığı kanser araştırmaları projesi TÜBİTAK 1001 programı kapsamında 3.5 milyon TL destek almaya hak kazandı.`,
    akademik: `${AppState.universityName} Kültür Merkezinde 2026-2027 Akademik Yılı Açılış Töreni gerçekleştirildi. Törende araştırma üniversitesi hedefleri ve yeni projeler paylaşıldı.`,
    green: `${AppState.universityName}, GreenMetric dünya yeşil kampüs sıralamasında derecesini korudu. Güneş enerjisi ve sıfır atık projeleri sergilendi.`
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
  btn.innerHTML = '<i class="fa-solid fa-spinner fa-spin"></i> Kurumsal Formatta Yazılıyor...';
  resultContainer.classList.add('hidden');

  try {
    const res = await fetch('/api/generate-news', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        api_key: AppState.apiKey,
        raw_text: rawText,
        reference_url: url,
        university_name: AppState.universityName,
        agency_name: AppState.agencyName,
        rector_name: AppState.rectorName,
        city_name: AppState.cityName,
        portal_url: AppState.portalUrl,
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
      showToast('Kurumsal haber başarıyla hazırlandı!', 'success');
      resultContainer.scrollIntoView({ behavior: 'smooth' });
    } else {
      showToast(data.error || 'Haber üretilemedi.', 'error');
    }
  } catch (err) {
    showToast(`Hata: ${err.message}`, 'error');
  } finally {
    btn.disabled = false;
    btn.innerHTML = '<i class="fa-solid fa-newspaper"></i> 📰 Haberi Oluştur (Kurumsal Format)';
  }
}

function sendToNewsWriter() {
  const audioText = document.getElementById('audio-raw-text').value;
  if (!audioText) return;
  document.getElementById('news-raw-text').value = audioText;
  switchView('news');
  showToast('🎙️ 1. Adım ➔ Deşifre metni Haber Yazarına aktarıldı.', 'success');
}

function sendToEditorialCheck() {
  const newsText = document.getElementById('news-raw-result').value;
  if (!newsText) {
    showToast('Lütfen önce bir haber oluşturun.', 'warning');
    return;
  }
  document.getElementById('editorial-raw-text').value = newsText;
  switchView('editorial');
  showToast('📰 2. Adım ➔ Haber metni Editoryal Denetime aktarıldı.', 'success');
}

function sendToTvFromEditorial() {
  const editedText = document.getElementById('editorial-edited-raw').value;
  const originalText = document.getElementById('editorial-raw-text').value;
  const targetText = (editedText && editedText.trim().length > 10) ? editedText : originalText;

  if (!targetText) {
    showToast('Aktarılacak haber metni bulunamadı.', 'warning');
    return;
  }
  document.getElementById('tv-raw-text').value = targetText;
  switchView('tv');
  showToast('🔍 3. Adım ➔ Düzeltilmiş haber TV Bülteni & Prompter modülüne aktarıldı.', 'success');
}

// ---------------------------------------------------------
// 3. TV HABER FORMATI MODÜLÜ
// ---------------------------------------------------------
async function convertToTvFormat() {
  if (!AppState.apiKey) {
    showToast('Lütfen önce Ayarlar bölümünden Gemini API Anahtarınızı girin.', 'warning');
    switchView('settings');
    return;
  }

  const rawText = document.getElementById('tv-raw-text').value.trim();
  const hasVideo = document.getElementById('tv-has-video').checked;
  const isPhonetic = document.getElementById('tv-is-phonetic').checked;
  const model = document.getElementById('tv-model-select').value;

  if (!rawText) {
    showToast('Lütfen TV formatına dönüştürülecek bir haber metni girin.', 'warning');
    return;
  }

  const btn = document.getElementById('btn-convert-tv');
  const resultContainer = document.getElementById('tv-result-container');
  const resultText = document.getElementById('tv-result-text');

  btn.disabled = true;
  btn.innerHTML = '<i class="fa-solid fa-spinner fa-spin"></i> TV Bülten Formatına Dönüştürülüyor...';
  resultContainer.classList.add('hidden');

  try {
    const res = await fetch('/api/convert-tv', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        api_key: AppState.apiKey,
        news_text: rawText,
        has_video: hasVideo,
        is_phonetic: isPhonetic,
        university_name: AppState.universityName,
        agency_name: AppState.agencyName,
        rector_name: AppState.rectorName,
        model: model
      })
    });

    const data = await res.json();
    if (data.success) {
      resultText.innerText = data.text;
      document.getElementById('tv-raw-result').value = data.text;
      document.getElementById('tv-used-model').innerText = `Model: ${data.used_model}`;
      resultContainer.classList.remove('hidden');
      showToast('TV bülteni ve spiker metni hazırlandı!', 'success');
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
// 4. EDİTORYAL DENETİM MODÜLÜ (3 KUTU)
// ---------------------------------------------------------
async function checkEditorialQuality() {
  if (!AppState.apiKey) {
    showToast('Lütfen önce Ayarlar bölümünden Gemini API Anahtarınızı girin.', 'warning');
    switchView('settings');
    return;
  }

  const rawText = document.getElementById('editorial-raw-text').value.trim();
  const model = document.getElementById('editorial-model-select').value;

  if (!rawText) {
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
        news_text: rawText,
        university_name: AppState.universityName,
        agency_name: AppState.agencyName,
        rector_name: AppState.rectorName,
        model: model
      })
    });

    const data = await res.json();
    if (data.success) {
      const st = data.structured || {};
      
      document.getElementById('editorial-report-raw').value = st.report || data.text;
      document.getElementById('editorial-report-text').innerHTML = marked.parse(st.report || data.text);

      document.getElementById('editorial-edited-raw').value = st.edited_text || '';
      document.getElementById('editorial-edited-text').innerHTML = marked.parse(st.edited_text || '*Düzeltilmiş metin üretilemedi.*');

      document.getElementById('editorial-changes-raw').value = st.changelog || '';
      document.getElementById('editorial-changes-text').innerHTML = marked.parse(st.changelog || '*Değişiklik maddesi belirtilmedi.*');

      document.getElementById('editorial-used-model').innerText = `Model: ${data.used_model}`;
      resultContainer.classList.remove('hidden');
      showToast('Editoryal denetim ve puanlama tamamlandı!', 'success');
      resultContainer.scrollIntoView({ behavior: 'smooth' });
    } else {
      showToast(data.error || 'Denetim başarısız oldu.', 'error');
    }
  } catch (err) {
    showToast(`Hata: ${err.message}`, 'error');
  } finally {
    btn.disabled = false;
    btn.innerHTML = '<i class="fa-solid fa-check-double"></i> 🔍 Metni Denetle & 100 Üzerinden Puanla';
  }
}

// ---------------------------------------------------------
// 5. GELİŞMİŞ TELEPROMPTER & SES SEÇENEKLERİ (TTS)
// ---------------------------------------------------------
function initTtsVoices() {
  if (!('speechSynthesis' in window)) return;

  const loadVoices = () => {
    const voices = window.speechSynthesis.getVoices();
    AppState.prompter.availableVoices = voices;

    const select = document.getElementById('prompter-voice-select');
    if (!select) return;

    select.innerHTML = '';
    const trVoices = voices.filter(v => v.lang.startsWith('tr') || v.lang.includes('TR'));
    const listToUse = trVoices.length > 0 ? trVoices : voices;

    listToUse.forEach((v, i) => {
      const opt = document.createElement('option');
      opt.value = v.voiceURI;
      opt.textContent = `${v.name} (${v.lang})${v.default ? ' [Varsayılan]' : ''}`;
      select.appendChild(opt);
    });

    if (trVoices.length > 0) {
      AppState.prompter.selectedVoiceURI = trVoices[0].voiceURI;
      select.value = trVoices[0].voiceURI;
    }
  };

  loadVoices();
  window.speechSynthesis.onvoiceschanged = loadVoices;
}

function togglePrompterVoicePanel() {
  const panel = document.getElementById('prompter-voice-panel');
  if (panel) {
    panel.classList.toggle('hidden');
  }
}

function updateTtsRate(val) {
  AppState.prompter.ttsRate = parseFloat(val);
  document.getElementById('prompter-rate-val').innerText = `${val}x`;
  // Eğer seslendirme çalışıyorsa yeniden başlat
  if (AppState.prompter.isSpeaking) {
    stopPrompterSpeech();
    startPrompterSpeech();
  }
}

function updateTtsPitch(val) {
  AppState.prompter.ttsPitch = parseFloat(val);
  document.getElementById('prompter-pitch-val').innerText = val;
}

function updateTtsVolume(val) {
  AppState.prompter.ttsVolume = parseFloat(val);
  const percent = Math.round(val * 100);
  document.getElementById('prompter-vol-val').innerText = `%${percent}`;
}

function openTeleprompter(elementId, title = '📺 Spiker Prompter') {
  const el = document.getElementById(elementId);
  const text = el ? (el.value || el.innerText) : '';

  if (!text || text.trim().length === 0) {
    showToast('Prompter için okunacak bir metin bulunamadı.', 'warning');
    return;
  }

  AppState.prompter.text = text;
  AppState.prompter.title = title;

  document.getElementById('prompter-title').innerText = title;
  document.getElementById('prompter-content').innerText = text;
  document.getElementById('prompter-content').style.fontSize = `${AppState.prompter.fontSize}px`;

  document.getElementById('prompter-modal').classList.remove('hidden');
  document.body.style.overflow = 'hidden';

  resetPrompterScroll();
}

function closeTeleprompter() {
  stopPrompterScroll();
  stopPrompterSpeech();
  document.getElementById('prompter-modal').classList.add('hidden');
  document.body.style.overflow = 'auto';
}

function togglePrompterMirror() {
  AppState.prompter.isMirrored = !AppState.prompter.isMirrored;
  const container = document.getElementById('prompter-content');
  if (AppState.prompter.isMirrored) {
    container.classList.add('prompter-mirrored');
    showToast('Prompter ayna modu açık.', 'info');
  } else {
    container.classList.remove('prompter-mirrored');
    showToast('Prompter ayna modu kapalı.', 'info');
  }
}

function changePrompterFontSize(delta) {
  AppState.prompter.fontSize = Math.max(18, Math.min(60, AppState.prompter.fontSize + delta));
  document.getElementById('prompter-content').style.fontSize = `${AppState.prompter.fontSize}px`;
}

function changePrompterSpeed(delta) {
  AppState.prompter.speed = Math.max(0.5, Math.min(10, AppState.prompter.speed + delta));
  document.getElementById('prompter-speed-label').innerText = `${AppState.prompter.speed.toFixed(1)}x`;
}

function togglePrompterScroll() {
  if (AppState.prompter.isPlaying) {
    stopPrompterScroll();
  } else {
    startPrompterCountdown();
  }
}

function startPrompterCountdown() {
  const cd = document.getElementById('prompter-countdown');
  cd.classList.remove('hidden');
  let count = 3;
  cd.innerText = count;

  const timer = setInterval(() => {
    count--;
    if (count > 0) {
      cd.innerText = count;
    } else {
      clearInterval(timer);
      cd.classList.add('hidden');
      startPrompterScroll();
    }
  }, 800);
}

function startPrompterScroll() {
  AppState.prompter.isPlaying = true;
  const btn = document.getElementById('btn-prompter-play');
  btn.innerHTML = '<i class="fa-solid fa-pause"></i> Duraklat';
  btn.classList.remove('bg-[#00A3E0]');
  btn.classList.add('bg-amber-600');

  const scrollContainer = document.getElementById('prompter-scroll-container');
  clearInterval(AppState.prompter.scrollInterval);

  AppState.prompter.scrollInterval = setInterval(() => {
    scrollContainer.scrollTop += AppState.prompter.speed * 1.5;
    if (scrollContainer.scrollTop + scrollContainer.clientHeight >= scrollContainer.scrollHeight) {
      stopPrompterScroll();
    }
  }, 30);
}

function stopPrompterScroll() {
  AppState.prompter.isPlaying = false;
  clearInterval(AppState.prompter.scrollInterval);
  const btn = document.getElementById('btn-prompter-play');
  if (btn) {
    btn.innerHTML = '<i class="fa-solid fa-play"></i> Kaydır';
    btn.classList.remove('bg-amber-600');
    btn.classList.add('bg-[#00A3E0]');
  }
}

function resetPrompterScroll() {
  stopPrompterScroll();
  const scrollContainer = document.getElementById('prompter-scroll-container');
  if (scrollContainer) scrollContainer.scrollTop = 0;
}

// TTS Sesli Okuma
function togglePrompterSpeech() {
  if (AppState.prompter.isSpeaking) {
    stopPrompterSpeech();
  } else {
    startPrompterSpeech();
  }
}

function startPrompterSpeech() {
  if (!('speechSynthesis' in window)) {
    showToast('Tarayıcınız sesli okumayı (TTS) desteklemiyor.', 'error');
    return;
  }

  const text = AppState.prompter.text;
  if (!text) return;

  window.speechSynthesis.cancel();

  // Yıldız ve parantez temizliği
  const cleanSpeechText = text
    .replace(/\*\*/g, '')
    .replace(/#/g, '')
    .replace(/KJ:.*?\n/g, '')
    .replace(/CAM:/g, '')
    .replace(/SES:/g, '')
    .replace(/Video/g, '')
    .trim();

  const utterance = new SpeechSynthesisUtterance(cleanSpeechText);
  utterance.lang = 'tr-TR';
  utterance.rate = AppState.prompter.ttsRate;
  utterance.pitch = AppState.prompter.ttsPitch;
  utterance.volume = AppState.prompter.ttsVolume;

  // Seçilen ses
  const voiceSelect = document.getElementById('prompter-voice-select');
  if (voiceSelect && voiceSelect.value) {
    const chosen = AppState.prompter.availableVoices.find(v => v.voiceURI === voiceSelect.value);
    if (chosen) utterance.voice = chosen;
  }

  utterance.onstart = () => {
    AppState.prompter.isSpeaking = true;
    const btn = document.getElementById('btn-prompter-tts');
    btn.innerHTML = '<i class="fa-solid fa-volume-xmark"></i> <span>Sustur</span>';
    btn.classList.add('bg-rose-700');

    // Prompter kaydırmayı konuşma hızıyla başlat
    if (!AppState.prompter.isPlaying) {
      startPrompterScroll();
    }
  };

  utterance.onend = () => stopPrompterSpeech();
  utterance.onerror = () => stopPrompterSpeech();

  window.speechSynthesis.speak(utterance);
}

function stopPrompterSpeech() {
  if ('speechSynthesis' in window) {
    window.speechSynthesis.cancel();
  }
  AppState.prompter.isSpeaking = false;
  const btn = document.getElementById('btn-prompter-tts');
  if (btn) {
    btn.innerHTML = '<i class="fa-solid fa-volume-high"></i> <span>Seslendir (TTS)</span>';
    btn.classList.remove('bg-rose-700');
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
        is_tv: isTv,
        university_name: AppState.universityName,
        agency_name: AppState.agencyName
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
