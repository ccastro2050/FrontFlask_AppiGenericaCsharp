"""
api_service.py - Servicio generico que consume la API REST.

Contiene los 4 metodos CRUD (Listar, Crear, Actualizar, Eliminar)
que se reutilizan en todos los Blueprints/rutas.
Cada metodo retorna los datos o una tupla (exito, mensaje).
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
        # URL base de la API, definida en config.py
        self.base_url = API_BASE_URL

    # ──────────────────────────────────────────────
    # LISTAR: GET /api/{tabla}
    # Obtiene todos los registros de una tabla.
    # Opcionalmente limita la cantidad con ?limite=N
    # ──────────────────────────────────────────────
    def listar(self, tabla, limite=None):
        """
        Consulta la API y retorna la lista de registros.

        Args:
            tabla:  nombre de la tabla (ej: 'empresa')
            limite: cantidad maxima de registros (opcional)

        Returns:
            Lista de diccionarios con los datos, o lista vacia si hay error.
        """
        try:
            url = f"{self.base_url}/api/{tabla}"

            # Agregar parametro de limite si fue proporcionado
            params = {}
            if limite:
                params['limite'] = limite

            respuesta = requests.get(url, params=params)
            datos_json = respuesta.json()

            # La API retorna: { "datos": [...], "mensaje": "..." }
            # Extraemos solo la lista de "datos"
            return datos_json.get("datos", [])

        except requests.RequestException as ex:
            print(f"Error al listar {tabla}: {ex}")
            return []

    # ──────────────────────────────────────────────
    # CREAR: POST /api/{tabla}
    # Envia los datos del formulario como JSON.
    # Retorna una tupla (exito, mensaje).
    # ──────────────────────────────────────────────
    def crear(self, tabla, datos, campos_encriptar=None):
        """
        Crea un nuevo registro en la tabla.

        Args:
            tabla:             nombre de la tabla
            datos:             diccionario con los campos del registro
            campos_encriptar:  nombre del campo a encriptar (opcional)

        Returns:
            Tupla (exito: bool, mensaje: str)
        """
        try:
            url = f"{self.base_url}/api/{tabla}"

            # Si hay campos a encriptar, se pasa como query param
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
    # Envia los campos a modificar como JSON.
    # La clave primaria va en la URL, no en el cuerpo.
    # ──────────────────────────────────────────────
    def actualizar(self, tabla, nombre_clave, valor_clave, datos, campos_encriptar=None):
        """
        Actualiza un registro existente.

        Args:
            tabla:             nombre de la tabla
            nombre_clave:      nombre del campo clave (ej: 'codigo')
            valor_clave:       valor de la clave del registro a actualizar
            datos:             diccionario con los campos a modificar
            campos_encriptar:  nombre del campo a encriptar (opcional)

        Returns:
            Tupla (exito: bool, mensaje: str)
        """
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
    # Solo necesita la clave primaria para identificar el registro.
    # ──────────────────────────────────────────────
    def eliminar(self, tabla, nombre_clave, valor_clave):
        """
        Elimina un registro de la tabla.

        Args:
            tabla:        nombre de la tabla
            nombre_clave: nombre del campo clave (ej: 'codigo')
            valor_clave:  valor de la clave del registro a eliminar

        Returns:
            Tupla (exito: bool, mensaje: str)
        """
        try:
            url = f"{self.base_url}/api/{tabla}/{nombre_clave}/{valor_clave}"

            respuesta = requests.delete(url)
            contenido = respuesta.json()

            mensaje = contenido.get("mensaje", "Operacion completada.")
            return (respuesta.ok, mensaje)

        except requests.RequestException as ex:
            return (False, f"Error de conexion: {ex}")
