# CS2 Steam Market Volatility Analysis

Projeto para recolher historico de precos do Steam Market e analisar preco, volume e volatilidade de skins, cases, knives e stickers de CS2/CS:GO.

Nome recomendado para o repositorio: `cs2-steam-market-volatility-analysis`.

## Estrutura

- `weapon_cases`: datasets, analise R e graficos de weapon cases.
- `galil_ar_chatterbox`: dataset, analise R e graficos da Galil AR | Chatterbox.
- `desert_eagle_blaze`: dataset, analise R e graficos da Desert Eagle | Blaze.
- `paracord_knives`: datasets, analise R e graficos de Paracord knives.
- `major_stickers`: datasets, analise R e graficos de stickers de Majors.
- `generate_all_datasets.py`: script principal para gerar todos os datasets.
- `for-links.py`: exemplo simples e didatico para recolher historico de precos da Steam.
- `ANALYSIS_GUIDE.md`: explicacao das variaveis, metricas e interpretacao da volatilidade.

## Python

Instalar dependencias:

```powershell
py -m pip install -r requirements.txt
```

Gerar todos os datasets:

```powershell
py generate_all_datasets.py
```

Executar o exemplo simples da Steam:

```powershell
py for-links.py
```

O `for-links.py` e o ficheiro mais importante para quem quer aprender a ir buscar precos ao Steam Market. Ele mostra o fluxo base:

1. abrir o Steam Market com Selenium;
2. fazer login manual;
3. construir o link `pricehistory` com `appid=730` e `market_hash_name`;
4. ler o JSON devolvido pela Steam;
5. transformar os dados em CSV com `date`, `price`, `volume`, `item` e `steam_url`.

Endpoint usado no exemplo:

```text
https://steamcommunity.com/market/pricehistory/?appid=730&market_hash_name=ITEM_NAME
```

## R

Pacotes necessarios:

```r
install.packages(c("tidyverse", "lubridate", "readr"))
```

Scripts de analise:

- `weapon_cases/analyze_weapon_cases.R`
- `galil_ar_chatterbox/analyze_galil_ar_chatterbox.R`
- `desert_eagle_blaze/analyze_desert_eagle_blaze.R`
- `paracord_knives/analyze_paracord_knives.R`
- `major_stickers/analyze_major_stickers.R`

Cada script R limpa os dados, calcula retornos, volatilidade e metricas de risco, e guarda:

- dataset tratado com metricas de volatilidade;
- resumo estatistico;
- graficos melhorados;
- graficos basicos apenas com `date` e `price`.

## Analise

O guia principal da analise esta em `ANALYSIS_GUIDE.md`.

Pontos principais:

- A volatilidade e calculada a partir dos retornos logaritmicos dos precos.
- A anualizacao usa `sqrt(365)`, porque o Steam Market funciona todos os dias e nao apenas em dias uteis.
- Um movimento grande e marcado quando a variacao absoluta diaria e igual ou superior a 5%.
- Os graficos com volatilidade ajudam a mostrar se o preco das skins muda de forma instavel ao longo do tempo.
- Economicamente, a volatilidade e usada como medida de risco e incerteza do preco.
- A analise permite relacionar movimentos de preco com liquidez, especulacao, procura/oferta e eventos do jogo.

## Fontes usadas

- [The Motley Fool - How to Calculate Annualized Volatility](https://www.fool.com/investing/how-to-calculate/annualized-volatility/)
- [Loris Tools - Historical Volatility Calculator](https://loris.tools/tools/volatility-calculator)

Current weapon cases included: Operation Breakout Weapon Case, Chroma Case and Revolver Case.
