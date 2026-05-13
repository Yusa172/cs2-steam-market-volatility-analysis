from __future__ import annotations

import json
import time
from pathlib import Path
from typing import Iterable
from urllib.parse import quote

import pandas as pd
from selenium import webdriver
from selenium.webdriver.chrome.service import Service
from webdriver_manager.chrome import ChromeDriverManager


ROOT_DIR = Path(__file__).resolve().parent

DATASETS = [
    {
        "name": "Weapon Cases",
        "folder": "weapon_cases",
        "csv_name": "cases_dataset.csv",
        "item_column": "case",
        "items": [
            "Operation Breakout Weapon Case",
            "Chroma Case",
            "Revolver Case",
        ],
    },
    {
        "name": "Galil AR Chatterbox",
        "folder": "galil_ar_chatterbox",
        "csv_name": "chatterbox_dataset.csv",
        "item_column": "item",
        "items": [
            "Galil AR | Chatterbox (Field-Tested)",
        ],
    },
    {
        "name": "Desert Eagle Blaze",
        "folder": "desert_eagle_blaze",
        "csv_name": "deagle_blaze_dataset.csv",
        "item_column": "item",
        "items": [
            "Desert Eagle | Blaze (Factory New)",
        ],
    },
    {
        "name": "Paracord Knife",
        "folder": "paracord_knives",
        "csv_name": "paracord_dataset.csv",
        "item_column": "item",
        "items": [
            "\u2605 Paracord Knife | Fade (Factory New)",
            "\u2605 Paracord Knife | Slaughter (Factory New)",
            "\u2605 Paracord Knife | Crimson Web (Minimal Wear)",
            "\u2605 Paracord Knife | Case Hardened (Factory New)",
        ],
    },
    {
        "name": "Major Stickers",
        "folder": "major_stickers",
        "csv_name": "major_stickers_dataset.csv",
        "item_column": "sticker",
        "items": [
            "Sticker | FaZe Clan | Antwerp 2022",
            "Sticker | Cloud9 | Boston 2018",
            "Sticker | Natus Vincere | Stockholm 2021",
            "Sticker | iBUYPOWER | Katowice 2014",
        ],
    },
]


def build_driver() -> webdriver.Chrome:
    options = webdriver.ChromeOptions()
    options.add_argument("--start-maximized")

    return webdriver.Chrome(
        service=Service(ChromeDriverManager().install()),
        options=options,
    )


def fetch_prices(driver: webdriver.Chrome, item_name: str, delay_seconds: int = 3) -> list:
    encoded_name = quote(item_name)
    url = (
        "https://steamcommunity.com/market/pricehistory/"
        f"?appid=730&market_hash_name={encoded_name}"
    )

    driver.get(url)
    time.sleep(delay_seconds)

    body_text = driver.find_element("tag name", "body").text
    data = json.loads(body_text)

    if not isinstance(data, dict):
        raise ValueError("JSON invalido")

    prices = data.get("prices", [])
    if not isinstance(prices, list) or len(prices) == 0:
        raise ValueError("Sem dados")

    return prices


def prices_to_dataframe(prices: Iterable, label_column: str, label_value: str) -> pd.DataFrame:
    df = pd.DataFrame(prices).iloc[:, :3]
    df.columns = ["date", "price", "volume"]
    df[label_column] = label_value
    return df


def save_dataset(dataset: dict, frames: list[pd.DataFrame]) -> None:
    if len(frames) == 0:
        print(f"\n{dataset['name']}: nenhum dado recolhido.")
        return

    output_folder = ROOT_DIR / dataset["folder"]
    output_folder.mkdir(parents=True, exist_ok=True)

    output_path = output_folder / dataset["csv_name"]
    final_df = pd.concat(frames, ignore_index=True)
    final_df.to_csv(output_path, index=False, encoding="utf-8-sig")

    print(f"\n{dataset['name']}: dataset criado com sucesso")
    print(f"Guardado em: {output_path}")


def main() -> None:
    driver = build_driver()

    try:
        driver.get("https://steamcommunity.com/market/")
        input("Faz login na Steam e pressiona ENTER para criar todos os datasets...")

        for dataset in DATASETS:
            print(f"\n===== {dataset['name']} =====")
            frames = []

            for item_name in dataset["items"]:
                print(f"\nA analisar: {item_name}")

                try:
                    prices = fetch_prices(driver, item_name)
                    frame = prices_to_dataframe(
                        prices,
                        dataset["item_column"],
                        item_name,
                    )
                    frames.append(frame)
                    print(f"Dados recolhidos: {item_name}")

                except Exception as exc:
                    print(f"Erro ao recolher {item_name}: {exc}")

            save_dataset(dataset, frames)

    finally:
        driver.quit()


if __name__ == "__main__":
    main()
