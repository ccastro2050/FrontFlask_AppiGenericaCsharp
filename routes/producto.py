"""
producto.py - Blueprint con las rutas CRUD para la tabla Producto.

Campos de la tabla:
    - codigo         (clave primaria, texto)
    - nombre         (texto)
    - stock          (entero)
    - valorunitario  (decimal)

Nota: Esta tabla tiene campos numericos. Se usa type=int y type=float
en request.form.get() para convertir los valores del formulario.

Rutas:
    GET  /producto              →  Listar registros y mostrar formulario si corresponde
    POST /producto/crear        →  Crear un nuevo registro
    POST /producto/actualizar   →  Actualizar un registro existente
    POST /producto/eliminar     →  Eliminar un registro
"""

# Importar las funciones necesarias de Flask (ver empresa.py para detalle de cada una)
from flask import Blueprint, render_template, request, redirect, url_for, flash

# Servicio generico para las llamadas HTTP a la API REST
from services.api_service import ApiService


# ══════════════════════════════════════════════
# CONFIGURACION DEL BLUEPRINT
# ══════════════════════════════════════════════

# Crear Blueprint con nombre 'producto' → se usa en url_for('producto.index')
bp = Blueprint('producto', __name__)

# Instancia del servicio CRUD para comunicarse con la API
api = ApiService()

# Nombre de la tabla en la API
TABLA = 'producto'

# Nombre del campo clave primaria
CLAVE = 'codigo'


# ══════════════════════════════════════════════
# LISTAR REGISTROS (GET)
# ══════════════════════════════════════════════

# Responde a GET /producto
@bp.route('/producto')
def index():
    """Muestra la tabla de productos con formulario opcional."""
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
    return render_template('pages/producto.html',
        registros=registros,                  # Lista de productos para la tabla HTML
        mostrar_formulario=mostrar_formulario, # Controla visibilidad del formulario
        editando=editando,                     # Controla modo crear vs editar
        registro=registro,                     # Datos del registro a editar (o None)
        limite=limite                          # Mantener el valor de limite en el input
    )


# ══════════════════════════════════════════════
# CREAR REGISTRO (POST)
# ══════════════════════════════════════════════

# Solo acepta peticiones POST (envio de formulario)
@bp.route('/producto/crear', methods=['POST'])
def crear():
    """Crea un nuevo registro de producto."""
    # Leer los campos del formulario y armar el diccionario de datos.
    # stock y valorunitario son numericos: se usa type=int y type=float
    # para que Flask los convierta automaticamente (o use el valor por defecto si falla).
    datos = {
        'codigo':        request.form.get('codigo', ''),             # Clave primaria (texto)
        'nombre':        request.form.get('nombre', ''),             # Nombre del producto (texto)
        'stock':         request.form.get('stock', 0, type=int),     # Cantidad disponible (entero, defecto 0)
        'valorunitario': request.form.get('valorunitario', 0, type=float)  # Precio (decimal, defecto 0)
    }

    # Enviar POST a la API y obtener resultado
    exito, mensaje = api.crear(TABLA, datos)

    # Guardar alerta (verde si exito, roja si error) y redirigir al listado
    flash(mensaje, 'success' if exito else 'danger')
    return redirect(url_for('producto.index'))


# ══════════════════════════════════════════════
# ACTUALIZAR REGISTRO (POST)
# ══════════════════════════════════════════════

@bp.route('/producto/actualizar', methods=['POST'])
def actualizar():
    """Actualiza un registro existente de producto."""
    # Leer la clave primaria del registro a actualizar
    valor = request.form.get('codigo', '')

    # Campos editables (sin la clave primaria, que va en la URL de la API)
    # stock y valorunitario se convierten a sus tipos numericos correspondientes
    datos = {
        'nombre':        request.form.get('nombre', ''),             # Nuevo nombre (texto)
        'stock':         request.form.get('stock', 0, type=int),     # Nuevo stock (entero)
        'valorunitario': request.form.get('valorunitario', 0, type=float)  # Nuevo precio (decimal)
    }

    # Enviar PUT a la API: /api/producto/codigo/{valor}
    exito, mensaje = api.actualizar(TABLA, CLAVE, valor, datos)

    # Guardar alerta y redirigir
    flash(mensaje, 'success' if exito else 'danger')
    return redirect(url_for('producto.index'))


# ══════════════════════════════════════════════
# ELIMINAR REGISTRO (POST)
# ══════════════════════════════════════════════

@bp.route('/producto/eliminar', methods=['POST'])
def eliminar():
    """Elimina un registro de producto."""
    # Leer la clave primaria desde el campo oculto del formulario de eliminar
    valor = request.form.get('codigo', '')

    # Enviar DELETE a la API: /api/producto/codigo/{valor}
    exito, mensaje = api.eliminar(TABLA, CLAVE, valor)

    # Guardar alerta y redirigir
    flash(mensaje, 'success' if exito else 'danger')
    return redirect(url_for('producto.index'))
