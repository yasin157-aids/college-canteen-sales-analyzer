# ==========================================================
# COLLEGE CANTEEN SALES ANALYZER
# ----------------------------------------------------------
# Reads canteen_sales.csv, calculates useful statistics,
# creates graphs, gives simple recommendations, and saves
# a text report inside the "output" folder.
#
# Run it with:  Rscript run_project.R
# (Or run this file directly from the project folder.)
# ==========================================================

# ----------------------------------------------------------
# SECTION 0: Settings (file names and required columns)
# ----------------------------------------------------------
csv_file         <- "canteen_sales.csv"
output_dir       <- "output"
report_file      <- file.path(output_dir, "analysis_report.txt")
required_columns <- c("Date", "Time", "Item", "Category", "Quantity", "Price")

# ggplot2 is used for the graphs
if (!requireNamespace("ggplot2", quietly = TRUE)) {
  stop("Package 'ggplot2' is not installed. Please run: Rscript install_packages.R",
       call. = FALSE)
}
library(ggplot2)

# Small helper functions to format numbers nicely
format_rs  <- function(x) paste0("Rs. ", formatC(x, format = "f", digits = 2, big.mark = ","))
format_num <- function(x) format(x, big.mark = ",", scientific = FALSE, trim = TRUE)

cat("\nReading data from", csv_file, "...\n")

# ----------------------------------------------------------
# SECTION 1: Read the CSV file
# ----------------------------------------------------------
if (!file.exists(csv_file)) {
  stop("canteen_sales.csv was not found. Please place the CSV file in the project folder.",
       call. = FALSE)
}

sales <- tryCatch(
  read.csv(csv_file, stringsAsFactors = FALSE, strip.white = TRUE,
           fileEncoding = "UTF-8-BOM"),
  error = function(e) {
    stop("canteen_sales.csv could not be read. Please check that it is a valid CSV file.",
         call. = FALSE)
  }
)

# ----------------------------------------------------------
# SECTION 2: Check that all required columns exist
# ----------------------------------------------------------
names(sales) <- trimws(names(sales))

# Allow small differences in capital/small letters (e.g. "item" instead of "Item")
for (col in required_columns) {
  match_pos <- which(tolower(names(sales)) == tolower(col))
  if (length(match_pos) > 0) {
    names(sales)[match_pos[1]] <- col
  }
}

missing_cols <- setdiff(required_columns, names(sales))
if (length(missing_cols) > 0) {
  stop("Required column(s) missing from canteen_sales.csv: ",
       paste(missing_cols, collapse = ", "), "\n",
       "The CSV file must contain these columns: ",
       paste(required_columns, collapse = ", "),
       call. = FALSE)
}

# ----------------------------------------------------------
# SECTION 3: Clean the data (skip rows with missing/invalid values)
# ----------------------------------------------------------
rows_before <- nrow(sales)

sales$Item     <- trimws(as.character(sales$Item))
sales$Category <- trimws(as.character(sales$Category))
sales$Time     <- trimws(as.character(sales$Time))
sales$Quantity <- suppressWarnings(as.numeric(as.character(sales$Quantity)))
sales$Price    <- suppressWarnings(as.numeric(as.character(sales$Price)))

# Dates: accept 2026-09-01 or 2026/09/01
date_text  <- trimws(as.character(sales$Date))
sales$Date <- as.Date(date_text, format = "%Y-%m-%d")
try_slash  <- is.na(sales$Date)
sales$Date[try_slash] <- as.Date(date_text[try_slash], format = "%Y/%m/%d")

# Hour is the number before the colon in Time (e.g. "09:30" -> 9)
sales$Hour <- suppressWarnings(as.integer(sub(":.*", "", sales$Time)))

# A row is valid only if every field has a sensible value
valid <- !is.na(sales$Date) &
  !is.na(sales$Hour) & sales$Hour >= 0 & sales$Hour <= 23 &
  !is.na(sales$Quantity) & sales$Quantity > 0 &
  !is.na(sales$Price) & sales$Price >= 0 &
  !is.na(sales$Item) & sales$Item != "" &
  !is.na(sales$Category) & sales$Category != ""
valid[is.na(valid)] <- FALSE

skipped <- sum(!valid)
if (skipped > 0) {
  cat("Note:", skipped, "row(s) with missing or invalid values were skipped.\n")
}
sales <- sales[valid, ]

if (nrow(sales) == 0) {
  stop("No valid rows were found in canteen_sales.csv. Please check the data.",
       call. = FALSE)
}

# ----------------------------------------------------------
# SECTION 4: Calculate revenue and add helper columns
# ----------------------------------------------------------
# Revenue = Quantity x Price
sales$Revenue <- sales$Quantity * sales$Price

# Time label such as "09:00" (used for sales by hour)
sales$Hour_Label <- sprintf("%02d:00", sales$Hour)

# Time period of the day: Morning, Lunch or Evening
sales$Period <- ifelse(sales$Hour < 12, "Morning",
                       ifelse(sales$Hour < 15, "Lunch", "Evening"))
sales$Period <- factor(sales$Period, levels = c("Morning", "Lunch", "Evening"))

# Day as text (used for sales by day)
sales$Day <- format(sales$Date, "%Y-%m-%d")

# ----------------------------------------------------------
# SECTION 5: Calculate the statistics
# ----------------------------------------------------------
total_items   <- sum(sales$Quantity)
total_revenue <- sum(sales$Revenue)
num_days      <- length(unique(sales$Date))

# --- Sales and revenue by item (highest quantity first) ---
item_summary <- aggregate(cbind(Quantity, Revenue) ~ Item, data = sales, FUN = sum)
item_summary <- item_summary[order(-item_summary$Quantity, item_summary$Item), ]

# --- Sales and revenue by category ---
category_summary <- aggregate(cbind(Quantity, Revenue) ~ Category, data = sales, FUN = sum)
category_summary <- category_summary[order(-category_summary$Quantity, category_summary$Category), ]

# --- Sales by time period (Morning / Lunch / Evening) ---
period_summary <- aggregate(cbind(Quantity, Revenue) ~ Period, data = sales, FUN = sum)
period_summary$Period <- as.character(period_summary$Period)

# --- Sales by hour ---
hour_summary <- aggregate(cbind(Quantity, Revenue) ~ Hour_Label + Period, data = sales, FUN = sum)
hour_summary <- hour_summary[order(hour_summary$Hour_Label), ]

# --- Sales by day ---
day_summary <- aggregate(cbind(Quantity, Revenue) ~ Day, data = sales, FUN = sum)
day_summary$Weekday <- format(as.Date(day_summary$Day), "%A")
day_summary <- day_summary[order(day_summary$Day), ]

# --- Find the best / least / highest values ---
best_item      <- item_summary[which.max(item_summary$Quantity), ]
least_item     <- item_summary[which.min(item_summary$Quantity), ]
top_rev_item   <- item_summary[which.max(item_summary$Revenue), ]
best_category  <- category_summary[which.max(category_summary$Quantity), ]
least_category <- category_summary[which.min(category_summary$Quantity), ]
busiest_period <- period_summary[which.max(period_summary$Quantity), ]
busiest_hour   <- hour_summary[which.max(hour_summary$Quantity), ]
best_day       <- day_summary[which.max(day_summary$Revenue), ]
lowest_day     <- day_summary[which.min(day_summary$Revenue), ]

# ----------------------------------------------------------
# SECTION 6: Simple rule-based stock recommendations
# ----------------------------------------------------------
# Rule: compare each item's quantity sold with the average item.
#   25% or more ABOVE average -> High demand   -> Prepare MORE
#   25% or more BELOW average -> Low demand    -> Prepare LESS
#   Otherwise                 -> Medium demand -> Maintain NORMAL stock
average_quantity <- mean(item_summary$Quantity)
demand_ratio     <- item_summary$Quantity / average_quantity

item_summary$Demand <- ifelse(demand_ratio >= 1.25, "High",
                              ifelse(demand_ratio <= 0.75, "Low", "Medium"))
item_summary$Recommendation <- ifelse(item_summary$Demand == "High", "Prepare MORE",
                                      ifelse(item_summary$Demand == "Low", "Prepare LESS",
                                             "Maintain NORMAL stock"))

more_items <- item_summary$Item[item_summary$Recommendation == "Prepare MORE"]
less_items <- item_summary$Item[item_summary$Recommendation == "Prepare LESS"]

# --- Written recommendations ---
recommendations <- c()

recommendations <- c(recommendations,
  paste0("Increase preparation of ", best_item$Item,
         " because it is highly demanded (", format_num(best_item$Quantity), " sold)."))

if (least_item$Item != best_item$Item) {
  recommendations <- c(recommendations,
    paste0("Reduce preparation of ", least_item$Item,
           " because it has relatively low sales (", format_num(least_item$Quantity), " sold)."))
}

recommendations <- c(recommendations,
  paste0("Prepare more items before the busiest selling period (",
         busiest_period$Period, ", especially around ", busiest_hour$Hour_Label, ")."))

recommendations <- c(recommendations,
  paste0("Focus on the ", best_category$Category,
         " category because it has the highest sales."))

recommendations <- c(recommendations,
  paste0("Always keep ", top_rev_item$Item,
         " well stocked because it earns the most money (",
         format_rs(top_rev_item$Revenue), ")."))

recommendations <- c(recommendations,
  paste0("Expect high demand on days like ", best_day$Weekday, " (", best_day$Day,
         "), and avoid over-preparing on slow days like ", lowest_day$Weekday,
         " (", lowest_day$Day, ")."))

if (length(more_items) > 0) {
  recommendations <- c(recommendations,
    paste0("Items to prepare MORE: ", paste(more_items, collapse = ", "), "."))
}
if (length(less_items) > 0) {
  recommendations <- c(recommendations,
    paste0("Items to prepare LESS: ", paste(less_items, collapse = ", "), "."))
}

# ----------------------------------------------------------
# SECTION 7: Create the output folder and the graphs
# ----------------------------------------------------------
if (!dir.exists(output_dir)) {
  dir.create(output_dir, showWarnings = FALSE)
}

# Helper: save a graph as a PNG file (shows a warning instead of crashing)
saved_graphs <- c()
save_graph <- function(plot_object, file_name) {
  path <- file.path(output_dir, file_name)
  ok <- tryCatch({
    ggsave(filename = path, plot = plot_object, width = 9, height = 6, dpi = 150)
    TRUE
  }, error = function(e) {
    cat("Warning: could not save", file_name, "-", conditionMessage(e), "\n")
    FALSE
  })
  ok
}

cat("Creating graphs ...\n")

# --- Graph 1: Sales by Item (horizontal bar chart) ---
graph1 <- ggplot(item_summary, aes(x = reorder(Item, Quantity), y = Quantity)) +
  geom_col(fill = "#2E86AB") +
  geom_text(aes(label = Quantity), hjust = -0.2, size = 4) +
  coord_flip() +
  scale_y_continuous(expand = expansion(mult = c(0, 0.15))) +
  labs(title = "Sales by Item", x = "Item", y = "Quantity Sold") +
  theme_minimal(base_size = 14)
if (save_graph(graph1, "item_sales.png")) saved_graphs <- c(saved_graphs, "item_sales.png")

# --- Graph 2: Sales by Category (bar chart) ---
graph2 <- ggplot(category_summary, aes(x = reorder(Category, -Quantity), y = Quantity, fill = Category)) +
  geom_col() +
  geom_text(aes(label = Quantity), vjust = -0.4, size = 4.5) +
  scale_y_continuous(expand = expansion(mult = c(0, 0.15))) +
  labs(title = "Sales by Category", x = "Category", y = "Quantity Sold") +
  theme_minimal(base_size = 14) +
  theme(legend.position = "none")
if (save_graph(graph2, "category_sales.png")) saved_graphs <- c(saved_graphs, "category_sales.png")

# --- Graph 3: Sales by Time (bar chart, one bar per hour) ---
graph3 <- ggplot(hour_summary, aes(x = Hour_Label, y = Quantity, fill = Period)) +
  geom_col() +
  geom_text(aes(label = Quantity), vjust = -0.4, size = 4) +
  scale_y_continuous(expand = expansion(mult = c(0, 0.15))) +
  labs(title = "Sales by Time", x = "Hour of Day", y = "Quantity Sold", fill = "Time of Day") +
  theme_minimal(base_size = 14)
if (save_graph(graph3, "time_sales.png")) saved_graphs <- c(saved_graphs, "time_sales.png")

# --- Graph 4: Revenue by Item (horizontal bar chart) ---
graph4 <- ggplot(item_summary, aes(x = reorder(Item, Revenue), y = Revenue)) +
  geom_col(fill = "#F18F01") +
  geom_text(aes(label = format(Revenue, big.mark = ",", scientific = FALSE, trim = TRUE)),
            hjust = -0.1, size = 4) +
  coord_flip() +
  scale_y_continuous(expand = expansion(mult = c(0, 0.2))) +
  labs(title = "Revenue by Item", x = "Item", y = "Revenue (Rs.)") +
  theme_minimal(base_size = 14)
if (save_graph(graph4, "revenue_by_item.png")) saved_graphs <- c(saved_graphs, "revenue_by_item.png")

# ----------------------------------------------------------
# SECTION 8: Build the report text
# ----------------------------------------------------------
line_long  <- strrep("=", 40)
line_short <- strrep("-", 40)

# Helper: turn a data frame into lines of text for the report
table_lines <- function(df) {
  capture.output(print(df, row.names = FALSE, right = FALSE))
}

# Tables shown in the report (numbers formatted for easy reading)
item_table <- data.frame(
  Item            = item_summary$Item,
  Quantity        = item_summary$Quantity,
  Demand          = item_summary$Demand,
  Recommendation  = item_summary$Recommendation,
  stringsAsFactors = FALSE
)

revenue_sorted <- item_summary[order(-item_summary$Revenue, item_summary$Item), ]
revenue_table <- data.frame(
  Item    = revenue_sorted$Item,
  Revenue = format_rs(revenue_sorted$Revenue),
  stringsAsFactors = FALSE
)

category_table <- data.frame(
  Category = category_summary$Category,
  Quantity = category_summary$Quantity,
  Revenue  = format_rs(category_summary$Revenue),
  stringsAsFactors = FALSE
)

period_table <- data.frame(
  Time     = period_summary$Period,
  Quantity = period_summary$Quantity,
  Revenue  = format_rs(period_summary$Revenue),
  stringsAsFactors = FALSE
)

hour_table <- data.frame(
  Hour     = hour_summary$Hour_Label,
  Quantity = hour_summary$Quantity,
  stringsAsFactors = FALSE
)

day_table <- data.frame(
  Date     = day_summary$Day,
  Day      = day_summary$Weekday,
  Quantity = day_summary$Quantity,
  Revenue  = format_rs(day_summary$Revenue),
  stringsAsFactors = FALSE
)

report <- c(
  line_long,
  "COLLEGE CANTEEN SALES ANALYZER",
  line_long,
  paste0("Data file       : ", csv_file),
  paste0("Records used    : ", nrow(sales)),
  paste0("Period covered  : ", min(sales$Day), " to ", max(sales$Day), " (", num_days, " days)"),
  "",
  paste0("Total Items Sold: ", format_num(total_items)),
  paste0("Total Revenue: ", format_rs(total_revenue)),
  "",
  "BEST SELLING ITEM",
  paste0("Item: ", best_item$Item),
  paste0("Quantity Sold: ", format_num(best_item$Quantity)),
  "",
  "LEAST SELLING ITEM",
  paste0("Item: ", least_item$Item),
  paste0("Quantity Sold: ", format_num(least_item$Quantity)),
  "",
  "MOST POPULAR CATEGORY",
  paste0("Category: ", best_category$Category),
  paste0("Quantity Sold: ", format_num(best_category$Quantity)),
  "",
  "LEAST POPULAR CATEGORY",
  paste0("Category: ", least_category$Category),
  paste0("Quantity Sold: ", format_num(least_category$Quantity)),
  "",
  "HIGHEST REVENUE ITEM",
  paste0("Item: ", top_rev_item$Item),
  paste0("Revenue: ", format_rs(top_rev_item$Revenue)),
  "",
  "BUSIEST SELLING TIME",
  paste0("Time Period: ", busiest_period$Period,
         " (", format_num(busiest_period$Quantity), " items sold)"),
  paste0("Busiest Hour: ", busiest_hour$Hour_Label,
         " (", format_num(busiest_hour$Quantity), " items sold)"),
  "",
  "BEST SALES DAY",
  paste0("Date: ", best_day$Day, " (", best_day$Weekday, ")"),
  paste0("Revenue: ", format_rs(best_day$Revenue)),
  "",
  "LOWEST SALES DAY",
  paste0("Date: ", lowest_day$Day, " (", lowest_day$Weekday, ")"),
  paste0("Revenue: ", format_rs(lowest_day$Revenue)),
  "",
  line_short,
  "SALES BY ITEM (with stock advice)",
  line_short,
  table_lines(item_table),
  "",
  line_short,
  "REVENUE BY ITEM",
  line_short,
  table_lines(revenue_table),
  "",
  line_short,
  "SALES BY CATEGORY",
  line_short,
  table_lines(category_table),
  "",
  line_short,
  "SALES BY TIME",
  line_short,
  "(Morning = before 12:00, Lunch = 12:00-14:59, Evening = 15:00 onwards)",
  table_lines(period_table),
  "",
  table_lines(hour_table),
  "",
  line_short,
  "SALES BY DAY",
  line_short,
  table_lines(day_table),
  "",
  line_short,
  "RECOMMENDATIONS",
  line_short,
  paste0(seq_along(recommendations), ". ", recommendations),
  "",
  line_short,
  "OUTPUT FILES (saved in the 'output' folder)",
  line_short,
  "analysis_report.txt",
  saved_graphs,
  "",
  line_long,
  "ANALYSIS COMPLETED",
  line_long
)

# ----------------------------------------------------------
# SECTION 9: Save the report and show it in the terminal
# ----------------------------------------------------------
tryCatch(
  writeLines(report, report_file),
  error = function(e) {
    cat("Warning: could not save the report file -", conditionMessage(e), "\n")
  }
)

cat("\n")
writeLines(report)
