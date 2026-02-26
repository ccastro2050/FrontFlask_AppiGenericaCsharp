"""
ruta.py - Blueprint con las rutas CRUD para la tabla Ruta.

Campos de la tabla:
    - ruta         (clave primaria, texto)
    - descripcion  (texto)

Nota: El campo clave primaria se llama igual que la tabla ('ruta').

Rutas:
    GET  /ruta              →  Listar registros y mostrar formulario si corresponde
    POST /ruta/crear        →  Crear un nuevo registro
    POST /ruta/actualizar   →  Actualizar un registro existente
    POST /ruta/eliminar     →  Eliminar un registro
"""

from flask import Blueprint, render_template, request, redirect, url_for, flash
from services.api_service import ApiService


# ══════════════════════════════════════════════
# CONFIGURACION DEL BLUEPRINT
# ══════════════════════════════════════════════

bp = Blueprint('ruta_page', __name__)
api = ApiService()

TABLA = 'ruta'
CLAVE = 'ruta'


# ══════════════════════════════════════════════
# LISTAR REGISTROS (GET)
# ══════════════════════════════════════════════

@bp.route('/ruta')
def index():
    """Muestra la tabla de rutas con formulario opcional."""
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

    return render_template('pages/ruta.html',
        registros=registros,
        mostrar_formulario=mostrar_formulario,
        editando=editando,
        registro=registro,
        limite=limite
    )


# ══════════════════════════════════════════════
# CREAR REGISTRO (POST)
# ══════════════════════════════════════════════

@bp.route('/ruta/crear', methods=['POST'])
def crear():
    """Crea un nuevo registro de ruta."""
    datos = {
        'ruta':        request.form.get('ruta', ''),
        'descripcion': request.form.get('descripcion', '')
    }

    exito, mensaje = api.crear(TABLA, datos)
    flash(mensaje, 'success' if exito else 'danger')
    return redirect(url_for('ruta_page.index'))


# ══════════════════════════════════════════════
# ACTUALIZAR REGISTRO (POST)
# ══════════════════════════════════════════════

@bp.route('/ruta/actualizar', methods=['POST'])
def actualizar():
    """Actualiza un registro existente de ruta."""
    valor = request.form.get('ruta', '')

    # Solo el campo editable (sin la clave primaria)
    datos = {
        'descripcion': request.form.get('descripcion', '')
    }

    exito, mensaje = api.actualizar(TABLA, CLAVE, valor, datos)
    flash(mensaje, 'success' if exito else 'danger')
    return redirect(url_for('ruta_page.index'))


# ══════════════════════════════════════════════
# ELIMINAR REGISTRO (POST)
# ══════════════════════════════════════════════

@bp.route('/ruta/eliminar', methods=['POST'])
def eliminar():
    """Elimina un registro de ruta."""
    valor = request.form.get('ruta', '')

    exito, mensaje = api.eliminar(TABLA, CLAVE, valor)
    flash(mensaje, 'success' if exito else 'danger')
    return redirect(url_for('ruta_page.index'))
