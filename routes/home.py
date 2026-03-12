"""
home.py - Blueprint para la pagina de inicio.

Ruta:
    GET /  →  Renderiza la pagina de bienvenida con info de conexion a la BD.
"""

# Blueprint: permite agrupar rutas en un modulo independiente
# render_template: funcion que renderiza un archivo HTML Jinja2 y lo retorna como respuesta
from flask import Blueprint, render_template

# ApiService: para reutilizar la URL base de la API
from services.api_service import ApiService

# requests: para hacer la llamada al endpoint de diagnostico de la API
import requests


# ══════════════════════════════════════════════
# CREAR EL BLUEPRINT
# ══════════════════════════════════════════════

# Blueprint('home', __name__) crea un grupo de rutas llamado 'home'.
# 'home' es el nombre interno que se usa con url_for('home.index').
# __name__ le indica a Flask donde buscar templates y archivos estaticos.
bp = Blueprint('home', __name__)

# Instancia del servicio para acceder a la URL base de la API
api = ApiService()


# ══════════════════════════════════════════════
# RUTA PRINCIPAL
# ══════════════════════════════════════════════

# @bp.route('/') registra esta funcion para responder a GET /
# Cuando el usuario navega a http://localhost:5100/ se ejecuta esta funcion.
@bp.route('/')
def index():
    """Renderiza la pagina de inicio con informacion del proyecto y conexion a BD."""

    # Intentar obtener el diagnostico de conexion de la API.
    # Endpoint: GET /api/diagnostico/conexion
    # Retorna info del servidor de BD: nombre, proveedor, version, etc.
    diagnostico = None
    try:
        url = f"{api.base_url}/api/diagnostico/conexion"
        respuesta = requests.get(url, timeout=3)
        if respuesta.ok:
            diagnostico = respuesta.json()
    except Exception:
        # Si la API no responde, diagnostico queda como None
        # y el template simplemente no muestra la seccion de conexion
        pass

    # render_template() busca el archivo 'pages/home.html' en la carpeta templates/,
    # lo procesa con Jinja2 (reemplaza variables, evalua bloques) y retorna el HTML final.
    return render_template('pages/home.html', diagnostico=diagnostico)
