# Spec v4: Sistema de Asignación + Webhook

## 1. Modelo de datos

Valores: `manuel` (default) | `hermes`

| Valor | Icono | Quién |
|-------|-------|-------|
| `manuel` | 👤 | Humano (default) |
| `hermes` | 🤖 | Hermes (yo) |

BD: columna `assigned_to` con constraint y default — **ya hecho** ✅

## 2. UI (implementa Claude)

### TaskForm
ActionChip selector: `[👤 Manuel ▼]` → bottom sheet con 2 opciones

### TaskTile (menú contextual)
"Assign to..." → bottom sheet 👤 🤖

### TaskDetailSheet
Mostrar assignee actual y permitir cambiar.

## 3. Webhook en tiempo real (implementa Claude + configuro yo)

### 3a. Edge Function en Supabase (`notify-assignee`)
Cuando se INSERT o UPDATE una task con `assigned_to = 'hermes'`, la función:
- Toma los datos de la tarea (título, proyecto, prioridad)
- Envía una notificación a Telegram via Bot API: `"🤖 Nueva tarea asignada: X (urgente)"` si es urgente, o solo `"Nueva tarea asignada: X"` si es normal

Esto evita tener que exponer un endpoint de Hermes — la Edge Function habla directamente con Telegram.

### 3b. Database Webhook en Supabase
En el dashboard de Supabase, configurar:
- **Tabla:** `tasks`
- **Eventos:** INSERT, UPDATE (solo cuando `assigned_to` cambie)
- **Endpoint:** la Edge Function `notify-assignee`
- Esto se configura desde la UI de Supabase, no requiere código.

### 3c. Conciencia en sesión
Si en medio de una conversación dices "tengo algo para ti", consulto `get_my_tasks` directamente.

## 4. Orden de implementación

| Paso | Qué | Quién |
|------|-----|-------|
| 1 | Provider + Formulario + Menú + DetailSheet | Claude |
| 2 | Edge Function `notify-assignee` para Telegram | Claude |
| 3 | Tests + Deploy Taskboi | Claude |
| 4 | Configurar Database Webhook en Supabase dashboard | Manuel/Hermes |

## 5. Edge cases
- Tareas existentes → `manuel`
- Subtareas → NO heredan assignee
- Varias tareas seguidas → no spamear, agrupar
- Webhook caído → no bloquear la creación de la tarea
