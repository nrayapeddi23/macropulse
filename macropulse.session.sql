INSERT INTO public.observations (
    series_id,
    observation_date,
    value,
    unit,
    source
)
VALUES ('SAMPLE', '2026-10-24', 75.50, 'index', 'manual')
RETURNING *;