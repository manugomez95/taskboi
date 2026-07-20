-- Prevent duplicate active recurring occurrences for the same series and date.
--
-- Existing same-series duplicates are removed before creating the index so the
-- migration can be applied to databases that already contain duplicate rows.

WITH ranked AS (
    SELECT
        id,
        ROW_NUMBER() OVER (
            PARTITION BY user_id, recurrence_parent_id, recurrence_anchor_date
            ORDER BY created_at ASC, updated_at ASC, id ASC
        ) AS rn
    FROM public.tasks
    WHERE recurrence_rule IS NOT NULL
      AND recurrence_parent_id IS NOT NULL
      AND recurrence_anchor_date IS NOT NULL
      AND is_completed = FALSE
)
DELETE FROM public.tasks t
USING ranked r
WHERE t.id = r.id
  AND r.rn > 1;

CREATE UNIQUE INDEX IF NOT EXISTS idx_tasks_recurring_occurrence_unique
ON public.tasks (user_id, recurrence_parent_id, recurrence_anchor_date)
WHERE recurrence_rule IS NOT NULL
  AND recurrence_parent_id IS NOT NULL
  AND recurrence_anchor_date IS NOT NULL
  AND is_completed = FALSE;
