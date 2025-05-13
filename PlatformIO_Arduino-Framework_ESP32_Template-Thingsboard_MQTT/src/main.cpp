#include "main.h"

// Firmware title and version used to compare with remote version, to check if an update is needed.
// Title needs to be the same and version needs to be different --> downgrading is possible
constexpr char CURRENT_FIRMWARE_TITLE[] = "max30102";
constexpr char CURRENT_FIRMWARE_VERSION[] = "1.1";

// Maximum amount of retries we attempt to download each firmware chunck over MQTT
constexpr uint8_t FIRMWARE_FAILURE_RETRIES = 12U;

// Size of each firmware chunck downloaded over MQTT,
// increased packet size, might increase download speed
constexpr uint16_t FIRMWARE_PACKET_SIZE = 4096U;

// constexpr char WIFI_SSID[] = "RD-SEAI_2.4G";
constexpr char WIFI_SSID[] = "ACLAB";
constexpr char WIFI_PASSWORD[] = "ACLAB2023";
// constexpr char WIFI_SSID[] = "GUEST";
// constexpr char WIFI_PASSWORD[] = "tmagroup2025";
// constexpr char WIFI_SSID[] = "PJAT";
// constexpr char WIFI_PASSWORD[] = "phat123456";
// constexpr char WIFI_SSID[] = "601H6-KH&KTMT";
// constexpr char WIFI_PASSWORD[] = "svkhktmt";

// constexpr char WLAN_SSID[] = "RNM esp sida";
// constexpr char WLAN_PASS[] = "whyarewestillhere";

// IPAddress local_ip(192,168,1,1);
// IPAddress gateway(192,168,1,1);
// IPAddress subnet(255,255,255,0);

constexpr char MAX30102_TOKEN[] = "5f15h7jvxhjyv999cius"; //new device
// constexpr char MAX30102_TOKEN[] = "test_heart_pulse"; //new device

constexpr char THINGSBOARD_SERVER[] = "app.coreiot.io";
constexpr uint16_t THINGSBOARD_PORT = 1883U;

constexpr uint32_t MAX_MESSAGE_SIZE = 1024U;
constexpr uint32_t SERIAL_DEBUG_BAUD = 115200U;

MAX30105 particleSensor;

// const byte RATE_SIZE = 32; //Increase this for more averaging. 4 is good.
// byte rates[RATE_SIZE]; //Array of heart rates
// byte rateSpot = 0;
// long lastBeat = 0; //Time at which the last beat occurred
// float beatsPerMinute;
// int beatAvg;

#if defined(__AVR_ATmega328P__) || defined(__AVR_ATmega168__)
//Arduino Uno doesn't have enough SRAM to store 100 samples of IR led data and red led data in 32-bit format
//To solve this problem, 16-bit MSB of the sampled data will be truncated. Samples become 16-bit data.
uint16_t irBuffer[BUFFER_LEN]; //infrared LED sensor data
uint16_t redBuffer[BUFFER_LEN];  //red LED sensor data
#else
uint32_t irBuffer[BUFFER_LEN]; //infrared LED sensor data
uint32_t redBuffer[BUFFER_LEN];  //red LED sensor data
#endif

int32_t spo2; //SPO2 value
int32_t heartRate; //heart rate value
int8_t validSPO2; //indicator to show if the SPO2 calculation is valid
int8_t validHeartRate; //indicator to show if the heart rate calculation is valid

time_t now;
struct tm timeinfo;

TaskHandle_t xMax30102Handle = NULL;
TaskHandle_t xThingsHandle = NULL;
TaskHandle_t xScheHandle = NULL;

const char* ntpServer = "pool.ntp.org";
const long  gmtOffset_sec = 0;
const int   daylightOffset_sec = 3600;

float temp = 29.0;
float humid = 40.0;

char turnOnSchedule[100] = ""; 
char turnOffSchedule[100] = "";
uint64_t turnOnEpoch = 0; 
uint64_t turnOffEpoch = 0;

bool subscribed = false;
bool firstRequestedShared = false;
bool firstRequestedClient = false;

constexpr char RPC_SENT_TELE_SUCCESS_METHOD[] = "getTeleResponse";
constexpr char RPC_SENT_ATTR_SUCCESS_METHOD[] = "getAttrResponse";
constexpr char RPC_SCHEDULER_METHOD[] = "setScheduler";
constexpr char RPC_TURNON_SCHE_KEY[] = "turnOnPeriod";
constexpr char RPC_TURNOFF_SCHE_KEY[] = "turnOffPeriod";
constexpr char RPC_TURNON_EPO_KEY[] = "turnOnEpoch";
constexpr char RPC_TURNOFF_EPO_KEY[] = "turnOffEpoch";

constexpr char RPC_HEART_P_KEY[] = "heart_R";
constexpr char RPC_OXY_R_KEY[] = "SpO2";

constexpr uint8_t MAX_RPC_SUBSCRIPTIONS = 5U;
constexpr uint8_t MAX_RPC_RESPONSE = 5U;
constexpr uint8_t MAX_ATTR_SUBSCRIPTIONS = 3U;
constexpr size_t MAX_ATTRIBUTES = 4U;
constexpr uint64_t REQUEST_TIMEOUT_MICROSECONDS = 30U * 1000U * 1000U;

constexpr std::array<const char*, MAX_ATTRIBUTES> REQUESTED_SHARED_ATTRIBUTES = {
  RPC_TURNON_SCHE_KEY, 
  RPC_TURNOFF_SCHE_KEY, 
  RPC_TURNON_EPO_KEY,
  RPC_TURNOFF_EPO_KEY
};

// constexpr std::array<const char*, MAX_ATTRIBUTES> REQUESTED_CLIENT_ATTRIBUTES = {
//   RPC_HEART_P_KEY, 
//   RPC_OXY_R_KEY
// };

Server_Side_RPC<MAX_RPC_SUBSCRIPTIONS, MAX_RPC_RESPONSE> rpc;
Attribute_Request<MAX_ATTR_SUBSCRIPTIONS, MAX_ATTRIBUTES> attr_request;
OTA_Firmware_Update<> ota;

const std::array<IAPI_Implementation*, 3U> apis = {
    &rpc,
    &attr_request,
    &ota
};

WiFiClient wifiClient;
Arduino_MQTT_Client mqttClient(wifiClient);
ThingsBoardSized<32> tb(mqttClient, 4096, 4096, 4096, apis);

const Attribute_Request_Callback<MAX_ATTRIBUTES> sharedCallback(&processSharedAttributeRequest, REQUEST_TIMEOUT_MICROSECONDS, 
                                                                  &requestTimedOut, REQUESTED_SHARED_ATTRIBUTES);

#ifdef ESP8266
Arduino_ESP8266_Updater updater;
#else
#ifdef ESP32
Espressif_Updater<> updater;
#endif // ESP32
#endif // ESP8266

// Statuses for updating
bool currentFWSent = false;
bool updateRequestSent = false;

void update_starting_callback(void) {
  vTaskSuspend(xThingsHandle);
  // vTaskSuspend(xScheHandle);
  vTaskSuspend(xMax30102Handle);

  const esp_partition_t* ota_0 = esp_partition_find_first(ESP_PARTITION_TYPE_APP, ESP_PARTITION_SUBTYPE_APP_OTA_0, NULL);
    
  if (ota_0 == NULL) {
      Serial.printf("Cant find ota0\n");
      return;
  }

  const esp_partition_t* ota_1 = esp_partition_find_first(ESP_PARTITION_TYPE_APP, ESP_PARTITION_SUBTYPE_APP_OTA_1, NULL);
    
  if (ota_1 == NULL) {
      Serial.printf("Cant find ota1\n");
      return;
  }

  const esp_partition_t* factory = esp_partition_find_first(ESP_PARTITION_TYPE_APP, ESP_PARTITION_SUBTYPE_APP_FACTORY, NULL);
    
  if (ota_0 == NULL) {
      Serial.printf("Cant find factory\n");
      return;
  }
  // esp_err_t err = esp_ota_set_boot_partition(ota_0);
  // if (err != ESP_OK) {
  //     // Serial.printf("Cant set boot factory\n");
  //     Serial.printf("Cant set boot ota0\n");
  //     return;
  // }
  // Nothing to do
}

static bool diagnostic(void)
{
    gpio_config_t io_conf;
    io_conf.intr_type    = GPIO_INTR_DISABLE;
    io_conf.mode         = GPIO_MODE_INPUT;
    io_conf.pin_bit_mask = (1ULL << LED);
    io_conf.pull_down_en = GPIO_PULLDOWN_DISABLE;
    io_conf.pull_up_en   = GPIO_PULLUP_ENABLE;
    gpio_config(&io_conf);

    ESP_LOGI(TAG, "Diagnostics (5 sec)...");
    vTaskDelay(5000 / portTICK_PERIOD_MS);

    bool diagnostic_is_ok = gpio_get_level(LED);

    gpio_reset_pin(LED);
    return diagnostic_is_ok;
}

/// @brief End callback method that will be called as soon as the OTA firmware update, either finished successfully or failed.
/// Is meant to allow to either restart the device if the udpate was successfull or to restart any stopped services before the update started in the subscribed update_starting_callback
/// @param success Either true (update successful) or false (update failed)
void finished_callback(const bool & success) {
  if (success) {
    Serial.println("Done, Reboot now");
#ifdef ESP8266
    ESP.restart();
#else
#ifdef ESP32
    esp_restart();
#endif // ESP32
#endif // ESP8266
    return;
  }
  Serial.println("Downloading firmware failed");
}

void progress_callback(const size_t & current, const size_t & total) {
  Serial.printf("Progress %.2f%%\n", static_cast<float>(current * 100U) / total);
}

void InitWiFi() {
  Serial.println("Connecting to AP ...");
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  Serial.println("Connected to AP");

  configTime(gmtOffset_sec, daylightOffset_sec, ntpServer);

  if (setenv("TZ", "CST-7", 1) != 0) {
    ESP_LOGE("setenv", "cant set time zone");
  }

  // Update the timezone settings
  tzset();

  time(&now);
  localtime_r(&now, &timeinfo);
  
  Serial.printf("Current local time in Vietnam: %s", asctime(&timeinfo));
}

bool reconnect() {
  if (WiFi.status() == WL_CONNECTED) {
    return true;
  }
  InitWiFi();
  
  return true;
}


void processTeleSuccess(const JsonVariantConst &data, JsonDocument &response) {
  // Serial.printf("receive state \n");
  Serial.printf("Tele sent successfully (rpc)\n");
  // serializeJson(data[RPC_SENT_TELE_SUCCESS_METHOD], Serial);
  // Serial.println();
          
  // Serial.printf("temp: %.2f, humid: %.1f\n", ["temperature"], data[RPC_SENT_TELE_SUCCESS_METHOD]["humidity"]);
}

void requestTimedOut() {
  // Serial.printf("share attri time out\n");
}

void processAttrSuccess(const JsonVariantConst &data, JsonDocument &response) {
  Serial.printf("Attr sent successfully (rpc)\n");
}

void processSharedAttributeRequest(const JsonObjectConst &data) {
  firstRequestedShared = true;
  Serial.println("Requested shared attributes...");
  // for (auto it = data.begin(); it != data.end(); ++it) {
  //   Serial.println(it->key().c_str());
  //   // Shared attributes have to be parsed by their type.
  //   Serial.println(it->value().as<const char*>());
    
  // }

  
  turnOnEpoch = data[RPC_TURNON_EPO_KEY].as<const uint64_t>();
  turnOffEpoch = data[RPC_TURNOFF_EPO_KEY].as<const uint64_t>();

  strcpy(turnOnSchedule, data[RPC_TURNON_SCHE_KEY].as<const char*>());
  strcpy(turnOffSchedule, data[RPC_TURNOFF_SCHE_KEY].as<const char*>());

  Serial.printf("on epo %lld, off epo %lld\n", turnOnEpoch, turnOffEpoch);
  Serial.printf("on %s, off %s\n", turnOnSchedule, turnOffSchedule);
}

void TaskLEDControl(void *pvParameters) {
  pinMode(LED, OUTPUT); // Initialize LED pin
  int ledState = 0;

  // uint8_t pin = 30;
  while(1) {
    // digitalWrite(LED, HIGH); // Turn ON LED
    // Serial.print(LED); Serial.print(" ");
    // Serial.print(digitalRead(pin));
    // Serial.println();
    // Serial.println("Hello word");
    if (ledState == 0) {
      digitalWrite(LED, HIGH); // Turn ON LED
    } else {
      digitalWrite(LED, LOW); // Turn OFF LED
    }
    ledState = 1 - ledState;
    // pin += 1;
    vTaskDelay(500 / portTICK_PERIOD_MS);
  }
  vTaskDelete(NULL);
}

void TaskHeartPulse_Oxy(void* pvParameters){
  while(particleSensor.getIR() < 50000){
    Serial.println("No finger");
    vTaskDelay(pdMS_TO_TICKS(1000));
  }

  if(particleSensor.getIR() > 50000){
  //read the first 100 samples, and determine the signal range
    for (byte i = 0 ; i < BUFFER_LEN ; i++)
    {
      while (particleSensor.available() == false) //do we have new data?
        particleSensor.check(); //Check the sensor for new data
      
        long redVal = particleSensor.getRed();
        long irVal = particleSensor.getIR();
        
        if(irVal > 50000){
          irBuffer[i] = irVal;
        }
        else{
          irBuffer[i] = 0;
        }

        if(redVal > 50000){
          redBuffer[i] = redVal;
        }
        else{
          redBuffer[i] = 0;
        }
        
        particleSensor.nextSample(); //We're finished with this sample so move to next sample
        // Serial.print(F("red="));
        // Serial.print(redBuffer[i], DEC);
        // Serial.print(F(", ir="));
        // Serial.println(irBuffer[i], DEC);
      }
      //calculate heart rate and SpO2 after first 100 samples (first 4 seconds of samples)
      maxim_heart_rate_and_oxygen_saturation(irBuffer, BUFFER_LEN, redBuffer, &spo2, &validSPO2, &heartRate, &validHeartRate);
  }
        

    //Continuously taking samples from MAX30102.  Heart rate and SpO2 are calculated every 1 second
  while (1){
    //dumping the first 25 sets of samples in the memory and shift the last 75 sets of samples to the top
    for (byte i = 25; i < 100; i++)
    {
      redBuffer[i - 25] = redBuffer[i];
      irBuffer[i - 25] = irBuffer[i];
    }
    //take 25 sets of samples before calculating the heart rate.
    for (byte i = 75; i < 100; i++)
    {
      while (particleSensor.available() == false) //do we have new data?
        particleSensor.check(); //Check the sensor for new data
  
      long redVal = particleSensor.getRed();
      long irVal = particleSensor.getIR();
      
      if(irVal > 50000){
        irBuffer[i] = irVal;
      }
      else{
        irBuffer[i] = 0;
      }

      if(redVal > 50000){
        redBuffer[i] = redVal;
      }
      else{
        redBuffer[i] = 0;
      }
      particleSensor.nextSample(); //We're finished with this sample so move to next sample
      //send samples and calculation result to terminal program through UART
      // Serial.print(F("red="));
      // Serial.print(redBuffer[i], DEC);
      // Serial.print(F(", ir="));
      // Serial.println(irBuffer[i], DEC);
    }
    //After gathering 25 new samples recalculate HR and SP02
    maxim_heart_rate_and_oxygen_saturation(irBuffer, BUFFER_LEN, redBuffer, &spo2, &validSPO2, &heartRate, &validHeartRate);
    if((validHeartRate | validSPO2) & ((heartRate) < 161 & (heartRate > 39))){
      Serial.print(F("HR="));
      Serial.print(heartRate, DEC);
      Serial.print(F(", HRvalid="));
      Serial.print(validHeartRate, DEC);
      Serial.print(F(", SPO2="));
      Serial.print(spo2, DEC);
      Serial.print(F(", SPO2Valid="));
      Serial.println(validSPO2, DEC);
    }

    vTaskDelay(pdMS_TO_TICKS(1000));
  }

  vTaskDelete(NULL);
}

// void TaskTemperature_Humidity(void *pvParameters){
//   DHT20 dht20;
//   Wire.begin(SDA, SCL);
//   dht20.begin();
//   while(1){
//     dht20.read();
//     // double temperature = dht20.getTemperature();
//     // double humidity = dht20.getHumidity();
//     // Serial.print("Temp: "); Serial.print(temperature); Serial.print(" *C ");
//     // Serial.print(" Humidity: "); Serial.print(humidity); Serial.print(" %");
//     // Serial.println();
//     temp = dht20.getTemperature();
//     humid = dht20.getHumidity();
//     // Serial.print("Temp: "); Serial.print(temp); Serial.print(" *C ");
//     // Serial.print(" Humidity: "); Serial.print(humid); Serial.print(" %");
//     // Serial.println();
//     // temp += 1;
//     // humid += 1;
//     vTaskDelay(3000 / portTICK_PERIOD_MS);
//   }
  // vTaskDelete(NULL);
// }

void ThingsBoardTask(void *pvParameters) {
    Serial.print("Connecting to ThingsBoard...");
    
    while (1)
    {
      if (!reconnect()) {
        Serial.println("Cant Reconect WIFI");
        continue;
      }
      
      // if (!tb.connected()) {
      //   // Serial.printf("Scheduler Connecting to: (%s) with token (%s)\n", THINGSBOARD_SERVER, MAX30102_TOKEN);
      //   if (!tb.connect(THINGSBOARD_SERVER, MAX30102_TOKEN, THINGSBOARD_PORT)) {
      //     Serial.println("Failed to connect");
      //     return;
      //   }
      // }

      tb.loop();
      
      if(!subscribed){
        const std::array<RPC_Callback, MAX_RPC_SUBSCRIPTIONS> callbacks = {
        // Requires additional memory in the JsonDocument for the JsonDocument that will be copied into the response
        // RPC_Callback{ RPC_SENT_ATTR_SUCCESS_METHOD, processAttrSuccess },
        RPC_Callback{ RPC_SENT_TELE_SUCCESS_METHOD, processTeleSuccess }
        };
        // Perform a subscription. All consequent data processing will happen in
        // processTemperatureChange() and processSwitchChange() functions,
        // as denoted by callbacks array.
        subscribed = rpc.RPC_Subscribe(callbacks.begin(), callbacks.end());
      }
      
      StaticJsonDocument<256> doc;

      if(validHeartRate){
        // doc["heart_R"] = heartRate;
        doc["heartbeat"] = heartRate;
      }

      if(validSPO2){
        doc["oxygen"] = spo2;
        // doc["SpO2"] = spo2;
      }
      
      if((validHeartRate | validSPO2) & ((heartRate) < 161 & (heartRate > 39))){
        // Serialize the JSON document
        char buffer[MAX_MESSAGE_SIZE];
        size_t len = serializeJson(doc, buffer, sizeof(buffer));

        // Attempt to send data with retries
        const int maxRetries = 3;
        for (int attempt = 0; attempt < maxRetries; ++attempt) {
          // if (tb.sendAttributeJson(doc, len)) {
          //     // serializeJson(doc, Serial);
          //     // Serial.println();
          //     // Serial.println("Telemery attr successfully");
          //     break; // Exit if successful
          // } else {
          //     Serial.println("Failed to send client attr, retrying...");
          //     vTaskDelay(1000 / portTICK_PERIOD_MS);

          //     if(attempt == 2){

          //       // Serial.println((int)time(NULL));
          //       Serial.println("Failed to send client attr after multiple attempts");
          //     }
              
          // }
          if (tb.sendTelemetryJson(doc, len)) {
              // serializeJson(doc, Serial);
              // Serial.println();
              // Serial.println("Telemery sent successfully");
              break; // Exit if successful
          } else {
              Serial.println("Failed to send telemetry, retrying...");
              vTaskDelay(1000 / portTICK_PERIOD_MS);

              if(attempt == 2){

                // Serial.println((int)time(NULL));
                Serial.println("Failed to send telemetry after multiple attempts");
              }
              
          }
        }
      }

      vTaskDelay(5000 / portTICK_PERIOD_MS);
    }

    vTaskDelete(NULL);
}

void WifiTask(void *pvParameters) {
    Serial.print("Connecting to Wifi...");
    WiFi.begin(WIFI_SSID, WIFI_PASSWORD);

    Serial.println("Wifi connected");

    configTime(gmtOffset_sec, daylightOffset_sec, ntpServer);

    if (setenv("TZ", "CST-7", 1) != 0) {
      ESP_LOGE("setenv", "cant set time zone");
    }

    // Update the timezone settings
    tzset();

    time(&now);
    localtime_r(&now, &timeinfo);
    // // Is time set? If not, tm_year will be (1970 - 1900).
    // if (timeinfo.tm_year < (2025 - 1900)) {
    //     ESP_LOGI("time", "Time is not set yet. Connecting to WiFi and getting time over NTP.");
    //     // obtain_time();
    //     // update 'now' variable with current time
    //     time(&now);
    // }
    Serial.printf("Current local time in Vietnam: %s", asctime(&timeinfo));


    // while (1) {
    //   if (!reconnect()) {
    //     continue;
    //   }
    //   // else{
    //   //   Serial.println("Wifi still connect");
    //   // }

    //   vTaskDelay(pdMS_TO_TICKS(1000));
    // }

    vTaskDelete(NULL);
}

// void dht20Power(uint64_t turnOnEpoch, uint64_t turnOffEpoch, char turnOnPeriod[], char turnOffPeriod[]){
//   time(&now);
//   localtime_r(&now, &timeinfo);
//   int turnOnSche = ((turnOnPeriod[0] - '0') * 10  + (turnOnPeriod[1] - '0')) * 60 + (turnOnPeriod[3] - '0') * 10 + (turnOnPeriod[0] - '4');
//   int turnOffSche = ((turnOffPeriod[0] - '0') * 10  + (turnOffPeriod[1] - '0')) * 60 + (turnOffPeriod[3] - '0') * 10 + (turnOffPeriod[0] - '4');
//   // Serial.printf("on Sche %d, off Sche %d\n", turnOnSche, turnOffSche);
//   if(now >= turnOffEpoch || (timeinfo.tm_hour * 60 + timeinfo.tm_min) >=  turnOffSche){
//     Serial.println("Turn off DHT20");
//     vTaskSuspend(xdht20Handle);
//   }
//   if(now >= turnOnEpoch || (timeinfo.tm_hour * 60 + timeinfo.tm_min) >=  turnOnSche){
//     Serial.println("Turn on DHT20");
//     vTaskResume(xdht20Handle);
//   }
// }

// void TaskScheduler(void *pvParameters) {
//   int count = 0, delay_period = 1000;
//   // Increase buffer size if necessary
//   tb.setBufferSize(MAX_MESSAGE_SIZE, MAX_MESSAGE_SIZE); // Adjust as needed
//   while(1){
//     if (!reconnect()) {
//       Serial.println("Cant Reconect WIFI");
//       return;
//     }
//     if (!tb.connected()) {
//       // Serial.printf("Scheduler Connecting to: (%s) with token (%s)\n", THINGSBOARD_SERVER, MAX30102_TOKEN);
//       if (!tb.connect(THINGSBOARD_SERVER, MAX30102_TOKEN, THINGSBOARD_PORT)) {
//         Serial.println("Failed to connect");
//         return;
//       }
//     }
//     tb.loop();
//     // Shared attributes we want to request from the server
//     attr_request.Shared_Attributes_Request(sharedCallback);
//     if (firstRequestedShared) {
//       delay_period = 10000;  
//     }
//     vTaskDelay(pdMS_TO_TICKS(delay_period));
//   }
//   vTaskDelete(NULL);
// }

void TaskOTA(void *pvParameters) {
  Serial.printf("Cur fw ver %s\n", CURRENT_FIRMWARE_VERSION);
  esp_partition_t const * running = esp_ota_get_running_partition();
  esp_partition_t const * configured = esp_ota_get_boot_partition();
  esp_ota_set_boot_partition(running);

  while(1){
    if (!reconnect()) {
      Serial.println("Cant Reconect WIFI");
      return;
    }
    
    if (!tb.connected()) {
      Serial.printf("Connecting to: (%s) with token (%s)\n", THINGSBOARD_SERVER, MAX30102_TOKEN);
      if (!tb.connect(THINGSBOARD_SERVER, MAX30102_TOKEN, THINGSBOARD_PORT)) {
        Serial.println("Failed to connect");
        return;
      }
    }

    // Serial.printf("running: %x, %d, %d, %d\n", running->address, running->encrypted, running->flash_chip->chip_id, running->size, running->subtype, running->type);
    // Serial.printf("configured: %x, %d, %d, %d\n", configured->address, configured->encrypted, configured->flash_chip->chip_id, configured->size, configured->subtype, configured->type);
    // Serial.printf("new configured: %x, %d, %d, %d\n", configured->address, configured->encrypted, configured->flash_chip->chip_id, configured->size, configured->subtype, configured->type);
    
    // Serial.printf("sent request: %d, update: %d\n", currentFWSent, updateRequestSent);
    if (!currentFWSent) {
      currentFWSent = ota.Firmware_Send_Info(CURRENT_FIRMWARE_TITLE, CURRENT_FIRMWARE_VERSION);
    }

    if (!updateRequestSent) {
      Serial.println("Firwmare Update Subscription...");
      OTA_Update_Callback callback(CURRENT_FIRMWARE_TITLE, CURRENT_FIRMWARE_VERSION, &updater, &finished_callback, &progress_callback, &update_starting_callback, FIRMWARE_FAILURE_RETRIES, FIRMWARE_PACKET_SIZE, REQUEST_TIMEOUT_MICROSECONDS);
      callback.Set_Timeout(REQUEST_TIMEOUT_MICROSECONDS);
      updateRequestSent = ota.Subscribe_Firmware_Update(callback);
      // ota.Process_Response();
      // updateRequestSent = ota.Start_Firmware_Update(callback);
    }

    // Serial.printf("sent request: %d, update: %d\n", currentFWSent, updateRequestSent);


    tb.loop();
    
    vTaskDelay(pdMS_TO_TICKS(3000));
  }

  vTaskDelete(NULL);
}

// PulseOximeter pox;

// uint32_t tsLastReport = 0;

// float beat_send = 0;
// float spo2_send = 0;

// // Callback (registered below) fired when a pulse is detected
// void onBeatDetected(){  
//   Serial.println("Beat!");
// }

void setup() {
  const esp_partition_t *running = esp_ota_get_running_partition();
  esp_ota_img_states_t ota_state;
  if (esp_ota_get_state_partition(running, &ota_state) == ESP_OK) {
      if (ota_state == ESP_OTA_IMG_PENDING_VERIFY) {
          // run diagnostic function ...
          bool diagnostic_is_ok = diagnostic();
          if (diagnostic_is_ok) {
              Serial.println("Diagnostics completed successfully! Continuing execution ...");
              esp_ota_mark_app_valid_cancel_rollback();
          } else {
              Serial.println("Diagnostics failed! Start rollback to the previous version ...");
              esp_ota_mark_app_invalid_rollback_and_reboot();
          }
      }
  }
  // InitWiFi();

  // put your setup code here, to run once:
  Serial.begin(SERIAL_DEBUG_BAUD);
  Wire.begin(SDA, SCL);

  // memset(rates, 0 , RATE_SIZE);
  
  delay(2000);
  if (!reconnect()) {
    Serial.println("Cant Reconect WIFI");
    return;
  }

  // while (!pox.begin()) {
  //   Serial.println("FAILED");
  //   vTaskDelay(pdMS_TO_TICKS(1000));
  // }

  while (!particleSensor.begin(Wire, I2C_SPEED_FAST)) {
    Serial.println("MAX30102 was not found. Please check wiring/power. ");
    vTaskDelay(pdMS_TO_TICKS(1000));
  }

  Serial.println("Place your index finger on the sensor with steady pressure.");
  // particleSensor.setup(); //Configure sensor with default settings
  // particleSensor.setPulseAmplitudeRed(0x0A); //Turn Red LED to low to indicate sensor is running
  // particleSensor.setPulseAmplitudeGreen(0); //Turn off Green LED

  byte ledBrightness = 60; //Options: 0=Off to 255=50mA
  byte sampleAverage = 4; //Options: 1, 2, 4, 8, 16, 32
  byte ledMode = 2; //Options: 1 = Red only, 2 = Red + IR, 3 = Red + IR + Green
  byte sampleRate = 100; //Options: 50, 100, 200, 400, 800, 1000, 1600, 3200
  int pulseWidth = 411; //Options: 69, 118, 215, 411
  int adcRange = 4096; //Options: 2048, 4096, 8192, 16384
  particleSensor.setup(ledBrightness, sampleAverage, ledMode, sampleRate, pulseWidth, adcRange); //Configure sensor with these settings
  
  // WiFi.softAPConfig(local_ip, gateway, subnet);
  // WiFi.softAP(WLAN_SSID, WLAN_PASS);
  
  // xTaskCreate(WifiTask, "Wifi", 4096, NULL, 6, NULL);
  xTaskCreate(TaskLEDControl, "LED Control", 2048, NULL, 1, NULL);
  xTaskCreate(TaskHeartPulse_Oxy, "Max30102", 2048, NULL, 4, &xMax30102Handle);
  xTaskCreate(ThingsBoardTask, "Thingsboard", 8192, NULL, 3, &xThingsHandle);
  // xTaskCreate(TaskScheduler, "Scheduler", 8192, NULL, 2, &xScheHandle);
  xTaskCreate(TaskOTA, "OTA", 8192, NULL, 5, NULL);
}

void loop() {
  // long irValue = particleSensor.getIR();
  // if (irValue > 50000){
  //   ++count;
  //   if (checkForBeat(irValue) == true) {
  //     //We sensed a beat!
  //     long delta = millis() - lastBeat;
  //     beatsPerMinute = 60 / (delta / 1000.0);

  //     Serial.printf("BPM %f\n", beatsPerMinute);
  //     count = 0;
  //     if (beatsPerMinute < 255 && beatsPerMinute > 20) {
  //       rates[rateSpot++] = (byte)beatsPerMinute; //Store this reading in the array
  //       ++off;
  //       rateSpot %= RATE_SIZE; //Wrap variable

  //       //Take average of readings
  //       beatAvg = 0;
  //       for (byte x = 0 ; x < RATE_SIZE ; x++)
  //         beatAvg += rates[x];

  //       if(off < RATE_SIZE) beatAvg /= off;
  //       else beatAvg /= RATE_SIZE;
  //     }

  //     lastBeat = millis();
  //   }
  //   Serial.print("IR=");
  //   Serial.print(irValue);
  //   Serial.print(", BPM=");
  //   Serial.print(beatsPerMinute);
  //   Serial.print(", Avg BPM=");
  //   Serial.println(beatAvg);
  //   Serial.printf("%ld\n", count);
  // }
  // else{
  //   Serial.print(" No finger?");
  // }
  // Serial.println();


  // pox.update();

  // if (millis() - tsLastReport > REPORTING_PERIOD_MS){
  //   beat_send = pox.getHeartRate();
  //   spo2_send = pox.getSpO2();
  //   Serial.print("Heart rate:");
  //   Serial.print(pox.getHeartRate());
  //   Serial.print("bpm / SpO2:");
  //   Serial.print(pox.getSpO2());
  //   Serial.println("%");
    
  //   tsLastReport = millis();
  // }

  // Serial.printf("Cur fw ver %s\n", CURRENT_FIRMWARE_VERSION);
  // if (!tb.connected()) {
  //   Serial.printf("Connecting to: (%s) with token (%s)\n", THINGSBOARD_SERVER, MAX30102_TOKEN);
  //   if (!tb.connect(THINGSBOARD_SERVER, MAX30102_TOKEN, THINGSBOARD_PORT)) {
  //     Serial.println("Failed to connect");
  //     return;
  //   }
  // }

  // esp_partition_t const * running = esp_ota_get_running_partition();
  // esp_partition_t const * configured = esp_ota_get_boot_partition();
  
  // Serial.printf("running: %x, %d, %d, %d\n", running->address, running->encrypted, running->flash_chip->chip_id, running->size, running->subtype, running->type);
  // Serial.printf("configured: %x, %d, %d, %d\n", configured->address, configured->encrypted, configured->flash_chip->chip_id, configured->size, configured->subtype, configured->type);
  // esp_ota_set_boot_partition(running);
  // Serial.printf("new configured: %x, %d, %d, %d\n", configured->address, configured->encrypted, configured->flash_chip->chip_id, configured->size, configured->subtype, configured->type);
  // // Serial.printf("sent request: %d, update: %d\n", currentFWSent, updateRequestSent);
  // if (!currentFWSent) {
  //   currentFWSent = ota.Firmware_Send_Info(CURRENT_FIRMWARE_TITLE, CURRENT_FIRMWARE_VERSION);
  // }

  // if (!updateRequestSent) {
  //   Serial.println("Firwmare Update Subscription...");
  //   OTA_Update_Callback callback(CURRENT_FIRMWARE_TITLE, CURRENT_FIRMWARE_VERSION, &updater, &finished_callback, &progress_callback, &update_starting_callback, FIRMWARE_FAILURE_RETRIES, FIRMWARE_PACKET_SIZE, REQUEST_TIMEOUT_MICROSECONDS);
  //   callback.Set_Timeout(REQUEST_TIMEOUT_MICROSECONDS);
  //   updateRequestSent = ota.Subscribe_Firmware_Update(callback);
  //   // ota.Process_Response();
  //   // updateRequestSent = ota.Start_Firmware_Update(callback);
  // }

  // // Serial.printf("sent request: %d, update: %d\n", currentFWSent, updateRequestSent);


  // tb.loop();

  

  // for(int count = 0; count < 4;){
    // if(!requestedShared){
      // int count = 0;

      // requestedShared = attr_request.Shared_Attributes_Request(sharedCallback);
      
      // if (!requestedShared) {
      //   // Serial.println("---------------------");
      //   // ++count;
      //   attr_request.Unsubscribe();
      // }
      // // if(count == 3){
      //   // count = -1;
        // Serial.printf("on epo %ld, off epo %ld\n", turnOnEpoch, turnOffEpoch);
        // Serial.printf("on %s, off %s\n", turnOnSchedule, turnOffSchedule);
      // }
      // count++;

      // requestedShared = attr_request.Shared_Attributes_Request(sharedCallback);
      // if (!requestedShared) {
      //   Serial.println("Failed to request shared attributes 3s");
        // ++count;
      // }
      // else {
      //   // Serial.println(count);
      //   // requestedShared = false;
      //   // break;
      // }
    // }
  //   delay(1000);
  // }
  
  
  // vTaskDelay(pdMS_TO_TICKS(10));
}