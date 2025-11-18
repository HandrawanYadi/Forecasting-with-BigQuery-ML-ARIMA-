# **FMCG Sales Forecasting with BigQuery ML (ARIMA+)**

This project demonstrates an end-to-end **demand forecasting pipeline** for a large FMCG (Fast-Moving Consumer Goods) dataset.  
The workflow integrates:

<ul>
  <li><strong>SQL + BigQuery ML (ARIMA+)</strong> for multi-series forecasting</li>
  <li><strong>Weekly segment-level aggregation</strong> for stable time-series modelling</li>
  <li><strong>SKU-level forecast allocation</strong> using sales mix ratios</li>
  <li><strong>Power BI</strong> for clean Actual vs Forecast visualisation</li>
</ul>

---

<h2>Dataset Description</h2>

<p>
The project uses a synthetic FMCG dataset (<code>FMCG_2022_2024.csv</code>) designed to resemble realistic retail and distribution data found in large consumer-goods companies.<br>
Below is the structural summary of the dataset.
</p>

<ul>
  <li><b>Time span:</b> January 2022 → December 2024 (3 years).</li>
  <li><b>Rows:</b> ~110,000 sales records.</li>
  <li><b>SKU count:</b> 30 SKUs.</li>
  <li><b>Segments:</b> 10 FMCG product segments (Milk, Juice, ReadyMeal, Yogurt, SnackBar, etc).</li>
  <li><b>Columns:</b> date, sku, segment, channel, region, units_sold.</li>
</ul>

### **Column Overview**

<ul>
  <li><strong>date</strong> - daily transaction date</li>
  <li><strong>sku</strong> - unique product code</li>
  <li><strong>brand</strong> - product brand name</li>
  <li><strong>segment</strong> - product segment/category (used for forecasting)</li>
  <li><strong>category</strong> - broad category grouping (e.g., Milk, Juice, ReadyMeal)</li>
  <li><strong>channel</strong> - sales channel (Retail, Discount, etc.)</li>
  <li><strong>region</strong> - geographical region (e.g., PL-Central, PL-North)</li>
  <li><strong>pack_type</strong> - unit configuration (Single, Carton, Multipack)</li>
  <li><strong>price_unit</strong> - selling price per unit</li>
  <li><strong>promotion_flag</strong> - binary indicator (1 = on promotion, 0 = not on promotion)</li>
  <li><strong>delivery_days</strong> - delivery lead time in days</li>
  <li><strong>stock_available</strong> - stock availability at the time of sale</li>
  <li><strong>delivered_qty</strong> - quantity delivered to the outlet</li>
  <li><strong>units_sold</strong> - units sold on that specific day</li>
</ul>

### **Key Notes About the Dataset**

<ul>
  <li>The dataset contains <strong>multiple regions</strong> and <strong>multiple channels</strong>, producing several demand patterns for the same SKU.</li>
  <li><strong>Segment</strong> is the most stable forecasting level, which is why ARIMA+ is trained on weekly segment totals.</li>
  <li>The final week of December 2024 shows a <strong>sharp drop</strong> because the dataset ends on 31 December 2024 — meaning the last weekly aggregate is incomplete. This is normal in real time-series datasets.</li>
  <li>SKU-level daily demand is noisy, which is typical in FMCG, making aggregation essential for stable forecasting.</li>
</ul>

## **About ARIMA+ in Real Demand Planning**

This project uses ARIMA+ as the core modelling technique because it is transparent, SQL-based, and well suited for a technical demonstration, but in real business environments it is only one component of a broader forecasting toolkit.

The ARIMA+ model occasionally produces negative forecast values.
This is expected behaviour in unconstrained statistical forecasting, especially when the final data points show a sharp drop (such as an incomplete last week in the dataset).
Real-world demand planning systems apply non-negativity rules to clip these values to zero, but this project keeps the raw output to show the unadjusted behaviour of the model.

### Limitations of ARIMA+ 
<ul>
  <li><strong>No business understanding</strong> - ARIMA+ only uses historical data. It doesn’t know about promotions, price changes, stockouts, new launches, weather, or competitor actions.</li>
  <li><strong>Not ideal for low-volume or noisy SKUs</strong> - SKU-level demand often behaves randomly in FMCG.</li>
  <li><strong>Assumes the past repeats</strong> - structural market changes cannot be predicted.</li>
  <li><strong>Does not compute inventory policies</strong> - ARIMA+ predicts demand, but does not calculate safety stock, reorder points, or service levels.</li>
</ul>


---
## Forecasting Pipeline (BigQuery ML + Power BI)
 ```mermaid
flowchart LR

    A["Raw Daily FMCG Data\n(110k rows, 30 SKUs)"]
    B["Weekly Segment Aggregation\nStable Time Series"]
    C["Train ARIMA+ Model\nMulti-series by Segment"]
    D["Generate 16-week Forecast\nwith Confidence Intervals"]
    E["Compute SKU Sales Mix\nLast 8 Weeks"]
    F["Allocate Segment Forecast\nto SKU Forecast (Mix Share)"]
    G["Power BI Dashboard\nActual vs Forecast + Segments"]

    A --> B --> C --> D --> E --> F --> G

```

## 📊 Visualization — Weekly Sales: Actual vs Forecasted Demand (Power BI)
<img width="1661" height="931" alt="Screenshot 2025-11-18 at 10 45 00 PM" src="https://github.com/user-attachments/assets/e1975cea-a044-4743-9097-698e45b12e6e" />

### What the Chart Shows
This chart presents the final output of the forecasting pipeline.  
It overlays **historical weekly sales** with a **16-week ARIMA+ forecast**, allowing comparison between past performance with projected future demand.
- **Actual weekly sales** (Yellow Column)
- **Forecasted demand** using ARIMA+ (Purple Column)
- **Average Sales Line** (Dotted Blue Line)
- **Confidence interval shading** (upper and lower bounds)
- **Interactive segment slicer** for exploring 10 FMCG product segments:
  - Milk, Juice, Yogurt, ReadyMeal, SnackBar, etc.
- **Time span**:  
  - Jan 2022 → Dec 2024 (actuals)  
  - 16-week forecast window into 2025

### **Chart Overview**
<ul>
<li>Actual weekly sales rise strongly through <strong>2022–2023</strong>, peaking around <strong>39K units</strong>.</li>
<li>A gradual decline continues throughout <strong>2024</strong>.</li>
<li>The ARIMA+ forecast projects a <strong>continued downward trend</strong> for the next 16 weeks.</li>
<li>Confidence intervals widen toward the end:
    <ul>
        <li><strong>Upper bound:</strong> ~24K–29K</li>
        <li><strong>Lower bound:</strong> dips below zero (a statistical artefact, not real negative demand)</li>
    </ul>
</li>
</ul>

---

### **Technical Interpretation**
<ul>
<li>ARIMA+ follows the recent trend, so weakening sales → weakening forecast.</li>
<li>Negative lower bounds occur due to volatility + softening trend, not because demand can go below zero.</li>
<li>Wider confidence intervals signal increasing uncertainty as the model forecasts further ahead.</li>
<li>This represents only one forecasting engine; real businesses use multiple models and business judgement.</li>
</ul>

---




