// Administrative Dashboard Application Code

const API_BASE = '/api';
let adminPasscode = localStorage.getItem('sair_admin_passcode') || '';

// Global Data Caches to enable instant client-side searching and filtering
let usersCache = [];
let transactionsCache = [];
let ticketsCache = [];

// DOM Elements
const loginScreen = document.getElementById('login-screen');
const adminLayout = document.getElementById('admin-layout');
const loginForm = document.getElementById('login-form');
const passcodeInput = document.getElementById('passcode-input');
const loginError = document.getElementById('login-error');
const logoutBtn = document.getElementById('logout-btn');
const tabTitle = document.getElementById('tab-title');

// Stats Cards
const statUsers = document.getElementById('stat-users');
const statTransactions = document.getElementById('stat-transactions');
const statTickets = document.getElementById('stat-tickets');
const statVolume = document.getElementById('stat-volume');
const pendingCountBadge = document.getElementById('pending-count-badge');

// Tabs & Navigation
const tabButtons = document.querySelectorAll('.nav-tab-btn');
const tabPanels = document.querySelectorAll('.tab-panel');

// Search & Filter Inputs
const userSearch = document.getElementById('user-search');
const txSearch = document.getElementById('tx-search');
const txFilterType = document.getElementById('tx-filter-type');
const ticketFilterBtns = document.querySelectorAll('.filter-btn');

let activeTicketFilter = 'all';

// Initialize Access Check
if (adminPasscode) {
  validateAndStartDashboard();
}

// Passcode Submission Event
loginForm.addEventListener('submit', (e) => {
  e.preventDefault();
  adminPasscode = passcodeInput.value.trim();
  validateAndStartDashboard();
});

// Logout Event
logoutBtn.addEventListener('click', () => {
  localStorage.removeItem('sair_admin_passcode');
  adminPasscode = '';
  usersCache = [];
  transactionsCache = [];
  ticketsCache = [];
  adminLayout.style.display = 'none';
  loginScreen.style.display = 'flex';
  passcodeInput.value = '';
});

// Authentication Validator
async function validateAndStartDashboard() {
  loginError.style.display = 'none';
  try {
    const success = await fetchStats();
    if (success) {
      localStorage.setItem('sair_admin_passcode', adminPasscode);
      loginScreen.style.display = 'none';
      adminLayout.style.display = 'grid';
      fetchAllData();
      
      // Bind settings form
      const settingsForm = document.getElementById('settings-form');
      if (settingsForm) {
        settingsForm.addEventListener('submit', handleSaveSettings);
      }
    } else {
      throw new Error('Unauthorized');
    }
  } catch (err) {
    console.error('Login validation error:', err);
    localStorage.removeItem('sair_admin_passcode');
    loginError.style.display = 'block';
  }
}

// Main Data Loader
function fetchAllData() {
  fetchUsers();
  fetchTransactions();
  fetchTickets();
  loadAirtime();
}

// Headers Helper
function getHeaders() {
  return {
    'Content-Type': 'application/json',
    'x-admin-secret': adminPasscode
  };
}

// ─── AIRTIME APPROVALS ────────────────────────────────────────────────────────

async function loadAirtime() {
  try {
    const res = await fetch('/api/admin/airtime', { headers: getHeaders() });
    const data = await res.json();
    if (res.ok && data.success) {
      renderAirtimeTable(data.transactions);
    }
  } catch (error) {
    console.error('Error loading airtime:', error);
  }
}

function renderAirtimeTable(transactions) {
  const tbody = document.getElementById('airtime-table-body');
  if (!tbody) return;
  tbody.innerHTML = '';
  if (transactions.length === 0) {
    tbody.innerHTML = '<tr><td colspan="6" class="empty-msg">No pending airtime conversions.</td></tr>';
    return;
  }
  transactions.forEach(tx => {
    const tr = document.createElement('tr');
    const userName = tx.user ? tx.user.fullName : 'Unknown User';
    
    tr.innerHTML = `
      <td>${userName}</td>
      <td>${tx.phone}</td>
      <td><span class="badge ${tx.network}">${tx.network.toUpperCase()}</span></td>
      <td>₦${tx.amount.toLocaleString(undefined, {minimumFractionDigits: 2})}</td>
      <td><span class="badge PENDING">PENDING</span></td>
      <td>
        <button class="btn btn-sm" onclick="approveAirtime('${tx.id}')" style="background: #27ae60; color: white;">Approve</button>
        <button class="btn btn-sm" onclick="rejectAirtime('${tx.id}')" style="background: #e74c3c; color: white; margin-left: 5px;">Reject</button>
      </td>
    `;
    tbody.appendChild(tr);
  });
}

async function approveAirtime(id) {
  if (!confirm('Are you sure you want to approve this airtime conversion? The user will be credited immediately.')) return;
  try {
    const res = await fetch(`/api/admin/airtime/${id}/approve`, { method: 'PUT', headers: getHeaders() });
    if (res.ok) {
      alert('Approved successfully.');
      loadAirtime();
      fetchStats();
    } else {
      const data = await res.json();
      alert('Error: ' + data.error);
    }
  } catch (error) {
    alert('Failed to approve');
  }
}

async function rejectAirtime(id) {
  if (!confirm('Are you sure you want to reject this airtime conversion?')) return;
  try {
    const res = await fetch(`/api/admin/airtime/${id}/reject`, { method: 'PUT', headers: getHeaders() });
    if (res.ok) {
      alert('Rejected successfully.');
      loadAirtime();
    } else {
      const data = await res.json();
      alert('Error: ' + data.error);
    }
  } catch (error) {
    alert('Failed to reject');
  }
}

// ─── PRICING SETTINGS ────────────────────────────────────────────────────────
async function loadSettings() {
  try {
    const res = await fetch('/api/admin/settings', { headers: getHeaders() });
    const data = await res.json();
    if (data.success && data.settings) {
      document.getElementById('set-data').value = data.settings.dataMarkupPercent;
      document.getElementById('set-airtime').value = data.settings.airtimeMarkupPercent;
      document.getElementById('set-airtime-cash').value = data.settings.airtimeToCashRate;
      document.getElementById('set-bills').value = data.settings.billConvenienceFee;
    }
  } catch (err) {
    console.error('Failed to load settings', err);
  }
}

async function handleSaveSettings(e) {
  e.preventDefault();
  const btn = e.target.querySelector('button');
  const originalText = btn.innerText;
  btn.innerText = 'Saving...';
  
  const payload = {
    dataMarkupPercent: parseFloat(document.getElementById('set-data').value),
    airtimeMarkupPercent: parseFloat(document.getElementById('set-airtime').value),
    airtimeToCashRate: parseFloat(document.getElementById('set-airtime-cash').value),
    billConvenienceFee: parseFloat(document.getElementById('set-bills').value)
  };

  try {
    const res = await fetch('/api/admin/settings', {
      method: 'PUT',
      headers: getHeaders(),
      body: JSON.stringify(payload)
    });
    const data = await res.json();
    if (data.success) {
      btn.innerText = 'Saved!';
      setTimeout(() => btn.innerText = originalText, 2000);
    } else {
      alert('Failed to save settings');
      btn.innerText = originalText;
    }
  } catch (err) {
    console.error(err);
    alert('Error saving settings');
    btn.innerText = originalText;
  }
}

// ─── Stat Counters Fetching ──────────────────────────────────────────────────
async function fetchStats() {
  try {
    const usersRes = await fetch(`${API_BASE}/admin/users`, { headers: getHeaders() });
    if (usersRes.status === 401 || usersRes.status === 403) return false;
    
    const usersData = await usersRes.json();
    const txRes = await fetch(`${API_BASE}/admin/transactions`, { headers: getHeaders() });
    const txData = await txRes.json();
    const ticketsRes = await fetch(`${API_BASE}/admin/tickets`, { headers: getHeaders() });
    const ticketsData = await ticketsRes.json();

    if (usersData.success && txData.success && ticketsData.success) {
      // Calculate Stats
      const totalUsers = usersData.users.length;
      const totalTxs = txData.transactions.length;
      
      const pendingTickets = ticketsData.tickets.filter(t => t.status === 'PENDING');
      const activeTicketsCount = pendingTickets.length;
      
      // Update sidebar badge
      if (activeTicketsCount > 0) {
        pendingCountBadge.textContent = activeTicketsCount;
        pendingCountBadge.style.display = 'inline-block';
      } else {
        pendingCountBadge.style.display = 'none';
      }

      // Total transaction volume
      const totalVol = txData.transactions
        .filter(tx => tx.status === 'COMPLETED')
        .reduce((sum, tx) => sum + tx.amount, 0);

      // Render Dashboard Stats Cards
      statUsers.textContent = totalUsers;
      statTransactions.textContent = totalTxs;
      statTickets.textContent = activeTicketsCount;
      statVolume.textContent = `₦${totalVol.toLocaleString('en-US', { minimumFractionDigits: 2 })}`;

      // Update Dashboard Recent Boards
      renderRecentDashboardItems(usersData.users, txData.transactions, ticketsData.tickets);

      return true;
    }
  } catch (e) {
    console.error('Error fetching stats:', e);
  }
  return false;
}

// Render Recent lists on the main overview dashboard tab
function renderRecentDashboardItems(users, transactions, tickets) {
  // Render Recent Activities (mix of users & transactions)
  const activitiesContainer = document.getElementById('dashboard-activities');
  activitiesContainer.innerHTML = '';
  
  const recentTxs = transactions.slice(0, 5);
  if (recentTxs.length === 0) {
    activitiesContainer.innerHTML = '<p class="loading-placeholder">No recent transaction logs found.</p>';
  } else {
    recentTxs.forEach(tx => {
      const date = new Date(tx.createdAt).toLocaleTimeString('en-US', { hour: '2-digit', minute: '2-digit' });
      const item = document.createElement('div');
      item.className = 'activity-item';
      item.innerHTML = `
        <span class="activity-badge ${tx.type === 'CONVERT_AIRTIME' ? 'bg-blue' : 'bg-purple'}" style="background: rgba(79, 70, 229, 0.1); color: #818CF8; padding: 4px 8px; border-radius: 6px; font-weight: bold; font-size: 10px;">${tx.type}</span>
        <div class="activity-details">
          <strong>${tx.user?.fullName || 'User'}</strong> processed <strong>₦${tx.amount.toLocaleString()}</strong> (${tx.status})
        </div>
        <span class="activity-time">${date}</span>
      `;
      activitiesContainer.appendChild(item);
    });
  }

  // Render Urgent support tickets (Pending status only)
  const ticketsContainer = document.getElementById('dashboard-tickets');
  ticketsContainer.innerHTML = '';
  
  const pendingTickets = tickets.filter(t => t.status === 'PENDING').slice(0, 5);
  if (pendingTickets.length === 0) {
    ticketsContainer.innerHTML = '<p class="loading-placeholder">No pending support issues! Clear board ✅</p>';
  } else {
    pendingTickets.forEach(t => {
      const date = new Date(t.createdAt).toLocaleDateString('en-US', { month: 'short', day: 'numeric' });
      const item = document.createElement('div');
      item.className = 'activity-item';
      item.innerHTML = `
        <span class="activity-badge" style="background: rgba(255, 152, 0, 0.1); color: #FF9800; padding: 4px 8px; border-radius: 6px; font-weight: bold; font-size: 10px;">PENDING</span>
        <div class="activity-details">
          <strong>${t.user?.fullName || 'User'}</strong>: "${t.subject}"
        </div>
        <span class="activity-time">${date}</span>
      `;
      ticketsContainer.appendChild(item);
    });
  }
}

// ─── Users Fetching & Rendering ──────────────────────────────────────────────
async function fetchUsers() {
  try {
    const res = await fetch(`${API_BASE}/admin/users`, { headers: getHeaders() });
    const data = await res.json();
    if (data.success) {
      usersCache = data.users;
      renderUsers();
    }
  } catch (e) {
    console.error('Error fetching users:', e);
  }
}

function renderUsers() {
  const tbody = document.getElementById('users-table-body');
  tbody.innerHTML = '';

  const query = userSearch.value.trim().toLowerCase();
  const filtered = usersCache.filter(u => 
    (u.fullName || '').toLowerCase().includes(query) ||
    u.email.toLowerCase().includes(query) ||
    (u.phone || '').includes(query)
  );

  if (filtered.length === 0) {
    tbody.innerHTML = '<tr><td colspan="6" style="text-align: center; color: var(--text-secondary);">No registered users match your search query.</td></tr>';
    return;
  }

  filtered.forEach(u => {
    const date = new Date(u.createdAt).toLocaleDateString('en-US', { year: 'numeric', month: 'short', day: 'numeric' });
    const tr = document.createElement('tr');
    tr.innerHTML = `
      <td style="font-weight: 700;">${u.fullName || 'No Name'}</td>
      <td>${u.email}</td>
      <td>${u.phone || 'N/A'}</td>
      <td style="font-weight: bold; font-family: var(--font-display);">₦${u.balance.toLocaleString('en-US', { minimumFractionDigits: 2 })}</td>
      <td>
        <span class="chip ${u.kycVerified ? 'verified' : 'unverified'}">
          ${u.kycVerified ? 'Verified' : 'Unverified'}
        </span>
      </td>
      <td>${date}</td>
      <td>
        <button onclick="openFundModal('${u.id}', '${(u.fullName || u.email).replace(/'/g, "\\'")}')" class="btn btn-primary" style="padding: 6px 12px; font-size: 12px;">Manage Wallet</button>
      </td>
    `;
    tbody.appendChild(tr);
  });
}

userSearch.addEventListener('input', renderUsers);

// ─── Transactions Fetching & Rendering ───────────────────────────────────────
async function fetchTransactions() {
  try {
    const res = await fetch(`${API_BASE}/admin/transactions`, { headers: getHeaders() });
    const data = await res.json();
    if (data.success) {
      transactionsCache = data.transactions;
      renderTransactions();
    }
  } catch (e) {
    console.error('Error fetching transactions:', e);
  }
}

function renderTransactions() {
  const tbody = document.getElementById('tx-table-body');
  tbody.innerHTML = '';

  const query = txSearch.value.trim().toLowerCase();
  const typeFilter = txFilterType.value;

  const filtered = transactionsCache.filter(tx => {
    const matchesQuery = 
      (tx.reference || '').toLowerCase().includes(query) ||
      (tx.phone || '').includes(query) ||
      (tx.user?.fullName || '').toLowerCase().includes(query) ||
      tx.user?.email.toLowerCase().includes(query);
      
    const matchesType = !typeFilter || tx.type === typeFilter;
    
    return matchesQuery && matchesType;
  });

  if (filtered.length === 0) {
    tbody.innerHTML = '<tr><td colspan="7" style="text-align: center; color: var(--text-secondary);">No transaction records match filters.</td></tr>';
    return;
  }

  filtered.forEach(tx => {
    const date = new Date(tx.createdAt).toLocaleDateString('en-US', { month: 'short', day: 'numeric', hour: '2-digit', minute: '2-digit' });
    const amountSign = tx.type === 'CONVERT_AIRTIME' || tx.type === 'FUND' ? '+' : '-';
    const amountColor = tx.type === 'CONVERT_AIRTIME' || tx.type === 'FUND' ? 'var(--color-resolved)' : 'var(--text-main)';
    
    const tr = document.createElement('tr');
    tr.innerHTML = `
      <td>
        <div style="display: flex; flex-direction: column;">
          <span style="font-weight: 700; font-size: 13px;">${tx.user?.fullName || 'User'}</span>
          <span style="font-size: 10px; color: var(--text-secondary);">${tx.user?.email}</span>
        </div>
      </td>
      <td style="font-weight: 700; font-size: 12px;">${tx.type}</td>
      <td style="font-weight: bold; color: ${amountColor}; font-family: var(--font-display);">${amountSign}₦${tx.amount.toLocaleString('en-US', { minimumFractionDigits: 2 })}</td>
      <td>${tx.phone || tx.network || 'N/A'}</td>
      <td style="font-family: monospace; font-size: 12px; color: var(--text-secondary);">${tx.reference || 'N/A'}</td>
      <td>
        <span class="status-badge ${tx.status.toLowerCase()}">${tx.status}</span>
      </td>
      <td style="font-size: 12px; color: var(--text-secondary);">${date}</td>
    `;
    tbody.appendChild(tr);
  });
}

txSearch.addEventListener('input', renderTransactions);
txFilterType.addEventListener('change', renderTransactions);

// ─── Support Tickets Fetching & Rendering ────────────────────────────────────
async function fetchTickets() {
  try {
    const res = await fetch(`${API_BASE}/admin/tickets`, { headers: getHeaders() });
    const data = await res.json();
    if (data.success) {
      ticketsCache = data.tickets;
      renderTickets();
    }
  } catch (e) {
    console.error('Error fetching tickets:', e);
  }
}

function renderTickets() {
  const container = document.getElementById('tickets-container');
  container.innerHTML = '';

  const filtered = ticketsCache.filter(t => {
    if (activeTicketFilter === 'all') return true;
    return t.status === activeTicketFilter;
  });

  if (filtered.length === 0) {
    container.innerHTML = '<div style="grid-column: span 2; text-align: center; color: var(--text-secondary); padding: 40px;">No support issues found in this category.</div>';
    return;
  }

  filtered.forEach(t => {
    const date = new Date(t.createdAt).toLocaleDateString('en-US', { month: 'short', day: 'numeric', hour: '2-digit', minute: '2-digit' });
    const card = document.createElement('div');
    card.className = 'ticket-card';
    card.innerHTML = `
      <div class="ticket-card-header">
        <span class="ticket-subject">${t.subject}</span>
        <span class="ticket-badge ${t.status.toLowerCase()}">${t.status}</span>
      </div>
      <p class="ticket-msg">${t.message}</p>
      <div class="ticket-footer">
        <div class="ticket-user">
          <span class="user-name">${t.user?.fullName || 'Anonymous'}</span>
          <span class="user-email">${t.user?.email || ''} ${t.user?.phone ? `(${t.user.phone})` : ''}</span>
          <span style="font-size: 9px; color: var(--text-secondary); margin-top: 4px;"><i class="fa-solid fa-clock"></i> ${date}</span>
        </div>
        ${t.status === 'PENDING' ? `
          <button class="btn-resolve" onclick="resolveTicket('${t.id}')">
            <i class="fa-solid fa-check"></i> Resolve
          </button>
        ` : ''}
      </div>
    `;
    container.appendChild(card);
  });
}

// Tab ticket filter clicks
ticketFilterBtns.forEach(btn => {
  btn.addEventListener('click', () => {
    ticketFilterBtns.forEach(b => b.classList.remove('active'));
    btn.classList.add('active');
    activeTicketFilter = btn.dataset.filter;
    renderTickets();
  });
});

// Resolve Ticket Handler
window.resolveTicket = async function(id) {
  if (!confirm('Are you sure you want to mark this support ticket as resolved?')) return;
  try {
    const res = await fetch(`${API_BASE}/admin/tickets/${id}/resolve`, {
      method: 'PUT',
      headers: getHeaders()
    });
    const data = await res.json();
    if (data.success) {
      alert('Ticket marked as resolved successfully!');
      // Re-fetch everything to update dashboards instantly
      fetchStats();
      fetchAllData();
    } else {
      alert(`Error: ${data.error || 'Failed to resolve ticket'}`);
    }
  } catch (e) {
    console.error('Error resolving ticket:', e);
    alert('Failed to resolve support ticket. Please check connection.');
  }
};

// ─── Sidebar Tabs Controller ─────────────────────────────────────────────────
tabButtons.forEach(btn => {
  btn.addEventListener('click', () => {
    const tabName = btn.dataset.tab;

    // Switch active buttons
    tabButtons.forEach(b => b.classList.remove('active'));
    btn.classList.add('active');

    // Switch active panels
    tabPanels.forEach(panel => {
      panel.classList.remove('active');
      if (panel.id === tabName) {
        panel.classList.add('active');
      }
    });

    // Update title header
    tabTitle.textContent = btn.innerText.trim();

    // Reload tab data
    fetchStats();
    if (tabName === 'tab-users') fetchUsers();
    if (tabName === 'tab-transactions') fetchTransactions();
    if (tabName === 'tab-tickets') fetchTickets();
    if (tabName === 'tab-airtime') loadAirtime();
    if (tabName === 'tab-kyc') loadKyc();
    if (tabName === 'tab-settings') loadSettings();
    if (tabName === 'tab-adverts') loadAdverts();
  });
});
// ─── Manual Wallet Funding ───────────────────────────────────────────────────
function openFundModal(userId, userName) {
  document.getElementById('fund-user-id').value = userId;
  document.getElementById('fund-modal-user-name').textContent = `User: ${userName}`;
  document.getElementById('fund-amount').value = '';
  document.getElementById('fund-reason').value = '';
  document.getElementById('fund-action').value = 'CREDIT';
  document.getElementById('fund-modal').style.display = 'flex';
}

document.getElementById('fund-form')?.addEventListener('submit', async (e) => {
  e.preventDefault();
  const btn = document.getElementById('fund-submit-btn');
  btn.textContent = 'Processing...';
  btn.disabled = true;

  const id = document.getElementById('fund-user-id').value;
  const amount = document.getElementById('fund-amount').value;
  const action = document.getElementById('fund-action').value;
  const reason = document.getElementById('fund-reason').value;

  try {
    const res = await fetch(`${API_BASE}/admin/users/${id}/fund`, {
      method: 'POST',
      headers: getHeaders(),
      body: JSON.stringify({ amount: Number(amount), action, reason })
    });
    const data = await res.json();
    
    if (data.success) {
      alert(`Successfully updated wallet! New balance: ₦${data.user.balance}`);
      document.getElementById('fund-modal').style.display = 'none';
      fetchUsers(); // Refresh table
    } else {
      alert(data.error || 'Failed to update wallet');
    }
  } catch (error) {
    console.error('Fund error:', error);
    alert('Network error while updating wallet');
  } finally {
    btn.textContent = 'Confirm Adjustment';
    btn.disabled = false;
  }
});
// ─── KYC Approvals ──────────────────────────────────────────────────────────
async function loadKyc() {
  const container = document.getElementById('kyc-container');
  container.innerHTML = '<p class="loading-placeholder">Loading pending KYC...</p>';

  try {
    const res = await fetch(`${API_BASE}/admin/kyc`, { headers: getHeaders() });
    const data = await res.json();
    
    if (!data.success || data.users.length === 0) {
      container.innerHTML = '<p style="color:var(--text-secondary); text-align:center; padding: 24px;">No pending KYC requests at the moment.</p>';
      return;
    }

    container.innerHTML = '';
    data.users.forEach(u => {
      const card = document.createElement('div');
      card.className = 'ticket-card';
      card.style.display = 'flex';
      card.style.flexDirection = 'column';
      card.style.gap = '12px';
      
      const docImg = u.kycDocument ? `<img src="${u.kycDocument}" style="width:100%; height:200px; object-fit:cover; border-radius:8px; border:1px solid #ddd;" alt="ID Card"/>` : '<div style="height:200px; background:#f0f0f0; display:flex; align-items:center; justify-content:center; border-radius:8px; color:#999;">No Image Uploaded</div>';

      card.innerHTML = `
        <div style="display:flex; justify-content:space-between;">
          <strong>${u.fullName || 'Unknown User'}</strong>
          <span style="font-size:12px; color:#666;">${new Date(u.createdAt).toLocaleDateString()}</span>
        </div>
        <div style="font-size:13px; color:#555;">
          <div><strong>Email:</strong> ${u.email}</div>
          <div><strong>BVN:</strong> ${u.bvn || 'N/A'}</div>
          <div><strong>NIN:</strong> ${u.nin || 'N/A'}</div>
        </div>
        ${docImg}
        <div style="display:flex; gap:8px; margin-top:8px;">
          <button onclick="approveKyc('${u.id}')" class="btn btn-primary" style="flex:1;">Approve</button>
          <button onclick="rejectKyc('${u.id}')" class="btn" style="flex:1; background:#fee; color:#e00;">Reject</button>
        </div>
      `;
      container.appendChild(card);
    });
  } catch (error) {
    console.error('loadKyc error:', error);
    container.innerHTML = '<p style="color:red;">Failed to load KYC requests.</p>';
  }
}

async function approveKyc(id) {
  if (!confirm('Are you sure you want to verify this user?')) return;
  try {
    const res = await fetch(`${API_BASE}/admin/kyc/${id}/approve`, { method: 'POST', headers: getHeaders() });
    const data = await res.json();
    if (data.success) {
      alert('KYC Approved successfully.');
      loadKyc();
    } else {
      alert('Failed to approve KYC');
    }
  } catch (e) {
    console.error(e);
  }
}

async function rejectKyc(id) {
  if (!confirm('Are you sure you want to reject this KYC?')) return;
  try {
    const res = await fetch(`${API_BASE}/admin/kyc/${id}/reject`, { method: 'POST', headers: getHeaders() });
    const data = await res.json();
    if (data.success) {
      alert('KYC Rejected.');
      loadKyc();
    } else {
      alert('Failed to reject KYC');
    }
  } catch (e) {
    console.error(e);
  }
}

// ─── BROADCAST LOGIC ──────────────────────────────────────────────────────────
const broadcastForm = document.getElementById('broadcast-form');
if (broadcastForm) {
  broadcastForm.addEventListener('submit', async (e) => {
    e.preventDefault();
    const title = document.getElementById('broadcast-title').value;
    const message = document.getElementById('broadcast-message').value;
    const btn = broadcastForm.querySelector('button[type="submit"]');

    if (!confirm('Are you sure you want to send this broadcast to EVERY user?')) return;

    btn.textContent = 'Sending...';
    btn.disabled = true;

    try {
      const res = await fetch(`${API_BASE}/admin/broadcast`, {
        method: 'POST',
        headers: getHeaders(),
        body: JSON.stringify({ title, message })
      });
      const data = await res.json();
      
      if (data.success) {
        alert(data.message || 'Broadcast sent successfully!');
        broadcastForm.reset();
      } else {
        alert(data.error || 'Failed to send broadcast');
      }
    } catch (error) {
      console.error(error);
      alert('An error occurred while sending the broadcast.');
    } finally {
      btn.textContent = 'Send Broadcast';
      btn.disabled = false;
    }
  });
}

// ─── ADVERTS MANAGEMENT ───────────────────────────────────────────────────────

const advertForm = document.getElementById('advert-form');

if (advertForm) {
  advertForm.addEventListener('submit', async (e) => {
    e.preventDefault();
    const btn = advertForm.querySelector('button');
    const originalText = btn.innerHTML;
    btn.innerHTML = '<i class="fa-solid fa-spinner fa-spin"></i> Publishing...';
    btn.disabled = true;

    const title = document.getElementById('adv-title').value.trim();
    const contactLink = document.getElementById('adv-link').value.trim();
    const fileInput = document.getElementById('adv-image');

    if (!title || !contactLink || !fileInput.files[0]) {
      btn.innerHTML = '<i class="fa-solid fa-triangle-exclamation"></i> Error: All fields are required';
      btn.style.backgroundColor = '#e74c3c';
      setTimeout(() => {
        btn.innerHTML = originalText;
        btn.style.backgroundColor = '';
        btn.disabled = false;
      }, 3000);
      return;
    }

    try {
      // Compress image to Base64
      const file = fileInput.files[0];
      const imageBase64 = await compressImage(file);

      const payload = { title, contactLink, imageBase64 };

      const res = await fetch('/api/admin/adverts', {
        method: 'POST',
        headers: getHeaders(),
        body: JSON.stringify(payload)
      });
      const data = await res.json();
      if (res.ok && data.success) {
        btn.innerHTML = '<i class="fa-solid fa-check"></i> Published Successfully!';
        btn.style.backgroundColor = '#27ae60';
        setTimeout(() => {
          btn.innerHTML = originalText;
          btn.style.backgroundColor = '';
          btn.disabled = false;
        }, 2000);
        
        advertForm.reset();
        loadAdverts();
      } else {
        btn.innerHTML = '<i class="fa-solid fa-triangle-exclamation"></i> Error: ' + (data.error || 'Failed');
        btn.style.backgroundColor = '#e74c3c';
        setTimeout(() => {
          btn.innerHTML = originalText;
          btn.style.backgroundColor = '';
          btn.disabled = false;
        }, 3000);
      }
    } catch (error) {
      console.error('Error creating advert:', error);
      btn.innerHTML = '<i class="fa-solid fa-wifi"></i> Network/Compression Error';
      btn.style.backgroundColor = '#e74c3c';
      setTimeout(() => {
        btn.innerHTML = originalText;
        btn.style.backgroundColor = '';
        btn.disabled = false;
      }, 3000);
    }
  });
}

function compressImage(file) {
  return new Promise((resolve, reject) => {
    const reader = new FileReader();
    reader.readAsDataURL(file);
    reader.onload = event => {
      const img = new Image();
      img.src = event.target.result;
      img.onload = () => {
        const canvas = document.createElement('canvas');
        const MAX_WIDTH = 800;
        const scaleSize = MAX_WIDTH / img.width;
        canvas.width = MAX_WIDTH;
        canvas.height = img.height * scaleSize;
        const ctx = canvas.getContext('2d');
        ctx.drawImage(img, 0, 0, canvas.width, canvas.height);
        const dataUrl = canvas.toDataURL('image/jpeg', 0.8);
        resolve(dataUrl);
      };
      img.onerror = error => reject(error);
    };
    reader.onerror = error => reject(error);
  });
}

async function loadAdverts() {
  const container = document.getElementById('adverts-container');
  if (!container) return;

  container.innerHTML = '<p class="loading-placeholder">Loading active adverts...</p>';

  try {
    const res = await fetch('/api/admin/adverts', { headers: getHeaders() });
    const data = await res.json();
    if (res.ok && data.success) {
      renderAdverts(data.adverts);
    } else {
      container.innerHTML = '<p class="empty-msg" style="color: #e74c3c;">Failed to load adverts.</p>';
    }
  } catch (error) {
    console.error('Error loading adverts:', error);
    container.innerHTML = '<p class="empty-msg" style="color: #e74c3c;">Connection error.</p>';
  }
}

function renderAdverts(adverts) {
  const container = document.getElementById('adverts-container');
  container.innerHTML = '';

  if (!adverts || adverts.length === 0) {
    container.innerHTML = '<p class="empty-msg">No active adverts found. Create one above to show it in the app.</p>';
    return;
  }

  adverts.forEach(ad => {
    const card = document.createElement('div');
    card.className = 'ticket-card';
    card.style.padding = '12px';
    card.style.position = 'relative';

    card.innerHTML = `
      <div style="display: flex; justify-content: space-between; align-items: flex-start; margin-bottom: 12px;">
        <h3 style="margin: 0; font-size: 16px; color: #333;">${ad.title || 'Advert'}</h3>
        <button onclick="deleteAdvert('${ad.id}')" class="btn" style="background: transparent; color: #e74c3c; padding: 4px 8px; font-size: 14px;" title="Delete Advert">
          <i class="fa-solid fa-trash"></i>
        </button>
      </div>
      <div style="width: 100%; height: 140px; border-radius: 8px; overflow: hidden; margin-bottom: 12px; background: #f0f0f0;">
        <img src="${ad.imageBase64}" style="width: 100%; height: 100%; object-fit: cover;" alt="Advert Preview" />
      </div>
      <div style="font-size: 13px; color: #555;">
        <strong>Link:</strong> <a href="${ad.contactLink}" target="_blank" style="color: #2980b9; text-decoration: none;">${ad.contactLink}</a>
      </div>
    `;
    container.appendChild(card);
  });
}

async function deleteAdvert(id) {
  if (!confirm('Are you sure you want to permanently delete this advert? It will disappear from all user apps immediately.')) return;
  try {
    const res = await fetch(`/api/admin/adverts/${id}`, { method: 'DELETE', headers: getHeaders() });
    if (res.ok) {
      loadAdverts(); // refresh list
    } else {
      const data = await res.json();
      alert('Error: ' + data.error);
    }
  } catch (error) {
    alert('Failed to delete advert');
  }
}
