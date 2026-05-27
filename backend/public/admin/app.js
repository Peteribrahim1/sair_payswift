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
}

// Headers Helper
function getHeaders() {
  return {
    'Content-Type': 'application/json',
    'x-admin-secret': adminPasscode
  };
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
  });
});
