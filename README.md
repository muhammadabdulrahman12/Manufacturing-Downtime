[README.md](https://github.com/user-attachments/files/34856926/README.md)
# Manufacturing Downtime Analysis

Analyzing machine downtime in a CNC and assembly plant, building interactive dashboards, and predicting next-day downtime to guide production planning.

## Table of Contents

- [Project Name](#project-name)
- [Project Idea](#project-idea)
- [Team Members](#team-members)
- [Work Plan](#work-plan)
- [Roles & Responsibilities](#roles--responsibilities)
- [KPIs](#kpis)
- [Instructor](#instructor)
- [Project Files](#project-files)

## Project Name

**Manufacturing Downtime Analysis**

## Project Idea

Unplanned stops are one of the biggest sources of lost output in a manufacturing plant. This project uses the plant's production, quality, and downtime records to understand **when, where, and why** machines stop, and how much that costs in lost production time and scrapped units.

The project has three goals:

1. **Prepare the data:** clean and preprocess the raw records so they are reliable for analysis.
2. **Analyze and visualize:** define the questions that matter to decision makers and answer them with dashboards.
3. **Predict and plan:** forecast downtime for the next day of operation and, based on it, highlight the number of batches to be produced.

### Dataset

The dataset was approved by management and covers **1 July to 30 September 2026** (79 production days, 3 shifts: A, B, C).

| File | Description | Rows |
|---|---|---|
| `machines.csv` | 9 machines with line, type, and ideal cycle time | 9 |
| `products.csv` | 6 products with family and unit cost | 6 |
| `production_log.csv` | Production runs per machine, shift, and date | 2,016 |
| `quality_checks.csv` | Inspected and rejected units with the main defect | 2,016 |
| `downtime_events.csv` | Downtime events with start, end, reason, and operator note | 3,286 |

### Tools

Power Query, Power BI, DAX, Tableau, SQL, Python, and Excel.

## Team Members

| # | Name | Role |
|---|---|---|
| 1 | Mohamed Abdelrahman | Data Preparation (Power Query & Python) |
| 2 | Gerges Nasry | DAX & KPIs |
| 3 | Omar Atef | Power BI Dashboards |
| 4 | Alaa Khaled | Tableau Dashboards |
| 5 | Engy Mohamed | SQL Analysis |
| 6 | Azmy Selim | Analysis Questions, Excel & Presentation |

## Work Plan

| Week | Focus | Main Tasks | Deliverables | Status |
|---|---|---|---|---|
| 1 | Data Cleaning & Preprocessing | Clean and preprocess the data using Power Query; build the fact and dimension tables | Cleaned dataset and preprocessing documentation | Done |
| 2 | Analysis Questions | Define all analysis questions that decision makers care about; predict downtime for the next day and highlight the number of batches to be produced | Set of analysis questions and the downtime prediction | Planned |
| 3 | Dashboards | Build dashboards that answer the questions (Power BI and Tableau) | Power BI dashboard and Tableau dashboard | Planned |
| 4 | Final Presentation | Prepare the report and presentation covering data analysis, model development, and deployment | Final report and presentation | Planned |

## Roles & Responsibilities

| Member | Role | Responsibilities |
|---|---|---|
| **Mohamed Abdelrahman** | Power Query & Python | Clean and preprocess the raw data; build the fact and dimension tables; document the preprocessing steps; build the next-day downtime prediction in Python |
| **Gerges Nasry** | DAX & KPIs | Write the DAX measures and define the KPIs (Availability, Performance, Quality, OEE, and downtime measures); support Omar with the Power BI model |
| **Omar Atef** | Power BI | Build the data model and the Power BI dashboard; visualize the answers to the analysis questions |
| **Alaa Khaled** | Tableau | Build the Tableau dashboard on the cleaned data |
| **Engy Mohamed** | SQL | Write the SQL queries for the analysis questions and validate the KPI results |
| **Azmy Selim** | Analysis, Excel & Presentation | Define the analysis questions; handle Excel tasks; prepare the final report and presentation; cover any remaining tasks |

## KPIs

KPI ratios are calculated as **sum / sum** across the selected rows (not as an average of row-level ratios).

| KPI | Definition |
|---|---|
| **Availability** | Run time / Planned production time |
| **Performance** | Actual units produced / Ideal units for the run time |
| **Quality** | Good units / Inspected units |
| **OEE** | Availability × Performance × Quality |
| **Total Downtime** | Sum of downtime minutes, in hours |
| **Downtime by Reason** | Downtime minutes per reason, split into Planned, Unplanned, and Unclassified |
| **Average Downtime per Event** | Total downtime minutes / Number of downtime events |
| **Reject Rate and Scrap Cost** | Rejected units / Inspected units, and rejected units × unit cost |

Baseline values for July to September 2026: Availability 85.6%, Performance 85.8%, Quality 97.9%, and OEE 71.9%.

## Instructor

**Adham Osama**

## Project Files

All project files are in the shared Google Drive folder:

[Open the project folder on Google Drive](https://drive.google.com/drive/folders/1wL3j7K6oV6aFrAv0JbtLODPKgA31IKPK?usp=drive_link)
