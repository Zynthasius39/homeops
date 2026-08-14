#include <string.h>
#include <stdbool.h>
#include <stdio.h>
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "freertos/event_groups.h"
#include "esp_system.h"
#include "esp_wifi.h"
#include "esp_event.h"
#include "esp_log.h"
#include "esp_sleep.h"
#include "esp_http_client.h"
#include "esp_crt_bundle.h"
#include "nvs_flash.h"
#include "lwip/sockets.h"
#include "lwip/netdb.h"
#include "secrets.h"

// --- CONFIGURATION ---
// Target PC MAC Address (00:c8:7f:68:81:7b)
static const uint8_t TARGET_MAC[6] = {0x00, 0xc8, 0x7f, 0x68, 0x81, 0x7b};

// WoL UDP Port (7 or 9)
#define WOL_PORT 9
#define WIFI_CONNECT_WAIT_MS 10000
#define RETRY_DELAY_MS       5000

static const char *TAG = "Alakx_Python";
static EventGroupHandle_t s_wifi_event_group;
#define WIFI_CONNECTED_BIT BIT0

static void wifi_event_handler(void* arg, esp_event_base_t event_base,
                               int32_t event_id, void* event_data)
{
    if (event_base == WIFI_EVENT && event_id == WIFI_EVENT_STA_START) {
        esp_wifi_connect();
    } else if (event_base == WIFI_EVENT && event_id == WIFI_EVENT_STA_DISCONNECTED) {
        // Do not let callers use a connection that has just gone away.
        xEventGroupClearBits(s_wifi_event_group, WIFI_CONNECTED_BIT);
        ESP_LOGW(TAG, "Wi-Fi disconnected; will retry connection");
    } else if (event_base == WIFI_EVENT && event_id == WIFI_EVENT_STA_CONNECTED) {
        ESP_LOGI(TAG, "Wi-Fi associated; waiting for DHCP lease...");
    } else if (event_base == IP_EVENT && event_id == IP_EVENT_STA_GOT_IP) {
        ip_event_got_ip_t* event = (ip_event_got_ip_t*) event_data;
        ESP_LOGI(TAG, "Got IP via DHCP: " IPSTR, IP2STR(&event->ip_info.ip));
        xEventGroupSetBits(s_wifi_event_group, WIFI_CONNECTED_BIT);
    }
}

/* Wait forever, but make a fresh association attempt every 10 seconds.
 * This also covers the access point not being available at boot. */
static void wait_for_wifi(void)
{
    while ((xEventGroupGetBits(s_wifi_event_group) & WIFI_CONNECTED_BIT) == 0) {
        ESP_LOGI(TAG, "Waiting for Wi-Fi; retrying in %d seconds...",
                 WIFI_CONNECT_WAIT_MS / 1000);

        EventBits_t bits = xEventGroupWaitBits(s_wifi_event_group,
                                                WIFI_CONNECTED_BIT,
                                                pdFALSE, pdTRUE,
                                                pdMS_TO_TICKS(WIFI_CONNECT_WAIT_MS));
        if ((bits & WIFI_CONNECTED_BIT) == 0) {
            esp_err_t err = esp_wifi_connect();
            if (err != ESP_OK && err != ESP_ERR_WIFI_STATE) {
                ESP_LOGW(TAG, "Wi-Fi reconnect request failed: %s", esp_err_to_name(err));
            }
        }
    }
}

static void reconnect_wifi(void)
{
    xEventGroupClearBits(s_wifi_event_group, WIFI_CONNECTED_BIT);
    esp_wifi_disconnect();
    vTaskDelay(pdMS_TO_TICKS(RETRY_DELAY_MS));
    esp_wifi_connect();
}

static void wifi_init_sta(void)
{
    s_wifi_event_group = xEventGroupCreate();

    ESP_ERROR_CHECK(esp_netif_init());
    ESP_ERROR_CHECK(esp_event_loop_create_default());

    esp_netif_t *sta_netif = esp_netif_create_default_wifi_sta();
    esp_netif_set_hostname(sta_netif, "somnus");

    // Temporarily use DHCP. Uncomment this block to restore the static IP.
    // esp_netif_dhcpc_stop(sta_netif);
    // esp_netif_ip_info_t ip_info;
    // IP4_ADDR(&ip_info.ip, 10, 0, 10, 16);
    // IP4_ADDR(&ip_info.gw, 10, 0, 10, 17);
    // IP4_ADDR(&ip_info.netmask, 255, 255, 255, 0);
    // esp_netif_set_ip_info(sta_netif, &ip_info);

    // 3. Initialize Wi-Fi driver
    wifi_init_config_t cfg = WIFI_INIT_CONFIG_DEFAULT();
    ESP_ERROR_CHECK(esp_wifi_init(&cfg));

    // 4. Register event handler (fixes the "unused" warning)
    ESP_ERROR_CHECK(esp_event_handler_instance_register(WIFI_EVENT,
                                                        ESP_EVENT_ANY_ID,
                                                        &wifi_event_handler,
                                                        NULL,
                                                        NULL));
    ESP_ERROR_CHECK(esp_event_handler_instance_register(IP_EVENT,
                                                        IP_EVENT_STA_GOT_IP,
                                                        &wifi_event_handler,
                                                        NULL,
                                                        NULL));

    wifi_config_t wifi_config = {
        .sta = {
            .ssid = WIFI_SSID,
            .password = WIFI_PASS,
        },
    };
    ESP_ERROR_CHECK(esp_wifi_set_mode(WIFI_MODE_STA));
    ESP_ERROR_CHECK(esp_wifi_set_config(WIFI_IF_STA, &wifi_config));
    ESP_ERROR_CHECK(esp_wifi_start());
}

static bool send_magic_packet(const uint8_t *mac_addr)
{
    // Build 102-byte magic packet: 6x 0xFF + 16x MAC Address
    uint8_t packet[102];
    memset(packet, 0xFF, 6);
    for (int i = 0; i < 16; i++) {
        memcpy(&packet[6 + (i * 6)], mac_addr, 6);
    }

    int sock = socket(AF_INET, SOCK_DGRAM, IPPROTO_IP);
    if (sock < 0) {
        ESP_LOGE(TAG, "Unable to create socket: errno %d", errno);
        return false;
    }

    int broadcast_enable = 1;
    setsockopt(sock, SOL_SOCKET, SO_BROADCAST, &broadcast_enable, sizeof(broadcast_enable));

    struct sockaddr_in dest_addr;
    dest_addr.sin_addr.s_addr = inet_addr("255.255.255.255");
    dest_addr.sin_family = AF_INET;
    dest_addr.sin_port = htons(WOL_PORT);

    int err = sendto(sock, packet, sizeof(packet), 0, (struct sockaddr *)&dest_addr, sizeof(dest_addr));
    if (err < 0) {
        ESP_LOGE(TAG, "Send failed: errno %d", errno);
    } else {
        ESP_LOGI(TAG, "Magic packet sent!");
    }

    close(sock);
    return err >= 0;
}

static bool http_up(void)
{
  char url[256];
  char json_payload[512];
  snprintf(url, sizeof(url), "https://api.telegram.org/bot%s/sendMessage",
           TELEGRAM_BOT_TOKEN);
  snprintf(json_payload, sizeof(json_payload),
           "{\"chat_id\": \"%s\", \"text\": \"🔌 ESP32: Alakx Python is UP!\"}",
           TELEGRAM_CHAT_ID);

  esp_http_client_config_t config = {
      .url = url,
      .method = HTTP_METHOD_POST,
      .crt_bundle_attach = esp_crt_bundle_attach, // Requires TLS/SSL for HTTPS
      .timeout_ms = 10000,
  };

  esp_http_client_handle_t client = esp_http_client_init(&config);
  if (client == NULL) {
      ESP_LOGE("TELEGRAM", "Unable to create HTTP client");
      return false;
  }
  esp_http_client_set_header(client, "Content-Type", "application/json");
  esp_http_client_set_post_field(client, json_payload, strlen(json_payload));

  esp_err_t err = esp_http_client_perform(client);
  int status = esp_http_client_get_status_code(client);
  bool success = err == ESP_OK && status >= 200 && status < 300;
  if (success) {
      ESP_LOGI("TELEGRAM", "Message sent! Status = %d", esp_http_client_get_status_code(client));
  } else {
      ESP_LOGE("TELEGRAM", "Message failed (result: %s, status: %d)",
               esp_err_to_name(err), status);
  }

  esp_http_client_cleanup(client);
  return success;
}

void app_main(void)
{
    // Init NVS
    esp_err_t ret = nvs_flash_init();
    if (ret == ESP_ERR_NVS_NO_FREE_PAGES || ret == ESP_ERR_NVS_NEW_VERSION_FOUND) {
        ESP_ERROR_CHECK(nvs_flash_erase());
        ret = nvs_flash_init();
    }
    ESP_ERROR_CHECK(ret);

    // Connect to Wi-Fi (currently using DHCP)
    wifi_init_sta();

    // Keep retrying if the AP is absent, drops out, or the internet is down.
    for (;;) {
        wait_for_wifi();

        if (!http_up()) {
            ESP_LOGW(TAG, "Internet check failed; reconnecting and retrying...");
            reconnect_wifi();
            continue;
        }

        if (!send_magic_packet(TARGET_MAC)) {
            ESP_LOGW(TAG, "WoL send failed; reconnecting and retrying...");
            reconnect_wifi();
            continue;
        }

        break;
    }

    // Preserve the original one-shot behavior after a successful send.
    vTaskDelay(pdMS_TO_TICKS(100));
    esp_wifi_stop();

    ESP_LOGI(TAG, "Entering Deep Sleep...");
    // esp_deep_sleep_start();
}
