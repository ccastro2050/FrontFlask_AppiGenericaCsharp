"""
home.py - Blueprint para la pagina de inicio.

Ruta:
    GET /  →  Renderiza la pagina de bienvenida.
"""

from flask import Blueprint, render_template


# ══════════════════════════════════════════════
# CREAR EL BLUEPRINT
# ══════════════════════════════════════════════

bp = Blueprint('home', __name__)


# ══════════════════════════════════════════════
# RUTA PRINCIPAL
# ══════════════════════════════════════════════

@bp.route('/')
def index():
    """Renderiza la pagina de inicio con informacion del proyecto."""
    return render_template('pages/home.html')
