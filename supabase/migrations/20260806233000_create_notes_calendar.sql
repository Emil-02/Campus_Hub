-- T-015/T-016/T-017: Catatan (dengan pencarian), gambar/link catatan, dan event kalender.

CREATE TABLE public.notes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    course_id UUID REFERENCES public.courses(id) ON DELETE SET NULL,
    title VARCHAR(300) NOT NULL,
    content TEXT,
    content_plain TEXT,
    is_deleted BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_notes_user_id ON public.notes(user_id);
CREATE INDEX idx_notes_user_course ON public.notes(user_id, course_id)
    WHERE is_deleted = FALSE;
-- Konfigurasi 'indonesian' tidak tersedia di Postgres; 'simple' cukup untuk MVP.
CREATE INDEX idx_notes_search ON public.notes USING gin(
    to_tsvector(
        'simple',
        COALESCE(title, '') || ' ' || COALESCE(content_plain, '')
    )
);

ALTER TABLE public.notes ENABLE ROW LEVEL SECURITY;

CREATE POLICY notes_select_own
    ON public.notes FOR SELECT
    USING (user_id = (SELECT auth.uid()));

CREATE POLICY notes_insert_own
    ON public.notes FOR INSERT
    WITH CHECK (user_id = (SELECT auth.uid()));

CREATE POLICY notes_update_own
    ON public.notes FOR UPDATE
    USING (user_id = (SELECT auth.uid()))
    WITH CHECK (user_id = (SELECT auth.uid()));

CREATE POLICY notes_delete_own
    ON public.notes FOR DELETE
    USING (user_id = (SELECT auth.uid()));

CREATE TRIGGER update_notes_updated_at
    BEFORE UPDATE ON public.notes
    FOR EACH ROW
    EXECUTE FUNCTION public.update_updated_at_column();

-- Lampiran gambar catatan (UI menyusul; tabel disiapkan untuk kompatibilitas).
CREATE TABLE public.note_images (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    note_id UUID NOT NULL REFERENCES public.notes(id) ON DELETE CASCADE,
    url TEXT NOT NULL,
    file_name VARCHAR(255),
    file_size INTEGER CHECK (file_size <= 5242880),
    mime_type VARCHAR(50) CHECK (
        mime_type IN ('image/jpeg', 'image/png', 'image/webp')
    ),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_note_images_note_id ON public.note_images(note_id);

ALTER TABLE public.note_images ENABLE ROW LEVEL SECURITY;

CREATE POLICY note_images_all_own
    ON public.note_images FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM public.notes n
            WHERE n.id = note_id AND n.user_id = (SELECT auth.uid())
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.notes n
            WHERE n.id = note_id AND n.user_id = (SELECT auth.uid())
        )
    );

-- Tautan eksternal catatan (Google Drive dsb.).
CREATE TYPE link_type AS ENUM ('google_drive', 'external', 'other');

CREATE TABLE public.note_links (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    note_id UUID NOT NULL REFERENCES public.notes(id) ON DELETE CASCADE,
    url TEXT NOT NULL,
    title VARCHAR(300),
    link_type link_type NOT NULL DEFAULT 'other',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_note_links_note_id ON public.note_links(note_id);

ALTER TABLE public.note_links ENABLE ROW LEVEL SECURITY;

CREATE POLICY note_links_all_own
    ON public.note_links FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM public.notes n
            WHERE n.id = note_id AND n.user_id = (SELECT auth.uid())
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.notes n
            WHERE n.id = note_id AND n.user_id = (SELECT auth.uid())
        )
    );

-- Event kalender kustom di luar deadline tugas.
CREATE TYPE event_type AS ENUM (
    'academic', 'personal', 'organization', 'exam', 'holiday'
);

CREATE TABLE public.calendar_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    title VARCHAR(300) NOT NULL,
    description TEXT,
    event_date DATE NOT NULL,
    event_time TIME,
    color VARCHAR(7) DEFAULT '#4A90D9',
    event_type event_type NOT NULL DEFAULT 'personal',
    is_all_day BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_calendar_events_user_id ON public.calendar_events(user_id);
CREATE INDEX idx_calendar_events_user_date
    ON public.calendar_events(user_id, event_date);

ALTER TABLE public.calendar_events ENABLE ROW LEVEL SECURITY;

CREATE POLICY calendar_events_select_own
    ON public.calendar_events FOR SELECT
    USING (user_id = (SELECT auth.uid()));

CREATE POLICY calendar_events_insert_own
    ON public.calendar_events FOR INSERT
    WITH CHECK (user_id = (SELECT auth.uid()));

CREATE POLICY calendar_events_update_own
    ON public.calendar_events FOR UPDATE
    USING (user_id = (SELECT auth.uid()))
    WITH CHECK (user_id = (SELECT auth.uid()));

CREATE POLICY calendar_events_delete_own
    ON public.calendar_events FOR DELETE
    USING (user_id = (SELECT auth.uid()));

CREATE TRIGGER update_calendar_events_updated_at
    BEFORE UPDATE ON public.calendar_events
    FOR EACH ROW
    EXECUTE FUNCTION public.update_updated_at_column();
