BEGIN;

CREATE EXTENSION IF NOT EXISTS pgtap WITH SCHEMA extensions;

SELECT plan(17);

INSERT INTO auth.users (id, email)
VALUES
    ('10000000-0000-4000-8000-000000000001', 'tenant-one@example.test'),
    ('20000000-0000-4000-8000-000000000002', 'tenant-two@example.test');

INSERT INTO public.tasks (id, project_id, user_id, title)
SELECT
    '11000000-0000-4000-8000-000000000001', id,
    '10000000-0000-4000-8000-000000000001', 'Tenant one task'
FROM public.projects
WHERE user_id = '10000000-0000-4000-8000-000000000001' AND is_inbox;

INSERT INTO public.tasks (id, project_id, user_id, title)
SELECT
    '22000000-0000-4000-8000-000000000002', id,
    '20000000-0000-4000-8000-000000000002', 'Tenant two task'
FROM public.projects
WHERE user_id = '20000000-0000-4000-8000-000000000002' AND is_inbox;

SELECT lives_ok(
    $$INSERT INTO public.tasks (project_id, user_id, parent_id, title)
      SELECT id, '10000000-0000-4000-8000-000000000001',
             '11000000-0000-4000-8000-000000000001', 'Valid subtask'
      FROM public.projects
      WHERE user_id = '10000000-0000-4000-8000-000000000001' AND is_inbox$$,
    'same-tenant project and parent are accepted'
);

SELECT throws_ok(
    $$INSERT INTO public.tasks (project_id, user_id, title)
      SELECT id, '10000000-0000-4000-8000-000000000001', 'Cross-project task'
      FROM public.projects
      WHERE user_id = '20000000-0000-4000-8000-000000000002' AND is_inbox$$,
    '23503', NULL, 'cross-tenant project is rejected'
);

SELECT throws_ok(
    $$INSERT INTO public.tasks (project_id, user_id, parent_id, title)
      SELECT id, '10000000-0000-4000-8000-000000000001',
             '22000000-0000-4000-8000-000000000002', 'Cross-parent task'
      FROM public.projects
      WHERE user_id = '10000000-0000-4000-8000-000000000001' AND is_inbox$$,
    '23503', NULL, 'cross-tenant parent is rejected'
);

SELECT throws_ok(
    $$INSERT INTO public.tasks
        (project_id, user_id, recurrence_parent_id, title)
      SELECT id, '10000000-0000-4000-8000-000000000001',
             '22000000-0000-4000-8000-000000000002', 'Cross-series task'
      FROM public.projects
      WHERE user_id = '10000000-0000-4000-8000-000000000001' AND is_inbox$$,
    '23503', NULL, 'cross-tenant recurrence parent is rejected'
);

SELECT lives_ok(
    $$INSERT INTO public.comments (task_id, user_id, content)
      VALUES ('11000000-0000-4000-8000-000000000001',
              '10000000-0000-4000-8000-000000000001', 'Valid comment')$$,
    'same-tenant comment is accepted'
);

SELECT throws_ok(
    $$INSERT INTO public.comments (task_id, user_id, content)
      VALUES ('22000000-0000-4000-8000-000000000002',
              '10000000-0000-4000-8000-000000000001', 'Cross comment')$$,
    '23503', NULL, 'cross-tenant comment task is rejected'
);

SELECT throws_ok(
    $$UPDATE public.tasks
      SET project_id = (SELECT id FROM public.projects
                        WHERE user_id = '20000000-0000-4000-8000-000000000002'
                          AND is_inbox)
      WHERE id = '11000000-0000-4000-8000-000000000001'$$,
    '23503', NULL, 'moving a task to another tenant project is rejected'
);

SELECT throws_ok(
    $$UPDATE public.tasks
      SET parent_id = '22000000-0000-4000-8000-000000000002'
      WHERE id = '11000000-0000-4000-8000-000000000001'$$,
    '23503', NULL, 'updating a task to another tenant parent is rejected'
);

SELECT throws_ok(
    $$UPDATE public.comments
      SET task_id = '22000000-0000-4000-8000-000000000002'
      WHERE user_id = '10000000-0000-4000-8000-000000000001'$$,
    '23503', NULL, 'moving a comment to another tenant task is rejected'
);

SELECT lives_ok(
    $$INSERT INTO public.tasks (project_id, user_id, parent_id,
                                recurrence_parent_id, title)
      SELECT id, '10000000-0000-4000-8000-000000000001', NULL, NULL,
             'Nullable relations'
      FROM public.projects
      WHERE user_id = '10000000-0000-4000-8000-000000000001' AND is_inbox$$,
    'nullable parent and recurrence parent remain accepted'
);

SELECT throws_ok(
    $$UPDATE public.tasks
      SET user_id = '20000000-0000-4000-8000-000000000002'
      WHERE id = '11000000-0000-4000-8000-000000000001'$$,
    '23503', NULL, 'changing task ownership across its project is rejected'
);

SELECT throws_ok(
    $$UPDATE public.projects
      SET user_id = '20000000-0000-4000-8000-000000000002'
      WHERE id = (SELECT project_id FROM public.tasks
                  WHERE id = '11000000-0000-4000-8000-000000000001')$$,
    '23503', NULL, 'changing project ownership away from its tasks is rejected'
);

SELECT throws_ok(
    $$UPDATE public.comments
      SET user_id = '20000000-0000-4000-8000-000000000002'
      WHERE task_id = '11000000-0000-4000-8000-000000000001'$$,
    '23503', NULL, 'changing comment ownership away from its task is rejected'
);

INSERT INTO public.tasks (id, project_id, user_id, title)
SELECT '13000000-0000-4000-8000-000000000003', id,
       '10000000-0000-4000-8000-000000000001', 'Recurrence parent'
FROM public.projects
WHERE user_id = '10000000-0000-4000-8000-000000000001' AND is_inbox;

INSERT INTO public.tasks
    (id, project_id, user_id, recurrence_parent_id, title)
SELECT '14000000-0000-4000-8000-000000000004', id,
       '10000000-0000-4000-8000-000000000001',
       '13000000-0000-4000-8000-000000000003', 'Occurrence'
FROM public.projects
WHERE user_id = '10000000-0000-4000-8000-000000000001' AND is_inbox;

DELETE FROM public.tasks
WHERE id = '13000000-0000-4000-8000-000000000003';

SELECT is(
    (SELECT recurrence_parent_id FROM public.tasks
     WHERE id = '14000000-0000-4000-8000-000000000004'),
    NULL::UUID,
    'deleting a recurrence parent still sets the relation to null'
);

INSERT INTO public.tasks (id, project_id, user_id, parent_id, title)
SELECT '15000000-0000-4000-8000-000000000005', project_id, user_id,
       id, 'Cascade child'
FROM public.tasks
WHERE id = '14000000-0000-4000-8000-000000000004';

DELETE FROM public.tasks
WHERE id = '14000000-0000-4000-8000-000000000004';

SELECT is(
    (SELECT COUNT(*) FROM public.tasks
     WHERE id = '15000000-0000-4000-8000-000000000005'),
    0::BIGINT,
    'deleting a parent still cascades to its subtasks'
);

INSERT INTO public.tasks (id, project_id, user_id, title)
SELECT '16000000-0000-4000-8000-000000000006', id,
       '10000000-0000-4000-8000-000000000001', 'Commented task'
FROM public.projects
WHERE user_id = '10000000-0000-4000-8000-000000000001' AND is_inbox;

INSERT INTO public.comments (id, task_id, user_id, content)
VALUES ('17000000-0000-4000-8000-000000000007',
        '16000000-0000-4000-8000-000000000006',
        '10000000-0000-4000-8000-000000000001', 'Cascade comment');

DELETE FROM public.tasks
WHERE id = '16000000-0000-4000-8000-000000000006';

SELECT is(
    (SELECT COUNT(*) FROM public.comments
     WHERE id = '17000000-0000-4000-8000-000000000007'),
    0::BIGINT,
    'deleting a task still cascades to its comments'
);

INSERT INTO public.projects (id, user_id, name)
VALUES ('18000000-0000-4000-8000-000000000008',
        '10000000-0000-4000-8000-000000000001', 'Cascade project');
INSERT INTO public.tasks (id, project_id, user_id, title)
VALUES ('19000000-0000-4000-8000-000000000009',
        '18000000-0000-4000-8000-000000000008',
        '10000000-0000-4000-8000-000000000001', 'Project task');

DELETE FROM public.projects
WHERE id = '18000000-0000-4000-8000-000000000008';

SELECT is(
    (SELECT COUNT(*) FROM public.tasks
     WHERE id = '19000000-0000-4000-8000-000000000009'),
    0::BIGINT,
    'deleting a project still cascades to its tasks'
);

SELECT * FROM finish();
ROLLBACK;
