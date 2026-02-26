# Tutorial: Frontend Flask CRUD
# Parte 5: CRUD Completo de Producto

En esta parte creamos el Blueprint y el template de Producto con las 4 operaciones CRUD completas. Esta es la pagina mas importante del tutorial porque sirve como modelo para las demas tablas.

**Tabla producto:**
| Columna | Tipo | Descripcion |
|---|---|---|
| codigo | varchar(30) | Clave primaria |
| nombre | varchar(100) | Nombre del producto |
| stock | int | Cantidad disponible |
| valorunitario | numeric | Precio unitario |

---

## 5.1 Estructura General de una Pagina CRUD

Cada pagina CRUD tiene 4 secciones principales:

```
┌──────────────────────────────────────────────────┐
│  1. BOTON "Nuevo Producto" (se oculta al abrir   │
│     el formulario)                                │
├──────────────────────────────────────────────────┤
│  2. LIMITE (control para limitar registros)       │
│     Limite: [___] [Cargar]                        │
├──────────────────────────────────────────────────┤
│  3. FORMULARIO (crear o editar, visible solo      │
│     cuando corresponde)                           │
│     Codigo: [________]                            │
│     Nombre: [________]                            │
│     Stock:  [________]                            │
│     Valor:  [________]                            │
│     [Guardar]  [Cancelar]                         │
├──────────────────────────────────────────────────┤
│  4. TABLA (lista de registros)                    │
│     ┌────────┬─────────┬───────┬────────┬──────┐ │
│     │ Codigo │ Nombre  │ Stock │ Valor  │ Acc. │ │
│     ├────────┼─────────┼───────┼────────┼──────┤ │
│     │ PR001  │ Laptop  │ 10    │ 2.5M   │ E  X │ │
│     │ PR002  │ Mouse   │ 50    │ 35K    │ E  X │ │
│     └────────┴─────────┴───────┴────────┴──────┘ │
│     E = Editar    X = Eliminar                    │
└──────────────────────────────────────────────────┘
```

---

## 5.2 El Blueprint (routes/producto.py)

Este archivo contiene las 4 rutas del CRUD:

```python
"""
producto.py - Blueprint con las rutas CRUD para la tabla Producto.
"""

from flask import Blueprint, render_template, request, redirect, url_for, flash
from services.api_service import ApiService

bp = Blueprint('producto', __name__)
api = ApiService()

TABLA = 'producto'
CLAVE = 'codigo'


# ──────────────────────────────────────────────
# LISTAR REGISTROS (GET)
# ──────────────────────────────────────────────

@bp.route('/producto')
def index():
    limite = request.args.get('limite', type=int)
    accion = request.args.get('accion', '')
    valor_clave = request.args.get('clave', '')

    registros = api.listar(TABLA, limite)

    mostrar_formulario = accion in ('nuevo', 'editar')
    editando = accion == 'editar'

    registro = None
    if editando and valor_clave:
        registro = next(
            (r for r in registros if str(r.get(CLAVE)) == valor_clave),
            None
        )

    return render_template('pages/producto.html',
        registros=registros,
        mostrar_formulario=mostrar_formulario,
        editando=editando,
        registro=registro,
        limite=limite
    )


# ──────────────────────────────────────────────
# CREAR REGISTRO (POST)
# ──────────────────────────────────────────────

@bp.route('/producto/crear', methods=['POST'])
def crear():
    datos = {
        'codigo':        request.form.get('codigo', ''),
        'nombre':        request.form.get('nombre', ''),
        'stock':         request.form.get('stock', 0, type=int),
        'valorunitario': request.form.get('valorunitario', 0, type=float)
    }

    exito, mensaje = api.crear(TABLA, datos)
    flash(mensaje, 'success' if exito else 'danger')
    return redirect(url_for('producto.index'))


# ──────────────────────────────────────────────
# ACTUALIZAR REGISTRO (POST)
# ──────────────────────────────────────────────

@bp.route('/producto/actualizar', methods=['POST'])
def actualizar():
    valor = request.form.get('codigo', '')
    datos = {
        'nombre':        request.form.get('nombre', ''),
        'stock':         request.form.get('stock', 0, type=int),
        'valorunitario': request.form.get('valorunitario', 0, type=float)
    }

    exito, mensaje = api.actualizar(TABLA, CLAVE, valor, datos)
    flash(mensaje, 'success' if exito else 'danger')
    return redirect(url_for('producto.index'))


# ──────────────────────────────────────────────
# ELIMINAR REGISTRO (POST)
# ──────────────────────────────────────────────

@bp.route('/producto/eliminar', methods=['POST'])
def eliminar():
    valor = request.form.get('codigo', '')

    exito, mensaje = api.eliminar(TABLA, CLAVE, valor)
    flash(mensaje, 'success' if exito else 'danger')
    return redirect(url_for('producto.index'))
```

---

## 5.3 Explicacion de las Rutas

### Ruta GET /producto (listar + formulario)

Esta ruta hace todo: lista los registros y decide si mostrar el formulario.

**Parametros de la URL:**

| Parametro | Ejemplo | Efecto |
|---|---|---|
| (ninguno) | `/producto` | Solo muestra la tabla |
| `accion=nuevo` | `/producto?accion=nuevo` | Muestra formulario vacio |
| `accion=editar&clave=PR001` | `/producto?accion=editar&clave=PR001` | Muestra formulario con datos |
| `limite=5` | `/producto?limite=5` | Limita a 5 registros |

**Buscar registro para editar:**
```python
registro = next(
    (r for r in registros if str(r.get(CLAVE)) == valor_clave),
    None
)
```

Esto es una **expresion generadora** con `next()`. Busca en la lista el primer registro cuyo `codigo` coincida con `valor_clave`. Si no lo encuentra, retorna `None`.

### Rutas POST (crear, actualizar, eliminar)

Las 3 rutas POST siguen el mismo patron:

```
1. Leer datos del formulario con request.form.get()
2. Llamar al ApiService (crear, actualizar o eliminar)
3. Guardar mensaje flash con flash()
4. Redirigir al listado con redirect(url_for('producto.index'))
```

**request.form.get()** lee los valores que el usuario envio en el formulario HTML. El atributo `name` del `<input>` es la clave:

```html
<input name="stock" type="number" />     →     request.form.get('stock', 0, type=int)
```

El parametro `type=int` convierte automaticamente el texto a entero (o usa el valor por defecto `0` si falla).

---

## 5.4 El Template (templates/pages/producto.html)

```html
{% extends 'layout/base.html' %}

{% block title %}Productos{% endblock %}

{% block content %}
<div class="container mt-4">
    <h3>Productos</h3>

    {# ───────── BOTON NUEVO PRODUCTO ───────── #}
    {% if not mostrar_formulario %}
        <a href="{{ url_for('producto.index', accion='nuevo') }}"
           class="btn btn-primary mb-3">
            Nuevo Producto
        </a>
    {% endif %}

    {# ───────── LIMITE DE REGISTROS ───────── #}
    <form method="GET" action="{{ url_for('producto.index') }}"
          class="d-flex align-items-center mb-3">
        <label class="form-label me-2 mb-0">Limite:</label>
        <input class="form-control me-2" type="number" name="limite"
               style="width:100px" value="{{ limite or '' }}" />
        <button class="btn btn-outline-secondary" type="submit">Cargar</button>
    </form>

    {# ───────── FORMULARIO (CREAR / EDITAR) ───────── #}
    {% if mostrar_formulario %}
        <div class="card mb-3">
            <div class="card-header">
                {{ "Editar Producto" if editando else "Nuevo Producto" }}
            </div>
            <div class="card-body">
                <form method="POST"
                      action="{{ url_for('producto.actualizar') if editando
                                 else url_for('producto.crear') }}">
                    <div class="row">
                        <div class="col-md-6 mb-3">
                            <label class="form-label">Codigo</label>
                            <input class="form-control" name="codigo"
                                   value="{{ registro.codigo if registro else '' }}"
                                   {{ 'readonly' if editando }} />
                        </div>
                        <div class="col-md-6 mb-3">
                            <label class="form-label">Nombre</label>
                            <input class="form-control" name="nombre"
                                   value="{{ registro.nombre if registro else '' }}" />
                        </div>
                        <div class="col-md-6 mb-3">
                            <label class="form-label">Stock</label>
                            <input class="form-control" type="number" name="stock"
                                   value="{{ registro.stock if registro else 0 }}" />
                        </div>
                        <div class="col-md-6 mb-3">
                            <label class="form-label">Valor Unitario</label>
                            <input class="form-control" type="number" step="0.01"
                                   name="valorunitario"
                                   value="{{ registro.valorunitario if registro else 0 }}" />
                        </div>
                    </div>
                    <button class="btn btn-success me-2" type="submit">Guardar</button>
                    <a href="{{ url_for('producto.index') }}"
                       class="btn btn-secondary">Cancelar</a>
                </form>
            </div>
        </div>
    {% endif %}

    {# ───────── TABLA DE REGISTROS ───────── #}
    {% if registros %}
        <table class="table table-striped table-hover">
            <thead class="table-dark">
                <tr>
                    <th>Codigo</th>
                    <th>Nombre</th>
                    <th>Stock</th>
                    <th>Valor Unitario</th>
                    <th>Acciones</th>
                </tr>
            </thead>
            <tbody>
                {% for reg in registros %}
                <tr>
                    <td>{{ reg.codigo }}</td>
                    <td>{{ reg.nombre }}</td>
                    <td>{{ reg.stock }}</td>
                    <td>{{ reg.valorunitario }}</td>
                    <td>
                        <a href="{{ url_for('producto.index',
                                    accion='editar', clave=reg.codigo) }}"
                           class="btn btn-warning btn-sm me-1">Editar</a>

                        <form method="POST"
                              action="{{ url_for('producto.eliminar') }}"
                              style="display:inline"
                              onsubmit="return confirm('Eliminar este registro?')">
                            <input type="hidden" name="codigo"
                                   value="{{ reg.codigo }}" />
                            <button class="btn btn-danger btn-sm"
                                    type="submit">Eliminar</button>
                        </form>
                    </td>
                </tr>
                {% endfor %}
            </tbody>
        </table>
    {% else %}
        <div class="alert alert-warning">
            No se encontraron registros en la tabla producto.
        </div>
    {% endif %}
</div>
{% endblock %}
```

---

## 5.5 Explicacion Seccion por Seccion

### Boton "Nuevo Producto"

```html
<a href="{{ url_for('producto.index', accion='nuevo') }}" class="btn btn-primary mb-3">
```

Es un link estilizado como boton que navega a `/producto?accion=nuevo`. La ruta Flask detecta `accion='nuevo'` y pasa `mostrar_formulario=True` al template.

### Control de limite

```html
<form method="GET" action="{{ url_for('producto.index') }}">
    <input type="number" name="limite" />
    <button type="submit">Cargar</button>
</form>
```

Es un formulario GET. Al enviar, la URL queda como `/producto?limite=5` y Flask pasa ese valor a `api.listar("producto", 5)`.

### Formulario con accion dinamica

```html
<form method="POST"
      action="{{ url_for('producto.actualizar') if editando
                 else url_for('producto.crear') }}">
```

La accion del formulario cambia segun el modo:
- Si estamos **editando** → POST a `/producto/actualizar`
- Si estamos **creando** → POST a `/producto/crear`

### Campo readonly al editar

```html
<input name="codigo" value="{{ registro.codigo if registro else '' }}"
       {{ 'readonly' if editando }} />
```

Cuando estamos editando, el campo `codigo` se marca como `readonly` para que no se pueda cambiar la clave primaria.

### Boton Editar (link GET)

```html
<a href="{{ url_for('producto.index', accion='editar', clave=reg.codigo) }}">
```

Genera una URL como `/producto?accion=editar&clave=PR001`. Flask busca el registro, lo pasa al template, y el formulario se muestra pre-llenado.

### Boton Eliminar (formulario POST oculto)

```html
<form method="POST" action="{{ url_for('producto.eliminar') }}"
      style="display:inline"
      onsubmit="return confirm('Eliminar este registro?')">
    <input type="hidden" name="codigo" value="{{ reg.codigo }}" />
    <button class="btn btn-danger btn-sm" type="submit">Eliminar</button>
</form>
```

Cada boton "Eliminar" es un mini-formulario POST con un campo oculto que contiene el codigo del registro. El `confirm()` pide confirmacion al usuario antes de enviar.

---

## 5.6 Registrar el Blueprint

En `app.py`, agregamos:

```python
from routes.producto import bp as producto_bp
app.register_blueprint(producto_bp)
```

---

## 5.7 Flujo de Cada Operacion

### Listar (al abrir la pagina)
```
GET /producto → api.listar("producto") → render_template con registros
```

### Crear
```
Click "Nuevo Producto" → GET /producto?accion=nuevo → formulario vacio
Llenar campos → Click "Guardar" → POST /producto/crear
api.crear("producto", datos) → flash(mensaje) → redirect /producto
```

### Editar
```
Click "Editar" → GET /producto?accion=editar&clave=PR001 → formulario con datos
Modificar campos → Click "Guardar" → POST /producto/actualizar
api.actualizar("producto", "codigo", "PR001", datos) → flash(mensaje) → redirect /producto
```

### Eliminar
```
Click "Eliminar" → confirm() → POST /producto/eliminar
api.eliminar("producto", "codigo", "PR001") → flash(mensaje) → redirect /producto
```

---

## 5.8 Commit

```bash
git add .
git commit -m "Agregar CRUD completo de Producto con Blueprint, template y formularios"
```

---

## 5.9 Resumen de Conceptos de esta Parte

| Concepto | Que hace | Ejemplo |
|---|---|---|
| `Blueprint` | Agrupa rutas de una tabla en un modulo | `bp = Blueprint('producto', __name__)` |
| `@bp.route` | Define una URL y su funcion | `@bp.route('/producto')` |
| `request.args.get` | Lee parametros GET de la URL | `accion = request.args.get('accion')` |
| `request.form.get` | Lee campos del formulario POST | `codigo = request.form.get('codigo')` |
| `render_template` | Genera HTML a partir de un template | `render_template('pages/producto.html', ...)` |
| `flash` | Guarda un mensaje para mostrar despues del redirect | `flash(mensaje, 'success')` |
| `redirect` | Redirige al navegador a otra URL | `redirect(url_for('producto.index'))` |
| `url_for` | Genera URL a partir del nombre del Blueprint y funcion | `url_for('producto.crear')` |
| `{% extends %}` | Herencia de template (reutilizar layout) | `{% extends 'layout/base.html' %}` |
| `{{ variable }}` | Imprime una variable en el HTML | `{{ reg.codigo }}` |
| `{% if %}` | Condicional en el template | `{% if mostrar_formulario %}` |
| `{% for %}` | Bucle en el template | `{% for reg in registros %}` |

---

## Siguiente Parte

En la **Parte 6** crearemos los CRUD para las 5 tablas restantes (Empresa, Persona, Rol, Ruta, Usuario) siguiendo el mismo patron de Producto.
