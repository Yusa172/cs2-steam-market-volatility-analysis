from __future__ import annotations

import json
import time
from pathlib import Path
from urllib.parse import quote

import pandas as pd
from selenium import webdriver
from selenium.webdriver.chrome.service import Service
from webdriver_manager.chrome import ChromeDriverManager


APP_ID = 730
OUTPUT_FILE = "steam_price_history_example.csv"

# Escreve aqui os nomes exatamente como aparecem no Steam Market.
ITEMS = [
    "AK-47 | Redline (Field-Tested)",
    "Desert Eagle | Blaze (Factory New)",
]


def create_driver() -> webdriver.Chrome:
    options = webdriver.ChromeOptions()
    options.add_argument("--start-maximized")

    return webdriver.Chrome(
        service=Service(ChromeDriverManager().install()),
        options=options,
    )


def build_price_history_url(item_name: str) -> str:
    encoded_name = quote(item_name)
    return (
        "https://steamcommunity.com/market/pricehistory/"
        f"?appid={APP_ID}&market_hash_name={encoded_name}"
    )


def get_price_history(driver: webdriver.Chrome, item_name: str) -> list:
    url = build_price_history_url(item_name)

    driver.get(url)
    time.sleep(3)

    body_text = driver.find_element("tag name", "body").text
    data = json.loads(body_text)

    if not isinstance(data, dict):
        raise ValueError("Resposta da Steam invalida")

    prices = data.get("prices", [])
    if not isinstance(prices, list) or len(prices) == 0:
        raise ValueError("Sem historico de precos")

    return prices


def price_history_to_dataframe(item_name: str, prices: list) -> pd.DataFrame:
    df = pd.DataFrame(prices).iloc[:, :3]
    df.columns = ["date", "price", "volume"]

    df["item"] = item_name
    df["steam_url"] = build_price_history_url(item_name)

    return df


def main() -> None:
    script_dir = Path(__file__).resolve().parent
    output_path = script_dir / OUTPUT_FILE
    all_data = []

    driver = create_driver()

    try:
        driver.get("https://steamcommunity.com/market/")
        input("Faz login na Steam e pressiona ENTER para continuar...")

        for item_name in ITEMS:
            print(f"A recolher dados: {item_name}")

            try:
                prices = get_price_history(driver, item_name)
                item_df = price_history_to_dataframe(item_name, prices)
                all_data.append(item_df)

                print(f"Dados recolhidos: {item_name}")

            except Exception as error:
                print(f"Erro em {item_name}: {error}")

    finally:
        driver.quit()

    if len(all_data) == 0:
        print("Nenhum dado foi recolhido.")
        return

    final_df = pd.concat(all_data, ignore_index=True)
    final_df.to_csv(output_path, index=False, encoding="utf-8-sig")

    print("Dataset criado com sucesso.")
    print(f"Guardado em: {output_path}")


if __name__ == "__main__":
    main()
