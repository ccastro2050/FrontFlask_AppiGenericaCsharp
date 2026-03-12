# Guia de Uso: EntidadesController desde el Frontend Flask

Esta guia explica como consumir los endpoints del `EntidadesController` de la API generica en C#
desde el frontend Flask. La API corre en `http://localhost:5035` y el frontend Flask en el puerto `5100`.

---

## 1. Vista General de Endpoints

La API expone un unico controlador generico que sirve para **cualquier tabla** de la base de datos.
La tabla se indica como parte de la URL: `/api/{tabla}`.

| Metodo | Ruta                                    | Descripcion                          |
|--------|-----------------------------------------|--------------------------------------|
| GET    | `/api/{tabla}`                          | Listar todos los registros           |
| GET    | `/api/{tabla}?limite=N`                 | Listar con limite de registros       |
| GET    | `/api/{tabla}/{nombreClave}/{valor}`    | Filtrar por clave primaria           |
| POST   | `/api/{tabla}`                          | Crear un nuevo registro              |
| PUT    | `/api/{tabla}/{nombreClave}/{valorClave}` | Actualizar un registro existente  |
| DELETE | `/api/{tabla}/{nombreClave}/{valorClave}` | Eliminar un registro              |
| POST   | `/api/{tabla}/verificar-contrasena`     | Verificar contrasena BCrypt          |
| GET    | `/api/info`                             | Informacion general de la API        |

### Parametros opcionales (query string)

| Parametro         | Tipo   | Descripcion                                              |
|-------------------|--------|----------------------------------------------------------|
| `esquema`         | string | Esquema de base de datos (por defecto usa el configurado)|
| `limite`          | int    | Cantidad maxima de registros a retornar                  |
| `camposEncriptar` | string | Campos a encriptar con BCrypt antes de guardar           |

### Tablas disponibles en la base de datos

`empresa`, `persona`, `producto`, `rol`, `ruta`, `usuario`, `cliente`, `vendedor`, `factura`, `productosporfactura`, `rutarol`

---

## 2. Como el ApiService de Flask Mapea a Cada Endpoint

La clase `ApiService` (en `services/api_service.py`) encapsula las llamadas HTTP a la API.
Cada metodo corresponde a una operacion CRUD:

### Configuracion base

```python
from config import API_BASE_URL  # "http://localhost:5035"

class ApiService:
    def __init__(self):
        self.base_url = API_BASE_URL  # http://localhost:5035
```

### Mapeo metodo por metodo

| Metodo ApiService                                          | Verbo HTTP | Endpoint API                                      |
|------------------------------------------------------------|------------|----------------------------------------------------|
| `listar(tabla, limite)`                                    | GET        | `/api/{tabla}?limite=N`                            |
| `crear(tabla, datos, campos_encriptar)`                    | POST       | `/api/{tabla}?camposEncriptar=campo`               |
| `actualizar(tabla, nombre_clave, valor_clave, datos, campos_encriptar)` | PUT | `/api/{tabla}/{nombre_clave}/{valor_clave}` |
| `eliminar(tabla, nombre_clave, valor_clave)`               | DELETE     | `/api/{tabla}/{nombre_clave}/{valor_clave}`        |

### Detalle de cada metodo

**listar(tabla, limite=None)** - Retorna una lista de diccionarios

```python
# Internamente hace:
url = f"{self.base_url}/api/{tabla}"       # http://localhost:5035/api/producto
params = {}
if limite:
    params['limite'] = limite               # ?limite=5
respuesta = requests.get(url, params=params)
return respuesta.json().get("datos", [])    # Extrae la lista del campo "datos"
```

**crear(tabla, datos, campos_encriptar=None)** - Retorna tupla (bool, str)

```python
# Internamente hace:
url = f"{self.base_url}/api/{tabla}"       # http://localhost:5035/api/producto
params = {}
if campos_encriptar:
    params['camposEncriptar'] = campos_encriptar  # ?camposEncriptar=contrasena
respuesta = requests.post(url, json=datos, params=params)
return (respuesta.ok, respuesta.json().get("mensaje", "Operacion completada."))
```

**actualizar(tabla, nombre_clave, valor_clave, datos, campos_encriptar=None)** - Retorna tupla (bool, str)

```python
# Internamente hace:
url = f"{self.base_url}/api/{tabla}/{nombre_clave}/{valor_clave}"
# Ejemplo: http://localhost:5035/api/producto/codigo/PR001
respuesta = requests.put(url, json=datos, params=params)
return (respuesta.ok, respuesta.json().get("mensaje", "Operacion completada."))
```

**eliminar(tabla, nombre_clave, valor_clave)** - Retorna tupla (bool, str)

```python
# Internamente hace:
url = f"{self.base_url}/api/{tabla}/{nombre_clave}/{valor_clave}"
# Ejemplo: http://localhost:5035/api/empresa/codigo/E001
respuesta = requests.delete(url)
return (respuesta.ok, respuesta.json().get("mensaje", "Operacion completada."))
```

---

## 3. Ejemplos desde las Rutas Flask (Codigo Real del Proyecto)

Cada tabla tiene un Blueprint en `routes/`. Todos siguen el mismo patron usando `ApiService`.

### 3.1 Producto (clave: codigo, campos: codigo, nombre, stock, valorunitario)

**Listar productos:**

```python
# routes/producto.py
TABLA = 'producto'
CLAVE = 'codigo'
api = ApiService()

# En la funcion index():
limite = request.args.get('limite', type=int)  # Lee ?limite=N de la URL
registros = api.listar(TABLA, limite)
# registros = [{"codigo": "PR001", "nombre": "Laptop", "stock": 10, "valorunitario": 2500.00}, ...]
```

**Crear producto:**

```python
# En la funcion crear():
datos = {
    'codigo':        request.form.get('codigo', ''),
    'nombre':        request.form.get('nombre', ''),
    'stock':         request.form.get('stock', 0, type=int),
    'valorunitario': request.form.get('valorunitario', 0, type=float)
}
exito, mensaje = api.crear(TABLA, datos)
# Envia POST a http://localhost:5035/api/producto con JSON:
# {"codigo": "PR001", "nombre": "Laptop", "stock": 10, "valorunitario": 2500.00}
```

**Actualizar producto:**

```python
# En la funcion actualizar():
valor = request.form.get('codigo', '')  # PR001
datos = {
    'nombre':        request.form.get('nombre', ''),
    'stock':         request.form.get('stock', 0, type=int),
    'valorunitario': request.form.get('valorunitario', 0, type=float)
}
exito, mensaje = api.actualizar(TABLA, CLAVE, valor, datos)
# Envia PUT a http://localhost:5035/api/producto/codigo/PR001
```

**Eliminar producto:**

```python
# En la funcion eliminar():
valor = request.form.get('codigo', '')  # PR001
exito, mensaje = api.eliminar(TABLA, CLAVE, valor)
# Envia DELETE a http://localhost:5035/api/producto/codigo/PR001
```

### 3.2 Empresa (clave: codigo, campos: codigo, nombre)

```python
# routes/empresa.py
TABLA = 'empresa'
CLAVE = 'codigo'

# Crear empresa
datos = {'codigo': 'E001', 'nombre': 'Mi Empresa SAS'}
exito, mensaje = api.crear(TABLA, datos)
# POST http://localhost:5035/api/empresa

# Actualizar empresa
datos = {'nombre': 'Mi Empresa Actualizada SAS'}
exito, mensaje = api.actualizar(TABLA, CLAVE, 'E001', datos)
# PUT http://localhost:5035/api/empresa/codigo/E001

# Eliminar empresa
exito, mensaje = api.eliminar(TABLA, CLAVE, 'E001')
# DELETE http://localhost:5035/api/empresa/codigo/E001
```

### 3.3 Persona (clave: codigo, campos: codigo, nombre, email, telefono)

```python
# routes/persona.py
TABLA = 'persona'
CLAVE = 'codigo'

# Crear persona
datos = {
    'codigo':   'PER001',
    'nombre':   'Carlos Castro',
    'email':    'carlos@email.com',
    'telefono': '3001234567'
}
exito, mensaje = api.crear(TABLA, datos)
# POST http://localhost:5035/api/persona

# Actualizar persona (solo campos editables, sin la PK)
datos = {
    'nombre':   'Carlos A. Castro',
    'email':    'carlos.castro@email.com',
    'telefono': '3009876543'
}
exito, mensaje = api.actualizar(TABLA, CLAVE, 'PER001', datos)
# PUT http://localhost:5035/api/persona/codigo/PER001
```

### 3.4 Usuario con Encriptacion BCrypt (clave: email, campos: email, contrasena)

```python
# routes/usuario.py
TABLA = 'usuario'
CLAVE = 'email'

# Crear usuario CON contrasena encriptada
datos = {'email': 'admin@sistema.com', 'contrasena': 'MiClave123'}
campos_encriptar = 'contrasena'
exito, mensaje = api.crear(TABLA, datos, campos_encriptar)
# POST http://localhost:5035/api/usuario?camposEncriptar=contrasena
# La API encripta 'contrasena' con BCrypt antes de guardar en la BD

# Crear usuario SIN encriptar
datos = {'email': 'test@sistema.com', 'contrasena': 'texto-plano'}
exito, mensaje = api.crear(TABLA, datos)
# POST http://localhost:5035/api/usuario (sin ?camposEncriptar)
```

### 3.5 Rol (clave: id [entero], campos: id, nombre)

```python
# routes/rol.py
TABLA = 'rol'
CLAVE = 'id'  # Nota: clave primaria es un entero, no texto

# Crear rol
datos = {'id': 1, 'nombre': 'Administrador'}
exito, mensaje = api.crear(TABLA, datos)

# Actualizar rol
datos = {'nombre': 'SuperAdmin'}
exito, mensaje = api.actualizar(TABLA, CLAVE, 1, datos)
# PUT http://localhost:5035/api/rol/id/1
```

### 3.6 Ruta (clave: ruta, campos: ruta, descripcion)

```python
# routes/ruta.py
TABLA = 'ruta'
CLAVE = 'ruta'  # La clave primaria se llama igual que la tabla

# Crear ruta
datos = {'ruta': '/api/productos', 'descripcion': 'Endpoint de productos'}
exito, mensaje = api.crear(TABLA, datos)

# Eliminar ruta
exito, mensaje = api.eliminar(TABLA, CLAVE, '/api/productos')
# DELETE http://localhost:5035/api/ruta/ruta/%2Fapi%2Fproductos
```

---

## 4. Ejemplos desde Swagger y Postman

### 4.1 Swagger (accesible en http://localhost:5035/swagger)

La API incluye documentacion interactiva en Swagger. Tambien hay ReDoc en `http://localhost:5035/redoc`.

Para probar en Swagger:
1. Abrir `http://localhost:5035/swagger` en el navegador
2. Buscar el endpoint deseado (ej: GET /api/{tabla})
3. Click en "Try it out"
4. Llenar los parametros y ejecutar

### 4.2 Postman - Ejemplos para cada operacion

#### LISTAR todos los productos

```
GET http://localhost:5035/api/producto
```

Respuesta esperada:
```json
{
    "datos": [
        {"codigo": "PR001", "nombre": "Laptop", "stock": 10, "valorunitario": 2500.00},
        {"codigo": "PR002", "nombre": "Mouse", "stock": 50, "valorunitario": 35.00}
    ],
    "mensaje": "Registros obtenidos exitosamente."
}
```

#### LISTAR empresas con limite

```
GET http://localhost:5035/api/empresa?limite=3
```

#### FILTRAR persona por clave

```
GET http://localhost:5035/api/persona/codigo/PER001
```

Respuesta esperada:
```json
{
    "datos": [
        {"codigo": "PER001", "nombre": "Carlos Castro", "email": "carlos@email.com", "telefono": "3001234567"}
    ],
    "mensaje": "Registros obtenidos exitosamente."
}
```

#### CREAR un cliente

```
POST http://localhost:5035/api/cliente
Content-Type: application/json

{
    "codigo": "CL001",
    "nombre": "Juan Perez",
    "email": "juan@email.com",
    "telefono": "3101112233"
}
```

Respuesta esperada:
```json
{
    "datos": null,
    "mensaje": "Registro creado exitosamente."
}
```

#### CREAR un vendedor

```
POST http://localhost:5035/api/vendedor
Content-Type: application/json

{
    "codigo": "VEN001",
    "nombre": "Maria Lopez",
    "zona": "Norte"
}
```

#### ACTUALIZAR una empresa

```
PUT http://localhost:5035/api/empresa/codigo/E001
Content-Type: application/json

{
    "nombre": "Empresa Actualizada SAS"
}
```

Respuesta esperada:
```json
{
    "datos": null,
    "mensaje": "Registro actualizado exitosamente."
}
```

#### ACTUALIZAR un producto

```
PUT http://localhost:5035/api/producto/codigo/PR001
Content-Type: application/json

{
    "nombre": "Laptop Pro",
    "stock": 25,
    "valorunitario": 3200.50
}
```

#### ELIMINAR una persona

```
DELETE http://localhost:5035/api/persona/codigo/PER001
```

Respuesta esperada:
```json
{
    "datos": null,
    "mensaje": "Registro eliminado exitosamente."
}
```

#### CREAR usuario con contrasena encriptada (BCrypt)

```
POST http://localhost:5035/api/usuario?camposEncriptar=contrasena
Content-Type: application/json

{
    "email": "nuevo@sistema.com",
    "contrasena": "MiClaveSegura123"
}
```

La API encripta el campo `contrasena` con BCrypt antes de guardarlo.
En la BD se almacena algo como: `$2a$11$xK8G...hash...`

#### VERIFICAR contrasena BCrypt

```
POST http://localhost:5035/api/usuario/verificar-contrasena
Content-Type: application/json

{
    "email": "nuevo@sistema.com",
    "contrasena": "MiClaveSegura123"
}
```

#### INFORMACION de la API

```
GET http://localhost:5035/api/info
```

---

## 5. Ejemplos con curl

### Listar todos los productos

```bash
curl -X GET "http://localhost:5035/api/producto"
```

### Listar empresas con limite

```bash
curl -X GET "http://localhost:5035/api/empresa?limite=5"
```

### Filtrar persona por clave primaria

```bash
curl -X GET "http://localhost:5035/api/persona/codigo/PER001"
```

### Crear un producto

```bash
curl -X POST "http://localhost:5035/api/producto" \
  -H "Content-Type: application/json" \
  -d '{"codigo": "PR003", "nombre": "Teclado Mecanico", "stock": 30, "valorunitario": 120.50}'
```

### Crear un cliente

```bash
curl -X POST "http://localhost:5035/api/cliente" \
  -H "Content-Type: application/json" \
  -d '{"codigo": "CL002", "nombre": "Ana Garcia", "email": "ana@email.com", "telefono": "3205556677"}'
```

### Crear un vendedor

```bash
curl -X POST "http://localhost:5035/api/vendedor" \
  -H "Content-Type: application/json" \
  -d '{"codigo": "VEN002", "nombre": "Pedro Ramirez", "zona": "Sur"}'
```

### Crear usuario con contrasena encriptada

```bash
curl -X POST "http://localhost:5035/api/usuario?camposEncriptar=contrasena" \
  -H "Content-Type: application/json" \
  -d '{"email": "admin@test.com", "contrasena": "Password123"}'
```

### Actualizar una empresa

```bash
curl -X PUT "http://localhost:5035/api/empresa/codigo/E001" \
  -H "Content-Type: application/json" \
  -d '{"nombre": "Empresa Renovada SAS"}'
```

### Actualizar un producto

```bash
curl -X PUT "http://localhost:5035/api/producto/codigo/PR001" \
  -H "Content-Type: application/json" \
  -d '{"nombre": "Laptop Gaming", "stock": 15, "valorunitario": 4500.00}'
```

### Eliminar una persona

```bash
curl -X DELETE "http://localhost:5035/api/persona/codigo/PER001"
```

### Eliminar un rol

```bash
curl -X DELETE "http://localhost:5035/api/rol/id/1"
```

### Verificar contrasena BCrypt

```bash
curl -X POST "http://localhost:5035/api/usuario/verificar-contrasena" \
  -H "Content-Type: application/json" \
  -d '{"email": "admin@test.com", "contrasena": "Password123"}'
```

### Obtener informacion de la API

```bash
curl -X GET "http://localhost:5035/api/info"
```

---

## 6. Formato de Respuesta de la API

Todas las respuestas de la API siguen una estructura JSON uniforme:

### Respuesta exitosa con datos (GET listar)

```json
{
    "datos": [
        {"codigo": "PR001", "nombre": "Laptop", "stock": 10, "valorunitario": 2500.00},
        {"codigo": "PR002", "nombre": "Mouse", "stock": 50, "valorunitario": 35.00}
    ],
    "mensaje": "Registros obtenidos exitosamente."
}
```

- `datos`: Lista de diccionarios. Cada diccionario es un registro de la tabla.
- `mensaje`: Texto descriptivo de la operacion.

### Respuesta exitosa sin datos (POST, PUT, DELETE)

```json
{
    "datos": null,
    "mensaje": "Registro creado exitosamente."
}
```

### Respuesta de error (codigo HTTP 4xx o 5xx)

```json
{
    "datos": null,
    "mensaje": "Error: La tabla 'tablaquenoexiste' no fue encontrada."
}
```

### Como interpreta Flask la respuesta

En `ApiService`:
- **listar()** extrae solo la lista: `respuesta.json().get("datos", [])` - retorna `[]` si hay error
- **crear/actualizar/eliminar()** retornan una tupla: `(respuesta.ok, mensaje)`
  - `respuesta.ok` es `True` si el codigo HTTP es 200-299
  - `mensaje` es el texto del campo `"mensaje"` de la respuesta

En los Blueprints (routes):

```python
exito, mensaje = api.crear(TABLA, datos)
flash(mensaje, 'success' if exito else 'danger')
# 'success' = alerta verde en Bootstrap
# 'danger'  = alerta roja en Bootstrap
```

---

## 7. Errores Comunes y Soluciones

### Error: "Error de conexion: Connection refused"

**Causa:** La API no esta corriendo o no esta en el puerto correcto.

**Solucion:**
1. Verificar que la API este corriendo en `http://localhost:5035`
2. Revisar `config.py` del proyecto Flask: `API_BASE_URL = "http://localhost:5035"`
3. Ejecutar la API con `dotnet run` en el proyecto ApiGenericaCsharp

### Error: "La tabla 'xxx' no fue encontrada"

**Causa:** El nombre de la tabla no existe en la base de datos o esta mal escrito.

**Solucion:**
- Usar los nombres exactos en minuscula: `empresa`, `persona`, `producto`, `rol`, `ruta`, `usuario`, `cliente`, `vendedor`, `factura`, `productosporfactura`, `rutarol`
- Los nombres son sensibles a como estan registrados en la base de datos

### Error: "Violation of PRIMARY KEY constraint"

**Causa:** Se intento crear un registro con una clave primaria que ya existe.

**Solucion:**
- Verificar que el valor del campo clave (ej: `codigo`, `id`, `email`) no este duplicado
- Usar un valor unico para la clave primaria

### Error: "The DELETE statement conflicted with the REFERENCE constraint"

**Causa:** Se intento eliminar un registro que tiene registros dependientes en otra tabla (integridad referencial).

**Solucion:**
- Eliminar primero los registros dependientes (ej: eliminar `productosporfactura` antes de `factura`)
- O actualizar las referencias para que apunten a otro registro

### Error: "Cannot insert the value NULL into column 'xxx'"

**Causa:** Se envio un JSON incompleto que no incluye un campo obligatorio.

**Solucion:**
- Asegurarse de incluir todos los campos requeridos en el cuerpo JSON
- Revisar que los nombres de los campos coincidan exactamente con los de la tabla

### El formulario Flask no muestra datos

**Causa posible:** La API retorna un error y `api.listar()` devuelve una lista vacia.

**Solucion:**
1. Abrir la consola del servidor Flask y buscar mensajes de error
2. Probar el endpoint directamente en el navegador: `http://localhost:5035/api/producto`
3. Verificar que la API este respondiendo correctamente en Swagger

### La contrasena no se encripta

**Causa:** No se esta pasando el parametro `camposEncriptar`.

**Solucion:**
- En Flask: marcar el checkbox "encriptar" en el formulario de usuario
- En Postman/curl: agregar `?camposEncriptar=contrasena` a la URL del POST
- Verificar que el nombre del campo coincida exactamente (ej: `contrasena`, no `password`)

### Error CORS al consumir desde otro origen

**Causa:** La API no tiene habilitado CORS para el origen del frontend.

**Solucion:**
- Verificar que la API tenga configurado CORS en `Program.cs`
- El frontend Flask corre en `http://localhost:5100`, la API en `http://localhost:5035`
- Nota: como Flask hace las peticiones HTTP desde el servidor (no desde el navegador), CORS normalmente no aplica. Solo aplica si se hacen peticiones AJAX directamente desde JavaScript en el navegador.

---

Autor: Carlos Arturo Castro Castro
