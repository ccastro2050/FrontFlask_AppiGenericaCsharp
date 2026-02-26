"""
rol.py - Blueprint con las rutas CRUD para la tabla Rol.

Campos de la tabla:
    - id      (clave primaria, entero)
    - nombre  (texto)

Rutas:
    GET  /rol              →  Listar registros y mostrar formulario si corresponde
    POST /rol/crear        →  Crear un nuevo registro
    POST /rol/actualizar   →  Actualizar un registro existente
    POST /rol/eliminar     →  Eliminar un registro
"""

from flask import Blueprint, render_template, request, redirect, url_for, flash
from services.api_service import ApiService


# ══════════════════════════════════════════════
# CONFIGURACION DEL BLUEPRINT
# ══════════════════════════════════════════════

bp = Blueprint('rol', __name__)
api = ApiService()

TABLA = 'rol'
CLAVE = 'id'


# ══════════════════════════════════════════════
# LISTAR REGISTROS (GET)
# ══════════════════════════════════════════════

@bp.route('/rol')
def index():
    """Muestra la tabla de roles con formulario opcional."""
    limite = request.args.get('limite', type=int)
    accion = request.args.get('accion', '')
    valor_clave = request.args.get('clave', '')

    registros = api.listar(TABLA, limite)

    mostrar_formulario = accion in ('nuevo', 'editar')
    editando = accion == 'editar'

    registro = None
    if editando and valor_clave:
        registro = next(
            (r for r in registros if str(r.get(CLAVE)) == str(valor_clave)),
            None
        )

    return render_template('pages/rol.html',
        registros=registros,
        mostrar_formulario=mostrar_formulario,
        editando=editando,
        registro=registro,
        limite=limite
    )


# ══════════════════════════════════════════════
# CREAR REGISTRO (POST)
# ══════════════════════════════════════════════

@bp.route('/rol/crear', methods=['POST'])
def crear():
    """Crea un nuevo registro de rol."""
    datos = {
        'id':     request.form.get('id', 0, type=int),
        'nombre': request.form.get('nombre', '')
    }

    exito, mensaje = api.crear(TABLA, datos)
    flash(mensaje, 'success' if exito else 'danger')
    return redirect(url_for('rol.index'))


# ══════════════════════════════════════════════
# ACTUALIZAR REGISTRO (POST)
# ══════════════════════════════════════════════

@bp.route('/rol/actualizar', methods=['POST'])
def actualizar():
    """Actualiza un registro existente de rol."""
    valor = request.form.get('id', '')

    # Solo el campo editable (sin la clave primaria)
    datos = {
        'nombre': request.form.get('nombre', '')
    }

    exito, mensaje = api.actualizar(TABLA, CLAVE, valor, datos)
    flash(mensaje, 'success' if exito else 'danger')
    return redirect(url_for('rol.index'))


# ══════════════════════════════════════════════
# ELIMINAR REGISTRO (POST)
# ══════════════════════════════════════════════

@bp.route('/rol/eliminar', methods=['POST'])
def eliminar():
    """Elimina un registro de rol."""
    valor = request.form.get('id', '')

    exito, mensaje = api.eliminar(TABLA, CLAVE, valor)
    flash(mensaje, 'success' if exito else 'danger')
    return redirect(url_for('rol.index'))
