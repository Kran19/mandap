/**
 * DLT SMS Dispatcher & Verifier Application Logic
 */

document.addEventListener('DOMContentLoaded', () => {
  // State
  let currentSettings = {
    uri: 'http://domain/sms-panel/api/http/index.php',
    username: '',
    apikey: '62CEF-9A446',
    sender_id: 'TXXTOO',
    template_id: '1607100000000313742',
    entity_id: '1401805350000060162',
    route: 'trans',
    template_pattern: "Dear {#var#} Your OTP for verification is {#var#}. Please enter this code to complete the process.\nRegards {#var#}\nTEXT2"
  };

  // DOM Elements
  const smsForm = document.getElementById('smsForm');
  const phoneInput = document.getElementById('phoneInput');
  const var1Input = document.getElementById('var1Input');
  const var2Input = document.getElementById('var2Input');
  const var3Input = document.getElementById('var3Input');
  const genOtpBtn = document.getElementById('genOtpBtn');
  const sendBtn = document.getElementById('sendBtn');
  const btnText = document.getElementById('btnText');
  const btnSpinner = document.getElementById('btnSpinner');

  const smsBubble = document.getElementById('smsBubble');
  const charCount = document.getElementById('charCount');
  const creditCount = document.getElementById('creditCount');
  const previewSender = document.getElementById('previewSender');

  // Inspector Elements
  const liveStatusBadge = document.getElementById('liveStatusBadge');
  const metricHttpCode = document.getElementById('metricHttpCode');
  const metricStatusDesc = document.getElementById('metricStatusDesc');
  const metricLatency = document.getElementById('metricLatency');
  const metricMsgId = document.getElementById('metricMsgId');
  const responseBox = document.getElementById('responseBox');
  const requestPayloadBox = document.getElementById('requestPayloadBox');
  const togglePayloadBtn = document.getElementById('togglePayloadBtn');

  // History Elements
  const historyTableBody = document.getElementById('historyTableBody');
  const refreshHistoryBtn = document.getElementById('refreshHistoryBtn');
  const clearHistoryBtn = document.getElementById('clearHistoryBtn');

  // Modal Elements
  const settingsModal = document.getElementById('settingsModal');
  const openSettingsBtn = document.getElementById('openSettingsBtn');
  const closeSettingsBtn = document.getElementById('closeSettingsBtn');
  const cancelSettingsBtn = document.getElementById('cancelSettingsBtn');
  const saveSettingsBtn = document.getElementById('saveSettingsBtn');

  const settingUri = document.getElementById('settingUri');
  const settingUsername = document.getElementById('settingUsername');
  const settingApiKey = document.getElementById('settingApiKey');
  const settingSender = document.getElementById('settingSender');
  const settingRoute = document.getElementById('settingRoute');
  const settingTemplateId = document.getElementById('settingTemplateId');
  const settingEntityId = document.getElementById('settingEntityId');
  const settingTemplatePattern = document.getElementById('settingTemplatePattern');

  // Helper: Quick phone setting
  window.setPhone = (num) => {
    phoneInput.value = num;
    phoneInput.focus();
  };

  // Random 6-digit OTP generator
  function generateRandomOtp() {
    return Math.floor(100000 + Math.random() * 900000).toString();
  }

  genOtpBtn.addEventListener('click', () => {
    const newOtp = generateRandomOtp();
    var2Input.value = newOtp;
    updatePreview();
  });

  // Calculate & Update Live Preview
  function updatePreview() {
    const v1 = var1Input.value.trim() || 'John Doe';
    const v2 = var2Input.value.trim() || '123456';
    const v3 = var3Input.value.trim() || 'TXXTOO Team';

    const template = currentSettings.template_pattern;
    previewSender.textContent = currentSettings.sender_id || 'TXXTOO';

    // Highlighted HTML Preview
    let htmlPreview = escapeHtml(template);
    
    // Replace sequential variables with styled badges
    let count = 0;
    htmlPreview = htmlPreview.replace(/\{#var#\}/g, () => {
      count++;
      if (count === 1) {
        return `<span class="highlight-var1">${escapeHtml(v1)}</span>`;
      } else if (count === 2) {
        return `<span class="highlight-var2">${escapeHtml(v2)}</span>`;
      } else if (count === 3) {
        return `<span class="highlight-var3">${escapeHtml(v3)}</span>`;
      }
      return '{#var#}';
    });

    smsBubble.innerHTML = htmlPreview;

    // Calculate plain text message length
    count = 0;
    const plainText = template.replace(/\{#var#\}/g, () => {
      count++;
      if (count === 1) return v1;
      if (count === 2) return v2;
      if (count === 3) return v3;
      return '';
    });

    const chars = plainText.length;
    charCount.textContent = `${chars} character${chars === 1 ? '' : 's'}`;

    // Standard GSM 7-bit calculation
    let parts = 1;
    if (chars > 160) {
      parts = Math.ceil(chars / 153);
    }
    creditCount.textContent = `${parts} SMS Part${parts > 1 ? 's' : ''} (GSM-7)`;
  }

  function escapeHtml(text) {
    const map = {
      '&': '&amp;',
      '<': '&lt;',
      '>': '&gt;',
      '"': '&quot;',
      "'": '&#039;'
    };
    return text.replace(/[&<>"']/g, (m) => map[m]);
  }

  // Bind inputs to preview updates
  [var1Input, var2Input, var3Input].forEach(input => {
    input.addEventListener('input', updatePreview);
  });

  // Toggle Payload
  togglePayloadBtn.addEventListener('click', () => {
    if (requestPayloadBox.style.display === 'none') {
      requestPayloadBox.style.display = 'block';
      togglePayloadBtn.textContent = 'Hide Request Payload';
    } else {
      requestPayloadBox.style.display = 'none';
      togglePayloadBtn.textContent = 'Show Request Payload';
    }
  });

  // Fetch Settings
  async function loadSettings() {
    try {
      const res = await fetch('send.php?action=get_settings');
      const data = await res.json();
      if (data.success && data.settings) {
        currentSettings = { ...currentSettings, ...data.settings };
        updatePreview();
      }
    } catch (err) {
      console.warn('Could not load settings from backend, using defaults', err);
    }
  }

  // Populate Settings Modal
  function populateSettingsModal() {
    settingUri.value = currentSettings.uri || '';
    settingUsername.value = currentSettings.username || '';
    settingApiKey.value = currentSettings.apikey || '';
    settingSender.value = currentSettings.sender_id || '';
    settingRoute.value = currentSettings.route || '';
    settingTemplateId.value = currentSettings.template_id || '';
    settingEntityId.value = currentSettings.entity_id || '';
    settingTemplatePattern.value = currentSettings.template_pattern || '';
  }

  openSettingsBtn.addEventListener('click', () => {
    populateSettingsModal();
    settingsModal.classList.add('active');
  });

  const closeSettings = () => settingsModal.classList.remove('active');
  closeSettingsBtn.addEventListener('click', closeSettings);
  cancelSettingsBtn.addEventListener('click', closeSettings);

  saveSettingsBtn.addEventListener('click', async () => {
    const updated = {
      uri: settingUri.value.trim(),
      username: settingUsername.value.trim(),
      apikey: settingApiKey.value.trim(),
      sender_id: settingSender.value.trim(),
      route: settingRoute.value.trim(),
      template_id: settingTemplateId.value.trim(),
      entity_id: settingEntityId.value.trim(),
      template_pattern: settingTemplatePattern.value
    };

    saveSettingsBtn.disabled = true;
    saveSettingsBtn.textContent = 'Saving...';

    try {
      const form = new FormData();
      form.append('action', 'save_settings');
      Object.keys(updated).forEach(k => {
        form.append(`settings[${k}]`, updated[k]);
      });

      const res = await fetch('send.php', { method: 'POST', body: form });
      const data = await res.json();
      if (data.success) {
        currentSettings = { ...currentSettings, ...data.settings };
        updatePreview();
        closeSettings();
      } else {
        alert('Failed to save settings: ' + (data.message || 'Unknown error'));
      }
    } catch (err) {
      alert('Error connecting to server to save settings.');
    } finally {
      saveSettingsBtn.disabled = false;
      saveSettingsBtn.textContent = 'Save Settings';
    }
  });

  // Handle Send SMS Form Submission
  smsForm.addEventListener('submit', async (e) => {
    e.preventDefault();

    const phone = phoneInput.value.trim();
    if (!phone) {
      alert('Please enter a valid recipient mobile number');
      phoneInput.focus();
      return;
    }

    // Set UI Loading State
    sendBtn.disabled = true;
    btnSpinner.style.display = 'inline-block';
    btnText.textContent = 'Dispatching to SMS Gateway...';

    liveStatusBadge.className = 'badge';
    liveStatusBadge.style.background = 'rgba(59, 130, 246, 0.2)';
    liveStatusBadge.style.color = '#93c5fd';
    liveStatusBadge.textContent = 'Transmitting...';

    const formData = new FormData();
    formData.append('action', 'send_sms');
    formData.append('phone', phone);
    formData.append('var1', var1Input.value.trim());
    formData.append('var2', var2Input.value.trim());
    formData.append('var3', var3Input.value.trim());

    try {
      const response = await fetch('send.php', {
        method: 'POST',
        body: formData
      });

      const result = await response.json();
      displayInspectorResult(result);
      await loadHistory();
    } catch (error) {
      console.error('Transmission error:', error);
      displayInspectorError(error.message);
    } finally {
      sendBtn.disabled = false;
      btnSpinner.style.display = 'none';
      btnText.textContent = '🚀 Send & Verify SMS via Gateway';
    }
  });

  function displayInspectorResult(data) {
    const { http_code, duration_ms, status_summary, raw_response, parsed_response, entry, curl_error } = data;

    // HTTP Code
    metricHttpCode.textContent = http_code ? `HTTP ${http_code}` : 'No HTTP Resp';
    metricHttpCode.className = 'metric-value ' + (http_code >= 200 && http_code < 300 ? 'status-success' : 'status-error');

    // Status Summary
    metricStatusDesc.textContent = status_summary || (data.is_dispatched ? 'Accepted' : 'Failed');
    metricStatusDesc.className = 'metric-value ' + (data.is_dispatched ? 'status-success' : 'status-error');

    // Latency
    metricLatency.textContent = duration_ms ? `${duration_ms} ms` : '—';

    // Message ID
    let msgId = 'None';
    if (data.message_id) {
      msgId = data.message_id;
    } else if (parsed_response) {
      const rawId = parsed_response['message-id'] || parsed_response.msgid || parsed_response.message_id || parsed_response.id || parsed_response.tracking_id;
      msgId = Array.isArray(rawId) ? rawId.join(', ') : (rawId || 'In Response');
    } else if (raw_response && raw_response.length < 50) {
      msgId = raw_response;
    }
    metricMsgId.textContent = msgId;

    // Live Badge
    if (data.is_dispatched) {
      liveStatusBadge.style.background = 'rgba(16, 185, 129, 0.2)';
      liveStatusBadge.style.color = '#34d399';
      liveStatusBadge.innerHTML = '<span class="badge-dot"></span> Dispatched / Queued';
    } else {
      liveStatusBadge.style.background = 'rgba(244, 63, 94, 0.2)';
      liveStatusBadge.style.color = '#fb7185';
      liveStatusBadge.innerHTML = '<span class="badge-dot" style="background:#f43f5e; box-shadow:0 0 8px #f43f5e;"></span> Dispatch Failed';
    }

    // Response Box Format
    let formattedResponse = '';
    if (parsed_response) {
      formattedResponse = '// Parsed JSON Response:\n' + JSON.stringify(parsed_response, null, 2);
    } else if (raw_response) {
      formattedResponse = '// Raw Gateway Output:\n' + raw_response;
    } else if (curl_error) {
      formattedResponse = '// cURL Transport Error:\n' + curl_error;
    } else {
      formattedResponse = '// Empty response from gateway.';
    }
    responseBox.textContent = formattedResponse;

    // Request Payload Box
    if (entry && entry.request_payload) {
      requestPayloadBox.textContent = '// Outgoing Request Payload Dispatched by cURL:\n' + JSON.stringify({
        ...entry.request_payload,
        message: entry.message
      }, null, 2);
    }

    // Scroll to inspector
    document.getElementById('inspectorCard').scrollIntoView({ behavior: 'smooth', block: 'nearest' });
  }

  function displayInspectorError(msg) {
    metricHttpCode.textContent = 'ERR';
    metricHttpCode.className = 'metric-value status-error';
    metricStatusDesc.textContent = 'Network / Script Error';
    metricStatusDesc.className = 'metric-value status-error';
    metricLatency.textContent = '—';
    metricMsgId.textContent = '—';

    liveStatusBadge.style.background = 'rgba(244, 63, 94, 0.2)';
    liveStatusBadge.style.color = '#fb7185';
    liveStatusBadge.textContent = 'Request Failed';

    responseBox.textContent = '// Local Execution Error:\n' + msg;
  }

  // Transmission History
  async function loadHistory() {
    try {
      const res = await fetch('send.php?action=get_history');
      const data = await res.json();
      renderHistoryTable(data.history || []);
    } catch (err) {
      console.warn('Could not load history:', err);
    }
  }

  function renderHistoryTable(items) {
    if (!items || items.length === 0) {
      historyTableBody.innerHTML = `
        <tr>
          <td colspan="7" style="text-align: center; color: var(--text-muted); padding: 30px;">
            No SMS transmission attempts logged yet.
          </td>
        </tr>
      `;
      return;
    }

    historyTableBody.innerHTML = items.map((item, index) => {
      const isSuccess = item.is_success;
      const statusClass = isSuccess ? 'status-tag-success' : 'status-tag-error';
      const statusIcon = isSuccess ? '✓' : '✗';
      const varsSummary = `${item.variables?.var1 || ''} | ${item.variables?.var2 || ''} | ${item.variables?.var3 || ''}`;

      return `
        <tr>
          <td style="white-space: nowrap; font-size: 12px; color: var(--text-secondary);">${escapeHtml(item.timestamp)}</td>
          <td><strong style="font-family: monospace;">${escapeHtml(item.phone)}</strong></td>
          <td style="max-width: 200px; overflow: hidden; text-overflow: ellipsis; white-space: nowrap;" title="${escapeHtml(item.message)}">
            <span style="font-size: 12px; color: #93c5fd;">${escapeHtml(varsSummary)}</span>
          </td>
          <td><span style="font-family: monospace; font-size: 12px;">${item.http_code || '—'}</span></td>
          <td>
            <span class="status-tag ${statusClass}">
              <span>${statusIcon}</span> ${escapeHtml(item.status_summary || (isSuccess ? 'Success' : 'Failed'))}
            </span>
          </td>
          <td style="font-size: 12px; color: var(--text-muted);">${item.duration_ms ? item.duration_ms + 'ms' : '—'}</td>
          <td>
            <button class="btn btn-secondary btn-sm" onclick="inspectPastItem(${index})">
              Inspect
            </button>
          </td>
        </tr>
      `;
    }).join('');

    window.pastHistoryCache = items;
  }

  window.inspectPastItem = (index) => {
    if (window.pastHistoryCache && window.pastHistoryCache[index]) {
      const item = window.pastHistoryCache[index];
      displayInspectorResult({
        http_code: item.http_code,
        duration_ms: item.duration_ms,
        status_summary: item.status_summary,
        raw_response: item.raw_response,
        parsed_response: item.parsed_response,
        is_dispatched: item.is_success,
        curl_error: item.curl_error,
        entry: item
      });

      // Also set the inputs
      phoneInput.value = item.phone || '';
      if (item.variables) {
        var1Input.value = item.variables.var1 || '';
        var2Input.value = item.variables.var2 || '';
        var3Input.value = item.variables.var3 || '';
        updatePreview();
      }
    }
  };

  refreshHistoryBtn.addEventListener('click', loadHistory);

  clearHistoryBtn.addEventListener('click', async () => {
    if (!confirm('Are you sure you want to clear all transmission history logs?')) return;
    try {
      await fetch('send.php?action=clear_history');
      await loadHistory();
    } catch (err) {
      alert('Failed to clear history');
    }
  });

  // Initialize
  loadSettings();
  loadHistory();
  updatePreview();
});
