# app/logic.py
import asyncio
import base64
import json
import logging
import re
import subprocess
import urllib.parse
from pathlib import Path
from typing import List, Dict, Any
import httpx
import sys
from bs4 import BeautifulSoup
import importlib.util
try:
    from sub_checker import cl
    SUB_CHECKER_AVAILABLE = True
    logging.info("Successfully imported 'sub_checker' module.")
except ImportError:
    logging.warning("Could not import 'sub_checker'. Checker functionality will be disabled in local dev mode.")
    SUB_CHECKER_AVAILABLE = False
    cl = None

PROJECT_ROOT = Path(__file__).parent.parent.resolve()
SUB_CHECKER_DIR = PROJECT_ROOT / "sub_checker"
INPUT_FILE = SUB_CHECKER_DIR / "normal.txt"
OUTPUT_FILE = SUB_CHECKER_DIR / "final.txt"
CL_SCRIPT = SUB_CHECKER_DIR / "cl.py"

logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')



async def scrape_configs_from_url(url: str, client: httpx.AsyncClient) -> List[str]:
    if "t.me/" in url and "/s/" not in url:
        url = url.replace("t.me/", "t.me/s/")
    try:
        response = await client.get(url, timeout=30, follow_redirects=True)
        response.raise_for_status()
    except httpx.RequestError as e:
        logging.error(f"Failed to fetch {url}: {e}")
        return []
    soup = BeautifulSoup(response.text, 'html.parser')
    page_text = soup.get_text('\n')
    pattern = r'((?:vmess|vless|ss|trojan|hy2|hysteria2)://[^\s<>"\'`]+)'
    found_configs = re.findall(pattern, page_text)
    logging.info(f"Found {len(found_configs)} configs from {url}")
    return found_configs

async def run_sub_checker(configs_to_check: List[str], options: Dict[str, Any]) -> List[str]:

    if not SUB_CHECKER_AVAILABLE:
        raise RuntimeError("Checker module is not available. This should not happen in a production build.")

    try:
        INPUT_FILE.write_text('\n'.join(configs_to_check), encoding='utf-8')
    except IOError as e:
        logging.error(f"Could not write to input file: {e}")
        raise

    check_location = options.get('get_location', False)
    check_iran = False

    logging.info(f"Directly calling checker function with options: location={check_location}")

    try:
        await asyncio.to_thread(cl.main, check_location, check_iran)

        if OUTPUT_FILE.exists():
            final_configs = OUTPUT_FILE.read_text('utf-8').splitlines()
            return [line for line in final_configs if line.strip()]
        else:
            return []

    except Exception as e:
        logging.error(f"An unexpected error occurred within the checker module: {e}", exc_info=True)
        raise RuntimeError("The checker module failed unexpectedly.")

async def run_main_process(urls: List[str], options: Dict[str, Any]) -> List[str]:
    async with httpx.AsyncClient() as client:
        tasks = [scrape_configs_from_url(url, client) for url in urls]
        scraped_results = await asyncio.gather(*tasks)
    all_raw_configs = []
    for result_list in scraped_results:
        all_raw_configs.extend(result_list)
    unique_configs = sorted(list(set(all_raw_configs)))
    logging.info(f"Total unique configs scraped: {len(unique_configs)}")
    if not unique_configs:
        logging.warning("No configs were scraped. Nothing to check.")
        return []
    final_working_configs = await run_sub_checker(unique_configs, options)
    return final_working_configs