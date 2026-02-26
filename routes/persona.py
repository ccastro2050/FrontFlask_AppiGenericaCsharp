"""
persona.py - Blueprint con las rutas CRUD para la tabla Persona.

Campos de la tabla:
    - codigo    (clave primaria, texto)
    - nombre    (texto)
    - email     (texto)
    - telefono  (texto)

Rutas:
    GET  /persona              →  Listar registros y mostrar formulario si corresponde
    POST /persona/crear        →  Crear un nuevo registro
    POST /persona/actualizar   →  Actualizar un registro existente
    POST /persona/eliminar     →  Eliminar un registro
"""

# Importar las funciones necesarias de Flask (ver empresa.py para detalle de cada una)
from flask import Blueprint, render_template, request, redirect, url_for, flash

# Servicio generico para las llamadas HTTP a la API REST
from services.api_service import ApiService


# ══════════════════════════════════════════════
# CONFIGURACION DEL BLUEPRINT
# ══════════════════════════════════════════════

# Crear Blueprint con nombre 'persona' → se usa en url_for('persona.index')
bp = Blueprint('persona', __name__)

# Instancia del servicio CRUD para comunicarse con la API
api = ApiService()

# Nombre de la tabla en la API
TABLA = 'persona'

# Nombre del campo clave primaria
CLAVE = 'codigo'


# ══════════════════════════════════════════════
# LISTAR REGISTROS (GET)
# ══════════════════════════════════════════════

# Responde a GET /persona
@bp.route('/persona')
def index():
    """Muestra la tabla de personas con formulario opcional."""
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
        # Buscar el primer registro cuyo 'codigo' coincida con valor_clave
        registro = next(
            (r for r in registros if str(r.get(CLAVE)) == valor_clave),
            None  # Retorna None si no encuentra coincidencia
        )

    # Renderizar la pagina pasando las variables al template
    return render_template('pages/persona.html',
        registros=registros,                  # Lista de personas para la tabla HTML
        mostrar_formulario=mostrar_formulario, # Controla visibilidad del formulario
        editando=editando,                     # Controla modo crear vs editar
        registro=registro,                     # Datos del registro a editar (o None)
        limite=limite                          # Mantener el valor de limite en el input
    )


# ══════════════════════════════════════════════
# CREAR REGISTRO (POST)
# ══════════════════════════════════════════════

# Solo acepta peticiones POST (envio de formulario)
@bp.route('/persona/crear', methods=['POST'])
def crear():
    """Crea un nuevo registro de persona."""
    # Leer los 4 campos del formulario y armar el diccionario de datos.
    # Todos son tipo texto, no necesitan conversion de tipo.
    datos = {
        'codigo':   request.form.get('codigo', ''),    # Clave primaria
        'nombre':   request.form.get('nombre', ''),    # Nombre de la persona
        'email':    request.form.get('email', ''),     # Correo electronico
        'telefono': request.form.get('telefono', '')   # Numero de telefono
    }

    # Enviar POST a la API y obtener resultado
    exito, mensaje = api.crear(TABLA, datos)

    # Guardar alerta (verde si exito, roja si error) y redirigir al listado
    flash(mensaje, 'success' if exito else 'danger')
    return redirect(url_for('persona.index'))


# ══════════════════════════════════════════════
# ACTUALIZAR REGISTRO (POST)
# ══════════════════════════════════════════════

@bp.route('/persona/actualizar', methods=['POST'])
def actualizar():
    """Actualiza un registro existente de persona."""
    # Leer la clave primaria del registro a actualizar
    valor = request.form.get('codigo', '')

    # Campos editables (sin la clave primaria, que va en la URL)
    datos = {
        'nombre':   request.form.get('nombre', ''),    # Nuevo nombre
        'email':    request.form.get('email', ''),     # Nuevo email
        'telefono': request.form.get('telefono', '')   # Nuevo telefono
    }

    # Enviar PUT a la API: /api/persona/codigo/{valor}
    exito, mensaje = api.actualizar(TABLA, CLAVE, valor, datos)

    # Guardar alerta y redirigir
    flash(mensaje, 'success' if exito else 'danger')
    return redirect(url_for('persona.index'))


# ══════════════════════════════════════════════
# ELIMINAR REGISTRO (POST)
# ══════════════════════════════════════════════

@bp.route('/persona/eliminar', methods=['POST'])
def eliminar():
    """Elimina un registro de persona."""
    # Leer la clave primaria desde el campo oculto del formulario de eliminar
    valor = request.form.get('codigo', '')

    # Enviar DELETE a la API: /api/persona/codigo/{valor}
    exito, mensaje = api.eliminar(TABLA, CLAVE, valor)

    # Guardar alerta y redirigir
    flash(mensaje, 'success' if exito else 'danger')
    return redirect(url_for('persona.index'))
