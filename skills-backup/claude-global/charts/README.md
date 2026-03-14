# Charts Skill

Generate charts and graphs from data for reports.

## Features

- **Bar charts** - Vertical or horizontal
- **Line charts** - Trends and time series
- **Pie charts** - Proportions and percentages
- **Scatter plots** - Correlations between variables
- **Histograms** - Data distributions

## Requirements

- Python 3
- matplotlib (installed automatically)

## Installation

```bash
./install.sh charts
```

## Usage

### Basic Examples

```bash
# Bar chart with inline data
charts bar --labels "Q1,Q2,Q3,Q4" --values "100,150,120,180" --title "Quarterly Sales"

# Line chart from CSV
charts line --file data.csv --x date --y value --title "Trend"

# Pie chart
charts pie --labels "Yes,No,Maybe" --values "60,25,15" --title "Survey Results"
```

### Data Input

The skill accepts data in three ways:

1. **Inline** - Use `--labels` and `--values` flags
2. **File** - Use `--file` with a CSV or JSON file
3. **Stdin** - Pipe data from another command

### Integration with Database Skill

```bash
# Visualize query results directly
database query "SELECT category, SUM(amount) as total FROM sales GROUP BY category" \
  | charts bar --x category --y total --title "Sales by Category"
```

## Commands

| Command | Description |
|---------|-------------|
| `bar` | Bar chart |
| `line` | Line chart |
| `pie` | Pie chart |
| `scatter` | Scatter plot |
| `histogram` | Histogram |
| `help` | Show help |

## Options

### Common

| Option | Description |
|--------|-------------|
| `--title TEXT` | Chart title |
| `--output FILE` | Output file path |
| `--open` | Open chart after generating |
| `--file FILE` | Input CSV/JSON file |
| `--x COLUMN` | X axis column |
| `--y COLUMN` | Y axis column |

### Chart-Specific

| Option | Command | Description |
|--------|---------|-------------|
| `--horizontal` | bar | Horizontal bars |
| `--column COL` | histogram | Column to analyze |
| `--bins N` | histogram | Number of bins (default: 10) |

## Output

Charts are saved to `/tmp/chart_<type>_<timestamp>.png` by default. The path is printed to stdout.

Use `--output` to specify a custom path, or `--open` to view immediately.
