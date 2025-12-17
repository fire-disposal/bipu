#pragma once

#include "esp_bt.h"
#include "esp_gatts_api.h"
#include "esp_gap_ble_api.h"

#ifdef __cplusplus
extern "C" {
#endif

void ble_bp_init(void);
void ble_bp_send_notify(const uint8_t *data, uint16_t len);

#ifdef __cplusplus
}
#endif