#include <WiFi.h>
#include <WebServer.h>

const char* WIFI_SSID = "Jose's iphone";
const char* WIFI_PASS = "bellakita";

WebServer server(80);

#define STM32_RX  16
#define STM32_TX  17
#define STM32_BAUD 9600

const char HTML_PAGE[] PROGMEM = R"rawliteral(
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Control de Acceso</title>
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link href="https://fonts.googleapis.com/css2?family=Space+Mono:wght@400;700&family=DM+Sans:wght@300;400/Users/jose/Downloads/Video_demostracion.MOV;500&display=swap" rel="stylesheet">
  <style>
    :root {
      --bg:        #0a0a0a;
      --surface:   #111111;
      --border:    #222222;
      --accent:    #c8f135;
      --open:      #c8f135;
      --close:     #ff3b3b;
      --text:      #f0f0f0;
      --muted:     #555555;
      --mono:      'Space Mono', monospace;
      --sans:      'DM Sans', sans-serif;
    }

    *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }

    body {
      font-family: var(--sans);
      background: var(--bg);
      min-height: 100vh;
      display: flex;
      align-items: center;
      justify-content: center;
      overflow: hidden;
    }

    /* Grid background */
    body::before {
      content: '';
      position: fixed;
      inset: 0;
      background-image:
        linear-gradient(rgba(200,241,53,0.03) 1px, transparent 1px),
        linear-gradient(90deg, rgba(200,241,53,0.03) 1px, transparent 1px);
      background-size: 40px 40px;
      pointer-events: none;
    }

    .panel {
      width: 360px;
      background: var(--surface);
      border: 1px solid var(--border);
      padding: 0;
      animation: fadeUp 0.5s ease both;
      position: relative;
      overflow: hidden;
    }

    .panel::before {
      content: '';
      position: absolute;
      top: 0; left: 0; right: 0;
      height: 2px;
      background: var(--accent);
    }

    @keyframes fadeUp {
      from { opacity: 0; transform: translateY(16px); }
      to   { opacity: 1; transform: translateY(0); }
    }

    /* Header */
    .panel-header {
      padding: 28px 28px 24px;
      border-bottom: 1px solid var(--border);
    }

    .panel-label {
      font-family: var(--mono);
      font-size: 10px;
      letter-spacing: 0.2em;
      color: var(--accent);
      text-transform: uppercase;
      margin-bottom: 10px;
    }

    .panel-title {
      font-family: var(--mono);
      font-size: 22px;
      font-weight: 700;
      color: var(--text);
      letter-spacing: -0.02em;
      line-height: 1.1;
    }

    .panel-subtitle {
      font-size: 13px;
      font-weight: 300;
      color: var(--muted);
      margin-top: 6px;
      letter-spacing: 0.01em;
    }

    /* Status indicator */
    .status-bar {
      padding: 14px 28px;
      border-bottom: 1px solid var(--border);
      display: flex;
      align-items: center;
      gap: 10px;
    }

    .dot {
      width: 7px;
      height: 7px;
      border-radius: 50%;
      background: var(--accent);
      flex-shrink: 0;
      animation: pulse 2s ease infinite;
    }

    @keyframes pulse {
      0%, 100% { opacity: 1; }
      50%       { opacity: 0.3; }
    }

    .status-text {
      font-family: var(--mono);
      font-size: 11px;
      color: var(--muted);
      letter-spacing: 0.08em;
      text-transform: uppercase;
    }

    /* Actions */
    .actions {
      padding: 28px;
      display: flex;
      flex-direction: column;
      gap: 12px;
    }

    .btn {
      display: flex;
      align-items: center;
      justify-content: space-between;
      width: 100%;
      padding: 18px 22px;
      border: 1px solid var(--border);
      background: transparent;
      font-family: var(--mono);
      font-size: 13px;
      font-weight: 700;
      letter-spacing: 0.12em;
      text-transform: uppercase;
      cursor: pointer;
      position: relative;
      overflow: hidden;
      transition: border-color 0.2s, color 0.2s;
    }

    .btn::after {
      content: '';
      position: absolute;
      inset: 0;
      transform: scaleX(0);
      transform-origin: left;
      transition: transform 0.25s ease;
      z-index: 0;
    }

    .btn:hover::after { transform: scaleX(1); }

    .btn span { position: relative; z-index: 1; }

    .btn-arrow {
      font-size: 16px;
      line-height: 1;
      position: relative;
      z-index: 1;
      transition: transform 0.2s;
    }

    .btn:hover .btn-arrow { transform: translateX(4px); }

    /* Open */
    .btn-open { color: var(--open); }
    .btn-open::after { background: rgba(200,241,53,0.08); }
    .btn-open:hover { border-color: var(--open); }

    /* Close */
    .btn-close { color: var(--close); }
    .btn-close::after { background: rgba(255,59,59,0.08); }
    .btn-close:hover { border-color: var(--close); }

    /* Response area */
    .response-area {
      padding: 0 28px 28px;
    }

    .response-box {
      border: 1px solid var(--border);
      padding: 14px 16px;
      display: flex;
      align-items: center;
      gap: 10px;
      min-height: 48px;
      transition: border-color 0.3s;
    }

    .response-box.active-open  { border-color: rgba(200,241,53,0.4); }
    .response-box.active-close { border-color: rgba(255,59,59,0.4); }

    .response-indicator {
      width: 4px;
      height: 20px;
      background: var(--border);
      flex-shrink: 0;
      transition: background 0.3s;
    }

    .response-box.active-open  .response-indicator { background: var(--open); }
    .response-box.active-close .response-indicator { background: var(--close); }

    #status {
      font-family: var(--mono);
      font-size: 11px;
      letter-spacing: 0.06em;
      color: var(--muted);
      text-transform: uppercase;
      transition: color 0.3s;
    }

    .response-box.active-open  #status { color: var(--open); }
    .response-box.active-close #status { color: var(--close); }

    /* Footer */
    .panel-footer {
      padding: 14px 28px;
      border-top: 1px solid var(--border);
      display: flex;
      justify-content: space-between;
      align-items: center;
    }

    .footer-label {
      font-family: var(--mono);
      font-size: 10px;
      color: var(--muted);
      letter-spacing: 0.1em;
    }

    .footer-id {
      font-family: var(--mono);
      font-size: 10px;
      color: var(--border);
      letter-spacing: 0.05em;
    }
  </style>
</head>
<body>
  <div class="panel">
    <div class="panel-header">
      <div class="panel-label">Sistema de Acceso</div>
      <div class="panel-title">Control de<br>Cerradura</div>
      <div class="panel-subtitle">Control remoto via Wi-Fi</div>
    </div>

    <div class="status-bar">
      <div class="dot"></div>
      <div class="status-text">Dispositivo en linea</div>
    </div>

    <div class="actions">
      <button class="btn btn-open" onclick="sendCmd('/abrir', 'open')">
        <span>Abrir</span>
        <span class="btn-arrow">&#x2192;</span>
      </button>
      <button class="btn btn-close" onclick="sendCmd('/cerrar', 'close')">
        <span>Cerrar</span>
        <span class="btn-arrow">&#x2192;</span>
      </button>
    </div>

    <div class="response-area">
      <div class="response-box" id="responseBox">
        <div class="response-indicator"></div>
        <div id="status">En espera</div>
      </div>
    </div>

    <div class="panel-footer">
      <span class="footer-label">ESP32 &mdash; UART Bridge</span>
      <span class="footer-id">REV 1.0</span>
    </div>
  </div>

  <script>
    function sendCmd(url, type) {
      const box = document.getElementById('responseBox');
      const txt = document.getElementById('status');
      box.className = 'response-box';
      txt.textContent = 'Enviando comando...';

      fetch(url)
        .then(r => r.text())
        .then(t => {
          box.className = 'response-box active-' + type;
          txt.textContent = t;
        })
        .catch(() => {
          box.className = 'response-box';
          txt.textContent = 'Error de conexion';
        });
    }
  </script>
</body>
</html>
)rawliteral";

void handleRoot()   { server.send(200, "text/html", HTML_PAGE); }

void handleAbrir() {
  Serial2.print("OPEN\n");
  server.send(200, "text/plain", "Acceso concedido — cerradura abierta");
}

void handleCerrar() {
  Serial2.print("CLOSE\n");
  server.send(200, "text/plain", "Acceso denegado — cerradura cerrada");
}

void handleNotFound() { server.send(404, "text/plain", "Recurso no encontrado"); }

void setup() {
  Serial.begin(115200);
  Serial2.begin(STM32_BAUD, SERIAL_8N1, STM32_RX, STM32_TX);

  WiFi.begin(WIFI_SSID, WIFI_PASS);
  Serial.print("Conectando");
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  Serial.println("\nConectado! IP: ");
  Serial.println(WiFi.localIP());

  server.on("/",       handleRoot);
  server.on("/abrir",  handleAbrir);
  server.on("/cerrar", handleCerrar);
  server.onNotFound(handleNotFound);
  server.begin();
}

void loop() {
  server.handleClient();
}