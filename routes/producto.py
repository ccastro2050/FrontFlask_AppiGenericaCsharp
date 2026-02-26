"""
producto.py - Blueprint con las rutas CRUD para la tabla Producto.

Campos de la tabla:
    - codigo         (clave primaria, texto)
    - nombre         (texto)
    - stock          (entero)
    - valorunitario  (decimal)

Rutas:
    GET  /producto              →  Listar registros y mostrar formulario si corresponde
    POST /producto/crear        →  Crear un nuevo registro
    POST /producto/actualizar   →  Actualizar un registro existente
    POST /producto/eliminar     →  Eliminar un registro
"""

from flask import Blueprint, render_template, request, redirect, url_for, flash
from services.api_service import ApiService


# ══════════════════════════════════════════════
# CONFIGURACION DEL BLUEPRINT
# ══════════════════════════════════════════════

bp = Blueprint('producto', __name__)
api = ApiService()

TABLA = 'producto'
CLAVE = 'codigo'


# ══════════════════════════════════════════════
# LISTAR REGISTROS (GET)
# ══════════════════════════════════════════════

@bp.route('/producto')
def index():
    """Muestra la tabla de productos con formulario opcional."""
    limite = request.args.get('limite', type=int)
    accion = request.args.get('accion', '')
    valor_clave = request.args.get('clave', '')

    registros = api.listar(TABLA, limite)

    mostrar_formulario = accion in ('nuevo', 'editar')
    editando = accion == 'editar'

    registro = None
    if editando and valor_clave:
        registro = next(
            (r for r in registros if str(r.get(CLAVE)) == valor_clave),
            None
        )

    return render_template('pages/producto.html',
        registros=registros,
        mostrar_formulario=mostrar_formulario,
        editando=editando,
        registro=registro,
        limite=limite
    )


# ══════════════════════════════════════════════
# CREAR REGISTRO (POST)
# ══════════════════════════════════════════════

@bp.route('/producto/crear', methods=['POST'])
def crear():
    """Crea un nuevo registro de producto."""
    datos = {
        'codigo':        request.form.get('codigo', ''),
        'nombre':        request.form.get('nombre', ''),
        'stock':         request.form.get('stock', 0, type=int),
        'valorunitario': request.form.get('valorunitario', 0, type=float)
    }

    exito, mensaje = api.crear(TABLA, datos)
    flash(mensaje, 'success' if exito else 'danger')
    return redirect(url_for('producto.index'))


# ══════════════════════════════════════════════
# ACTUALIZAR REGISTRO (POST)
# ══════════════════════════════════════════════

@bp.route('/producto/actualizar', methods=['POST'])
def actualizar():
    """Actualiza un registro existente de producto."""
    valor = request.form.get('codigo', '')

    # Campos editables (sin la clave primaria)
    datos = {
        'nombre':        request.form.get('nombre', ''),
        'stock':         request.form.get('stock', 0, type=int),
        'valorunitario': request.form.get('valorunitario', 0, type=float)
    }

    exito, mensaje = api.actualizar(TABLA, CLAVE, valor, datos)
    flash(mensaje, 'success' if exito else 'danger')
    return redirect(url_for('producto.index'))


# ══════════════════════════════════════════════
# ELIMINAR REGISTRO (POST)
# ══════════════════════════════════════════════

@bp.route('/producto/eliminar', methods=['POST'])
def eliminar():
    """Elimina un registro de producto."""
    valor = request.form.get('codigo', '')

    exito, mensaje = api.eliminar(TABLA, CLAVE, valor)
    flash(mensaje, 'success' if exito else 'danger')
    return redirect(url_for('producto.index'))
