# Tutorial: Frontend Flask CRUD
# Parte 7: Verificacion Final

En esta ultima parte vamos a correr la API y el frontend juntos, probar las 6 tablas CRUD y confirmar que todo funciona.

---

## 7.1 Requisitos Previos

Antes de empezar necesitamos:

1. **Base de datos** corriendo (PostgreSQL, SQL Server, MySQL, etc.)
2. **La API `ApiGenericaCsharp`** lista para correr (puerto 5034)
3. **El frontend `FrontFlask_AppiGenericaCsharp`** listo para correr (puerto 5100)
4. **Dependencias Python instaladas** (`pip install -r requirements.txt`)

Si no tienes datos en las tablas, no hay problema. El frontend mostrara "No se encontraron registros" y podras crear registros desde el formulario.

---

## 7.2 Paso 1: Correr la API

Abrimos una terminal y ejecutamos:

```bash
cd ApiGenericaCsharp
dotnet run
```

Debemos ver algo como:

```
info: Microsoft.Hosting.Lifetime[14]
      Now listening on: http://localhost:5034
```

**No cerrar esta terminal.** La API debe seguir corriendo mientras probamos el frontend.

Para verificar que la API responde, podemos abrir en el navegador:

```
http://localhost:5034/swagger
```

Si vemos la interfaz de Swagger, la API esta funcionando correctamente.

---

## 7.3 Paso 2: Correr el Frontend

Abrimos **otra terminal** (la anterior debe seguir abierta con la API) y ejecutamos:

```bash
cd FrontFlask_AppiGenericaCsharp
python app.py
```

Debemos ver algo como:

```
 * Serving Flask app 'app'
 * Debug mode: on
 * Running on http://127.0.0.1:5100
```

Ahora abrimos el navegador en:

```
http://localhost:5100
```

Debemos ver la pagina de inicio con el mensaje de bienvenida y el sidebar con los 6 links.

---

## 7.4 Paso 3: Probar Cada Tabla

Vamos a probar las 3 operaciones basicas en cada tabla: **Crear**, **Editar** y **Eliminar**.

### 7.4.1 Probar Producto

1. Click en **Producto** en el menu lateral
2. Click en **Nuevo Producto**
3. Llenar: Codigo=`PR001`, Nombre=`Laptop`, Stock=`10`, Valor Unitario=`1500.50`
4. Click en **Guardar** → debe aparecer alerta verde "Registro creado"
5. El registro aparece en la tabla
6. Click en **Editar** → cambiar Nombre a `Laptop Pro`
7. Click en **Guardar** → alerta verde "Registro actualizado"
8. Click en **Eliminar** → confirmacion → alerta verde "Registro eliminado"

### 7.4.2 Probar Empresa

1. Click en **Empresa** en el menu
2. Crear: Codigo=`E001`, Nombre=`Mi Empresa`
3. Editar: cambiar Nombre a `Mi Empresa S.A.`
4. Eliminar el registro

### 7.4.3 Probar Persona

1. Click en **Persona** en el menu
2. Crear: Codigo=`P001`, Nombre=`Juan`, Email=`juan@test.com`, Telefono=`555-1234`
3. Editar: cambiar Email a `juan@empresa.com`
4. Eliminar el registro

### 7.4.4 Probar Rol

1. Click en **Rol** en el menu
2. Crear: ID=`1`, Nombre=`Administrador`
3. Editar: cambiar Nombre a `Admin`
4. Eliminar el registro

**Nota:** En esta tabla la clave primaria es `id` (numerico), no `codigo` (texto).

### 7.4.5 Probar Ruta

1. Click en **Ruta** en el menu
2. Crear: Ruta=`/api/productos`, Descripcion=`Endpoint de productos`
3. Editar: cambiar Descripcion a `Endpoint CRUD de productos`
4. Eliminar el registro

### 7.4.6 Probar Usuario

1. Click en **Usuario** en el menu
2. Crear: Email=`admin@test.com`, Contrasena=`123456`, marcar checkbox **Encriptar contrasena**
3. Verificar que la contrasena se muestra como hash (texto largo que empieza con `$2a$`)
4. Editar: cambiar Contrasena a `nueva123`
5. Eliminar el registro

### 7.4.7 Probar Limite

1. En cualquier tabla, escribir `3` en el campo Limite
2. Click en **Cargar**
3. Verificar que la tabla muestra maximo 3 registros

---

## 7.5 Posibles Errores y Soluciones

### Error: "No se encontraron registros" (cuando si deberia haber)

- **Causa:** La API no esta corriendo o esta en otro puerto
- **Solucion:** Verificar que la terminal de la API muestre `Now listening on: http://localhost:5034`
- **Solucion:** Verificar que `API_BASE_URL` en `config.py` sea `http://localhost:5034`

### Error: La pagina muestra un error 500 de Flask

- **Causa:** Error en el codigo Python (ruta, template o servicio)
- **Solucion:** Revisar la terminal de Flask — con `debug=True` muestra el traceback completo
- **Solucion:** Verificar que todos los Blueprints estan registrados en `app.py`

### Error: "Connection refused" en la consola de Flask

- **Causa:** La API no esta corriendo
- **Solucion:** Iniciar la API con `dotnet run` en el proyecto ApiGenericaCsharp

### Error: "405 Method Not Allowed"

- **Causa:** Se esta haciendo GET a una ruta que solo acepta POST, o viceversa
- **Solucion:** Verificar que los formularios usen `method="POST"` y las rutas tengan `methods=['POST']`

### Error: El CSS no carga (pagina sin estilos)

- **Causa:** La carpeta `static/css/` no existe o el archivo no esta
- **Solucion:** Verificar que `http://localhost:5100/static/css/app.css` responde
- **Solucion:** Limpiar cache del navegador con `Ctrl + Shift + R`

---

## 7.6 Resumen del Proyecto Completo

### Estructura de Archivos

```
FrontFlask_AppiGenericaCsharp/
├── app.py                          ← Punto de entrada + registro de Blueprints
├── config.py                       ← URL de la API + clave secreta
├── requirements.txt                ← Flask + requests
├── services/
│   ├── __init__.py
│   └── api_service.py              ← Servicio generico CRUD
├── routes/
│   ├── __init__.py
│   ├── home.py                     ← GET /
│   ├── empresa.py                  ← CRUD /empresa
│   ├── persona.py                  ← CRUD /persona
│   ├── producto.py                 ← CRUD /producto
│   ├── rol.py                      ← CRUD /rol
│   ├── ruta.py                     ← CRUD /ruta
│   └── usuario.py                  ← CRUD /usuario
├── templates/
│   ├── layout/
│   │   └── base.html               ← Plantilla base (sidebar + topbar + flash)
│   ├── components/
│   │   └── nav_menu.html           ← Menu lateral con 7 links
│   └── pages/
│       ├── home.html
│       ├── empresa.html
│       ├── persona.html
│       ├── producto.html
│       ├── rol.html
│       ├── ruta.html
│       └── usuario.html
├── static/css/
│   └── app.css                     ← Estilos del layout
├── Parte1_ConceptosFundamentales.md
├── Parte2_CrearProyectoYConfiguracion.md
├── Parte3_ApiService.md
├── Parte4_LayoutYNavegacion.md
├── Parte5_CrudProducto.md
├── Parte6_CrudDemasTablas.md
├── Parte7_VerificacionFinal.md     ← Este archivo
└── README.md
```

### Resumen por Parte

| Parte | Que Hicimos |
|---|---|
| 1 | Conceptos fundamentales de Flask, Jinja2, formularios, flash |
| 2 | Crear proyecto, instalar dependencias, configurar puerto 5100, git init |
| 3 | ApiService: servicio generico con listar, crear, actualizar, eliminar |
| 4 | Layout Jinja2: base.html, nav_menu.html, home.html, CSS |
| 5 | CRUD completo de Producto (patron base) |
| 6 | CRUD de las 5 tablas restantes (Empresa, Persona, Rol, Ruta, Usuario) |
| 7 | Verificacion final: correr API + frontend, probar todo |

### Las 6 Tablas

| Tabla | Campos | Clave Primaria | Tipo PK |
|---|---|---|---|
| empresa | codigo, nombre | codigo | string |
| persona | codigo, nombre, email, telefono | codigo | string |
| producto | codigo, nombre, stock, valorunitario | codigo | string |
| rol | id, nombre | id | int |
| ruta | ruta, descripcion | ruta | string |
| usuario | email, contrasena | email | string |

### Tecnologias Utilizadas

- **Flask 3.1** como framework web
- **Jinja2** como motor de templates
- **requests** para consumir la API REST
- **Bootstrap 5** (CDN) para estilos
- **ApiService** generico usando diccionarios Python
- **API GenericaCsharp** como backend (CRUD generico por nombre de tabla)

---

## 7.7 Que Sigue (Ideas para Mejorar)

Este tutorial cubre un CRUD basico funcional. Algunas mejoras posibles para el futuro:

1. **Validacion de formularios:** Agregar validacion con Flask-WTF o validacion HTML5
2. **Tablas con FK:** Crear paginas para tablas con relaciones (dropdown para seleccionar la FK)
3. **Autenticacion:** Implementar login con JWT usando la tabla `usuario` y Flask-Login
4. **Paginacion:** Para tablas con muchos registros, implementar paginacion real
5. **Busqueda/filtrado:** Agregar un campo para filtrar registros en la tabla
6. **CSS mejorado:** Agregar animaciones, temas oscuros o usar un framework CSS diferente
7. **Deploy:** Publicar en un servidor con Gunicorn + Nginx o en plataformas como Railway/Render

---

## 7.8 Commit Final

```bash
git add .
git commit -m "Agregar Parte 7: verificacion final y resumen del proyecto"
```

Con esto completamos el tutorial. El proyecto esta funcionando y listo para publicar.
