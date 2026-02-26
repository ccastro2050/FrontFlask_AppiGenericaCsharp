"""
usuario.py - Blueprint con las rutas CRUD para la tabla Usuario.

Campos de la tabla:
    - email       (clave primaria, texto)
    - contrasena  (texto)

Funcionalidad especial:
    - Opcion para encriptar la contrasena antes de enviarla a la API.
      Se activa con el checkbox 'encriptar' en el formulario.

Rutas:
    GET  /usuario              →  Listar registros y mostrar formulario si corresponde
    POST /usuario/crear        →  Crear un nuevo registro
    POST /usuario/actualizar   →  Actualizar un registro existente
    POST /usuario/eliminar     →  Eliminar un registro
"""

from flask import Blueprint, render_template, request, redirect, url_for, flash
from services.api_service import ApiService


# ══════════════════════════════════════════════
# CONFIGURACION DEL BLUEPRINT
# ══════════════════════════════════════════════

bp = Blueprint('usuario', __name__)
api = ApiService()

TABLA = 'usuario'
CLAVE = 'email'


# ══════════════════════════════════════════════
# LISTAR REGISTROS (GET)
# ══════════════════════════════════════════════

@bp.route('/usuario')
def index():
    """Muestra la tabla de usuarios con formulario opcional."""
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

    return render_template('pages/usuario.html',
        registros=registros,
        mostrar_formulario=mostrar_formulario,
        editando=editando,
        registro=registro,
        limite=limite
    )


# ══════════════════════════════════════════════
# CREAR REGISTRO (POST)
# ══════════════════════════════════════════════

@bp.route('/usuario/crear', methods=['POST'])
def crear():
    """Crea un nuevo registro de usuario. Opcionalmente encripta la contrasena."""
    datos = {
        'email':      request.form.get('email', ''),
        'contrasena': request.form.get('contrasena', '')
    }

    # Si el checkbox de encriptar esta marcado, se envia el parametro
    # La API se encarga de encriptar el campo indicado
    encriptar = request.form.get('encriptar')
    campos_encriptar = 'contrasena' if encriptar else None

    exito, mensaje = api.crear(TABLA, datos, campos_encriptar)
    flash(mensaje, 'success' if exito else 'danger')
    return redirect(url_for('usuario.index'))


# ══════════════════════════════════════════════
# ACTUALIZAR REGISTRO (POST)
# ══════════════════════════════════════════════

@bp.route('/usuario/actualizar', methods=['POST'])
def actualizar():
    """Actualiza un registro existente de usuario."""
    valor = request.form.get('email', '')

    # Solo el campo editable (sin la clave primaria)
    datos = {
        'contrasena': request.form.get('contrasena', '')
    }

    # Verificar si se quiere encriptar la contrasena
    encriptar = request.form.get('encriptar')
    campos_encriptar = 'contrasena' if encriptar else None

    exito, mensaje = api.actualizar(TABLA, CLAVE, valor, datos, campos_encriptar)
    flash(mensaje, 'success' if exito else 'danger')
    return redirect(url_for('usuario.index'))


# ══════════════════════════════════════════════
# ELIMINAR REGISTRO (POST)
# ══════════════════════════════════════════════

@bp.route('/usuario/eliminar', methods=['POST'])
def eliminar():
    """Elimina un registro de usuario."""
    valor = request.form.get('email', '')

    exito, mensaje = api.eliminar(TABLA, CLAVE, valor)
    flash(mensaje, 'success' if exito else 'danger')
    return redirect(url_for('usuario.index'))
