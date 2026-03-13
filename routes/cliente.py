"""
cliente.py - Blueprint con las rutas CRUD para la tabla Cliente.

Campos de la tabla:
    - id            (clave primaria, entero, autoincremental)
    - credito       (numerico, decimal)
    - fkcodpersona  (clave foranea a persona.codigo)
    - fkcodempresa  (clave foranea a empresa.codigo, nullable)

Rutas:
    GET  /cliente              →  Listar registros y mostrar formulario si corresponde
    POST /cliente/crear        →  Crear un nuevo registro
    POST /cliente/actualizar   →  Actualizar un registro existente
    POST /cliente/eliminar     →  Eliminar un registro
"""

from flask import Blueprint, render_template, request, redirect, url_for, flash
from services.api_service import ApiService


# ══════════════════════════════════════════════
# CONFIGURACION DEL BLUEPRINT
# ══════════════════════════════════════════════

bp = Blueprint('cliente', __name__)
api = ApiService()
TABLA = 'cliente'
CLAVE = 'id'


# ══════════════════════════════════════════════
# LISTAR REGISTROS (GET)
# ══════════════════════════════════════════════

@bp.route('/cliente')
def index():
    """Muestra la tabla de clientes con selects de persona y empresa."""
    limite = request.args.get('limite', type=int)
    accion = request.args.get('accion', '')
    valor_clave = request.args.get('clave', '')

    registros = api.listar(TABLA, limite)
    personas = api.listar('persona')
    empresas = api.listar('empresa')

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
    mapa_empresas = {str(e.get('codigo', '')): e.get('nombre', 'Sin nombre') for e in empresas}

    return render_template('pages/cliente.html',
        registros=registros,
        mostrar_formulario=mostrar_formulario,
        editando=editando,
        registro=registro,
        limite=limite,
        personas=personas,
        empresas=empresas,
        mapa_personas=mapa_personas,
        mapa_empresas=mapa_empresas
    )


# ══════════════════════════════════════════════
# CREAR REGISTRO (POST)
# ══════════════════════════════════════════════

@bp.route('/cliente/crear', methods=['POST'])
def crear():
    """Crea un nuevo registro de cliente."""
    datos = {
        'credito': request.form.get('credito', '0'),
        'fkcodpersona': request.form.get('fkcodpersona', ''),
        'fkcodempresa': request.form.get('fkcodempresa', '') or None
    }

    exito, mensaje = api.crear(TABLA, datos)
    flash(mensaje, 'success' if exito else 'danger')
    return redirect(url_for('cliente.index'))


# ══════════════════════════════════════════════
# ACTUALIZAR REGISTRO (POST)
# ══════════════════════════════════════════════

@bp.route('/cliente/actualizar', methods=['POST'])
def actualizar():
    """Actualiza un registro existente de cliente."""
    valor = request.form.get('id', '')

    datos = {
        'credito': request.form.get('credito', '0'),
        'fkcodpersona': request.form.get('fkcodpersona', ''),
        'fkcodempresa': request.form.get('fkcodempresa', '') or None
    }

    exito, mensaje = api.actualizar(TABLA, CLAVE, valor, datos)
    flash(mensaje, 'success' if exito else 'danger')
    return redirect(url_for('cliente.index'))


# ══════════════════════════════════════════════
# ELIMINAR REGISTRO (POST)
# ══════════════════════════════════════════════

@bp.route('/cliente/eliminar', methods=['POST'])
def eliminar():
    """Elimina un registro de cliente."""
    valor = request.form.get('id', '')

    exito, mensaje = api.eliminar(TABLA, CLAVE, valor)
    flash(mensaje, 'success' if exito else 'danger')
    return redirect(url_for('cliente.index'))
