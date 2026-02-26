# Tutorial: Frontend Flask CRUD
# Parte 4: Layout y Navegacion

En esta parte creamos la plantilla base con sidebar, el menu de navegacion con links a las 6 tablas, los estilos CSS y la pagina de inicio.

---

## 4.1 Que es el Layout en Flask con Jinja2

El **layout** es la estructura visual que envuelve todas las paginas. En Flask se implementa con **herencia de templates** Jinja2:

```
┌──────────────────────────────────────────────────────┐
│  base.html                                            │
│  ┌────────────┐  ┌────────────────────────────────┐  │
│  │ nav_menu   │  │  Contenido de la pagina        │  │
│  │ .html      │  │  ({% block content %})          │  │
│  │            │  │                                 │  │
│  │  Home      │  │  Aqui se inserta cada           │  │
│  │  Empresa   │  │  pagina hija segun la URL:      │  │
│  │  Persona   │  │                                 │  │
│  │  Producto  │  │  /          → home.html         │  │
│  │  Rol       │  │  /producto  → producto.html     │  │
│  │  Ruta      │  │  /empresa   → empresa.html      │  │
│  │  Usuario   │  │                                 │  │
│  └────────────┘  └────────────────────────────────┘  │
└──────────────────────────────────────────────────────┘
```

- **base.html** — Define la estructura general: sidebar + area de contenido + mensajes flash
- **nav_menu.html** — Define los links del menu lateral (se incluye con `{% include %}`)
- **{% block content %}** — Hueco donde cada pagina hija inserta su contenido

---

## 4.2 Crear base.html (Plantilla Principal)

Creamos `templates/layout/base.html`:

```html
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>{% block title %}CRUD Facturas{% endblock %}</title>

    {# Bootstrap 5 desde CDN #}
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css"
          rel="stylesheet" />

    {# Estilos personalizados #}
    <link href="{{ url_for('static', filename='css/app.css') }}" rel="stylesheet" />
</head>
<body>
    <div class="page">
        {# Sidebar con menu de navegacion #}
        <div class="sidebar">
            {% include 'components/nav_menu.html' %}
        </div>

        {# Contenido principal #}
        <main>
            <div class="top-row px-4">
                <span>Frontend Flask — API GenericaCsharp</span>
            </div>

            <article class="content px-4">
                {# Mensajes flash (alertas de exito/error) #}
                {% with mensajes = get_flashed_messages(with_categories=true) %}
                    {% if mensajes %}
                        {% for categoria, mensaje in mensajes %}
                            <div class="alert alert-{{ categoria }} alert-dismissible fade show mt-3">
                                {{ mensaje }}
                                <button type="button" class="btn-close"
                                        onclick="this.parentElement.remove()"></button>
                            </div>
                        {% endfor %}
                    {% endif %}
                {% endwith %}

                {# Contenido especifico de cada pagina #}
                {% block content %}{% endblock %}
            </article>
        </main>
    </div>
</body>
</html>
```

**Elementos clave:**

| Elemento | Que hace |
|---|---|
| `{% block title %}` | Titulo de la pestaña (cada pagina lo sobreescribe) |
| `{{ url_for('static', ...) }}` | Genera la URL correcta al archivo CSS estatico |
| `{% include 'components/nav_menu.html' %}` | Inserta el menu de navegacion |
| `get_flashed_messages(with_categories=true)` | Obtiene los mensajes flash con su categoria |
| `alert-{{ categoria }}` | La categoria (success/danger) se usa como clase CSS |
| `{% block content %}{% endblock %}` | Hueco donde va el contenido de cada pagina |

---

## 4.3 Crear nav_menu.html (Menu Lateral)

Creamos `templates/components/nav_menu.html`:

```html
{# Barra superior del sidebar #}
<div class="top-row ps-3 navbar navbar-dark">
    <div class="container-fluid">
        <a class="navbar-brand" href="/">CRUD Facturas</a>
    </div>
</div>

{# Toggle hamburguesa para movil (funciona sin JavaScript, solo CSS) #}
<input type="checkbox" title="Menu de navegacion" class="navbar-toggler" />

{# Links de navegacion #}
<div class="nav-scrollable">
    <nav class="nav flex-column">
        <div class="nav-item px-3">
            <a class="nav-link {{ 'active' if request.path == '/' }}" href="/">
                <span class="bi bi-house-door-fill-nav-menu"></span> Home
            </a>
        </div>

        <div class="nav-item px-3">
            <a class="nav-link {{ 'active' if request.path.startswith('/empresa') }}" href="/empresa">
                <span class="bi bi-list-nested-nav-menu"></span> Empresa
            </a>
        </div>

        {# ... (los demas links siguen el mismo patron) #}
    </nav>
</div>
```

**Link activo:** La expresion `{{ 'active' if request.path.startswith('/empresa') }}` agrega la clase CSS `active` cuando el usuario esta en la pagina de Empresa. Esto resalta visualmente el link actual en el sidebar.

**Toggle movil:** El checkbox `navbar-toggler` funciona como boton hamburguesa en pantallas pequenas. Se controla solo con CSS (sin JavaScript): cuando esta marcado, el CSS muestra el menu.

---

## 4.4 Crear home.html (Pagina de Inicio)

Creamos `templates/pages/home.html`:

```html
{% extends 'layout/base.html' %}

{% block title %}CRUD Facturas{% endblock %}

{% block content %}
<div class="container mt-4">
    <h1>CRUD - Base de Datos Facturas</h1>
    <p class="lead">
        Frontend Flask que consume la API generica
        <strong>ApiGenericaCsharp</strong> para gestionar las tablas
        de <code>bdfacturas</code>.
    </p>

    <div class="alert alert-info">
        <strong>Tablas disponibles:</strong> Empresa, Persona, Producto, Rol, Ruta, Usuario.
        <br />
        Use el menu lateral para navegar a cada tabla.
    </div>
</div>
{% endblock %}
```

**Que hace:**
- `{% extends 'layout/base.html' %}` — Hereda la estructura de la plantilla base
- `{% block title %}` — Define el titulo de la pestaña
- `{% block content %}` — Define el contenido especifico de esta pagina
- Clases Bootstrap: `container`, `mt-4`, `lead`, `alert alert-info` — dan estilo profesional

---

## 4.5 Crear la Ruta Home

Creamos `routes/home.py`:

```python
"""
home.py - Blueprint para la pagina de inicio.
"""

from flask import Blueprint, render_template

bp = Blueprint('home', __name__)

@bp.route('/')
def index():
    """Renderiza la pagina de inicio."""
    return render_template('pages/home.html')
```

Y lo registramos en `app.py`:

```python
from routes.home import bp as home_bp
app.register_blueprint(home_bp)
```

---

## 4.6 Crear los Estilos CSS

Creamos `static/css/app.css` con los estilos del sidebar, topbar, navegacion e iconos. El archivo completo incluye:

- **Estructura `.page`** — Flexbox: sidebar a la izquierda, main a la derecha
- **Sidebar** — Fondo degradado azul oscuro a morado
- **Topbar** — Barra gris clara con el nombre del frontend
- **Toggle movil** — Checkbox estilizado como boton hamburguesa (sin JavaScript)
- **Iconos SVG inline** — Icono de casa (Home) e icono de lista (tablas)
- **Links activos** — Fondo blanco semitransparente para el link actual
- **Responsive** — En escritorio: sidebar fijo 250px; en movil: menu colapsable

---

## 4.7 Como Funciona la Navegacion

```
  1. Usuario abre http://localhost:5100/
                    │
                    ▼
  2. Flask ejecuta home.index() → render_template('pages/home.html')
     - home.html hereda de base.html
     - base.html incluye nav_menu.html
     - Se genera HTML completo con sidebar + contenido
                    │
                    ▼
  3. Usuario hace click en "Producto" en el menu
                    │
                    ▼
  4. El navegador hace GET http://localhost:5100/producto
     - Flask ejecuta producto.index()
     - Genera HTML completo de nuevo (sidebar + tabla de productos)
     - El navegador reemplaza TODA la pagina
```

**Diferencia con SPA:** En Flask, cada click en el menu recarga la pagina completa. El sidebar y el layout se re-renderizan cada vez, pero como el HTML es ligero, la carga es rapida.

---

## 4.8 Commit

```bash
git add .
git commit -m "Agregar layout, navegacion, pagina Home y estilos CSS"
```

---

## Siguiente Parte

En la **Parte 5** crearemos el CRUD completo de la tabla **Producto** — la pagina mas importante del tutorial. Incluira: tabla con datos, formulario para crear/editar, botones de eliminar, alertas y control de limite.
