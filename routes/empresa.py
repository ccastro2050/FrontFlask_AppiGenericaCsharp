"""
empresa.py - Blueprint con las rutas CRUD para la tabla Empresa.

Campos de la tabla:
    - codigo  (clave primaria, texto)
    - nombre  (texto)

Rutas:
    GET  /empresa              →  Listar registros y mostrar formulario si corresponde
    POST /empresa/crear        →  Crear un nuevo registro
    POST /empresa/actualizar   →  Actualizar un registro existente
    POST /empresa/eliminar     →  Eliminar un registro
"""

from flask import Blueprint, render_template, request, redirect, url_for, flash
from services.api_service import ApiService


# ══════════════════════════════════════════════
# CONFIGURACION DEL BLUEPRINT
# ══════════════════════════════════════════════

bp = Blueprint('empresa', __name__)
api = ApiService()

# Nombre de la tabla y campo clave primaria en la API
TABLA = 'empresa'
CLAVE = 'codigo'


# ══════════════════════════════════════════════
# LISTAR REGISTROS (GET)
# ══════════════════════════════════════════════

@bp.route('/empresa')
def index():
    """
    Muestra la tabla de empresas.

    Parametros opcionales en la URL:
        limite : int  - cantidad maxima de registros
        accion : str  - 'nuevo' para formulario vacio, 'editar' para editar
        clave  : str  - valor de la clave primaria del registro a editar
    """
    # Leer parametros de la URL
    limite = request.args.get('limite', type=int)
    accion = request.args.get('accion', '')
    valor_clave = request.args.get('clave', '')

    # Obtener registros de la API
    registros = api.listar(TABLA, limite)

    # Determinar si se muestra el formulario y en que modo
    mostrar_formulario = accion in ('nuevo', 'editar')
    editando = accion == 'editar'

    # Si estamos editando, buscar el registro en la lista cargada
    registro = None
    if editando and valor_clave:
        registro = next(
            (r for r in registros if str(r.get(CLAVE)) == valor_clave),
            None
        )

    return render_template('pages/empresa.html',
        registros=registros,
        mostrar_formulario=mostrar_formulario,
        editando=editando,
        registro=registro,
        limite=limite
    )


# ══════════════════════════════════════════════
# CREAR REGISTRO (POST)
# ══════════════════════════════════════════════

@bp.route('/empresa/crear', methods=['POST'])
def crear():
    """Recibe los datos del formulario y crea un nuevo registro."""
    datos = {
        'codigo': request.form.get('codigo', ''),
        'nombre': request.form.get('nombre', '')
    }

    exito, mensaje = api.crear(TABLA, datos)
    flash(mensaje, 'success' if exito else 'danger')
    return redirect(url_for('empresa.index'))


# ══════════════════════════════════════════════
# ACTUALIZAR REGISTRO (POST)
# ══════════════════════════════════════════════

@bp.route('/empresa/actualizar', methods=['POST'])
def actualizar():
    """Recibe los datos del formulario y actualiza el registro existente."""
    valor = request.form.get('codigo', '')

    # Solo enviamos los campos editables (sin la clave primaria)
    datos = {
        'nombre': request.form.get('nombre', '')
    }

    exito, mensaje = api.actualizar(TABLA, CLAVE, valor, datos)
    flash(mensaje, 'success' if exito else 'danger')
    return redirect(url_for('empresa.index'))


# ══════════════════════════════════════════════
# ELIMINAR REGISTRO (POST)
# ══════════════════════════════════════════════

@bp.route('/empresa/eliminar', methods=['POST'])
def eliminar():
    """Elimina el registro identificado por su clave primaria."""
    valor = request.form.get('codigo', '')

    exito, mensaje = api.eliminar(TABLA, CLAVE, valor)
    flash(mensaje, 'success' if exito else 'danger')
    return redirect(url_for('empresa.index'))
