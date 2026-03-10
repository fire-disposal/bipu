#!/usr/bin/env python3
"""
Bipupu 接线员语音资源生成工具
=====================================
使用 Microsoft Edge TTS（免费，无需 API Key）批量生成全套接线员预录制台词音频。

用法:
  python generate_voices.py                        # 生成全部（跳过已存在文件）
  python generate_voices.py --force                # 强制重新生成（覆盖已存在文件）
  python generate_voices.py --op op_001            # 只生成指定接线员
  python generate_voices.py --op op_001 op_003     # 生成多个接线员
  python generate_voices.py --dry-run              # 预览任务，不实际生成
  python generate_voices.py --list-voices          # 列出所有可用中文语音
  python generate_voices.py --config my.yaml       # 使用指定配置文件

依赖安装:
  pip install edge-tts aiofiles tqdm pyyaml

输出结构:
  mobile/assets/voices/
    manifest.json          ← 文本→文件路径映射（Dart 端加载）
    op_001/
      greeting_0.mp3
      greeting_1.mp3
      ask_target_0.mp3
      ...
    op_002/
      ...
"""

import argparse
import asyncio
import hashlib
import json
import os
import sys
import time
from pathlib import Path
from typing import Any

import yaml

try:
    import edge_tts
    from edge_tts import list_voices
except ImportError:
    print("❌ 缺少 edge-tts，请先运行：pip install edge-tts aiofiles tqdm pyyaml")
    sys.exit(1)

try:
    from tqdm.asyncio import tqdm as async_tqdm
    import tqdm as tqdm_module
except ImportError:
    print("❌ 缺少 tqdm，请先运行：pip install tqdm")
    sys.exit(1)

# ─────────────────────────────────────────────────────────────────────────────
# 常量
# ─────────────────────────────────────────────────────────────────────────────

SCRIPT_DIR = Path(__file__).parent
DEFAULT_CONFIG = SCRIPT_DIR / "voices_config.yaml"

# confirmId 等含占位符的行，不做预录制
DYNAMIC_LINE_KEYS = {"confirm_id", "verify"}

# 并发上限（edge-tts 有速率限制，建议 3~5）
MAX_CONCURRENCY = 4

# 单次请求失败最大重试次数
MAX_RETRIES = 3
RETRY_DELAY = 2.0  # 秒


# ─────────────────────────────────────────────────────────────────────────────
# 工具函数
# ─────────────────────────────────────────────────────────────────────────────

def text_md5(text: str) -> str:
    """取文本 MD5 前 8 位（用于日志去重，不用于索引）"""
    return hashlib.md5(text.encode("utf-8")).hexdigest()[:8]


def is_dynamic(text: str) -> bool:
    """判断台词是否含动态占位符（不可预录）"""
    return "%s" in text or "{" in text


def slugify_line_key(raw_key: str) -> str:
    """将 YAML key 转为文件名友好格式（已是下划线格式，保持不变）"""
    return raw_key.strip().replace(" ", "_").lower()


# ─────────────────────────────────────────────────────────────────────────────
# 核心生成逻辑
# ─────────────────────────────────────────────────────────────────────────────

async def generate_one(
    text: str,
    voice: str,
    rate: str,
    pitch: str,
    volume: str,
    output_path: Path,
    semaphore: asyncio.Semaphore,
    dry_run: bool = False,
) -> bool:
    """生成单条台词音频，返回是否成功"""
    if dry_run:
        print(f"  [DRY-RUN] {output_path.name}  ← \"{text[:40]}{'...' if len(text) > 40 else ''}\"")
        return True

    output_path.parent.mkdir(parents=True, exist_ok=True)

    async with semaphore:
        for attempt in range(1, MAX_RETRIES + 1):
            try:
                communicate = edge_tts.Communicate(
                    text=text,
                    voice=voice,
                    rate=rate,
                    pitch=pitch,
                    volume=volume,
                )
                await communicate.save(str(output_path))
                return True
            except Exception as e:
                if attempt < MAX_RETRIES:
                    await asyncio.sleep(RETRY_DELAY * attempt)
                else:
                    print(f"\n  ⚠️  生成失败（已重试 {MAX_RETRIES} 次）: {output_path.name}\n     {e}")
                    return False
    return False


async def generate_operator(
    op_id: str,
    op_cfg: dict[str, Any],
    output_base: Path,
    semaphore: asyncio.Semaphore,
    force: bool = False,
    dry_run: bool = False,
) -> dict[str, str]:
    """
    生成一个接线员的所有台词音频。

    返回 manifest 条目：{text: relative_path}
    """
    voice   = op_cfg["edge_tts_voice"]
    rate    = op_cfg.get("rate", "+0%")
    pitch   = op_cfg.get("pitch", "+0Hz")
    volume  = op_cfg.get("volume", "+0%")
    dialogues: dict[str, list[str]] = op_cfg.get("dialogues", {})

    op_dir = output_base / op_id
    manifest_entries: dict[str, str] = {}

    # 收集所有待生成任务
    tasks = []
    for line_key, variants in dialogues.items():
        if line_key in DYNAMIC_LINE_KEYS:
            continue  # 动态台词，跳过

        for idx, text in enumerate(variants):
            if is_dynamic(text):
                print(f"  ⚠️  [{op_id}] {line_key}[{idx}] 含占位符，跳过: \"{text[:30]}...\"")
                continue

            filename = f"{slugify_line_key(line_key)}_{idx}.mp3"
            rel_path = f"{op_id}/{filename}"
            out_path = op_dir / filename
            manifest_entries[text] = rel_path

            # 已存在且不强制重新生成，跳过
            if not force and out_path.exists() and out_path.stat().st_size > 0:
                continue

            tasks.append((text, voice, rate, pitch, volume, out_path))

    if not tasks:
        print(f"  ✓  [{op_id}] 全部文件已存在，跳过（使用 --force 强制重新生成）")
        return manifest_entries

    print(f"\n  🎙  [{op_id}] {op_cfg['name']}  |  voice={voice}  rate={rate}  pitch={pitch}")
    print(f"      待生成：{len(tasks)} 条  |  已跳过：{len(manifest_entries) - len(tasks)} 条")

    # 并发生成
    coros = [
        generate_one(text, voice, rate, pitch, volume, out_path, semaphore, dry_run)
        for text, voice, rate, pitch, volume, out_path in tasks
    ]

    results = []
    for coro in async_tqdm(
        asyncio.as_completed(coros),
        total=len(coros),
        desc=f"  {op_id}",
        unit="条",
        leave=False,
    ):
        result = await coro
        results.append(result)

    success = sum(results)
    failed  = len(results) - success
    print(f"  ✅  [{op_id}] 完成：{success} 成功  {failed} 失败")
    return manifest_entries


async def run(
    config_path: Path,
    output_dir: Path | None,
    ops_filter: list[str] | None,
    force: bool,
    dry_run: bool,
) -> None:
    """主流程"""
    # 读取配置
    with open(config_path, encoding="utf-8") as f:
        cfg = yaml.safe_load(f)

    # 输出目录：命令行参数 > 配置文件 > 默认
    if output_dir is None:
        raw_dir = cfg.get("output_dir", "../mobile/assets/voices")
        output_dir = (config_path.parent / raw_dir).resolve()

    print(f"\n{'='*60}")
    print(f"  Bipupu 语音资源生成器")
    print(f"  配置文件：{config_path}")
    print(f"  输出目录：{output_dir}")
    print(f"  模式：{'DRY-RUN（预览）' if dry_run else '生成'} | force={force}")
    print(f"{'='*60}\n")

    operators: dict[str, dict] = cfg["operators"]
    if ops_filter:
        operators = {k: v for k, v in operators.items() if k in ops_filter}
        if not operators:
            print(f"⚠️  未找到指定接线员：{ops_filter}")
            return

    semaphore = asyncio.Semaphore(MAX_CONCURRENCY)
    all_manifest: dict[str, str] = {}

    t_start = time.monotonic()

    for op_id, op_cfg in operators.items():
        entries = await generate_operator(
            op_id, op_cfg, output_dir, semaphore, force, dry_run
        )
        all_manifest.update(entries)

    # 写入 manifest.json
    manifest = {
        "version": 1,
        "generated_at": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
        "total": len(all_manifest),
        "by_text": all_manifest,
    }
    manifest_path = output_dir / "manifest.json"

    if not dry_run:
        output_dir.mkdir(parents=True, exist_ok=True)
        with open(manifest_path, "w", encoding="utf-8") as f:
            json.dump(manifest, f, ensure_ascii=False, indent=2)
        print(f"\n  📄  manifest.json 已写入：{manifest_path}")
        print(f"      收录台词：{len(all_manifest)} 条")
    else:
        print(f"\n  [DRY-RUN] 将写入 manifest.json，收录 {len(all_manifest)} 条台词")

    elapsed = time.monotonic() - t_start
    print(f"\n{'='*60}")
    print(f"  ✅  完成！耗时 {elapsed:.1f}s")
    print(f"{'='*60}\n")


# ─────────────────────────────────────────────────────────────────────────────
# 列出可用中文语音
# ─────────────────────────────────────────────────────────────────────────────

async def list_zh_voices() -> None:
    voices = await list_voices()
    zh_voices = [v for v in voices if v["Locale"].startswith("zh-")]
    print(f"\n可用中文语音（共 {len(zh_voices)} 个）：\n")
    print(f"  {'语音名称':<40} {'性别':<8} {'区域':<12} {'说明'}")
    print(f"  {'-'*80}")
    for v in sorted(zh_voices, key=lambda x: x["ShortName"]):
        name    = v["ShortName"]
        gender  = v.get("Gender", "")
        locale  = v.get("Locale", "")
        desc    = v.get("FriendlyName", "")
        print(f"  {name:<40} {gender:<8} {locale:<12} {desc}")
    print()


# ─────────────────────────────────────────────────────────────────────────────
# 入口
# ─────────────────────────────────────────────────────────────────────────────

def main() -> None:
    parser = argparse.ArgumentParser(
        description="Bipupu 接线员语音资源生成工具",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=__doc__,
    )
    parser.add_argument(
        "--config", "-c",
        type=Path,
        default=DEFAULT_CONFIG,
        help=f"配置文件路径（默认：{DEFAULT_CONFIG}）",
    )
    parser.add_argument(
        "--output", "-o",
        type=Path,
        default=None,
        help="输出目录（覆盖配置文件中的 output_dir）",
    )
    parser.add_argument(
        "--op",
        nargs="+",
        metavar="OP_ID",
        help="只生成指定接线员（如 op_001 op_003）",
    )
    parser.add_argument(
        "--force",
        action="store_true",
        help="强制重新生成（覆盖已存在文件）",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="预览任务清单，不实际生成文件",
    )
    parser.add_argument(
        "--list-voices",
        action="store_true",
        help="列出所有可用中文语音后退出",
    )
    parser.add_argument(
        "--concurrency",
        type=int,
        default=MAX_CONCURRENCY,
        help=f"并发数（默认：{MAX_CONCURRENCY}）",
    )

    args = parser.parse_args()

    # 动态修改并发数
    global MAX_CONCURRENCY
    MAX_CONCURRENCY = args.concurrency

    if args.list_voices:
        asyncio.run(list_zh_voices())
        return

    if not args.config.exists():
        print(f"❌ 配置文件不存在：{args.config}")
        sys.exit(1)

    asyncio.run(run(
        config_path=args.config,
        output_dir=args.output,
        ops_filter=args.op,
        force=args.force,
        dry_run=args.dry_run,
    ))


if __name__ == "__main__":
    main()
