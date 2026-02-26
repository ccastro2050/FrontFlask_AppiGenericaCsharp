"""
usuario.py - Blueprint con las rutas CRUD para la tabla Usuario.

Campos de la tabla:
    - email       (clave primaria, texto)
    - contrasena  (texto)

Funcionalidad especial:
    - Opcion para encriptar la contrasena antes de enviarla a la API.
      Se activa con el checkbox 'encriptar' en el formulario.
      La API encripta el campo con bcrypt antes de guardarlo en la BD.

Rutas:
    GET  /usuario              →  Listar registros y mostrar formulario si corresponde
    POST /usuario/crear        →  Crear un nuevo registro
    POST /usuario/actualizar   →  Actualizar un registro existente
    POST /usuario/eliminar     →  Eliminar un registro
"""

# Importar las funciones necesarias de Flask (ver empresa.py para detalle de cada una)
from flask import Blueprint, render_template, request, redirect, url_for, flash

# Servicio generico para las llamadas HTTP a la API REST
from services.api_service import ApiService


# ══════════════════════════════════════════════
# CONFIGURACION DEL BLUEPRINT
# ══════════════════════════════════════════════

# Crear Blueprint con nombre 'usuario' → se usa en url_for('usuario.index')
bp = Blueprint('usuario', __name__)

# Instancia del servicio CRUD para comunicarse con la API
api = ApiService()

# Nombre de la tabla en la API
TABLA = 'usuario'

# Nombre del campo clave primaria (es el email, no codigo)
CLAVE = 'email'


# ══════════════════════════════════════════════
# LISTAR REGISTROS (GET)
# ══════════════════════════════════════════════

# Responde a GET /usuario
@bp.route('/usuario')
def index():
    """Muestra la tabla de usuarios con formulario opcional."""
    # Leer parametros de la URL (query string)
    limite = request.args.get('limite', type=int)       # Limite de registros (entero o None)
    accion = request.args.get('accion', '')              # 'nuevo', 'editar' o '' (vacio)
    valor_clave = request.args.get('clave', '')          # Valor de la PK para editar

    # Obtener registros de la API
    registros = api.listar(TABLA, limite)

    # Determinar estado del formulario
    mostrar_formulario = accion in ('nuevo', 'editar')   # True si hay que mostrar formulario
    editando = accion == 'editar'                        # True solo en modo edicion

    # Buscar el registro a editar en la lista (si aplica)
    registro = None
    if editando and valor_clave:
        # Buscar el primer registro cuyo 'email' coincida con valor_clave
        registro = next(
            (r for r in registros if str(r.get(CLAVE)) == valor_clave),
            None  # Retorna None si no encuentra coincidencia
        )

    # Renderizar la pagina pasando las variables al template
    return render_template('pages/usuario.html',
        registros=registros,                  # Lista de usuarios para la tabla HTML
        mostrar_formulario=mostrar_formulario, # Controla visibilidad del formulario
        editando=editando,                     # Controla modo crear vs editar
        registro=registro,                     # Datos del registro a editar (o None)
        limite=limite                          # Mantener el valor de limite en el input
    )


# ══════════════════════════════════════════════
# CREAR REGISTRO (POST)
# ══════════════════════════════════════════════

# Solo acepta peticiones POST (envio de formulario)
@bp.route('/usuario/crear', methods=['POST'])
def crear():
    """Crea un nuevo registro de usuario. Opcionalmente encripta la contrasena."""
    # Leer los campos del formulario
    datos = {
        'email':      request.form.get('email', ''),       # Clave primaria (correo electronico)
        'contrasena': request.form.get('contrasena', '')   # Contrasena en texto plano
    }

    # Verificar si el checkbox 'encriptar' esta marcado en el formulario.
    # Si esta marcado, request.form.get('encriptar') retorna "si" (valor del checkbox).
    # Si NO esta marcado, retorna None (los checkboxes no marcados no se envian).
    encriptar = request.form.get('encriptar')

    # Si el checkbox esta marcado, indicar a la API que encripte el campo 'contrasena'.
    # campos_encriptar se pasa como query param: ?camposEncriptar=contrasena
    # La API usa bcrypt para generar el hash antes de guardar en la BD.
    campos_encriptar = 'contrasena' if encriptar else None

    # Enviar POST a la API, pasando el parametro de encriptacion si aplica
    exito, mensaje = api.crear(TABLA, datos, campos_encriptar)

    # Guardar alerta (verde si exito, roja si error) y redirigir al listado
    flash(mensaje, 'success' if exito else 'danger')
    return redirect(url_for('usuario.index'))


# ══════════════════════════════════════════════
# ACTUALIZAR REGISTRO (POST)
# ══════════════════════════════════════════════

@bp.route('/usuario/actualizar', methods=['POST'])
def actualizar():
    """Actualiza un registro existente de usuario."""
    # Leer la clave primaria (email) del registro a actualizar
    valor = request.form.get('email', '')

    # Solo el campo editable (sin la clave primaria, que va en la URL de la API)
    datos = {
        'contrasena': request.form.get('contrasena', '')  # Nueva contrasena
    }

    # Verificar si se quiere encriptar la nueva contrasena (mismo mecanismo que en crear)
    encriptar = request.form.get('encriptar')
    campos_encriptar = 'contrasena' if encriptar else None

    # Enviar PUT a la API: /api/usuario/email/{valor}
    exito, mensaje = api.actualizar(TABLA, CLAVE, valor, datos, campos_encriptar)

    # Guardar alerta y redirigir
    flash(mensaje, 'success' if exito else 'danger')
    return redirect(url_for('usuario.index'))


# ══════════════════════════════════════════════
# ELIMINAR REGISTRO (POST)
# ══════════════════════════════════════════════

@bp.route('/usuario/eliminar', methods=['POST'])
def eliminar():
    """Elimina un registro de usuario."""
    # Leer la clave primaria (email) desde el campo oculto del formulario de eliminar
    valor = request.form.get('email', '')

    # Enviar DELETE a la API: /api/usuario/email/{valor}
    exito, mensaje = api.eliminar(TABLA, CLAVE, valor)

    # Guardar alerta y redirigir
    flash(mensaje, 'success' if exito else 'danger')
    return redirect(url_for('usuario.index'))
