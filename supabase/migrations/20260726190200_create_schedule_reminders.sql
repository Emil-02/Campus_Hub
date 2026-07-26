-- T-011: Reminder yang terkait dengan jadwal kuliah.
CREATE TABLE public.schedule_reminders (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    schedule_id UUID NOT NULL REFERENCES public.schedules(id) ON DELETE CASCADE,
    minutes_before INTEGER NOT NULL DEFAULT 30 CHECK (minutes_before > 0),
    is_enabled BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_schedule_reminders_schedule_id
    ON public.schedule_reminders(schedule_id);
