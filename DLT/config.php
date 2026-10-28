<?php
/**
 * DLT SMS Configuration
 * 
 * Pre-configured with the verified allsmssolution.in gateway parameters.
 */

$configFile = __DIR__ . '/settings.json';
$defaultSettings = [
    'uri'         => 'https://allsmssolution.in/sms-panel/api/http/index.php',
    'username'    => 'EMPEROR',
    'apikey'      => '62CEF-9A446',
    'sender_id'   => 'TXXTOO',
    'template_id' => '1607100000000313742',
    'entity_id'   => '1401805350000060162',
    'route'       => 'TRANS',
    'apirequest'  => 'Text',
    'format'      => 'JSON',
    'template_pattern' => "Dear {#var#} Your OTP for verification is {#var#}. Please enter this code to complete the process.\nRegards {#var#}\nTEXT2"
];

function getSettings() {
    global $configFile, $defaultSettings;
    if (file_exists($configFile)) {
        $saved = json_decode(file_get_contents($configFile), true);
        if (is_array($saved)) {
            return array_merge($defaultSettings, $saved);
        }
    }
    return $defaultSettings;
}

function saveSettings($newSettings) {
    global $configFile, $defaultSettings;
    $current = getSettings();
    $merged = array_merge($current, array_intersect_key($newSettings, $defaultSettings));
    file_put_contents($configFile, json_encode($merged, JSON_PRETTY_PRINT));
    return $merged;
}
