# Tutorial: Frontend Flask CRUD
# Parte 3: Servicio Generico para la API (ApiService)

En esta parte creamos un servicio reutilizable que encapsula todas las llamadas HTTP a la API. Todos los Blueprints (rutas) lo usaran para comunicarse con el backend.

---

## 3.1 Por que un Servicio

En lugar de que cada ruta haga sus propias llamadas HTTP directamente, centralizamos esa logica en un solo lugar:

```
SIN servicio (malo):                    CON servicio (bueno):
┌──────────────┐                        ┌──────────────┐
│ producto.py  │──► requests.get()      │ producto.py  │──┐
└──────────────┘                        └──────────────┘  │
┌──────────────┐                        ┌──────────────┐  │   ┌────────────┐       ┌─────┐
│ empresa.py   │──► requests.get()      │ empresa.py   │──┼──►│ ApiService │──────►│ API │
└──────────────┘                        └──────────────┘  │   └────────────┘       └─────┘
┌──────────────┐                        ┌──────────────┐  │
│ persona.py   │──► requests.get()      │ persona.py   │──┘
└──────────────┘                        └──────────────┘
Codigo repetido en cada ruta            Codigo en un solo lugar
```

**Ventajas:**
- Si la URL de la API cambia, se modifica en un solo archivo (`config.py`)
- Si el formato de respuesta cambia, se ajusta una sola vez
- Las rutas quedan mas limpias: solo logica de formularios y templates

---

## 3.2 Estructura de las Respuestas de la API

Antes de escribir el servicio, necesitamos entender que devuelve la API.

**Respuesta de GET** (listar registros):
```json
{
    "tabla": "producto",
    "esquema": "por defecto",
    "limite": null,
    "total": 3,
    "datos": [
        { "codigo": "PR001", "nombre": "Laptop", "stock": 10, "valorunitario": 2500000 },
        { "codigo": "PR002", "nombre": "Mouse", "stock": 50, "valorunitario": 35000 },
        { "codigo": "PR003", "nombre": "Teclado", "stock": 30, "valorunitario": 75000 }
    ]
}
```

Lo que nos interesa es la propiedad `datos`, que es una lista de diccionarios. En Python, `respuesta.json()["datos"]` nos da directamente esa lista.

**Respuesta de POST, PUT, DELETE** (crear, actualizar, eliminar):
```json
{
    "estado": 200,
    "mensaje": "Registro creado exitosamente.",
    "tabla": "producto"
}
```

Aqui lo que nos interesa es `mensaje` (para mostrar al usuario) y el codigo HTTP de respuesta (200 = exito).

---

## 3.3 Codigo del ApiService

Creamos el archivo `services/api_service.py`:

```python
"""
api_service.py - Servicio generico que consume la API REST.
"""

import requests
from config import API_BASE_URL


class ApiService:
    """
    Servicio generico para consumir la API REST.

    Metodos:
        listar(tabla, limite)           → lista de diccionarios
        crear(tabla, datos, ...)        → (bool, str)
        actualizar(tabla, clave, ...)   → (bool, str)
        eliminar(tabla, clave, valor)   → (bool, str)
    """

    def __init__(self):
        self.base_url = API_BASE_URL

    # ──────────────────────────────────────────────
    # LISTAR: GET /api/{tabla}
    # ──────────────────────────────────────────────
    def listar(self, tabla, limite=None):
        try:
            url = f"{self.base_url}/api/{tabla}"
            params = {}
            if limite:
                params['limite'] = limite

            respuesta = requests.get(url, params=params)
            datos_json = respuesta.json()
            return datos_json.get("datos", [])

        except requests.RequestException as ex:
            print(f"Error al listar {tabla}: {ex}")
            return []

    # ──────────────────────────────────────────────
    # CREAR: POST /api/{tabla}
    # ──────────────────────────────────────────────
    def crear(self, tabla, datos, campos_encriptar=None):
        try:
            url = f"{self.base_url}/api/{tabla}"
            params = {}
            if campos_encriptar:
                params['camposEncriptar'] = campos_encriptar

            respuesta = requests.post(url, json=datos, params=params)
            contenido = respuesta.json()
            mensaje = contenido.get("mensaje", "Operacion completada.")
            return (respuesta.ok, mensaje)

        except requests.RequestException as ex:
            return (False, f"Error de conexion: {ex}")

    # ──────────────────────────────────────────────
    # ACTUALIZAR: PUT /api/{tabla}/{nombre_clave}/{valor_clave}
    # ──────────────────────────────────────────────
    def actualizar(self, tabla, nombre_clave, valor_clave, datos, campos_encriptar=None):
        try:
            url = f"{self.base_url}/api/{tabla}/{nombre_clave}/{valor_clave}"
            params = {}
            if campos_encriptar:
                params['camposEncriptar'] = campos_encriptar

            respuesta = requests.put(url, json=datos, params=params)
            contenido = respuesta.json()
            mensaje = contenido.get("mensaje", "Operacion completada.")
            return (respuesta.ok, mensaje)

        except requests.RequestException as ex:
            return (False, f"Error de conexion: {ex}")

    # ──────────────────────────────────────────────
    # ELIMINAR: DELETE /api/{tabla}/{nombre_clave}/{valor_clave}
    # ──────────────────────────────────────────────
    def eliminar(self, tabla, nombre_clave, valor_clave):
        try:
            url = f"{self.base_url}/api/{tabla}/{nombre_clave}/{valor_clave}"
            respuesta = requests.delete(url)
            contenido = respuesta.json()
            mensaje = contenido.get("mensaje", "Operacion completada.")
            return (respuesta.ok, mensaje)

        except requests.RequestException as ex:
            return (False, f"Error de conexion: {ex}")
```

---

## 3.4 Explicacion del Codigo

### Constructor

```python
def __init__(self):
    self.base_url = API_BASE_URL
```

La URL base se lee de `config.py`. Todos los metodos la usan para construir las URLs de la API.

### Tipo de retorno: Tupla (bool, str)

```python
def crear(self, tabla, datos, campos_encriptar=None):
    ...
    return (respuesta.ok, mensaje)
```

Los metodos de crear, actualizar y eliminar devuelven una **tupla** con dos valores:
- `respuesta.ok` — `True` si el HTTP status es 200-299, `False` si es 4xx o 5xx
- `mensaje` — Texto de la API para mostrar al usuario

Esto permite en la ruta hacer:

```python
exito, mensaje = api.crear("producto", datos)
if exito:
    flash(mensaje, "success")    # Alerta verde
else:
    flash(mensaje, "danger")     # Alerta roja
```

### Manejo de errores

```python
except requests.RequestException as ex:
    return (False, f"Error de conexion: {ex}")
```

Si la API no esta disponible o hay un error de red, el servicio captura la excepcion y retorna un mensaje de error en lugar de romper la aplicacion.

### f-strings para construir URLs

```python
url = f"{self.base_url}/api/{tabla}/{nombre_clave}/{valor_clave}"
```

Python usa **f-strings** (cadenas con `f""`) para insertar variables dentro de texto. Las variables van entre `{}`.

### json=datos vs data=datos

```python
respuesta = requests.post(url, json=datos)
```

El parametro `json=datos` hace dos cosas automaticamente:
1. Convierte el diccionario Python a JSON
2. Agrega el header `Content-Type: application/json`

---

## 3.5 Como se Usa en las Rutas

Cada Blueprint instancia el servicio y lo usa asi:

```python
# routes/empresa.py
from services.api_service import ApiService

api = ApiService()

# Listar
registros = api.listar("empresa")

# Crear
exito, mensaje = api.crear("empresa", {"codigo": "E01", "nombre": "Mi Empresa"})

# Actualizar
exito, mensaje = api.actualizar("empresa", "codigo", "E01", {"nombre": "Nuevo Nombre"})

# Eliminar
exito, mensaje = api.eliminar("empresa", "codigo", "E01")
```

---

## 3.6 Commit

```bash
git add .
git commit -m "Agregar ApiService: servicio generico para consumir la API CRUD"
```

---

## Siguiente Parte

En la **Parte 4** crearemos el layout visual con Jinja2: la plantilla base con sidebar, la barra superior, el menu de navegacion y los mensajes flash.
