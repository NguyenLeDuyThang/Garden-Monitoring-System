char ssid[]  = "BietDoiSieuQuay";
char pass[] = "@01032023";

#include <Wire.h>
#include <LiquidCrystal_I2C.h>
LiquidCrystal_I2C lcd(0x27, 20, 4);//0x27 0x3F
#define I2C_SDA 21
#define I2C_SCL 22

unsigned long last = millis();

#include "ccs811.h"
CCS811 ccs811(-1);

long Value_CCS811 = 0;
float Value_TVOC = 0;
#include <GP2Y1010AU0F.h>
int measurePin = 34;
int ledPin     = 12;
GP2Y1010AU0F dustSensor(ledPin, measurePin); // Construct dust sensor global object
float dustDensity = 0;
long Value_GP2Y101AU0F = 0;
char* Value_AQI;
#define PIN_MQ135 35
long Value_MQ135 = 0;
#define Data_MQ135 analogRead(PIN_MQ135)

#define PIN_MQ2 32
long Value_MQ2 = 0;
#define Data_MQ2 analogRead(PIN_MQ2)

#define PIN_MQ7 33
long Value_MQ7 = 0;
#define Data_MQ7 analogRead(PIN_MQ7)


#define LED1  2
#define LED2  5
#define LED3  17
#define LED4  16
#define LED5  4

#define PIN_QUAT1  19
#define PIN_QUAT2  18
const int freq_1 = 500;
const int pwmChannel_1 = 1;
const int resolution_1 = 8;
const int freq_2 = 500;
const int pwmChannel_2 = 2;
const int resolution_2 = 8;
int PWM_QUAT = 0;
int PWM_DEN = 0;

int TT_QUAT = 0;
int TT_DEN = 0;

//==========THƯ VIỆN MQTT , WIFI , JSON , EEPROM
#include <WiFi.h>
#include <PubSubClient.h>
#include <EEPROM.h>
#include <Ticker.h>
#include <ArduinoJson.h>
Ticker ticker;

//============MQTT

const char* mqtt_server = "ngoinhaiot.com"; //server
int mqtt_port = 1111; // port
const char* mqtt_user = "vmduc11"; // user mqtt
const char* mqtt_pass = "33561BE6D5D84395"; // pass mqtt
String topicsub = "vmduc11/C"; // topic nhận dữ liệu ESP
String topicpub = "vmduc11/D"; // topic gửi dữ liệu
WiFiClient espClient;
PubSubClient client(espClient);
void DuytriMQTT();
void ConnectMqtt(); // khai báo kết nối server mqtt
void callback(char* topic, byte* payload, unsigned int length); // hàm nhận dữ liệu từ server mqtt
void reconnect(); // check kết nối server
void SendMQTT();
String DataM = "";
String DataMqttJson = "";
void tick1()
{
  digitalWrite(LED1, !digitalRead(LED1));
}


#define LED2_ON digitalWrite(LED2,HIGH)
#define LED2_OFF digitalWrite(LED2,LOW)
int TT_LED2 = 0;
#define LED3_ON digitalWrite(LED3,HIGH)
#define LED3_OFF digitalWrite(LED3,LOW)
int TT_LED3 = 0;
#define LED4_ON digitalWrite(LED4,HIGH)
#define LED4_OFF digitalWrite(LED4,LOW)
int TT_LED4 = 0;
#define LED5_ON digitalWrite(LED5,HIGH)
#define LED5_OFF digitalWrite(LED5,LOW)
int TT_LED5 = 0;


void setup()
{

  Serial.begin(115200);
  Wire.begin(I2C_SDA , I2C_SCL);
  delay(100);
  BeginLed(); LED2_OFF; LED3_OFF; LED4_OFF; LED5_OFF;
  BeginCCS811(); delay(100);
  BeginGP2Y101AU0F(); delay(100);
  BeginMQ(); delay(100);
  ConfigPWM(); delay(100);
  BeginLCDi2C(); delay(100);
  lcd.clear();
  lcd.print("Connecting WiFi");
  ConnectWifi(); delay(100);
  lcd.print(" - OK");delay(1000);
  lcd.clear();lcd.print("Wait Connect MQTT");
  ConnectMqtt();

  Serial.println("Start ESp32");
  last = millis();
}

void loop()
{
  DuytriMQTT();
  if (millis() - last >= 1500)
  {
    Read_CCS811();
    Read_GP2Y101AU0F();
    Read_MQ135_MQ2_MQ7();
    HienThi_LCD();
    SendMQTT();
    Serial.println("==========================");
   last = millis();
 

    
    if (Data_MQ7 >100)
  {
  LED2_ON; 
  TT_LED2 = 1;
    }
   else
   {
  LED2_OFF; 
  TT_LED2 = 0;
    }

    if (Data_MQ2 >4000)
  {
  LED3_ON; 
  TT_LED3 = 1;
    }
   else
   {
  LED3_OFF; 
  TT_LED3 = 0;
    }

   if (Value_CCS811 >2000 )
  {
  LED4_ON; 
  TT_LED4 = 1;
    }
   else
   {
  LED4_OFF; 
  TT_LED4 = 0;
    }
    if (Value_GP2Y101AU0F >56 )
  {
  LED5_ON; 
  TT_LED5 = 1;
    }
   else
   {
  LED5_OFF; 
  TT_LED5 = 0;
    }
    
  }

}

void  BeginLed()
{
  pinMode(LED1, OUTPUT); pinMode(LED2, OUTPUT); pinMode(LED3, OUTPUT); pinMode(LED4, OUTPUT); pinMode(LED5, OUTPUT);
}
void SendMQTT()
{
  if (WiFi.status() == WL_CONNECTED)
  {
    if (client.connected())
    {


      DataJson();

      client.publish(topicpub.c_str(), DataMqttJson.c_str());
      tick1();
      yield();
    }

  }
}
void DataJson()
{

  DataMqttJson = "";
  DataMqttJson = "{\"CO2\":\"" + String(Value_CCS811) + "\"," +
                 "\"TVOC\":\"" + String(Value_TVOC) + "\"," +
                 "\"BUI\":\"" + String(Value_GP2Y101AU0F) + "\"," +
                 "\"MQ135\":\"" + String(Value_MQ135) + "\"," +
                 "\"MQ2\":\"" + String(Value_MQ2) + "\"," +
                 "\"AQI\":\"" + String(Value_AQI) + "\"," +
                 "\"MQ7\":\"" + String(Value_MQ7) + "\"," +
                 "\"DEN\":\"" + String(TT_DEN) + "\"," +
                 "\"QUAT\":\"" + String(TT_QUAT) + "\"," +
                 "\"P_D\":\"" + String(PWM_DEN) + "\"," +
                 "\"P_Q\":\"" + String(PWM_QUAT) + "\"," +
                 "\"L2\":\"" + String(TT_LED2) + "\"," +
                 "\"L3\":\"" + String(TT_LED3) + "\"," +
                 "\"L4\":\"" + String(TT_LED4) + "\"," +
                 "\"L5\":\"" + String(TT_LED5) + "\"}";

  Serial.print("DataMqttJson:");
  Serial.println(DataMqttJson);
}
void DieuKhienLED2()
{
  if (TT_LED2 == 0)
  {
    TT_LED2 = 1;
    LED2_ON;
  }
  else if (TT_LED2 == 1)
  {
    TT_LED2 = 0;
    LED2_OFF;
  }
}

void DieuKhienLED3()
{
  if (TT_LED3 == 0)
  {
    TT_LED3 = 1;
    LED3_ON;
  }
  else if (TT_LED3 == 1)
  {
    TT_LED3 = 0;
    LED3_OFF;
  }
}

void DieuKhienLED4()
{
  if (TT_LED4 == 0)
  {
    TT_LED4 = 1;
    LED4_ON;
  }
  else if (TT_LED4 == 1)
  {
    TT_LED4 = 0;
    LED4_OFF;
  }
}

void DieuKhienLED5()
{
  if (TT_LED5 == 0)
  {
    TT_LED5 = 1;
    LED5_ON;
  }
  else if (TT_LED5 == 1)
  {
    TT_LED5 = 0;
    LED5_OFF;
  }
}

void ConnectWifi()
{
  WiFi.disconnect();
  WiFi.mode(WIFI_STA);
  ticker.attach(0.2, tick1);
  int count = 0;
  WiFi.begin(ssid, pass);
  while (WiFi.status() != WL_CONNECTED)
  {

    delay(500);
    Serial.print(".");
    count++;
    if (count >= 40)
    {
      ESP.restart();
      count = 0;
    }
  }
  //=============================================================
  Serial.println();
  Serial.println("Connect WiFi");
  Serial.print("Address IP esp: ");
  Serial.println(WiFi.localIP());
  ticker.detach();
}
void reconnect()
{

  while (!client.connected())
  {
    String clientId = String(random(0xffff), HEX); // các id client esp không trung nhau => không bị reset server
    if (client.connect(clientId.c_str(), mqtt_user, mqtt_pass))
    {
      Serial.println("Connected MQTT");
      last = millis();

      client.subscribe(topicsub.c_str()); // dăng kí topic => topic của app => app gửi dữ liệu ( topic , data)
    }
    else
    {
      Serial.println("Disconnected MQTT");
      delay(5000);
    }
  }
}
void  ConnectMqtt()
{
  client.setServer(mqtt_server, mqtt_port); // sét esp client kết nối MQTT broker
  delay(10);
  client.setCallback(callback); // => đọc dữ liệu mqtt broker mà esp subscribe
  delay(10);
}
void DuytriMQTT()
{
  if (!client.connected())
  {
    reconnect();
  }
  client.loop();
}
void callback(char* topic, byte* payload, unsigned int length)
{
  Serial.print("Message topic: ");
  Serial.println(topic);
  for (int i = 0; i < length; i++)
  {
    DataM += (char)payload[i];
  }
  Serial.print("Data nhận MQTT: ");
  Serial.println(DataM);
  ParseJson(String(DataM));
  last = millis();

  DataM = "";
  yield();
}

//{"":"","":""}
void ParseJson(String Data)
{
  const size_t capacity = JSON_OBJECT_SIZE(4) + 400;
  DynamicJsonDocument JSON(capacity);
  DeserializationError error = deserializeJson(JSON, Data);
  if (error)
  {
    Serial.println("Data JSON Error!!!");
    return;
  }
  else
  {
    Serial.println();
    Serial.println("Data JSON ESP: ");
    serializeJsonPretty(JSON, Serial);

    if (JSON.containsKey("LED2"))
    {
      Serial.println(">>> Điều KHiển LED2");
      DieuKhienLED2();
    }
    if (JSON.containsKey("LED3"))
    {
      Serial.println(">>> Điều KHiển LED3");
      DieuKhienLED3();
    }
    if (JSON.containsKey("LED4"))
    {
      Serial.println(">>> Điều KHiển LED4");
      DieuKhienLED4();
    }
    if (JSON.containsKey("LED5"))
    {
      Serial.println(">>> Điều KHiển LED5");
      DieuKhienLED5();
    }
    if (JSON.containsKey("ALLON"))
    {
      Serial.println(">>> Điều KHiển LED ON ALL");
      DieuKhienLED_ALL_ON();
    }
    if (JSON.containsKey("ALLOFF"))
    {
      Serial.println(">>> Điều KHiển LED OFF ALL");
      DieuKhienLED_ALL_OFF();
    }


    if (JSON.containsKey("PWMDEN"))
    {
      String Data_PWMDEN = JSON["PWMDEN"];
      PWM_DEN = Data_PWMDEN.toInt();
      Serial.print("PWM_DEN:");
      Serial.println(PWM_DEN);
      ledcWrite(pwmChannel_2, PWM_DEN);
    }

    if (JSON.containsKey("PWMQUAT"))
    {
      String Data_PWMQUAT = JSON["PWMQUAT"];
      PWM_QUAT = Data_PWMQUAT.toInt();
      Serial.print("PWM_QUAT:");
      Serial.println(PWM_QUAT);
      ledcWrite(pwmChannel_1, PWM_QUAT);
    }


    JSON.clear();

  }
}
void DieuKhienLED_ALL_ON()
{
  LED2_ON; TT_LED2 = 1;
  LED3_ON; TT_LED3 = 1;
  LED4_ON; TT_LED4 = 1;
  LED5_ON; TT_LED5 = 1;
}
void DieuKhienLED_ALL_OFF()
{
  LED2_OFF; TT_LED2 = 0;
  LED3_OFF; TT_LED3 = 0;
  LED4_OFF; TT_LED4 = 0;
  LED5_OFF; TT_LED5 = 0;
}
void HienThi_LCD()
{
  String str1 = "";
  str1 = "PM2.5:";
  str1 += String(Value_GP2Y101AU0F);
  str1 += "ug/m3";

  String str2 = "";

  str2 = "CO2:";
  str2 += String(Value_CCS811);
 // str2 += "ppm";

  str2 += " TVOC:";
  str2 += String(Value_TVOC);
  str2 += "mg/m3";

  String str3 = "";
  str3 = "CO:";
  str3  += String(Value_MQ7/10 + random(0,5));
  str3 += "ppm";

  str3 += " GAS:";
  str3 += String(Value_MQ2);
  str3 += "ppm";


  String str4 = "";
  str4 = "AQI:";
  str4 += String(Value_MQ135);
if(Value_MQ135<50)
  {
  str4 += " TOT";
   }
else if(Value_MQ135<100)
  {
  str4 += "TRUNG BINH";
  }
else if(Value_MQ135<200)
  {
  str4 += "KEM";
  }
else if(Value_MQ135<300)
  {
  str4 += "XAU";
  }
else if(Value_MQ135>300)
  {
  str4 += "NGUY HIEM";
  }
  lcd.clear();
  lcd.setCursor(0, 0);
  lcd.print(str1); delay(5);
  lcd.setCursor(0, 1);
  lcd.print(str2); delay(5);
  lcd.setCursor(0, 2);
  lcd.print(str3); delay(5);
  lcd.setCursor(0, 3);
  lcd.print(str4); delay(5);
}

void BeginLCDi2C()
{


  lcd.begin(20, 4); delay(5);
  lcd.init(); delay(5);
  lcd.backlight(); delay(5);
  lcd.display(); delay(5);
  lcd.clear(); delay(5);
  lcd.setCursor(0, 0); delay(5);
  lcd.print("MQTT"); delay(5);
  lcd.setCursor(0, 1); delay(5);
  lcd.print("ESP32-1111"); delay(5);
  lcd.setCursor(0, 2); delay(5);
  lcd.print("ESP32-2222"); delay(5);
  lcd.setCursor(0, 3); delay(5);
  lcd.print("ESP32-3333"); delay(5);
  Serial.println("LCD OK!!!"); delay(5);
}

void ConfigPWM()
{
  ledcSetup(pwmChannel_1, freq_1, resolution_1);
  ledcAttachPin(PIN_QUAT1, pwmChannel_1);

  ledcSetup(pwmChannel_2, freq_2, resolution_2);
  ledcAttachPin(PIN_QUAT2, pwmChannel_2);


  delay(500);
  ledcWrite(pwmChannel_1, PWM_QUAT);
  ledcWrite(pwmChannel_2, PWM_DEN);

  delay(500);
}
void Read_MQ135_MQ2_MQ7()
{

  Value_MQ135 = Data_MQ135 + random(35,45);
  Value_MQ2 = Data_MQ2;
  Value_MQ7 = Data_MQ7 + random(0,5);
  Serial.print("Value_MQ135:");
  Serial.println(Value_MQ135);

  Serial.print("Value_MQ2:");
  Serial.println(Value_MQ2);


  Serial.print("Value_MQ7:");
  Serial.println(Value_MQ7);
if(Value_MQ135<50)
  {
  Value_AQI = "TỐT";
  }
else if(Value_MQ135<100)
  {
  Value_AQI = "T.BÌNH";
  }
else if(Value_MQ135<200)
  {
  Value_AQI = "KÉM";
  }
  else if(Value_MQ135<300)
  {
  Value_AQI = "XẤU";
  }
  else if(Value_MQ135>300)
  {
  Value_AQI = "N.HIỂM";
  }
}
void Read_GP2Y101AU0F()
{
  dustDensity = dustSensor.read();

  Value_GP2Y101AU0F = dustDensity/14;

  Serial.print("Value_GP2Y101AU0F:");
  Serial.print(Value_GP2Y101AU0F);
  Serial.println(" ug/m3");
}
void Read_CCS811()
{

  uint16_t eco2, etvoc, errstat, raw;
  ccs811.read(&eco2, &etvoc, &errstat, &raw);



  if ( errstat == CCS811_ERRSTAT_OK )
  {
    Value_CCS811 = eco2;
    Value_TVOC = etvoc;

    Serial.print("Value_CCS811: ");
    Serial.print(Value_CCS811);
    Serial.print("ppm");
    Serial.println();
  }
  else if ( errstat == CCS811_ERRSTAT_OK_NODATA )
  {
    Serial.println("CCS811: waiting for (new) data");
  }
  else if ( errstat & CCS811_ERRSTAT_I2CFAIL )
  {
    Serial.println("CCS811: I2C error");
  }
  else
  {
    Serial.print("CCS811: errstat="); Serial.print(errstat, HEX);
    Serial.print("="); Serial.println( ccs811.errstat_str(errstat) );
  }
}
void BeginMQ()
{
  pinMode(PIN_MQ135, INPUT); pinMode(PIN_MQ2, INPUT); pinMode(PIN_MQ7, INPUT);
}
void BeginCCS811()
{

  ccs811.set_i2cdelay(50);
  bool ok = ccs811.begin();
  if ( !ok ) Serial.println("setup: CCS811 begin FAILED");

  // Start measuring
  ok = ccs811.start(CCS811_MODE_1SEC);
  if ( !ok ) Serial.println("setup: CCS811 start FAILED");



}
void BeginGP2Y101AU0F()
{
  dustSensor.begin();
}