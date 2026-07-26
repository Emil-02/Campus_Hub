-- T-009: Data mata kuliah milik user.
CREATE TABLE public.courses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    name VARCHAR(200) NOT NULL,
    code VARCHAR(20),
    credits INTEGER CHECK (credits >= 1 AND credits <= 6),
    lecturer VARCHAR(200),
    color VARCHAR(7) NOT NULL DEFAULT '#4A90D9',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_courses_user_id ON public.courses(user_id);
