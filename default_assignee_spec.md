# Spec v5: Default Assignee por Proyecto

## 1. Modelo

BD: columna `default_assignee TEXT NOT NULL DEFAULT 'manuel'` en tabla `projects`
Constraint: `CHECK (default_assignee IN ('manuel', 'hermes'))`

| Valor | Significado |
|-------|-------------|
| `manuel` | 👤 Humano (default global) |
| `hermes` | 🤖 Hermes |

## 2. Capas (orden)

### 2a. Migration SQL → `013_add_default_assignee.sql`
```sql
ALTER TABLE public.projects
ADD COLUMN default_assignee TEXT NOT NULL DEFAULT 'manuel';
CREATE INDEX IF NOT EXISTS idx_projects_default_assignee ON public.projects(default_assignee);
ALTER TABLE public.projects
ADD CONSTRAINT valid_default_assignee CHECK (default_assignee IN ('manuel', 'hermes'));
```

### 2b. Edge Function `mcp-api/index.ts`
- Añadir `defaultAssignee?: string` al body de `createProject` y `updateProject`
- Validar valores permitidos
- En el SELECT de projects, devolver `default_assignee`

### 2c. MCP Worker `api-client.ts`
- Añadir `defaultAssignee: string` a la interfaz `Project`
- Añadir `defaultAssignee?: string` a `createProject()` params
- Añadir `defaultAssignee?: string` a `updateProject()` params

### 2d. MCP Worker `index.ts`
- Añadir `defaultAssignee` opcional a inputSchema de `create_project` y `update_project`
- Devolver `default_assignee` en `get_project` y `list_projects`

### 2e. Modelo Flutter → `project.dart`
```dart
@JsonKey(name: 'default_assignee') @Default('manuel') String defaultAssignee,
```
Y regenerar `.freezed.dart` y `.g.dart`.

### 2f. Provider de proyectos
Añadir `defaultAssignee` a create/update en el notifier de proyectos.

### 2g. UI → `project_form.dart`
Añadir selector de default_assignee (👤 Manuel / 🤖 Hermes).

Necesito leer `project_form.dart` para ver su estructura actual.

### 2h. Lógica en `task_form.dart`
Al crear tarea: si el proyecto seleccionado tiene `default_assignee`, usar ese valor como `_assignedTo` inicial. Si el usuario lo cambia manualmente, respetar su elección.

## 3. Valores por defecto tras migración
Aplicar manualmente en Supabase:
```sql
UPDATE public.projects SET default_assignee = 'hermes' WHERE name LIKE 'Hermes%';
```
(O desde la UI al editar cada proyecto)

## 4. Tests + Deploy + Git
```bash
$HOME/development/flutter-3.44.1/bin/flutter test --dart-define-from-file=public-config.local.json
# luego deploy-taskboi
```
