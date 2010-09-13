sub fields {
#	Note: GTD database is master.
#	Todo database is slave.
#	Anything we change here is reflected back to GTD immediately.

	print <<"EOF";
 todo_id     | integer               | not null default nextval('todo_id'::text)
 category    | character varying(16) | default 'Unfiled'::character varying
 task        | character varying(60) |
 priority    | smallint              | default (3)::smallint
 desc        | text                  |
 note        | text                  |
 owner       | character varying(12) |
 private     | boolean               |
 created     | date                  | default ('now'::text)::date
 modified    | date                  | default ('now'::text)::date
 due         | date                  |
 completed   | date                  |
 palm_id     | integer               |


todo_id      - unique todo item identifier (number) (in-sync with gtd ItemId)
priority     - priority of the item (number range: 1-5, 1 == now, 2, soon, 3 normal)
palm_id      - palm pilot id
owner        - who this item is for
private      - item is private on the palm
category     - palm category

task         - keyword or project
description  - 1 line description for the task.
note         - extended notes
created      - date item was created.
modified     - date item was modified.
due          - date item is due.
completed    - date item was done.
EOF
}
