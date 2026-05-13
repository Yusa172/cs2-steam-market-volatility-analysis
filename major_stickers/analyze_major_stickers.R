library(readr)
library(tidyverse)
library(lubridate)

args <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("^--file=", args, value = TRUE)
script_dir <- if(length(file_arg) > 0){
  dirname(normalizePath(sub("^--file=", "", file_arg[1])))
} else {
  getwd()
}
if(!file.exists(file.path(script_dir, "major_stickers_dataset.csv"))){
  script_dir <- file.path(getwd(), "major_stickers")
}

cat("==== Major Stickers Analysis ====\n")

graphs_folder <- file.path(script_dir, "graphs")
if(!dir.exists(graphs_folder)){
  dir.create(graphs_folder, recursive = TRUE)
}
basic_graphs_folder <- file.path(graphs_folder, "basic")
if(!dir.exists(basic_graphs_folder)){
  dir.create(basic_graphs_folder, recursive = TRUE)
}

clean_file_name <- function(value){
  value %>%
    str_replace_all("\\|", "") %>%
    str_replace_all("/", "_") %>%
    str_replace_all("\\s+", "_")
}

rolling_sd <- function(values, window = 30){
  sapply(
    seq_along(values),
    function(i){
      start_index <- max(1, i - window + 1)
      temp <- values[start_index:i]
      if(sum(!is.na(temp)) < 5){
        return(NA_real_)
      }
      sd(temp, na.rm = TRUE) * sqrt(365) * 100
    }
  )
}

event_for_sticker <- function(sticker_name){
  if(str_detect(sticker_name, "Antwerp 2022")){
    return(data.frame(event = "Antwerp 2022", event_date = as.Date("2022-05-09")))
  }
  if(str_detect(sticker_name, "Stockholm 2021")){
    return(data.frame(event = "Stockholm 2021", event_date = as.Date("2021-10-26")))
  }
  if(str_detect(sticker_name, "Boston 2018")){
    return(data.frame(event = "Boston 2018", event_date = as.Date("2018-01-12")))
  }
  if(str_detect(sticker_name, "Katowice 2014")){
    return(data.frame(event = "Katowice 2014", event_date = as.Date("2014-03-13")))
  }
  data.frame(event = character(), event_date = as.Date(character()))
}

data <- read_csv(file.path(script_dir, "major_stickers_dataset.csv"))
colnames(data)[1:3] <- c("date_raw", "price_raw", "volume_raw")

data <- data %>%
  mutate(
    date = str_extract(date_raw, "[A-Za-z]{3} \\d{1,2} \\d{4}"),
    date = as.Date(date, format = "%b %d %Y"),
    price = as.numeric(str_replace(as.character(price_raw), ",", ".")),
    volume = as.numeric(str_replace_all(as.character(volume_raw), ",", ""))
  ) %>%
  drop_na(date, price) %>%
  arrange(sticker, date) %>%
  group_by(sticker) %>%
  mutate(
    log_return = log(price / lag(price)),
    percent_return = log_return * 100,
    absolute_return = abs(log_return),
    big_move = absolute_return >= 0.05,
    rolling_average_14 = as.numeric(stats::filter(price, rep(1 / 14, 14), sides = 1)),
    rolling_volatility_30 = rolling_sd(log_return)
  ) %>%
  ungroup()

summary_data <- data %>%
  group_by(sticker) %>%
  summarise(
    observations = n(),
    min_price = min(price, na.rm = TRUE),
    max_price = max(price, na.rm = TRUE),
    price_range_percent = ((max_price / min_price) - 1) * 100,
    daily_return_sd_percent = sd(percent_return, na.rm = TRUE),
    annualized_volatility_percent = sd(log_return, na.rm = TRUE) * sqrt(365) * 100,
    average_absolute_daily_move_percent = mean(abs(percent_return), na.rm = TRUE),
    days_with_moves_above_5_percent = sum(big_move, na.rm = TRUE),
    share_of_days_above_5_percent = mean(big_move, na.rm = TRUE) * 100,
    biggest_daily_gain_percent = max(percent_return, na.rm = TRUE),
    biggest_daily_loss_percent = min(percent_return, na.rm = TRUE),
    .groups = "drop"
  )

write_csv(data, file.path(script_dir, "major_stickers_volatility_dataset.csv"))
write_csv(summary_data, file.path(script_dir, "major_stickers_volatility_summary.csv"))

for(sticker_name in unique(data$sticker)){
  temp_data <- data %>% filter(sticker == sticker_name)
  sticker_summary <- summary_data %>% filter(sticker == sticker_name)
  events <- event_for_sticker(sticker_name)

  if(sticker_name == "Sticker | FaZe Clan | Antwerp 2022"){
    events <- bind_rows(
      events,
      data.frame(event = c("ESL Pro League S17", "IEM Sydney 2023"), event_date = as.Date(c("2023-03-26", "2023-10-22")))
    )
  }

  basic_plot <- ggplot(temp_data, aes(x = date, y = price)) +
    geom_line(linewidth = 0.9, color = "#0f766e") +
    geom_vline(data = events, aes(xintercept = event_date), color = "#334155", linetype = "dashed", linewidth = 0.8) +
    geom_text(data = events, aes(x = event_date, y = max(temp_data$price, na.rm = TRUE) * 0.96, label = event), angle = 90, size = 3, hjust = 1) +
    labs(
      title = paste(sticker_name, "- Market Price"),
      x = "Date",
      y = "Market price"
    ) +
    theme_minimal(base_size = 13) +
    theme(plot.title = element_text(face = "bold", size = 18), panel.grid.minor = element_blank())

  ggsave(file.path(basic_graphs_folder, paste0(clean_file_name(sticker_name), "_basic_price.png")), basic_plot, width = 13, height = 7, dpi = 160)

  price_plot <- ggplot(temp_data, aes(x = date)) +
    annotate("rect", xmin = min(temp_data$date), xmax = max(temp_data$date), ymin = min(temp_data$price), ymax = max(temp_data$price), fill = "#dbeafe", alpha = 0.35) +
    geom_line(aes(y = price, color = "Market price"), linewidth = 1) +
    geom_line(aes(y = rolling_average_14, color = "14 observation average"), linewidth = 0.9, na.rm = TRUE) +
    geom_point(data = temp_data %>% filter(big_move), aes(y = price, color = "Absolute move >= 5%"), size = 2.1) +
    geom_vline(data = events, aes(xintercept = event_date), color = "#334155", linetype = "dashed", linewidth = 0.8) +
    geom_text(data = events, aes(x = event_date, y = max(temp_data$price, na.rm = TRUE) * 0.96, label = event), angle = 90, size = 3, hjust = 1) +
    scale_color_manual(values = c("Market price" = "#0f766e", "14 observation average" = "#f97316", "Absolute move >= 5%" = "#dc2626")) +
    labs(
      title = paste(sticker_name, "- Price Volatility"),
      subtitle = paste0("Annualized volatility: ", round(sticker_summary$annualized_volatility_percent, 1), "% | Days above 5% move: ", sticker_summary$days_with_moves_above_5_percent, " | Price range: ", round(sticker_summary$price_range_percent, 1), "%"),
      x = "Date",
      y = "Price",
      color = NULL
    ) +
    theme_minimal(base_size = 13) +
    theme(plot.title = element_text(face = "bold", size = 18), plot.subtitle = element_text(color = "#475569"), panel.grid.minor = element_blank(), legend.position = "top")

  ggsave(file.path(graphs_folder, paste0(clean_file_name(sticker_name), ".png")), price_plot, width = 13, height = 7, dpi = 180)
}

comparison_plot <- ggplot(data, aes(x = date, y = price, color = sticker)) +
  geom_line(linewidth = 0.9) +
  labs(
    title = "Major Stickers - Price Comparison",
    subtitle = "All selected sticker markets shown on the same axis.",
    x = "Date",
    y = "Price",
    color = NULL
  ) +
  theme_minimal(base_size = 13) +
  theme(plot.title = element_text(face = "bold", size = 18), plot.subtitle = element_text(color = "#475569"), panel.grid.minor = element_blank(), legend.position = "top")

ggsave(file.path(graphs_folder, "major_stickers_price_comparison.png"), comparison_plot, width = 13, height = 7, dpi = 180)

basic_comparison_plot <- ggplot(data, aes(x = date, y = price, color = sticker)) +
  geom_line(linewidth = 0.8) +
  labs(
    title = "Major Stickers - Market Price",
    x = "Date",
    y = "Market price",
    color = NULL
  ) +
  theme_minimal(base_size = 13) +
  theme(plot.title = element_text(face = "bold", size = 18), panel.grid.minor = element_blank(), legend.position = "top")

ggsave(file.path(basic_graphs_folder, "all_major_stickers_basic_price.png"), basic_comparison_plot, width = 13, height = 7, dpi = 160)

volatility_plot <- ggplot(data %>% drop_na(rolling_volatility_30), aes(x = date, y = rolling_volatility_30, color = sticker)) +
  geom_line(linewidth = 0.9) +
  labs(
    title = "Major Stickers - Rolling Volatility Comparison",
    subtitle = "30 observation rolling volatility, calculated from log returns and annualized with sqrt(365).",
    x = "Date",
    y = "Annualized volatility (%)",
    color = NULL
  ) +
  theme_minimal(base_size = 13) +
  theme(plot.title = element_text(face = "bold", size = 18), plot.subtitle = element_text(color = "#475569"), panel.grid.minor = element_blank(), legend.position = "top")

ggsave(file.path(graphs_folder, "major_stickers_rolling_volatility.png"), volatility_plot, width = 13, height = 7, dpi = 180)

cat("\n==== Major stickers graphs updated ====\n")
