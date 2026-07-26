-- Enable least-privilege row access for the database foundation tables.
ALTER TABLE public.courses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.schedules ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.schedule_reminders ENABLE ROW LEVEL SECURITY;

-- Courses are owned directly by the authenticated user.
CREATE POLICY courses_select_own
    ON public.courses
    FOR SELECT
    USING (user_id = (SELECT auth.uid()));

CREATE POLICY courses_insert_own
    ON public.courses
    FOR INSERT
    WITH CHECK (user_id = (SELECT auth.uid()));

CREATE POLICY courses_update_own
    ON public.courses
    FOR UPDATE
    USING (user_id = (SELECT auth.uid()))
    WITH CHECK (user_id = (SELECT auth.uid()));

CREATE POLICY courses_delete_own
    ON public.courses
    FOR DELETE
    USING (user_id = (SELECT auth.uid()));

-- Schedules are owned directly by the user and may reference only that user's course.
CREATE POLICY schedules_select_own
    ON public.schedules
    FOR SELECT
    USING (user_id = (SELECT auth.uid()));

CREATE POLICY schedules_insert_own_course
    ON public.schedules
    FOR INSERT
    WITH CHECK (
        user_id = (SELECT auth.uid())
        AND EXISTS (
            SELECT 1
            FROM public.courses AS c
            WHERE c.id = schedules.course_id
              AND c.user_id = (SELECT auth.uid())
        )
    );

CREATE POLICY schedules_update_own_course
    ON public.schedules
    FOR UPDATE
    USING (user_id = (SELECT auth.uid()))
    WITH CHECK (
        user_id = (SELECT auth.uid())
        AND EXISTS (
            SELECT 1
            FROM public.courses AS c
            WHERE c.id = schedules.course_id
              AND c.user_id = (SELECT auth.uid())
        )
    );

CREATE POLICY schedules_delete_own
    ON public.schedules
    FOR DELETE
    USING (user_id = (SELECT auth.uid()));

-- Reminders inherit ownership through their parent schedule.
CREATE POLICY schedule_reminders_select_own_schedule
    ON public.schedule_reminders
    FOR SELECT
    USING (
        EXISTS (
            SELECT 1
            FROM public.schedules AS s
            WHERE s.id = schedule_reminders.schedule_id
              AND s.user_id = (SELECT auth.uid())
        )
    );

CREATE POLICY schedule_reminders_insert_own_schedule
    ON public.schedule_reminders
    FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1
            FROM public.schedules AS s
            WHERE s.id = schedule_reminders.schedule_id
              AND s.user_id = (SELECT auth.uid())
        )
    );

CREATE POLICY schedule_reminders_update_own_schedule
    ON public.schedule_reminders
    FOR UPDATE
    USING (
        EXISTS (
            SELECT 1
            FROM public.schedules AS s
            WHERE s.id = schedule_reminders.schedule_id
              AND s.user_id = (SELECT auth.uid())
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1
            FROM public.schedules AS s
            WHERE s.id = schedule_reminders.schedule_id
              AND s.user_id = (SELECT auth.uid())
        )
    );

CREATE POLICY schedule_reminders_delete_own_schedule
    ON public.schedule_reminders
    FOR DELETE
    USING (
        EXISTS (
            SELECT 1
            FROM public.schedules AS s
            WHERE s.id = schedule_reminders.schedule_id
              AND s.user_id = (SELECT auth.uid())
        )
    );

-- Keep the RPC invoker-scoped and prevent callers from probing another user's ID.
CREATE OR REPLACE FUNCTION public.check_schedule_conflict(
    p_user_id UUID,
    p_day_of_week INTEGER,
    p_start_time TIME,
    p_end_time TIME,
    p_exclude_id UUID DEFAULT NULL
)
RETURNS TABLE(
    conflicting_id UUID,
    course_name VARCHAR,
    start_time TIME,
    end_time TIME
)
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = pg_catalog, public
AS $$
BEGIN
    IF auth.uid() IS NULL OR p_user_id IS DISTINCT FROM auth.uid() THEN
        RETURN;
    END IF;

    RETURN QUERY
    SELECT s.id, c.name, s.start_time, s.end_time
    FROM public.schedules AS s
    JOIN public.courses AS c ON c.id = s.course_id
    WHERE s.user_id = auth.uid()
      AND s.day_of_week = p_day_of_week
      AND s.is_active = TRUE
      AND (p_exclude_id IS NULL OR s.id <> p_exclude_id)
      AND s.start_time < p_end_time
      AND s.end_time > p_start_time;
END;
$$;

REVOKE EXECUTE ON FUNCTION public.check_schedule_conflict(UUID, INTEGER, TIME, TIME, UUID)
    FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION public.check_schedule_conflict(UUID, INTEGER, TIME, TIME, UUID)
    FROM anon;
GRANT EXECUTE ON FUNCTION public.check_schedule_conflict(UUID, INTEGER, TIME, TIME, UUID)
    TO authenticated;
