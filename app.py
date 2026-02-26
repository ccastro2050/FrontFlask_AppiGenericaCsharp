"""
app.py - Punto de entrada de la aplicacion Flask.

Crea la aplicacion, registra los Blueprints (uno por tabla)
e inicia el servidor de desarrollo en el puerto 5100.
"""

# Flask: clase principal del framework web para crear la aplicacion
from flask import Flask

# SECRET_KEY: clave secreta definida en config.py, necesaria para mensajes flash
from config import SECRET_KEY


# ══════════════════════════════════════════════
# CREAR LA APLICACION FLASK
# ══════════════════════════════════════════════

# Flask(__name__) crea la instancia de la aplicacion.
# __name__ le indica a Flask en que modulo esta corriendo (necesario para encontrar templates y static).
app = Flask(__name__)

# La clave secreta es necesaria para los mensajes flash (alertas).
# Flask la usa internamente para firmar las cookies de sesion.
app.secret_key = SECRET_KEY


# ══════════════════════════════════════════════
# REGISTRAR BLUEPRINTS
# Cada Blueprint agrupa las rutas de una tabla.
# Es el equivalente a tener una pagina separada por tabla.
# ══════════════════════════════════════════════

# Importar el Blueprint de cada modulo de rutas.
# 'bp' es la variable que cada archivo exporta con su Blueprint.
# Se renombra con 'as' para evitar conflictos de nombres entre modulos.
from routes.home import bp as home_bp          # Blueprint de la pagina de inicio
from routes.empresa import bp as empresa_bp    # Blueprint CRUD de empresa
from routes.persona import bp as persona_bp    # Blueprint CRUD de persona
from routes.producto import bp as producto_bp  # Blueprint CRUD de producto
from routes.rol import bp as rol_bp            # Blueprint CRUD de rol
from routes.ruta import bp as ruta_bp          # Blueprint CRUD de ruta
from routes.usuario import bp as usuario_bp    # Blueprint CRUD de usuario

# register_blueprint() conecta las rutas del Blueprint a la aplicacion Flask.
# Sin esto, las URLs definidas en cada Blueprint no funcionarian.
app.register_blueprint(home_bp)      # Registra GET /
app.register_blueprint(empresa_bp)   # Registra /empresa, /empresa/crear, etc.
app.register_blueprint(persona_bp)   # Registra /persona, /persona/crear, etc.
app.register_blueprint(producto_bp)  # Registra /producto, /producto/crear, etc.
app.register_blueprint(rol_bp)       # Registra /rol, /rol/crear, etc.
app.register_blueprint(ruta_bp)      # Registra /ruta, /ruta/crear, etc.
app.register_blueprint(usuario_bp)   # Registra /usuario, /usuario/crear, etc.


# ══════════════════════════════════════════════
# INICIAR EL SERVIDOR
# ══════════════════════════════════════════════

# __name__ == '__main__' se cumple solo cuando ejecutamos "python app.py" directamente.
# No se ejecuta si otro archivo importa este modulo.
if __name__ == '__main__':
    # app.run() inicia el servidor de desarrollo de Flask.
    # debug=True: recarga automaticamente al guardar cambios y muestra errores detallados.
    # port=5100: puerto del frontend, diferente al de la API (5034) para evitar conflicto.
    app.run(debug=True, port=5100)
