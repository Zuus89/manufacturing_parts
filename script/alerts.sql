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