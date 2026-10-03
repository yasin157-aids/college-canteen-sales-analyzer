# College Canteen Sales Analyzer Using R

## Objective

This project reads the sales data of a college canteen from a CSV file and finds useful information such as:

- total items sold and total revenue
- best-selling and least-selling items
- most and least popular categories
- highest revenue item
- busiest selling time
- best and lowest sales days

It then draws 4 simple graphs and gives easy, rule-based advice such as "Prepare MORE", "Maintain NORMAL stock" or "Prepare LESS" for each item.

No database, web server, or machine learning is used. It is just: **CSV -> R analysis -> Graphs -> Recommendations**.

## Requirements

- R (https://cran.r-project.org)
- Visual Studio Code (VS Code)
- R extension for VS Code (search "R" by REditorSupport in the Extensions tab)
- ggplot2 (installed automatically the first time you run the project; internet is needed only for this step)

## Files in this project

| File | What it does |
|------|--------------|
| `run_project.R` | Runs everything in one step |
| `install_packages.R` | Installs ggplot2 if it is missing |
| `canteen_analyzer.R` | Main analysis code (reads CSV, calculates, makes graphs and report) |
| `canteen_sales.csv` | Sample sales data (edit this to use your own data) |
| `output/` | Graphs and report are saved here |

## How to Run

1. Install R.
2. Install VS Code.
3. Install the R extension in VS Code.
4. Extract the ZIP file.
5. Open the extracted folder `College_Canteen_Sales_Analyzer` in VS Code (File -> Open Folder).
6. Open the VS Code terminal (Terminal -> New Terminal).
7. Run:

```
Rscript run_project.R
```

8. Check the terminal for the results.
9. Check the `output` folder for the graphs and the report.

**If `Rscript` is not recognized** (common on Windows): add R's `bin` folder to your PATH (for example `C:\Program Files\R\R-4.x.x\bin`), then close and reopen VS Code. Alternatively, open the R terminal in VS Code and type: `source("run_project.R")`

## Output

After running, the `output` folder will contain:

- `analysis_report.txt` - the full text report (also printed in the terminal)
- `item_sales.png` - Sales by Item
- `category_sales.png` - Sales by Category
- `time_sales.png` - Sales by Time
- `revenue_by_item.png` - Revenue by Item

## How to Change the Dataset

Open `canteen_sales.csv` and replace the rows with your own data (or replace the whole file, keeping the same name). Keep this header row exactly:

```
Date,Time,Item,Category,Quantity,Price
```

Rules for the data:

- **Date**: `YYYY-MM-DD`, for example `2026-09-01`
- **Time**: 24-hour `HH:MM`, for example `13:30`
- **Item**: name of the food/drink, for example `Samosa`
- **Category**: for example `Snack`, `Beverage`, `Food`
- **Quantity**: number sold (a positive number)
- **Price**: price of one item in rupees

Rows with missing or invalid values are skipped automatically, and a note is shown in the terminal.

## Common Errors

- `canteen_sales.csv was not found` - the CSV file must be in the project folder (next to `run_project.R`).
- `Required column(s) missing` - check that the header row has all six column names listed above.
- ggplot2 could not be installed - check your internet connection and run again.

## How the Recommendations Work

For each item, the program compares its quantity sold with the average item:

- 25% or more above average -> **Prepare MORE**
- 25% or more below average -> **Prepare LESS**
- Otherwise -> **Maintain NORMAL stock**
