"""
factura.py - Blueprint con las rutas CRUD para Facturas y Productos por Factura.

Usa los stored procedures de PostgreSQL a traves de la API:
    - sp_listar_facturas_y_productosporfactura
    - sp_consultar_factura_y_productosporfactura
    - sp_insertar_factura_y_productosporfactura
    - sp_actualizar_factura_y_productosporfactura
    - sp_borrar_factura_y_productosporfactura

Endpoint API: POST /api/procedimientos/ejecutarsp

Rutas:
    GET  /factura                →  Listar facturas
    GET  /factura/ver/<numero>   →  Ver detalle de una factura
    GET  /factura/nueva          →  Formulario nueva factura
    POST /factura/crear          →  Crear factura con productos
    GET  /factura/editar/<numero>→  Formulario editar factura
    POST /factura/actualizar     →  Actualizar factura con productos
    POST /factura/eliminar       →  Eliminar factura (cascade)
"""

import json
from flask import Blueprint, render_template, request, redirect, url_for, flash
from services.api_service import ApiService


# ══════════════════════════════════════════════
# CONFIGURACION DEL BLUEPRINT
# ══════════════════════════════════════════════

bp = Blueprint('factura', __name__)
api = ApiService()


# ══════════════════════════════════════════════
# LISTAR FACTURAS (GET)
# ══════════════════════════════════════════════

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


# ══════════════════════════════════════════════
# VER DETALLE DE FACTURA (GET)
# ══════════════════════════════════════════════

@bp.route('/factura/ver/<int:numero>')
def ver(numero):
    """Muestra el detalle de una factura con sus productos."""
    exito, datos = api.ejecutar_sp("sp_consultar_factura_y_productosporfactura", {
        "p_numero": numero,
        "p_resultado": None
    })

    factura = None
    if exito and isinstance(datos, dict):
        # SP retorna {factura: {...}, productos: [...]}
        info = datos.get("factura", datos)
        info["productos"] = datos.get("productos", [])
        factura = info

    return render_template('pages/factura.html',
        factura=factura,
        vista='ver'
    )


# ══════════════════════════════════════════════
# FORMULARIO NUEVA FACTURA (GET)
# ══════════════════════════════════════════════

@bp.route('/factura/nueva')
def nueva():
    """Muestra el formulario para crear una factura."""
    # Cargar clientes, vendedores, personas y productos para los selects
    clientes = api.listar('cliente')
    vendedores = api.listar('vendedor')
    personas = api.listar('persona')
    productos = api.listar('producto')

    # Cruzar cliente/vendedor con persona para obtener el nombre
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


# ══════════════════════════════════════════════
# CREAR FACTURA (POST)
# ══════════════════════════════════════════════

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


# ══════════════════════════════════════════════
# FORMULARIO EDITAR FACTURA (GET)
# ══════════════════════════════════════════════

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
        # SP retorna {factura: {...}, productos: [...]}
        info = datos.get("factura", datos)
        info["productos"] = datos.get("productos", [])
        factura = info

    if not factura:
        flash("Factura no encontrada.", "danger")
        return redirect(url_for('factura.index'))

    # Cargar clientes, vendedores, personas y productos para los selects
    clientes = api.listar('cliente')
    vendedores = api.listar('vendedor')
    personas = api.listar('persona')
    productos = api.listar('producto')

    # Cruzar cliente/vendedor con persona para obtener el nombre
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


# ══════════════════════════════════════════════
# ACTUALIZAR FACTURA (POST)
# ══════════════════════════════════════════════

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


# ══════════════════════════════════════════════
# ELIMINAR FACTURA (POST)
# ══════════════════════════════════════════════

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
