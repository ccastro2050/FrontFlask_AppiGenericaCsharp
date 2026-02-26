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

# Blueprint: agrupa rutas en un modulo independiente
# render_template: renderiza un archivo HTML Jinja2
# request: objeto que contiene los datos de la peticion HTTP (parametros URL, formulario)
# redirect: redirige el navegador a otra URL (codigo 302)
# url_for: genera una URL a partir del nombre del Blueprint y la funcion
# flash: guarda un mensaje temporal en la sesion para mostrarlo despues del redirect
from flask import Blueprint, render_template, request, redirect, url_for, flash

# ApiService: clase que contiene los metodos CRUD para comunicarse con la API REST
from services.api_service import ApiService


# ══════════════════════════════════════════════
# CONFIGURACION DEL BLUEPRINT
# ══════════════════════════════════════════════

# Crear el Blueprint con nombre 'empresa'. Este nombre se usa en url_for('empresa.index').
bp = Blueprint('empresa', __name__)

# Crear una instancia del servicio para hacer las llamadas HTTP a la API
api = ApiService()

# Nombre de la tabla en la API (se pasa a todos los metodos del ApiService)
TABLA = 'empresa'

# Nombre del campo que es clave primaria en esta tabla
CLAVE = 'codigo'


# ══════════════════════════════════════════════
# LISTAR REGISTROS (GET)
# ══════════════════════════════════════════════

# @bp.route('/empresa') registra esta funcion para responder a GET /empresa
@bp.route('/empresa')
def index():
    """
    Muestra la tabla de empresas.

    Parametros opcionales en la URL:
        limite : int  - cantidad maxima de registros
        accion : str  - 'nuevo' para formulario vacio, 'editar' para editar
        clave  : str  - valor de la clave primaria del registro a editar
    """
    # request.args.get() lee parametros de la URL (query string).
    # Ejemplo: /empresa?limite=5 → limite = 5
    # type=int convierte el valor a entero automaticamente (None si no viene)
    limite = request.args.get('limite', type=int)

    # Leer que accion quiere el usuario: 'nuevo', 'editar' o '' (ninguna)
    accion = request.args.get('accion', '')

    # Leer el valor de la clave primaria del registro a editar (solo si accion='editar')
    valor_clave = request.args.get('clave', '')

    # Llamar a la API para obtener la lista de registros de la tabla empresa
    registros = api.listar(TABLA, limite)

    # Determinar si hay que mostrar el formulario (True si accion es 'nuevo' o 'editar')
    mostrar_formulario = accion in ('nuevo', 'editar')

    # Determinar si estamos en modo edicion (True solo si accion es 'editar')
    editando = accion == 'editar'

    # Si estamos editando, buscar el registro con la clave indicada en la lista
    registro = None
    if editando and valor_clave:
        # next() con generador: busca el primer registro cuyo 'codigo' coincida.
        # str() convierte ambos valores a texto para comparar de forma segura.
        # Si no encuentra ninguno, retorna None (segundo argumento de next).
        registro = next(
            (r for r in registros if str(r.get(CLAVE)) == valor_clave),
            None
        )

    # render_template() genera el HTML final a partir del template Jinja2.
    # Pasa las variables que el template necesita para renderizar la pagina.
    return render_template('pages/empresa.html',
        registros=registros,                  # Lista de registros para la tabla HTML
        mostrar_formulario=mostrar_formulario, # Bool: muestra u oculta el formulario
        editando=editando,                     # Bool: modo crear vs modo editar
        registro=registro,                     # Diccionario del registro a editar (o None)
        limite=limite                          # Valor del campo limite (para mantenerlo visible)
    )


# ══════════════════════════════════════════════
# CREAR REGISTRO (POST)
# ══════════════════════════════════════════════

# methods=['POST'] indica que esta ruta solo responde a peticiones POST (envio de formulario)
@bp.route('/empresa/crear', methods=['POST'])
def crear():
    """Recibe los datos del formulario y crea un nuevo registro."""
    # request.form.get() lee los campos enviados por el formulario HTML.
    # El nombre ('codigo', 'nombre') debe coincidir con el atributo name="" del <input>.
    # El segundo parametro ('') es el valor por defecto si el campo viene vacio.
    datos = {
        'codigo': request.form.get('codigo', ''),  # Leer el campo 'codigo' del formulario
        'nombre': request.form.get('nombre', '')    # Leer el campo 'nombre' del formulario
    }

    # api.crear() envia un POST a la API con los datos como JSON.
    # Retorna una tupla: (True/False, "mensaje de la API").
    exito, mensaje = api.crear(TABLA, datos)

    # flash() guarda un mensaje en la sesion para mostrarlo en la siguiente pagina.
    # 'success' = alerta verde, 'danger' = alerta roja (clases de Bootstrap).
    flash(mensaje, 'success' if exito else 'danger')

    # redirect() envia al navegador un codigo 302 que lo redirige a GET /empresa.
    # url_for('empresa.index') genera la URL '/empresa' a partir del nombre del Blueprint.
    return redirect(url_for('empresa.index'))


# ══════════════════════════════════════════════
# ACTUALIZAR REGISTRO (POST)
# ══════════════════════════════════════════════

@bp.route('/empresa/actualizar', methods=['POST'])
def actualizar():
    """Recibe los datos del formulario y actualiza el registro existente."""
    # Leer el valor de la clave primaria del registro que se esta editando
    valor = request.form.get('codigo', '')

    # Solo enviamos los campos editables (sin la clave primaria).
    # La clave primaria va en la URL de la API, no en el cuerpo JSON.
    datos = {
        'nombre': request.form.get('nombre', '')  # Solo el campo editable
    }

    # api.actualizar() envia un PUT a: /api/empresa/codigo/{valor}
    # TABLA='empresa', CLAVE='codigo', valor=el codigo del registro, datos=campos a cambiar
    exito, mensaje = api.actualizar(TABLA, CLAVE, valor, datos)

    # Guardar mensaje flash y redirigir a la lista
    flash(mensaje, 'success' if exito else 'danger')
    return redirect(url_for('empresa.index'))


# ══════════════════════════════════════════════
# ELIMINAR REGISTRO (POST)
# ══════════════════════════════════════════════

@bp.route('/empresa/eliminar', methods=['POST'])
def eliminar():
    """Elimina el registro identificado por su clave primaria."""
    # Leer el valor de la clave primaria desde el campo oculto del formulario de eliminar
    valor = request.form.get('codigo', '')

    # api.eliminar() envia un DELETE a: /api/empresa/codigo/{valor}
    exito, mensaje = api.eliminar(TABLA, CLAVE, valor)

    # Guardar mensaje flash y redirigir a la lista
    flash(mensaje, 'success' if exito else 'danger')
    return redirect(url_for('empresa.index'))
