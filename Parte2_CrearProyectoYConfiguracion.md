# Tutorial: Frontend Flask CRUD
# Parte 2: Crear el Proyecto y Configuracion

En esta parte creamos el proyecto Flask, instalamos las dependencias, configuramos la conexion a la API y hacemos el primer commit en Git.

---

## 2.1 Entorno de Trabajo

En este tutorial trabajaremos con:

- **Visual Studio Code (VS Code)** — Editor de codigo con excelente soporte para Python a traves de la extension "Python" de Microsoft.
- **Terminal** — PowerShell en Windows o bash en Linux/Mac. Se accede desde VS Code con `Ctrl + ` ` (backtick).

---

## 2.2 Crear la Carpeta del Proyecto

En la terminal, nos ubicamos en la carpeta donde se creara el proyecto:

```bash
cd proyectoscsharp
```

Creamos la carpeta del proyecto y entramos:

```bash
mkdir FrontFlask_AppiGenericaCsharp
cd FrontFlask_AppiGenericaCsharp
```

---

## 2.3 Crear Entorno Virtual (Recomendado)

Un entorno virtual aisla las dependencias de este proyecto del resto del sistema:

```bash
python -m venv venv
```

Activar el entorno virtual:

```bash
# Windows (PowerShell)
venv\Scripts\activate

# Linux / Mac
source venv/bin/activate
```

**Que hace este comando:**
- `python -m venv venv` — Crea una carpeta `venv/` con una copia aislada de Python
- Al activarlo, `pip install` solo afecta a este proyecto
- Para desactivar: `deactivate`

---

## 2.4 Crear requirements.txt

Creamos el archivo de dependencias:

```
# requirements.txt
Flask==3.1.0
requests==2.32.3
```

Instalamos las dependencias:

```bash
pip install -r requirements.txt
```

**Que instala:**
- `Flask` — Framework web (incluye Jinja2 para templates y Werkzeug para el servidor)
- `requests` — Libreria HTTP para consumir la API REST

---

## 2.5 Crear la Estructura de Carpetas

```bash
mkdir services routes templates static
mkdir templates/layout templates/components templates/pages
mkdir static/css
```

Creamos los archivos `__init__.py` para que Python reconozca las carpetas como paquetes:

```bash
# Windows
echo # Paquete de servicios > services/__init__.py
echo # Paquete de rutas > routes/__init__.py

# Linux / Mac
echo "# Paquete de servicios" > services/__init__.py
echo "# Paquete de rutas" > routes/__init__.py
```

---

## 2.6 Crear config.py (Configuracion)

Este archivo centraliza la configuracion de la aplicacion. Es el lugar donde se define la URL de la API.

```python
"""
config.py - Configuracion centralizada de la aplicacion Flask.
"""

# URL base de la API REST que consume este frontend.
# La API generica en C# corre en el puerto 5034.
API_BASE_URL = "http://localhost:5034"

# Clave secreta para el manejo de sesiones y mensajes flash.
# Flask la necesita para firmar las cookies de sesion.
SECRET_KEY = "clave-secreta-flask-frontend-2024"
```

**Que hace cada constante:**
- `API_BASE_URL` — La URL completa de la API. Si la API cambia de puerto, solo se modifica aqui
- `SECRET_KEY` — Flask la usa para firmar las cookies de sesion donde viajan los mensajes flash

---

## 2.7 Crear app.py (Punto de Entrada)

Este es el archivo principal que crea la aplicacion Flask y registra todos los Blueprints.

```python
"""
app.py - Punto de entrada de la aplicacion Flask.
"""

from flask import Flask
from config import SECRET_KEY

# Crear la aplicacion Flask
app = Flask(__name__)

# La clave secreta es necesaria para los mensajes flash (alertas)
app.secret_key = SECRET_KEY

# Los Blueprints se registran aqui (los crearemos en las siguientes partes)
# from routes.home import bp as home_bp
# app.register_blueprint(home_bp)

if __name__ == '__main__':
    # Puerto 5100 para no chocar con la API (puerto 5034)
    # debug=True recarga automaticamente al guardar cambios
    app.run(debug=True, port=5100)
```

**Que hace cada parte:**
- `Flask(__name__)` — Crea la instancia de la aplicacion Flask
- `app.secret_key` — Necesario para que funcionen los mensajes flash
- `app.run(debug=True, port=5100)` — Inicia el servidor en el puerto 5100 con recarga automatica

**Puerto 5100:** El frontend corre en el puerto 5100 para no chocar con la API que corre en el 5034.

---

## 2.8 Verificar que Flask Funciona

Ejecutamos la aplicacion:

```bash
python app.py
```

Debemos ver:

```
 * Serving Flask app 'app'
 * Debug mode: on
 * Running on http://127.0.0.1:5100
```

Abrimos `http://localhost:5100` en el navegador. Vera un error 404 (pagina no encontrada) — esto es normal porque todavia no hemos creado ninguna ruta.

Presionar `Ctrl + C` para detener el servidor.

---

## 2.9 Inicializar Git

Inicializamos el repositorio Git:

```bash
git init
```

Creamos un archivo `.gitignore` para excluir archivos innecesarios:

```
# .gitignore

# Entorno virtual
venv/

# Archivos compilados de Python
__pycache__/
*.pyc
*.pyo

# Archivos del sistema
.DS_Store
Thumbs.db

# IDE
.vscode/
.idea/
```

Primer commit:

```bash
git add .
git commit -m "Proyecto inicial: Flask configurado con conexion a API puerto 5034"
```

---

## 2.10 Verificar

Despues de ejecutar estos pasos debes tener:

1. **Carpeta del proyecto** `FrontFlask_AppiGenericaCsharp/` con la estructura de carpetas
2. **Entorno virtual** `venv/` (opcional pero recomendado)
3. **Dependencias instaladas** (Flask y requests)
4. **config.py** con `API_BASE_URL = "http://localhost:5034"`
5. **app.py** configurado en el puerto 5100
6. **Primer commit** en Git

Estructura actual:

```
FrontFlask_AppiGenericaCsharp/
├── app.py
├── config.py
├── requirements.txt
├── .gitignore
├── services/
│   └── __init__.py
├── routes/
│   └── __init__.py
├── templates/
│   ├── layout/
│   ├── components/
│   └── pages/
└── static/
    └── css/
```

---

## Siguiente Parte

En la **Parte 3** crearemos el `ApiService` — un servicio generico reutilizable que encapsula todas las llamadas HTTP a la API (listar, crear, actualizar, eliminar).
