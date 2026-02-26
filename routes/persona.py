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

from flask import Blueprint, render_template, request, redirect, url_for, flash
from services.api_service import ApiService


# ══════════════════════════════════════════════
# CONFIGURACION DEL BLUEPRINT
# ══════════════════════════════════════════════

bp = Blueprint('persona', __name__)
api = ApiService()

TABLA = 'persona'
CLAVE = 'codigo'


# ══════════════════════════════════════════════
# LISTAR REGISTROS (GET)
# ══════════════════════════════════════════════

@bp.route('/persona')
def index():
    """Muestra la tabla de personas con formulario opcional."""
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

    return render_template('pages/persona.html',
        registros=registros,
        mostrar_formulario=mostrar_formulario,
        editando=editando,
        registro=registro,
        limite=limite
    )


# ══════════════════════════════════════════════
# CREAR REGISTRO (POST)
# ══════════════════════════════════════════════

@bp.route('/persona/crear', methods=['POST'])
def crear():
    """Crea un nuevo registro de persona."""
    datos = {
        'codigo':   request.form.get('codigo', ''),
        'nombre':   request.form.get('nombre', ''),
        'email':    request.form.get('email', ''),
        'telefono': request.form.get('telefono', '')
    }

    exito, mensaje = api.crear(TABLA, datos)
    flash(mensaje, 'success' if exito else 'danger')
    return redirect(url_for('persona.index'))


# ══════════════════════════════════════════════
# ACTUALIZAR REGISTRO (POST)
# ══════════════════════════════════════════════

@bp.route('/persona/actualizar', methods=['POST'])
def actualizar():
    """Actualiza un registro existente de persona."""
    valor = request.form.get('codigo', '')

    # Campos editables (sin la clave primaria)
    datos = {
        'nombre':   request.form.get('nombre', ''),
        'email':    request.form.get('email', ''),
        'telefono': request.form.get('telefono', '')
    }

    exito, mensaje = api.actualizar(TABLA, CLAVE, valor, datos)
    flash(mensaje, 'success' if exito else 'danger')
    return redirect(url_for('persona.index'))


# ══════════════════════════════════════════════
# ELIMINAR REGISTRO (POST)
# ══════════════════════════════════════════════

@bp.route('/persona/eliminar', methods=['POST'])
def eliminar():
    """Elimina un registro de persona."""
    valor = request.form.get('codigo', '')

    exito, mensaje = api.eliminar(TABLA, CLAVE, valor)
    flash(mensaje, 'success' if exito else 'danger')
    return redirect(url_for('persona.index'))
