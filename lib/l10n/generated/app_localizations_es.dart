// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appName => 'Taskboi';

  @override
  String get tagline => 'Mantente organizado. Haz las cosas.';

  @override
  String get signIn => 'Iniciar Sesion';

  @override
  String get signUp => 'Registrarse';

  @override
  String get createAccount => 'Crear Cuenta';

  @override
  String get signUpToGetStarted => 'Registrate para empezar';

  @override
  String get continueWithGoogle => 'Continuar con Google';

  @override
  String get or => 'o';

  @override
  String get email => 'Correo electronico';

  @override
  String get password => 'Contrasena';

  @override
  String get confirmPassword => 'Confirmar Contrasena';

  @override
  String get nameOptional => 'Nombre (opcional)';

  @override
  String get dontHaveAccount => 'No tienes una cuenta?';

  @override
  String get alreadyHaveAccount => 'Ya tienes una cuenta?';

  @override
  String get privacyPolicy => 'Politica de Privacidad';

  @override
  String get termsOfService => 'Terminos de Servicio';

  @override
  String get accountCreatedVerifyEmail =>
      'Cuenta creada! Por favor revisa tu correo para verificar.';

  @override
  String get pleaseEnterEmail => 'Por favor ingresa tu correo';

  @override
  String get pleaseEnterValidEmail => 'Por favor ingresa un correo valido';

  @override
  String get pleaseEnterPassword => 'Por favor ingresa tu contrasena';

  @override
  String get pleaseEnterAPassword => 'Por favor ingresa una contrasena';

  @override
  String get passwordMinLength =>
      'La contrasena debe tener al menos 6 caracteres';

  @override
  String get passwordsDoNotMatch => 'Las contrasenas no coinciden';

  @override
  String get signOut => 'Cerrar sesion';

  @override
  String get signOutSubtitle => 'Salir de tu cuenta';

  @override
  String get user => 'Usuario';

  @override
  String get inbox => 'Bandeja de entrada';

  @override
  String get today => 'Hoy';

  @override
  String get tomorrow => 'Manana';

  @override
  String get upcoming => 'Proximas';

  @override
  String get thisWeekend => 'Este fin de semana';

  @override
  String get nextWeek => 'Proxima semana';

  @override
  String get projects => 'Proyectos';

  @override
  String get noProjectsYet => 'Aun no hay proyectos';

  @override
  String get createProject => 'Crear proyecto';

  @override
  String get editProject => 'Editar Proyecto';

  @override
  String get deleteProject => 'Eliminar Proyecto';

  @override
  String deleteProjectConfirmation(String projectName) {
    return 'Estas seguro de que quieres eliminar \"$projectName\"? Todas las tareas de este proyecto tambien se eliminaran.';
  }

  @override
  String get projectName => 'Nombre del proyecto';

  @override
  String get enterProjectName => 'Ingresa nombre del proyecto';

  @override
  String get pleaseEnterProjectName =>
      'Por favor ingresa un nombre de proyecto';

  @override
  String get color => 'Color';

  @override
  String get edit => 'Editar';

  @override
  String get delete => 'Eliminar';

  @override
  String get cancel => 'Cancelar';

  @override
  String get save => 'Guardar';

  @override
  String get create => 'Crear';

  @override
  String get add => 'Agregar';

  @override
  String get done => 'Listo';

  @override
  String get discardChangesTitle => 'Descartar cambios?';

  @override
  String get discardChangesMessage =>
      'Tienes cambios sin guardar. Si sales ahora, se perderan.';

  @override
  String get discard => 'Descartar';

  @override
  String get keepEditing => 'Seguir editando';

  @override
  String get settings => 'Configuracion';

  @override
  String get integrations => 'Integraciones';

  @override
  String get apiKeys => 'Claves API';

  @override
  String get mcpIntegration => 'Integracion MCP';

  @override
  String get apiKeysSubtitle => 'Integracion MCP para asistentes de IA';

  @override
  String get generateNewKey => 'Generar Nueva Clave';

  @override
  String get generateApiKey => 'Generar Clave API';

  @override
  String get mcpIntegrationDescription =>
      'Genera una clave API para conectar Taskboi con asistentes de IA como Claude o Cursor usando el Protocolo de Contexto de Modelo (MCP).';

  @override
  String get newApiKeyCreated => 'Nueva Clave API Creada';

  @override
  String get copyKeyNow => 'Copia esta clave ahora - no se mostrara de nuevo!';

  @override
  String get apiKeyCopied => 'Clave API copiada al portapapeles';

  @override
  String get apiKeyDeleted => 'Clave API eliminada';

  @override
  String get apiKeyDeleteFailed =>
      'No se pudo eliminar la clave API. Intentalo de nuevo.';

  @override
  String get dismiss => 'Descartar';

  @override
  String get noApiKeysYet => 'Aun no hay claves API';

  @override
  String get createOneToConnect => 'Crea una para conectar con clientes MCP';

  @override
  String get deleteApiKey => 'Eliminar Clave API';

  @override
  String deleteApiKeyConfirmation(String keyName) {
    return 'Estas seguro de que quieres eliminar \"$keyName\"?\n\nLas aplicaciones que usen esta clave perderan acceso.';
  }

  @override
  String get keyName => 'Nombre de la Clave';

  @override
  String get keyNameHint => 'ej., Claude Desktop, Cursor';

  @override
  String get giveKeyName =>
      'Dale un nombre a esta clave para identificarla despues.';

  @override
  String get generate => 'Generar';

  @override
  String createdDate(String date) {
    return 'Creada $date';
  }

  @override
  String lastUsedDate(String date) {
    return 'Ultimo uso $date';
  }

  @override
  String get appearance => 'Apariencia';

  @override
  String get theme => 'Tema';

  @override
  String get mode => 'Modo';

  @override
  String get light => 'Claro';

  @override
  String get dark => 'Oscuro';

  @override
  String get system => 'Sistema';

  @override
  String get language => 'Idioma';

  @override
  String get languageSubtitle => 'Elige tu idioma preferido';

  @override
  String get languageSystem => 'Sistema';

  @override
  String get languageEnglish => 'Ingles';

  @override
  String get languageSpanish => 'Espanol';

  @override
  String get data => 'Datos';

  @override
  String get exportBackup => 'Exportar Respaldo';

  @override
  String get exportBackupSubtitle =>
      'Guardar todos los datos en un archivo JSON';

  @override
  String get exporting => 'Exportando...';

  @override
  String get importBackup => 'Importar Respaldo';

  @override
  String get importBackupSubtitle => 'Restaurar datos desde un archivo JSON';

  @override
  String get importing => 'Importando...';

  @override
  String get importBackupWarning =>
      'Esto reemplazara todos tus datos existentes con los datos del respaldo. Esta accion no se puede deshacer.\n\nEstas seguro de que quieres continuar?';

  @override
  String get replaceData => 'Reemplazar Datos';

  @override
  String get backupExportedSuccessfully => 'Respaldo exportado exitosamente';

  @override
  String exportFailed(String error) {
    return 'Exportacion fallida: $error';
  }

  @override
  String importedProjectsAndTasks(int projectCount, int taskCount) {
    return 'Importados $projectCount proyectos y $taskCount tareas';
  }

  @override
  String importFailed(String error) {
    return 'Importacion fallida: $error';
  }

  @override
  String get account => 'Cuenta';

  @override
  String get deleteAccount => 'Eliminar Cuenta';

  @override
  String get deleteAccountSubtitle =>
      'Eliminar permanentemente tu cuenta y datos';

  @override
  String get couldNotOpenDeleteAccountPage =>
      'No se pudo abrir la pagina de eliminar cuenta';

  @override
  String get about => 'Acerca de';

  @override
  String get aboutTaskboi => 'Acerca de Taskboi';

  @override
  String get aboutSubtitle => 'Version, politica de privacidad y mas';

  @override
  String version(String version) {
    return 'Version $version';
  }

  @override
  String get appDescription =>
      'Una aplicacion simple y hermosa de gestion de tareas para ayudarte a mantenerte organizado y productivo.';

  @override
  String get couldNotOpenLink => 'No se pudo abrir el enlace';

  @override
  String allRightsReserved(int year) {
    return '© $year Taskboi. Todos los derechos reservados.';
  }

  @override
  String get newTask => 'Nueva Tarea';

  @override
  String get editTask => 'Editar Tarea';

  @override
  String get newSubtask => 'Nueva Subtarea';

  @override
  String get editSubtask => 'Editar Subtarea';

  @override
  String get taskName => 'Nombre de la tarea';

  @override
  String get subtaskName => 'Nombre de la subtarea';

  @override
  String get description => 'Descripcion';

  @override
  String get pleaseEnterTaskName => 'Por favor ingresa un nombre de tarea';

  @override
  String get project => 'Proyecto';

  @override
  String get dueDate => 'Fecha de vencimiento';

  @override
  String get addDueDate => 'Agregar fecha de vencimiento';

  @override
  String get date => 'Fecha';

  @override
  String get pickADate => 'Elegir una fecha';

  @override
  String get pickATime => 'Elegir hora';

  @override
  String get removeTime => 'Quitar hora';

  @override
  String get removeDateAndRecurrence => 'Eliminar fecha y recurrencia';

  @override
  String get priority => 'Prioridad';

  @override
  String get addPriority => 'Agregar prioridad';

  @override
  String get priorityUrgent => 'Urgente';

  @override
  String get priorityHigh => 'Alta';

  @override
  String get priorityNormal => 'Normal';

  @override
  String get priorityMedium => 'Media';

  @override
  String get priorityLow => 'Baja';

  @override
  String get priorityNone => 'Ninguna';

  @override
  String priorityN(int n) {
    return 'Prioridad $n';
  }

  @override
  String get deleteTask => 'Eliminar tarea';

  @override
  String get deleteSubtask => 'Eliminar subtarea';

  @override
  String deleteTaskConfirmation(String taskTitle) {
    return 'Estas seguro de que quieres eliminar \"$taskTitle\"?';
  }

  @override
  String deleteTaskWithSubtasks(String taskTitle, int subtaskCount) {
    return 'Estas seguro de que quieres eliminar \"$taskTitle\"?\n\nEsto tambien eliminara $subtaskCount subtarea(s).';
  }

  @override
  String taskDeleted(String taskTitle) {
    return '\"$taskTitle\" eliminada';
  }

  @override
  String taskCompleted(String taskTitle) {
    return '\"$taskTitle\" completada';
  }

  @override
  String taskMarkedIncomplete(String taskTitle) {
    return '\"$taskTitle\" marcada como incompleta';
  }

  @override
  String taskMovedTo(String taskTitle, String projectName) {
    return '\"$taskTitle\" movida a $projectName';
  }

  @override
  String get undo => 'Deshacer';

  @override
  String get reschedule => 'Reprogramar';

  @override
  String get moveToProject => 'Mover a Proyecto';

  @override
  String get setPriority => 'Establecer Prioridad';

  @override
  String get addSubtask => 'Agregar Subtarea';

  @override
  String get markComplete => 'Marcar Completa';

  @override
  String get markIncomplete => 'Marcar Incompleta';

  @override
  String deleteWithSubtasks(int count) {
    return 'Eliminar ($count subtareas)';
  }

  @override
  String get subtasks => 'Subtareas';

  @override
  String subtasksCount(int completed, int total) {
    return '$completed/$total';
  }

  @override
  String get addASubtask => 'Agregar una subtarea';

  @override
  String get parentTask => 'Tarea Padre';

  @override
  String get errorLoadingProjects => 'Error al cargar proyectos';

  @override
  String get comments => 'Comentarios';

  @override
  String get commentDeleted => 'Comentario eliminado';

  @override
  String get addComment => 'Agregar un comentario...';

  @override
  String get commentCreateFailed =>
      'No se pudo agregar el comentario. Inténtalo de nuevo.';

  @override
  String get commentAttachmentFailed =>
      'El comentario se agregó, pero no se pudieron subir las imágenes. Inténtalo de nuevo para terminar de agregarlas.';

  @override
  String get imagePickerFailed =>
      'No se pudo abrir el selector de imágenes. Inténtalo de nuevo.';

  @override
  String get editComment => 'Editar comentario...';

  @override
  String get sortTasks => 'Ordenar tareas';

  @override
  String get sortManual => 'Manual';

  @override
  String get sortPriority => 'Prioridad';

  @override
  String get sortDueDate => 'Fecha de vencimiento';

  @override
  String get sortTitle => 'Titulo';

  @override
  String get sortDateAdded => 'Fecha de creación';

  @override
  String get showCompleted => 'Mostrar completadas';

  @override
  String get hideCompleted => 'Ocultar completadas';

  @override
  String completedCount(int count) {
    return 'Completadas ($count)';
  }

  @override
  String get noTasksDueToday => 'No hay tareas para hoy';

  @override
  String get noUpcomingTasks => 'No hay tareas proximas';

  @override
  String get yourInboxIsEmpty => 'Tu bandeja de entrada esta vacia';

  @override
  String get noTasksInProject => 'No hay tareas en este proyecto';

  @override
  String get tapToAddTask => 'Toca + para agregar una tarea';

  @override
  String get loading => 'Cargando...';

  @override
  String error(String error) {
    return 'Error: $error';
  }

  @override
  String get recurrenceNone => 'Ninguna';

  @override
  String get recurrenceDaily => 'Diaria';

  @override
  String get recurrenceWeekly => 'Semanal';

  @override
  String get recurrenceMonthly => 'Mensual';

  @override
  String get recurrenceYearly => 'Anual';

  @override
  String get recurrenceWeekdays => 'Dias laborables';

  @override
  String recurrenceEveryNDays(int n) {
    return 'Cada $n dias';
  }

  @override
  String recurrenceEveryNWeeks(int n) {
    return 'Cada $n semanas';
  }

  @override
  String recurrenceEveryNMonths(int n) {
    return 'Cada $n meses';
  }

  @override
  String recurrenceWeeklyOn(String days) {
    return 'Semanal los $days';
  }

  @override
  String get recurring => 'Recurrente';

  @override
  String get dayMon => 'Lun';

  @override
  String get dayTue => 'Mar';

  @override
  String get dayWed => 'Mie';

  @override
  String get dayThu => 'Jue';

  @override
  String get dayFri => 'Vie';

  @override
  String get daySat => 'Sab';

  @override
  String get daySun => 'Dom';

  @override
  String get offline => 'Sin conexion';

  @override
  String get online => 'En linea';

  @override
  String get syncStatus => 'Estado de Sincronizacion';

  @override
  String syncing(int count) {
    return 'Sincronizando $count';
  }

  @override
  String get allChangesSynced => 'Todos los cambios sincronizados';

  @override
  String changesPendingSync(int count) {
    return '$count cambios pendientes de sincronizar';
  }

  @override
  String get checking => 'Verificando...';

  @override
  String get changesWillSyncWhenOnline =>
      'Los cambios se sincronizaran cuando estes en linea';

  @override
  String get noDate => 'Sin Fecha';

  @override
  String todayYesterday(String time) {
    return 'Hoy $time';
  }

  @override
  String yesterdayTime(String time) {
    return 'Ayer $time';
  }

  @override
  String get getTheApp => 'Obtener la app';

  @override
  String get androidAppAvailable =>
      'Taskboi esta disponible en Android para una mejor experiencia movil!';

  @override
  String pageNotFound(String path) {
    return 'Pagina no encontrada: $path';
  }

  @override
  String get camera => 'Camara';

  @override
  String get gallery => 'Galeria';
}
