#include "WiFi.h"
#include "ESPAsyncWebServer.h"
#include "DHT.h"
#include <Wire.h>
#include <Adafruit_GFX.h>
#include <Adafruit_SSD1306.h>

const char* ssid = "Nha Tro 156_T1";
const char* password = "123456789";

#define DHTPIN 4       // Chân dữ liệu cảm biến DHT
#define DHTTYPE DHT22  // Sử dụng cảm biến DHT22
#define SCREEN_WIDTH 128
#define SCREEN_HEIGHT 64
#define SOIL_MOISTURE_PIN 36 // Chân cảm biến độ ẩm đất

DHT dht(DHTPIN, DHTTYPE);
AsyncWebServer server(80);
Adafruit_SSD1306 display(SCREEN_WIDTH, SCREEN_HEIGHT, &Wire, -1);

void updateDisplay(float temperature, float humidity, int soilMoisture) {
  display.clearDisplay();
  display.setTextSize(1);
  display.setTextColor(WHITE);
  display.setCursor(0, 10);
  display.print("Temp: ");
  display.print(temperature);
  display.println(" C");
  display.print("Humidity: ");
  display.print(humidity);
  display.println(" %");
  display.print("Soil Moisture: ");
  display.print(soilMoisture);
  display.println();
  display.display();
}

String readDHTTemperature() {
  float t = dht.readTemperature();
  if (isnan(t)) {
    Serial.println("Failed to read from DHT sensor!");
    return "--";
  }
  Serial.println(t);
  return String(t);
}

String readDHTHumidity() {
  float h = dht.readHumidity();
  if (isnan(h)) {
    Serial.println("Failed to read from DHT sensor!");
    return "--";
  }
  Serial.println(h);
  return String(h);
}

String readSoilMoisture() {
  int value = analogRead(SOIL_MOISTURE_PIN);
  Serial.print("Soil Moisture: ");
  Serial.println(value);
  return String(value);
}

const char index_html[] PROGMEM = R"rawliteral(
<!DOCTYPE HTML><html>
<head>
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <style>
    html { font-family: Arial; text-align: center; }
    h2 { font-size: 2.5rem; }
    p { font-size: 2.0rem; }
  </style>
</head>
<body>
  <h2>ESP32 DHT Server</h2>
  <p>Temperature: <span id="temperature">%TEMPERATURE%</span> &deg;C</p>
  <p>Humidity: <span id="humidity">%HUMIDITY%</span> &percnt;</p>
  <p>Soil Moisture: <span id="soilmoisture">%SOILMOISTURE%</span></p>
</body>
<script>
setInterval(function() {
  fetch("/temperature").then(response => response.text()).then(data => {
    document.getElementById("temperature").innerText = data;
  });
  fetch("/humidity").then(response => response.text()).then(data => {
    document.getElementById("humidity").innerText = data;
  });
  fetch("/soilmoisture").then(response => response.text()).then(data => {
    document.getElementById("soilmoisture").innerText = data;
  });
}, 10000);
</script>
</html>)rawliteral";

String processor(const String& var) {
  if (var == "TEMPERATURE") return readDHTTemperature();
  if (var == "HUMIDITY") return readDHTHumidity();
  if (var == "SOILMOISTURE") return readSoilMoisture();
  return String();
}

void setup() {
  Serial.begin(115200);
  dht.begin();
  WiFi.begin(ssid, password);
  
  // Cấu hình ADC để đọc giá trị chính xác
  analogSetAttenuation(ADC_11db);

  if (!display.begin(SSD1306_SWITCHCAPVCC, 0x3C)) {
    Serial.println(F("SSD1306 allocation failed"));
    for (;;);
  }
  display.clearDisplay();
  display.display();

  while (WiFi.status() != WL_CONNECTED) {
    delay(1000);
    Serial.println("Connecting to WiFi...");
  }
  Serial.println(WiFi.localIP());

  server.on("/", HTTP_GET, [](AsyncWebServerRequest *request) {
    request->send_P(200, "text/html", index_html, processor);
  });
  server.on("/temperature", HTTP_GET, [](AsyncWebServerRequest *request) {
    request->send_P(200, "text/plain", readDHTTemperature().c_str());
  });
  server.on("/humidity", HTTP_GET, [](AsyncWebServerRequest *request) {
    request->send_P(200, "text/plain", readDHTHumidity().c_str());
  });
  server.on("/soilmoisture", HTTP_GET, [](AsyncWebServerRequest *request) {
    request->send_P(200, "text/plain", readSoilMoisture().c_str());
  });

  server.begin();
}

void loop() {
  float temperature = dht.readTemperature();
  float humidity = dht.readHumidity();
  int soilMoisture = analogRead(SOIL_MOISTURE_PIN);
  
  Serial.print("Temperature: ");
  Serial.print(temperature);
  Serial.print(" °C, Humidity: ");
  Serial.print(humidity);
  Serial.print(" %, Soil Moisture: ");
  Serial.println(soilMoisture);

  if (!isnan(temperature) && !isnan(humidity)) {
    updateDisplay(temperature, humidity, soilMoisture);
  }
  delay(2000);
}

