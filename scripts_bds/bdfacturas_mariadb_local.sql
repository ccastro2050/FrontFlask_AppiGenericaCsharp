-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Servidor: 127.0.0.1
-- Tiempo de generación: 26-02-2026 a las 19:21:27
-- Versión del servidor: 10.4.32-MariaDB
-- Versión de PHP: 8.0.30

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Base de datos: `bdfacturas_mariadb_local`
--

DELIMITER $$
--
-- Procedimientos
--
CREATE DEFINER=`root`@`localhost` PROCEDURE `actualizar_factura_con_detalle` (IN `p_numfactura` INT, IN `p_fkidcliente` INT, IN `p_fkidvendedor` INT, IN `p_fecha` TIMESTAMP, IN `p_detalles` JSON)   BEGIN
    DECLARE v_count INT;
    DECLARE v_mensaje VARCHAR(255);
    DECLARE v_i INT DEFAULT 0;
    DECLARE v_length INT;
    DECLARE v_fkcodproducto VARCHAR(30);
    DECLARE v_cantidad INT;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    -- Validar que la factura existe
    SELECT COUNT(*) INTO v_count FROM factura WHERE numero = p_numfactura;
    IF v_count = 0 THEN
        SIGNAL SQLSTATE '45004' SET MESSAGE_TEXT = 'La factura especificada no existe';
    END IF;

    -- Validar que el cliente existe
    SELECT COUNT(*) INTO v_count FROM cliente WHERE id = p_fkidcliente;
    IF v_count = 0 THEN
        SIGNAL SQLSTATE '45001' SET MESSAGE_TEXT = 'El cliente especificado no existe';
    END IF;

    -- Validar que el vendedor existe
    SELECT COUNT(*) INTO v_count FROM vendedor WHERE id = p_fkidvendedor;
    IF v_count = 0 THEN
        SIGNAL SQLSTATE '45002' SET MESSAGE_TEXT = 'El vendedor especificado no existe';
    END IF;

    -- Actualizar factura
    UPDATE factura
    SET fkidcliente = p_fkidcliente,
        fkidvendedor = p_fkidvendedor,
        fecha = p_fecha
    WHERE numero = p_numfactura;

    -- Restaurar stock de productos antiguos
    UPDATE producto p
    INNER JOIN productosporfactura ppf ON p.codigo = ppf.fkcodproducto
    SET p.stock = p.stock + ppf.cantidad
    WHERE ppf.fknumfactura = p_numfactura;

    -- Eliminar detalles antiguos
    DELETE FROM productosporfactura WHERE fknumfactura = p_numfactura;

    -- Insertar nuevos detalles desde JSON usando bucle
    SET v_length = JSON_LENGTH(p_detalles);

    WHILE v_i < v_length DO
        SET v_fkcodproducto = JSON_UNQUOTE(JSON_EXTRACT(p_detalles, CONCAT('$[', v_i, '].fkcodproducto')));
        SET v_cantidad = JSON_EXTRACT(p_detalles, CONCAT('$[', v_i, '].cantidad'));

        INSERT INTO productosporfactura (fknumfactura, fkcodproducto, cantidad)
        VALUES (p_numfactura, v_fkcodproducto, v_cantidad);

        SET v_i = v_i + 1;
    END WHILE;

    -- Validar stock
    SELECT COUNT(*) INTO v_count
    FROM producto p
    INNER JOIN productosporfactura ppf ON p.codigo = ppf.fkcodproducto
    WHERE ppf.fknumfactura = p_numfactura AND p.stock < 0;

    IF v_count > 0 THEN
        SIGNAL SQLSTATE '45003' SET MESSAGE_TEXT = 'Stock insuficiente para uno o más productos';
    END IF;

    COMMIT;

    SET v_mensaje = CONCAT('Factura ', p_numfactura, ' actualizada exitosamente');
    SELECT v_mensaje AS Mensaje;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `actualizar_usuario_con_roles` (IN `p_email` VARCHAR(100), IN `p_contrasena` VARCHAR(100), IN `p_roles` JSON)   BEGIN
    DECLARE v_count INT;
    DECLARE v_i INT DEFAULT 0;
    DECLARE v_length INT;
    DECLARE v_fkidrol INT;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    -- Validar que el usuario existe
    SELECT COUNT(*) INTO v_count FROM usuario WHERE email = p_email;
    IF v_count = 0 THEN
        SIGNAL SQLSTATE '45006' SET MESSAGE_TEXT = 'El usuario no existe';
    END IF;

    -- Actualizar contraseña si se proporciona
    IF p_contrasena IS NOT NULL AND LENGTH(p_contrasena) > 0 THEN
        UPDATE usuario SET contrasena = p_contrasena WHERE email = p_email;
    END IF;

    -- Eliminar roles antiguos
    DELETE FROM rol_usuario WHERE fkemail = p_email;

    -- Insertar nuevos roles desde JSON usando bucle
    SET v_length = JSON_LENGTH(p_roles);

    WHILE v_i < v_length DO
        SET v_fkidrol = JSON_EXTRACT(p_roles, CONCAT('$[', v_i, '].fkidrol'));

        INSERT INTO rol_usuario (fkemail, fkidrol)
        VALUES (p_email, v_fkidrol);

        SET v_i = v_i + 1;
    END WHILE;

    COMMIT;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `crear_factura_con_detalle` (IN `p_fkidcliente` INT, IN `p_fkidvendedor` INT, IN `p_fecha` TIMESTAMP, IN `p_detalles` JSON)   BEGIN
    DECLARE v_numfactura INT;
    DECLARE v_count INT;
    DECLARE v_mensaje VARCHAR(255);
    DECLARE v_i INT DEFAULT 0;
    DECLARE v_length INT;
    DECLARE v_fkcodproducto VARCHAR(30);
    DECLARE v_cantidad INT;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    -- Validar que el cliente existe
    SELECT COUNT(*) INTO v_count FROM cliente WHERE id = p_fkidcliente;
    IF v_count = 0 THEN
        SIGNAL SQLSTATE '45001' SET MESSAGE_TEXT = 'El cliente especificado no existe';
    END IF;

    -- Validar que el vendedor existe
    SELECT COUNT(*) INTO v_count FROM vendedor WHERE id = p_fkidvendedor;
    IF v_count = 0 THEN
        SIGNAL SQLSTATE '45002' SET MESSAGE_TEXT = 'El vendedor especificado no existe';
    END IF;

    -- Insertar factura
    INSERT INTO factura (fkidcliente, fkidvendedor, fecha)
    VALUES (p_fkidcliente, p_fkidvendedor, p_fecha);

    SET v_numfactura = LAST_INSERT_ID();

    -- Insertar detalles desde JSON usando bucle
    SET v_length = JSON_LENGTH(p_detalles);

    WHILE v_i < v_length DO
        SET v_fkcodproducto = JSON_UNQUOTE(JSON_EXTRACT(p_detalles, CONCAT('$[', v_i, '].fkcodproducto')));
        SET v_cantidad = JSON_EXTRACT(p_detalles, CONCAT('$[', v_i, '].cantidad'));

        INSERT INTO productosporfactura (fknumfactura, fkcodproducto, cantidad)
        VALUES (v_numfactura, v_fkcodproducto, v_cantidad);

        SET v_i = v_i + 1;
    END WHILE;

    -- Validar stock
    SELECT COUNT(*) INTO v_count
    FROM producto p
    INNER JOIN productosporfactura ppf ON p.codigo = ppf.fkcodproducto
    WHERE ppf.fknumfactura = v_numfactura AND p.stock < 0;

    IF v_count > 0 THEN
        SIGNAL SQLSTATE '45003' SET MESSAGE_TEXT = 'Stock insuficiente para uno o más productos';
    END IF;

    COMMIT;

    SET v_mensaje = CONCAT('Factura ', v_numfactura, ' creada exitosamente');
    SELECT v_mensaje AS Mensaje;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `crear_rutarol` (IN `p_ruta` VARCHAR(100), IN `p_rol` VARCHAR(100))   BEGIN
    DECLARE v_count INT;

    -- Validar que el rol existe
    SELECT COUNT(*) INTO v_count FROM rol WHERE nombre = p_rol;
    IF v_count = 0 THEN
        SELECT JSON_OBJECT('success', 0, 'message', 'El rol especificado no existe') AS resultado;
    ELSE
        -- Validar que el permiso no existe
        SELECT COUNT(*) INTO v_count FROM rutarol WHERE ruta = p_ruta AND rol = p_rol;
        IF v_count > 0 THEN
            SELECT JSON_OBJECT('success', 0, 'message', 'El permiso ya existe') AS resultado;
        ELSE
            -- Insertar permiso
            INSERT INTO rutarol (ruta, rol) VALUES (p_ruta, p_rol);
            SELECT JSON_OBJECT('success', 1, 'message', 'Permiso creado exitosamente') AS resultado;
        END IF;
    END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `crear_usuario_con_roles` (IN `p_email` VARCHAR(100), IN `p_contrasena` VARCHAR(100), IN `p_roles` JSON)   BEGIN
    DECLARE v_count INT;
    DECLARE v_i INT DEFAULT 0;
    DECLARE v_length INT;
    DECLARE v_fkidrol INT;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    -- Validar que el usuario no existe
    SELECT COUNT(*) INTO v_count FROM usuario WHERE email = p_email;
    IF v_count > 0 THEN
        SIGNAL SQLSTATE '45005' SET MESSAGE_TEXT = 'El usuario ya existe';
    END IF;

    -- Insertar usuario
    INSERT INTO usuario (email, contrasena)
    VALUES (p_email, p_contrasena);

    -- Insertar roles desde JSON usando bucle
    SET v_length = JSON_LENGTH(p_roles);

    WHILE v_i < v_length DO
        SET v_fkidrol = JSON_EXTRACT(p_roles, CONCAT('$[', v_i, '].fkidrol'));

        INSERT INTO rol_usuario (fkemail, fkidrol)
        VALUES (p_email, v_fkidrol);

        SET v_i = v_i + 1;
    END WHILE;

    COMMIT;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `eliminar_factura_con_detalle` (IN `p_numfactura` INT)   BEGIN
    DECLARE v_count INT;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    -- Validar que la factura existe
    SELECT COUNT(*) INTO v_count FROM factura WHERE numero = p_numfactura;
    IF v_count = 0 THEN
        SIGNAL SQLSTATE '45004' SET MESSAGE_TEXT = 'La factura especificada no existe';
    END IF;

    -- Restaurar stock de productos
    UPDATE producto p
    INNER JOIN productosporfactura ppf ON p.codigo = ppf.fkcodproducto
    SET p.stock = p.stock + ppf.cantidad
    WHERE ppf.fknumfactura = p_numfactura;

    -- Eliminar factura (ON DELETE CASCADE eliminará los detalles)
    DELETE FROM factura WHERE numero = p_numfactura;

    COMMIT;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `eliminar_rutarol` (IN `p_ruta` VARCHAR(100), IN `p_rol` VARCHAR(100))   BEGIN
    DECLARE v_count INT;

    -- Validar que el permiso existe
    SELECT COUNT(*) INTO v_count FROM rutarol WHERE ruta = p_ruta AND rol = p_rol;
    IF v_count = 0 THEN
        SELECT JSON_OBJECT('success', 0, 'message', 'El permiso no existe') AS resultado;
    ELSE
        -- Eliminar permiso
        DELETE FROM rutarol WHERE ruta = p_ruta AND rol = p_rol;
        SELECT JSON_OBJECT('success', 1, 'message', 'Permiso eliminado exitosamente') AS resultado;
    END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `eliminar_usuario_con_roles` (IN `p_email` VARCHAR(100))   BEGIN
    DECLARE v_count INT;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    -- Validar que el usuario existe
    SELECT COUNT(*) INTO v_count FROM usuario WHERE email = p_email;
    IF v_count = 0 THEN
        SIGNAL SQLSTATE '45006' SET MESSAGE_TEXT = 'El usuario no existe';
    END IF;

    -- Eliminar usuario
    DELETE FROM usuario WHERE email = p_email;

    COMMIT;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `listar_rutarol` ()   BEGIN
    SELECT ruta, rol
    FROM rutarol
    ORDER BY ruta, rol;
END$$

--
-- Funciones
--
CREATE DEFINER=`root`@`localhost` FUNCTION `consultar_factura_con_detalle` (`p_numfactura` INT) RETURNS LONGTEXT CHARSET utf8mb4 COLLATE utf8mb4_bin DETERMINISTIC READS SQL DATA BEGIN
    DECLARE v_resultado JSON;

    SELECT JSON_OBJECT(
        'numero', f.numero,
        'fecha', f.fecha,
        'total', f.total,
        'cliente', c.fkcodpersona,
        'vendedor', v.fkcodpersona,
        'detalle', (
            SELECT JSON_ARRAYAGG(
                JSON_OBJECT(
                    'fkcodproducto', d.fkcodproducto,
                    'cantidad', d.cantidad,
                    'subtotal', d.subtotal,
                    'valorunitario', p.valorunitario
                )
            )
            FROM productosporfactura d
            INNER JOIN producto p ON p.codigo = d.fkcodproducto
            WHERE d.fknumfactura = f.numero
        )
    ) INTO v_resultado
    FROM factura f
    INNER JOIN cliente c ON c.id = f.fkidcliente
    INNER JOIN vendedor v ON v.id = f.fkidvendedor
    WHERE f.numero = p_numfactura;

    RETURN v_resultado;
END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `consultar_usuario_con_roles` (`p_email` VARCHAR(100)) RETURNS LONGTEXT CHARSET utf8mb4 COLLATE utf8mb4_bin DETERMINISTIC READS SQL DATA BEGIN
    DECLARE v_resultado JSON;

    SELECT JSON_OBJECT(
        'email', u.email,
        'roles', (
            SELECT JSON_ARRAYAGG(
                JSON_OBJECT(
                    'idrol', r.id,
                    'nombre', r.nombre
                )
            )
            FROM rol_usuario ru
            INNER JOIN rol r ON r.id = ru.fkidrol
            WHERE ru.fkemail = u.email
        )
    ) INTO v_resultado
    FROM usuario u
    WHERE u.email = p_email;

    RETURN v_resultado;
END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `listar_usuarios_con_roles` () RETURNS LONGTEXT CHARSET utf8mb4 COLLATE utf8mb4_bin DETERMINISTIC READS SQL DATA BEGIN
    DECLARE v_resultado JSON;

    SELECT JSON_ARRAYAGG(
        JSON_OBJECT(
            'email', u.email,
            'roles', (
                SELECT JSON_ARRAYAGG(
                    JSON_OBJECT(
                        'idrol', r.id,
                        'nombre', r.nombre
                    )
                )
                FROM rol_usuario ru
                INNER JOIN rol r ON r.id = ru.fkidrol
                WHERE ru.fkemail = u.email
            )
        )
    ) INTO v_resultado
    FROM usuario u;

    RETURN IFNULL(v_resultado, JSON_ARRAY());
END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `verificar_acceso_ruta` (`p_email` VARCHAR(100), `p_ruta` VARCHAR(100)) RETURNS LONGTEXT CHARSET utf8mb4 COLLATE utf8mb4_bin DETERMINISTIC READS SQL DATA BEGIN
    DECLARE v_tiene_acceso BOOLEAN DEFAULT FALSE;
    DECLARE v_resultado JSON;

    -- Verificar si el usuario tiene acceso
    SELECT EXISTS(
        SELECT 1
        FROM usuario u
        INNER JOIN rol_usuario ur ON u.email = ur.fkemail
        INNER JOIN rol r ON ur.fkidrol = r.id
        INNER JOIN rutarol rr ON r.nombre = rr.rol
        WHERE u.email = p_email AND rr.ruta = p_ruta
    ) INTO v_tiene_acceso;

    -- Construir resultado JSON
    SET v_resultado = JSON_OBJECT(
        'tiene_acceso', v_tiene_acceso,
        'email', p_email,
        'ruta', p_ruta
    );

    RETURN v_resultado;
END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `cliente`
--

CREATE TABLE `cliente` (
  `id` int(11) NOT NULL,
  `credito` decimal(14,2) NOT NULL DEFAULT 0.00 CHECK (`credito` >= 0),
  `fkcodpersona` varchar(20) NOT NULL,
  `fkcodempresa` varchar(10) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `cliente`
--

INSERT INTO `cliente` (`id`, `credito`, `fkcodpersona`, `fkcodempresa`) VALUES
(1, 555000.00, 'P001', 'E001'),
(2, 250000.00, 'P003', 'E002'),
(3, 400000.00, 'P005', 'E001');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `empresa`
--

CREATE TABLE `empresa` (
  `codigo` varchar(10) NOT NULL,
  `nombre` varchar(200) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `empresa`
--

INSERT INTO `empresa` (`codigo`, `nombre`) VALUES
('E001', 'Comercial Los Andes S.A.'),
('E002', 'Distribuciones El Centro S.A.');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `factura`
--

CREATE TABLE `factura` (
  `numero` int(11) NOT NULL,
  `fecha` timestamp NOT NULL DEFAULT current_timestamp(),
  `total` decimal(14,2) NOT NULL DEFAULT 0.00 CHECK (`total` >= 0),
  `fkidcliente` int(11) NOT NULL,
  `fkidvendedor` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `factura`
--

INSERT INTO `factura` (`numero`, `fecha`, `total`, `fkidcliente`, `fkidvendedor`) VALUES
(1, '2025-10-15 05:00:00', 2680000.00, 1, 1),
(2, '2025-10-16 05:00:00', 2700000.00, 2, 2),
(3, '2025-10-17 05:00:00', 1400000.00, 3, 3);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `persona`
--

CREATE TABLE `persona` (
  `codigo` varchar(20) NOT NULL,
  `nombre` varchar(100) NOT NULL,
  `email` varchar(100) NOT NULL,
  `telefono` varchar(20) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `persona`
--

INSERT INTO `persona` (`codigo`, `nombre`, `email`, `telefono`) VALUES
('P001', 'Ana Torres', 'ana.torres@correo.com', '3011111111'),
('P002', 'Carlos Pérez', 'carlos.perez@correo.com', '3022222222'),
('P003', 'María Gómez', 'maria.gomez@correo.com', '3033333333'),
('P004', 'Juan Díaz', 'juan.diaz@correo.com', '3044444444'),
('P005', 'Laura Rojas', 'laura.rojas@correo.com', '3055555555'),
('P006', 'Pedro Castillo', 'pedro.castillo@correo.com', '3066666666');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `producto`
--

CREATE TABLE `producto` (
  `codigo` varchar(30) NOT NULL,
  `nombre` varchar(100) NOT NULL,
  `stock` int(11) NOT NULL CHECK (`stock` >= 0),
  `valorunitario` decimal(14,2) NOT NULL CHECK (`valorunitario` >= 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `producto`
--

INSERT INTO `producto` (`codigo`, `nombre`, `stock`, `valorunitario`) VALUES
('PR001', 'Laptop Lenovo IdeaPad', 19, 2500000.00),
('PR002', 'Monitor Samsung 24\"', 28, 800000.00),
('PR003', 'Teclado Logitech K380', 47, 150000.00),
('PR004', 'Mouse HP', 58, 90000.00),
('PR005', 'Impresora Epson EcoTank', 14, 1100000.00),
('PR006', 'Auriculares Sony WH-CH510', 25, 240000.00),
('PR007', 'Tablet Samsung Tab A9', 17, 950000.00),
('PR008', 'Disco Duro Seagate 1TB', 35, 280000.00);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `productosporfactura`
--

CREATE TABLE `productosporfactura` (
  `fknumfactura` int(11) NOT NULL,
  `fkcodproducto` varchar(30) NOT NULL,
  `cantidad` int(11) NOT NULL CHECK (`cantidad` > 0),
  `subtotal` decimal(14,2) NOT NULL DEFAULT 0.00 CHECK (`subtotal` >= 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `productosporfactura`
--

INSERT INTO `productosporfactura` (`fknumfactura`, `fkcodproducto`, `cantidad`, `subtotal`) VALUES
(1, 'PR001', 1, 2500000.00),
(1, 'PR004', 2, 180000.00),
(2, 'PR002', 2, 1600000.00),
(2, 'PR005', 1, 1100000.00),
(3, 'PR003', 3, 450000.00),
(3, 'PR007', 1, 950000.00);

--
-- Disparadores `productosporfactura`
--
DELIMITER $$
CREATE TRIGGER `trigger_actualizar_totales_y_stock_delete` AFTER DELETE ON `productosporfactura` FOR EACH ROW BEGIN
    -- Restaurar stock
    UPDATE producto SET stock = stock + OLD.cantidad
    WHERE codigo = OLD.fkcodproducto;

    -- Actualizar total de factura
    UPDATE factura SET total = (
        SELECT COALESCE(SUM(subtotal), 0)
        FROM productosporfactura
        WHERE fknumfactura = OLD.fknumfactura
    )
    WHERE numero = OLD.fknumfactura;
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `trigger_actualizar_totales_y_stock_insert` BEFORE INSERT ON `productosporfactura` FOR EACH ROW BEGIN
    DECLARE v_valorunitario DECIMAL(14,2);

    -- Obtener valor unitario del producto
    SELECT valorunitario INTO v_valorunitario
    FROM producto WHERE codigo = NEW.fkcodproducto;

    -- Calcular subtotal
    SET NEW.subtotal = NEW.cantidad * v_valorunitario;

    -- Actualizar stock (restar cantidad)
    UPDATE producto SET stock = stock - NEW.cantidad
    WHERE codigo = NEW.fkcodproducto;

    -- Actualizar total de factura
    UPDATE factura SET total = (
        SELECT COALESCE(SUM(subtotal), 0)
        FROM productosporfactura
        WHERE fknumfactura = NEW.fknumfactura
    ) + NEW.subtotal
    WHERE numero = NEW.fknumfactura;
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `trigger_actualizar_totales_y_stock_update` BEFORE UPDATE ON `productosporfactura` FOR EACH ROW BEGIN
    DECLARE v_valorunitario DECIMAL(14,2);

    -- Obtener valor unitario del producto
    SELECT valorunitario INTO v_valorunitario
    FROM producto WHERE codigo = NEW.fkcodproducto;

    -- Calcular nuevo subtotal
    SET NEW.subtotal = NEW.cantidad * v_valorunitario;

    -- Ajustar stock (devolver cantidad antigua, descontar nueva)
    UPDATE producto SET stock = stock + OLD.cantidad - NEW.cantidad
    WHERE codigo = NEW.fkcodproducto;

    -- Actualizar total de factura
    UPDATE factura SET total = (
        SELECT COALESCE(SUM(subtotal), 0)
        FROM productosporfactura
        WHERE fknumfactura = NEW.fknumfactura AND fkcodproducto != NEW.fkcodproducto
    ) + NEW.subtotal
    WHERE numero = NEW.fknumfactura;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `rol`
--

CREATE TABLE `rol` (
  `id` int(11) NOT NULL,
  `nombre` varchar(100) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `rol`
--

INSERT INTO `rol` (`id`, `nombre`) VALUES
(1, 'Administrador'),
(3, 'Cajero'),
(5, 'Cliente'),
(4, 'Contador'),
(2, 'Vendedor');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `rol_usuario`
--

CREATE TABLE `rol_usuario` (
  `fkemail` varchar(100) NOT NULL,
  `fkidrol` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `rol_usuario`
--

INSERT INTO `rol_usuario` (`fkemail`, `fkidrol`) VALUES
('admin@correo.com', 1),
('cliente1@correo.com', 5),
('jefe@correo.com', 1),
('jefe@correo.com', 3),
('jefe@correo.com', 4),
('vendedor1@correo.com', 2),
('vendedor1@correo.com', 3);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `ruta`
--

CREATE TABLE `ruta` (
  `ruta` varchar(100) NOT NULL,
  `descripcion` varchar(255) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `ruta`
--

INSERT INTO `ruta` (`ruta`, `descripcion`) VALUES
('/clientes', 'Gestión de clientes'),
('/empresas', 'Gestión de empresas'),
('/facturas', 'Gestión de facturas'),
('/home', 'Página principal - Dashboard'),
('/permisos', 'Gestión de permisos (asignación rol-ruta)'),
('/permisos/crear', 'Crear permiso (POST)'),
('/permisos/eliminar', 'Eliminar permiso (POST)'),
('/personas', 'Gestión de personas'),
('/productos', 'Gestión de productos'),
('/roles', 'Gestión de roles'),
('/rutas', 'Gestión de rutas del sistema'),
('/rutas/crear', 'Crear ruta (POST)'),
('/rutas/eliminar', 'Eliminar ruta (POST)'),
('/usuarios', 'Gestión de usuarios'),
('/vendedores', 'Gestión de vendedores');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `rutarol`
--

CREATE TABLE `rutarol` (
  `ruta` varchar(100) NOT NULL,
  `rol` varchar(100) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `rutarol`
--

INSERT INTO `rutarol` (`ruta`, `rol`) VALUES
('/clientes', 'Administrador'),
('/clientes', 'Contador'),
('/clientes', 'Vendedor'),
('/empresas', 'Administrador'),
('/facturas', 'Administrador'),
('/facturas', 'Cajero'),
('/facturas', 'Vendedor'),
('/home', 'Administrador'),
('/home', 'Cajero'),
('/home', 'Contador'),
('/home', 'Vendedor'),
('/permisos', 'Administrador'),
('/permisos/crear', 'Administrador'),
('/permisos/eliminar', 'Administrador'),
('/personas', 'Administrador'),
('/productos', 'Administrador'),
('/productos', 'Contador'),
('/roles', 'Administrador'),
('/rutas', 'Administrador'),
('/rutas/crear', 'Administrador'),
('/rutas/eliminar', 'Administrador'),
('/usuarios', 'Administrador'),
('/vendedores', 'Administrador');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `usuario`
--

CREATE TABLE `usuario` (
  `email` varchar(100) NOT NULL,
  `contrasena` varchar(100) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `usuario`
--

INSERT INTO `usuario` (`email`, `contrasena`) VALUES
('admin@correo.com', '$2a$10$jhrc07/ugDnXCsXY7iUr4u9lvj2Rjddx6bPjs7XNYkR.YSJv7JD/q'),
('cliente1@correo.com', 'cli123'),
('jefe@correo.com', 'jefe123'),
('vendedor1@correo.com', 'vend123');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `vendedor`
--

CREATE TABLE `vendedor` (
  `id` int(11) NOT NULL,
  `carnet` int(11) NOT NULL,
  `direccion` varchar(100) NOT NULL,
  `fkcodpersona` varchar(20) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `vendedor`
--

INSERT INTO `vendedor` (`id`, `carnet`, `direccion`, `fkcodpersona`) VALUES
(1, 1001, 'Calle 10 #5-33', 'P002'),
(2, 1002, 'Carrera 15 #7-20', 'P004'),
(3, 1003, 'Avenida 30 #18-09', 'P006');

--
-- Índices para tablas volcadas
--

--
-- Indices de la tabla `cliente`
--
ALTER TABLE `cliente`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `fkcodpersona` (`fkcodpersona`),
  ADD KEY `fkcodempresa` (`fkcodempresa`);

--
-- Indices de la tabla `empresa`
--
ALTER TABLE `empresa`
  ADD PRIMARY KEY (`codigo`);

--
-- Indices de la tabla `factura`
--
ALTER TABLE `factura`
  ADD PRIMARY KEY (`numero`),
  ADD KEY `fkidcliente` (`fkidcliente`),
  ADD KEY `fkidvendedor` (`fkidvendedor`);

--
-- Indices de la tabla `persona`
--
ALTER TABLE `persona`
  ADD PRIMARY KEY (`codigo`);

--
-- Indices de la tabla `producto`
--
ALTER TABLE `producto`
  ADD PRIMARY KEY (`codigo`);

--
-- Indices de la tabla `productosporfactura`
--
ALTER TABLE `productosporfactura`
  ADD PRIMARY KEY (`fknumfactura`,`fkcodproducto`),
  ADD KEY `fkcodproducto` (`fkcodproducto`);

--
-- Indices de la tabla `rol`
--
ALTER TABLE `rol`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `nombre` (`nombre`);

--
-- Indices de la tabla `rol_usuario`
--
ALTER TABLE `rol_usuario`
  ADD PRIMARY KEY (`fkemail`,`fkidrol`),
  ADD KEY `fkidrol` (`fkidrol`);

--
-- Indices de la tabla `ruta`
--
ALTER TABLE `ruta`
  ADD PRIMARY KEY (`ruta`);

--
-- Indices de la tabla `rutarol`
--
ALTER TABLE `rutarol`
  ADD PRIMARY KEY (`ruta`,`rol`),
  ADD KEY `rol` (`rol`);

--
-- Indices de la tabla `usuario`
--
ALTER TABLE `usuario`
  ADD PRIMARY KEY (`email`);

--
-- Indices de la tabla `vendedor`
--
ALTER TABLE `vendedor`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `fkcodpersona` (`fkcodpersona`);

--
-- AUTO_INCREMENT de las tablas volcadas
--

--
-- AUTO_INCREMENT de la tabla `cliente`
--
ALTER TABLE `cliente`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT de la tabla `factura`
--
ALTER TABLE `factura`
  MODIFY `numero` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT de la tabla `rol`
--
ALTER TABLE `rol`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- AUTO_INCREMENT de la tabla `vendedor`
--
ALTER TABLE `vendedor`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- Restricciones para tablas volcadas
--

--
-- Filtros para la tabla `cliente`
--
ALTER TABLE `cliente`
  ADD CONSTRAINT `cliente_ibfk_1` FOREIGN KEY (`fkcodpersona`) REFERENCES `persona` (`codigo`),
  ADD CONSTRAINT `cliente_ibfk_2` FOREIGN KEY (`fkcodempresa`) REFERENCES `empresa` (`codigo`);

--
-- Filtros para la tabla `factura`
--
ALTER TABLE `factura`
  ADD CONSTRAINT `factura_ibfk_1` FOREIGN KEY (`fkidcliente`) REFERENCES `cliente` (`id`),
  ADD CONSTRAINT `factura_ibfk_2` FOREIGN KEY (`fkidvendedor`) REFERENCES `vendedor` (`id`);

--
-- Filtros para la tabla `productosporfactura`
--
ALTER TABLE `productosporfactura`
  ADD CONSTRAINT `productosporfactura_ibfk_1` FOREIGN KEY (`fknumfactura`) REFERENCES `factura` (`numero`) ON DELETE CASCADE,
  ADD CONSTRAINT `productosporfactura_ibfk_2` FOREIGN KEY (`fkcodproducto`) REFERENCES `producto` (`codigo`);

--
-- Filtros para la tabla `rol_usuario`
--
ALTER TABLE `rol_usuario`
  ADD CONSTRAINT `rol_usuario_ibfk_1` FOREIGN KEY (`fkemail`) REFERENCES `usuario` (`email`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `rol_usuario_ibfk_2` FOREIGN KEY (`fkidrol`) REFERENCES `rol` (`id`);

--
-- Filtros para la tabla `rutarol`
--
ALTER TABLE `rutarol`
  ADD CONSTRAINT `rutarol_ibfk_1` FOREIGN KEY (`ruta`) REFERENCES `ruta` (`ruta`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `rutarol_ibfk_2` FOREIGN KEY (`rol`) REFERENCES `rol` (`nombre`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Filtros para la tabla `vendedor`
--
ALTER TABLE `vendedor`
  ADD CONSTRAINT `vendedor_ibfk_1` FOREIGN KEY (`fkcodpersona`) REFERENCES `persona` (`codigo`);
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
