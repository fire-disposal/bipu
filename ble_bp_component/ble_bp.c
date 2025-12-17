#include "ble_bp.h"
#include "ble_bp_protocol.h"
#include <string.h>
#include "esp_log.h"
#include "nvs_flash.h"

#define TAG "BLE_BP"

// UUIDs (128-bit, little endian)
static const uint8_t BP_SERVICE_UUID[16]     = {0x9E,0xDC,0x24,0xE5,0xA9,0xE0,0x93,0xF3,0xA3,0xB5,0x01,0x00,0x40,0x6E,0x00,0x00};
static const uint8_t BP_CHAR_CMD_UUID[16]    = {0x9E,0xDC,0x24,0xE5,0xA9,0xE0,0x93,0xF3,0xA3,0xB5,0x03,0x00,0x40,0x6E,0x00,0x00};
static const uint8_t BP_CHAR_NOTIFY_UUID[16] = {0x9E,0xDC,0x24,0xE5,0xA9,0xE0,0x93,0xF3,0xA3,0xB5,0x04,0x00,0x40,0x6E,0x00,0x00};

static uint16_t bp_service_handle = 0;
static uint16_t bp_char_cmd_handle = 0;
static uint16_t bp_char_notify_handle = 0;
static esp_gatt_if_t bp_gatts_if = 0;
static uint16_t bp_conn_id = 0;

static void gap_event_handler(esp_gap_ble_cb_event_t event, esp_ble_gap_cb_param_t *param) {
    // 可根据需要实现广播等
}

static void gatts_event_handler(esp_gatts_cb_event_t event, esp_gatt_if_t gatts_if,
                               esp_ble_gatts_cb_param_t *param) {
    switch (event) {
        case ESP_GATTS_CONNECT_EVT:
            bp_conn_id = param->connect.conn_id;
            bp_gatts_if = gatts_if;
            ESP_LOGI(TAG, "Device connected, conn_id=%d", bp_conn_id);
            break;
        case ESP_GATTS_DISCONNECT_EVT:
            ESP_LOGI(TAG, "Device disconnected");
            bp_conn_id = 0;
            break;
        case ESP_GATTS_WRITE_EVT:
            if (param->write.handle == bp_char_cmd_handle && param->write.len > 0) {
                ble_bp_packet_t pkt;
                if (ble_bp_parse_packet(param->write.value, param->write.len, &pkt)) {
                    ESP_LOGI(TAG, "Received valid BP packet, CMD=0x%02X", pkt.cmd_type);
                    ble_bp_handle_packet(&pkt);
                } else {
                    ESP_LOGW(TAG, "Invalid BP packet received");
                }
            }
            break;
        case ESP_GATTS_CREATE_EVT:
            bp_service_handle = param->create.service_handle;
            break;
        case ESP_GATTS_ADD_CHAR_EVT:
            if (param->add_char.char_uuid.len == ESP_UUID_LEN_128) {
                if (memcmp(param->add_char.char_uuid.uuid.uuid128, BP_CHAR_CMD_UUID, 16) == 0) {
                    bp_char_cmd_handle = param->add_char.attr_handle;
                } else if (memcmp(param->add_char.char_uuid.uuid.uuid128, BP_CHAR_NOTIFY_UUID, 16) == 0) {
                    bp_char_notify_handle = param->add_char.attr_handle;
                }
            }
            break;
        default:
            break;
    }
}

void ble_bp_init(void) {
    esp_err_t ret = nvs_flash_init();
    if (ret == ESP_ERR_NVS_NO_FREE_PAGES || ret == ESP_ERR_NVS_NEW_VERSION_FOUND) {
        ESP_ERROR_CHECK(nvs_flash_erase());
        ret = nvs_flash_init();
    }
    ESP_ERROR_CHECK(ret);

    esp_bt_controller_config_t bt_cfg = BT_CONTROLLER_INIT_CONFIG_DEFAULT();
    ESP_ERROR_CHECK(esp_bt_controller_init(&bt_cfg));
    ESP_ERROR_CHECK(esp_bt_controller_enable(ESP_BT_MODE_BLE));
    ESP_ERROR_CHECK(esp_bluedroid_init());
    ESP_ERROR_CHECK(esp_bluedroid_enable());

    esp_ble_gap_register_callback(gap_event_handler);
    esp_ble_gatts_register_callback(gatts_event_handler);

    // 注册服务和特征
    esp_gatt_srvc_id_t service_id = {
        .is_primary = true,
        .id = {.inst_id = 0, .uuid = {.len = ESP_UUID_LEN_128}}
    };
    memcpy(service_id.id.uuid.uuid.uuid128, BP_SERVICE_UUID, 16);
    ESP_ERROR_CHECK(esp_ble_gatts_create_service(bp_gatts_if, &service_id, 8));

    // 在 ESP_GATTS_CREATE_EVT 后添加特征
    // 这里只做演示，实际应在回调中添加
    // esp_ble_gatts_add_char(bp_service_handle, ...);
}

void ble_bp_send_notify(const uint8_t *data, uint16_t len) {
    if (bp_gatts_if && bp_conn_id && bp_char_notify_handle) {
        esp_ble_gatts_send_indicate(bp_gatts_if, bp_conn_id, bp_char_notify_handle, len, (uint8_t *)data, false);
    }
}