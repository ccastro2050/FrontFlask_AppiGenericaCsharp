"""
ruta.py - Blueprint con las rutas CRUD para la tabla Ruta.

Campos de la tabla:
    - ruta         (clave primaria, texto)
    - descripcion  (texto)

Nota: El campo clave primaria se llama igual que la tabla ('ruta').
Para evitar confusion, el Blueprint se nombra 'ruta_page' en vez de 'ruta'.
En los templates se usa url_for('ruta_page.index') en vez de url_for('ruta.index').

Rutas:
    GET  /ruta              →  Listar registros y mostrar formulario si corresponde
    POST /ruta/crear        →  Crear un nuevo registro
    POST /ruta/actualizar   →  Actualizar un registro existente
    POST /ruta/eliminar     →  Eliminar un registro
"""

# Importar las funciones necesarias de Flask (ver empresa.py para detalle de cada una)
from flask import Blueprint, render_template, request, redirect, url_for, flash

# Servicio generico para las llamadas HTTP a la API REST
from services.api_service import ApiService


# ══════════════════════════════════════════════
# CONFIGURACION DEL BLUEPRINT
# ══════════════════════════════════════════════

# Crear Blueprint con nombre 'ruta_page' (no 'ruta') para evitar ambiguedad.
# Se usa en url_for('ruta_page.index') en los templates y redirects.
bp = Blueprint('ruta_page', __name__)

# Instancia del servicio CRUD para comunicarse con la API
api = ApiService()

# Nombre de la tabla en la API
TABLA = 'ruta'

# Nombre del campo clave primaria (se llama igual que la tabla)
CLAVE = 'ruta'


# ══════════════════════════════════════════════
# LISTAR REGISTROS (GET)
# ══════════════════════════════════════════════

# Responde a GET /ruta
@bp.route('/ruta')
def index():
    """Muestra la tabla de rutas con formulario opcional."""
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
        # Buscar el primer registro cuyo campo 'ruta' coincida con valor_clave
        registro = next(
            (r for r in registros if str(r.get(CLAVE)) == valor_clave),
            None  # Retorna None si no encuentra coincidencia
        )

    # Renderizar la pagina pasando las variables al template
    return render_template('pages/ruta.html',
        registros=registros,                  # Lista de rutas para la tabla HTML
        mostrar_formulario=mostrar_formulario, # Controla visibilidad del formulario
        editando=editando,                     # Controla modo crear vs editar
        registro=registro,                     # Datos del registro a editar (o None)
        limite=limite                          # Mantener el valor de limite en el input
    )


# ══════════════════════════════════════════════
# CREAR REGISTRO (POST)
# ══════════════════════════════════════════════

# Solo acepta peticiones POST (envio de formulario)
@bp.route('/ruta/crear', methods=['POST'])
def crear():
    """Crea un nuevo registro de ruta."""
    # Leer los campos del formulario (ambos son texto)
    datos = {
        'ruta':        request.form.get('ruta', ''),         # Clave primaria (ej: '/api/productos')
        'descripcion': request.form.get('descripcion', '')   # Descripcion de la ruta
    }

    # Enviar POST a la API y obtener resultado
    exito, mensaje = api.crear(TABLA, datos)

    # Guardar alerta y redirigir al listado.
    # Nota: se usa 'ruta_page.index' (nombre del Blueprint), no 'ruta.index'
    flash(mensaje, 'success' if exito else 'danger')
    return redirect(url_for('ruta_page.index'))


# ══════════════════════════════════════════════
# ACTUALIZAR REGISTRO (POST)
# ══════════════════════════════════════════════

@bp.route('/ruta/actualizar', methods=['POST'])
def actualizar():
    """Actualiza un registro existente de ruta."""
    # Leer la clave primaria del registro a actualizar
    valor = request.form.get('ruta', '')

    # Solo el campo editable (sin la clave primaria, que va en la URL de la API)
    datos = {
        'descripcion': request.form.get('descripcion', '')  # Nueva descripcion
    }

    # Enviar PUT a la API: /api/ruta/ruta/{valor}
    exito, mensaje = api.actualizar(TABLA, CLAVE, valor, datos)

    # Guardar alerta y redirigir
    flash(mensaje, 'success' if exito else 'danger')
    return redirect(url_for('ruta_page.index'))


# ══════════════════════════════════════════════
# ELIMINAR REGISTRO (POST)
# ══════════════════════════════════════════════

@bp.route('/ruta/eliminar', methods=['POST'])
def eliminar():
    """Elimina un registro de ruta."""
    # Leer la clave primaria desde el campo oculto del formulario de eliminar
    valor = request.form.get('ruta', '')

    # Enviar DELETE a la API: /api/ruta/ruta/{valor}
    exito, mensaje = api.eliminar(TABLA, CLAVE, valor)

    # Guardar alerta y redirigir
    flash(mensaje, 'success' if exito else 'danger')
    return redirect(url_for('ruta_page.index'))
