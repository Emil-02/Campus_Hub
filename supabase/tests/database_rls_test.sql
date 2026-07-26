-- Development-only RLS and function privilege checks.
-- Run with a Supabase development database and rollback all changes at the end.
BEGIN;

CREATE TEMP TABLE rls_test_ids (
    user_a UUID NOT NULL,
    user_b UUID NOT NULL,
    course_a UUID,
    course_b UUID,
    course_delete_a UUID,
    schedule_a UUID,
    schedule_b UUID,
    reminder_a UUID
);

INSERT INTO rls_test_ids (user_a, user_b)
SELECT
    (SELECT id FROM auth.users ORDER BY id OFFSET 0 LIMIT 1),
    (SELECT id FROM auth.users ORDER BY id OFFSET 1 LIMIT 1);

DO $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM rls_test_ids
        WHERE user_a IS NULL OR user_b IS NULL
    ) THEN
        RAISE EXCEPTION 'Two development auth.users rows are required for RLS tests';
    END IF;
END;
$$;

GRANT SELECT, INSERT, UPDATE, DELETE ON rls_test_ids TO authenticated, anon;

-- User A: own course CRUD and ownership-protected delete target.
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub', user_a::TEXT, true)
FROM rls_test_ids;

WITH inserted AS (
    INSERT INTO public.courses (user_id, name)
    SELECT user_a, 'RLS Course A'
    FROM rls_test_ids
    RETURNING id
)
UPDATE rls_test_ids
SET course_a = inserted.id
FROM inserted;

WITH inserted AS (
    INSERT INTO public.courses (user_id, name)
    SELECT user_a, 'RLS Course Delete A'
    FROM rls_test_ids
    RETURNING id
)
UPDATE rls_test_ids
SET course_delete_a = inserted.id
FROM inserted;

DO $$
DECLARE
    own_courses INTEGER;
BEGIN
    SELECT COUNT(*) INTO own_courses
    FROM public.courses
    WHERE user_id = (SELECT user_a FROM rls_test_ids);
    IF own_courses < 2 THEN
        RAISE EXCEPTION 'User A cannot select own courses';
    END IF;
END;
$$;

UPDATE public.courses
SET name = 'RLS Course A Updated'
WHERE id = (SELECT course_a FROM rls_test_ids);

DELETE FROM public.courses
WHERE id = (SELECT course_delete_a FROM rls_test_ids);

-- User B: cannot read, update, delete, or spoof User A's course ownership.
RESET ROLE;
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub', user_b::TEXT, true)
FROM rls_test_ids;

DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM public.courses
        WHERE id = (SELECT course_a FROM rls_test_ids)
    ) THEN
        RAISE EXCEPTION 'User B can read User A course';
    END IF;
END;
$$;

DO $$
BEGIN
    UPDATE public.courses
    SET name = 'Unauthorized update'
    WHERE id = (SELECT course_a FROM rls_test_ids);
    IF FOUND THEN
        RAISE EXCEPTION 'User B updated User A course';
    END IF;

    DELETE FROM public.courses
    WHERE id = (SELECT course_a FROM rls_test_ids);
    IF FOUND THEN
        RAISE EXCEPTION 'User B deleted User A course';
    END IF;
END;
$$;

DO $$
BEGIN
    BEGIN
        INSERT INTO public.courses (user_id, name)
        SELECT user_a, 'Spoofed Course'
        FROM rls_test_ids;
        RAISE EXCEPTION 'User B inserted a course for User A';
    EXCEPTION WHEN insufficient_privilege THEN
        NULL;
    END;
END;
$$;

-- User B creates a course of their own for cross-owner schedule tests.
WITH inserted AS (
    INSERT INTO public.courses (user_id, name)
    SELECT user_b, 'RLS Course B'
    FROM rls_test_ids
    RETURNING id
)
UPDATE rls_test_ids
SET course_b = inserted.id
FROM inserted;

-- User A can create a schedule only for User A's course.
RESET ROLE;
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub', user_a::TEXT, true)
FROM rls_test_ids;

WITH inserted AS (
    INSERT INTO public.schedules (
        user_id, course_id, day_of_week, start_time, end_time
    )
    SELECT user_a, course_a, 1, TIME '09:00', TIME '10:00'
    FROM rls_test_ids
    RETURNING id
)
UPDATE rls_test_ids
SET schedule_a = inserted.id
FROM inserted;

DO $$
BEGIN
    BEGIN
        INSERT INTO public.schedules (
            user_id, course_id, day_of_week, start_time, end_time
        )
        SELECT user_a, course_b, 1, TIME '10:00', TIME '11:00'
        FROM rls_test_ids;
        RAISE EXCEPTION 'User A used User B course';
    EXCEPTION WHEN insufficient_privilege THEN
        NULL;
    END;
END;
$$;

DO $$
BEGIN
    BEGIN
        UPDATE public.schedules
        SET user_id = (SELECT user_b FROM rls_test_ids)
        WHERE id = (SELECT schedule_a FROM rls_test_ids);
        RAISE EXCEPTION 'User A transferred schedule ownership';
    EXCEPTION WHEN insufficient_privilege THEN
        NULL;
    END;

    BEGIN
        UPDATE public.schedules
        SET course_id = (SELECT course_b FROM rls_test_ids)
        WHERE id = (SELECT schedule_a FROM rls_test_ids);
        RAISE EXCEPTION 'User A moved schedule to User B course';
    EXCEPTION WHEN insufficient_privilege THEN
        NULL;
    END;
END;
$$;

-- User B cannot read User A schedule and cannot use User A course.
RESET ROLE;
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub', user_b::TEXT, true)
FROM rls_test_ids;

DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM public.schedules
        WHERE id = (SELECT schedule_a FROM rls_test_ids)
    ) THEN
        RAISE EXCEPTION 'User B can read User A schedule';
    END IF;

    BEGIN
        INSERT INTO public.schedules (
            user_id, course_id, day_of_week, start_time, end_time
        )
        SELECT user_b, course_a, 2, TIME '09:00', TIME '10:00'
        FROM rls_test_ids;
        RAISE EXCEPTION 'User B used User A course';
    EXCEPTION WHEN insufficient_privilege THEN
        NULL;
    END;
END;
$$;

-- User B creates their own schedule for reminder ownership tests.
WITH inserted AS (
    INSERT INTO public.schedules (
        user_id, course_id, day_of_week, start_time, end_time
    )
    SELECT user_b, course_b, 2, TIME '09:00', TIME '10:00'
    FROM rls_test_ids
    RETURNING id
)
UPDATE rls_test_ids
SET schedule_b = inserted.id
FROM inserted;

-- User A can create a reminder only for User A's schedule.
RESET ROLE;
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub', user_a::TEXT, true)
FROM rls_test_ids;

WITH inserted AS (
    INSERT INTO public.schedule_reminders (schedule_id, minutes_before)
    SELECT schedule_a, 15
    FROM rls_test_ids
    RETURNING id
)
UPDATE rls_test_ids
SET reminder_a = inserted.id
FROM inserted;

DO $$
BEGIN
    BEGIN
        INSERT INTO public.schedule_reminders (schedule_id, minutes_before)
        SELECT schedule_b, 15
        FROM rls_test_ids;
        RAISE EXCEPTION 'User A created reminder for User B schedule';
    EXCEPTION WHEN insufficient_privilege THEN
        NULL;
    END;

    BEGIN
        UPDATE public.schedule_reminders
        SET schedule_id = (SELECT schedule_b FROM rls_test_ids)
        WHERE id = (SELECT reminder_a FROM rls_test_ids);
        RAISE EXCEPTION 'User A moved reminder to User B schedule';
    EXCEPTION WHEN insufficient_privilege THEN
        NULL;
    END;
END;
$$;

-- User B cannot read, update, or delete User A reminder.
RESET ROLE;
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub', user_b::TEXT, true)
FROM rls_test_ids;

DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM public.schedule_reminders
        WHERE id = (SELECT reminder_a FROM rls_test_ids)
    ) THEN
        RAISE EXCEPTION 'User B can read User A reminder';
    END IF;
END;
$$;

DO $$
BEGIN
    UPDATE public.schedule_reminders
    SET minutes_before = 30
    WHERE id = (SELECT reminder_a FROM rls_test_ids);
    IF FOUND THEN
        RAISE EXCEPTION 'User B updated User A reminder';
    END IF;

    DELETE FROM public.schedule_reminders
    WHERE id = (SELECT reminder_a FROM rls_test_ids);
    IF FOUND THEN
        RAISE EXCEPTION 'User B deleted User A reminder';
    END IF;
END;
$$;

-- Conflict RPC: own schedule is visible; another user ID is rejected.
RESET ROLE;
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub', user_a::TEXT, true)
FROM rls_test_ids;

DO $$
DECLARE
    own_conflicts INTEGER;
    other_conflicts INTEGER;
BEGIN
    SELECT COUNT(*) INTO own_conflicts
    FROM public.check_schedule_conflict(
        (SELECT user_a FROM rls_test_ids),
        1,
        TIME '09:00',
        TIME '10:00'
    );
    IF own_conflicts <> 1 THEN
        RAISE EXCEPTION 'User A cannot inspect own schedule conflicts';
    END IF;

    SELECT COUNT(*) INTO other_conflicts
    FROM public.check_schedule_conflict(
        (SELECT user_b FROM rls_test_ids),
        1,
        TIME '09:00',
        TIME '10:00'
    );
    IF other_conflicts <> 0 THEN
        RAISE EXCEPTION 'User A inspected User B schedule conflicts';
    END IF;
END;
$$;

-- Anonymous callers have no EXECUTE privilege on the conflict RPC.
RESET ROLE;
SET LOCAL ROLE anon;

DO $$
BEGIN
    BEGIN
        PERFORM 1
        FROM public.check_schedule_conflict(
            gen_random_uuid(), 1, TIME '09:00', TIME '10:00'
        );
        RAISE EXCEPTION 'anon can execute check_schedule_conflict';
    EXCEPTION WHEN insufficient_privilege THEN
        NULL;
    END;
END;
$$;

ROLLBACK;
