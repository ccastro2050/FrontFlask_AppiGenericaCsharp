"""
home.py - Blueprint para la pagina de inicio.

Ruta:
    GET /  →  Renderiza la pagina de bienvenida.
"""

# Blueprint: permite agrupar rutas en un modulo independiente
# render_template: funcion que renderiza un archivo HTML Jinja2 y lo retorna como respuesta
from flask import Blueprint, render_template


# ══════════════════════════════════════════════
# CREAR EL BLUEPRINT
# ══════════════════════════════════════════════

# Blueprint('home', __name__) crea un grupo de rutas llamado 'home'.
# 'home' es el nombre interno que se usa con url_for('home.index').
# __name__ le indica a Flask donde buscar templates y archivos estaticos.
bp = Blueprint('home', __name__)


# ══════════════════════════════════════════════
# RUTA PRINCIPAL
# ══════════════════════════════════════════════

# @bp.route('/') registra esta funcion para responder a GET /
# Cuando el usuario navega a http://localhost:5100/ se ejecuta esta funcion.
@bp.route('/')
def index():
    """Renderiza la pagina de inicio con informacion del proyecto."""
    # render_template() busca el archivo 'pages/home.html' en la carpeta templates/,
    # lo procesa con Jinja2 (reemplaza variables, evalua bloques) y retorna el HTML final.
    return render_template('pages/home.html')
