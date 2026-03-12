# Guia de Uso: ProcedimientosController desde Flask

Esta guia explica como consumir el endpoint de procedimientos almacenados de la API C# desde el frontend Flask, usando como ejemplo los 5 SPs de facturas.

- **API C#:** `http://localhost:5035`
- **Flask:** `http://localhost:5100`

---

## 1. Vision General del Endpoint

La API expone un unico endpoint generico para ejecutar cualquier stored procedure o funcion de PostgreSQL:

```
POST http://localhost:5035/api/procedimientos/ejecutarsp
Content-Type: application/json
```

El controlador `ProcedimientosController` recibe un JSON con el nombre del SP y sus parametros. Internamente:

1. Extrae `nombreSP` del body
2. Separa los demas campos como parametros del SP
3. Ejecuta el SP via `IServicioConsultas.EjecutarProcedimientoAlmacenadoAsync`
4. Convierte el `DataTable` resultante a una lista de diccionarios
5. Retorna la respuesta en formato JSON

**Respuesta exitosa (200):**
```json
{
    "procedimiento": "nombre_del_sp",
    "resultados": [
        {
            "p_resultado": "{\"facturas\": [...]}"
        }
    ],
    "total": 1,
    "mensaje": "Procedimiento ejecutado correctamente"
}
```

**Respuesta de error (400):**
```json
{
    "estado": 400,
    "mensaje": "Parametros de entrada invalidos.",
    "detalle": "Descripcion del error"
}
```

**Respuesta de error (500):**
```json
{
    "estado": 500,
    "mensaje": "Error interno del servidor al ejecutar procedimiento almacenado.",
    "tipoError": "NombreDelError",
    "detalle": "Mensaje del error",
    "errorInterno": "Mensaje del error interno (si existe)",
    "sugerencia": "Revise los logs del servidor para mas detalles o contacte al administrador."
}
```

---

## 2. Como Funciona ejecutar_sp en Flask

El metodo `ejecutar_sp` de `services/api_service.py` encapsula toda la logica de comunicacion con el endpoint:

```python
def ejecutar_sp(self, nombre_sp, parametros=None):
    """
    Ejecuta un stored procedure via la API.

    Args:
        nombre_sp:   nombre del procedimiento (str)
        parametros:  diccionario con los parametros del SP (sin nombreSP)

    Returns:
        Tupla (exito: bool, datos_o_mensaje)
    """
    try:
        import json as json_mod
        url = f"{self.base_url}/api/procedimientos/ejecutarsp"

        # 1. Construir el payload: nombreSP + parametros
        payload = {"nombreSP": nombre_sp}
        if parametros:
            payload.update(parametros)

        # 2. POST al endpoint
        respuesta = requests.post(url, json=payload)
        contenido = respuesta.json()

        # 3. Si hubo error HTTP, retornar (False, mensaje)
        if not respuesta.ok:
            mensaje = contenido.get("mensaje", "Error al ejecutar el procedimiento.")
            return (False, mensaje)

        # 4. Extraer p_resultado de resultados[0]
        resultados = contenido.get("resultados", [])
        if resultados and "p_resultado" in resultados[0]:
            p_resultado = resultados[0]["p_resultado"]
            # 5. Si es string JSON, parsearlo a dict/list de Python
            if isinstance(p_resultado, str):
                return (True, json_mod.loads(p_resultado))
            return (True, p_resultado)

        return (True, contenido)

    except requests.RequestException as ex:
        return (False, f"Error de conexion: {ex}")
    except Exception as ex:
        return (False, f"Error procesando respuesta: {ex}")
```

### Flujo paso a paso

```
Flask (factura.py)                  api_service.py                     API C#
       |                                  |                               |
       |-- ejecutar_sp("sp_xxx", {...}) ->|                               |
       |                                  |-- POST /ejecutarsp  --------->|
       |                                  |   payload: {nombreSP, ...}    |
       |                                  |                               |-- Ejecuta SP
       |                                  |                               |-- DataTable -> JSON
       |                                  |<--- 200 OK -------------------|
       |                                  |   {resultados: [{p_resultado}]}
       |                                  |-- json.loads(p_resultado)     |
       |<-- (True, datos_parseados) ------|                               |
```

**Punto clave:** El SP retorna su resultado en el parametro `p_resultado` como un string JSON. El metodo `ejecutar_sp` lo parsea automaticamente a un diccionario o lista de Python.

---

## 3. Como se Llama Cada SP desde Flask (factura.py)

El archivo `routes/factura.py` es el Blueprint que maneja las rutas de facturas. Cada ruta usa `api.ejecutar_sp()` para comunicarse con la API.

### 3.1 Listar todas las facturas

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

**Payload que se envia a la API:**
```json
{
    "nombreSP": "sp_listar_facturas_y_productosporfactura",
    "p_resultado": null
}
```

### 3.2 Consultar una factura por numero

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

**Payload que se envia a la API:**
```json
{
    "nombreSP": "sp_consultar_factura_y_productosporfactura",
    "p_numero": 1,
    "p_resultado": null
}
```

### 3.3 Crear factura con productos

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

    # Llamar al SP
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

**Payload que se envia a la API:**
```json
{
    "nombreSP": "sp_insertar_factura_y_productosporfactura",
    "p_fkidcliente": 1,
    "p_fkidvendedor": 2,
    "p_productos": "[{\"codigo\":\"PR001\",\"cantidad\":2},{\"codigo\":\"PR003\",\"cantidad\":5}]",
    "p_resultado": null
}
```

**Nota:** `p_productos` es un string JSON, no un array directamente. Se genera con `json.dumps(productos_lista)`.

### 3.4 Actualizar factura con productos

```python
@bp.route('/factura/actualizar', methods=['POST'])
def actualizar():
    """Actualiza una factura existente con sus productos."""
    numero = request.form.get('numero', 0, type=int)
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
        return redirect(url_for('factura.editar', numero=numero))

    # Llamar al SP
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

**Payload que se envia a la API:**
```json
{
    "nombreSP": "sp_actualizar_factura_y_productosporfactura",
    "p_numero": 1,
    "p_fkidcliente": 1,
    "p_fkidvendedor": 2,
    "p_productos": "[{\"codigo\":\"PR001\",\"cantidad\":3},{\"codigo\":\"PR002\",\"cantidad\":1}]",
    "p_resultado": null
}
```

### 3.5 Eliminar factura

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

**Payload que se envia a la API:**
```json
{
    "nombreSP": "sp_borrar_factura_y_productosporfactura",
    "p_numero": 1,
    "p_resultado": null
}
```

---

## 4. Ejemplos en Swagger y Postman

### 4.1 Swagger (interfaz web)

La API tiene Swagger disponible en: `http://localhost:5035/swagger`

Para probar desde Swagger:

1. Abrir `http://localhost:5035/swagger` en el navegador
2. Buscar el endpoint `POST /api/procedimientos/ejecutarsp`
3. Click en "Try it out"
4. Pegar el JSON en el campo "Request body"
5. Click en "Execute"

### 4.2 Postman - Los 5 SPs

Para todos los ejemplos:
- **Method:** POST
- **URL:** `http://localhost:5035/api/procedimientos/ejecutarsp`
- **Headers:** `Content-Type: application/json`
- **Body:** raw > JSON

#### SP 1: Listar facturas

```json
{
    "nombreSP": "sp_listar_facturas_y_productosporfactura",
    "p_resultado": null
}
```

#### SP 2: Consultar factura por numero

```json
{
    "nombreSP": "sp_consultar_factura_y_productosporfactura",
    "p_numero": 1,
    "p_resultado": null
}
```

#### SP 3: Insertar factura con productos

```json
{
    "nombreSP": "sp_insertar_factura_y_productosporfactura",
    "p_fkidcliente": 1,
    "p_fkidvendedor": 2,
    "p_productos": "[{\"codigo\":\"PR001\",\"cantidad\":2},{\"codigo\":\"PR003\",\"cantidad\":5}]",
    "p_resultado": null
}
```

#### SP 4: Actualizar factura con productos

```json
{
    "nombreSP": "sp_actualizar_factura_y_productosporfactura",
    "p_numero": 1,
    "p_fkidcliente": 1,
    "p_fkidvendedor": 2,
    "p_productos": "[{\"codigo\":\"PR001\",\"cantidad\":3},{\"codigo\":\"PR002\",\"cantidad\":1}]",
    "p_resultado": null
}
```

#### SP 5: Eliminar factura

```json
{
    "nombreSP": "sp_borrar_factura_y_productosporfactura",
    "p_numero": 1,
    "p_resultado": null
}
```

---

## 5. El Parametro p_minimo_detalle

El parametro `p_minimo_detalle` controla la cantidad minima de productos que debe tener una factura. Solo aplica a los SPs de insertar y actualizar.

### Como funciona internamente

El SP usa esta logica en PostgreSQL:

```sql
COALESCE(NULLIF(p_minimo_detalle, 0), 1)
```

Esto significa:

1. `NULLIF(p_minimo_detalle, 0)` -- Si el valor es 0, lo convierte a NULL
2. `COALESCE(..., 1)` -- Si es NULL, usa 1 como valor por defecto

### Por que se usa NULLIF con 0

Cuando la API C# recibe un parametro entero que no fue enviado en el JSON, lo deserializa como `0` (valor por defecto de `int`). Por eso el SP trata `0` como "no enviado" y aplica el valor por defecto de `1`.

### Ejemplo: Exigir minimo 3 productos por factura

```json
{
    "nombreSP": "sp_insertar_factura_y_productosporfactura",
    "p_fkidcliente": 1,
    "p_fkidvendedor": 2,
    "p_productos": "[{\"codigo\":\"PR001\",\"cantidad\":2},{\"codigo\":\"PR002\",\"cantidad\":1},{\"codigo\":\"PR003\",\"cantidad\":3}]",
    "p_minimo_detalle": 3,
    "p_resultado": null
}
```

### Ejemplo: Usar el valor por defecto (minimo 1 producto)

Cualquiera de estas formas es equivalente. No enviar el parametro:

```json
{
    "nombreSP": "sp_insertar_factura_y_productosporfactura",
    "p_fkidcliente": 1,
    "p_fkidvendedor": 2,
    "p_productos": "[{\"codigo\":\"PR001\",\"cantidad\":2}]",
    "p_resultado": null
}
```

O enviar 0 (se trata como "no enviado"):

```json
{
    "nombreSP": "sp_insertar_factura_y_productosporfactura",
    "p_fkidcliente": 1,
    "p_fkidvendedor": 2,
    "p_productos": "[{\"codigo\":\"PR001\",\"cantidad\":2}]",
    "p_minimo_detalle": 0,
    "p_resultado": null
}
```

En ambos casos el SP exigira al menos 1 producto.

### Tabla resumen

| Valor enviado      | Valor que usa el SP | Efecto                          |
|--------------------|---------------------|---------------------------------|
| No se envia        | 1                   | Minimo 1 producto (por defecto) |
| 0                  | 1                   | Minimo 1 producto (por defecto) |
| 1                  | 1                   | Minimo 1 producto               |
| 3                  | 3                   | Minimo 3 productos              |
| null               | 1                   | Minimo 1 producto (por defecto) |

---

## 6. Formato de Respuesta y Como Parsear p_resultado

### Respuesta cruda de la API

Cuando la API ejecuta un SP exitosamente, retorna:

```json
{
    "procedimiento": "sp_listar_facturas_y_productosporfactura",
    "resultados": [
        {
            "p_resultado": "{\"facturas\": [{\"numero\": 1, \"fecha\": \"2025-01-15\", \"fkidcliente\": 1, \"fkidvendedor\": 2, \"productos\": [{\"codigo\": \"PR001\", \"nombre\": \"Laptop\", \"cantidad\": 2, \"valorunitario\": 2500000}]}]}"
        }
    ],
    "total": 1,
    "mensaje": "Procedimiento ejecutado correctamente"
}
```

Observar que `p_resultado` es un **string JSON dentro de otro JSON**. Es decir, hay dos niveles de serializacion.

### Como lo parsea ejecutar_sp

```python
# 1. La API retorna el JSON exterior (requests lo parsea automaticamente)
contenido = respuesta.json()
# contenido = {"procedimiento": "...", "resultados": [...], ...}

# 2. Extraer la lista de resultados
resultados = contenido.get("resultados", [])
# resultados = [{"p_resultado": "{\"facturas\": [...]}"}]

# 3. Obtener p_resultado del primer resultado
p_resultado = resultados[0]["p_resultado"]
# p_resultado = '{"facturas": [...]}'  <-- es un STRING

# 4. Parsear ese string JSON a un diccionario Python
datos = json.loads(p_resultado)
# datos = {"facturas": [...]}  <-- ahora es un DICT
```

### Estructura de datos ya parseados por SP

**sp_listar_facturas_y_productosporfactura:**
```python
{
    "facturas": [
        {
            "numero": 1,
            "fecha": "2025-01-15",
            "fkidcliente": 1,
            "fkidvendedor": 2,
            "productos": [
                {"codigo": "PR001", "nombre": "Laptop", "cantidad": 2, "valorunitario": 2500000}
            ]
        }
    ]
}
```

**sp_consultar_factura_y_productosporfactura:**
```python
{
    "factura": {
        "numero": 1,
        "fecha": "2025-01-15",
        "fkidcliente": 1,
        "fkidvendedor": 2
    },
    "productos": [
        {"codigo": "PR001", "nombre": "Laptop", "cantidad": 2, "valorunitario": 2500000}
    ]
}
```

**sp_insertar / sp_actualizar / sp_borrar:**
```python
{
    "mensaje": "Factura creada/actualizada/eliminada exitosamente",
    "numero": 1
}
```

---

## 7. Validacion de Stock (Trigger en PostgreSQL)

La base de datos tiene un **trigger** que valida el stock antes de insertar o actualizar productos de una factura.

### Como funciona

1. Cuando el SP inserta/actualiza registros en la tabla de productos por factura, el trigger se dispara
2. El trigger consulta el stock disponible del producto en la tabla `producto`
3. Si la cantidad solicitada es mayor al stock disponible, el trigger lanza un error

### Mensaje de error

```
Stock insuficiente para producto PRXXX
```

Donde `PRXXX` es el codigo del producto que no tiene stock suficiente.

### Como se ve el error en Flask

Cuando el trigger lanza el error, la API lo captura y retorna un 500. El metodo `ejecutar_sp` retorna `(False, mensaje_de_error)` y el Blueprint muestra la alerta:

```python
exito, datos = api.ejecutar_sp("sp_insertar_factura_y_productosporfactura", {...})

if exito:
    flash("Factura creada exitosamente.", "success")
else:
    # datos contiene: "Error interno del servidor al ejecutar procedimiento almacenado."
    # o el mensaje especifico del trigger
    flash(f"Error al crear factura: {datos}", "danger")
```

### Ejemplo practico

Si el producto `PR001` tiene stock = 10 y se intenta crear una factura con cantidad = 15:

```json
{
    "nombreSP": "sp_insertar_factura_y_productosporfactura",
    "p_fkidcliente": 1,
    "p_fkidvendedor": 2,
    "p_productos": "[{\"codigo\":\"PR001\",\"cantidad\":15}]",
    "p_resultado": null
}
```

La API retornara algo como:

```json
{
    "estado": 500,
    "mensaje": "Error interno del servidor al ejecutar procedimiento almacenado.",
    "detalle": "Stock insuficiente para producto PR001"
}
```

---

## 8. Errores Comunes y Soluciones

### Error: "El parametro 'nombreSP' es requerido."

**Causa:** El JSON no incluye el campo `nombreSP` o su valor es null.

**Solucion:** Verificar que el payload incluya `"nombreSP": "nombre_del_sp"`.

```json
// MAL - falta nombreSP
{
    "p_resultado": null
}

// BIEN
{
    "nombreSP": "sp_listar_facturas_y_productosporfactura",
    "p_resultado": null
}
```

---

### Error: SP no existe (400 Bad Request)

**Causa:** El nombre del SP esta mal escrito o no existe en la base de datos.

**Solucion:** Verificar que el nombre sea exacto. Los nombres son case-sensitive en PostgreSQL.

```json
// MAL
{"nombreSP": "sp_listar_facturas"}

// BIEN
{"nombreSP": "sp_listar_facturas_y_productosporfactura"}
```

---

### Error: "Stock insuficiente para producto PRXXX"

**Causa:** La cantidad solicitada supera el stock disponible del producto.

**Solucion:**
1. Verificar el stock actual del producto en la tabla `producto`
2. Reducir la cantidad en `p_productos`
3. O aumentar el stock del producto antes de crear la factura

---

### Error: Factura no encontrada (update/delete)

**Causa:** Se intenta actualizar o eliminar una factura con un numero que no existe.

**Solucion:** Verificar que el `p_numero` corresponda a una factura existente.

---

### Error: "Debe agregar al menos un producto"

**Causa:** El SP valida que la cantidad de productos sea >= `p_minimo_detalle`. Si se envia una lista vacia o con menos productos de los requeridos, el SP rechaza la operacion.

**Solucion:** Enviar al menos la cantidad minima de productos. Si no se especifica `p_minimo_detalle`, el minimo es 1.

---

### Error: p_productos con formato incorrecto

**Causa:** El string JSON de productos esta mal formado.

**Solucion:** Verificar que sea un JSON valido con la estructura correcta:

```json
// MAL - no es string JSON valido
"p_productos": "[{codigo:PR001}]"

// MAL - es un array, no un string
"p_productos": [{"codigo": "PR001", "cantidad": 2}]

// BIEN - string JSON con escape correcto
"p_productos": "[{\"codigo\":\"PR001\",\"cantidad\":2}]"
```

En Python, usar `json.dumps()` para generar el string:
```python
import json
productos = [{"codigo": "PR001", "cantidad": 2}, {"codigo": "PR003", "cantidad": 5}]
p_productos = json.dumps(productos)
# Resultado: '[{"codigo": "PR001", "cantidad": 2}, {"codigo": "PR003", "cantidad": 5}]'
```

---

### Error: "Error de conexion"

**Causa:** La API C# no esta corriendo o no es accesible desde Flask.

**Solucion:**
1. Verificar que la API este corriendo en `http://localhost:5035`
2. Verificar que `config.py` tenga la URL correcta: `API_BASE_URL = "http://localhost:5035"`
3. Verificar que no haya un firewall bloqueando la conexion

---

## 9. Ejemplos con curl

### Listar todas las facturas

```bash
curl -X POST http://localhost:5035/api/procedimientos/ejecutarsp \
  -H "Content-Type: application/json" \
  -d '{
    "nombreSP": "sp_listar_facturas_y_productosporfactura",
    "p_resultado": null
  }'
```

### Consultar factura numero 1

```bash
curl -X POST http://localhost:5035/api/procedimientos/ejecutarsp \
  -H "Content-Type: application/json" \
  -d '{
    "nombreSP": "sp_consultar_factura_y_productosporfactura",
    "p_numero": 1,
    "p_resultado": null
  }'
```

### Crear factura con 2 productos

```bash
curl -X POST http://localhost:5035/api/procedimientos/ejecutarsp \
  -H "Content-Type: application/json" \
  -d '{
    "nombreSP": "sp_insertar_factura_y_productosporfactura",
    "p_fkidcliente": 1,
    "p_fkidvendedor": 2,
    "p_productos": "[{\"codigo\":\"PR001\",\"cantidad\":2},{\"codigo\":\"PR003\",\"cantidad\":5}]",
    "p_resultado": null
  }'
```

### Crear factura con minimo 3 productos

```bash
curl -X POST http://localhost:5035/api/procedimientos/ejecutarsp \
  -H "Content-Type: application/json" \
  -d '{
    "nombreSP": "sp_insertar_factura_y_productosporfactura",
    "p_fkidcliente": 1,
    "p_fkidvendedor": 2,
    "p_productos": "[{\"codigo\":\"PR001\",\"cantidad\":2},{\"codigo\":\"PR002\",\"cantidad\":1},{\"codigo\":\"PR003\",\"cantidad\":3}]",
    "p_minimo_detalle": 3,
    "p_resultado": null
  }'
```

### Actualizar factura numero 1

```bash
curl -X POST http://localhost:5035/api/procedimientos/ejecutarsp \
  -H "Content-Type: application/json" \
  -d '{
    "nombreSP": "sp_actualizar_factura_y_productosporfactura",
    "p_numero": 1,
    "p_fkidcliente": 1,
    "p_fkidvendedor": 2,
    "p_productos": "[{\"codigo\":\"PR001\",\"cantidad\":3},{\"codigo\":\"PR002\",\"cantidad\":1}]",
    "p_resultado": null
  }'
```

### Eliminar factura numero 1

```bash
curl -X POST http://localhost:5035/api/procedimientos/ejecutarsp \
  -H "Content-Type: application/json" \
  -d '{
    "nombreSP": "sp_borrar_factura_y_productosporfactura",
    "p_numero": 1,
    "p_resultado": null
  }'
```

### Ejemplo con respuesta formateada (usando jq)

```bash
curl -s -X POST http://localhost:5035/api/procedimientos/ejecutarsp \
  -H "Content-Type: application/json" \
  -d '{
    "nombreSP": "sp_listar_facturas_y_productosporfactura",
    "p_resultado": null
  }' | jq .
```

### Ejemplo desde Windows (PowerShell)

En PowerShell las comillas se manejan diferente:

```powershell
$body = @{
    nombreSP = "sp_listar_facturas_y_productosporfactura"
    p_resultado = $null
} | ConvertTo-Json

Invoke-RestMethod -Uri "http://localhost:5035/api/procedimientos/ejecutarsp" -Method POST -Body $body -ContentType "application/json"
```

---

Autor: Carlos Arturo Castro Castro
