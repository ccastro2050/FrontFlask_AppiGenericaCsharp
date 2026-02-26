# Tutorial: Frontend Flask CRUD
# Parte 1: Conceptos Fundamentales

Este tutorial construye un frontend web con **Flask** (Python) que consume una API REST generica para hacer operaciones CRUD (Crear, Leer, Actualizar, Eliminar) sobre tablas de una base de datos.

**Proyecto**: FrontFlask_AppiGenericaCsharp
**API backend**: ApiGenericaCsharp (http://localhost:5034)

---

## 1.1 Que es Flask

Flask es un **microframework** web de Python creado por Armin Ronacher en 2010. Se llama "micro" porque viene con lo minimo necesario para funcionar y se le agregan extensiones segun se necesite.

### Caracteristicas principales

```
┌─────────────────────────────────────────────────────────────┐
│                         FLASK                                │
│                                                              │
│  Framework web ligero y flexible para Python.                │
│  El codigo Python se ejecuta en el SERVIDOR.                 │
│  El navegador recibe HTML generado por templates Jinja2.     │
│                                                              │
│  Ventaja: Simple, facil de aprender, gran comunidad.         │
│  Ventaja: No impone una estructura fija (tu decides).        │
│  Desventaja: Para proyectos grandes se necesita mas config.  │
│                                                              │
│  >>> Ideal para frontends CRUD y prototipos rapidos <<<      │
└─────────────────────────────────────────────────────────────┘
```

### Como funciona Flask (nuestro caso)

```
┌──────────────┐       HTTP Request       ┌──────────────────┐
│  NAVEGADOR   │ ─────────────────────────►│  SERVIDOR FLASK  │
│              │                           │                  │
│  Recibe HTML │  1. Usuario hace click    │  Codigo Python   │
│  completo    │  o envia formulario       │  Rutas           │
│  cada vez    │  ─────────────────────►   │  Templates       │
│              │                           │                  │
│              │  2. Flask ejecuta Python   │  2. Llama a la   │
│              │     y genera HTML         │     API REST     │
│              │                           │                  │
│              │  3. HTML completo          │  3. Renderiza    │
│              │  ◄─────────────────────── │     template     │
└──────────────┘                           └──────────────────┘
```

A diferencia de frameworks SPA (Single Page Application), Flask genera una pagina HTML completa en cada peticion. El navegador recibe HTML listo para mostrar — no ejecuta logica en el cliente.

---

## 1.2 Rutas y Blueprints

En Flask, una **ruta** es una funcion de Python que responde a una URL especifica. Un **Blueprint** es una forma de agrupar rutas relacionadas en un modulo independiente.

### Ejemplo basico de ruta

```python
from flask import Flask

app = Flask(__name__)

@app.route('/producto')           # ← URL que activa esta funcion
def listar_productos():
    return '<h1>Lista de Productos</h1>'  # ← HTML que recibe el navegador
```

### Ejemplo con Blueprint

```python
# routes/producto.py
from flask import Blueprint

bp = Blueprint('producto', __name__)  # ← Crear Blueprint

@bp.route('/producto')                # ← Ruta dentro del Blueprint
def index():
    return '<h1>Lista de Productos</h1>'
```

```python
# app.py
from routes.producto import bp as producto_bp
app.register_blueprint(producto_bp)   # ← Registrar en la app
```

**Ventaja de Blueprints:**
- Cada tabla tiene su propio archivo de rutas (empresa.py, persona.py, etc.)
- El codigo queda organizado y facil de mantener
- Se pueden agregar mas tablas sin tocar los archivos existentes

---

## 1.3 Templates Jinja2

Jinja2 es el motor de templates que viene incluido con Flask. Permite mezclar HTML con logica de Python para generar paginas dinamicas.

### Mostrar datos (Python → HTML)

```html
<p>Hola, {{ nombre }}</p>          {# Muestra el valor de la variable #}
```

El doble corchete `{{ }}` imprime el valor de una variable que Flask le pasa al template.

### Condicionales

```html
{% if registros %}
    <table>...</table>
{% else %}
    <p>No hay registros.</p>
{% endif %}
```

### Bucles

```html
{% for reg in registros %}
    <tr>
        <td>{{ reg.codigo }}</td>
        <td>{{ reg.nombre }}</td>
    </tr>
{% endfor %}
```

### Herencia de templates

Jinja2 permite que un template "herede" de otro para reutilizar la estructura comun:

```
base.html (define sidebar, topbar, area de contenido)
    │
    ├── home.html      (rellena solo el area de contenido)
    ├── empresa.html   (rellena solo el area de contenido)
    └── producto.html  (rellena solo el area de contenido)
```

**Template padre (base.html):**
```html
<html>
<body>
    <nav>Menu lateral...</nav>
    <main>
        {% block content %}{% endblock %}     {# Hueco para el contenido #}
    </main>
</body>
</html>
```

**Template hijo (producto.html):**
```html
{% extends 'layout/base.html' %}             {# Hereda de base.html #}

{% block content %}                           {# Rellena el hueco #}
    <h3>Productos</h3>
    <table>...</table>
{% endblock %}
```

---

## 1.4 Formularios HTML y Metodos HTTP

En Flask, los formularios HTML son la forma principal de recibir datos del usuario. No hay enlace bidireccional automatico — el usuario llena el formulario, lo envia, y Flask lo procesa.

### Formulario basico

```html
<form method="POST" action="/producto/crear">
    <input name="codigo" type="text" />       {# name = clave del campo #}
    <input name="nombre" type="text" />
    <button type="submit">Guardar</button>
</form>
```

### Recibir datos en Flask

```python
@bp.route('/producto/crear', methods=['POST'])
def crear():
    codigo = request.form.get('codigo')       # ← Lee el valor del input "codigo"
    nombre = request.form.get('nombre')       # ← Lee el valor del input "nombre"
    # ... procesar datos ...
    return redirect(url_for('producto.index'))
```

### Metodos HTTP

| Metodo | Uso | Ejemplo |
|--------|-----|---------|
| GET | Obtener datos / mostrar pagina | `GET /empresa` → lista de empresas |
| POST | Enviar datos / formularios | `POST /empresa/crear` → crear registro |

En nuestro proyecto usamos GET para mostrar las paginas y POST para crear, actualizar y eliminar registros.

---

## 1.5 Mensajes Flash

Flask tiene un sistema de **mensajes flash** para mostrar notificaciones entre peticiones. Funciona asi:

```
  1. Usuario envia formulario (POST /empresa/crear)
              │
              ▼
  2. Flask procesa el formulario y llama a la API
              │
              ▼
  3. Flask guarda un mensaje flash:
     flash("Registro creado exitosamente.", "success")
              │
              ▼
  4. Flask redirige al usuario: redirect("/empresa")
              │
              ▼
  5. El navegador hace GET /empresa (pagina nueva)
              │
              ▼
  6. El template lee los mensajes flash y los muestra como alertas Bootstrap
```

### En la ruta (Python)

```python
from flask import flash, redirect

flash("Registro creado exitosamente.", "success")   # ← Mensaje verde
flash("Error al eliminar.", "danger")               # ← Mensaje rojo
return redirect(url_for('empresa.index'))
```

### En el template (Jinja2)

```html
{% with mensajes = get_flashed_messages(with_categories=true) %}
    {% for categoria, mensaje in mensajes %}
        <div class="alert alert-{{ categoria }}">
            {{ mensaje }}
        </div>
    {% endfor %}
{% endwith %}
```

La categoria (`success` o `danger`) se usa como clase CSS de Bootstrap para determinar el color de la alerta.

---

## 1.6 requests: Como Consumir una API REST desde Python

La libreria `requests` permite hacer peticiones HTTP (GET, POST, PUT, DELETE) a una API desde Python.

En nuestro proyecto, el frontend Flask se comunica con la API generica asi:

```
┌───────────────────┐    HTTP GET/POST/PUT/DELETE    ┌────────────────────┐
│  FLASK            │ ──────────────────────────────►│  API               │
│  (puerto 5100)    │                                │  (puerto 5034)     │
│                   │◄────────────────────────────── │                    │
│  Frontend         │         JSON                   │  ApiGenericaCsharp │
└───────────────────┘                                └────────────────────┘
```

### Las 4 operaciones basicas

| Operacion | Metodo HTTP | Endpoint de la API | Que hace |
|---|---|---|---|
| Listar | GET | `/api/producto` | Obtiene todos los registros |
| Crear | POST | `/api/producto` | Inserta un nuevo registro |
| Actualizar | PUT | `/api/producto/codigo/PR001` | Modifica un registro existente |
| Eliminar | DELETE | `/api/producto/codigo/PR001` | Borra un registro |

### Ejemplo de cada operacion

```python
import requests

BASE = "http://localhost:5034"

# LISTAR - Obtener todos los productos
respuesta = requests.get(f"{BASE}/api/producto")
datos = respuesta.json()["datos"]

# CREAR - Enviar un nuevo producto
datos = {"codigo": "PR099", "nombre": "Laptop HP", "stock": 10, "valorunitario": 2500000}
respuesta = requests.post(f"{BASE}/api/producto", json=datos)

# ACTUALIZAR - Modificar un producto existente
cambios = {"nombre": "Laptop HP Actualizada", "stock": 15}
respuesta = requests.put(f"{BASE}/api/producto/codigo/PR099", json=cambios)

# ELIMINAR - Borrar un producto
respuesta = requests.delete(f"{BASE}/api/producto/codigo/PR099")
```

---

## 1.7 Bootstrap Basico

Bootstrap es una libreria CSS que permite crear interfaces profesionales con solo agregar clases CSS a los elementos HTML. En nuestro proyecto lo cargamos desde CDN.

### Tablas

```html
<table class="table table-striped table-hover">
    <thead class="table-dark">
        <tr>
            <th>Codigo</th>
            <th>Nombre</th>
            <th>Acciones</th>
        </tr>
    </thead>
    <tbody>
        <tr>
            <td>PR001</td>
            <td>Laptop</td>
            <td>
                <a class="btn btn-warning btn-sm">Editar</a>
                <button class="btn btn-danger btn-sm">Eliminar</button>
            </td>
        </tr>
    </tbody>
</table>
```

### Formularios

```html
<div class="mb-3">
    <label class="form-label">Nombre</label>
    <input class="form-control" type="text" name="nombre" />
</div>

<button class="btn btn-primary" type="submit">Guardar</button>
<a class="btn btn-secondary" href="/producto">Cancelar</a>
```

### Botones

| Clase | Color | Uso tipico |
|---|---|---|
| `btn btn-primary` | Azul | Guardar, Crear |
| `btn btn-success` | Verde | Confirmar |
| `btn btn-warning` | Amarillo | Editar |
| `btn btn-danger` | Rojo | Eliminar |
| `btn btn-secondary` | Gris | Cancelar |
| `btn btn-sm` | (pequeño) | Botones dentro de tablas |

### Alertas

```html
<div class="alert alert-success">Registro creado exitosamente.</div>
<div class="alert alert-danger">Error al eliminar el registro.</div>
```

---

## 1.8 Estructura del Proyecto

Este es el mapa del proyecto que construiremos:

```
FrontFlask_AppiGenericaCsharp/
│
├── app.py                          ← Punto de entrada. Crea la app Flask
│                                     y registra los Blueprints.
│
├── config.py                       ← Configuracion (URL de la API, clave secreta).
│
├── requirements.txt                ← Dependencias Python (Flask, requests).
│
├── services/
│   ├── __init__.py
│   └── api_service.py              ← Servicio que hace las llamadas HTTP a la API.
│                                     Metodos: listar, crear, actualizar, eliminar.
│
├── routes/                         ← Blueprints (uno por tabla).
│   ├── __init__.py
│   ├── home.py                     ← Ruta GET /
│   ├── empresa.py                  ← Rutas CRUD /empresa/*
│   ├── persona.py                  ← Rutas CRUD /persona/*
│   ├── producto.py                 ← Rutas CRUD /producto/*
│   ├── rol.py                      ← Rutas CRUD /rol/*
│   ├── ruta.py                     ← Rutas CRUD /ruta/*
│   └── usuario.py                  ← Rutas CRUD /usuario/*
│
├── templates/                      ← Templates Jinja2.
│   ├── layout/
│   │   └── base.html               ← Plantilla base (sidebar + topbar + flash).
│   ├── components/
│   │   └── nav_menu.html           ← Menu de navegacion lateral.
│   └── pages/
│       ├── home.html               ← Pagina de bienvenida.
│       ├── empresa.html            ← CRUD de empresa.
│       ├── persona.html            ← CRUD de persona.
│       ├── producto.html           ← CRUD de producto.
│       ├── rol.html                ← CRUD de rol.
│       ├── ruta.html               ← CRUD de ruta.
│       └── usuario.html            ← CRUD de usuario.
│
└── static/
    └── css/
        └── app.css                 ← Estilos del layout (sidebar, topbar, nav).
```

---

## 1.9 Flujo Completo de una Operacion

Cuando el usuario hace click en "Eliminar" un producto, esto es lo que sucede:

```
  1. Usuario hace click en "Eliminar"
              │
              ▼
  2. El navegador envia POST /producto/eliminar (formulario oculto)
              │
              ▼
  3. Flask ejecuta la funcion eliminar() en routes/producto.py
              │
              ▼
  4. La funcion llama a api.eliminar("producto", "codigo", "PR001")
              │
              ▼
  5. ApiService hace: DELETE http://localhost:5034/api/producto/codigo/PR001
              │
              ▼
  6. La API recibe la peticion y ejecuta el SQL en la base de datos
              │
              ▼
  7. La API responde: { "estado": 200, "mensaje": "Registro eliminado exitosamente." }
              │
              ▼
  8. ApiService retorna la tupla (True, "Registro eliminado exitosamente.")
              │
              ▼
  9. Flask guarda el mensaje con flash() y redirige a GET /producto
              │
              ▼
  10. El navegador carga /producto: Flask lista los registros y renderiza el template
              │
              ▼
  11. El template muestra la tabla actualizada y la alerta verde de exito
```

---

## 1.10 Tablas que Vamos a Gestionar

Estas son las 6 tablas de la base de datos que gestionaremos (tablas maestras sin clave foranea):

| Tabla | Columnas | Clave | Descripcion |
|---|---|---|---|
| empresa | codigo, nombre | codigo | Empresas registradas |
| persona | codigo, nombre, email, telefono | codigo | Personas (clientes potenciales) |
| producto | codigo, nombre, stock, valorunitario | codigo | Catalogo de productos |
| rol | id, nombre | id | Roles del sistema |
| ruta | ruta, descripcion | ruta | Rutas de navegacion/permisos |
| usuario | email, contrasena | email | Usuarios del sistema |

Cada tabla tendra su propio Blueprint (rutas) y template (pagina HTML) con las 4 operaciones CRUD completas.

---

## 1.11 Prerequisitos

Antes de comenzar necesitas tener instalado:

**Python 3.10+**
```bash
python --version
pip --version
```

**Visual Studio Code** con la extension **Python** (Microsoft)

**Git**
```bash
git --version
```

**La API ApiGenericaCsharp** funcionando en http://localhost:5034

**Una base de datos** (PostgreSQL, SQL Server, MySQL, etc.) con las tablas creadas y accesible desde la API

---

## Siguiente Parte

En la **Parte 2** crearemos el proyecto, instalaremos las dependencias, configuraremos la conexion a la API, y haremos el primer commit en Git.
