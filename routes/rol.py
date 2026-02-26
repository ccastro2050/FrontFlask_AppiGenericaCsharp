"""
rol.py - Blueprint con las rutas CRUD para la tabla Rol.

Campos de la tabla:
    - id      (clave primaria, entero)
    - nombre  (texto)

Nota: A diferencia de las demas tablas, la clave primaria es un entero ('id'),
no un texto ('codigo'). Por eso CLAVE = 'id' y se usa type=int al leer el formulario.

Rutas:
    GET  /rol              →  Listar registros y mostrar formulario si corresponde
    POST /rol/crear        →  Crear un nuevo registro
    POST /rol/actualizar   →  Actualizar un registro existente
    POST /rol/eliminar     →  Eliminar un registro
"""

# Importar las funciones necesarias de Flask (ver empresa.py para detalle de cada una)
from flask import Blueprint, render_template, request, redirect, url_for, flash

# Servicio generico para las llamadas HTTP a la API REST
from services.api_service import ApiService


# ══════════════════════════════════════════════
# CONFIGURACION DEL BLUEPRINT
# ══════════════════════════════════════════════

# Crear Blueprint con nombre 'rol' → se usa en url_for('rol.index')
bp = Blueprint('rol', __name__)

# Instancia del servicio CRUD para comunicarse con la API
api = ApiService()

# Nombre de la tabla en la API
TABLA = 'rol'

# Nombre del campo clave primaria (entero, no texto)
CLAVE = 'id'


# ══════════════════════════════════════════════
# LISTAR REGISTROS (GET)
# ══════════════════════════════════════════════

# Responde a GET /rol
@bp.route('/rol')
def index():
    """Muestra la tabla de roles con formulario opcional."""
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
        # Convertir ambos lados a str() para comparar de forma segura
        # (la API puede retornar id como int y la URL lo trae como str)
        registro = next(
            (r for r in registros if str(r.get(CLAVE)) == str(valor_clave)),
            None  # Retorna None si no encuentra coincidencia
        )

    # Renderizar la pagina pasando las variables al template
    return render_template('pages/rol.html',
        registros=registros,                  # Lista de roles para la tabla HTML
        mostrar_formulario=mostrar_formulario, # Controla visibilidad del formulario
        editando=editando,                     # Controla modo crear vs editar
        registro=registro,                     # Datos del registro a editar (o None)
        limite=limite                          # Mantener el valor de limite en el input
    )


# ══════════════════════════════════════════════
# CREAR REGISTRO (POST)
# ══════════════════════════════════════════════

# Solo acepta peticiones POST (envio de formulario)
@bp.route('/rol/crear', methods=['POST'])
def crear():
    """Crea un nuevo registro de rol."""
    # Leer los campos del formulario.
    # 'id' es entero: se usa type=int para convertir automaticamente.
    datos = {
        'id':     request.form.get('id', 0, type=int),  # Clave primaria (entero, defecto 0)
        'nombre': request.form.get('nombre', '')          # Nombre del rol (texto)
    }

    # Enviar POST a la API y obtener resultado
    exito, mensaje = api.crear(TABLA, datos)

    # Guardar alerta (verde si exito, roja si error) y redirigir al listado
    flash(mensaje, 'success' if exito else 'danger')
    return redirect(url_for('rol.index'))


# ══════════════════════════════════════════════
# ACTUALIZAR REGISTRO (POST)
# ══════════════════════════════════════════════

@bp.route('/rol/actualizar', methods=['POST'])
def actualizar():
    """Actualiza un registro existente de rol."""
    # Leer la clave primaria (id) del registro a actualizar
    valor = request.form.get('id', '')

    # Solo el campo editable (sin la clave primaria, que va en la URL)
    datos = {
        'nombre': request.form.get('nombre', '')  # Nuevo nombre del rol
    }

    # Enviar PUT a la API: /api/rol/id/{valor}
    exito, mensaje = api.actualizar(TABLA, CLAVE, valor, datos)

    # Guardar alerta y redirigir
    flash(mensaje, 'success' if exito else 'danger')
    return redirect(url_for('rol.index'))


# ══════════════════════════════════════════════
# ELIMINAR REGISTRO (POST)
# ══════════════════════════════════════════════

@bp.route('/rol/eliminar', methods=['POST'])
def eliminar():
    """Elimina un registro de rol."""
    # Leer la clave primaria (id) desde el campo oculto del formulario de eliminar
    valor = request.form.get('id', '')

    # Enviar DELETE a la API: /api/rol/id/{valor}
    exito, mensaje = api.eliminar(TABLA, CLAVE, valor)

    # Guardar alerta y redirigir
    flash(mensaje, 'success' if exito else 'danger')
    return redirect(url_for('rol.index'))
