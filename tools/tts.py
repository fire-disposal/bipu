#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import json
import yaml
import requests
import uuid
import base64
from pathlib import Path
from concurrent.futures import ThreadPoolExecutor, as_completed

# =========================
# 配置 (请务必替换为您的真实信息)
# =========================
APP_ID = "9186606170"               # 您的火山引擎 AppID
ACCESS_TOKEN = "5zmuJOVf5oBsgsi_eqB3a5NOCRVWjXbk" # 您的Access Token
# 重要: 根据您使用的音色类型选择正确的 Resource ID
# - TTS 2.0 音色 (如 saturn_zh_male_xxx): "seed-tts-2.0"
# - TTS 1.0 音色: "seed-tts-1.0" 或 "seed-tts-1.0-concurr"
# - 声音复刻 2.0 音色: "seed-icl-2.0"
RESOURCE_ID = "seed-tts-2.0"        # 请根据实际情况修改！
URL = "https://openspeech.bytedance.com/api/v3/tts/unidirectional" # HTTP Chunked 接口

YAML_FILE = "operators.yaml"
OUTPUT_DIR = Path("voices")
THREADS = 8                         # 并发线程数

# =========================
# TTS 请求函数 (支持流式响应)
# =========================
def tts_request(text, speaker_id):
    """
    严格按照火山引擎文档处理 HTTP Chunked 流式响应
    """
    headers = {
        "X-Api-App-Id": APP_ID,
        "X-Api-Access-Key": ACCESS_TOKEN,
        "X-Api-Resource-Id": RESOURCE_ID,
        "X-Api-Request-Id": str(uuid.uuid4()),
        "Content-Type": "application/json"
    }

    payload = {
        "user": {"uid": "batch_script_user"},
        "req_params": {
            "text": text,
            "speaker": speaker_id,
            "audio_params": {
                "format": "mp3",
                "sample_rate": 24000
            }
        }
    }

    session = requests.Session()
    try:
        # 关键：启用 stream=True 以获取分块响应
        response = session.post(URL, headers=headers, json=payload, stream=True, timeout=30)
        response.raise_for_status()

        audio_parts = []
        # 逐行读取响应流（每个块通常为一行JSON）
        for line in response.iter_lines():
            if not line:
                continue
            try:
                chunk = json.loads(line)
            except json.JSONDecodeError as e:
                raise RuntimeError(f"解析响应行失败: {e}, 原始行: {line[:200]}")

            code = chunk.get("code")

            # 1. 提取音频数据（如果有）
            if "data" in chunk and chunk["data"]:
                audio_base64 = chunk["data"]
                audio_parts.append(base64.b64decode(audio_base64))

            # 2. 检查业务错误（code 不为 0 且不为 20000000 表示出错）
            if code is not None and code != 0 and code != 20000000:
                message = chunk.get("message", "未知错误")
                raise RuntimeError(f"合成业务错误 (Code: {code}): {message}")

            # 3. 遇到会话结束标志，停止读取
            if code == 20000000:
                break

        if not audio_parts:
            raise RuntimeError("未收到任何音频数据")

        return b''.join(audio_parts)

    except requests.exceptions.RequestException as e:
        raise RuntimeError(f"HTTP请求失败: {e}")
    finally:
        session.close()

# =========================
# 以下辅助函数与主程序保持不变
# =========================
def collect_dialogues(dialogues):
    lines = []
    for category, arr in dialogues.items():
        if isinstance(arr, list):
            for text in arr:
                lines.append((category, text))
    return lines

def generate_one(op_id, speaker_id, category, index, text):
    out_dir = OUTPUT_DIR / op_id
    out_dir.mkdir(parents=True, exist_ok=True)
    filename = f"{category}_{index:03d}.mp3"
    path = out_dir / filename

    if path.exists():
        return ("skip", path)

    for attempt in range(3):
        try:
            print(f"→ 正在生成: {op_id}/{filename} (尝试 {attempt+1}/3)")
            audio_data = tts_request(text, speaker_id)
            with open(path, "wb") as f:
                f.write(audio_data)
            return ("ok", path)
        except Exception as e:
            if attempt == 2:
                return ("error", f"[{op_id}] {filename} 生成失败: {str(e)}")

def main():
    print("--- 火山引擎 Seed-TTS 批量生成脚本 (流式修正版) ---")

    if not Path(YAML_FILE).exists():
        print(f"✘ 错误: 找不到配置文件 {YAML_FILE}")
        return

    with open(YAML_FILE, "r", encoding="utf-8") as f:
        config = yaml.safe_load(f)

    tasks = []
    manifest = {}

    for op in config.get("operators", []):
        op_id = op["id"]
        speaker_id = op["ssml_config"]  # 音色ID
        dialogues = op["dialogues"]

        lines = collect_dialogues(dialogues)
        print(f"读取角色: {op_id} | 音色: {speaker_id} | 台词数: {len(lines)}")

        manifest[op_id] = {}
        for i, (category, text) in enumerate(lines):
            tasks.append((op_id, speaker_id, category, i, text))
            manifest[op_id][f"{category}_{i:03d}"] = text

    print(f"\n开始任务并行处理 (线程数: {THREADS})...")
    ok, skip, err = 0, 0, 0

    with ThreadPoolExecutor(max_workers=THREADS) as pool:
        future_to_task = {
            pool.submit(generate_one, *task): task for task in tasks
        }
        for future in as_completed(future_to_task):
            status, info = future.result()
            if status == "ok":
                ok += 1
                print(f"✔ 已生成: {info.name}")
            elif status == "skip":
                skip += 1
                print(f"⏭ 已跳过: {info.name}")
            else:
                err += 1
                print(f"✘ {info}")

    manifest_file = OUTPUT_DIR / "voice_manifest.json"
    with open(manifest_file, "w", encoding="utf-8") as f:
        json.dump(manifest, f, ensure_ascii=False, indent=2)

    print("\n" + "="*40)
    print(f"任务完成!")
    print(f"成功: {ok}")
    print(f"跳过: {skip}")
    print(f"失败: {err}")
    print(f"Manifest 文件: {manifest_file}")
    print("="*40)

if __name__ == "__main__":
    main()