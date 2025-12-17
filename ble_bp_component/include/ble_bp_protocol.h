#pragma once

#include <stdint.h>
#include <stdbool.h>

#define BLE_BP_PROTOCOL_VERSION 0x01
#define BLE_BP_TEXT_MAX_LEN     64
#define BLE_BP_RGB_MAX_COUNT    20

typedef enum {
    BLE_BP_CMD_NOTIFICATION     = 0x01,
    BLE_BP_CMD_RGB_CONTROL      = 0x02,
    BLE_BP_CMD_VIBRATION        = 0x03,
    BLE_BP_CMD_TEXT_DISPLAY     = 0x04,
    BLE_BP_CMD_DEVICE_STATUS    = 0x05,
    BLE_BP_CMD_BATTERY_LEVEL    = 0x06
} ble_bp_cmd_type_t;

typedef struct {
    uint8_t protocol_version;
    uint8_t cmd_type;
    uint16_t seq;
    uint8_t rgb_count;
    uint8_t rgb[BLE_BP_RGB_MAX_COUNT][3];
    uint8_t vibration_pattern;
    uint8_t vibration_intensity;
    uint8_t text_len;
    char text[BLE_BP_TEXT_MAX_LEN + 1];
    uint16_t duration_ms;
    uint8_t checksum;
} ble_bp_packet_t;

bool ble_bp_parse_packet(const uint8_t *data, uint16_t len, ble_bp_packet_t *out_pkt);
void ble_bp_handle_packet(const ble_bp_packet_t *pkt);
