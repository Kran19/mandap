<?php
/**
 * DLT SMS Dispatcher & API Controller
 */

header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

if (($_SERVER['REQUEST_METHOD'] ?? '') === 'OPTIONS') {
    http_response_code(200);
    exit;
}

require_once __DIR__ . '/config.php';

$historyFile = __DIR__ . '/history.json';

function getHistory() {
    global $historyFile;
    if (file_exists($historyFile)) {
        $content = file_get_contents($historyFile);
        $data = json_decode($content, true);
        return is_array($data) ? $data : [];
    }
    return [];
}

function appendHistory($entry) {
    global $historyFile;
    $history = getHistory();
    array_unshift($history, $entry); // Add to beginning
    // Keep last 100 entries
    if (count($history) > 100) {
        $history = array_slice($history, 0, 100);
    }
    file_put_contents($historyFile, json_encode($history, JSON_PRETTY_PRINT));
}

// Route actions
$action = $_GET['action'] ?? ($_POST['action'] ?? '');
if (empty($action)) {
    // Check php://input for JSON payload
    $rawInput = file_get_contents('php://input');
    $jsonData = json_decode($rawInput, true);
    if (is_array($jsonData) && !empty($jsonData['action'])) {
        $action = $jsonData['action'];
        $_POST = array_merge($_POST, $jsonData);
    }
}

switch ($action) {
    case 'get_settings':
        echo json_encode([
            'success' => true,
            'settings' => getSettings()
        ]);
        exit;

    case 'save_settings':
        $newSettings = $_POST['settings'] ?? [];
        if (!is_array($newSettings)) {
            echo json_encode(['success' => false, 'message' => 'Invalid settings payload']);
            exit;
        }
        $saved = saveSettings($newSettings);
        echo json_encode(['success' => true, 'settings' => $saved, 'message' => 'Settings saved successfully']);
        exit;

    case 'get_history':
        echo json_encode([
            'success' => true,
            'history' => getHistory()
        ]);
        exit;

    case 'clear_history':
        global $historyFile;
        file_put_contents($historyFile, json_encode([]));
        echo json_encode(['success' => true, 'message' => 'History cleared successfully']);
        exit;

    case 'send_sms':
        handleSendSms();
        exit;

    default:
        echo json_encode([
            'success' => false,
            'message' => 'Invalid action specified. Supported actions: get_settings, save_settings, get_history, clear_history, send_sms'
        ]);
        exit;
}

function handleSendSms() {
    $settings = getSettings();

    // Input parameters
    $phone = trim($_POST['phone'] ?? '');
    $var1  = trim($_POST['var1'] ?? ''); // Name
    $var2  = trim($_POST['var2'] ?? ''); // OTP
    $var3  = trim($_POST['var3'] ?? ''); // Regards/Company

    // Allow overriding gateway config for one-off testing
    $uri        = trim($_POST['uri'] ?? $settings['uri']);
    $username   = trim($_POST['username'] ?? $settings['username']);
    $apikey     = trim($_POST['apikey'] ?? $settings['apikey']);
    $sender_id  = trim($_POST['sender_id'] ?? $settings['sender_id']);
    $route      = trim($_POST['route'] ?? $settings['route']);
    $template_id= trim($_POST['template_id'] ?? $settings['template_id']);
    $entity_id  = trim($_POST['entity_id'] ?? $settings['entity_id']);
    $customMsg  = trim($_POST['message'] ?? '');

    // Validation
    if (empty($phone)) {
        echo json_encode(['success' => false, 'message' => 'Recipient mobile number is required.']);
        exit;
    }

    // Clean phone numbers (allow comma separated)
    $cleanNumbers = [];
    foreach (explode(',', $phone) as $num) {
        $cleaned = preg_replace('/[^0-9]/', '', trim($num));
        // If 10 digits Indian number, keep as is or prefix if gateway needs, usually standard 10 or 12 digits
        if (!empty($cleaned)) {
            $cleanNumbers[] = $cleaned;
        }
    }
    $phoneFormatted = implode(',', $cleanNumbers);

    if (empty($phoneFormatted)) {
        echo json_encode(['success' => false, 'message' => 'Valid mobile number(s) required.']);
        exit;
    }

    // Build the message if not custom provided
    if (!empty($customMsg)) {
        $finalMessage = $customMsg;
    } else {
        // Construct message using the 3 dynamic variables
        $template = $settings['template_pattern'] ?? "Dear {#var#} Your OTP for verification is {#var#}. Please enter this code to complete the process.\nRegards {#var#}\nTEXT2";
        
        // Sequentially replace the 3 {#var#} placeholders
        $vars = [$var1, $var2, $var3];
        $count = 0;
        $finalMessage = preg_replace_callback('/\{#var#\}/', function($match) use (&$count, $vars) {
            $val = $vars[$count] ?? '';
            $count++;
            return $val;
        }, $template);
    }

    // Prepare API Post Data matching the user's PHP specification
    $postData = [
        'username'    => $username,
        'apikey'      => $apikey,
        'apirequest'  => $settings['apirequest'] ?? 'Text',
        'sender'      => $sender_id,
        'route'       => $route,
        'format'      => 'JSON',
        'message'     => $finalMessage,
        'mobile'      => $phoneFormatted,
        'TemplateID'  => $template_id,
    ];

    // Some DLT telecom gateways in India also require EntityID or PE_ID parameter
    if (!empty($entity_id)) {
        $postData['EntityID'] = $entity_id;
        $postData['PE_ID'] = $entity_id;
    }

    // Dispatch cURL Request
    $startTime = microtime(true);
    $ch = curl_init($uri);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_POST, 1);
    curl_setopt($ch, CURLOPT_POSTFIELDS, $postData);
    curl_setopt($ch, CURLOPT_FAILONERROR, false); // Allow reading HTTP 4xx/5xx response bodies
    curl_setopt($ch, CURLOPT_TIMEOUT, 15);
    curl_setopt($ch, CURLOPT_CONNECTTIMEOUT, 10);
    curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, false); // Help in local/testing setups
    curl_setopt($ch, CURLOPT_SSL_VERIFYHOST, 0);

    $rawResponse = curl_exec($ch);
    $curlError = curl_error($ch);
    $curlErrno = curl_errno($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    $execDurationMs = round((microtime(true) - $startTime) * 1000, 2);
    curl_close($ch);

    // Analyze Response
    $parsedResponse = null;
    $isDeliveredOrQueued = false;
    $statusDescription = 'Unknown';
    $messageId = null;

    if (!empty($rawResponse)) {
        $parsedResponse = json_decode($rawResponse, true);
        if (json_last_error() === JSON_ERROR_NONE && is_array($parsedResponse)) {
            // Check message-id (support array or string)
            if (isset($parsedResponse['message-id'])) {
                $messageId = is_array($parsedResponse['message-id']) ? implode(', ', $parsedResponse['message-id']) : $parsedResponse['message-id'];
            } elseif (isset($parsedResponse['msgid'])) {
                $messageId = $parsedResponse['msgid'];
            }

            // Check common response patterns from Indian SMS gateway panels
            $statusField = strtolower($parsedResponse['status'] ?? $parsedResponse['status_code'] ?? $parsedResponse['response'] ?? '');
            if (in_array($statusField, ['success', 'queued', 'submitted', '1', '200', 'ok', 'sent'])) {
                $isDeliveredOrQueued = true;
                $statusDescription = $parsedResponse['message'] ?? 'Queued / Sent Successfully';
            } elseif (in_array($statusField, ['error', 'failed', 'fail', '0'])) {
                $statusDescription = $parsedResponse['message'] ?? $parsedResponse['desc'] ?? $parsedResponse['error'] ?? 'API Returned Failure';
            } else {
                $statusDescription = 'Response received';
            }
        } else {
            // Raw text response (e.g. "MSGID:12345" or "ERR:Invalid Login")
            if (stripos($rawResponse, 'success') !== false || stripos($rawResponse, 'msgid') !== false || stripos($rawResponse, 'submitted') !== false) {
                $isDeliveredOrQueued = true;
                $statusDescription = 'Success / Message ID Found';
            } elseif (stripos($rawResponse, 'err') !== false || stripos($rawResponse, 'invalid') !== false || stripos($rawResponse, 'fail') !== false) {
                $statusDescription = 'Gateway Error Detected: ' . substr(strip_tags($rawResponse), 0, 100);
            } else {
                $statusDescription = 'HTTP ' . $httpCode . ' Response';
            }
        }
    } else if ($curlErrno !== 0) {
        $statusDescription = 'cURL Connection Error: ' . $curlError;
    }

    // Build History Entry
    $entry = [
        'id'               => 'msg_' . time() . '_' . rand(100, 999),
        'timestamp'        => date('Y-m-d H:i:s'),
        'phone'            => $phoneFormatted,
        'variables'        => [
            'var1' => $var1,
            'var2' => $var2,
            'var3' => $var3
        ],
        'message'          => $finalMessage,
        'message_id'      => $messageId,
        'http_code'        => $httpCode,
        'duration_ms'      => $execDurationMs,
        'curl_error'       => $curlError,
        'is_success'       => $isDeliveredOrQueued,
        'status_summary'   => $statusDescription,
        'raw_response'     => $rawResponse,
        'parsed_response'  => $parsedResponse,
        'request_payload'  => [
            'uri'         => $uri,
            'sender'      => $sender_id,
            'route'       => $route,
            'TemplateID'  => $template_id,
            'EntityID'    => $entity_id,
            'username'    => $username,
            'apikey_mask' => substr($apikey, 0, 4) . '****' . substr($apikey, -3),
            'mobile'      => $phoneFormatted
        ]
    ];

    appendHistory($entry);

    echo json_encode([
        'success'         => ($curlErrno === 0 && ($httpCode >= 200 && $httpCode < 400)),
        'is_dispatched'   => $isDeliveredOrQueued,
        'message_id'      => $messageId,
        'http_code'       => $httpCode,
        'duration_ms'     => $execDurationMs,
        'status_summary'  => $statusDescription,
        'raw_response'    => $rawResponse,
        'parsed_response' => $parsedResponse,
        'curl_error'      => $curlError,
        'final_message'   => $finalMessage,
        'entry'           => $entry
    ]);
}
