"""
app.py - Punto de entrada de la aplicacion Flask.

Crea la aplicacion, registra los Blueprints (uno por tabla)
e inicia el servidor de desarrollo en el puerto 5100.
"""

from flask import Flask
from config import SECRET_KEY


# ══════════════════════════════════════════════
# CREAR LA APLICACION FLASK
# ══════════════════════════════════════════════

app = Flask(__name__)

# La clave secreta es necesaria para los mensajes flash (alertas)
app.secret_key = SECRET_KEY


# ══════════════════════════════════════════════
# REGISTRAR BLUEPRINTS
# Cada Blueprint agrupa las rutas de una tabla.
# Es el equivalente a tener una pagina separada por tabla.
# ══════════════════════════════════════════════

from routes.home import bp as home_bp
from routes.empresa import bp as empresa_bp
from routes.persona import bp as persona_bp
from routes.producto import bp as producto_bp
from routes.rol import bp as rol_bp
from routes.ruta import bp as ruta_bp
from routes.usuario import bp as usuario_bp

app.register_blueprint(home_bp)
app.register_blueprint(empresa_bp)
app.register_blueprint(persona_bp)
app.register_blueprint(producto_bp)
app.register_blueprint(rol_bp)
app.register_blueprint(ruta_bp)
app.register_blueprint(usuario_bp)


# ══════════════════════════════════════════════
# INICIAR EL SERVIDOR
# ══════════════════════════════════════════════

if __name__ == '__main__':
    # Puerto 5100 para no chocar con la API (puerto 5034)
    # debug=True recarga automaticamente al guardar cambios
    app.run(debug=True, port=5100)
