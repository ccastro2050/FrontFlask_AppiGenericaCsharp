# Tutorial: Vistas Maestro-Detalle en Flask + Jinja2

Guia completa para construir paginas con vistas integradas de maestro-detalle en Flask, usando el proyecto `FrontFlask_AppiGenericaCsharp` como referencia.

---

## Tabla de Contenido

1. [Fundamentos](#1-fundamentos)
2. [Prerequisitos y Estructura del Proyecto](#2-prerequisitos-y-estructura-del-proyecto)
3. [Anatomia de una Pagina CRUD Simple](#3-anatomia-de-una-pagina-crud-simple)
4. [Diseno de la Pagina Maestro-Detalle](#4-diseno-de-la-pagina-maestro-detalle)
5. [Paso a Paso: Construir factura.py y factura.html](#5-paso-a-paso-construir-facturapy-y-facturahtml)
6. [Patrones Clave Explicados](#6-patrones-clave-explicados)
7. [Otros Ejemplos de Maestro-Detalle](#7-otros-ejemplos-de-maestro-detalle)
8. [Errores Comunes y Soluciones](#8-errores-comunes-y-soluciones)
9. [Equivalencia Flask vs Blazor](#9-equivalencia-flask-vs-blazor)

---

## 1. Fundamentos

### Relacion Maestro-Detalle

Una relacion maestro-detalle conecta un registro principal (maestro) con multiples registros secundarios (detalle) que dependen de el. El registro maestro existe de forma independiente, pero los registros de detalle solo tienen sentido dentro del contexto del maestro.

**Ejemplo concreto:** Una **Factura** (maestro) contiene uno o mas **Productos por Factura** (detalle). La factura tiene datos generales (cliente, vendedor, fecha, total) y cada linea de producto tiene datos especificos (codigo producto, cantidad, valor unitario, subtotal).

### Ejemplos de Relaciones Maestro-Detalle

**Ejemplos genericos:**

| Maestro | Detalle | Descripcion |
|---------|---------|-------------|
| **Factura** | Productos por Factura | Cada factura tiene N productos con cantidad y subtotal |
| Pedido | Items del Pedido | Cada pedido tiene N items solicitados |
| Orden de Compra | Detalle de Compra | Cada orden tiene N materiales/servicios |
| Receta Medica | Medicamentos | Cada receta tiene N medicamentos con dosis |
| Matricula | Materias Inscritas | Cada matricula tiene N materias con horarios |

**Ejemplos reales del sistema (por modulo):**

| Modulo | Maestro | Detalle | Descripcion |
|--------|---------|---------|-------------|
| **Gestion Profesoral** | Docente | Estudios Realizados | Cada docente tiene N estudios con titulo, universidad, tipo y pais |
| **Innovacion Curricular** | Programa | Actividades Academicas | Cada programa tiene N actividades con creditos, horas e idioma |
| **Investigacion** | Grupo de Investigacion | Semilleros | Cada grupo tiene N semilleros con fecha de fundacion |
| **Mapa de Conocimiento** | Proyecto | Productos Academicos | Cada proyecto genera N productos con categoria y tipo |

### CRUD Simple vs Maestro-Detalle

| Aspecto | CRUD Simple | Maestro-Detalle |
|---------|-------------|-----------------|
| Vistas | Lista + Formulario (toggle) | Lista + Detalle + Formulario (3 vistas) |
| Datos | Una sola tabla | Tabla maestra + tabla detalle (anidada) |
| Formulario | Campos escalares | Campos escalares + filas dinamicas |
| Persistencia | CRUD directo (POST, PUT, DELETE) | Stored procedures (transaccional) |
| JSON | No se usa | JSON como puente para datos anidados |
| Rutas | 1 GET + 3 POST | 4 GET + 3 POST (7 rutas) |
| Servicio | `ApiService` (CRUD) | `ApiService.ejecutar_sp()` (SPs) |

---

## 2. Prerequisitos y Estructura del Proyecto

### Que se necesita antes de empezar

1. **API REST corriendo** — `ApiGenericaCsharp` en el puerto configurado en `config.py`
2. **Base de datos con SPs** — 5 stored procedures para maestro-detalle (insertar, consultar, listar, actualizar, borrar)
3. **Triggers** — Para calcular subtotales, descontar stock y actualizar totales automaticamente
4. **Flask instalado** — `pip install flask requests`

### Estructura de archivos

```
FrontFlask_AppiGenericaCsharp/
├── app.py                          # Punto de entrada, registra Blueprints
├── config.py                       # URL de la API y clave secreta
├── services/
│   └── api_service.py              # Servicio generico CRUD + ejecutar_sp()
├── routes/
│   ├── home.py                     # Blueprint pagina inicio
│   ├── producto.py                 # Blueprint CRUD simple (referencia)
│   ├── empresa.py                  # Blueprint CRUD simple
│   ├── persona.py                  # Blueprint CRUD simple
│   ├── rol.py                      # Blueprint CRUD simple
│   ├── ruta.py                     # Blueprint CRUD simple
│   ├── usuario.py                  # Blueprint CRUD simple
│   ├── cliente.py                  # Blueprint CRUD con FKs
│   ├── vendedor.py                 # Blueprint CRUD con FKs
│   └── factura.py                  # ★ Blueprint maestro-detalle (SPs)
├── templates/
│   ├── layout/
│   │   └── base.html               # Template base (sidebar + alertas)
│   ├── components/
│   │   └── nav_menu.html           # Menu de navegacion lateral
│   └── pages/
│       ├── producto.html           # Template CRUD simple (referencia)
│       ├── factura.html            # ★ Template maestro-detalle
│       └── ...                     # Otros templates
└── static/
    └── css/
        └── app.css                 # Estilos del sidebar y responsive
```

### Servicio: ApiService

El archivo `services/api_service.py` encapsula las operaciones HTTP contra la API REST. Para maestro-detalle se usa el metodo `ejecutar_sp()`:

```python
class ApiService:
    def __init__(self):
        self.base_url = API_BASE_URL

    # CRUD simple
    def listar(self, tabla, limite=None):    # GET /api/{tabla}
    def crear(self, tabla, datos, ...):      # POST /api/{tabla}
    def actualizar(self, tabla, ...):        # PUT /api/{tabla}/{clave}/{valor}
    def eliminar(self, tabla, ...):          # DELETE /api/{tabla}/{clave}/{valor}

    # Stored procedures (maestro-detalle)
    def ejecutar_sp(self, nombre_sp, parametros=None):
        """POST /api/procedimientos/ejecutarsp"""
        # Retorna tupla (exito: bool, datos_o_mensaje)
```

El metodo `ejecutar_sp()` envia un POST con el nombre del SP y sus parametros. Retorna una tupla `(True, datos)` o `(False, mensaje_error)`.

**Detalle clave:** El resultado del SP viene en `resultados[0]` como un JSON string. El metodo detecta automaticamente si la clave es `p_resultado` (PostgreSQL) o `@p_resultado` (SQL Server):

```python
resultados = contenido.get("resultados", [])
if resultados:
    p_resultado = resultados[0].get("p_resultado") or resultados[0].get("@p_resultado")
    if p_resultado is not None:
        if isinstance(p_resultado, str):
            return (True, json.loads(p_resultado))
        return (True, p_resultado)
```

### Registro en app.py

Cada Blueprint se importa y registra en `app.py`:

```python
from routes.factura import bp as factura_bp
app.register_blueprint(factura_bp)
```

---

## 3. Anatomia de una Pagina CRUD Simple

Antes de construir maestro-detalle, es util entender el patron CRUD simple. `producto.py` + `producto.html` es el ejemplo de referencia.

### Blueprint CRUD Simple (routes/producto.py)

Un CRUD simple tiene **4 rutas**:

```python
bp = Blueprint('producto', __name__)
api = ApiService()
TABLA = 'producto'
CLAVE = 'codigo'

@bp.route('/producto')                          # GET: listar + formulario opcional
def index(): ...

@bp.route('/producto/crear', methods=['POST'])   # POST: crear registro
def crear(): ...

@bp.route('/producto/actualizar', methods=['POST'])  # POST: actualizar registro
def actualizar(): ...

@bp.route('/producto/eliminar', methods=['POST'])    # POST: eliminar registro
def eliminar(): ...
```

### Variables de estado via query string

Flask no tiene estado como Blazor. En su lugar, se usan **parametros en la URL** para controlar la vista:

```python
# En la ruta index():
accion = request.args.get('accion', '')       # 'nuevo', 'editar' o ''
valor_clave = request.args.get('clave', '')   # PK del registro a editar

mostrar_formulario = accion in ('nuevo', 'editar')
editando = accion == 'editar'
```

Los links del template generan la URL con los parametros:

```html
<!-- Boton "Nuevo" → GET /producto?accion=nuevo -->
<a href="{{ url_for('producto.index', accion='nuevo') }}">Nuevo Producto</a>

<!-- Boton "Editar" → GET /producto?accion=editar&clave=PR001 -->
<a href="{{ url_for('producto.index', accion='editar', clave=reg.codigo) }}">Editar</a>
```

### Template CRUD Simple (templates/pages/producto.html)

El template tiene 2 secciones controladas por variables:

```html
{% extends 'layout/base.html' %}

{% block content %}
<div class="container mt-4">
    <h3>Productos</h3>

    {# Boton "Nuevo" solo visible cuando no hay formulario abierto #}
    {% if not mostrar_formulario %}
        <a href="...?accion=nuevo" class="btn btn-primary mb-3">Nuevo Producto</a>
    {% endif %}

    {# Formulario (crear o editar) — visible solo cuando accion = 'nuevo' o 'editar' #}
    {% if mostrar_formulario %}
        <form method="POST" action="{{ url_for('producto.actualizar') if editando else url_for('producto.crear') }}">
            <input name="codigo" value="{{ registro.codigo if registro else '' }}" />
            <input name="nombre" value="{{ registro.nombre if registro else '' }}" />
            ...
        </form>
    {% endif %}

    {# Tabla de registros — siempre visible #}
    {% if registros %}
        <table class="table">
            {% for reg in registros %}
            <tr>
                <td>{{ reg.codigo }}</td>
                <td>{{ reg.nombre }}</td>
                <td>
                    <a href="...?accion=editar&clave={{ reg.codigo }}">Editar</a>
                    <form method="POST" action="{{ url_for('producto.eliminar') }}"
                          onsubmit="return confirm('¿Eliminar?')">
                        <input type="hidden" name="codigo" value="{{ reg.codigo }}" />
                        <button type="submit">Eliminar</button>
                    </form>
                </td>
            </tr>
            {% endfor %}
        </table>
    {% endif %}
</div>
{% endblock %}
```

**Puntos clave:**
- `{% extends 'layout/base.html' %}` — hereda sidebar, Bootstrap y alertas flash
- `{% if mostrar_formulario %}` — toggle de formulario
- `{{ url_for('producto.crear') }}` — genera la URL del POST
- `request.form.get()` — lee los campos del formulario en el Blueprint
- `flash()` — muestra alertas despues de redirigir

---

## 4. Diseno de la Pagina Maestro-Detalle

### Diferencia clave con CRUD simple

En CRUD simple, el formulario y la tabla estan en la **misma ruta** (`/producto`), controlados por query params. En maestro-detalle, cada vista tiene su **propia ruta**:

| Vista | Ruta | Metodo | Descripcion |
|-------|------|--------|-------------|
| Listar | `/factura` | GET | Tabla con todas las facturas |
| Ver | `/factura/ver/<numero>` | GET | Detalle de una factura con productos |
| Formulario nuevo | `/factura/nueva` | GET | Formulario vacio para crear |
| Formulario editar | `/factura/editar/<numero>` | GET | Formulario precargado |
| Crear | `/factura/crear` | POST | Procesa creacion |
| Actualizar | `/factura/actualizar` | POST | Procesa actualizacion |
| Eliminar | `/factura/eliminar` | POST | Procesa eliminacion |

### La variable `vista` en el template

En lugar de multiples archivos HTML, se usa **un solo template** con la variable `vista` para controlar que seccion se muestra:

```python
# En el Blueprint:
return render_template('pages/factura.html', vista='listar', ...)
return render_template('pages/factura.html', vista='ver', ...)
return render_template('pages/factura.html', vista='formulario', ...)
```

```html
<!-- En el template: -->
{% if vista == 'listar' %}
    ... tabla de facturas ...
{% elif vista == 'ver' %}
    ... detalle de factura + tabla de productos ...
{% elif vista == 'formulario' %}
    ... formulario con filas dinamicas ...
{% endif %}
```

### Las 3 vistas

```
┌─────────────────────────────────────────────┐
│  VISTA "listar"                             │
│  ┌────┬──────────┬──────────┬─────┬──────┐  │
│  │ #  │ Cliente  │ Vendedor │Total│ Acc. │  │
│  ├────┼──────────┼──────────┼─────┼──────┤  │
│  │ 1  │ Ana      │ Carlos   │5.0M │V E X │  │
│  │ 2  │ Maria    │ Juan     │1.2M │V E X │  │
│  └────┴──────────┴──────────┴─────┴──────┘  │
│  [V]er  [E]ditar  [X] Eliminar              │
└─────────────────────────────────────────────┘

┌─────────────────────────────────────────────┐
│  VISTA "ver"                                │
│  ┌─────────────────────────────────────┐    │
│  │ Factura #1                          │    │
│  │ Cliente: Ana Torres (ID: 1)         │    │
│  │ Vendedor: Carlos Perez (ID: 1)      │    │
│  │ Total: $5,000,000.00                │    │
│  ├─────────────────────────────────────┤    │
│  │ Productos:                          │    │
│  │ ┌───────┬──────────┬────┬─────────┐ │    │
│  │ │Codigo │ Producto │Cant│ Subtotal│ │    │
│  │ ├───────┼──────────┼────┼─────────┤ │    │
│  │ │PR001  │ Laptop   │  2 │ 5.0M    │ │    │
│  │ └───────┴──────────┴────┴─────────┘ │    │
│  └─────────────────────────────────────┘    │
│  [Editar] [Eliminar]                        │
└─────────────────────────────────────────────┘

┌─────────────────────────────────────────────┐
│  VISTA "formulario"                         │
│  Cliente:   [▼ Ana Torres          ]        │
│  Vendedor:  [▼ Carlos Perez        ]        │
│                                             │
│  Productos:                                 │
│  [▼ PR001 - Laptop ] [Cant: 2] [Quitar]     │
│  [▼ PR003 - Teclado] [Cant: 3] [Quitar]     │
│  [+ Agregar Producto]                       │
│                                             │
│  [Guardar] [Cancelar]                       │
└─────────────────────────────────────────────┘
```

---

## 5. Paso a Paso: Construir factura.py y factura.html

### Paso 1: Crear el Blueprint (routes/factura.py)

Importaciones y configuracion base:

```python
import json
from flask import Blueprint, render_template, request, redirect, url_for, flash
from services.api_service import ApiService

bp = Blueprint('factura', __name__)
api = ApiService()
```

A diferencia del CRUD simple, no hay `TABLA` ni `CLAVE` porque los datos se manejan via stored procedures, no via el CRUD generico.

### Paso 2: Ruta LISTAR (GET /factura)

```python
@bp.route('/factura')
def index():
    """Lista todas las facturas con sus productos."""
    exito, datos = api.ejecutar_sp("sp_listar_facturas_y_productosporfactura", {
        "p_resultado": None
    })

    facturas = []
    if exito and isinstance(datos, dict):
        facturas = datos.get("facturas", [])
    elif exito and isinstance(datos, list):
        facturas = datos

    return render_template('pages/factura.html',
        facturas=facturas,
        vista='listar'
    )
```

**Detalles:**
- `api.ejecutar_sp()` llama a `POST /api/procedimientos/ejecutarsp`
- El SP retorna un JSON array donde cada factura incluye un array `productos` anidado
- Se pasa `vista='listar'` para que el template muestre la tabla de facturas
- `isinstance(datos, list)` maneja el caso donde el SP retorna directamente la lista

### Paso 3: Ruta VER (GET /factura/ver/\<numero\>)

```python
@bp.route('/factura/ver/<int:numero>')
def ver(numero):
    """Muestra el detalle de una factura con sus productos."""
    exito, datos = api.ejecutar_sp("sp_consultar_factura_y_productosporfactura", {
        "p_numero": numero,
        "p_resultado": None
    })

    factura = None
    if exito and isinstance(datos, dict):
        info = datos.get("factura", datos)
        info["productos"] = datos.get("productos", [])
        factura = info

    return render_template('pages/factura.html',
        factura=factura,
        vista='ver'
    )
```

**Detalles:**
- `<int:numero>` en la ruta convierte automaticamente el parametro a entero
- El SP consultar retorna `{"factura": {...}, "productos": [...]}`
- Se combinan en un solo diccionario `factura` con `factura["productos"]` adentro
- Si la factura no existe, `factura` queda como `None` y el template muestra un error

### Paso 4: Ruta FORMULARIO NUEVO (GET /factura/nueva)

```python
@bp.route('/factura/nueva')
def nueva():
    """Muestra el formulario para crear una factura."""
    clientes = api.listar('cliente')
    vendedores = api.listar('vendedor')
    personas = api.listar('persona')
    productos = api.listar('producto')

    # Cruzar FK: cliente/vendedor → persona → nombre
    mapa_personas = {p['codigo']: p['nombre'] for p in personas}
    for cli in clientes:
        cli['nombre'] = mapa_personas.get(cli.get('fkcodpersona'), 'Sin nombre')
    for ven in vendedores:
        ven['nombre'] = mapa_personas.get(ven.get('fkcodpersona'), 'Sin nombre')

    return render_template('pages/factura.html',
        vista='formulario',
        editando=False,
        clientes=clientes,
        vendedores=vendedores,
        productos_disponibles=productos
    )
```

**Detalles:**
- Se cargan 4 tablas: clientes, vendedores, personas, productos
- **Cross-reference de FKs**: `cliente.fkcodpersona` → `persona.codigo` → `persona.nombre`. Sin esto, los selects mostrarian solo IDs
- `mapa_personas` es un diccionario `{codigo: nombre}` para busqueda rapida O(1)
- `productos_disponibles` se pasa al template para los `<select>` de productos

### Paso 5: Ruta CREAR (POST /factura/crear)

```python
@bp.route('/factura/crear', methods=['POST'])
def crear():
    """Crea una nueva factura con sus productos."""
    fkidcliente = request.form.get('fkidcliente', 0, type=int)
    fkidvendedor = request.form.get('fkidvendedor', 0, type=int)

    # Recoger productos del formulario dinamico
    codigos = request.form.getlist('prod_codigo[]')
    cantidades = request.form.getlist('prod_cantidad[]')

    productos_lista = []
    for codigo, cantidad in zip(codigos, cantidades):
        if codigo and cantidad:
            productos_lista.append({
                "codigo": codigo,
                "cantidad": int(cantidad)
            })

    if not productos_lista:
        flash("Debe agregar al menos un producto.", "danger")
        return redirect(url_for('factura.nueva'))

    exito, datos = api.ejecutar_sp("sp_insertar_factura_y_productosporfactura", {
        "p_fkidcliente": fkidcliente,
        "p_fkidvendedor": fkidvendedor,
        "p_productos": json.dumps(productos_lista),
        "p_resultado": None
    })

    if exito:
        flash("Factura creada exitosamente.", "success")
    else:
        flash(f"Error al crear factura: {datos}", "danger")

    return redirect(url_for('factura.index'))
```

**Detalles:**
- `request.form.getlist('prod_codigo[]')` lee **todos** los valores con el mismo nombre del formulario. Los `[]` en el nombre son una convencion para campos multiples
- `zip(codigos, cantidades)` empareja cada codigo con su cantidad por posicion
- `json.dumps(productos_lista)` serializa la lista de productos a JSON string para el SP
- `p_resultado: None` — parametro OUTPUT del SP, la API lo maneja internamente

### Paso 6: Ruta FORMULARIO EDITAR (GET /factura/editar/\<numero\>)

```python
@bp.route('/factura/editar/<int:numero>')
def editar(numero):
    """Muestra el formulario para editar una factura existente."""
    # Consultar la factura actual
    exito, datos = api.ejecutar_sp("sp_consultar_factura_y_productosporfactura", {
        "p_numero": numero,
        "p_resultado": None
    })

    factura = None
    if exito and isinstance(datos, dict):
        info = datos.get("factura", datos)
        info["productos"] = datos.get("productos", [])
        factura = info

    if not factura:
        flash("Factura no encontrada.", "danger")
        return redirect(url_for('factura.index'))

    # Cargar datos para los selects (igual que en nueva())
    clientes = api.listar('cliente')
    vendedores = api.listar('vendedor')
    personas = api.listar('persona')
    productos = api.listar('producto')

    mapa_personas = {p['codigo']: p['nombre'] for p in personas}
    for cli in clientes:
        cli['nombre'] = mapa_personas.get(cli.get('fkcodpersona'), 'Sin nombre')
    for ven in vendedores:
        ven['nombre'] = mapa_personas.get(ven.get('fkcodpersona'), 'Sin nombre')

    return render_template('pages/factura.html',
        vista='formulario',
        editando=True,
        factura=factura,
        clientes=clientes,
        vendedores=vendedores,
        productos_disponibles=productos
    )
```

**Detalles:**
- Primero consulta la factura actual (con productos) via SP
- Luego carga las mismas 4 tablas que `nueva()` para los selects
- `editando=True` y `factura=factura` le dicen al template que precargue los datos
- Si la factura no existe, redirige al listado con un flash de error

### Paso 7: Ruta ACTUALIZAR (POST /factura/actualizar)

```python
@bp.route('/factura/actualizar', methods=['POST'])
def actualizar():
    """Actualiza una factura existente con sus productos."""
    numero = request.form.get('numero', 0, type=int)
    fkidcliente = request.form.get('fkidcliente', 0, type=int)
    fkidvendedor = request.form.get('fkidvendedor', 0, type=int)

    codigos = request.form.getlist('prod_codigo[]')
    cantidades = request.form.getlist('prod_cantidad[]')

    productos_lista = []
    for codigo, cantidad in zip(codigos, cantidades):
        if codigo and cantidad:
            productos_lista.append({"codigo": codigo, "cantidad": int(cantidad)})

    if not productos_lista:
        flash("Debe agregar al menos un producto.", "danger")
        return redirect(url_for('factura.editar', numero=numero))

    exito, datos = api.ejecutar_sp("sp_actualizar_factura_y_productosporfactura", {
        "p_numero": numero,
        "p_fkidcliente": fkidcliente,
        "p_fkidvendedor": fkidvendedor,
        "p_productos": json.dumps(productos_lista),
        "p_resultado": None
    })

    if exito:
        flash("Factura actualizada exitosamente.", "success")
    else:
        flash(f"Error al actualizar factura: {datos}", "danger")

    return redirect(url_for('factura.index'))
```

**El SP de actualizar hace:** DELETE de productos viejos (trigger restaura stock) → INSERT de nuevos productos (trigger descuenta stock) → UPDATE de cliente/vendedor. Todo dentro de una transaccion.

### Paso 8: Ruta ELIMINAR (POST /factura/eliminar)

```python
@bp.route('/factura/eliminar', methods=['POST'])
def eliminar():
    """Elimina una factura y sus productos (cascade)."""
    numero = request.form.get('numero', 0, type=int)

    exito, datos = api.ejecutar_sp("sp_borrar_factura_y_productosporfactura", {
        "p_numero": numero,
        "p_resultado": None
    })

    if exito:
        flash("Factura eliminada exitosamente.", "success")
    else:
        flash(f"Error al eliminar factura: {datos}", "danger")

    return redirect(url_for('factura.index'))
```

**El SP de borrar hace:** DELETE de factura con ON DELETE CASCADE → trigger restaura stock de cada producto eliminado.

### Paso 9: Template factura.html — Vista "listar"

```html
{% extends 'layout/base.html' %}

{% block title %}Facturas{% endblock %}

{% block content %}
<div class="container mt-4">
    <h3>Facturas y Productos por Factura</h3>

    {% if vista == 'listar' %}

        <a href="{{ url_for('factura.nueva') }}" class="btn btn-primary mb-3">
            Nueva Factura
        </a>

        {% if facturas %}
            <table class="table table-striped table-hover">
                <thead class="table-dark">
                    <tr>
                        <th>Numero</th>
                        <th>Cliente</th>
                        <th>Vendedor</th>
                        <th>Fecha</th>
                        <th>Total</th>
                        <th>Productos</th>
                        <th>Acciones</th>
                    </tr>
                </thead>
                <tbody>
                    {% for fac in facturas %}
                    <tr>
                        <td>{{ fac.numero }}</td>
                        <td>{{ fac.nombre_cliente }} (ID: {{ fac.fkidcliente }})</td>
                        <td>{{ fac.nombre_vendedor }} (ID: {{ fac.fkidvendedor }})</td>
                        <td>{{ fac.fecha[:10] if fac.fecha else '' }}</td>
                        <td>${{ "%.2f"|format(fac.total|float) }}</td>
                        <td>{{ fac.productos|length if fac.productos else 0 }}</td>
                        <td>
                            <a href="{{ url_for('factura.ver', numero=fac.numero) }}"
                               class="btn btn-info btn-sm">Ver</a>
                            <a href="{{ url_for('factura.editar', numero=fac.numero) }}"
                               class="btn btn-warning btn-sm">Editar</a>
                            <form method="POST" action="{{ url_for('factura.eliminar') }}"
                                  style="display:inline"
                                  onsubmit="return confirm('Eliminar factura #{{ fac.numero }}?')">
                                <input type="hidden" name="numero" value="{{ fac.numero }}" />
                                <button class="btn btn-danger btn-sm" type="submit">Eliminar</button>
                            </form>
                        </td>
                    </tr>
                    {% endfor %}
                </tbody>
            </table>
        {% else %}
            <div class="alert alert-warning">No se encontraron facturas.</div>
        {% endif %}
```

**Detalles:**
- `fac.productos|length` cuenta los productos de cada factura (el SP los incluye anidados)
- `"%.2f"|format(fac.total|float)` formatea el total con 2 decimales
- `fac.fecha[:10]` corta la fecha ISO para mostrar solo `YYYY-MM-DD`
- Cada factura tiene 3 acciones: Ver (GET), Editar (GET), Eliminar (POST con confirm)

### Paso 10: Template factura.html — Vista "ver"

```html
    {% elif vista == 'ver' %}

        <a href="{{ url_for('factura.index') }}" class="btn btn-secondary mb-3">
            Volver al listado
        </a>

        {% if factura %}
            <div class="card mb-3">
                <div class="card-header">
                    <strong>Factura #{{ factura.numero }}</strong>
                </div>
                <div class="card-body">
                    {# Cabecera: datos del maestro #}
                    <div class="row mb-3">
                        <div class="col-md-4">
                            <strong>Cliente:</strong> {{ factura.nombre_cliente }}
                        </div>
                        <div class="col-md-4">
                            <strong>Vendedor:</strong> {{ factura.nombre_vendedor }}
                        </div>
                        <div class="col-md-4">
                            <strong>Total:</strong> ${{ "%.2f"|format(factura.total|float) }}
                        </div>
                    </div>

                    {# Detalle: tabla anidada de productos #}
                    <h5>Productos</h5>
                    {% if factura.productos %}
                        <table class="table table-bordered">
                            <thead class="table-light">
                                <tr>
                                    <th>Codigo</th>
                                    <th>Producto</th>
                                    <th>Cantidad</th>
                                    <th>Valor Unitario</th>
                                    <th>Subtotal</th>
                                </tr>
                            </thead>
                            <tbody>
                                {% for prod in factura.productos %}
                                <tr>
                                    <td>{{ prod.codigo_producto }}</td>
                                    <td>{{ prod.nombre_producto }}</td>
                                    <td>{{ prod.cantidad }}</td>
                                    <td>${{ "%.2f"|format(prod.valorunitario|float) }}</td>
                                    <td>${{ "%.2f"|format(prod.subtotal|float) }}</td>
                                </tr>
                                {% endfor %}
                            </tbody>
                        </table>
                    {% endif %}
                </div>
            </div>

            {# Botones de accion #}
            <a href="{{ url_for('factura.editar', numero=factura.numero) }}"
               class="btn btn-warning me-2">Editar</a>
            <form method="POST" action="{{ url_for('factura.eliminar') }}" style="display:inline"
                  onsubmit="return confirm('Eliminar factura #{{ factura.numero }}?')">
                <input type="hidden" name="numero" value="{{ factura.numero }}" />
                <button class="btn btn-danger" type="submit">Eliminar</button>
            </form>
        {% else %}
            <div class="alert alert-danger">Factura no encontrada.</div>
        {% endif %}
```

**Estructura de la vista "ver":**
1. Card con cabecera (datos del maestro: cliente, vendedor, total, fecha)
2. Tabla anidada de productos (detalle)
3. Botones Editar y Eliminar al pie

### Paso 11: Template factura.html — Vista "formulario"

```html
    {% elif vista == 'formulario' %}

        <a href="{{ url_for('factura.index') }}" class="btn btn-secondary mb-3">
            Volver al listado
        </a>

        <div class="card mb-3">
            <div class="card-header">
                {{ "Editar Factura #" ~ factura.numero if editando else "Nueva Factura" }}
            </div>
            <div class="card-body">
                <form method="POST"
                      action="{{ url_for('factura.actualizar') if editando else url_for('factura.crear') }}"
                      id="formFactura"
                      onsubmit="{{ 'return confirm(...)' if editando else '' }}">

                    {% if editando %}
                        <input type="hidden" name="numero" value="{{ factura.numero }}" />
                    {% endif %}

                    <div class="row mb-3">
                        {# Select Cliente #}
                        <div class="col-md-6">
                            <label class="form-label">Cliente</label>
                            <select class="form-select" name="fkidcliente" required>
                                <option value="">-- Seleccionar --</option>
                                {% for cli in clientes %}
                                    <option value="{{ cli.id }}"
                                        {{ 'selected' if editando and factura
                                           and factura.fkidcliente == cli.id }}>
                                        {{ cli.nombre }} (Credito: ${{ cli.credito }})
                                    </option>
                                {% endfor %}
                            </select>
                        </div>

                        {# Select Vendedor #}
                        <div class="col-md-6">
                            <label class="form-label">Vendedor</label>
                            <select class="form-select" name="fkidvendedor" required>
                                <option value="">-- Seleccionar --</option>
                                {% for ven in vendedores %}
                                    <option value="{{ ven.id }}"
                                        {{ 'selected' if editando and factura
                                           and factura.fkidvendedor == ven.id }}>
                                        {{ ven.nombre }} (Carnet: {{ ven.carnet }})
                                    </option>
                                {% endfor %}
                            </select>
                        </div>
                    </div>
```

**Detalles clave de los selects:**
- `'selected' if editando and factura and factura.fkidcliente == cli.id` — preselecciona el cliente/vendedor actual al editar
- El cross-reference de personas ya se hizo en la ruta (`cli['nombre']`), asi que aqui solo se muestra
- `required` en el `<select>` obliga a seleccionar antes de enviar

### Paso 12: Filas dinamicas de productos (JavaScript)

```html
                    {# ───────── PRODUCTOS DINAMICOS ───────── #}
                    <h5>Productos</h5>
                    <div id="productos-container">
                        {% if editando and factura and factura.productos %}
                            {# Modo editar: precargar productos existentes #}
                            {% for prod in factura.productos %}
                            <div class="row mb-2 producto-fila">
                                <div class="col-md-5">
                                    <select class="form-select" name="prod_codigo[]" required>
                                        <option value="">-- Producto --</option>
                                        {% for p in productos_disponibles %}
                                            <option value="{{ p.codigo }}"
                                                {{ 'selected' if p.codigo == prod.codigo_producto }}>
                                                {{ p.codigo }} - {{ p.nombre }} (Stock: {{ p.stock }})
                                            </option>
                                        {% endfor %}
                                    </select>
                                </div>
                                <div class="col-md-3">
                                    <input class="form-control" type="number" name="prod_cantidad[]"
                                           min="1" value="{{ prod.cantidad }}" required />
                                </div>
                                <div class="col-md-2">
                                    <button type="button" class="btn btn-danger btn-sm"
                                            onclick="this.closest('.producto-fila').remove()">
                                        Quitar
                                    </button>
                                </div>
                            </div>
                            {% endfor %}
                        {% else %}
                            {# Modo crear: una fila vacia #}
                            <div class="row mb-2 producto-fila">
                                <div class="col-md-5">
                                    <select class="form-select" name="prod_codigo[]" required>
                                        <option value="">-- Producto --</option>
                                        {% for p in productos_disponibles %}
                                            <option value="{{ p.codigo }}">
                                                {{ p.codigo }} - {{ p.nombre }} (Stock: {{ p.stock }})
                                            </option>
                                        {% endfor %}
                                    </select>
                                </div>
                                <div class="col-md-3">
                                    <input class="form-control" type="number" name="prod_cantidad[]"
                                           min="1" value="1" required />
                                </div>
                                <div class="col-md-2">
                                    <button type="button" class="btn btn-danger btn-sm"
                                            onclick="this.closest('.producto-fila').remove()">
                                        Quitar
                                    </button>
                                </div>
                            </div>
                        {% endif %}
                    </div>

                    <button type="button" class="btn btn-outline-primary btn-sm mb-3"
                            onclick="agregarProducto()">
                        + Agregar Producto
                    </button>

                    <div>
                        <button class="btn btn-success me-2" type="submit">Guardar</button>
                        <a href="{{ url_for('factura.index') }}" class="btn btn-secondary">Cancelar</a>
                    </div>
                </form>
            </div>
        </div>
```

**Detalles:**
- `name="prod_codigo[]"` — los `[]` permiten que Flask lea multiples valores con `getlist()`
- `this.closest('.producto-fila').remove()` — JavaScript nativo para quitar la fila mas cercana
- Al editar, el `{% for prod in factura.productos %}` precarga las filas existentes con `selected`

### Paso 13: JavaScript para agregar filas

```html
        <script>
            function agregarProducto() {
                const container = document.getElementById('productos-container');
                const primeraFila = container.querySelector('.producto-fila');

                if (!primeraFila) {
                    // Si no hay filas, crear una desde cero con los productos disponibles
                    const opciones = {{ productos_disponibles | tojson }};
                    let selectHtml = '<option value="">-- Producto --</option>';
                    opciones.forEach(p => {
                        selectHtml += `<option value="${p.codigo}">` +
                            `${p.codigo} - ${p.nombre} (Stock: ${p.stock})</option>`;
                    });
                    container.innerHTML += `
                        <div class="row mb-2 producto-fila">
                            <div class="col-md-5">
                                <select class="form-select" name="prod_codigo[]"
                                        required>${selectHtml}</select>
                            </div>
                            <div class="col-md-3">
                                <input class="form-control" type="number" name="prod_cantidad[]"
                                       min="1" value="1" required />
                            </div>
                            <div class="col-md-2">
                                <button type="button" class="btn btn-danger btn-sm"
                                        onclick="this.closest('.producto-fila').remove()">
                                    Quitar
                                </button>
                            </div>
                        </div>`;
                    return;
                }

                // Clonar la primera fila y resetear valores
                const nuevaFila = primeraFila.cloneNode(true);
                nuevaFila.querySelector('select').selectedIndex = 0;
                nuevaFila.querySelector('input[type="number"]').value = 1;
                container.appendChild(nuevaFila);
            }
        </script>

    {% endif %}
</div>
{% endblock %}
```

**Detalles:**
- `{{ productos_disponibles | tojson }}` — el filtro `tojson` de Jinja2 convierte la lista Python a JSON en el HTML generado, accesible desde JavaScript
- `cloneNode(true)` — clona la primera fila incluyendo todos sus hijos
- Si todas las filas fueron quitadas, crea una nueva desde los datos JSON

---

## 6. Patrones Clave Explicados

### Patron 1: Vista controlada por variable

En Flask, la variable `vista` se pasa desde cada ruta y el template usa `{% if %}` / `{% elif %}`:

```python
# Blueprint:
return render_template('pages/factura.html', vista='listar', ...)
return render_template('pages/factura.html', vista='ver', ...)
return render_template('pages/factura.html', vista='formulario', ...)
```

```html
<!-- Template: -->
{% if vista == 'listar' %}
    ...
{% elif vista == 'ver' %}
    ...
{% elif vista == 'formulario' %}
    ...
{% endif %}
```

### Patron 2: Filas dinamicas con name="campo[]" + getlist()

Las filas de productos en el formulario usan campos con `[]` en el nombre. Al enviar, Flask los recibe como listas:

```html
<!-- HTML: multiples campos con el mismo nombre -->
<select name="prod_codigo[]">...</select>   <!-- Fila 1 -->
<input name="prod_cantidad[]" value="2" />

<select name="prod_codigo[]">...</select>   <!-- Fila 2 -->
<input name="prod_cantidad[]" value="3" />
```

```python
# Python: leer como listas y emparejar
codigos = request.form.getlist('prod_codigo[]')      # ['PR001', 'PR003']
cantidades = request.form.getlist('prod_cantidad[]')  # ['2', '3']

for codigo, cantidad in zip(codigos, cantidades):
    productos_lista.append({"codigo": codigo, "cantidad": int(cantidad)})
```

### Patron 3: Cross-reference de FKs con diccionario

Los clientes y vendedores tienen `fkcodpersona` (FK a persona), no nombres directos. Para mostrar nombres en los selects:

```python
# 1. Cargar personas y crear mapa {codigo: nombre}
personas = api.listar('persona')
mapa_personas = {p['codigo']: p['nombre'] for p in personas}

# 2. Inyectar el nombre en cada cliente/vendedor
for cli in clientes:
    cli['nombre'] = mapa_personas.get(cli.get('fkcodpersona'), 'Sin nombre')
```

```html
<!-- 3. Usar en el template -->
<option value="{{ cli.id }}">{{ cli.nombre }} (Credito: ${{ cli.credito }})</option>
```

### Patron 4: JSON como puente entre formulario y SP

El formulario HTML envia campos individuales. El Blueprint los recolecta, arma una lista de diccionarios y la serializa a JSON para el SP:

```
Formulario HTML          →  Blueprint Python           →  SP en la BD
prod_codigo[] = PR001       productos_lista = [           @p_productos =
prod_cantidad[] = 2           {"codigo":"PR001",           '[{"codigo":"PR001",
prod_codigo[] = PR003           "cantidad":2},               "cantidad":2},
prod_cantidad[] = 3           {"codigo":"PR003",            {"codigo":"PR003",
                                "cantidad":3}                "cantidad":3}]'
                              ]
                              json.dumps(productos_lista)
```

### Patron 5: Confirm con onsubmit nativo

Flask no necesita JavaScript interop como Blazor. Se usa `onsubmit` directamente en el `<form>`:

```html
<!-- Eliminar: confirm siempre -->
<form method="POST" action="{{ url_for('factura.eliminar') }}"
      onsubmit="return confirm('Eliminar factura #{{ fac.numero }}?')">

<!-- Actualizar: confirm solo en modo edicion -->
<form method="POST" action="{{ url_for('factura.actualizar') }}"
      onsubmit="{{ 'return confirm(\'¿Actualizar esta factura?\')' if editando else '' }}">
```

---

## 7. Otros Ejemplos de Maestro-Detalle

### Ejemplo: Pedido → Items del Pedido

Misma estructura que Factura, con diferentes campos:

```python
# routes/pedido.py
bp = Blueprint('pedido', __name__)
api = ApiService()

@bp.route('/pedido')
def index():
    exito, datos = api.ejecutar_sp("sp_listar_pedidos_y_items", {"p_resultado": None})
    pedidos = datos if exito and isinstance(datos, list) else []
    return render_template('pages/pedido.html', pedidos=pedidos, vista='listar')

@bp.route('/pedido/crear', methods=['POST'])
def crear():
    fkidcliente = request.form.get('fkidcliente', 0, type=int)
    codigos = request.form.getlist('item_codigo[]')
    cantidades = request.form.getlist('item_cantidad[]')
    observaciones = request.form.getlist('item_observacion[]')

    items = []
    for cod, cant, obs in zip(codigos, cantidades, observaciones):
        if cod and cant:
            items.append({"codigo": cod, "cantidad": int(cant), "observacion": obs})

    exito, datos = api.ejecutar_sp("sp_insertar_pedido_y_items", {
        "p_fkidcliente": fkidcliente,
        "p_direccion_entrega": request.form.get('direccion', ''),
        "p_items": json.dumps(items),
        "p_resultado": None
    })
    flash("Pedido creado." if exito else f"Error: {datos}", "success" if exito else "danger")
    return redirect(url_for('pedido.index'))
```

### Ejemplo: Matricula → Materias Inscritas

```python
# routes/matricula.py
@bp.route('/matricula/crear', methods=['POST'])
def crear():
    fkidestudiante = request.form.get('fkidestudiante', 0, type=int)
    periodo = request.form.get('periodo', '')

    codigos = request.form.getlist('materia_codigo[]')
    horarios = request.form.getlist('materia_horario[]')

    materias = []
    for cod, hor in zip(codigos, horarios):
        if cod:
            materias.append({"codigo": cod, "horario": hor})

    exito, datos = api.ejecutar_sp("sp_insertar_matricula_y_materias", {
        "p_fkidestudiante": fkidestudiante,
        "p_periodo": periodo,
        "p_materias": json.dumps(materias),
        "p_resultado": None
    })
    ...
```

### Ejemplos Reales por Modulo (Bases de Datos del Sistema)

#### Modulo: Gestion Profesoral (`gestion_profesoral`)

**Relacion: Docente → Estudios Realizados**

Un docente (maestro) posee multiples estudios realizados (detalle), cada uno con titulo, universidad, tipo, ciudad, pais y metodologia.

```
docente (cedula PK)
   └── estudios_realizados (id PK, docente FK → docente.cedula)
          ├── estudio_ac (N:N con area_conocimiento)
          ├── apoyo_profesoral (1:1)
          └── beca (1:1)
```

```python
# routes/docente_estudios.py — Blueprint maestro-detalle
@bp.route('/docente-estudios/crear', methods=['POST'])
def crear():
    cedula = request.form.get('cedula', 0, type=int)
    nombres = request.form.get('nombres', '')
    apellidos = request.form.get('apellidos', '')
    # ... demas campos del docente

    titulos = request.form.getlist('estudio_titulo[]')
    universidades = request.form.getlist('estudio_universidad[]')
    tipos = request.form.getlist('estudio_tipo[]')
    ciudades = request.form.getlist('estudio_ciudad[]')

    estudios = []
    for tit, uni, tip, ciu in zip(titulos, universidades, tipos, ciudades):
        if tit and uni:
            estudios.append({
                "titulo": tit, "universidad": uni,
                "tipo": tip, "ciudad": ciu
            })

    exito, datos = api.ejecutar_sp("sp_insertar_docente_y_estudios", {
        "p_cedula": cedula, "p_nombres": nombres, "p_apellidos": apellidos,
        "p_estudios": json.dumps(estudios), "p_resultado": None
    })
    ...
```

#### Modulo: Innovacion Curricular (`innovacion_curricular`)

**Relacion: Programa → Actividades Academicas**

```
programa (id PK, facultad FK)
   └── activ_academica (id PK, disenio FK → programa.id)
```

```python
# Campos del formulario dinamico para actividades:
# name="aa_nombre[]", name="aa_creditos[]", name="aa_tipo[]",
# name="aa_area_formacion[]", name="aa_idioma[]"
```

#### Modulo: Investigacion (`investigacion`)

**Relacion: Grupo de Investigacion → Semilleros**

```
grupo_investigacion (id PK, universidad FK)
   └── semillero (id PK, grupo_investigacion FK)
```

#### Modulo: Mapa de Conocimiento (`mapa_conocimiento`)

**Relacion: Proyecto → Productos Academicos**

```
proyecto (id PK)
   └── producto (id PK, proyecto FK, tipo_producto FK)
```

### Resumen Comparativo de los 5 Modulos

| Modulo | Maestro | Detalle | Campos `[]` del formulario |
|--------|---------|---------|---------------------------|
| **Facturas** | factura | productosporfactura | `prod_codigo[]`, `prod_cantidad[]` |
| **Gestion Profesoral** | docente | estudios_realizados | `estudio_titulo[]`, `estudio_universidad[]`, `estudio_tipo[]` |
| **Innovacion Curricular** | programa | activ_academica | `aa_nombre[]`, `aa_creditos[]`, `aa_tipo[]` |
| **Investigacion** | grupo_investigacion | semillero | `sem_nombre[]`, `sem_fecha_fundacion[]` |
| **Mapa de Conocimiento** | proyecto | producto | `prod_nombre[]`, `prod_categoria[]`, `prod_tipo_producto[]` |

### Tabla de Adaptacion

Para adaptar `factura.py` + `factura.html` a otro maestro-detalle:

| Elemento | Factura → Productos | Tu caso |
|----------|-------------------|---------|
| Blueprint nombre | `'factura'` | `'tu_modulo'` |
| Rutas | `/factura`, `/factura/ver/<n>`, ... | `/tu-modulo`, `/tu-modulo/ver/<id>`, ... |
| SP listar | `sp_listar_facturas_y_productosporfactura` | `sp_listar_tu_maestro_y_detalle` |
| SP consultar | `sp_consultar_factura_...` | `sp_consultar_tu_maestro_...` |
| SP insertar | `sp_insertar_factura_...` | `sp_insertar_tu_maestro_...` |
| SP actualizar | `sp_actualizar_factura_...` | `sp_actualizar_tu_maestro_...` |
| SP borrar | `sp_borrar_factura_...` | `sp_borrar_tu_maestro_...` |
| Selects maestro | Cliente, Vendedor | FKs de tu maestro |
| Campos `[]` detalle | `prod_codigo[]`, `prod_cantidad[]` | Campos de tu detalle |
| Cross-reference | persona → cliente/vendedor | Tablas FK de tu maestro |
| `json.dumps()` | `productos_lista` | Tu lista de detalle |

---

## 8. Errores Comunes y Soluciones

### Error 1: getlist() retorna lista vacia

**Sintoma:** `request.form.getlist('prod_codigo[]')` retorna `[]`.

**Causa:** El nombre en el HTML no coincide exactamente con el del `getlist()`.

```html
<!-- MAL: sin [] -->
<select name="prod_codigo">

<!-- BIEN: con [] -->
<select name="prod_codigo[]">
```

```python
# El nombre debe ser identico, incluyendo los []
codigos = request.form.getlist('prod_codigo[]')
```

### Error 2: zip() descarta elementos

**Sintoma:** Si hay 3 codigos pero 2 cantidades, se pierde un producto.

`zip()` se detiene en la lista mas corta. Siempre asegurar que los campos `[]` son pares:

```python
# Verificar que todas las listas tienen la misma longitud
codigos = request.form.getlist('prod_codigo[]')
cantidades = request.form.getlist('prod_cantidad[]')
assert len(codigos) == len(cantidades), "Campos desalineados"
```

### Error 3: p_resultado vs @p_resultado

**Sintoma:** Los datos del SP no se parsean correctamente.

SQL Server retorna OUTPUT con prefijo `@`:
```json
{ "resultados": [{ "@p_resultado": "[...]" }] }
```

PostgreSQL retorna sin prefijo:
```json
{ "resultados": [{ "p_resultado": "[...]" }] }
```

**Solucion en api_service.py:** Buscar ambas variantes:

```python
p_resultado = resultados[0].get("p_resultado") or resultados[0].get("@p_resultado")
```

### Error 4: json.dumps() con caracteres especiales

**Sintoma:** Error al enviar productos con nombres que contienen comillas.

`json.dumps()` escapa automaticamente comillas y caracteres especiales. No hay que hacer escape manual:

```python
# BIEN - json.dumps maneja todo
productos_lista = [{"codigo": "PR001", "cantidad": 2}]
json_str = json.dumps(productos_lista)
# Resultado: '[{"codigo": "PR001", "cantidad": 2}]'
```

### Error 5: tojson genera HTML-escaped

**Sintoma:** `{{ productos_disponibles | tojson }}` en JavaScript genera `&quot;` en vez de `"`.

**Solucion:** En Jinja2, `tojson` ya es seguro para JavaScript. Pero si se escapa doble:

```html
<!-- BIEN -->
<script>
    const opciones = {{ productos_disponibles | tojson }};
</script>

<!-- MAL: safe no necesario con tojson -->
<script>
    const opciones = {{ productos_disponibles | tojson | safe }};
</script>
```

### Error 6: Flash messages no aparecen

**Sintoma:** `flash()` no muestra la alerta despues de redirigir.

**Causa:** Falta `app.secret_key` en `app.py`. Flask necesita la clave secreta para firmar las cookies de sesion donde se almacenan los mensajes flash:

```python
# app.py
app.secret_key = SECRET_KEY  # Sin esto, flash() falla silenciosamente
```

### Error 7: Confirm no funciona en el formulario de actualizar

**Sintoma:** El `onsubmit` con confirm no se genera correctamente.

```html
<!-- MAL: comillas mal escapadas -->
<form onsubmit="return confirm('¿Actualizar?')">

<!-- BIEN: escapar con \' dentro de la expresion Jinja2 -->
<form onsubmit="{{ 'return confirm(\'¿Actualizar esta factura?\')' if editando else '' }}">
```

---

## 9. Equivalencia Flask vs Blazor

### Tabla Comparativa

| Concepto | Flask (Python + Jinja2) | Blazor Server (C# + .razor) |
|----------|------------------------|----------------------------|
| **Archivo de logica** | `routes/factura.py` (Blueprint) | `Components/Pages/Factura.razor` (`@code {}`) |
| **Archivo de template** | `templates/pages/factura.html` | Mismo archivo `.razor` (HTML arriba) |
| **Framework UI** | Jinja2 templates + Bootstrap | Razor syntax + Bootstrap |
| **Lenguaje servidor** | Python | C# |
| **Estado** | Sin estado (HTTP stateless) | Con estado (SignalR connection) |
| **Switch de vistas** | `{% if vista == 'listar' %}` | `@if (vista == "listar")` |
| **Bucle** | `{% for prod in productos %}` | `@foreach (var prod in productos)` |
| **Condicional en atributo** | `{{ 'selected' if condicion }}` | `selected="@(condicion ? "selected" : null)"` |
| **Formulario** | `<form method="POST" action="...">` | `<button @onclick="Guardar">` (sin form) |
| **Campos multiples** | `name="prod_codigo[]"` + `getlist()` | `List<ProductoFila>` + `@for` con `@bind` |
| **Agregar fila** | JavaScript: `cloneNode()` | C#: `filas.Add(new ProductoFila())` |
| **Quitar fila** | JS: `this.closest('.fila').remove()` | C#: `filas.RemoveAt(idx)` |
| **Confirm** | `onsubmit="return confirm(...)"` | `await JS.InvokeAsync<bool>("confirm", ...)` |
| **Cross-reference FK** | `mapa_personas = {p['codigo']: p['nombre'] ...}` | `mapaPersonas = personas.ToDictionary(...)` |
| **JSON a SP** | `json.dumps(lista)` | `JsonSerializer.Serialize(lista)` |
| **Alertas** | `flash("msg", "success")` + redirect | `mensaje = "msg"` + `<div class="alert">` |
| **Servicio API** | `ApiService.ejecutar_sp()` (requests) | `SpService.EjecutarSpAsync()` (HttpClient) |
| **Registro servicio** | `app.register_blueprint(bp)` | `builder.Services.AddScoped<SpService>()` |
| **Navegacion** | `redirect(url_for('factura.index'))` | `vista = "listar"` (cambia variable) |
| **Interactividad** | Requiere recarga de pagina (POST/Redirect/GET) | Sin recarga (SignalR actualiza DOM) |

### Ventajas de cada enfoque

**Flask:**
- Simplicidad: un archivo `.py` + un `.html` por modulo
- Sin estado: no hay problemas de conexion SignalR
- JavaScript nativo: `confirm()`, `cloneNode()` sin interop
- Familiar para desarrolladores web clasicos

**Blazor:**
- Sin recargas: la UI se actualiza sin navegar
- Tipo seguro: clases C# para `ProductoFila`, `ClienteInfo`
- Sin JavaScript: `@bind`, `@onclick`, `List<T>.Add()`
- Reutilizable: componentes `.razor` encapsulados

### Flujo Comparativo: Crear Factura

```
FLASK:
1. GET /factura/nueva          → render template (formulario vacio)
2. Usuario llena formulario    → agrega filas con JavaScript (cloneNode)
3. POST /factura/crear         → getlist() → json.dumps() → ejecutar_sp()
4. flash() + redirect          → GET /factura (recarga pagina completa)

BLAZOR:
1. Click "Nueva Factura"       → vista = "formulario" (sin navegar)
2. Usuario llena formulario    → agrega filas con filas.Add() (sin JS)
3. Click "Guardar"             → @onclick → Serialize() → EjecutarSpAsync()
4. mensaje = "..." + vista = "listar" (sin recargar pagina)
```
