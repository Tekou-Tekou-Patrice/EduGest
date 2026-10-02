/**
 * EDUGUEST SIA - Frontend Application Logic
 * Connected to Spring Boot Backend API (port 8003)
 */

// ==========================================================================
// CONFIGURATION & GLOBAL STATE
// ==========================================================================

const State = {
  apiBaseUrl: localStorage.getItem('edugest_api_url') || (window.location.port === '8003' ? window.location.origin : 'http://localhost:8003'),
  activeSchoolId: localStorage.getItem('edugest_active_school_id') || '',
  activeTab: 'dashboard',
  isOnline: false,
  schools: [],
  students: [],
  teachers: [],
  classrooms: [],
  payments: [],
  expenses: [],
  absences: [],
  sanctions: [],
  users: [],
  paymentMethods: [],
  promotions: [],
  adminSchools: [],
  expiringSubscriptions: [],
  platformArchiveCode: '',
  stats: {
    totalSchools: 0,
    activeSchools: 0,
    totalStudents: 0,
    totalTeachers: 0,
    totalClassrooms: 0,
    totalUsers: 0,
    totalPayments: 0
  }
};

if (State.apiBaseUrl.includes('onrender.com')) {
  State.apiBaseUrl = 'http://localhost:8003';
  localStorage.setItem('edugest_api_url', State.apiBaseUrl);
}

function getDefaultAdminConfig() {
  return {
    schools: [
      {
        id: 'school-001',
        name: 'École de l’Excellence',
        status: 'active',
        founderName: 'M. Ibrahima Diop',
        founderPhone: '+221 77 123 45 67',
        whatsapp: '+221 77 123 45 67',
        subscription: 'Premium',
        city: 'Dakar'
      },
      {
        id: 'school-002',
        name: 'Collège Saint Martin',
        status: 'suspended',
        founderName: 'Mme Awa Sall',
        founderPhone: '+221 76 654 32 10',
        whatsapp: '+221 76 654 32 10',
        subscription: 'Basic',
        city: 'Thiès'
      },
      {
        id: 'school-003',
        name: 'Complexe Scolaire Bintou',
        status: 'active',
        founderName: 'M. Cheikh Ndoye',
        founderPhone: '+221 70 987 65 43',
        whatsapp: '+221 70 987 65 43',
        subscription: 'Pro',
        city: 'Saint-Louis'
      }
    ],
    paymentMethods: [
      {
        id: 'mtn',
        label: 'MTN Mobile Money',
        number: '+221 77 000 00 00',
        accountHolder: 'EduGuest',
        status: 'active'
      },
      {
        id: 'orange',
        label: 'Orange Money',
        number: '+221 76 000 00 00',
        accountHolder: 'EduGuest',
        status: 'active'
      }
    ],
    promotions: [
      {
        id: 'promo-1',
        title: 'Offre de lancement',
        description: '1 mois offert pour les nouveaux établissements.',
        discountPct: 20,
        status: 'active'
      },
      {
        id: 'promo-2',
        title: 'Pack école complète',
        description: 'Réduction sur les abonnements premium pour 3 écoles.',
        discountPct: 15,
        status: 'inactive'
      },
      {
        id: 'promo-3',
        title: 'Retour de l’année',
        description: 'Promotion spéciale pour la reprise des classes.',
        discountPct: 10,
        status: 'active'
      }
    ]
  };
}

// ==========================================================================
// HTTP API CLIENT (FETCH WRAPPER)
// ==========================================================================

async function apiRequest(endpoint, options = {}) {
  const url = `${State.apiBaseUrl}${endpoint}`;
  const headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    ...(localStorage.getItem('edugest_admin_token')
      ? { 'Authorization': 'Bearer ' + localStorage.getItem('edugest_admin_token') }
      : {}),
    ...(options.headers || {})
  };

  // Attach school context if selected
  if (State.activeSchoolId && !endpoint.startsWith('/api/schools')) {
    headers['X-School-Id'] = State.activeSchoolId;
  }

  try {
    const startTime = performance.now();
    const response = await fetch(url, {
      ...options,
      headers
    });
    const endTime = performance.now();
    const latency = Math.round(endTime - startTime);

    updateServerStatus(true, latency);

    if (!response.ok) {
      let errorMsg = `Erreur HTTP ${response.status}`;
      try {
        const errorData = await response.json();
        if (errorData && errorData.message) {
          errorMsg = errorData.message;
        }
      } catch (_) {}
      throw new Error(errorMsg);
    }

    if (response.status === 204) {
      return null;
    }

    return await response.json();
  } catch (error) {
    if (error.name === 'TypeError' && error.message.includes('fetch')) {
      updateServerStatus(false);
      throw new Error('Problème de réseau, vérifiez votre accès à Internet.');
    }
    throw error;
  }
}

function updatePlatformAuthButton() {
  const button = document.getElementById('platform-auth-button');
  if (button) button.textContent = localStorage.getItem('edugest_admin_token')
    ? 'Déconnexion propriétaire'
    : 'Connexion propriétaire';
}

function togglePlatformAdminAuth() {
  if (!localStorage.getItem('edugest_admin_token')) {
    document.getElementById('platform-admin-login-error').textContent = '';
    openModal('modal-platform-admin-login');
    return;
  }
  localStorage.removeItem('edugest_admin_token');
  State.platformArchiveCode = '';
  document.getElementById('archive-school-code').value = '';
  updatePlatformAuthButton();
  document.getElementById('platform-archives-list').innerHTML =
    '<div class="table-empty">Connectez-vous au compte propriétaire pour consulter les archives.</div>';
  document.getElementById('platform-archives-status').textContent = '';
}

async function handlePlatformAdminLogin(event) {
  event.preventDefault();
  const error = document.getElementById('platform-admin-login-error');
  const username = document.getElementById('platform-admin-username').value.trim();
  const password = document.getElementById('platform-admin-password').value;
  error.textContent = '';
  try {
    const result = await apiRequest('/api/users/login', {
      method: 'POST',
      body: JSON.stringify({ username, password })
    });
    if (!result || !result.token) throw new Error('La réponse de connexion ne contient pas de jeton.');
    localStorage.setItem('edugest_admin_token', result.token);
    await apiRequest('/api/platform-admin/access');
    closeModal('modal-platform-admin-login');
    document.getElementById('platform-admin-password').value = '';
    updatePlatformAuthButton();
    showToast('Compte propriétaire connecté.', 'success');
  } catch (loginError) {
    localStorage.removeItem('edugest_admin_token');
    updatePlatformAuthButton();
    error.textContent = loginError.message;
  }
}

async function loadPlatformArchives() {
  const schoolId = State.activeSchoolId;
  const privateCode = document.getElementById('archive-school-code').value.trim();
  const status = document.getElementById('platform-archives-status');
  const list = document.getElementById('platform-archives-list');
  if (!localStorage.getItem('edugest_admin_token')) {
    status.textContent = 'Connectez-vous au compte propriétaire pour continuer.';
    return;
  }
  if (!schoolId) {
    status.textContent = 'Sélectionnez une école dans la liste du haut.';
    return;
  }
  if (!privateCode) {
    status.textContent = 'Saisissez le code privé de cette école.';
    return;
  }
  State.platformArchiveCode = privateCode;
  status.textContent = 'Chargement des récapitulatifs...';
  list.innerHTML = '<div class="table-empty">Chargement...</div>';
  try {
    const headers = { 'X-School-Private-Code': privateCode };
    const years = await apiRequest(
      `/api/platform-admin/schools/${encodeURIComponent(schoolId)}/years/recaps`,
      { headers }
    );
    if (!Array.isArray(years) || years.length === 0) {
      list.innerHTML = '<div class="table-empty">Aucune année clôturée pour cette école.</div>';
      status.textContent = 'Chargement terminé.';
      return;
    }
    const rows = await Promise.all(years.map(async year => {
      const files = await apiRequest(
        `/api/platform-admin/schools/${encodeURIComponent(schoolId)}/years/${encodeURIComponent(year.id)}/archives`,
        { headers }
      );
      return { year, files: Array.isArray(files) ? files : [] };
    }));
    const labels = {
      year_recap: 'Récapitulatif annuel',
      bulletins: 'Bulletins',
      receipts: 'Reçus',
      year_data: 'Sauvegarde complète compressée'
    };
    list.innerHTML = rows.map(({ year, files }) => `
      <article class="school-card">
        <div class="school-card-header">
          <div class="school-card-meta">
            <h4>Année ${escapeHtml(year.label || '')}</h4>
            <span>${escapeHtml(year.schoolName || '')}</span>
          </div>
          <div class="school-card-icon">📚</div>
        </div>
        <div class="school-card-body">
          ${Object.entries(labels).map(([type, label]) => files.includes(type)
          ? `<button class="btn btn-secondary" onclick="downloadPlatformArchive('${escapeHtml(schoolId)}','${escapeHtml(year.id)}','${type}')">Télécharger ${label} (${type === 'year_data' ? '.json.gz' : 'PDF'})</button>`
          : `<div class="meta-row"><span>${label}</span><span>Fichier non disponible</span></div>`).join('')}
        ${files.includes('data_purged') ? '<div class="meta-row"><strong>Données annuelles supprimées de la base</strong></div>' : ''}
        </div>
      </article>
    `).join('');
    status.textContent = `${rows.length} année(s) clôturée(s).`;
  } catch (archiveError) {
    State.platformArchiveCode = '';
    list.innerHTML = '<div class="table-empty">Impossible de charger les archives.</div>';
    status.textContent = archiveError.message;
    if (archiveError.message.includes('propriétaire')) {
      localStorage.removeItem('edugest_admin_token');
      updatePlatformAuthButton();
    }
  }
}

async function downloadPlatformArchive(schoolId, yearId, type) {
  const headers = {
    'Authorization': 'Bearer ' + localStorage.getItem('edugest_admin_token'),
    'X-School-Private-Code': State.platformArchiveCode
  };
  const endpoint = `/api/platform-admin/schools/${encodeURIComponent(schoolId)}/years/${encodeURIComponent(yearId)}/archives/${encodeURIComponent(type)}`;
  try {
    const response = await fetch(`${State.apiBaseUrl}${endpoint}`, { headers });
    if (!response.ok) {
      let message = `Erreur HTTP ${response.status}`;
      try {
        const body = await response.json();
        if (body && body.message) message = body.message;
      } catch (_) {}
      throw new Error(message);
    }
    const objectUrl = URL.createObjectURL(await response.blob());
    const link = document.createElement('a');
    link.href = objectUrl;
    link.download = `${yearId}_${type}${type === 'year_data' ? '.json.gz' : '.pdf'}`;
    link.click();
    setTimeout(() => URL.revokeObjectURL(objectUrl), 1000);
  } catch (error) {
    showToast(`Téléchargement impossible : ${error.message}`, 'error');
  }
}

// ==========================================================================
// SERVER STATUS & HEALTH CHECK
// ==========================================================================

function updateServerStatus(online, latency = 0) {
  State.isOnline = online;
  const dot = document.getElementById('server-status-dot');
  const text = document.getElementById('server-status-text');

  if (online) {
    dot.className = 'status-dot online';
    text.textContent = `En ligne (${latency}ms)`;
  } else {
    dot.className = 'status-dot offline';
    text.textContent = 'Backend Hors Ligne';
  }
}

async function checkBackendHealth() {
  try {
    await apiRequest('/api/schools');
  } catch (e) {
    updateServerStatus(false);
  }
}

// ==========================================================================
// NOTIFICATION TOAST SYSTEM
// ==========================================================================

function showToast(message, type = 'info') {
  const container = document.getElementById('toast-container');
  const toast = document.createElement('div');
  toast.className = `toast toast-${type}`;

  const icons = {
    success: '✅',
    error: '❌',
    info: 'ℹ️',
    warning: '⚠️'
  };

  toast.innerHTML = `
    <span class="toast-icon">${icons[type] || 'ℹ️'}</span>
    <span style="flex: 1;">${escapeHtml(message)}</span>
    <button style="background:none;border:none;color:var(--text-dim);cursor:pointer;" onclick="this.parentElement.remove()">✕</button>
  `;

  container.appendChild(toast);

  setTimeout(() => {
    toast.style.opacity = '0';
    toast.style.transform = 'translateY(10px)';
    toast.style.transition = 'all 0.3s ease';
    setTimeout(() => toast.remove(), 300);
  }, 4500);
}

function escapeHtml(str) {
  if (str == null) return '';
  return String(str)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#039;');
}

// ==========================================================================
// MODAL MANAGEMENT
// ==========================================================================

function openModal(modalId) {
  const modal = document.getElementById(modalId);
  if (modal) {
    modal.classList.add('open');
    populateModalSelects();
  }
}

function closeModal(modalId) {
  const modal = document.getElementById(modalId);
  if (modal) {
    modal.classList.remove('open');
  }
}

// Close modal on backdrop click
document.addEventListener('click', (e) => {
  if (e.target.classList.contains('modal-backdrop')) {
    e.target.classList.remove('open');
  }
});

function populateModalSelects() {
  // Populate classrooms in student modal
  const studentClassSelect = document.getElementById('student-classroom-select');
  if (studentClassSelect && State.classrooms.length > 0) {
    const currentVal = studentClassSelect.value;
    studentClassSelect.innerHTML = '<option value="">Sélectionner une classe</option>' +
      State.classrooms.map(c => `<option value="${escapeHtml(c.name)}">${escapeHtml(c.name)}</option>`).join('');
    studentClassSelect.value = currentVal;
  }

  // Populate students in payment modal
  const paymentStudentSelect = document.getElementById('payment-student-select');
  if (paymentStudentSelect && State.students.length > 0) {
    const currentVal = paymentStudentSelect.value;
    paymentStudentSelect.innerHTML = '<option value="">Sélectionner un élève</option>' +
      State.students.map(s => `<option value="${s.id}">${escapeHtml(s.firstName)} ${escapeHtml(s.lastName)} (${escapeHtml(s.className || 'Sans classe')})</option>`).join('');
    paymentStudentSelect.value = currentVal;
  }

  // Populate founder in school modal
  const founderSelect = document.getElementById('school-founder-select');
  if (founderSelect && State.users.length > 0) {
    founderSelect.innerHTML = '<option value="">Aucun ou créer sans fondateur direct</option>' +
      State.users.map(u => `<option value="${u.id}">${escapeHtml(u.fullName || u.username)} (${u.role || 'USER'})</option>`).join('');
  }
}

// ==========================================================================
// DATA LOADERS & DATA SYNC
// ==========================================================================

async function loadAllData() {
  await Promise.allSettled([
    loadStats(),
    loadSchools(),
    loadExpiringSubscriptions(),
    loadSaasPaymentMethods(),
    loadStudents(),
    loadTeachers(),
    loadClassrooms(),
    loadFinances(),
    loadDiscipline(),
    loadUsers()
  ]);
  loadAdminConfig();
  updateSchoolSelectorDropdown();
  updateSidebarActiveSchool();
}

async function loadSaasPaymentMethods() {
  try {
    const settings = await apiRequest('/api/saas-settings');
    State.paymentMethods = [
      { id: 'mtn', label: 'MTN Mobile Money', number: settings.mtnNumber || '', accountHolder: settings.mtnName || '', status: 'active' },
      { id: 'orange', label: 'Orange Money', number: settings.orangeNumber || '', accountHolder: settings.orangeName || '', status: 'active' }
    ];
    renderAdminPortal();
  } catch (error) {
    console.error('Failed to load SaaS payment methods:', error);
    const fallback = getDefaultAdminConfig();
    State.paymentMethods = fallback.paymentMethods;
    renderAdminPortal();
  }
}

async function loadStats() {
  try {
    const stats = await apiRequest('/api/schools/stats');
    if (stats) {
      State.stats = stats;
      renderStats();
    }
  } catch (e) {
    console.warn('Stats endpoint fallback:', e);
  }
}

async function loadSchools() {
  try {
    let list = [];
    try {
      list = await apiRequest('/api/schools/all');
    } catch (_) {
      const memberships = await apiRequest('/api/schools');
      list = (memberships || []).map(m => ({
        id: m.schoolId || m.id,
        name: m.schoolName || m.name,
        code: m.schoolCode || m.code,
        active: m.active !== false
      }));
    }

    State.schools = Array.isArray(list) ? list.map(mapBackendSchool) : [];
    State.adminSchools = State.schools;
    saveAdminConfig();
    renderSchools();
    updateSchoolCounts();
  } catch (error) {
    console.error('Failed to load schools:', error);
  }
}

async function loadExpiringSubscriptions() {
  try {
    const schools = await apiRequest('/api/schools/expiring-soon');
    State.expiringSubscriptions = Array.isArray(schools) ? schools : [];
    renderExpiringSubscriptions();
  } catch (error) {
    console.error('Failed to load expiring subscriptions:', error);
    State.expiringSubscriptions = [];
    renderExpiringSubscriptions();
  }
}

async function loadStudents() {
  try {
    const list = await apiRequest('/api/scolarite/students');
    State.students = Array.isArray(list) ? list : [];
    renderStudents();
  } catch (error) {
    console.error('Failed to load students:', error);
  }
}

async function loadTeachers() {
  try {
    const list = await apiRequest('/api/scolarite/teachers');
    State.teachers = Array.isArray(list) ? list : [];
    renderTeachers();
  } catch (error) {
    console.error('Failed to load teachers:', error);
  }
}

async function loadClassrooms() {
  try {
    const list = await apiRequest('/api/scolarite/classrooms');
    State.classrooms = Array.isArray(list) ? list : [];
    renderClassrooms();
  } catch (error) {
    console.error('Failed to load classrooms:', error);
  }
}

async function loadFinances() {
  try {
    const [payments, expenses] = await Promise.all([
      apiRequest('/api/finance/payments').catch(() => []),
      apiRequest('/api/finance/expenses').catch(() => [])
    ]);

    State.payments = Array.isArray(payments) ? payments : [];
    State.expenses = Array.isArray(expenses) ? expenses : [];
    renderFinances();
  } catch (error) {
    console.error('Failed to load finances:', error);
  }
}

async function loadDiscipline() {
  try {
    const [absences, sanctions] = await Promise.all([
      apiRequest('/api/discipline/absences').catch(() => []),
      apiRequest('/api/discipline/sanctions').catch(() => [])
    ]);

    State.absences = Array.isArray(absences) ? absences : [];
    State.sanctions = Array.isArray(sanctions) ? sanctions : [];
    renderDiscipline();
  } catch (error) {
    console.error('Failed to load discipline:', error);
  }
}

async function loadUsers() {
  try {
    const list = await apiRequest('/api/users');
    State.users = Array.isArray(list) ? list : [];
    renderUsers();
  } catch (error) {
    console.error('Failed to load users:', error);
  }
}

function loadAdminConfig() {
  try {
    const raw = localStorage.getItem('edugest_admin_saas');
    if (!raw) {
      State.adminSchools = State.schools;
      State.promotions = getDefaultAdminConfig().promotions;
      renderAdminPortal();
      return;
    }

    const parsed = JSON.parse(raw);
    State.adminSchools = State.schools;
    State.promotions = Array.isArray(parsed.promotions)
      ? parsed.promotions
      : getDefaultAdminConfig().promotions;
    renderAdminPortal();
  } catch (error) {
    console.error('Failed to load admin config:', error);
    const fallback = getDefaultAdminConfig();
    State.adminSchools = fallback.schools;
    State.paymentMethods = fallback.paymentMethods;
    State.promotions = fallback.promotions;
    renderAdminPortal();
  }

}

function mapBackendSchool(school) {
  return {
    ...school,
    id: String(school.id),
    status: school.active === false ? 'suspended' : 'active',
    founderName: school.founderName || 'Non renseigné',
    founderPhone: school.founderPhone || '',
    whatsapp: school.founderPhone || '',
    secretaryName: school.secretaryName || '',
    secretaryPhone: school.secretaryPhone || '',
    subscription: school.planName || 'Standard',
    monthlyPrice: school.monthlyFee || 0,
    subscriptionEnd: school.subscriptionExpiresAt || ''
  };
}

function saveAdminConfig() {
  const payload = {
    schools: State.adminSchools,
    paymentMethods: State.paymentMethods,
    promotions: State.promotions
  };
  localStorage.setItem('edugest_admin_saas', JSON.stringify(payload));
}

function ensureSchoolAdminMetadata(schoolId, schoolName) {
  const existing = State.adminSchools.find(s => String(s.id) === String(schoolId));
  if (existing) return existing;

  const base = {
    id: String(schoolId),
    name: schoolName || 'Nouvelle école',
    status: 'active',
    founderName: 'Non renseigné',
    founderPhone: '',
    whatsapp: '',
    subscription: 'Standard',
    city: ''
  };

  State.adminSchools.push(base);
  saveAdminConfig();
  return base;
}

function renderAdminPortal() {
  const activeSchools = State.adminSchools.filter(s => (s.status || 'active') === 'active').length;
  const suspendedSchools = State.adminSchools.length - activeSchools;

  document.getElementById('admin-active-schools-count').textContent = activeSchools;
  document.getElementById('admin-suspended-schools-count').textContent = suspendedSchools;
  document.getElementById('admin-payment-methods-count').textContent = State.paymentMethods.length;
  document.getElementById('admin-promotion-count').textContent = State.promotions.length;

  const adminSchoolsRoot = document.getElementById('admin-schools-list');
  adminSchoolsRoot.innerHTML = State.adminSchools.map(school => {
    const isActive = (school.status || 'active') === 'active';
    const founderPhone = school.founderPhone || 'Non renseigné';
    const whatsapp = school.whatsapp || founderPhone;

    return `
      <div class="admin-school-card ${isActive ? 'active' : 'suspended'}">
        <div class="admin-school-top">
          <div>
            <h4>${escapeHtml(school.name || 'École')}</h4>
            <small>${escapeHtml(school.subscription || 'Standard')}</small>
          </div>
          <span class="status-pill ${isActive ? 'success' : 'warning'}">${isActive ? 'Active' : 'Suspendue'}</span>
        </div>
        <div class="admin-school-meta">
          <span>Fondateur : <strong>${escapeHtml(school.founderName || 'Non renseigné')}</strong></span>
          <span>Téléphone : <strong>${escapeHtml(founderPhone)}</strong></span>
          <span>Secrétaire : <strong>${escapeHtml(school.secretaryName || 'Non renseigné')}</strong></span>
          <span>Téléphone secrétaire : <strong>${escapeHtml(school.secretaryPhone || 'Non renseigné')}</strong></span>
          <span>Ville : <strong>${escapeHtml(school.city || 'Non renseigné')}</strong></span>
        </div>
        <div class="admin-school-actions">
          <button class="btn btn-sm btn-primary" onclick="toggleAdminSchoolStatus('${school.id}')">${isActive ? 'Suspendre' : 'Activer'}</button>
          <button class="btn btn-sm btn-secondary" onclick="openWhatsApp('${escapeHtml(whatsapp)}')">WhatsApp</button>
        </div>
      </div>
    `;
  }).join('') || '<div class="table-empty">Aucune école à afficher.</div>';

  const paymentRoot = document.getElementById('admin-payment-methods-list');
  paymentRoot.innerHTML = State.paymentMethods.map(method => {
    const active = (method.status || 'active') === 'active';
    return `
      <div class="admin-payment-card">
        <div class="admin-payment-header">
          <strong>${escapeHtml(method.label || 'Paiement')}</strong>
          <span class="status-pill ${active ? 'success' : 'warning'}">${active ? 'Actif' : 'Inactif'}</span>
        </div>
        <p>${escapeHtml(method.number || '')}</p>
        <small>Titulaire : ${escapeHtml(method.accountHolder || '')}</small>
        <button class="btn btn-sm btn-secondary" onclick="openPaymentMethodEditor('${method.id}')">Modifier</button>
      </div>
    `;
  }).join('') || '<div class="table-empty">Aucun numéro enregistré.</div>';

  const promoRoot = document.getElementById('admin-promotions-list');
  promoRoot.innerHTML = State.promotions.map(promo => {
    const active = (promo.status || 'active') === 'active';
    return `
      <div class="admin-promo-card">
        <div class="admin-promo-top">
          <div>
            <h4>${escapeHtml(promo.title || 'Promotion')}</h4>
            <small>${escapeHtml(promo.description || '')}</small>
          </div>
          <span class="status-pill ${active ? 'success' : 'warning'}">${active ? 'Active' : 'Inactive'}</span>
        </div>
        <div class="admin-promo-footer">
          <strong>${Number(promo.discountPct || 0)}%</strong>
          <button class="btn btn-sm btn-secondary" onclick="togglePromotion('${promo.id}')">${active ? 'Désactiver' : 'Activer'}</button>
        </div>
      </div>
    `;
  }).join('') || '<div class="table-empty">Aucune promotion.</div>';

  renderExpiringSubscriptions();
}

function renderExpiringSubscriptions() {
  const root = document.getElementById('admin-expiring-subscriptions');
  if (!root) return;

  if (!State.expiringSubscriptions.length) {
    root.innerHTML = '<div class="table-empty">Aucun abonnement n’expire dans les 7 prochains jours.</div>';
    return;
  }

  root.innerHTML = State.expiringSubscriptions.map(school => {
    const expiry = school.subscriptionExpiresAt
      ? new Date(`${school.subscriptionExpiresAt}T00:00:00`).toLocaleDateString('fr-FR')
      : 'Date inconnue';
    return `
      <div class="admin-school-card subscription-expiring-card">
        <div class="admin-school-top">
          <div>
            <h4>${escapeHtml(school.name || 'École')}</h4>
            <small>Fondateur : ${escapeHtml(school.founderName || 'Non renseigné')}</small>
          </div>
          <span class="status-pill warning">Expire le ${escapeHtml(expiry)}</span>
        </div>
      </div>
    `;
  }).join('');
}

function openWhatsApp(rawNumber) {
  if (!rawNumber) {
    showToast('Aucun numéro WhatsApp disponible.', 'warning');
    return;
  }

  const digits = String(rawNumber).replace(/[^0-9]/g, '');
  if (!digits) {
    showToast('Numéro invalide pour WhatsApp.', 'warning');
    return;
  }

  const url = `https://wa.me/${digits}`;
  window.open(url, '_blank');
}

async function toggleAdminSchoolStatus(schoolId) {
  const school = State.adminSchools.find(s => String(s.id) === String(schoolId));
  if (!school) return;

  try {
    const updatedSchool = await apiRequest(`/api/schools/${encodeURIComponent(schoolId)}/toggle`, {
      method: 'PATCH'
    });
    const isActive = updatedSchool.active !== false;
    school.status = isActive ? 'active' : 'suspended';
    school.name = updatedSchool.name || school.name;
    const backendSchool = State.schools.find(s => String(s.id) === String(schoolId));
    if (backendSchool) backendSchool.active = isActive;

    saveAdminConfig();
    renderAdminPortal();
    showToast(`École ${school.name || 'sélectionnée'} ${isActive ? 'activée' : 'suspendue'}.`, 'success');
  } catch (error) {
    showToast(error.message || "Impossible de modifier l'état de l'école.", 'error');
  }
}

function openPaymentMethodEditor(methodId) {
  const method = State.paymentMethods.find(item => item.id === methodId);
  if (!method) return;

  document.getElementById('payment-method-id').value = method.id;
  document.getElementById('payment-method-label').value = method.label || '';
  document.getElementById('payment-method-number').value = method.number || '';
  document.getElementById('payment-method-holder').value = method.accountHolder || '';
  document.getElementById('payment-method-status').value = (method.status || 'active');

  openModal('modal-admin-payment');
}

async function handleSavePaymentMethod(event) {
  event.preventDefault();

  const id = document.getElementById('payment-method-id').value || `payment-${Date.now()}`;
  const label = document.getElementById('payment-method-label').value.trim();
  const number = document.getElementById('payment-method-number').value.trim();
  const holder = document.getElementById('payment-method-holder').value.trim();
  const status = document.getElementById('payment-method-status').value;

  const payload = { id, label, number, accountHolder: holder, status };
  if (id !== 'mtn' && id !== 'orange') {
    showToast('Seuls les numéros MTN et Orange peuvent être configurés ici.', 'warning');
    return;
  }

  try {
    const settings = await apiRequest('/api/saas-settings');
    if (id === 'mtn') {
      settings.mtnNumber = number;
      settings.mtnName = holder;
    } else {
      settings.orangeNumber = number;
      settings.orangeName = holder;
    }
    await apiRequest('/api/saas-settings', {
      method: 'PUT',
      body: JSON.stringify(settings)
    });
    const index = State.paymentMethods.findIndex(item => item.id === id);
    if (index >= 0) State.paymentMethods[index] = payload;
    renderAdminPortal();
    closeModal('modal-admin-payment');
    document.getElementById('form-admin-payment').reset();
    showToast('Numéro de paiement enregistré et publié dans l’application.', 'success');
  } catch (error) {
    showToast(error.message || 'Impossible d’enregistrer le numéro.', 'error');
  }
}

function togglePromotion(promoId) {
  const item = State.promotions.find(p => p.id === promoId);
  if (!item) return;

  item.status = (item.status || 'active') === 'active' ? 'inactive' : 'active';
  saveAdminConfig();
  renderAdminPortal();
  showToast(`Promotion ${item.title || 'modifiée'} ${item.status === 'active' ? 'activée' : 'désactivée'}.`, 'info');
}

function handleSavePromotion(event) {
  event.preventDefault();

  const payload = {
    id: `promo-${Date.now()}`,
    title: document.getElementById('promotion-title').value.trim() || 'Nouvelle promotion',
    description: document.getElementById('promotion-description').value.trim() || 'Promotion disponible pour les etablissements.',
    discountPct: Number(document.getElementById('promotion-discount').value || 10),
    status: document.getElementById('promotion-status').value === 'active' ? 'active' : 'inactive'
  };

  State.promotions.push(payload);
  saveAdminConfig();
  renderAdminPortal();
  closeModal('modal-admin-promotion');
  document.getElementById('form-admin-promotion').reset();
  showToast('Promotion ajoutée avec succès.', 'success');
}

// ==========================================================================
// RENDERERS
// ==========================================================================

function updateSchoolCounts() {
  const total = State.schools.length;
  const active = State.schools.filter(s => s.active !== false).length;

  document.getElementById('nav-schools-count').textContent = total;
  document.getElementById('hero-schools-count').textContent = total;
  document.getElementById('dash-schools-count').textContent = total;
  document.getElementById('schools-total-count').textContent = total;
  document.getElementById('dash-active-schools-badge').textContent = `${active} Actives`;
}

function renderStats() {
  document.getElementById('dash-students-count').textContent = State.stats.totalStudents || State.students.length;
  document.getElementById('dash-teachers-count').textContent = State.stats.totalTeachers || State.teachers.length;
  document.getElementById('dash-classrooms-count').textContent = State.stats.totalClassrooms || State.classrooms.length;
  document.getElementById('dash-users-count').textContent = State.stats.totalUsers || State.users.length;
  document.getElementById('dash-payments-count').textContent = State.stats.totalPayments || State.payments.length;

  document.getElementById('nav-students-count').textContent = State.students.length;
  document.getElementById('nav-teachers-count').textContent = State.teachers.length;
  document.getElementById('nav-classes-count').textContent = State.classrooms.length;
  document.getElementById('nav-users-count').textContent = State.users.length;
}

function renderSchools() {
  const gridContainer = document.getElementById('schools-grid-container');
  const dashGridContainer = document.getElementById('dash-schools-grid');

  if (State.schools.length === 0) {
    const emptyHtml = `
      <div class="table-empty" style="grid-column: 1 / -1;">
        <div class="empty-icon">🏫</div>
        <h4>Aucune école disponible</h4>
        <p>Commencez par ajouter votre premier établissement scolaire.</p>
        <button class="btn btn-primary" style="margin-top: 14px;" onclick="openModal('modal-add-school')">➕ Créer une École</button>
      </div>
    `;
    gridContainer.innerHTML = emptyHtml;
    dashGridContainer.innerHTML = emptyHtml;
    return;
  }

  const query = (document.getElementById('search-schools')?.value || '').toLowerCase().trim();
  const statusFilter = document.getElementById('filter-schools-status')?.value || 'all';

  const filtered = State.schools.filter(school => {
    const matchesSearch = !query || 
      (school.name && school.name.toLowerCase().includes(query)) ||
      (school.code && school.code.toLowerCase().includes(query));

    const isActive = school.active !== false;
    const matchesStatus = statusFilter === 'all' || 
      (statusFilter === 'active' && isActive) ||
      (statusFilter === 'inactive' && !isActive);

    return matchesSearch && matchesStatus;
  });

  const generateCardHtml = (school) => {
    const isSelected = String(school.id) === String(State.activeSchoolId);
    const isActive = school.active !== false;
    const dateFormatted = school.createdAt ? new Date(school.createdAt).toLocaleDateString('fr-FR') : 'Date N/D';

    return `
      <div class="school-card ${isSelected ? 'is-active-context' : ''}">
        <div class="school-card-header">
          <div class="school-card-icon">🏫</div>
          <div class="school-card-meta">
            <h4>${escapeHtml(school.name)}</h4>
            <div style="display: flex; gap: 8px; align-items: center; margin-top: 4px;">
              <span class="school-code-tag" onclick="copyToClipboard('${escapeHtml(school.code)}')" title="Cliquer pour copier le code">
                🔑 ${escapeHtml(school.code || 'SANS CODE')}
              </span>
              <span class="pill ${isActive ? 'pill-success' : 'pill-danger'}">
                ${isActive ? 'Active' : 'Inactive'}
              </span>
            </div>
          </div>
        </div>

        <div class="school-card-body">
          <div class="meta-row">
            <span>Identifiant (ID)</span>
            <strong style="color: var(--text-main);">#${school.id}</strong>
          </div>
          <div class="meta-row">
            <span>Créée le</span>
            <span>${dateFormatted}</span>
          </div>
        </div>

        <div class="school-card-footer">
          <button class="btn btn-sm ${isSelected ? 'btn-primary' : 'btn-outline'}" onclick="selectActiveSchool('${school.id}', '${escapeHtml(school.name)}')">
            ${isSelected ? '✓ École Active' : 'Sélectionner'}
          </button>
          <div style="display: flex; gap: 6px;">
            <button class="btn-icon" style="width: 32px; height: 32px;" onclick="openEditSchoolCodeModal('${school.id}', '${escapeHtml(school.name)}', '${escapeHtml(school.code)}')" title="Modifier le Code">✏️</button>
            <button class="btn-icon" style="width: 32px; height: 32px;" onclick="toggleSchoolStatus('${school.id}')" title="Activer / Désactiver">🔄</button>
            <button class="btn-icon" style="width: 32px; height: 32px; color: var(--danger);" onclick="deleteSchool('${school.id}', '${escapeHtml(school.name)}')" title="Supprimer">🗑️</button>
          </div>
        </div>
      </div>
    `;
  };

  gridContainer.innerHTML = filtered.map(generateCardHtml).join('');
  dashGridContainer.innerHTML = State.schools.slice(0, 6).map(generateCardHtml).join('');
}

function renderStudents() {
  const tbody = document.getElementById('students-table-body');
  const countEl = document.getElementById('students-total-count');
  countEl.textContent = State.students.length;

  if (State.students.length === 0) {
    tbody.innerHTML = `<tr><td colspan="8" class="table-empty">Aucun élève enregistré.</td></tr>`;
    return;
  }

  const query = (document.getElementById('search-students')?.value || '').toLowerCase().trim();
  const classFilter = document.getElementById('filter-students-class')?.value || '';

  const filtered = State.students.filter(student => {
    const fullName = `${student.firstName || ''} ${student.lastName || ''}`.toLowerCase();
    const matchesQuery = !query || fullName.includes(query);
    const matchesClass = !classFilter || student.className === classFilter;
    return matchesQuery && matchesClass;
  });

  if (filtered.length === 0) {
    tbody.innerHTML = `<tr><td colspan="8" class="table-empty">Aucun résultat trouvé pour votre recherche.</td></tr>`;
    return;
  }

  tbody.innerHTML = filtered.map(s => `
    <tr>
      <td><strong>#${s.id}</strong></td>
      <td><strong>${escapeHtml(s.firstName)} ${escapeHtml(s.lastName)}</strong></td>
      <td><span class="pill pill-info">${escapeHtml(s.className || 'Non assigné')}</span></td>
      <td>${escapeHtml(s.parentName || '-')}</td>
      <td>${escapeHtml(s.parentPhone || '-')}</td>
      <td>${escapeHtml(s.parentEmail || '-')}</td>
      <td>${s.registrationDate ? new Date(s.registrationDate).toLocaleDateString('fr-FR') : '-'}</td>
      <td>
        <button class="btn btn-sm btn-danger-outline" onclick="deleteStudent(${s.id})">Supprimer</button>
      </td>
    </tr>
  `).join('');

  // Update class filter dropdown
  const classFilterSelect = document.getElementById('filter-students-class');
  const uniqueClasses = [...new Set(State.students.map(s => s.className).filter(Boolean))];
  const currentVal = classFilterSelect.value;
  classFilterSelect.innerHTML = '<option value="">Toutes les classes</option>' +
    uniqueClasses.map(c => `<option value="${escapeHtml(c)}">${escapeHtml(c)}</option>`).join('');
  classFilterSelect.value = currentVal;
}

function renderTeachers() {
  const tbody = document.getElementById('teachers-table-body');
  const countEl = document.getElementById('teachers-total-count');
  countEl.textContent = State.teachers.length;

  if (State.teachers.length === 0) {
    tbody.innerHTML = `<tr><td colspan="6" class="table-empty">Aucun enseignant enregistré.</td></tr>`;
    return;
  }

  const query = (document.getElementById('search-teachers')?.value || '').toLowerCase().trim();
  const filtered = State.teachers.filter(t => {
    const full = `${t.firstName || ''} ${t.lastName || ''} ${t.speciality || ''}`.toLowerCase();
    return !query || full.includes(query);
  });

  tbody.innerHTML = filtered.map(t => `
    <tr>
      <td><strong>#${t.id}</strong></td>
      <td><strong>${escapeHtml(t.firstName)} ${escapeHtml(t.lastName)}</strong></td>
      <td><span class="pill pill-warning">${escapeHtml(t.speciality || 'Général')}</span></td>
      <td>${escapeHtml(t.phone || '-')}</td>
      <td>${escapeHtml(t.email || '-')}</td>
      <td>
        <button class="btn btn-sm btn-danger-outline" onclick="deleteTeacher(${t.id})">Supprimer</button>
      </td>
    </tr>
  `).join('');
}

function renderClassrooms() {
  const tbody = document.getElementById('classrooms-table-body');
  if (State.classrooms.length === 0) {
    tbody.innerHTML = `<tr><td colspan="5" class="table-empty">Aucune classe enregistrée.</td></tr>`;
    return;
  }

  tbody.innerHTML = State.classrooms.map(c => `
    <tr>
      <td><strong>#${c.id}</strong></td>
      <td><strong>${escapeHtml(c.name)}</strong></td>
      <td>${escapeHtml(c.level || c.description || 'Secondaire')}</td>
      <td><span class="pill pill-info">${c.capacity || 40} places</span></td>
      <td>
        <button class="btn btn-sm btn-danger-outline" onclick="deleteClassroom(${c.id})">Supprimer</button>
      </td>
    </tr>
  `).join('');
}

function renderFinances() {
  let totalRev = 0;
  let totalExp = 0;

  const paymentsTbody = document.getElementById('payments-table-body');
  if (State.payments.length === 0) {
    paymentsTbody.innerHTML = `<tr><td colspan="6" class="table-empty">Aucun paiement enregistré.</td></tr>`;
  } else {
    paymentsTbody.innerHTML = State.payments.map(p => {
      const amount = Number(p.amount || 0);
      totalRev += amount;
      return `
        <tr>
          <td><strong>#${p.id}</strong></td>
          <td>${escapeHtml(p.studentName || `Élève #${p.studentId}`)}</td>
          <td><strong style="color: var(--success);">${amount.toLocaleString('fr-FR')} FCFA</strong></td>
          <td><span class="pill pill-success">${escapeHtml(p.type || p.category || 'Scolarité')}</span></td>
          <td>${escapeHtml(p.paymentMethod || 'Espèces')}</td>
          <td>${p.date ? new Date(p.date).toLocaleDateString('fr-FR') : '-'}</td>
        </tr>
      `;
    }).join('');
  }

  const expensesTbody = document.getElementById('expenses-table-body');
  if (State.expenses.length === 0) {
    expensesTbody.innerHTML = `<tr><td colspan="6" class="table-empty">Aucune dépense enregistrée.</td></tr>`;
  } else {
    expensesTbody.innerHTML = State.expenses.map(e => {
      const amount = Number(e.amount || 0);
      totalExp += amount;
      return `
        <tr>
          <td><strong>#${e.id}</strong></td>
          <td><strong>${escapeHtml(e.title || e.description || 'Dépense')}</strong></td>
          <td><span class="pill pill-warning">${escapeHtml(e.category || 'Général')}</span></td>
          <td><strong style="color: var(--danger);">${amount.toLocaleString('fr-FR')} FCFA</strong></td>
          <td>${e.date ? new Date(e.date).toLocaleDateString('fr-FR') : '-'}</td>
          <td>
            <button class="btn btn-sm btn-danger-outline" onclick="deleteExpense(${e.id})">Supprimer</button>
          </td>
        </tr>
      `;
    }).join('');
  }

  const netBalance = Math.max(0, totalRev - totalExp);
  document.getElementById('fin-total-revenue').textContent = `${totalRev.toLocaleString('fr-FR')} FCFA`;
  document.getElementById('fin-total-expenses').textContent = `${totalExp.toLocaleString('fr-FR')} FCFA`;
  document.getElementById('fin-net-balance').textContent = `${netBalance.toLocaleString('fr-FR')} FCFA`;
  document.getElementById('dash-revenue-badge').textContent = `${totalRev.toLocaleString('fr-FR')} FCFA`;
}

function renderDiscipline() {
  const absencesTbody = document.getElementById('absences-table-body');
  if (State.absences.length === 0) {
    absencesTbody.innerHTML = `<tr><td colspan="6" class="table-empty">Aucune absence enregistrée.</td></tr>`;
  } else {
    absencesTbody.innerHTML = State.absences.map(a => `
      <tr>
        <td><strong>#${a.id}</strong></td>
        <td>${escapeHtml(a.studentName || `Élève #${a.studentId}`)}</td>
        <td>${a.date ? new Date(a.date).toLocaleDateString('fr-FR') : '-'}</td>
        <td>${escapeHtml(a.period || a.hours || '1h')}</td>
        <td><span class="pill ${a.justified ? 'pill-success' : 'pill-danger'}">${a.justified ? 'Justifiée' : 'Non justifiée'}</span></td>
        <td>${escapeHtml(a.reason || '-')}</td>
      </tr>
    `).join('');
  }

  const sanctionsTbody = document.getElementById('sanctions-table-body');
  if (State.sanctions.length === 0) {
    sanctionsTbody.innerHTML = `<tr><td colspan="6" class="table-empty">Aucune sanction enregistrée.</td></tr>`;
  } else {
    sanctionsTbody.innerHTML = State.sanctions.map(s => `
      <tr>
        <td><strong>#${s.id}</strong></td>
        <td>${escapeHtml(s.studentName || `Élève #${s.studentId}`)}</td>
        <td><span class="pill pill-danger">${escapeHtml(s.type || s.sanctionType || 'Avertissement')}</span></td>
        <td>${escapeHtml(s.reason || s.description || '-')}</td>
        <td>${s.date ? new Date(s.date).toLocaleDateString('fr-FR') : '-'}</td>
        <td>
          <button class="btn btn-sm btn-danger-outline" onclick="deleteSanction(${s.id})">Supprimer</button>
        </td>
      </tr>
    `).join('');
  }
}

function renderUsers() {
  const tbody = document.getElementById('users-table-body');
  if (State.users.length === 0) {
    tbody.innerHTML = `<tr><td colspan="7" class="table-empty">Aucun utilisateur enregistré.</td></tr>`;
    return;
  }

  tbody.innerHTML = State.users.map(u => `
    <tr>
      <td><strong>#${u.id}</strong></td>
      <td><strong>${escapeHtml(u.fullName || u.username)}</strong></td>
      <td><code>${escapeHtml(u.username)}</code></td>
      <td>${escapeHtml(u.email || '-')}</td>
      <td>${escapeHtml(u.phone || '-')}</td>
      <td><span class="pill pill-info">${escapeHtml(u.role || 'FONDATEUR')}</span></td>
      <td>
        <button class="btn btn-sm btn-danger-outline" onclick="deleteUser(${u.id})">Supprimer</button>
      </td>
    </tr>
  `).join('');
}

// ==========================================================================
// SCHOOL SELECTION & CONTEXT ACTIONS
// ==========================================================================

function selectActiveSchool(schoolId, schoolName) {
  if (State.activeSchoolId === String(schoolId)) {
    State.activeSchoolId = '';
    localStorage.removeItem('edugest_active_school_id');
    showToast('Contexte réinitialisé : Toutes les écoles', 'info');
  } else {
    State.activeSchoolId = String(schoolId);
    localStorage.setItem('edugest_active_school_id', State.activeSchoolId);
    showToast(`École active : ${schoolName}`, 'success');
  }

  updateSchoolSelectorDropdown();
  updateSidebarActiveSchool();
  renderSchools();
  loadAllData();
}

function updateSchoolSelectorDropdown() {
  const select = document.getElementById('header-school-select');
  select.innerHTML = '<option value="">🌐 Toutes les écoles</option>' +
    State.schools.map(s => `<option value="${s.id}" ${String(s.id) === String(State.activeSchoolId) ? 'selected' : ''}>🏫 ${escapeHtml(s.name)}</option>`).join('');
}

function updateSidebarActiveSchool() {
  const nameEl = document.getElementById('sidebar-active-school-name');
  const indicator = document.getElementById('sidebar-indicator');

  if (State.activeSchoolId) {
    const current = State.schools.find(s => String(s.id) === String(State.activeSchoolId));
    nameEl.textContent = current ? current.name : `École #${State.activeSchoolId}`;
    indicator.style.background = 'var(--primary)';
    indicator.style.boxShadow = '0 0 10px var(--primary)';
  } else {
    nameEl.textContent = 'Toutes les écoles';
    indicator.style.background = 'var(--success)';
    indicator.style.boxShadow = '0 0 10px var(--success)';
  }
}

document.getElementById('header-school-select').addEventListener('change', (e) => {
  State.activeSchoolId = e.target.value;
  State.platformArchiveCode = '';
  document.getElementById('archive-school-code').value = '';
  document.getElementById('platform-archives-list').innerHTML =
    '<div class="table-empty">Saisissez le code privé de l’école sélectionnée pour afficher ses archives.</div>';
  document.getElementById('platform-archives-status').textContent = '';
  if (State.activeSchoolId) {
    localStorage.setItem('edugest_active_school_id', State.activeSchoolId);
  } else {
    localStorage.removeItem('edugest_active_school_id');
  }
  updateSidebarActiveSchool();
  renderSchools();
  loadAllData();
});

// ==========================================================================
// CRUD OPERATIONS FOR SCHOOLS
// ==========================================================================

async function handleCreateSchool(e) {
  e.preventDefault();
  const name = document.getElementById('school-name-input').value.trim();
  const founderUserId = document.getElementById('school-founder-select').value;

  if (!name) {
    showToast('Le nom de l\'école est requis.', 'warning');
    return;
  }

  try {
    const payload = {
      name,
      userId: founderUserId ? Number(founderUserId) : null
    };

    const created = await apiRequest('/api/schools', {
      method: 'POST',
      body: JSON.stringify(payload)
    });

    const generatedCode = created && created.code ? ` (Code privé : ${created.code})` : '';
    showToast(`Établissement "${name}" créé avec succès !${generatedCode}`, 'success');
    closeModal('modal-add-school');
    document.getElementById('form-add-school').reset();
    await loadSchools();
    await loadStats();
  } catch (error) {
    showToast(error.message, 'error');
  }
}

function openEditSchoolCodeModal(schoolId, schoolName, currentCode) {
  document.getElementById('edit-code-school-id').value = schoolId;
  document.getElementById('edit-code-school-name').value = schoolName;
  document.getElementById('edit-code-new-code').value = currentCode || '';
  openModal('modal-edit-school-code');
}

async function handleUpdateSchoolCode(e) {
  e.preventDefault();
  const schoolId = document.getElementById('edit-code-school-id').value;
  const newCode = document.getElementById('edit-code-new-code').value.trim().toUpperCase();
  const userId = document.getElementById('edit-code-user-id').value || '1';

  try {
    await apiRequest(`/api/schools/${schoolId}/code?userId=${encodeURIComponent(userId)}&code=${encodeURIComponent(newCode)}`, {
      method: 'PUT'
    });

    showToast(`Code d'accès mis à jour vers : ${newCode}`, 'success');
    closeModal('modal-edit-school-code');
    await loadSchools();
  } catch (error) {
    showToast(error.message, 'error');
  }
}

async function toggleSchoolStatus(schoolId) {
  try {
    await apiRequest(`/api/schools/${schoolId}/toggle`, { method: 'PATCH' });
    showToast('Statut de l\'école modifié.', 'info');
    await loadSchools();
  } catch (error) {
    showToast(error.message, 'error');
  }
}

async function deleteSchool(schoolId, schoolName) {
  if (!confirm(`Êtes-vous sûr de vouloir supprimer l'école "${schoolName}" (#${schoolId}) ?`)) {
    return;
  }

  try {
    await apiRequest(`/api/schools/${schoolId}`, { method: 'DELETE' });
    showToast(`École "${schoolName}" supprimée.`, 'success');
    if (String(State.activeSchoolId) === String(schoolId)) {
      State.activeSchoolId = '';
      localStorage.removeItem('edugest_active_school_id');
      updateSidebarActiveSchool();
    }
    await loadSchools();
    await loadStats();
  } catch (error) {
    showToast(error.message, 'error');
  }
}

function copyToClipboard(text) {
  if (!text) return;
  navigator.clipboard.writeText(text).then(() => {
    showToast(`Code "${text}" copié dans le presse-papiers !`, 'success');
  }).catch(() => {
    showToast(`Code : ${text}`, 'info');
  });
}

// ==========================================================================
// OTHER MODULE CRUD HANDLERS
// ==========================================================================

async function handleCreateStudent(e) {
  e.preventDefault();
  const payload = {
    firstName: document.getElementById('student-first-name').value.trim(),
    lastName: document.getElementById('student-last-name').value.trim(),
    className: document.getElementById('student-classroom-select').value,
    birthDate: document.getElementById('student-birth-date').value || null,
    parentName: document.getElementById('student-parent-name').value.trim() || null,
    parentPhone: document.getElementById('student-parent-phone').value.trim() || null,
    parentEmail: document.getElementById('student-parent-email').value.trim() || null
  };

  try {
    await apiRequest('/api/scolarite/students', {
      method: 'POST',
      body: JSON.stringify(payload)
    });
    showToast('Élève inscrit avec succès !', 'success');
    closeModal('modal-add-student');
    document.getElementById('form-add-student').reset();
    await loadStudents();
    await loadStats();
  } catch (error) {
    showToast(error.message, 'error');
  }
}

async function deleteStudent(id) {
  if (!confirm('Supprimer cet élève ?')) return;
  try {
    await apiRequest(`/api/scolarite/students/${id}`, { method: 'DELETE' });
    showToast('Élève supprimé.', 'success');
    await loadStudents();
  } catch (error) {
    showToast(error.message, 'error');
  }
}

async function handleCreateTeacher(e) {
  e.preventDefault();
  const payload = {
    firstName: document.getElementById('teacher-first-name').value.trim(),
    lastName: document.getElementById('teacher-last-name').value.trim(),
    speciality: document.getElementById('teacher-speciality').value.trim(),
    phone: document.getElementById('teacher-phone').value.trim() || null,
    email: document.getElementById('teacher-email').value.trim() || null
  };

  try {
    await apiRequest('/api/scolarite/teachers', {
      method: 'POST',
      body: JSON.stringify(payload)
    });
    showToast('Enseignant enregistré !', 'success');
    closeModal('modal-add-teacher');
    document.getElementById('form-add-teacher').reset();
    await loadTeachers();
    await loadStats();
  } catch (error) {
    showToast(error.message, 'error');
  }
}

async function deleteTeacher(id) {
  if (!confirm('Supprimer cet enseignant ?')) return;
  try {
    await apiRequest(`/api/scolarite/teachers/${id}`, { method: 'DELETE' });
    showToast('Enseignant supprimé.', 'success');
    await loadTeachers();
  } catch (error) {
    showToast(error.message, 'error');
  }
}

async function handleCreateClassroom(e) {
  e.preventDefault();
  const payload = {
    name: document.getElementById('classroom-name').value.trim(),
    level: document.getElementById('classroom-level').value.trim() || 'Secondaire',
    capacity: Number(document.getElementById('classroom-capacity').value || 40)
  };

  try {
    await apiRequest('/api/scolarite/classrooms', {
      method: 'POST',
      body: JSON.stringify(payload)
    });
    showToast('Classe créée avec succès !', 'success');
    closeModal('modal-add-classroom');
    document.getElementById('form-add-classroom').reset();
    await loadClassrooms();
    await loadStats();
  } catch (error) {
    showToast(error.message, 'error');
  }
}

async function deleteClassroom(id) {
  if (!confirm('Supprimer cette classe ?')) return;
  try {
    await apiRequest(`/api/scolarite/classrooms/${id}`, { method: 'DELETE' });
    showToast('Classe supprimée.', 'success');
    await loadClassrooms();
  } catch (error) {
    showToast(error.message, 'error');
  }
}

async function handleCreatePayment(e) {
  e.preventDefault();
  const payload = {
    studentId: document.getElementById('payment-student-select').value,
    amount: Number(document.getElementById('payment-amount').value),
    paymentMethod: document.getElementById('payment-method').value,
    type: document.getElementById('payment-type').value.trim() || 'Scolarité'
  };

  try {
    await apiRequest('/api/finance/payments', {
      method: 'POST',
      body: JSON.stringify(payload)
    });
    showToast('Paiement enregistré avec succès !', 'success');
    closeModal('modal-add-payment');
    document.getElementById('form-add-payment').reset();
    await loadFinances();
  } catch (error) {
    showToast(error.message, 'error');
  }
}

async function handleCreateExpense(e) {
  e.preventDefault();
  const payload = {
    title: document.getElementById('expense-title').value.trim(),
    amount: Number(document.getElementById('expense-amount').value),
    category: document.getElementById('expense-category').value
  };

  try {
    await apiRequest('/api/finance/expenses', {
      method: 'POST',
      body: JSON.stringify(payload)
    });
    showToast('Dépense enregistrée !', 'success');
    closeModal('modal-add-expense');
    document.getElementById('form-add-expense').reset();
    await loadFinances();
  } catch (error) {
    showToast(error.message, 'error');
  }
}

async function deleteExpense(id) {
  if (!confirm('Supprimer cette dépense ?')) return;
  try {
    await apiRequest(`/api/finance/expenses/${id}`, { method: 'DELETE' });
    showToast('Dépense supprimée.', 'success');
    await loadFinances();
  } catch (error) {
    showToast(error.message, 'error');
  }
}

async function deleteSanction(id) {
  if (!confirm('Supprimer cette sanction ?')) return;
  try {
    await apiRequest(`/api/discipline/sanctions/${id}`, { method: 'DELETE' });
    showToast('Sanction supprimée.', 'success');
    await loadDiscipline();
  } catch (error) {
    showToast(error.message, 'error');
  }
}

async function handleCreateUser(e) {
  e.preventDefault();
  const payload = {
    fullName: document.getElementById('user-fullname').value.trim(),
    username: document.getElementById('user-username').value.trim(),
    email: document.getElementById('user-email').value.trim(),
    password: document.getElementById('user-password').value,
    role: document.getElementById('user-role').value,
    phone: document.getElementById('user-phone').value.trim() || null
  };

  try {
    await apiRequest('/api/users/register', {
      method: 'POST',
      body: JSON.stringify(payload)
    });
    showToast('Compte utilisateur créé avec succès !', 'success');
    closeModal('modal-add-user');
    document.getElementById('form-add-user').reset();
    await loadUsers();
    await loadStats();
  } catch (error) {
    showToast(error.message, 'error');
  }
}

async function deleteUser(id) {
  if (!confirm('Supprimer cet utilisateur ?')) return;
  try {
    await apiRequest(`/api/users/${id}`, { method: 'DELETE' });
    showToast('Utilisateur supprimé.', 'success');
    await loadUsers();
  } catch (error) {
    showToast(error.message, 'error');
  }
}

// ==========================================================================
// TABS & NAVIGATION
// ==========================================================================

function switchTab(tabId) {
  State.activeTab = tabId;

  // Update nav items
  document.querySelectorAll('.sidebar-nav .nav-item').forEach(item => {
    if (item.getAttribute('data-tab') === tabId) {
      item.classList.add('active');
    } else {
      item.classList.remove('active');
    }
  });

  // Update panes
  document.querySelectorAll('.tab-pane').forEach(pane => {
    if (pane.id === `pane-${tabId}`) {
      pane.classList.add('active');
    } else {
      pane.classList.remove('active');
    }
  });

  // Update breadcrumb
  const titles = {
    'dashboard': 'Tableau de Bord',
    'schools': 'Gestion des Écoles',
    'subscriptions': 'Abonnements & Promotions',
    'students': 'Élèves & Inscriptions',
    'teachers': 'Enseignants',
    'classrooms': 'Classes & Salles',
    'finances': 'Finances & Trésorerie',
    'discipline': 'Discipline & Présences',
    'users': 'Utilisateurs & Accès',
    'api-console': 'Console API',
    'archives': 'Archives annuelles'
  };

  document.getElementById('breadcrumb-current-tab').textContent = titles[tabId] || tabId;

  // Close mobile menu if open
  document.getElementById('sidebar').classList.remove('mobile-open');
}

document.querySelectorAll('.sidebar-nav .nav-item').forEach(item => {
  item.addEventListener('click', () => {
    const tab = item.getAttribute('data-tab');
    if (tab) switchTab(tab);
  });
});

// Mobile menu toggle
document.getElementById('mobile-menu-toggle').addEventListener('click', () => {
  document.getElementById('sidebar').classList.toggle('mobile-open');
});

// Refresh button
document.getElementById('refresh-all-btn').addEventListener('click', () => {
  showToast('Actualisation des données...', 'info');
  loadAllData();
});

// Server status pill click -> open config modal
document.getElementById('server-status-pill').addEventListener('click', () => {
  document.getElementById('config-api-base-url').value = State.apiBaseUrl;
  openModal('modal-api-config');
});

function saveApiBaseUrl() {
  const newUrl = document.getElementById('config-api-base-url').value.trim();
  if (!newUrl) return;
  State.apiBaseUrl = newUrl;
  localStorage.setItem('edugest_api_url', newUrl);
  closeModal('modal-api-config');
  showToast(`URL API définie sur : ${newUrl}`, 'info');
  loadAllData();
}

// Search inputs live filters
document.getElementById('search-schools')?.addEventListener('input', renderSchools);
document.getElementById('filter-schools-status')?.addEventListener('change', renderSchools);
document.getElementById('search-students')?.addEventListener('input', renderStudents);
document.getElementById('filter-students-class')?.addEventListener('change', renderStudents);
document.getElementById('search-teachers')?.addEventListener('input', renderTeachers);

// Theme Toggle
const themeBtn = document.getElementById('theme-toggle-btn');
themeBtn.addEventListener('click', () => {
  document.body.classList.toggle('light-theme');
  const isLight = document.body.classList.contains('light-theme');
  localStorage.setItem('edugest_theme', isLight ? 'light' : 'dark');
});

if (localStorage.getItem('edugest_theme') === 'light') {
  document.body.classList.add('light-theme');
}

// ==========================================================================
// API TEST CONSOLE
// ==========================================================================

document.getElementById('api-test-send-btn').addEventListener('click', async () => {
  const method = document.getElementById('api-test-method').value;
  const endpoint = document.getElementById('api-test-endpoint').value.trim();
  const statusEl = document.getElementById('api-response-status');
  const timeEl = document.getElementById('api-response-time');
  const outputEl = document.getElementById('api-response-json');

  outputEl.textContent = 'Envoi de la requête en cours...';
  statusEl.textContent = '...';
  timeEl.textContent = '...';

  const startTime = performance.now();
  try {
    const data = await apiRequest(endpoint, { method });
    const endTime = performance.now();
    statusEl.textContent = '200 OK';
    statusEl.style.color = 'var(--success)';
    timeEl.textContent = `${Math.round(endTime - startTime)} ms`;
    outputEl.textContent = JSON.stringify(data, null, 2);
  } catch (error) {
    const endTime = performance.now();
    statusEl.textContent = 'Erreur';
    statusEl.style.color = 'var(--danger)';
    timeEl.textContent = `${Math.round(endTime - startTime)} ms`;
    outputEl.textContent = JSON.stringify({ error: error.message }, null, 2);
  }
});

// ==========================================================================
// INITIALIZATION
// ==========================================================================

window.addEventListener('DOMContentLoaded', () => {
  updatePlatformAuthButton();
  checkBackendHealth();
  loadAllData();
  // Auto-refresh every 30 seconds
  setInterval(checkBackendHealth, 30000);
});
