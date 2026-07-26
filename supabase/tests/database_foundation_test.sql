-- Development-only database foundation checks.
-- The transaction is rolled back so no test data persists.
BEGIN;

DO $$
DECLARE
    test_user_id UUID;
    test_course_id UUID;
    test_schedule_id UUID;
    test_reminder_schedule_id UUID;
    test_reminder_id UUID;
    conflict_count INTEGER;
    default_color VARCHAR;
BEGIN
    SELECT id INTO test_user_id FROM auth.users LIMIT 1;
    IF test_user_id IS NULL THEN
        RAISE EXCEPTION 'A development auth.users row is required for these tests';
    END IF;

    -- Courses: valid insert, default color, and credits bounds.
    INSERT INTO public.courses (user_id, name)
    VALUES (test_user_id, 'Database Foundation Test')
    RETURNING id INTO test_course_id;

    SELECT color INTO default_color
    FROM public.courses
    WHERE id = test_course_id;
    ASSERT default_color = '#4A90D9', 'courses.color default is incorrect';

    UPDATE public.courses
    SET updated_at = TIMESTAMPTZ '2000-01-01 00:00:00+00'
    WHERE id = test_course_id;
    ASSERT (
        SELECT updated_at > TIMESTAMPTZ '2000-01-01 00:00:00+00'
        FROM public.courses
        WHERE id = test_course_id
    ), 'courses.updated_at trigger did not run';

    BEGIN
        INSERT INTO public.courses (user_id, name, credits)
        VALUES (test_user_id, 'Invalid Credits Low', 0);
        RAISE EXCEPTION 'credits below 1 was accepted';
    EXCEPTION WHEN check_violation THEN
        NULL;
    END;

    BEGIN
        INSERT INTO public.courses (user_id, name, credits)
        VALUES (test_user_id, 'Invalid Credits High', 7);
        RAISE EXCEPTION 'credits above 6 was accepted';
    EXCEPTION WHEN check_violation THEN
        NULL;
    END;

    -- Schedules: boundary days and time-range validation.
    INSERT INTO public.schedules (
        user_id, course_id, day_of_week, start_time, end_time
    ) VALUES (
        test_user_id, test_course_id, 1, TIME '09:00', TIME '10:00'
    ) RETURNING id INTO test_schedule_id;

    UPDATE public.schedules
    SET updated_at = TIMESTAMPTZ '2000-01-01 00:00:00+00'
    WHERE id = test_schedule_id;
    ASSERT (
        SELECT updated_at > TIMESTAMPTZ '2000-01-01 00:00:00+00'
        FROM public.schedules
        WHERE id = test_schedule_id
    ), 'schedules.updated_at trigger did not run';

    INSERT INTO public.schedules (
        user_id, course_id, day_of_week, start_time, end_time
    ) VALUES (
        test_user_id, test_course_id, 7, TIME '11:00', TIME '12:00'
    );

    BEGIN
        INSERT INTO public.schedules (
            user_id, course_id, day_of_week, start_time, end_time
        ) VALUES (
            test_user_id, test_course_id, 0, TIME '13:00', TIME '14:00'
        );
        RAISE EXCEPTION 'day_of_week 0 was accepted';
    EXCEPTION WHEN check_violation THEN
        NULL;
    END;

    BEGIN
        INSERT INTO public.schedules (
            user_id, course_id, day_of_week, start_time, end_time
        ) VALUES (
            test_user_id, test_course_id, 8, TIME '13:00', TIME '14:00'
        );
        RAISE EXCEPTION 'day_of_week 8 was accepted';
    EXCEPTION WHEN check_violation THEN
        NULL;
    END;

    BEGIN
        INSERT INTO public.schedules (
            user_id, course_id, day_of_week, start_time, end_time
        ) VALUES (
            test_user_id, test_course_id, 1, TIME '14:00', TIME '14:00'
        );
        RAISE EXCEPTION 'equal start and end times were accepted';
    EXCEPTION WHEN check_violation THEN
        NULL;
    END;

    BEGIN
        INSERT INTO public.schedules (
            user_id, course_id, day_of_week, start_time, end_time
        ) VALUES (
            test_user_id, test_course_id, 1, TIME '15:00', TIME '14:00'
        );
        RAISE EXCEPTION 'end time before start time was accepted';
    EXCEPTION WHEN check_violation THEN
        NULL;
    END;

    -- Conflict function: identical, partial, and wrapping overlaps conflict.
    SELECT COUNT(*) INTO conflict_count
    FROM public.check_schedule_conflict(
        test_user_id, 1, TIME '09:00', TIME '10:00'
    );
    ASSERT conflict_count = 1, 'identical schedule did not conflict';

    SELECT COUNT(*) INTO conflict_count
    FROM public.check_schedule_conflict(
        test_user_id, 1, TIME '09:30', TIME '10:30'
    );
    ASSERT conflict_count = 1, 'partial overlap did not conflict';

    SELECT COUNT(*) INTO conflict_count
    FROM public.check_schedule_conflict(
        test_user_id, 1, TIME '08:00', TIME '11:00'
    );
    ASSERT conflict_count = 1, 'wrapping overlap did not conflict';

    -- Touching boundaries, different day, and different user do not conflict.
    SELECT COUNT(*) INTO conflict_count
    FROM public.check_schedule_conflict(
        test_user_id, 1, TIME '10:00', TIME '11:00'
    );
    ASSERT conflict_count = 0, 'touching schedules conflicted';

    SELECT COUNT(*) INTO conflict_count
    FROM public.check_schedule_conflict(
        test_user_id, 2, TIME '09:00', TIME '10:00'
    );
    ASSERT conflict_count = 0, 'different day conflicted';

    SELECT COUNT(*) INTO conflict_count
    FROM public.check_schedule_conflict(
        gen_random_uuid(), 1, TIME '09:00', TIME '10:00'
    );
    ASSERT conflict_count = 0, 'different user conflicted';

    SELECT COUNT(*) INTO conflict_count
    FROM public.check_schedule_conflict(
        test_user_id, 1, TIME '09:00', TIME '10:00', test_schedule_id
    );
    ASSERT conflict_count = 0, 'excluded schedule still conflicted';

    INSERT INTO public.schedules (
        user_id, course_id, day_of_week, start_time, end_time, is_active
    ) VALUES (
        test_user_id, test_course_id, 1, TIME '11:00', TIME '12:00', FALSE
    );

    SELECT COUNT(*) INTO conflict_count
    FROM public.check_schedule_conflict(
        test_user_id, 1, TIME '11:00', TIME '12:00'
    );
    ASSERT conflict_count = 0, 'inactive schedule conflicted';

    -- Reminders: positive values are accepted, non-positive values are rejected.
    INSERT INTO public.schedules (
        user_id, course_id, day_of_week, start_time, end_time
    ) VALUES (
        test_user_id, test_course_id, 3, TIME '13:00', TIME '14:00'
    ) RETURNING id INTO test_reminder_schedule_id;

    INSERT INTO public.schedule_reminders (schedule_id, minutes_before)
    VALUES (test_reminder_schedule_id, 15)
    RETURNING id INTO test_reminder_id;

    ASSERT test_reminder_id IS NOT NULL, 'positive reminder was not inserted';

    BEGIN
        INSERT INTO public.schedule_reminders (schedule_id, minutes_before)
        VALUES (test_reminder_schedule_id, 0);
        RAISE EXCEPTION 'zero minutes_before was accepted';
    EXCEPTION WHEN check_violation THEN
        NULL;
    END;

    BEGIN
        INSERT INTO public.schedule_reminders (schedule_id, minutes_before)
        VALUES (test_reminder_schedule_id, -15);
        RAISE EXCEPTION 'negative minutes_before was accepted';
    EXCEPTION WHEN check_violation THEN
        NULL;
    END;

    DELETE FROM public.schedules WHERE id = test_reminder_schedule_id;
    ASSERT NOT EXISTS (
        SELECT 1 FROM public.schedule_reminders WHERE id = test_reminder_id
    ), 'schedule reminder was not cascade-deleted';
END;
$$;

ROLLBACK;
