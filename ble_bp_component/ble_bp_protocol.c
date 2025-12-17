#include "ble_bp_protocol.h"
#include <string.h>
#include <stdio.h>

static uint8_t calc_checksum(const uint8_t *data, uint16_t len) {
    uint32_t sum = 0;
    for (uint16_t i = 0; i < len; ++i) sum += data[i];
    return (uint8_t)(sum & 0xFF);
}

bool ble_bp_parse_packet(const uint8_t *data, uint16_t len, ble_bp_packet_t *out_pkt) {
    if (!data || !out_pkt || len < 12) return false;
    uint16_t offset = 0;
    out_pkt->protocol_version = data[offset++];
    out_pkt->cmd_type = data[offset++];
    out_pkt->seq = data[offset++];
    out_pkt->seq |= (data[offset++] << 8);
    out_pkt->rgb_count = data[offset++];
    if (out_pkt->rgb_count > BLE_BP_RGB_MAX_COUNT) return false;
    for (uint8_t i = 0; i < out_pkt->rgb_count; ++i) {
        memcpy(out_pkt->rgb[i], &data[offset], 3);
        offset += 3;
    }
    out_pkt->vibration_pattern = data[offset++];
    out_pkt->vibration_intensity = data[offset++];
    out_pkt->text_len = data[offset++];
    if (out_pkt->text_len > BLE_BP_TEXT_MAX_LEN) return false;
    memcpy(out_pkt->text, &data[offset], out_pkt->text_len);
    out_pkt->text[out_pkt->text_len] = 0;
    offset += out_pkt->text_len;
    out_pkt->duration_ms = data[offset++];
    out_pkt->duration_ms |= (data[offset++] << 8);
    out_pkt->checksum = data[offset++];
    // 校验和
    if (out_pkt->checksum != calc_checksum(data, offset - 1)) return false;
    return true;
}

void ble_bp_handle_packet(const ble_bp_packet_t *pkt) {
    // 用户可在此处根据pkt->cmd_type等字段处理业务
    printf("[BLE_BP] CMD=0x%02X, TEXT=%s, RGB_COUNT=%d, DURATION=%dms\n",
        pkt->cmd_type, pkt->text, pkt->rgb_count, pkt->duration_ms);
    // TODO: 按协议类型分发到具体业务处理
}