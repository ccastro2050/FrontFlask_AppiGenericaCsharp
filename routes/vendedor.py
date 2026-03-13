"""
vendedor.py - Blueprint con las rutas CRUD para la tabla Vendedor.

Campos de la tabla:
    - id            (clave primaria, entero, autoincremental)
    - carnet        (texto)
    - direccion     (texto)
    - fkcodpersona  (clave foranea a persona.codigo)

Rutas:
    GET  /vendedor              →  Listar registros y mostrar formulario si corresponde
    POST /vendedor/crear        →  Crear un nuevo registro
    POST /vendedor/actualizar   →  Actualizar un registro existente
    POST /vendedor/eliminar     →  Eliminar un registro
"""

from flask import Blueprint, render_template, request, redirect, url_for, flash
from services.api_service import ApiService


# ══════════════════════════════════════════════
# CONFIGURACION DEL BLUEPRINT
# ══════════════════════════════════════════════

bp = Blueprint('vendedor', __name__)
api = ApiService()
TABLA = 'vendedor'
CLAVE = 'id'


# ══════════════════════════════════════════════
# LISTAR REGISTROS (GET)
# ══════════════════════════════════════════════

@bp.route('/vendedor')
def index():
    """Muestra la tabla de vendedores con select de persona."""
    limite = request.args.get('limite', type=int)
    accion = request.args.get('accion', '')
    valor_clave = request.args.get('clave', '')

    registros = api.listar(TABLA, limite)
    personas = api.listar('persona')

    mostrar_formulario = accion in ('nuevo', 'editar')
    editando = accion == 'editar'

    registro = None
    if editando and valor_clave:
        registro = next(
            (r for r in registros if str(r.get(CLAVE)) == valor_clave),
            None
        )

    # Mapa persona codigo -> nombre para mostrar en la tabla
    mapa_personas = {str(p.get('codigo', '')): p.get('nombre', 'Sin nombre') for p in personas}

    return render_template('pages/vendedor.html',
        registros=registros,
        mostrar_formulario=mostrar_formulario,
        editando=editando,
        registro=registro,
        limite=limite,
        personas=personas,
        mapa_personas=mapa_personas
    )


# ══════════════════════════════════════════════
# CREAR REGISTRO (POST)
# ══════════════════════════════════════════════

@bp.route('/vendedor/crear', methods=['POST'])
def crear():
    """Crea un nuevo registro de vendedor."""
    datos = {
        'carnet': request.form.get('carnet', ''),
        'direccion': request.form.get('direccion', ''),
        'fkcodpersona': request.form.get('fkcodpersona', '')
    }

    exito, mensaje = api.crear(TABLA, datos)
    flash(mensaje, 'success' if exito else 'danger')
    return redirect(url_for('vendedor.index'))


# ══════════════════════════════════════════════
# ACTUALIZAR REGISTRO (POST)
# ══════════════════════════════════════════════

@bp.route('/vendedor/actualizar', methods=['POST'])
def actualizar():
    """Actualiza un registro existente de vendedor."""
    valor = request.form.get('id', '')

    datos = {
        'carnet': request.form.get('carnet', ''),
        'direccion': request.form.get('direccion', ''),
        'fkcodpersona': request.form.get('fkcodpersona', '')
    }

    exito, mensaje = api.actualizar(TABLA, CLAVE, valor, datos)
    flash(mensaje, 'success' if exito else 'danger')
    return redirect(url_for('vendedor.index'))


# ══════════════════════════════════════════════
# ELIMINAR REGISTRO (POST)
# ══════════════════════════════════════════════

@bp.route('/vendedor/eliminar', methods=['POST'])
def eliminar():
    """Elimina un registro de vendedor."""
    valor = request.form.get('id', '')

    exito, mensaje = api.eliminar(TABLA, CLAVE, valor)
    flash(mensaje, 'success' if exito else 'danger')
    return redirect(url_for('vendedor.index'))
