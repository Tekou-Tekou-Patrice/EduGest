/**
 * EDUGEST SUPER ADMIN — SaaS Platform & Subscription Control Logic
 * Controls School Licences, Subscriptions, MTN / Orange Money & WhatsApp Automation
 */

// ==========================================================================
// GLOBAL STATE & LOCAL STORAGE INITIALIZATION
// ==========================================================================

const DEFAULT_SCHOOLS = [
  {
    id: 'school-001',
    name: "École de l'Excellence",
    code: 'EXCELLENCE-2026',
    city: 'Dakar',
    founderName: 'M. Ibrahima Diop',
    founderPhone: '+221 77 123 45 67',
    whatsapp: '+221 77 123 45 67',
    pack: 'Premium',
    monthlyPrice: 45000,
    status: 'active',
    subscriptionStart: '2026-08-01',
    subscriptionEnd: '2026-09-30',
    lastPaymentMethod: 'Orange Money',
    lastPaymentDate: '2026-08-30'
  },
  {
    id: 'school-002',
    name: 'Collège Saint Martin',
    code: 'STMARTIN-2026',
    city: 'Thiès',
    founderName: 'Mme Awa Sall',
    founderPhone: '+221 76 654 32 10',
    whatsapp: '+221 76 654 32 10',
    pack: 'Basic',
    monthlyPrice: 20000,
    status: 'suspended',
    subscriptionStart: '2026-07-01',
    subscriptionEnd: '2026-08-20',
    lastPaymentMethod: 'MTN Mobile Money',
    lastPaymentDate: '2026-07-20'
  },
  {
    id: 'school-003',
    name: 'Complexe Scolaire Bintou',
    code: 'BINTOU-2026',
    city: 'Saint-Louis',
    founderName: 'M. Cheikh Ndoye',
    founderPhone: '+221 70 987 65 43',
    whatsapp: '+221 70 987 65 43',
    pack: 'Standard',
    monthlyPrice: 30000,
    status: 'active',
    subscriptionStart: '2026-08-05',
    subscriptionEnd: '2026-09-04',
    lastPaymentMethod: 'Orange Money',
    lastPaymentDate: '2026-08-05'
  },
  {
    id: 'school-004',
    name: 'Lycée Bilingue La Référence',
    code: 'REFERENCE-2026',
    city: 'Douala',
    founderName: 'Dr. Paul Kamga',
    founderPhone: '+237 699 12 34 56',
    whatsapp: '+237 699 12 34 56',
    pack: 'Pro',
    monthlyPrice: 60000,
    status: 'active',
    subscriptionStart: '2026-08-15',
    subscriptionEnd: '2026-10-15',
    lastPaymentMethod: 'MTN Mobile Money',
    lastPaymentDate: '2026-08-15'
  },
  {
    id: 'school-005',
    name: "Institut Moderne de l'Avenir",
    code: 'AVENIR-2026',
    city: 'Yaoundé',
    founderName: 'Mme Chantal Ngo',
    founderPhone: '+237 677 88 99 00',
    whatsapp: '+237 677 88 99 00',
    pack: 'Standard',
    monthlyPrice: 30000,
    status: 'suspended',
    subscriptionStart: '2026-07-10',
    subscriptionEnd: '2026-08-25',
    lastPaymentMethod: 'Orange Money',
    lastPaymentDate: '2026-07-10'
  }
];

const DEFAULT_PAYMENT_METHODS = {
  orange: {
    active: true,
    label: 'Orange Money',
    number: '+221 77 123 45 67',
    holder: 'EDUGEST SAS / PATRICK',
    instructions: 'Mentionnez le nom de votre établissement en motif du transfert'
  },
  mtn: {
    active: true,
    label: 'MTN Mobile Money (MoMo)',
    number: '+221 76 654 32 10',
    holder: 'EDUGEST SERVICES',
    instructions: 'Tapez *126# puis validez le paiement vers le compte officiel'
  },
  other: {
    active: false,
    label: 'Wave Money',
    number: '+221 70 987 65 43',
    holder: 'EDUGEST DIRECT',
    instructions: 'Transfert direct sans frais via Wave'
  }
};

const DEFAULT_PROMOTIONS = [
  {
    id: 'promo-1',
    title: 'Offre Spéciale Rentrée Scolaire 2026',
    code: 'RENTREE2026',
    discount: '-25% sur 3 mois',
    description: 'Bénéficiez de 25% de réduction immédiate pour tout réabonnement trimestriel effectué avant la rentrée des classes.',
    expiry: '2026-09-30',
    status: 'active'
  },
  {
    id: 'promo-2',
    title: 'Pack Annuel : 2 Mois Offerts',
    code: 'ANNEE2026',
    discount: '2 Mois Gratuits',
    description: 'Réglez 10 mois d’abonnement et profitez de l’année scolaire complète (12 mois) avec support technique prioritaire.',
    expiry: '2026-10-31',
    status: 'active'
  },
  {
    id: 'promo-3',
    title: 'Programme Parrainage Écoles',
    code: 'PARRAIN20',
    discount: '1 Mois Offert',
    description: 'Recommandez EduGest à un établissement confrère et gagnez 1 mois gratuit dès l’inscription de son fondateur.',
    expiry: '2026-12-31',
    status: 'active'
  }
];

const DEFAULT_TEMPLATES = {
  reminder: `Bonjour M./Mme {FONDATEUR}, nous espérons que vous allez bien.\n\nNous vous informons que l'abonnement EduGest de votre établissement *{ECOLE}* arrive à échéance le *{DATE_ECHEANCE}*.\n\n💰 *Montant de l'abonnement :* {MONTANT} FCFA\n\nPour continuer à garantir l'accès sans coupure à vos équipes pédagogiques et administratives, vous pouvez effectuer le règlement sur l'un de nos comptes officiels :\n\n{PAIEMENTS}\n\nMerci de nous faire suivre la capture ou le numéro de transaction après paiement.\n\nCordialement,\n*Direction EduGest Platform*`,
  
  urgent: `⚠️ *AVIS D'ÉCHÉANCE IMMINENTE — EDUGEST*\n\nBonjour M./Mme {FONDATEUR},\n\nL'abonnement de votre établissement *{ECOLE}* arrive à expiration *le {DATE_ECHEANCE}*.\n\n💰 *Montant dû :* {MONTANT} FCFA\n\nAfin d'éviter la suspension automatique des accès sur l'application mobile et le portail web, veuillez régulariser votre paiement via :\n\n{PAIEMENTS}\n\nUne fois le transfert effectué, vos accès seront automatiquement reconduits.\n\nMerci de votre réactivité,\n*L'équipe EduGest*`,
  
  suspended: `🔴 *NOTIFICATION DE SUSPENSION — EDUGEST*\n\nBonjour M./Mme {FONDATEUR},\n\nNous vous informons que les accès de l'établissement *{ECOLE}* sur la plateforme EduGest ont été *temporairement suspendus* pour impayé d'abonnement.\n\n💰 *Montant pour réactivation immédiate :* {MONTANT} FCFA\n\nPour réactiver immédiatement vos accès et reprendre l'activité, effectuez le règlement sur l'un de nos numéros :\n\n{PAIEMENTS}\n\nDès réception de votre preuve de paiement, le compte de votre école sera réactivé instantanément.\n\nService Client EduGest`,
  
  renewed: `✅ *CONFIRMATION DE PAIEMENT & RÉACTIVATION*\n\nBonjour M./Mme {FONDATEUR},\n\nNous accusons bonne réception de votre règlement pour l'établissement *{ECOLE}*.\n\n🎉 Votre abonnement EduGest est désormais *ACTIF* jusqu'au *{DATE_ECHEANCE}*.\n\nNous vous remercions pour votre fidélité et restons à votre entière disposition pour tout besoin d'assistance.\n\n*L'équipe EduGest Platform*`,
  
  promo: `🎁 *OFFRE PROMOTIONNELLE EXCLUSIVE EDUGEST*\n\nBonjour M./Mme {FONDATEUR},\n\nNous avons le plaisir de vous proposer une offre spéciale pour l'établissement *{ECOLE}* !\n\n🔥 *Offre spéciale :* Bénéficiez d'une remise exceptionnelle sur le renouvellement de votre abonnement EduGest.\n\nPour en profiter dès aujourd'hui ou en savoir plus, répondez directement à ce message.\n\nBelle année scolaire avec EduGest !`
};

const State = {
  apiBaseUrl: localStorage.getItem('edugest_admin_api_url') || 'http://localhost:8003',
  isOnline: false,
  activeTab: 'dashboard',
  schools: [],
  paymentMethods: {},
  promotions: [],
  templates: {}
};

if (State.apiBaseUrl.includes('onrender.com')) {
  State.apiBaseUrl = 'http://localhost:8003';
  localStorage.setItem('edugest_admin_api_url', State.apiBaseUrl);
}

async function apiRequest(endpoint, options = {}) {
  try {
    const response = await fetch(`${State.apiBaseUrl}${endpoint}`, {
      ...options,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        ...(localStorage.getItem('edugest_admin_token')
          ? { 'Authorization': 'Bearer ' + localStorage.getItem('edugest_admin_token') }
          : {}),
        ...(options.headers || {})
      }
    });
    if (!response.ok) {
      let message = `Erreur HTTP ${response.status}`;
      try {
        const data = await response.json();
        message = data.message || message;
      } catch (_) {}
      throw new Error(message);
    }
    return response.status === 204 ? null : response.json();
  } catch (error) {
    if (error instanceof TypeError) {
      throw new Error('Problème de réseau, vérifiez votre accès à Internet.');
    }
    throw error;
  }
}

// ==========================================================================
// DATA PERSISTENCE HELPERS
// ==========================================================================

function loadStateFromStorage() {
  try {
    const rawSchools = localStorage.getItem('edugest_admin_schools');
    State.schools = rawSchools ? JSON.parse(rawSchools) : [];

    const rawPayments = localStorage.getItem('edugest_admin_payments_config');
    State.paymentMethods = rawPayments ? JSON.parse(rawPayments) : {};

    const rawPromos = localStorage.getItem('edugest_admin_promos');
    State.promotions = rawPromos ? JSON.parse(rawPromos) : [];

    const rawTemplates = localStorage.getItem('edugest_admin_templates');
    State.templates = rawTemplates ? JSON.parse(rawTemplates) : {};
  } catch (e) {
    console.error('Erreur chargement localStorage, réinitialisation par défaut', e);
    State.schools = [];
    State.paymentMethods = {};
    State.promotions = [];
    State.templates = {};
  }
}

function saveStateToStorage() {
  localStorage.setItem('edugest_admin_schools', JSON.stringify(State.schools));
  localStorage.setItem('edugest_admin_payments_config', JSON.stringify(State.paymentMethods));
  localStorage.setItem('edugest_admin_promos', JSON.stringify(State.promotions));
  localStorage.setItem('edugest_admin_templates', JSON.stringify(State.templates));
}

async function loadConnectedData() {
  let schoolsLoaded = false;
  try {
    const schools = await apiRequest('/api/schools/all');
    State.schools = Array.isArray(schools) ? schools.map(mapBackendSchool) : [];
    schoolsLoaded = true;
  } catch (error) {
    console.error('Impossible de charger les écoles:', error);
  }

  try {
    const settings = await apiRequest('/api/saas-settings');
    State.paymentMethods = {
      orange: {
        active: Boolean(settings.orangeNumber),
        label: 'Orange Money',
        number: settings.orangeNumber || '',
        holder: settings.orangeName || '',
        instructions: settings.paymentInstructions || ''
      },
      mtn: {
        active: Boolean(settings.mtnNumber),
        label: 'MTN Mobile Money',
        number: settings.mtnNumber || '',
        holder: settings.mtnName || '',
        instructions: settings.paymentInstructions || ''
      }
    };
  } catch (error) {
    console.error('Impossible de charger les paramètres de paiement:', error);
  }

  if (!schoolsLoaded) {
    State.schools = [];
    showToast('Impossible de charger les écoles depuis le serveur local.', 'error');
  }
  saveStateToStorage();
  renderDashboard();
  renderSchools();
  renderPaymentMethodsConfig();
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
    pack: school.planName || 'Standard',
    monthlyPrice: school.monthlyFee || 0,
    subscriptionEnd: school.subscriptionExpiresAt || ''
  };
}

// ==========================================================================
// DATE & SUBSCRIPTION HELPERS
// ==========================================================================

function formatDateFr(dateStr) {
  if (!dateStr) return 'Non définie';
  try {
    const parts = dateStr.split('-');
    if (parts.length === 3) {
      return `${parts[2]}/${parts[1]}/${parts[0]}`;
    }
    const d = new Date(dateStr);
    return d.toLocaleDateString('fr-FR');
  } catch (_) {
    return dateStr;
  }
}

function getDaysRemaining(expiryDateStr) {
  if (!expiryDateStr) return 0;
  const now = new Date();
  now.setHours(0, 0, 0, 0);
  const expiry = new Date(expiryDateStr);
  expiry.setHours(0, 0, 0, 0);
  const diffTime = expiry.getTime() - now.getTime();
  return Math.ceil(diffTime / (1000 * 60 * 60 * 24));
}

function addMonthsToDate(dateStr, months) {
  let baseDate = new Date();
  if (dateStr) {
    const existing = new Date(dateStr);
    if (!isNaN(existing.getTime()) && existing.getTime() > baseDate.getTime()) {
      baseDate = existing;
    }
  }
  const result = new Date(baseDate);
  result.setMonth(result.getMonth() + parseInt(months, 10));
  return result.toISOString().split('T')[0];
}

function formatMoney(amount) {
  if (amount == null) return '0 FCFA';
  return Number(amount).toLocaleString('fr-FR') + ' FCFA';
}

function sanitizePhoneForWhatsApp(phone) {
  if (!phone) return '';
  return phone.replace(/[^0-9]/g, '');
}

// ==========================================================================
// PAYMENT TEXT BUILDER FOR WHATSAPP
// ==========================================================================

function buildPaymentMethodsText() {
  const parts = [];
  const pm = State.paymentMethods;

  if (pm.orange && pm.orange.active && pm.orange.number) {
    parts.push(`🟠 *Orange Money :* ${pm.orange.number} (${pm.orange.holder || 'EDUGEST'})\n   _${pm.orange.instructions || 'Précisez le nom de l\'école'}_`);
  }

  if (pm.mtn && pm.mtn.active && pm.mtn.number) {
    parts.push(`🟡 *MTN Mobile Money :* ${pm.mtn.number} (${pm.mtn.holder || 'EDUGEST'})\n   _${pm.mtn.instructions || 'Validez via compte marchand'}_`);
  }

  if (pm.other && pm.other.active && pm.other.number) {
    parts.push(`🔵 *${pm.other.label || 'Autre'} :* ${pm.other.number} (${pm.other.holder || ''})`);
  }

  if (parts.length === 0) {
    return 'Aucun numéro de paiement configuré.';
  }

  return parts.join('\n\n');
}

// ==========================================================================
// NOTIFICATION TOAST SYSTEM
// ==========================================================================

function showToast(message, type = 'info') {
  const container = document.getElementById('toast-container');
  if (!container) return;
  const toast = document.createElement('div');
  toast.className = `toast toast-${type}`;

  const icons = {
    success: '✅',
    error: '❌',
    info: 'ℹ️',
    warning: '⚠️'
  };

  toast.innerHTML = `
    <span style="font-size: 18px;">${icons[type] || 'ℹ️'}</span>
    <span style="flex: 1;">${escapeHtml(message)}</span>
    <button style="background:none;border:none;color:var(--text-dim);cursor:pointer;" onclick="this.parentElement.remove()">✕</button>
  `;

  container.appendChild(toast);

  setTimeout(() => {
    toast.style.opacity = '0';
    toast.style.transform = 'translateY(10px)';
    toast.style.transition = 'all 0.3s ease';
    setTimeout(() => toast.remove(), 300);
  }, 4200);
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
  }
}

function closeModal(modalId) {
  const modal = document.getElementById(modalId);
  if (modal) {
    modal.classList.remove('open');
  }
}

document.addEventListener('click', (e) => {
  if (e.target.classList && e.target.classList.contains('modal-backdrop')) {
    e.target.classList.remove('open');
  }
});

// ==========================================================================
// TAB NAVIGATION
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

  // Update tab panes
  document.querySelectorAll('.tab-pane').forEach(pane => {
    pane.classList.remove('active');
  });

  const targetPane = document.getElementById(`pane-${tabId}`);
  if (targetPane) {
    targetPane.classList.add('active');
  }

  // Update breadcrumb
  const breadcrumb = document.getElementById('breadcrumb-current-tab');
  if (breadcrumb) {
    const titles = {
      'dashboard': 'Tableau de Bord',
      'schools': 'Écoles & Abonnements',
      'payments-config': 'Numéros MTN & Orange',
      'promotions': 'Promotions & Offres',
      'whatsapp-center': 'Relances WhatsApp',
      'invoices': 'Reçus & Factures SaaS',
      'settings': 'Paramètres Système'
    };
    breadcrumb.textContent = titles[tabId] || 'Tableau de Bord';
  }

  // Refresh tab contents
  if (tabId === 'dashboard') renderDashboard();
  if (tabId === 'schools') renderSchools();
  if (tabId === 'payments-config') renderPaymentMethodsConfig();
  if (tabId === 'promotions') renderPromotions();
  if (tabId === 'whatsapp-center') renderWhatsAppCenter();
  if (tabId === 'invoices') renderInvoicesTab();
}

// ==========================================================================
// 1. DASHBOARD TAB RENDERING & METRICS
// ==========================================================================

function renderDashboard() {
  const totalSchools = State.schools.length;
  const activeSchools = State.schools.filter(s => s.status === 'active').length;
  const suspendedSchools = State.schools.filter(s => s.status === 'suspended').length;

  let expiringSoonCount = 0;
  let totalMonthlyRevenue = 0;

  State.schools.forEach(s => {
    const days = getDaysRemaining(s.subscriptionEnd);
    if (s.status === 'active' && days >= 0 && days <= 7) {
      expiringSoonCount++;
    }
    if (s.status === 'active') {
      totalMonthlyRevenue += Number(s.monthlyPrice || 0);
    }
  });

  const activePromos = State.promotions.filter(p => p.status === 'active').length;

  // Update hero & counters
  const heroCount = document.getElementById('hero-schools-count');
  if (heroCount) heroCount.textContent = totalSchools;

  document.getElementById('dash-schools-count').textContent = totalSchools;
  document.getElementById('dash-active-schools-count').textContent = activeSchools;
  document.getElementById('dash-suspended-schools-count').textContent = suspendedSchools;
  document.getElementById('dash-expiring-count').textContent = expiringSoonCount;
  document.getElementById('dash-monthly-revenue').textContent = formatMoney(totalMonthlyRevenue);
  document.getElementById('dash-active-promos-count').textContent = activePromos;

  // Sidebar badge counts
  const navSchoolsBadge = document.getElementById('nav-schools-count');
  if (navSchoolsBadge) navSchoolsBadge.textContent = totalSchools;

  const navPromosBadge = document.getElementById('nav-promos-count');
  if (navPromosBadge) navPromosBadge.textContent = activePromos;

  const navAlertsBadge = document.getElementById('nav-alerts-count');
  const alertTotal = suspendedSchools + expiringSoonCount;
  if (navAlertsBadge) {
    navAlertsBadge.textContent = alertTotal;
    navAlertsBadge.style.display = alertTotal > 0 ? 'inline-block' : 'none';
  }

  // Top header alert pill
  const topAlertsBtn = document.getElementById('top-alerts-btn');
  const topAlertsText = document.getElementById('top-alerts-text');
  if (topAlertsBtn && topAlertsText) {
    if (alertTotal > 0) {
      topAlertsBtn.style.display = 'inline-flex';
      topAlertsText.textContent = `${alertTotal} école(s) à relancer`;
    } else {
      topAlertsBtn.style.display = 'none';
    }
  }

  // Urgent Alert Banner
  const alertBanner = document.getElementById('urgent-alert-banner');
  const alertDesc = document.getElementById('urgent-alert-desc');
  if (alertBanner && alertDesc) {
    if (suspendedSchools > 0 || expiringSoonCount > 0) {
      alertBanner.style.display = 'flex';
      alertDesc.innerHTML = `Il y a actuellement <strong>${suspendedSchools} école(s) suspendue(s)</strong> pour impayé et <strong>${expiringSoonCount} école(s)</strong> dont l'abonnement expire sous 7 jours.`;
    } else {
      alertBanner.style.display = 'none';
    }
  }

  // Dashboard Payment numbers preview
  const dashPmPreview = document.getElementById('dash-payment-numbers-preview');
  if (dashPmPreview) {
    const pm = State.paymentMethods;
    let html = '';
    if (pm.orange && pm.orange.active) {
      html += `
        <div style="display: flex; align-items: center; justify-content: space-between; background: var(--bg-input); padding: 8px 12px; border-radius: var(--radius-sm);">
          <span class="pill pill-orange">🟠 Orange Money</span>
          <strong style="font-size: 13px;">${escapeHtml(pm.orange.number)}</strong>
          <span style="font-size: 11px; color: var(--text-dim);">${escapeHtml(pm.orange.holder || '')}</span>
        </div>
      `;
    }
    if (pm.mtn && pm.mtn.active) {
      html += `
        <div style="display: flex; align-items: center; justify-content: space-between; background: var(--bg-input); padding: 8px 12px; border-radius: var(--radius-sm);">
          <span class="pill pill-mtn">🟡 MTN MoMo</span>
          <strong style="font-size: 13px;">${escapeHtml(pm.mtn.number)}</strong>
          <span style="font-size: 11px; color: var(--text-dim);">${escapeHtml(pm.mtn.holder || '')}</span>
        </div>
      `;
    }
    if (!html) {
      html = '<div style="font-size: 12px; color: var(--text-muted);">Aucun numéro actif configuré. Cliquez sur "Modifier" pour en ajouter.</div>';
    }
    dashPmPreview.innerHTML = html;
  }

  // Dashboard schools grid preview (first 4 items)
  const dashSchoolsGrid = document.getElementById('dash-schools-grid');
  if (dashSchoolsGrid) {
    if (State.schools.length === 0) {
      dashSchoolsGrid.innerHTML = '<div class="table-empty">Aucun établissement enregistré.</div>';
    } else {
      dashSchoolsGrid.innerHTML = State.schools.slice(0, 4).map(s => renderSchoolCardHtml(s)).join('');
    }
  }
}

// ==========================================================================
// 2. SCHOOLS TAB & SUBSCRIPTION MANAGEMENT
// ==========================================================================

function renderSchools() {
  const container = document.getElementById('schools-grid-container');
  const searchInput = document.getElementById('search-schools');
  const statusFilter = document.getElementById('filter-schools-status');
  const packFilter = document.getElementById('filter-schools-pack');
  const totalCountEl = document.getElementById('schools-total-count');

  if (!container) return;

  const query = (searchInput ? searchInput.value : '').toLowerCase().trim();
  const status = statusFilter ? statusFilter.value : 'all';
  const pack = packFilter ? packFilter.value : 'all';

  let filtered = State.schools.filter(school => {
    // Search query matches school name, city, founder, phone or code
    const matchQuery = !query || 
      (school.name && school.name.toLowerCase().includes(query)) ||
      (school.city && school.city.toLowerCase().includes(query)) ||
      (school.founderName && school.founderName.toLowerCase().includes(query)) ||
      (school.founderPhone && school.founderPhone.toLowerCase().includes(query)) ||
      (school.code && school.code.toLowerCase().includes(query));

    if (!matchQuery) return false;

    // Status filter
    if (status === 'active' && school.status !== 'active') return false;
    if (status === 'suspended' && school.status !== 'suspended') return false;
    if (status === 'expiring') {
      const days = getDaysRemaining(school.subscriptionEnd);
      if (school.status !== 'active' || days < 0 || days > 7) return false;
    }
    if (status === 'unpaid') {
      const days = getDaysRemaining(school.subscriptionEnd);
      if (school.status !== 'suspended' && days > 7) return false;
    }

    // Pack filter
    if (pack !== 'all' && school.pack !== pack) return false;

    return true;
  });

  if (totalCountEl) totalCountEl.textContent = filtered.length;

  if (filtered.length === 0) {
    container.innerHTML = `
      <div class="table-empty" style="grid-column: 1 / -1;">
        <div style="font-size: 40px; margin-bottom: 8px;">🔍</div>
        <p>Aucune école ne correspond à vos critères de recherche.</p>
        <button class="btn btn-secondary btn-sm" style="margin-top: 10px;" onclick="resetSchoolFilters()">Réinitialiser les filtres</button>
      </div>
    `;
    return;
  }

  container.innerHTML = filtered.map(school => renderSchoolCardHtml(school)).join('');
}

function renderSchoolCardHtml(school) {
  const days = getDaysRemaining(school.subscriptionEnd);
  const isSuspended = school.status === 'suspended';
  
  let statusBadge = '';
  let progressColor = 'var(--success)';
  let progressWidth = '100%';
  let daysText = '';

  if (isSuspended) {
    statusBadge = '<span class="pill pill-danger">🔴 Suspendu (Impayé)</span>';
    progressColor = 'var(--danger)';
    progressWidth = '100%';
    daysText = `<span style="color: var(--danger); font-weight: 700;">Accès bloqué</span>`;
  } else if (days < 0) {
    statusBadge = '<span class="pill pill-danger">⚠️ Expiré (À suspendre)</span>';
    progressColor = 'var(--danger)';
    progressWidth = '100%';
    daysText = `<span style="color: var(--danger); font-weight: 700;">Expiré depuis ${Math.abs(days)} jour(s)</span>`;
  } else if (days <= 7) {
    statusBadge = '<span class="pill pill-warning">⏰ Expire dans ' + days + ' j</span>';
    progressColor = 'var(--warning)';
    progressWidth = `${Math.max(10, Math.min(100, (days / 30) * 100))}%`;
    daysText = `<span style="color: var(--warning); font-weight: 700;">Expire le ${formatDateFr(school.subscriptionEnd)}</span>`;
  } else {
    statusBadge = '<span class="pill pill-success">🟢 Actif (À jour)</span>';
    progressColor = 'var(--success)';
    progressWidth = `${Math.max(15, Math.min(100, (days / 30) * 100))}%`;
    daysText = `Valide jusqu'au ${formatDateFr(school.subscriptionEnd)} (${days} jours restants)`;
  }

  const sanitizedWa = sanitizePhoneForWhatsApp(school.whatsapp || school.founderPhone);

  return `
    <div class="school-card ${isSuspended ? 'suspended' : ''}" id="school-card-${school.id}">
      <div class="school-card-header">
        <div class="school-title-wrap">
          <div class="school-avatar">${isSuspended ? '🔒' : '🏫'}</div>
          <div>
            <div class="school-name">${escapeHtml(school.name)}</div>
            <div class="school-location">📍 ${escapeHtml(school.city || 'Ville non spécifiée')} • Code: <strong>${escapeHtml(school.code)}</strong></div>
          </div>
        </div>
        <div>
          ${statusBadge}
        </div>
      </div>

      <!-- Founder & Contact Details Box -->
      <div class="founder-box">
        <div class="founder-row">
          <span class="founder-label">Fondateur :</span>
          <span class="founder-value">👤 ${escapeHtml(school.founderName || 'Non renseigné')}</span>
        </div>
        <div class="founder-row">
          <span class="founder-label">Téléphone :</span>
          <a href="tel:${escapeHtml(school.founderPhone || '')}" style="color: var(--primary); text-decoration: none; font-weight: 600;">
            📞 ${escapeHtml(school.founderPhone || 'N/A')}
          </a>
        </div>
        <div class="founder-row">
          <span class="founder-label">Secrétaire :</span>
          <span class="founder-value">👤 ${escapeHtml(school.secretaryName || 'Non renseigné')}</span>
        </div>
        <div class="founder-row">
          <span class="founder-label">Téléphone secrétaire :</span>
          <a href="tel:${escapeHtml(school.secretaryPhone || '')}" style="color: var(--primary); text-decoration: none; font-weight: 600;">
            📞 ${escapeHtml(school.secretaryPhone || 'N/A')}
          </a>
        </div>
        <div class="founder-row">
          <span class="founder-label">WhatsApp Direct :</span>
          <span style="color: var(--whatsapp); font-weight: 700;">💬 ${escapeHtml(school.whatsapp || school.founderPhone || 'N/A')}</span>
        </div>
      </div>

      <!-- Subscription & Pricing Details -->
      <div class="subscription-meta">
        <div class="subscription-row">
          <span style="color: var(--text-dim); font-size: 12px;">Formule : <strong style="color: var(--text-main);">${escapeHtml(school.pack || 'Standard')}</strong></span>
          <span style="font-weight: 800; font-size: 13.5px; color: var(--accent);">${formatMoney(school.monthlyPrice)} / mois</span>
        </div>
        <div class="subscription-row" style="font-size: 11.5px; color: var(--text-muted); margin-top: 2px;">
          <span>${daysText}</span>
        </div>
        <div class="subscription-progress">
          <div class="subscription-progress-fill" style="width: ${progressWidth}; background: ${progressColor};"></div>
        </div>
      </div>

      <!-- Action Buttons & Quick Toggle -->
      <div class="school-card-actions">
        <!-- 1-Click Status Switch -->
        <label class="switch-container" title="Activer ou suspendre l'accès de l'école">
          <div class="switch">
            <input type="checkbox" ${!isSuspended ? 'checked' : ''} onchange="toggleSchoolStatus('${school.id}')">
            <span class="slider"></span>
          </div>
          <span style="color: ${!isSuspended ? 'var(--success)' : 'var(--danger)'};">
            ${!isSuspended ? 'Actif' : 'Suspendu'}
          </span>
        </label>

        <div style="display: flex; align-items: center; gap: 6px;">
          <!-- Direct WhatsApp Button -->
          <button class="btn btn-whatsapp btn-sm" onclick="sendWhatsAppToSchool('${school.id}')" title="Envoyer le message de relance WhatsApp">
            💬 WhatsApp
          </button>

          <!-- Renew Button -->
          <button class="btn btn-secondary btn-sm" onclick="openRenewModal('${school.id}')" title="Renouveler l'abonnement">
            🔄 Renouveler
          </button>

          <!-- Edit Button -->
          <button class="btn btn-icon btn-sm" style="width: 32px; height: 32px;" onclick="openEditSchoolModal('${school.id}')" title="Modifier l'école">
            ✏️
          </button>

          <!-- Delete Button -->
          <button class="btn btn-icon btn-sm" style="width: 32px; height: 32px; color: var(--danger);" onclick="deleteSchool('${school.id}')" title="Supprimer">
            🗑️
          </button>
        </div>
      </div>
    </div>
  `;
}

function resetSchoolFilters() {
  const s = document.getElementById('search-schools');
  if (s) s.value = '';
  const st = document.getElementById('filter-schools-status');
  if (st) st.value = 'all';
  const pk = document.getElementById('filter-schools-pack');
  if (pk) pk.value = 'all';
  renderSchools();
}

function setSchoolFilter(filterVal) {
  const st = document.getElementById('filter-schools-status');
  if (st) {
    st.value = filterVal;
    renderSchools();
  }
}

function filterExpiringSchools() {
  switchTab('schools');
  setSchoolFilter('expiring');
}

// Toggle School Active / Suspended
async function toggleSchoolStatus(schoolId) {
  const school = State.schools.find(s => s.id === schoolId);
  if (!school) return;
  try {
    const updated = await apiRequest(`/api/schools/${encodeURIComponent(schoolId)}/toggle`, { method: 'PATCH' });
    Object.assign(school, mapBackendSchool(updated));
    saveStateToStorage();
    renderDashboard();
    renderSchools();
    showToast(`L'école "${school.name}" a été ${school.status === 'active' ? 'activée' : 'suspendue'}.`, 'success');
  } catch (error) {
    showToast(error.message || "Impossible de modifier l'état de l'école.", 'error');
  }
}

// ==========================================================================
// 3. WHATSAPP AUTOMATION & DIRECT RELANCE
// ==========================================================================

function generateWhatsAppText(school, templateKey = 'reminder') {
  if (!school) return '';
  const tpl = State.templates[templateKey] || State.templates['reminder'] || '';
  const paymentBlock = buildPaymentMethodsText();

  let text = tpl
    .replace(/\{FONDATEUR\}/g, school.founderName || 'Fondateur')
    .replace(/\{ECOLE\}/g, school.name || 'Votre établissement')
    .replace(/\{MONTANT\}/g, (school.monthlyPrice || 30000).toLocaleString('fr-FR'))
    .replace(/\{DATE_ECHEANCE\}/g, formatDateFr(school.subscriptionEnd))
    .replace(/\{PAIEMENTS\}/g, paymentBlock);

  return text;
}

function sendWhatsAppToSchool(schoolId, templateType = null) {
  const school = State.schools.find(s => s.id === schoolId);
  if (!school) return;

  const phone = school.whatsapp || school.founderPhone;
  const sanitized = sanitizePhoneForWhatsApp(phone);

  if (!sanitized) {
    showToast("Numéro WhatsApp invalide pour ce fondateur. Veuillez mettre à jour la fiche de l'école.", "error");
    return;
  }

  // Choose appropriate template based on school status
  let tplKey = templateType;
  if (!tplKey) {
    if (school.status === 'suspended') {
      tplKey = 'suspended';
    } else if (getDaysRemaining(school.subscriptionEnd) <= 0) {
      tplKey = 'urgent';
    } else {
      tplKey = 'reminder';
    }
  }

  const message = generateWhatsAppText(school, tplKey);
  const waUrl = `https://wa.me/${sanitized}?text=${encodeURIComponent(message)}`;
  
  window.open(waUrl, '_blank');
  showToast(`Ouverture de WhatsApp pour ${school.founderName} (${school.name})`, 'success');
}

// ==========================================================================
// 4. ADD & EDIT SCHOOL
// ==========================================================================

function openEditSchoolModal(schoolId) {
  const school = State.schools.find(s => s.id === schoolId);
  if (!school) return;

  document.getElementById('modal-school-title').textContent = "✏️ Modifier l'Établissement";
  document.getElementById('school-id-hidden').value = school.id;
  document.getElementById('school-name-input').value = school.name || '';
  document.getElementById('school-city-input').value = school.city || '';
  document.getElementById('school-code-input').value = school.code || '';
  document.getElementById('school-founder-name').value = school.founderName || '';
  document.getElementById('school-founder-phone').value = school.founderPhone || '';
  document.getElementById('school-founder-whatsapp').value = school.whatsapp || school.founderPhone || '';
  document.getElementById('school-pack-select').value = school.pack || 'Standard';
  document.getElementById('school-price-input').value = school.monthlyPrice || 30000;
  document.getElementById('school-expiry-input').value = school.subscriptionEnd || '';
  document.getElementById('school-status-select').value = school.status || 'active';

  openModal('modal-add-school');
}

function updateDefaultPackPrice() {
  const pack = document.getElementById('school-pack-select').value;
  const priceInput = document.getElementById('school-price-input');
  if (!priceInput) return;

  const prices = {
    'Basic': 20000,
    'Standard': 30000,
    'Premium': 45000,
    'Pro': 60000
  };

  priceInput.value = prices[pack] || 30000;
}

function handleSaveSchool(e) {
  e.preventDefault();
  const idHidden = document.getElementById('school-id-hidden').value;
  const name = document.getElementById('school-name-input').value.trim();
  const city = document.getElementById('school-city-input').value.trim();
  const code = document.getElementById('school-code-input').value.trim().toUpperCase();
  const founderName = document.getElementById('school-founder-name').value.trim();
  const founderPhone = document.getElementById('school-founder-phone').value.trim();
  const whatsapp = document.getElementById('school-founder-whatsapp').value.trim();
  const pack = document.getElementById('school-pack-select').value;
  const monthlyPrice = parseInt(document.getElementById('school-price-input').value, 10) || 30000;
  const subscriptionEnd = document.getElementById('school-expiry-input').value;
  const status = document.getElementById('school-status-select').value;

  if (idHidden) {
    // Edit existing school
    const index = State.schools.findIndex(s => s.id === idHidden);
    if (index !== -1) {
      State.schools[index] = {
        ...State.schools[index],
        name,
        city,
        code,
        founderName,
        founderPhone,
        whatsapp,
        pack,
        monthlyPrice,
        subscriptionEnd,
        status
      };
      showToast(`Établissement "${name}" mis à jour avec succès.`, 'success');
    }
  } else {
    // Create new school
    const newSchool = {
      id: 'school-' + Date.now(),
      name,
      city,
      code,
      founderName,
      founderPhone,
      whatsapp,
      pack,
      monthlyPrice,
      status,
      subscriptionStart: new Date().toISOString().split('T')[0],
      subscriptionEnd: subscriptionEnd || addMonthsToDate(new Date().toISOString().split('T')[0], 1),
      lastPaymentMethod: 'Orange Money',
      lastPaymentDate: new Date().toISOString().split('T')[0]
    };
    State.schools.unshift(newSchool);
    showToast(`Nouvelle école "${name}" créée avec succès.`, 'success');
  }

  saveStateToStorage();
  closeModal('modal-add-school');
  
  // Reset form
  document.getElementById('form-add-school').reset();
  document.getElementById('school-id-hidden').value = '';
  document.getElementById('modal-school-title').textContent = "🏫 Inscription d'un Nouvel Établissement";

  renderDashboard();
  renderSchools();
}

function deleteSchool(schoolId) {
  const school = State.schools.find(s => s.id === schoolId);
  if (!school) return;

  if (confirm(`Êtes-vous sûr de vouloir supprimer définitivement l'école "${school.name}" ?`)) {
    State.schools = State.schools.filter(s => s.id !== schoolId);
    saveStateToStorage();
    showToast(`École "${school.name}" supprimée.`, 'info');
    renderDashboard();
    renderSchools();
  }
}

// ==========================================================================
// 5. RENEW SUBSCRIPTION MODAL
// ==========================================================================

let activeRenewSchool = null;

function openRenewModal(schoolId) {
  const school = State.schools.find(s => s.id === schoolId);
  if (!school) return;
  activeRenewSchool = school;

  document.getElementById('renew-school-id').value = school.id;
  document.getElementById('renew-school-name').value = `${school.name} (Fondateur: ${school.founderName})`;
  document.getElementById('renew-duration-select').value = '1';
  calculateRenewTotal();
  openModal('modal-renew-school');
}

function calculateRenewTotal() {
  if (!activeRenewSchool) return;
  const duration = parseInt(document.getElementById('renew-duration-select').value, 10);
  const price = activeRenewSchool.monthlyPrice || 30000;
  const total = price * duration;

  const newDate = addMonthsToDate(activeRenewSchool.subscriptionEnd, duration);
  document.getElementById('renew-new-date').textContent = formatDateFr(newDate);
  document.getElementById('renew-total-amount').textContent = formatMoney(total);
}

function handleRenewSubscription(e) {
  e.preventDefault();
  if (!activeRenewSchool) return;

  const duration = parseInt(document.getElementById('renew-duration-select').value, 10);
  const paymentMethod = document.getElementById('renew-payment-method').value;
  const newDate = addMonthsToDate(activeRenewSchool.subscriptionEnd, duration);

  activeRenewSchool.subscriptionEnd = newDate;
  activeRenewSchool.status = 'active'; // Automatically reactivate
  activeRenewSchool.lastPaymentMethod = paymentMethod;
  activeRenewSchool.lastPaymentDate = new Date().toISOString().split('T')[0];

  saveStateToStorage();
  closeModal('modal-renew-school');
  showToast(`Abonnement de "${activeRenewSchool.name}" renouvelé avec succès jusqu'au ${formatDateFr(newDate)} !`, 'success');

  renderDashboard();
  renderSchools();
}

// ==========================================================================
// 6. PAYMENT METHODS SETTINGS (ORANGE & MTN)
// ==========================================================================

function renderPaymentMethodsConfig() {
  const pm = State.paymentMethods;
  
  if (pm.orange) {
    document.getElementById('cfg-orange-active').checked = !!pm.orange.active;
    document.getElementById('cfg-orange-number').value = pm.orange.number || '';
    document.getElementById('cfg-orange-holder').value = pm.orange.holder || '';
    document.getElementById('cfg-orange-instructions').value = pm.orange.instructions || '';
  }

  if (pm.mtn) {
    document.getElementById('cfg-mtn-active').checked = !!pm.mtn.active;
    document.getElementById('cfg-mtn-number').value = pm.mtn.number || '';
    document.getElementById('cfg-mtn-holder').value = pm.mtn.holder || '';
    document.getElementById('cfg-mtn-instructions').value = pm.mtn.instructions || '';
  }

  if (pm.other) {
    document.getElementById('cfg-other-active').checked = !!pm.other.active;
    document.getElementById('cfg-other-label').value = pm.other.label || '';
    document.getElementById('cfg-other-number').value = pm.other.number || '';
    document.getElementById('cfg-other-holder').value = pm.other.holder || '';
  }

  updateLivePaymentTextPreview();
}

function updateLivePaymentTextPreview() {
  const preview = document.getElementById('payment-text-live-preview');
  if (preview) {
    preview.textContent = buildPaymentMethodsText();
  }
}

async function savePaymentMethodsConfig() {
  State.paymentMethods.orange = {
    active: document.getElementById('cfg-orange-active').checked,
    label: 'Orange Money',
    number: document.getElementById('cfg-orange-number').value.trim(),
    holder: document.getElementById('cfg-orange-holder').value.trim(),
    instructions: document.getElementById('cfg-orange-instructions').value.trim()
  };

  State.paymentMethods.mtn = {
    active: document.getElementById('cfg-mtn-active').checked,
    label: 'MTN Mobile Money',
    number: document.getElementById('cfg-mtn-number').value.trim(),
    holder: document.getElementById('cfg-mtn-holder').value.trim(),
    instructions: document.getElementById('cfg-mtn-instructions').value.trim()
  };

  State.paymentMethods.other = {
    active: document.getElementById('cfg-other-active').checked,
    label: document.getElementById('cfg-other-label').value.trim() || 'Wave / Autre',
    number: document.getElementById('cfg-other-number').value.trim(),
    holder: document.getElementById('cfg-other-holder').value.trim()
  };

  try {
    const settings = await apiRequest('/api/saas-settings');
    settings.orangeNumber = State.paymentMethods.orange.number;
    settings.orangeName = State.paymentMethods.orange.holder;
    settings.mtnNumber = State.paymentMethods.mtn.number;
    settings.mtnName = State.paymentMethods.mtn.holder;
    settings.paymentInstructions = [
      State.paymentMethods.orange.instructions,
      State.paymentMethods.mtn.instructions
    ].filter(Boolean).join(' | ');
    await apiRequest('/api/saas-settings', {
      method: 'PUT',
      body: JSON.stringify(settings)
    });
    saveStateToStorage();
    updateLivePaymentTextPreview();
    showToast("Paramètres des numéros MTN & Orange Money enregistrés sur le serveur.", "success");
  } catch (error) {
    showToast(error.message || "Impossible d'enregistrer les numéros.", "error");
  }
}

// ==========================================================================
// 7. PROMOTIONS MANAGEMENT
// ==========================================================================

function renderPromotions() {
  const container = document.getElementById('promotions-grid-container');
  if (!container) return;

  if (State.promotions.length === 0) {
    container.innerHTML = '<div class="table-empty" style="grid-column: 1 / -1;">Aucune promotion configurée. Cliquez sur "Créer une Promotion".</div>';
    return;
  }

  container.innerHTML = State.promotions.map(promo => {
    const isActive = promo.status === 'active';
    return `
      <div class="promo-card">
        <div style="display: flex; align-items: flex-start; justify-content: space-between;">
          <div>
            <h3 style="font-size: 16px; font-weight: 800;">${escapeHtml(promo.title)}</h3>
            <span style="font-size: 12px; color: var(--accent); font-weight: 700;">Code: ${escapeHtml(promo.code || 'SANS CODE')}</span>
          </div>
          <span class="pill ${isActive ? 'pill-success' : 'pill-muted'}">
            ${isActive ? '🟢 Active' : '⚪ Désactivée'}
          </span>
        </div>

        <div class="promo-discount-badge">
          ${escapeHtml(promo.discount)}
        </div>

        <p style="font-size: 13px; color: var(--text-muted); line-height: 1.4;">
          ${escapeHtml(promo.description)}
        </p>

        <div style="font-size: 11.5px; color: var(--text-dim);">
          Valable jusqu'au : <strong>${formatDateFr(promo.expiry)}</strong>
        </div>

        <div style="display: flex; align-items: center; justify-content: space-between; padding-top: 10px; border-top: 1px solid var(--border-color);">
          <button class="btn btn-whatsapp btn-sm" onclick="sharePromoWhatsApp('${promo.id}')">
            💬 Diffuser WhatsApp
          </button>
          <div style="display: flex; gap: 6px;">
            <button class="btn btn-secondary btn-sm" onclick="togglePromoStatus('${promo.id}')">
              ${isActive ? 'Désactiver' : 'Activer'}
            </button>
            <button class="btn btn-icon btn-sm" style="width: 32px; height: 32px; color: var(--danger);" onclick="deletePromo('${promo.id}')">
              🗑️
            </button>
          </div>
        </div>
      </div>
    `;
  }).join('');
}

function sharePromoWhatsApp(promoId) {
  const promo = State.promotions.find(p => p.id === promoId);
  if (!promo) return;

  const msg = `🎁 *OFFRE PROMOTIONNELLE EDUGEST — ${promo.title}*\n\n🔥 *Avantage :* ${promo.discount}\n\n${promo.description}\n\n🏷️ *Code Promo :* ${promo.code || 'DIRECT'}\n⏳ *Offre valable jusqu'au :* ${formatDateFr(promo.expiry)}\n\nPour appliquer cette promotion sur votre établissement, contactez-nous dès maintenant !`;
  const waUrl = `https://wa.me/?text=${encodeURIComponent(msg)}`;
  window.open(waUrl, '_blank');
}

function togglePromoStatus(promoId) {
  const promo = State.promotions.find(p => p.id === promoId);
  if (!promo) return;
  promo.status = promo.status === 'active' ? 'inactive' : 'active';
  saveStateToStorage();
  renderPromotions();
  renderDashboard();
}

function handleSavePromo(e) {
  e.preventDefault();
  const title = document.getElementById('promo-title-input').value.trim();
  const code = document.getElementById('promo-code-input').value.trim().toUpperCase();
  const discount = document.getElementById('promo-discount-input').value.trim();
  const description = document.getElementById('promo-desc-input').value.trim();
  const expiry = document.getElementById('promo-expiry-input').value;
  const status = document.getElementById('promo-status-select').value;

  const newPromo = {
    id: 'promo-' + Date.now(),
    title,
    code,
    discount,
    description,
    expiry: expiry || addMonthsToDate(new Date().toISOString().split('T')[0], 1),
    status
  };

  State.promotions.unshift(newPromo);
  saveStateToStorage();
  closeModal('modal-add-promo');
  document.getElementById('form-add-promo').reset();
  showToast(`Promotion "${title}" enregistrée.`, 'success');
  renderPromotions();
  renderDashboard();
}

function deletePromo(promoId) {
  State.promotions = State.promotions.filter(p => p.id !== promoId);
  saveStateToStorage();
  showToast("Promotion supprimée.", "info");
  renderPromotions();
  renderDashboard();
}

// ==========================================================================
// 8. WHATSAPP CENTER & TEMPLATES
// ==========================================================================

function renderWhatsAppCenter() {
  loadSelectedTemplate();
  populateSchoolSelect('wa-preview-school-select');
  updateWhatsAppPreview();
}

function loadSelectedTemplate() {
  const selector = document.getElementById('wa-template-selector');
  const content = document.getElementById('wa-template-content');
  if (!selector || !content) return;

  const tplKey = selector.value;
  content.value = State.templates[tplKey] || DEFAULT_TEMPLATES[tplKey] || '';
  updateWhatsAppPreview();
}

function saveWhatsAppTemplates() {
  const selector = document.getElementById('wa-template-selector');
  const content = document.getElementById('wa-template-content');
  if (!selector || !content) return;

  const tplKey = selector.value;
  State.templates[tplKey] = content.value;
  saveStateToStorage();
  showToast("Modèle de message WhatsApp enregistré.", "success");
  updateWhatsAppPreview();
}

function updateWhatsAppPreview() {
  const previewBox = document.getElementById('wa-live-preview-box');
  const schoolSelect = document.getElementById('wa-preview-school-select');
  const selector = document.getElementById('wa-template-selector');
  if (!previewBox || !schoolSelect || !selector) return;

  const schoolId = schoolSelect.value;
  const school = State.schools.find(s => s.id === schoolId) || State.schools[0];
  const tplKey = selector.value;

  if (school) {
    previewBox.textContent = generateWhatsAppText(school, tplKey);
  } else {
    previewBox.textContent = "Veuillez inscrire au moins une école pour prévisualiser le message.";
  }
}

function testSendWhatsApp() {
  const schoolSelect = document.getElementById('wa-preview-school-select');
  const selector = document.getElementById('wa-template-selector');
  if (!schoolSelect || !selector) return;

  const school = State.schools.find(s => s.id === schoolSelect.value);
  if (!school) {
    showToast("Veuillez sélectionner une école valide.", "error");
    return;
  }

  sendWhatsAppToSchool(school.id, selector.value);
}

// ==========================================================================
// 9. INVOICES & RECEIPTS SAAS GENERATOR
// ==========================================================================

function renderInvoicesTab() {
  populateSchoolSelect('inv-school-select');
  renderInvoicePreview();
}

function populateSchoolSelect(selectId) {
  const select = document.getElementById(selectId);
  if (!select) return;

  const currentVal = select.value;
  select.innerHTML = State.schools.map(s => `
    <option value="${s.id}">${escapeHtml(s.name)} (Fondateur: ${escapeHtml(s.founderName)})</option>
  `).join('');

  if (currentVal && State.schools.some(s => s.id === currentVal)) {
    select.value = currentVal;
  }
}

function renderInvoicePreview() {
  const select = document.getElementById('inv-school-select');
  if (!select) return;

  const school = State.schools.find(s => s.id === select.value) || State.schools[0];
  if (!school) return;

  const period = parseInt(document.getElementById('inv-period-select').value, 10) || 1;
  const method = document.getElementById('inv-payment-method').value;
  const status = document.getElementById('inv-status-select').value;
  const price = school.monthlyPrice || 30000;
  const total = price * period;

  document.getElementById('inv-date-now').textContent = `Date : ${new Date().toLocaleDateString('fr-FR')}`;
  document.getElementById('inv-ref-number').textContent = `FACT-${new Date().getFullYear()}-${school.code || '001'}`;
  
  const badgeStatus = document.getElementById('inv-badge-status');
  if (badgeStatus) {
    if (status === 'PAID') {
      badgeStatus.className = 'pill pill-success';
      badgeStatus.textContent = 'ACQUITTÉ (PAYÉ)';
    } else {
      badgeStatus.className = 'pill pill-warning';
      badgeStatus.textContent = 'PROFORMA (EN ATTENTE)';
    }
  }

  document.getElementById('inv-client-school').textContent = school.name;
  document.getElementById('inv-client-founder').textContent = `Fondateur : ${school.founderName || 'N/A'}`;
  document.getElementById('inv-client-phone').textContent = `Téléphone : ${school.founderPhone || 'N/A'}`;
  document.getElementById('inv-client-city').textContent = `Ville : ${school.city || 'Non renseignée'}`;
  document.getElementById('inv-payment-details').textContent = `Règlement : ${method}`;

  document.getElementById('inv-table-pack').textContent = school.pack || 'Standard';
  document.getElementById('inv-table-period').textContent = `${period} Mois`;
  document.getElementById('inv-table-price').textContent = formatMoney(total);
  document.getElementById('inv-total-amount').textContent = formatMoney(total);
}

function printInvoice() {
  window.print();
}

function sendInvoiceWhatsApp() {
  const select = document.getElementById('inv-school-select');
  if (!select) return;
  const school = State.schools.find(s => s.id === select.value);
  if (!school) return;

  const period = document.getElementById('inv-period-select').value;
  const total = (school.monthlyPrice || 30000) * parseInt(period, 10);
  const sanitized = sanitizePhoneForWhatsApp(school.whatsapp || school.founderPhone);

  const msg = `📄 *FACTURE D'ABONNEMENT EDUGEST*\n\nÉtablissement : *${school.name}*\nFondateur : ${school.founderName}\nPériode : ${period} Mois (${school.pack})\nMontant Total : *${formatMoney(total)}*\n\nNuméros de règlement :\n${buildPaymentMethodsText()}\n\nMerci de votre confiance !`;
  const waUrl = `https://wa.me/${sanitized}?text=${encodeURIComponent(msg)}`;
  window.open(waUrl, '_blank');
}

// ==========================================================================
// 10. BACKUP, EXPORT & SYSTEM
// ==========================================================================

function exportSchoolsCsv() {
  const headers = ['ID', 'Nom Ecole', 'Code', 'Ville', 'Fondateur', 'Telephone', 'WhatsApp', 'Pack', 'Prix Mensuel', 'Statut', 'Date Expiration'];
  const rows = State.schools.map(s => [
    s.id,
    `"${(s.name || '').replace(/"/g, '""')}"`,
    s.code,
    `"${(s.city || '').replace(/"/g, '""')}"`,
    `"${(s.founderName || '').replace(/"/g, '""')}"`,
    s.founderPhone,
    s.whatsapp,
    s.pack,
    s.monthlyPrice,
    s.status,
    s.subscriptionEnd
  ]);

  const csvContent = 'data:text/csv;charset=utf-8,\uFEFF' + [headers.join(','), ...rows.map(r => r.join(','))].join('\n');
  const encodedUri = encodeURI(csvContent);
  const link = document.createElement('a');
  link.setAttribute('href', encodedUri);
  link.setAttribute('download', `edugest_ecoles_${new Date().toISOString().split('T')[0]}.csv`);
  document.body.appendChild(link);
  link.click();
  document.body.removeChild(link);
  showToast("Fichier CSV téléchargé avec succès.", "success");
}

function exportFullBackup() {
  const data = {
    version: '2.0',
    exportDate: new Date().toISOString(),
    schools: State.schools,
    paymentMethods: State.paymentMethods,
    promotions: State.promotions,
    templates: State.templates
  };

  const jsonStr = 'data:text/json;charset=utf-8,' + encodeURIComponent(JSON.stringify(data, null, 2));
  const link = document.createElement('a');
  link.setAttribute('href', jsonStr);
  link.setAttribute('download', `edugest_sauvegarde_superadmin_${new Date().toISOString().split('T')[0]}.json`);
  document.body.appendChild(link);
  link.click();
  document.body.removeChild(link);
  showToast("Sauvegarde JSON exportée.", "success");
}

function handleImportBackup(e) {
  const file = e.target.files[0];
  if (!file) return;

  const reader = new FileReader();
  reader.onload = (event) => {
    try {
      const data = JSON.parse(event.target.result);
      if (data.schools) State.schools = data.schools;
      if (data.paymentMethods) State.paymentMethods = data.paymentMethods;
      if (data.promotions) State.promotions = data.promotions;
      if (data.templates) State.templates = data.templates;

      saveStateToStorage();
      showToast("Sauvegarde restaurée avec succès !", "success");
      renderDashboard();
      renderSchools();
    } catch (err) {
      showToast("Fichier de sauvegarde invalide.", "error");
    }
  };
  reader.readAsText(file);
}

async function resetToDemoData() {
  if (confirm("Voulez-vous supprimer les données locales et recharger les données du serveur ?")) {
    State.schools = [];
    State.paymentMethods = {};
    State.promotions = [];
    State.templates = {};
    localStorage.removeItem('edugest_admin_schools');
    localStorage.removeItem('edugest_admin_payments_config');
    localStorage.removeItem('edugest_admin_promos');
    localStorage.removeItem('edugest_admin_templates');
    await loadConnectedData();
    showToast("Les données locales ont été supprimées. Les données serveur ont été rechargées.", "info");
  }
}

function saveApiBaseUrl() {
  const input = document.getElementById('config-api-base-url');
  if (!input) return;
  const val = input.value.trim();
  State.apiBaseUrl = val;
  localStorage.setItem('edugest_admin_api_url', val);
  closeModal('modal-api-config');
  showToast(`URL Backend configurée : ${val}`, 'info');
  checkBackendHealth();
}

async function checkBackendHealth() {
  const dot = document.getElementById('server-status-dot');
  const text = document.getElementById('server-status-text');

  try {
    const res = await fetch(`${State.apiBaseUrl}/api/schools`, { method: 'GET' });
    if (res.ok) {
      State.isOnline = true;
      if (dot) { dot.className = 'status-dot online'; }
      if (text) { text.textContent = 'Backend Connecté'; }
    } else {
      throw new Error();
    }
  } catch (_) {
    State.isOnline = false;
    if (dot) { dot.className = 'status-dot offline'; }
    if (text) { text.textContent = 'Mode Autonome'; }
  }
}

// ==========================================================================
// INITIALIZATION ON PAGE LOAD
// ==========================================================================

document.addEventListener('DOMContentLoaded', () => {
  loadStateFromStorage();

  // Bind Sidebar Navigation Click
  document.querySelectorAll('.sidebar-nav .nav-item').forEach(item => {
    item.addEventListener('click', (e) => {
      e.preventDefault();
      const tabId = item.getAttribute('data-tab');
      if (tabId) switchTab(tabId);
      
      // Close mobile menu if open
      const sidebar = document.getElementById('sidebar');
      if (sidebar) sidebar.classList.remove('open');
    });
  });

  // Mobile menu toggle
  const mobileBtn = document.getElementById('mobile-menu-toggle');
  if (mobileBtn) {
    mobileBtn.addEventListener('click', () => {
      const sidebar = document.getElementById('sidebar');
      if (sidebar) sidebar.classList.toggle('open');
    });
  }

  // Theme Toggle
  const themeBtn = document.getElementById('theme-toggle-btn');
  if (themeBtn) {
    if (localStorage.getItem('edugest_admin_theme') === 'light') {
      document.body.classList.add('light-theme');
    }
    themeBtn.addEventListener('click', () => {
      document.body.classList.toggle('light-theme');
      const isLight = document.body.classList.contains('light-theme');
      localStorage.setItem('edugest_admin_theme', isLight ? 'light' : 'dark');
      showToast(isLight ? "Thème clair activé" : "Thème sombre activé", "info");
    });
  }

  // Refresh All Button
  const refreshBtn = document.getElementById('refresh-all-btn');
  if (refreshBtn) {
    refreshBtn.addEventListener('click', () => {
      loadStateFromStorage();
      renderDashboard();
      renderSchools();
      checkBackendHealth();
      showToast("Données actualisées.", "info");
    });
  }

  // Search input live filtering
  const searchInput = document.getElementById('search-schools');
  if (searchInput) {
    searchInput.addEventListener('input', () => renderSchools());
  }

  // Initial render
  renderDashboard();
  renderSchools();
  renderPaymentMethodsConfig();
  checkBackendHealth();
  loadConnectedData();
});
