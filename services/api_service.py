"""
api_service.py - Servicio generico que consume la API REST.

Contiene los 4 metodos CRUD (Listar, Crear, Actualizar, Eliminar)
que se reutilizan en todos los Blueprints/rutas.
Cada metodo retorna los datos o una tupla (exito, mensaje).
"""

# requests: libreria de Python para hacer peticiones HTTP (GET, POST, PUT, DELETE)
import requests

# API_BASE_URL: URL base de la API, importada desde config.py (ej: "http://localhost:5034")
from config import API_BASE_URL


# Clase que encapsula las 4 operaciones CRUD contra la API REST.
# Se instancia en cada Blueprint con: api = ApiService()
class ApiService:
    """
    Servicio generico para consumir la API REST.

    Metodos:
        listar(tabla, limite)           → lista de diccionarios
        crear(tabla, datos, ...)        → (bool, str)
        actualizar(tabla, clave, ...)   → (bool, str)
        eliminar(tabla, clave, valor)   → (bool, str)
    """

    # Constructor: se ejecuta al crear una instancia con ApiService()
    def __init__(self):
        # Guarda la URL base como atributo de la instancia para usarla en todos los metodos
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
            # Construir la URL del endpoint: ej → "http://localhost:5034/api/empresa"
            url = f"{self.base_url}/api/{tabla}"

            # Diccionario para los query params de la URL (ej: ?limite=5)
            params = {}
            # Solo agregar el parametro limite si el usuario lo proporciono
            if limite:
                params['limite'] = limite

            # requests.get() hace una peticion HTTP GET a la URL indicada
            # params se agrega automaticamente como query string (ej: ?limite=5)
            respuesta = requests.get(url, params=params)

            # .json() convierte el cuerpo de la respuesta de texto JSON a diccionario Python
            datos_json = respuesta.json()

            # La API retorna: { "datos": [...], "mensaje": "..." }
            # .get("datos", []) extrae la lista; si no existe la clave, retorna lista vacia
            return datos_json.get("datos", [])

        # RequestException: captura cualquier error de conexion (timeout, DNS, servidor caido)
        except requests.RequestException as ex:
            # Imprimir el error en la consola del servidor para depuracion
            print(f"Error al listar {tabla}: {ex}")
            # Retornar lista vacia para que el template muestre "No se encontraron registros"
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
            campos_encriptar:  nombre del campo a encriptar (opcional, ej: 'contrasena')

        Returns:
            Tupla (exito: bool, mensaje: str)
        """
        try:
            # Construir la URL del endpoint: ej → "http://localhost:5034/api/usuario"
            url = f"{self.base_url}/api/{tabla}"

            # Diccionario para los query params opcionales
            params = {}
            # Si hay un campo a encriptar, agregarlo como parametro en la URL
            # La API recibe ?camposEncriptar=contrasena y encripta ese campo con bcrypt
            if campos_encriptar:
                params['camposEncriptar'] = campos_encriptar

            # requests.post() hace una peticion HTTP POST.
            # json=datos: convierte el diccionario Python a JSON y lo envia en el cuerpo.
            # params: agrega los query params a la URL si existen.
            respuesta = requests.post(url, json=datos, params=params)

            # Convertir la respuesta JSON a diccionario Python
            contenido = respuesta.json()

            # Extraer el mensaje de la respuesta (ej: "Registro creado exitosamente.")
            # Si no viene el campo "mensaje", usar un texto por defecto
            mensaje = contenido.get("mensaje", "Operacion completada.")

            # respuesta.ok es True si el codigo HTTP esta entre 200-299 (exito)
            # Retorna una tupla: (True/False, "texto del mensaje")
            return (respuesta.ok, mensaje)

        # Capturar errores de conexion (API apagada, timeout, error de red)
        except requests.RequestException as ex:
            # Retornar False y el texto del error para mostrarlo como alerta roja
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
            nombre_clave:      nombre del campo clave (ej: 'codigo', 'id', 'email')
            valor_clave:       valor de la clave del registro a actualizar (ej: 'PR001')
            datos:             diccionario con los campos a modificar
            campos_encriptar:  nombre del campo a encriptar (opcional)

        Returns:
            Tupla (exito: bool, mensaje: str)
        """
        try:
            # Construir la URL con la clave primaria en la ruta
            # Ejemplo: "http://localhost:5034/api/producto/codigo/PR001"
            url = f"{self.base_url}/api/{tabla}/{nombre_clave}/{valor_clave}"

            # Diccionario para query params opcionales (encriptacion)
            params = {}
            # Agregar parametro de encriptacion si fue solicitado
            if campos_encriptar:
                params['camposEncriptar'] = campos_encriptar

            # requests.put() hace una peticion HTTP PUT para modificar un recurso existente.
            # json=datos: envia solo los campos que cambiaron (sin la clave primaria).
            respuesta = requests.put(url, json=datos, params=params)

            # Convertir la respuesta JSON a diccionario Python
            contenido = respuesta.json()

            # Extraer el mensaje de la API (ej: "Registro actualizado exitosamente.")
            mensaje = contenido.get("mensaje", "Operacion completada.")

            # Retornar tupla (exito, mensaje) para que el Blueprint muestre la alerta
            return (respuesta.ok, mensaje)

        # Capturar errores de conexion
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
            valor_clave:  valor de la clave del registro a eliminar (ej: 'PR001')

        Returns:
            Tupla (exito: bool, mensaje: str)
        """
        try:
            # Construir la URL con la clave primaria
            # Ejemplo: "http://localhost:5034/api/empresa/codigo/E001"
            url = f"{self.base_url}/api/{tabla}/{nombre_clave}/{valor_clave}"

            # requests.delete() hace una peticion HTTP DELETE para borrar el recurso.
            # No necesita cuerpo JSON porque la clave ya va en la URL.
            respuesta = requests.delete(url)

            # Convertir la respuesta JSON a diccionario Python
            contenido = respuesta.json()

            # Extraer el mensaje de la API (ej: "Registro eliminado exitosamente.")
            mensaje = contenido.get("mensaje", "Operacion completada.")

            # Retornar tupla (exito, mensaje)
            return (respuesta.ok, mensaje)

        # Capturar errores de conexion
        except requests.RequestException as ex:
            return (False, f"Error de conexion: {ex}")
