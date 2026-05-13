# CS2/CS:GO Skins Analysis and Market

Project for collecting Steam Market price history and analysing price, volume and volatility for selected CS2/CS:GO skins, knives, stickers and cases.

## Structure

- `weapon_cases`: datasets, volatility outputs and graphs for weapon cases.
- `galil_ar_chatterbox`: dataset, volatility outputs and graphs for Galil AR | Chatterbox.
- `desert_eagle_blaze`: dataset, volatility outputs and graphs for Desert Eagle | Blaze.
- `paracord_knives`: datasets, volatility outputs and graphs for Paracord knives.
- `major_stickers`: datasets, volatility outputs and graphs for Major stickers.
- `generate_all_datasets.py`: main Python script that generates all datasets.
- `for-links.py`: simplified Steam Market scraping example for future work.

## Python setup

```powershell
py -m pip install -r requirements.txt
```

Run all dataset collectors:

```powershell
py generate_all_datasets.py
```

Run the simple Steam Market example:

```powershell
py for-links.py
```

## R analysis

- `weapon_cases/analyze_weapon_cases.R`
- `galil_ar_chatterbox/analyze_galil_ar_chatterbox.R`
- `desert_eagle_blaze/analyze_desert_eagle_blaze.R`
- `paracord_knives/analyze_paracord_knives.R`
- `major_stickers/analyze_major_stickers.R`

Each R script exports improved graphs to its `graphs` folder and creates volatility summary files next to the dataset.

Basic market-price-only charts are saved in each `graphs/basic` folder. Event lines are included where relevant, including CS2 events and the Paracord Knife Trade-Up Update on 2025-10-23.

Current weapon cases included: Operation Breakout Weapon Case, Chroma Case and Revolver Case.
