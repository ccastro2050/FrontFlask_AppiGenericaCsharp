# FrontFlask_AppiGenericaCsharp

Frontend web desarrollado con **Flask** (Python) que consume una API REST genérica en C#
para realizar operaciones CRUD sobre las tablas de la base de datos `bdfacturas`.

---

## Tabla de contenido

- [Descripción general](#descripción-general)
- [Arquitectura del proyecto](#arquitectura-del-proyecto)
- [Estructura de carpetas](#estructura-de-carpetas)
- [Requisitos previos](#requisitos-previos)
- [Instalación](#instalación)
- [Ejecución](#ejecución)
- [Configuración](#configuración)
- [Tablas disponibles](#tablas-disponibles)
- [Cómo funciona el CRUD](#cómo-funciona-el-crud)
- [Capa de servicio (ApiService)](#capa-de-servicio-apiservice)
- [Rutas y Blueprints](#rutas-y-blueprints)
- [Templates Jinja2](#templates-jinja2)
- [Estilos y diseño responsive](#estilos-y-diseño-responsive)
- [JavaScript utilizado](#javascript-utilizado)
- [Endpoints del frontend](#endpoints-del-frontend)
- [Tecnologías utilizadas](#tecnologías-utilizadas)
- [Comandos útiles](#comandos-útiles)
- [Solución de problemas](#solución-de-problemas)

---

## Descripción general

Este proyecto es un **frontend web CRUD** que permite gestionar 6 tablas de una base de datos
a través de una interfaz visual con sidebar de navegación, formularios de creación/edición,
tablas de datos y alertas de éxito/error.

**Flujo de la aplicación:**

```
Navegador (usuario)
    │
    ▼
Frontend Flask (:5100)      ← Este proyecto
    │
    ▼
API REST C# (:5034)         ← ApiGenericaCsharp
    │
    ▼
Base de datos                ← PostgreSQL, SQL Server, MySQL, etc.
```

El frontend **no se conecta directamente** a la base de datos. Toda la comunicación
se realiza a través de la API REST.

---

## Arquitectura del proyecto

El proyecto sigue una arquitectura de **3 capas** dentro del frontend:

```
┌─────────────────────────────────────────────────────┐
│  CAPA DE PRESENTACIÓN (templates/)                  │
│  Templates Jinja2 que generan el HTML               │
│  ├── layout/base.html      → Plantilla principal    │
│  ├── components/nav_menu   → Navegación lateral     │
│  └── pages/*.html          → Páginas CRUD           │
├─────────────────────────────────────────────────────┤
│  CAPA DE RUTAS (routes/)                            │
│  Blueprints Flask que manejan las peticiones HTTP   │
│  ├── Reciben formularios del navegador              │
│  ├── Llaman al servicio API                         │
│  └── Renderizan templates con los datos             │
├─────────────────────────────────────────────────────┤
│  CAPA DE SERVICIO (services/)                       │
│  Clase ApiService que consume la API REST           │
│  ├── listar()       → GET /api/{tabla}              │
│  ├── crear()        → POST /api/{tabla}             │
│  ├── actualizar()   → PUT /api/{tabla}/{clave}/{v}  │
│  └── eliminar()     → DELETE /api/{tabla}/{clave}/v │
└─────────────────────────────────────────────────────┘
```

---

## Estructura de carpetas

```
FrontFlask_AppiGenericaCsharp/
│
├── app.py                          # Punto de entrada de la aplicación
├── config.py                       # Configuración (URL de la API, clave secreta)
├── requirements.txt                # Dependencias Python
├── README.md                       # Este archivo
│
├── services/                       # Capa de servicio
│   ├── __init__.py
│   └── api_service.py              # Clase genérica que consume la API REST
│
├── routes/                         # Capa de rutas (Blueprints)
│   ├── __init__.py
│   ├── home.py                     # GET /
│   ├── empresa.py                  # CRUD /empresa
│   ├── persona.py                  # CRUD /persona
│   ├── producto.py                 # CRUD /producto
│   ├── rol.py                      # CRUD /rol
│   ├── ruta.py                     # CRUD /ruta
│   └── usuario.py                  # CRUD /usuario (con encriptación)
│
├── templates/                      # Capa de presentación (Jinja2)
│   ├── layout/
│   │   └── base.html               # Plantilla base (sidebar + topbar + flash)
│   ├── components/
│   │   └── nav_menu.html           # Menú de navegación lateral
│   └── pages/
│       ├── home.html               # Página de inicio
│       ├── empresa.html            # Tabla y formulario de empresas
│       ├── persona.html            # Tabla y formulario de personas
│       ├── producto.html           # Tabla y formulario de productos
│       ├── rol.html                # Tabla y formulario de roles
│       ├── ruta.html               # Tabla y formulario de rutas
│       └── usuario.html            # Tabla y formulario de usuarios
│
└── static/                         # Archivos estáticos
    └── css/
        └── app.css                 # Estilos del layout, sidebar y navegación
```

---

## Requisitos previos

1. **Python 3.10+** instalado ([descargar](https://www.python.org/downloads/))
2. **API GenericaCsharp** corriendo en el puerto `5034`
3. **Base de datos** configurada y accesible desde la API

Verificar la instalación de Python:

```bash
python --version
pip --version
```

---

## Instalación

```bash
# 1. Navegar a la carpeta del proyecto
cd FrontFlask_AppiGenericaCsharp

# 2. (Opcional) Crear un entorno virtual
python -m venv venv
venv\Scripts\activate         # Windows
# source venv/bin/activate    # Linux/Mac

# 3. Instalar las dependencias
pip install -r requirements.txt
```

Las dependencias son solo dos:

| Paquete    | Versión | Descripción                          |
|------------|---------|--------------------------------------|
| `Flask`    | 3.1.0   | Framework web para Python            |
| `requests` | 2.32.3  | Cliente HTTP para consumir la API    |

---

## Ejecución

```bash
# Asegurarse de que la API C# esté corriendo en el puerto 5034

# Iniciar el frontend Flask
python app.py
```

Salida esperada:

```
 * Serving Flask app 'app'
 * Debug mode: on
 * Running on http://127.0.0.1:5100
```

Abrir en el navegador: **http://localhost:5100**

---

## Configuración

Toda la configuración está en `config.py`:

```python
# URL de la API REST que consume este frontend
API_BASE_URL = "http://localhost:5034"

# Clave secreta para sesiones Flask y mensajes flash
SECRET_KEY = "clave-secreta-flask-frontend-2024"
```

Para cambiar el puerto del frontend, modificar la última línea de `app.py`:

```python
app.run(debug=True, port=5100)   # Cambiar 5100 por el puerto deseado
```

---

## Tablas disponibles

| Tabla     | Clave primaria | Campos                                    | Especial            |
|-----------|---------------|-------------------------------------------|---------------------|
| Empresa   | `codigo`      | codigo, nombre                             | —                   |
| Persona   | `codigo`      | codigo, nombre, email, telefono            | —                   |
| Producto  | `codigo`      | codigo, nombre, stock, valorunitario       | Campos numéricos    |
| Rol       | `id`          | id, nombre                                 | Clave numérica      |
| Ruta      | `ruta`        | ruta, descripcion                          | Clave = nombre tabla |
| Usuario   | `email`       | email, contrasena                          | Encriptación bcrypt |

---

## Cómo funciona el CRUD

Cada tabla tiene 4 operaciones. El flujo completo para cada una:

### Listar (GET)

```
Navegador  ──GET /empresa──▶  Flask (routes/empresa.py)
                                │
                                ├── api.listar("empresa", limite)
                                │       │
                                │       └── GET http://localhost:5034/api/empresa
                                │              │
                                │              ◀── { "datos": [...] }
                                │
                                └── render_template("pages/empresa.html", registros=...)
                                        │
Navegador  ◀── HTML con la tabla ───────┘
```

### Crear (POST)

```
Navegador  ──POST /empresa/crear──▶  Flask
    (formulario)                       │
                                       ├── api.crear("empresa", datos)
                                       │       │
                                       │       └── POST http://localhost:5034/api/empresa
                                       │              body: { "codigo": "...", "nombre": "..." }
                                       │
                                       ├── flash(mensaje, "success" o "danger")
                                       └── redirect("/empresa")
                                              │
Navegador  ◀── 302 → GET /empresa ────────────┘
```

### Actualizar (POST)

```
1. Clic en "Editar" → GET /empresa?accion=editar&clave=E001
   Flask busca el registro y muestra el formulario con los datos.

2. Clic en "Guardar" → POST /empresa/actualizar
   Flask envía PUT /api/empresa/codigo/E001 con los campos editados.
   Redirige a /empresa con mensaje flash.
```

### Eliminar (POST)

```
1. Clic en "Eliminar" → confirm() del navegador
2. Si acepta → POST /empresa/eliminar (formulario oculto con la clave)
   Flask envía DELETE /api/empresa/codigo/E001
   Redirige a /empresa con mensaje flash.
```

---

## Capa de servicio (ApiService)

`services/api_service.py` contiene una clase genérica que consume la API REST.
Todos los Blueprints la instancian y la usan con el nombre de su tabla.

### Métodos disponibles

```python
api = ApiService()

# Listar registros (retorna lista de diccionarios)
registros = api.listar("empresa", limite=10)

# Crear registro (retorna tupla: exito, mensaje)
exito, msg = api.crear("empresa", {"codigo": "E01", "nombre": "Mi Empresa"})

# Actualizar registro
exito, msg = api.actualizar("empresa", "codigo", "E01", {"nombre": "Nuevo Nombre"})

# Eliminar registro
exito, msg = api.eliminar("empresa", "codigo", "E01")

# Crear con encriptación (solo para usuario)
exito, msg = api.crear("usuario", datos, campos_encriptar="contrasena")
```

### Endpoints de la API que consume

| Método | URL de la API                              | Descripción            |
|--------|--------------------------------------------|------------------------|
| GET    | `/api/{tabla}`                             | Listar registros       |
| GET    | `/api/{tabla}?limite=N`                    | Listar con límite      |
| POST   | `/api/{tabla}`                             | Crear registro         |
| POST   | `/api/{tabla}?camposEncriptar=campo`       | Crear con encriptación |
| PUT    | `/api/{tabla}/{nombre_clave}/{valor_clave}`| Actualizar registro    |
| DELETE | `/api/{tabla}/{nombre_clave}/{valor_clave}`| Eliminar registro      |

---

## Rutas y Blueprints

Cada tabla tiene su propio **Blueprint** (módulo de rutas independiente).
Todos siguen el mismo patrón con 4 rutas:

| Ruta Flask              | Método HTTP | Función       | Descripción                        |
|-------------------------|-------------|---------------|------------------------------------|
| `/{tabla}`              | GET         | `index()`     | Listar + formulario opcional       |
| `/{tabla}/crear`        | POST        | `crear()`     | Crear registro y redirigir         |
| `/{tabla}/actualizar`   | POST        | `actualizar()`| Actualizar registro y redirigir    |
| `/{tabla}/eliminar`     | POST        | `eliminar()`  | Eliminar registro y redirigir      |

### Parámetros GET de la ruta index

El listado acepta parámetros en la URL para controlar el estado de la página:

| Parámetro | Ejemplo                          | Efecto                              |
|-----------|----------------------------------|-------------------------------------|
| `limite`  | `/empresa?limite=5`              | Limita la cantidad de registros     |
| `accion`  | `/empresa?accion=nuevo`          | Muestra el formulario vacío         |
| `accion`  | `/empresa?accion=editar&clave=X` | Muestra el formulario con datos     |
| `clave`   | `&clave=E001`                    | Identifica el registro a editar     |

### Registro de Blueprints en app.py

```python
app.register_blueprint(home_bp)       # GET /
app.register_blueprint(empresa_bp)    # /empresa/*
app.register_blueprint(persona_bp)    # /persona/*
app.register_blueprint(producto_bp)   # /producto/*
app.register_blueprint(rol_bp)        # /rol/*
app.register_blueprint(ruta_bp)       # /ruta/*
app.register_blueprint(usuario_bp)    # /usuario/*
```

---

## Templates Jinja2

Los templates usan **herencia** para reutilizar el layout:

```
base.html                     ← Define la estructura (sidebar + topbar + flash + content)
    │
    ├── {% include nav_menu.html %}   ← Menú lateral (se incluye dentro del sidebar)
    │
    └── {% block content %}    ← Cada página hija define su contenido aquí
         ├── home.html
         ├── empresa.html
         ├── persona.html
         ├── producto.html
         ├── rol.html
         ├── ruta.html
         └── usuario.html
```

### Directivas Jinja2 principales usadas

| Directiva                             | Uso en el proyecto                              |
|---------------------------------------|-------------------------------------------------|
| `{% extends 'layout/base.html' %}`   | Heredar la plantilla base                       |
| `{% block title %}...{% endblock %}`  | Definir el título de la página                  |
| `{% block content %}...{% endblock %}`| Definir el contenido de la página               |
| `{% include 'components/...' %}`      | Incluir el menú de navegación                   |
| `{% if condicion %}...{% endif %}`    | Mostrar/ocultar formulario, tabla, alertas      |
| `{% for reg in registros %}`          | Iterar sobre los registros en la tabla           |
| `{{ variable }}`                      | Imprimir valores (nombres, códigos, etc.)       |
| `{{ url_for('blueprint.funcion') }}`  | Generar URLs de rutas Flask                     |
| `{{ request.path }}`                  | Detectar la página actual para el link activo   |
| `{{ get_flashed_messages(...) }}`     | Mostrar mensajes flash (alertas de éxito/error) |

### Mensajes flash

Flask usa `flash(mensaje, categoria)` para enviar mensajes entre peticiones.
Las categorías usadas son:

- `success` → Alerta verde (operación exitosa)
- `danger` → Alerta roja (error de la API o conexión)

Se muestran en `base.html` como alertas Bootstrap con botón de cerrar.

---

## Estilos y diseño responsive

El archivo `static/css/app.css` implementa un layout con sidebar que se adapta
a pantallas de escritorio y móvil.

### Layout en escritorio (641px+)

```
┌──────────────┬──────────────────────────────────────┐
│              │  Frontend Flask — API GenericaCsharp  │  ← Topbar
│  CRUD        ├──────────────────────────────────────┤
│  Facturas    │                                      │
│              │  [Nueva Empresa]                     │
│  ● Home      │                                      │
│  ● Empresa   │  Limite: [___] [Cargar]              │
│  ● Persona   │                                      │
│  ● Producto  │  ┌──────┬──────────┬─────────┐      │
│  ● Rol       │  │Codigo│ Nombre   │ Acciones │      │
│  ● Ruta      │  ├──────┼──────────┼─────────┤      │
│  ● Usuario   │  │ E001 │ Andes SA │ Ed │ El │      │
│              │  │ E002 │ Centro   │ Ed │ El │      │
│  250px       │  └──────┴──────────┴─────────┘      │
└──────────────┴──────────────────────────────────────┘
```

### Layout en móvil (hasta 640px)

```
┌──────────────────────┐
│ CRUD Facturas    [≡] │  ← Toggle hamburguesa
├──────────────────────┤
│ (menú oculto,        │
│  se abre al tocar ≡) │
├──────────────────────┤
│ Frontend Flask — API │
├──────────────────────┤
│ [Nueva Empresa]      │
│ Limite: [___][Cargar]│
│ ┌──────────────────┐ │
│ │ Tabla responsive │ │
│ └──────────────────┘ │
└──────────────────────┘
```

### Esquema de colores

| Elemento              | Color                                          |
|-----------------------|------------------------------------------------|
| Sidebar (gradiente)   | `rgb(5, 39, 103)` → `#3a0647` (azul a morado) |
| Topbar del sidebar    | `rgba(0, 0, 0, 0.4)` (negro semitransparente)  |
| Topbar del contenido  | `#f7f7f7` (gris claro)                          |
| Link activo           | `rgba(255, 255, 255, 0.37)` (blanco semi)       |
| Link hover            | `rgba(255, 255, 255, 0.1)`                      |
| Texto links           | `#d7d7d7` (gris claro)                           |

---

## JavaScript utilizado

El proyecto usa **JavaScript mínimo** — solo 2 líneas inline en todo el código:

| Línea                                          | Ubicación           | Función                          |
|------------------------------------------------|---------------------|----------------------------------|
| `onclick="this.parentElement.remove()"`        | `base.html`         | Cerrar alertas flash             |
| `onsubmit="return confirm('Eliminar...?')"`   | Cada página CRUD    | Confirmar antes de eliminar      |

El menú responsive (hamburguesa) funciona **sin JavaScript**, usando un checkbox CSS:

```html
<input type="checkbox" class="navbar-toggler" />  <!-- CSS: checked → mostrar menú -->
```

---

## Endpoints del frontend

### Página de inicio

| Método | URL   | Descripción                    |
|--------|-------|--------------------------------|
| GET    | `/`   | Página de bienvenida           |

### CRUD por tabla

Todas las tablas siguen el mismo patrón de URLs:

| Método | URL                              | Descripción                              |
|--------|----------------------------------|------------------------------------------|
| GET    | `/empresa`                       | Listar empresas                          |
| GET    | `/empresa?limite=5`              | Listar con límite                        |
| GET    | `/empresa?accion=nuevo`          | Mostrar formulario de crear              |
| GET    | `/empresa?accion=editar&clave=X` | Mostrar formulario de editar             |
| POST   | `/empresa/crear`                 | Procesar creación y redirigir            |
| POST   | `/empresa/actualizar`            | Procesar actualización y redirigir       |
| POST   | `/empresa/eliminar`              | Procesar eliminación y redirigir         |

Reemplazar `/empresa` por `/persona`, `/producto`, `/rol`, `/ruta` o `/usuario`.

---

## Tecnologías utilizadas

| Tecnología     | Versión | Uso                                            |
|----------------|---------|------------------------------------------------|
| Python         | 3.10+   | Lenguaje del backend del frontend              |
| Flask          | 3.1.0   | Framework web (rutas, templates, flash)         |
| Jinja2         | 3.1+    | Motor de templates HTML                         |
| requests       | 2.32.3  | Cliente HTTP para consumir la API REST          |
| Bootstrap      | 5.3.3   | Framework CSS (CDN, no instalado localmente)    |
| HTML5          | —       | Estructura de las páginas                        |
| CSS3           | —       | Estilos personalizados del layout               |

---

## Comandos útiles

```bash
# Instalar dependencias
pip install -r requirements.txt

# Ejecutar el frontend (modo desarrollo con recarga automática)
python app.py

# Verificar que Flask responde
curl http://localhost:5100/

# Verificar que la API responde
curl http://localhost:5034/api/empresa

# Crear entorno virtual (recomendado)
python -m venv venv
venv\Scripts\activate           # Windows
source venv/bin/activate        # Linux/Mac

# Ver dependencias instaladas
pip list

# Congelar dependencias actuales
pip freeze > requirements.txt
```

---

## Solución de problemas

### La página muestra "No se encontraron registros"

- Verificar que la API C# esté corriendo en `http://localhost:5034`
- Verificar que la base de datos tenga datos en la tabla consultada
- Revisar la consola de Flask por errores de conexión

### Error "Connection refused" en la consola de Flask

- La API no está corriendo. Iniciarla con `dotnet run` en el proyecto ApiGenericaCsharp
- Verificar que el puerto de la API coincida con `API_BASE_URL` en `config.py`

### El formulario no guarda / no elimina

- Verificar que la API permite operaciones de escritura (POST, PUT, DELETE)
- Revisar las alertas flash — si son rojas, contienen el mensaje de error de la API
- Verificar que la tabla no esté en `TablasProhibidas` del `appsettings.json` de la API

### El CSS no carga (página sin estilos)

- Verificar que la carpeta `static/css/app.css` exista
- En el navegador, verificar que `http://localhost:5100/static/css/app.css` responde
- Limpiar caché del navegador (Ctrl+Shift+R)

### Error al instalar Flask

```bash
# Si pip no está actualizado
python -m pip install --upgrade pip

# Si hay conflicto de versiones, instalar sin versión fija
pip install Flask requests
```
