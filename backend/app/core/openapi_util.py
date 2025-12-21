import os
import json
from fastapi import FastAPI
from typing import Optional

def export_openapi_json(app: FastAPI, output_path: Optional[str] = None) -> str:
    """
    导出 FastAPI OpenAPI schema 到指定路径，兼容多系统。
    :param app: FastAPI 实例
    :param output_path: 保存路径，默认 'openapi.json'，自动创建目录
    :return: 实际保存的文件路径
    """
    schema = app.openapi()
    if output_path is None:
        output_path = os.path.join(os.getcwd(), "openapi.json")
    else:
        output_path = os.path.abspath(output_path)
        os.makedirs(os.path.dirname(output_path), exist_ok=True)
    with open(output_path, "w", encoding="utf-8") as f:
        json.dump(schema, f, ensure_ascii=False, indent=2)
    return output_path