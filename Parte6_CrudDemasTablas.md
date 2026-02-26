# Tutorial: Frontend Flask CRUD
# Parte 6: CRUD de las 5 Tablas Restantes

En esta parte creamos los Blueprints y templates para Empresa, Persona, Rol, Ruta y Usuario. Todas siguen el mismo patron de Producto (Parte 5), adaptado a las columnas de cada tabla.

---

## 6.1 Que Cambia de una Tabla a Otra

El patron CRUD es identico para todas las tablas. Lo unico que cambia entre un Blueprint y otro son 4 cosas:

| Que cambia | Ejemplo Producto | Ejemplo Empresa |
|---|---|---|
| Nombre del Blueprint | `Blueprint('producto', ...)` | `Blueprint('empresa', ...)` |
| Nombre de la tabla en la API | `TABLA = 'producto'` | `TABLA = 'empresa'` |
| Campos del formulario | codigo, nombre, stock, valorunitario | codigo, nombre |
| Nombre de la clave primaria | `CLAVE = 'codigo'` | `CLAVE = 'codigo'` |

La estructura de las rutas (index, crear, actualizar, eliminar) y del template (boton nuevo, formulario, tabla, acciones) son las mismas.

---

## 6.2 Empresa

**Columnas:** codigo (varchar 10), nombre (varchar 200)
**Clave primaria:** codigo

Esta es la tabla mas simple: solo 2 campos.

**Blueprint:** `routes/empresa.py`
**Template:** `templates/pages/empresa.html`

**Diferencias con Producto:**
- Solo 2 campos en el formulario y en la tabla: `codigo` y `nombre`
- No hay campos numericos (no se necesita `type=int` ni `type=float`)
- El diccionario de datos para crear solo tiene 2 entradas

```python
# En la ruta crear:
datos = {
    'codigo': request.form.get('codigo', ''),
    'nombre': request.form.get('nombre', '')
}
```

---

## 6.3 Persona

**Columnas:** codigo (varchar 20), nombre (varchar 100), email (varchar 100), telefono (varchar 20)
**Clave primaria:** codigo

**Blueprint:** `routes/persona.py`
**Template:** `templates/pages/persona.html`

**Diferencias con Producto:**
- 4 campos de texto: codigo, nombre, email, telefono
- Todos son `string`, no hay campos numericos
- El input de email usa `type="email"` para validacion basica del navegador
- La tabla tiene 5 columnas (4 campos + acciones)

```html
<!-- En el template, el campo email tiene type="email" -->
<input class="form-control" type="email" name="email"
       value="{{ registro.email if registro else '' }}" />
```

---

## 6.4 Rol

**Columnas:** id (int), nombre (varchar 100)
**Clave primaria:** id

**Blueprint:** `routes/rol.py`
**Template:** `templates/pages/rol.html`

**Diferencias con Producto:**
- La clave primaria es `id` (entero), no `codigo` (texto)
- `CLAVE = 'id'` en el Blueprint
- El campo `id` usa `type="number"` en el formulario
- En las rutas de actualizar y eliminar: `api.actualizar(TABLA, 'id', valor, datos)`
- Los links de editar usan `clave=reg.id` en vez de `clave=reg.codigo`

```python
# Blueprint: la clave primaria es 'id'
CLAVE = 'id'

# Crear: id es entero
datos = {
    'id':     request.form.get('id', 0, type=int),
    'nombre': request.form.get('nombre', '')
}
```

---

## 6.5 Ruta

**Columnas:** ruta (varchar 100), descripcion (varchar 255)
**Clave primaria:** ruta

**Blueprint:** `routes/ruta.py`
**Template:** `templates/pages/ruta.html`

**Diferencias con Producto:**
- La clave primaria se llama `ruta` (mismo nombre que la tabla)
- Solo 2 campos: ruta y descripcion
- El Blueprint se nombra `ruta_page` para evitar confusion: `Blueprint('ruta_page', __name__)`
- En los templates se usa `url_for('ruta_page.index')` en vez de `url_for('ruta.index')`

```python
# Blueprint con nombre diferente para claridad
bp = Blueprint('ruta_page', __name__)

TABLA = 'ruta'
CLAVE = 'ruta'    # La clave se llama igual que la tabla
```

---

## 6.6 Usuario

**Columnas:** email (varchar 100), contrasena (varchar 100)
**Clave primaria:** email

**Blueprint:** `routes/usuario.py`
**Template:** `templates/pages/usuario.html`

**Diferencias con Producto:**
- La clave primaria es `email`
- El campo contrasena usa `type="password"` para ocultar los caracteres
- Incluye un **checkbox para encriptar** la contrasena antes de enviarla a la API
- La ruta de crear y actualizar verifica si el checkbox esta marcado y pasa el parametro `campos_encriptar`

```python
# Verificar si el checkbox de encriptar esta marcado
encriptar = request.form.get('encriptar')
campos_encriptar = 'contrasena' if encriptar else None

exito, mensaje = api.crear(TABLA, datos, campos_encriptar)
```

```html
<!-- Checkbox en el template -->
<div class="form-check mt-4">
    <input class="form-check-input" type="checkbox"
           name="encriptar" value="si" id="chkEncriptar" />
    <label class="form-check-label" for="chkEncriptar">
        Encriptar contrasena
    </label>
</div>
```

**Como funciona la encriptacion:**
1. Si el checkbox NO esta marcado → `request.form.get('encriptar')` retorna `None`
2. Si el checkbox esta marcado → `request.form.get('encriptar')` retorna `"si"`
3. El Blueprint pasa `campos_encriptar='contrasena'` al ApiService
4. El ApiService agrega `?camposEncriptar=contrasena` a la URL de la API
5. La API encripta el campo antes de guardarlo en la BD (hash bcrypt)

---

## 6.7 Registrar Todos los Blueprints

En `app.py`, registramos todos los Blueprints:

```python
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
```

---

## 6.8 Resumen de Diferencias por Tabla

| Tabla | Clave | Campos | Especial |
|---|---|---|---|
| Empresa | `codigo` (str) | codigo, nombre | Tabla mas simple |
| Persona | `codigo` (str) | codigo, nombre, email, telefono | Email con `type="email"` |
| Producto | `codigo` (str) | codigo, nombre, stock, valorunitario | Campos numericos (int, float) |
| Rol | `id` (int) | id, nombre | Clave numerica |
| Ruta | `ruta` (str) | ruta, descripcion | Clave = nombre tabla |
| Usuario | `email` (str) | email, contrasena | Checkbox encriptar |

---

## 6.9 Commit

```bash
git add .
git commit -m "Agregar CRUD de Empresa, Persona, Rol, Ruta y Usuario"
```

---

## Siguiente Parte

En la **Parte 7** haremos la verificacion final: correr la API y el frontend juntos, probar las 6 tablas CRUD y confirmar que todo funciona.
