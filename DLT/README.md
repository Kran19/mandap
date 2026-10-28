# DLT SMS Dispatcher & Live Verifier Portal

A high-performance web portal and testing suite for sending TRAI DLT-compliant SMS messages and verifying real-time delivery status, cURL payloads, and gateway responses.

---

## 📋 Pre-Configured Parameters

- **Principal Entity ID (PE_ID)**: `1401805350000060162`
- **Sender ID (Header)**: `TXXTOO`
- **DLT Template ID**: `1607100000000313742`
- **HTTP API Key**: `62CEF-9A446`
- **DLT Approved Template Pattern**:
  ```text
  Dear {#var#} Your OTP for verification is {#var#}. Please enter this code to complete the process.
  Regards {#var#}
  TEXT2
  ```
- **3 Dynamic Variables**:
  1. `{#var#}` 1: Recipient Name (e.g. *Rahul Sharma*)
  2. `{#var#}` 2: OTP Code (e.g. *482910*)
  3. `{#var#}` 3: Sign-off / Regards (e.g. *Team TXXTOO*)

---

## 🚀 Quick Start Guide

### 1. Start the Local Server
Open PowerShell in this directory and run:
```powershell
php -S 127.0.0.1:8090
```

### 2. Open the Portal
Visit:
```
http://127.0.0.1:8090
```

### 3. Configure Your SMS Panel
1. Click **⚙️ Gateway Settings** in the top right.
2. Enter your actual **SMS Gateway HTTP Endpoint** (replace `http://domain/...` with your vendor's actual domain).
3. Enter your **SMS Panel Username**.
4. Click **Save Settings**.

### 4. Send & Inspect
1. Enter recipient mobile number (e.g. `9876543210` or multiple comma-separated numbers).
2. Enter the 3 dynamic values or click **🎲 Generate 6-Digit OTP**.
3. Watch the live **Recipient Handset Preview** update in real-time.
4. Click **🚀 Send & Verify SMS via Gateway**.
5. Check the **Live Delivery & Transmission Inspector** for:
   - HTTP response code
   - Delivery / Queued status badge
   - Gateway Round-trip latency (ms)
   - Message ID / Tracking reference
   - Raw JSON response & cURL payload
