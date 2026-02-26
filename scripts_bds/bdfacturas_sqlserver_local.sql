-- ==============================================================
--  BASE DE DATOS FACTURACIÓN - SQL Server
--  Solo tablas, trigger y datos iniciales
--  Los SP maestro-detalle se generan con /api/generador-sp
-- ==============================================================

-- ================================================================
-- TABLAS BASE
-- ================================================================
CREATE TABLE persona (
    codigo VARCHAR(20) PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    email VARCHAR(100) NOT NULL,
    telefono VARCHAR(20) NOT NULL
);

CREATE TABLE empresa (
    codigo VARCHAR(10) PRIMARY KEY,
    nombre VARCHAR(200) NOT NULL
);

CREATE TABLE usuario (
    email VARCHAR(100) PRIMARY KEY,
    contrasena VARCHAR(100) NOT NULL
);

CREATE TABLE rol (
    id INT IDENTITY(1,1) PRIMARY KEY,
    nombre VARCHAR(100) UNIQUE NOT NULL
);

CREATE TABLE ruta (
    ruta VARCHAR(100) PRIMARY KEY,
    descripcion VARCHAR(255) NOT NULL
);

CREATE TABLE cliente (
    id INT IDENTITY(1,1) PRIMARY KEY,
    credito NUMERIC(14,2) NOT NULL DEFAULT 0 CHECK (credito >= 0),
    fkcodpersona VARCHAR(20) NOT NULL UNIQUE REFERENCES persona (codigo),
    fkcodempresa VARCHAR(10) REFERENCES empresa (codigo)
);

CREATE TABLE vendedor (
    id INT IDENTITY(1,1) PRIMARY KEY,
    carnet INT NOT NULL,
    direccion VARCHAR(100) NOT NULL,
    fkcodpersona VARCHAR(20) NOT NULL UNIQUE REFERENCES persona (codigo)
);

CREATE TABLE rol_usuario (
    fkemail VARCHAR(100) NOT NULL REFERENCES usuario (email) ON UPDATE CASCADE ON DELETE CASCADE,
    fkidrol INT NOT NULL REFERENCES rol (id),
    PRIMARY KEY (fkemail, fkidrol)
);

CREATE TABLE rutarol (
    ruta VARCHAR(100) NOT NULL REFERENCES ruta (ruta) ON UPDATE CASCADE ON DELETE CASCADE,
    rol VARCHAR(100) NOT NULL REFERENCES rol (nombre) ON UPDATE CASCADE ON DELETE CASCADE,
    PRIMARY KEY (ruta, rol)
);

CREATE TABLE producto (
    codigo VARCHAR(30) PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    stock INT NOT NULL CHECK (stock >= 0),
    valorunitario NUMERIC(14,2) NOT NULL CHECK (valorunitario >= 0)
);

CREATE TABLE factura (
    numero INT IDENTITY(1,1) PRIMARY KEY,
    fecha DATETIME2 NOT NULL DEFAULT GETDATE(),
    total NUMERIC(14,2) NOT NULL DEFAULT 0 CHECK (total >= 0),
    fkidcliente INT NOT NULL REFERENCES cliente (id),
    fkidvendedor INT NOT NULL REFERENCES vendedor (id)
);

CREATE TABLE productosporfactura (
    fknumfactura INT NOT NULL REFERENCES factura (numero) ON DELETE CASCADE,
    fkcodproducto VARCHAR(30) NOT NULL REFERENCES producto (codigo),
    cantidad INT NOT NULL CHECK (cantidad > 0),
    subtotal NUMERIC(14,2) NOT NULL DEFAULT 0 CHECK (subtotal >= 0),
    PRIMARY KEY (fknumfactura, fkcodproducto)
);
GO

-- ================================================================
-- TRIGGER: Actualizar totales y stock automáticamente
-- ================================================================
CREATE OR ALTER TRIGGER trigger_actualizar_totales_y_stock
ON productosporfactura
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    -- INSERT
    IF EXISTS(SELECT * FROM inserted) AND NOT EXISTS(SELECT * FROM deleted)
    BEGIN
        UPDATE ppf
        SET subtotal = i.cantidad * p.valorunitario
        FROM productosporfactura ppf
        INNER JOIN inserted i ON ppf.fknumfactura = i.fknumfactura AND ppf.fkcodproducto = i.fkcodproducto
        INNER JOIN producto p ON p.codigo = i.fkcodproducto;

        UPDATE p
        SET stock = stock - i.cantidad
        FROM producto p
        INNER JOIN inserted i ON p.codigo = i.fkcodproducto;

        UPDATE f
        SET total = ISNULL((SELECT SUM(subtotal) FROM productosporfactura WHERE fknumfactura = f.numero), 0)
        FROM factura f
        INNER JOIN inserted i ON f.numero = i.fknumfactura;
    END

    -- UPDATE
    IF EXISTS(SELECT * FROM inserted) AND EXISTS(SELECT * FROM deleted)
    BEGIN
        UPDATE ppf
        SET subtotal = i.cantidad * p.valorunitario
        FROM productosporfactura ppf
        INNER JOIN inserted i ON ppf.fknumfactura = i.fknumfactura AND ppf.fkcodproducto = i.fkcodproducto
        INNER JOIN producto p ON p.codigo = i.fkcodproducto;

        UPDATE p
        SET stock = stock + d.cantidad - i.cantidad
        FROM producto p
        INNER JOIN deleted d ON p.codigo = d.fkcodproducto
        INNER JOIN inserted i ON p.codigo = i.fkcodproducto;

        UPDATE f
        SET total = ISNULL((SELECT SUM(subtotal) FROM productosporfactura WHERE fknumfactura = f.numero), 0)
        FROM factura f
        INNER JOIN inserted i ON f.numero = i.fknumfactura;
    END

    -- DELETE
    IF EXISTS(SELECT * FROM deleted) AND NOT EXISTS(SELECT * FROM inserted)
    BEGIN
        UPDATE p
        SET stock = stock + d.cantidad
        FROM producto p
        INNER JOIN deleted d ON p.codigo = d.fkcodproducto;

        UPDATE f
        SET total = ISNULL((SELECT SUM(subtotal) FROM productosporfactura WHERE fknumfactura = f.numero), 0)
        FROM factura f
        INNER JOIN deleted d ON f.numero = d.fknumfactura;
    END
END;
GO

-- ================================================================
-- DATOS INICIALES
-- ================================================================
INSERT INTO rol (nombre) VALUES
('Administrador'),
('Vendedor'),
('Cajero'),
('Contador'),
('Cliente');

INSERT INTO empresa (codigo, nombre) VALUES
('E001', 'Comercial Los Andes S.A.'),
('E002', 'Distribuciones El Centro S.A.');

INSERT INTO persona (codigo, nombre, email, telefono) VALUES
('P001', 'Ana Torres', 'ana.torres@correo.com', '3011111111'),
('P002', 'Carlos Pérez', 'carlos.perez@correo.com', '3022222222'),
('P003', 'María Gómez', 'maria.gomez@correo.com', '3033333333'),
('P004', 'Juan Díaz', 'juan.diaz@correo.com', '3044444444'),
('P005', 'Laura Rojas', 'laura.rojas@correo.com', '3055555555'),
('P006', 'Pedro Castillo', 'pedro.castillo@correo.com', '3066666666');

INSERT INTO cliente (credito, fkcodpersona, fkcodempresa) VALUES
(500000, 'P001', 'E001'),
(250000, 'P003', 'E002'),
(400000, 'P005', 'E001');

INSERT INTO vendedor (carnet, direccion, fkcodpersona) VALUES
(1001, 'Calle 10 #5-33', 'P002'),
(1002, 'Carrera 15 #7-20', 'P004'),
(1003, 'Avenida 30 #18-09', 'P006');

INSERT INTO producto (codigo, nombre, stock, valorunitario) VALUES
('PR001', 'Laptop Lenovo IdeaPad', 20, 2500000),
('PR002', 'Monitor Samsung 24"', 30, 800000),
('PR003', 'Teclado Logitech K380', 50, 150000),
('PR004', 'Mouse HP', 60, 90000),
('PR005', 'Impresora Epson EcoTank', 15, 1100000),
('PR006', 'Auriculares Sony WH-CH510', 25, 240000),
('PR007', 'Tablet Samsung Tab A9', 18, 950000),
('PR008', 'Disco Duro Seagate 1TB', 35, 280000);

-- Usuarios iniciales (contraseñas en texto plano, la API las cifra con camposEncriptar)
INSERT INTO usuario (email, contrasena) VALUES
('admin@correo.com', 'admin123'),
('vendedor1@correo.com', 'vend123'),
('jefe@correo.com', 'jefe123'),
('cliente1@correo.com', 'cli123');

INSERT INTO rol_usuario (fkemail, fkidrol) VALUES
('admin@correo.com', 1),
('vendedor1@correo.com', 2),
('vendedor1@correo.com', 3),
('jefe@correo.com', 1),
('jefe@correo.com', 3),
('jefe@correo.com', 4),
('cliente1@correo.com', 5);

-- Rutas del sistema
INSERT INTO ruta (ruta, descripcion) VALUES
('/home', 'Página principal - Dashboard'),
('/usuarios', 'Gestión de usuarios'),
('/facturas', 'Gestión de facturas'),
('/clientes', 'Gestión de clientes'),
('/vendedores', 'Gestión de vendedores'),
('/personas', 'Gestión de personas'),
('/empresas', 'Gestión de empresas'),
('/productos', 'Gestión de productos'),
('/roles', 'Gestión de roles'),
('/permisos', 'Gestión de permisos (asignación rol-ruta)'),
('/permisos/crear', 'Crear permiso (POST)'),
('/permisos/eliminar', 'Eliminar permiso (POST)'),
('/rutas', 'Gestión de rutas del sistema'),
('/rutas/crear', 'Crear ruta (POST)'),
('/rutas/eliminar', 'Eliminar ruta (POST)');

-- Permisos: Administrador (acceso total)
INSERT INTO rutarol (ruta, rol) VALUES
('/home', 'Administrador'),
('/usuarios', 'Administrador'),
('/facturas', 'Administrador'),
('/clientes', 'Administrador'),
('/vendedores', 'Administrador'),
('/personas', 'Administrador'),
('/empresas', 'Administrador'),
('/productos', 'Administrador'),
('/roles', 'Administrador'),
('/permisos', 'Administrador'),
('/permisos/crear', 'Administrador'),
('/permisos/eliminar', 'Administrador'),
('/rutas', 'Administrador'),
('/rutas/crear', 'Administrador'),
('/rutas/eliminar', 'Administrador');

-- Permisos: Vendedor
INSERT INTO rutarol (ruta, rol) VALUES
('/home', 'Vendedor'),
('/facturas', 'Vendedor'),
('/clientes', 'Vendedor');

-- Permisos: Cajero
INSERT INTO rutarol (ruta, rol) VALUES
('/home', 'Cajero'),
('/facturas', 'Cajero');

-- Permisos: Contador
INSERT INTO rutarol (ruta, rol) VALUES
('/home', 'Contador'),
('/clientes', 'Contador'),
('/productos', 'Contador');

-- Permisos: Cliente
INSERT INTO rutarol (ruta, rol) VALUES
('/home', 'Cliente'),
('/productos', 'Cliente');
GO

-- ================================================================
-- FACTURAS DE EJEMPLO (3 facturas con 1, 2 y 3 detalles)
-- ================================================================
-- Factura 1: Cliente 1, Vendedor 1, 1 producto
SET IDENTITY_INSERT factura ON;
INSERT INTO factura (numero, fecha, total, fkidcliente, fkidvendedor) VALUES
(1, GETDATE(), 0, 1, 1);
SET IDENTITY_INSERT factura OFF;
INSERT INTO productosporfactura (fknumfactura, fkcodproducto, cantidad) VALUES
(1, 'PR001', 2);

-- Factura 2: Cliente 2, Vendedor 2, 2 productos
SET IDENTITY_INSERT factura ON;
INSERT INTO factura (numero, fecha, total, fkidcliente, fkidvendedor) VALUES
(2, GETDATE(), 0, 2, 2);
SET IDENTITY_INSERT factura OFF;
INSERT INTO productosporfactura (fknumfactura, fkcodproducto, cantidad) VALUES
(2, 'PR002', 1),
(2, 'PR003', 3);

-- Factura 3: Cliente 3, Vendedor 3, 3 productos
SET IDENTITY_INSERT factura ON;
INSERT INTO factura (numero, fecha, total, fkidcliente, fkidvendedor) VALUES
(3, GETDATE(), 0, 3, 3);
SET IDENTITY_INSERT factura OFF;
INSERT INTO productosporfactura (fknumfactura, fkcodproducto, cantidad) VALUES
(3, 'PR004', 5),
(3, 'PR005', 1),
(3, 'PR006', 2);
GO

-- ================================================================
-- SINCRONIZAR IDENTITY CON DATOS INSERTADOS
-- ================================================================
DBCC CHECKIDENT ('rol', RESEED);
DBCC CHECKIDENT ('cliente', RESEED);
DBCC CHECKIDENT ('vendedor', RESEED);
DBCC CHECKIDENT ('factura', RESEED);
GO
