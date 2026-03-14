---
name: charts
description: Generate charts and graphs from data for reports. Use when user wants to visualize data, create charts, graphs, plots, or diagrams from CSV, JSON, or query results.
allowed-tools:
  - Read
  - Bash(~/.claude/skills/charts/*:*)
---

# Charts Skill

Generate charts and graphs from data using matplotlib.

## Commands

| Command | Description |
|---------|-------------|
| `charts bar` | Bar chart (vertical or horizontal) |
| `charts line` | Line chart for trends/time series |
| `charts pie` | Pie chart for proportions |
| `charts scatter` | Scatter plot for correlations |
| `charts histogram` | Histogram for distributions |
| `charts help` | Show help |

## Data Input Methods

### 1. Inline data
```bash
charts bar --labels "A,B,C" --values "10,20,30"
```

### 2. From CSV/JSON file
```bash
charts line --file data.csv --x date --y revenue
```

### 3. From stdin (pipe)
```bash
echo "name,value
Product A,100
Product B,150" | charts bar --x name --y value
```

### 4. Combined with database skill
```bash
database query "SELECT status, COUNT(*) as count FROM orders GROUP BY status" | charts pie --x status --y count --title "Order Status"
```

## Common Options

- `--title "Text"` - Set chart title
- `--output file.png` - Specify output path (default: /tmp/chart_<type>_<timestamp>.png)
- `--open` - Open image after generating
- `--x column` - Column for X axis / labels
- `--y column` - Column for Y axis / values

## Chart-Specific Options

### Bar chart
- `--horizontal` - Horizontal bars instead of vertical

### Histogram
- `--column name` - Column to analyze
- `--bins N` - Number of bins (default: 10)

## Output

By default, charts are saved to `/tmp/chart_<type>_<timestamp>.png` and the path is printed to stdout.

Use the Read tool to view the generated chart image.

## Examples

```bash
# Sales by month
charts bar --labels "Jan,Feb,Mar,Apr" --values "12000,15000,13500,18000" --title "Monthly Sales"

# Revenue trend from CSV
charts line --file sales.csv --x month --y revenue --title "Revenue Trend"

# Distribution pie chart
charts pie --labels "Desktop,Mobile,Tablet" --values "55,35,10" --title "Traffic by Device"

# Query results visualization
database query "SELECT date, amount FROM transactions ORDER BY date" | charts line --x date --y amount --title "Transaction History"

# Age distribution histogram
charts histogram --file users.csv --column age --bins 15 --title "User Age Distribution"
```
