# 📊 Statistical Process Control – Manufacturing Parts

This project applies **Statistical Process Control (SPC)** techniques to a manufacturing dataset using SQL. The goal is to monitor the `height` dimension of manufactured parts and identify when the process deviates from acceptable control limits.

## 🏭 Context

In manufacturing, it's essential to ensure consistent quality. SPC is a data-driven approach that defines acceptable variation using:

- **UCL (Upper Control Limit)**  
- **LCL (Lower Control Limit)**  

If a measurement falls outside these limits, it may indicate that the process is drifting and needs attention.

---

## 📐 Formulas Used

Control limits are calculated based on a moving window of the last 5 measurements:

```
UCL = avg_height + 3 * (stddev_height / √5) LCL = avg_height - 3 * (stddev_height / √5)
```

Where:
- `avg_height`: moving average of the last 5 height values
- `stddev_height`: moving standard deviation of the last 5 height values

---

## 📄 Data Schema

The dataset is stored in the `manufacturing_parts` table and contains:

| Column   | Description                    |
|----------|--------------------------------|
| item_no  | Production sequence ID         |
| length   | Length of the manufactured part|
| width    | Width of the manufactured part |
| height   | Height of the manufactured part|
| operator | Machine operator ID            |

---

## 🛠️ SQL Logic

The analysis uses **window functions** to compute moving statistics per operator:

```
sql
WITH base AS (	
	SELECT 
		operator,
		item_no,
		height,
		ROW_NUMBER() OVER (PARTITION BY operator ORDER BY item_no) AS row_number,

		-- Promedio de altura en ventana móvil de 5
		AVG(height) OVER (
		  PARTITION BY operator 
		  ORDER BY item_no 
		  ROWS BETWEEN 4 PRECEDING AND CURRENT ROW
		) AS avg_height,

		-- Desviación estándar en ventana móvil de 5
		STDDEV(height) OVER (
		  PARTITION BY operator 
		  ORDER BY item_no 
		  ROWS BETWEEN 4 PRECEDING AND CURRENT ROW
		) AS stddev_height
	FROM public.manufacturing_parts
)

SELECT 
  operator,
  row_number,
  height,
  avg_height,
  stddev_height,

  -- UCL y LCL usando fórmula con raíz cuadrada de 5
  avg_height + 3 * stddev_height / POWER(5, 0.5) AS ucl,
  avg_height - 3 * stddev_height / POWER(5, 0.5) AS lcl,

  -- Alerta: TRUE si fuera del rango (importante: es FUERA del rango)
  CASE 
    WHEN height < avg_height - 3 * stddev_height / POWER(5, 0.5)
      OR height > avg_height + 3 * stddev_height / POWER(5, 0.5)
    THEN TRUE ELSE FALSE 
  END AS alert

FROM base
WHERE row_number >= 5
ORDER BY item_no;
```
## ✅ Results

- Only rows with complete 5-row windows are considered (`row_number >= 5`).
- The final result includes an `alert` column that flags `TRUE` if the height is outside control limits.
- Total TRUE alerts: **57**, indicating 57 parts were produced outside the acceptable range.

---

## 📈 Insights

- This method provides a systematic way to monitor quality in real time.
- Alerts can be used to trigger interventions or quality checks during production.
- Using SQL allows the integration of SPC into any data warehouse or reporting environment.

---

## 🔗 Technologies

- PostgreSQL
- SQL Window Functions
- Statistical Quality Control (SPC)

---

## 🧑‍💻 Author

**Cristóbal Elton**  
Data & Tech Enthusiast | Manufacturing Process Optimizer
