-- T-012/T-013/T-014/T-020: Tugas, checklist dengan auto-completion, reminder, dan statistik.

CREATE TYPE task_priority AS ENUM ('low', 'medium', 'high', 'urgent');
CREATE TYPE task_status AS ENUM ('todo', 'in_progress', 'completed');

CREATE TABLE public.tasks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    course_id UUID REFERENCES public.courses(id) ON DELETE SET NULL,
    title VARCHAR(300) NOT NULL,
    description TEXT,
    deadline TIMESTAMPTZ,
    priority task_priority NOT NULL DEFAULT 'medium',
    status task_status NOT NULL DEFAULT 'todo',
    completion_percentage INTEGER NOT NULL DEFAULT 0 CHECK (
        completion_percentage >= 0 AND completion_percentage <= 100
    ),
    is_deleted BOOLEAN NOT NULL DEFAULT FALSE,
    completed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_tasks_user_id ON public.tasks(user_id);
CREATE INDEX idx_tasks_user_status ON public.tasks(user_id, status)
    WHERE is_deleted = FALSE;
CREATE INDEX idx_tasks_user_deadline ON public.tasks(user_id, deadline)
    WHERE is_deleted = FALSE;
CREATE INDEX idx_tasks_course_id ON public.tasks(course_id);

ALTER TABLE public.tasks ENABLE ROW LEVEL SECURITY;

CREATE POLICY tasks_select_own
    ON public.tasks FOR SELECT
    USING (user_id = (SELECT auth.uid()));

CREATE POLICY tasks_insert_own
    ON public.tasks FOR INSERT
    WITH CHECK (user_id = (SELECT auth.uid()));

CREATE POLICY tasks_update_own
    ON public.tasks FOR UPDATE
    USING (user_id = (SELECT auth.uid()))
    WITH CHECK (user_id = (SELECT auth.uid()));

CREATE POLICY tasks_delete_own
    ON public.tasks FOR DELETE
    USING (user_id = (SELECT auth.uid()));

CREATE TRIGGER update_tasks_updated_at
    BEFORE UPDATE ON public.tasks
    FOR EACH ROW
    EXECUTE FUNCTION public.update_updated_at_column();

-- Checklist / sub-tugas.
CREATE TABLE public.task_checklists (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    task_id UUID NOT NULL REFERENCES public.tasks(id) ON DELETE CASCADE,
    title VARCHAR(300) NOT NULL,
    is_completed BOOLEAN NOT NULL DEFAULT FALSE,
    sort_order INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_task_checklists_task_id ON public.task_checklists(task_id);

ALTER TABLE public.task_checklists ENABLE ROW LEVEL SECURITY;

CREATE POLICY task_checklists_all_own
    ON public.task_checklists FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM public.tasks t
            WHERE t.id = task_id AND t.user_id = (SELECT auth.uid())
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.tasks t
            WHERE t.id = task_id AND t.user_id = (SELECT auth.uid())
        )
    );

CREATE TRIGGER update_task_checklists_updated_at
    BEFORE UPDATE ON public.task_checklists
    FOR EACH ROW
    EXECUTE FUNCTION public.update_updated_at_column();

-- BR-01/BR-02: progres & status tugas dihitung otomatis dari checklist.
CREATE OR REPLACE FUNCTION public.update_task_completion()
RETURNS TRIGGER AS $$
DECLARE
    total_items INTEGER;
    completed_items INTEGER;
BEGIN
    SELECT COUNT(*), COUNT(*) FILTER (WHERE is_completed = TRUE)
    INTO total_items, completed_items
    FROM public.task_checklists
    WHERE task_id = COALESCE(NEW.task_id, OLD.task_id);

    IF total_items > 0 THEN
        UPDATE public.tasks
        SET completion_percentage = (completed_items * 100 / total_items),
            status = CASE
                WHEN completed_items = total_items THEN 'completed'::task_status
                WHEN completed_items > 0 THEN 'in_progress'::task_status
                ELSE 'todo'::task_status
            END,
            completed_at = CASE
                WHEN completed_items = total_items THEN NOW()
                ELSE NULL
            END
        WHERE id = COALESCE(NEW.task_id, OLD.task_id);
    END IF;

    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

CREATE TRIGGER on_checklist_change
    AFTER INSERT OR UPDATE OR DELETE ON public.task_checklists
    FOR EACH ROW
    EXECUTE FUNCTION public.update_task_completion();

-- Reminder tugas (H-3/H-1) — jadwal notifikasi disimpan untuk pembatalan.
CREATE TABLE public.task_reminders (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    task_id UUID NOT NULL REFERENCES public.tasks(id) ON DELETE CASCADE,
    remind_at TIMESTAMPTZ NOT NULL,
    is_sent BOOLEAN NOT NULL DEFAULT FALSE,
    local_notification_id VARCHAR(50),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_task_reminders_task_id ON public.task_reminders(task_id);
CREATE INDEX idx_task_reminders_remind_at ON public.task_reminders(remind_at)
    WHERE is_sent = FALSE;

ALTER TABLE public.task_reminders ENABLE ROW LEVEL SECURITY;

CREATE POLICY task_reminders_all_own
    ON public.task_reminders FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM public.tasks t
            WHERE t.id = task_id AND t.user_id = (SELECT auth.uid())
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.tasks t
            WHERE t.id = task_id AND t.user_id = (SELECT auth.uid())
        )
    );

-- Statistik tugas untuk dashboard; memakai auth.uid() agar aman di bawah RLS.
CREATE OR REPLACE FUNCTION public.get_task_statistics()
RETURNS JSON AS $$
DECLARE
    result JSON;
BEGIN
    SELECT json_build_object(
        'total_active', COUNT(*) FILTER (
            WHERE status != 'completed' AND is_deleted = FALSE
        ),
        'completed_total', COUNT(*) FILTER (
            WHERE status = 'completed' AND is_deleted = FALSE
        ),
        'completed_this_week', COUNT(*) FILTER (
            WHERE status = 'completed'
              AND is_deleted = FALSE
              AND completed_at >= date_trunc('week', NOW())
        ),
        'overdue', COUNT(*) FILTER (
            WHERE status != 'completed'
              AND is_deleted = FALSE
              AND deadline < NOW()
        )
    ) INTO result
    FROM public.tasks
    WHERE user_id = auth.uid();

    RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY INVOKER SET search_path = public;
