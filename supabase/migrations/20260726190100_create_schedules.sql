-- T-010: Jadwal kuliah mingguan dan fungsi deteksi bentrok.
CREATE TABLE public.schedules (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    course_id UUID NOT NULL REFERENCES public.courses(id) ON DELETE CASCADE,
    day_of_week INTEGER NOT NULL CHECK (day_of_week >= 1 AND day_of_week <= 7),
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    room VARCHAR(50),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT valid_time_range CHECK (start_time < end_time)
);

CREATE INDEX idx_schedules_user_id ON public.schedules(user_id);
CREATE INDEX idx_schedules_user_day ON public.schedules(user_id, day_of_week);
CREATE INDEX idx_schedules_course_id ON public.schedules(course_id);

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
AS $$
BEGIN
    RETURN QUERY
    SELECT s.id, c.name, s.start_time, s.end_time
    FROM public.schedules AS s
    JOIN public.courses AS c ON c.id = s.course_id
    WHERE s.user_id = p_user_id
      AND s.day_of_week = p_day_of_week
      AND s.is_active = TRUE
      AND (p_exclude_id IS NULL OR s.id <> p_exclude_id)
      AND s.start_time < p_end_time
      AND s.end_time > p_start_time;
END;
$$;
