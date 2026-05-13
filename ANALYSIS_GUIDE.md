# Guia da analise em R

Este ficheiro explica o que os scripts em R calculam, que variaveis aparecem nos datasets e como interpretar as metricas principais.

## Objetivo da analise

A analise serve para perceber como o mercado de cada item se comporta ao longo do tempo.

O foco principal e:

- acompanhar a evolucao do preco de mercado;
- comparar precos entre itens;
- medir a volatilidade;
- identificar dias com movimentos fortes;
- observar eventos importantes, como anuncio/lancamento do CS2 ou updates relevantes;
- criar graficos simples e graficos com indicadores estatisticos.

## Variaveis originais

Os dados recolhidos da Steam chegam normalmente com estas colunas:

| Variavel | Significado |
| --- | --- |
| `date_raw` | Data original como veio da Steam. Pode incluir hora e formato textual. |
| `price_raw` | Preco original como texto. |
| `volume_raw` | Volume original como texto. Representa o numero de vendas/registos nesse ponto. |
| `item`, `case` ou `sticker` | Nome do ativo analisado. O nome da coluna muda conforme a pasta. |

## Variaveis tratadas

Depois da limpeza em R, os scripts criam variaveis mais faceis de usar:

| Variavel | Significado |
| --- | --- |
| `date` | Data convertida para formato de data em R. |
| `price` | Preco convertido para numero. |
| `volume` | Volume convertido para numero. |

Estas variaveis sao a base dos graficos simples: `date` no eixo X e `price` no eixo Y.

## Variaveis de retorno e volatilidade

Os scripts tambem calculam variaveis novas para estudar risco e instabilidade de preco:

| Variavel | Formula / criterio | Significado |
| --- | --- | --- |
| `log_return` | `log(price / lag(price))` | Retorno logaritmico entre uma observacao e a anterior. Mede a variacao relativa do preco. |
| `percent_return` | `log_return * 100` | Retorno em percentagem. |
| `absolute_return` | `abs(log_return)` | Tamanho do movimento, ignorando se foi subida ou descida. |
| `big_move` | `absolute_return >= 0.05` | Marca dias com movimento absoluto igual ou superior a 5%. |
| `rolling_average_14` | Media movel de 14 observacoes | Suaviza o preco para mostrar tendencia. |
| `rolling_volume_14` | Media movel de 14 observacoes do volume | Usada nos scripts que tambem analisam volume. |
| `rolling_volatility_30` | Desvio padrao movel dos retornos, anualizado | Mostra como a volatilidade muda ao longo do tempo. |

## Como a volatilidade e calculada

A volatilidade e baseada no desvio padrao dos retornos logaritmicos.

Formula principal:

```r
annualized_volatility_percent = sd(log_return, na.rm = TRUE) * sqrt(365) * 100
```

Interpretacao:

- `sd(log_return)` mede a dispersao diaria dos retornos.
- `sqrt(365)` transforma a volatilidade diaria numa estimativa anual.
- Usa-se `365` porque o Steam Market esta aberto todos os dias, incluindo fins de semana.
- `* 100` converte o resultado para percentagem.

Quanto maior for a volatilidade anualizada, mais instavel e o preco do item.

## Resumo estatistico

Cada script cria um ficheiro de resumo com metricas como:

| Variavel | Significado |
| --- | --- |
| `observations` | Numero de observacoes usadas na analise. |
| `average_price` | Preco medio, quando aplicavel. |
| `min_price` | Preco minimo observado. |
| `max_price` | Preco maximo observado. |
| `price_range_percent` | Diferenca percentual entre preco maximo e minimo. |
| `daily_return_sd_percent` | Desvio padrao dos retornos diarios em percentagem. |
| `annualized_volatility_percent` | Volatilidade anualizada. |
| `average_absolute_daily_move_percent` | Movimento diario medio em valor absoluto. |
| `days_with_moves_above_5_percent` | Numero de dias com movimentos iguais ou superiores a 5%. |
| `share_of_days_above_5_percent` | Percentagem de dias com movimentos fortes. |
| `biggest_daily_gain_percent` | Maior subida diaria. |
| `biggest_daily_loss_percent` | Maior queda diaria. |

## Como interpretar a volatilidade

Um item mostra sinais de volatilidade quando:

- tem `annualized_volatility_percent` alta;
- apresenta muitos dias com `big_move = TRUE`;
- tem grande diferenca entre `min_price` e `max_price`;
- a linha de `rolling_volatility_30` sobe em determinados periodos;
- os graficos mostram saltos bruscos de preco.

Exemplo de interpretacao:

> Se uma skin tem muitos dias com movimentos acima de 5% e uma volatilidade anualizada elevada, isso sugere que o seu preco nao evolui de forma estavel. O mercado desse item tem maior risco e maior incerteza.

## Graficos gerados

Os scripts R criam dois tipos principais de graficos:

| Tipo | Localizacao | Objetivo |
| --- | --- | --- |
| Graficos basicos | `graphs/basic` | Mostrar apenas preco de mercado ao longo do tempo. |
| Graficos completos | `graphs` | Mostrar preco, media movel, movimentos grandes e eventos. |
| Graficos de volatilidade | `graphs` | Mostrar a volatilidade movel de 30 observacoes. |

## Eventos marcados

Alguns graficos incluem linhas verticais para eventos importantes:

- `CS2 Announcement`: 2023-03-22.
- `CS2 Release`: 2023-09-27.
- `Trade-Up Update`: 2025-10-23, usado especialmente nas Paracord knives.

Estas linhas ajudam a comparar movimentos de preco com acontecimentos que podem ter influenciado o mercado.

## Ficheiros de output

Cada pasta guarda outputs parecidos:

| Output | Significado |
| --- | --- |
| `*_volatility_dataset.csv` | Dataset tratado com retornos, movimentos e volatilidade. |
| `*_volatility_summary.csv` | Resumo estatistico da analise. |
| `*_volatility_test.txt` | Texto curto com conclusao sobre volatilidade, quando aplicavel. |
| `graphs/*.png` | Graficos principais da analise. |
| `graphs/basic/*.png` | Graficos simples de preco e data. |

## Conclusao esperada

A analise permite defender que existe volatilidade no mercado das skins quando os resultados mostram movimentos frequentes, amplitudes grandes entre minimo e maximo, e volatilidade anualizada elevada.

No caso da Desert Eagle Blaze em 2024, o teste extra foi criado para mostrar isso de forma direta, usando retornos, movimentos acima de 5% e volatilidade anualizada.

