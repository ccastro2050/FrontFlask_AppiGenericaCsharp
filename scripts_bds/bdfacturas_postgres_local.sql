--
-- PostgreSQL database 
CREATE FUNCTION public.actualizar_totales_y_stock() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        NEW.subtotal := NEW.cantidad * (SELECT valorunitario FROM producto WHERE codigo = NEW.fkcodproducto);
        UPDATE producto SET stock = stock - NEW.cantidad WHERE codigo = NEW.fkcodproducto;
        UPDATE factura SET total = (SELECT COALESCE(SUM(subtotal),0) FROM productosporfactura WHERE fknumfactura = NEW.fknumfactura) + NEW.subtotal WHERE numero = NEW.fknumfactura;
        RETURN NEW;
    END IF;
    IF TG_OP = 'UPDATE' THEN
        NEW.subtotal := NEW.cantidad * (SELECT valorunitario FROM producto WHERE codigo = NEW.fkcodproducto);
        UPDATE producto SET stock = stock + OLD.cantidad - NEW.cantidad WHERE codigo = NEW.fkcodproducto;
        UPDATE factura SET total = (SELECT COALESCE(SUM(subtotal),0) FROM productosporfactura WHERE fknumfactura = NEW.fknumfactura AND fkcodproducto != NEW.fkcodproducto) + NEW.subtotal WHERE numero = NEW.fknumfactura;
        RETURN NEW;
    END IF;
    IF TG_OP = 'DELETE' THEN
        UPDATE producto SET stock = stock + OLD.cantidad WHERE codigo = OLD.fkcodproducto;
        UPDATE factura SET total = (SELECT COALESCE(SUM(subtotal),0) FROM productosporfactura WHERE fknumfactura = OLD.fknumfactura AND fkcodproducto != OLD.fkcodproducto) WHERE numero = OLD.fknumfactura;
        RETURN OLD;
    END IF;
    RETURN NULL;
END;
$$;


ALTER FUNCTION public.actualizar_totales_y_stock() OWNER TO postgres;

--
-- TOC entry 247 (class 1255 OID 20355)
-- Name: sp_actualizar_empresa_con_cliente(character varying, json, json, json); Type: PROCEDURE; Schema: public; Owner: postgres
--

CREATE PROCEDURE public.sp_actualizar_empresa_con_cliente(IN p_codigo character varying, IN p_maestro json, IN p_detalles json, INOUT p_resultado json DEFAULT NULL::json)
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_detalle JSON;
    v_cantidad_detalles INTEGER := 0;
BEGIN
    -- Verificar que existe el maestro
    IF NOT EXISTS (SELECT 1 FROM empresa WHERE codigo = p_codigo) THEN
        p_resultado := json_build_object(
            'exito', false,
            'error', 'Registro maestro no encontrado'
        );
        RETURN;
    END IF;

    -- Actualizar maestro
    UPDATE empresa SET
        nombre = (p_maestro->>'nombre')::VARCHAR
    WHERE codigo = p_codigo;

    -- Eliminar detalles existentes
    DELETE FROM cliente WHERE fkcodempresa = p_codigo;

    -- Insertar nuevos detalles
    FOR v_detalle IN SELECT * FROM json_array_elements(p_detalles)
    LOOP
        INSERT INTO cliente (
            fkcodempresa,
            id, credito, fkcodpersona
        )
        VALUES (
            p_codigo,
            (v_detalle->>'id')::INTEGER,
            (v_detalle->>'credito')::NUMERIC,
            (v_detalle->>'fkcodpersona')::VARCHAR
        );
        v_cantidad_detalles := v_cantidad_detalles + 1;
    END LOOP;

    -- Asignar resultado exitoso
    p_resultado := json_build_object(
        'exito', true,
        'mensaje', 'Actualización exitosa',
        'cantidad_detalles', v_cantidad_detalles
    );

EXCEPTION WHEN OTHERS THEN
    -- Rollback implícito en procedimiento
    p_resultado := json_build_object(
        'exito', false,
        'error', SQLERRM
    );
END;
$$;


ALTER PROCEDURE public.sp_actualizar_empresa_con_cliente(IN p_codigo character varying, IN p_maestro json, IN p_detalles json, INOUT p_resultado json) OWNER TO postgres;

--
-- TOC entry 248 (class 1255 OID 20356)
-- Name: sp_actualizar_factura_con_productosporfactura(integer, json, json, json); Type: PROCEDURE; Schema: public; Owner: postgres
--

CREATE PROCEDURE public.sp_actualizar_factura_con_productosporfactura(IN p_numero integer, IN p_maestro json, IN p_detalles json, INOUT p_resultado json DEFAULT NULL::json)
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_detalle JSON;
    v_cantidad_detalles INTEGER := 0;
BEGIN
    -- Verificar que existe el maestro
    IF NOT EXISTS (SELECT 1 FROM factura WHERE numero = p_numero) THEN
        p_resultado := json_build_object(
            'exito', false,
            'error', 'Registro maestro no encontrado'
        );
        RETURN;
    END IF;

    -- Actualizar maestro
    UPDATE factura SET
        fecha = (p_maestro->>'fecha')::TIMESTAMP,
        total = (p_maestro->>'total')::NUMERIC,
        fkidcliente = (p_maestro->>'fkidcliente')::INTEGER,
        fkidvendedor = (p_maestro->>'fkidvendedor')::INTEGER
    WHERE numero = p_numero;

    -- Eliminar detalles existentes
    DELETE FROM productosporfactura WHERE fknumfactura = p_numero;

    -- Insertar nuevos detalles
    FOR v_detalle IN SELECT * FROM json_array_elements(p_detalles)
    LOOP
        INSERT INTO productosporfactura (
            fknumfactura,
            fkcodproducto, cantidad, subtotal
        )
        VALUES (
            p_numero,
            (v_detalle->>'fkcodproducto')::VARCHAR,
            (v_detalle->>'cantidad')::INTEGER,
            (v_detalle->>'subtotal')::NUMERIC
        );
        v_cantidad_detalles := v_cantidad_detalles + 1;
    END LOOP;

    -- Asignar resultado exitoso
    p_resultado := json_build_object(
        'exito', true,
        'mensaje', 'Actualización exitosa',
        'cantidad_detalles', v_cantidad_detalles
    );

EXCEPTION WHEN OTHERS THEN
    -- Rollback implícito en procedimiento
    p_resultado := json_build_object(
        'exito', false,
        'error', SQLERRM
    );
END;
$$;


ALTER PROCEDURE public.sp_actualizar_factura_con_productosporfactura(IN p_numero integer, IN p_maestro json, IN p_detalles json, INOUT p_resultado json) OWNER TO postgres;

--
-- TOC entry 249 (class 1255 OID 20357)
-- Name: sp_actualizar_persona_con_cliente(character varying, json, json, json); Type: PROCEDURE; Schema: public; Owner: postgres
--

CREATE PROCEDURE public.sp_actualizar_persona_con_cliente(IN p_codigo character varying, IN p_maestro json, IN p_detalles json, INOUT p_resultado json DEFAULT NULL::json)
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_detalle JSON;
    v_cantidad_detalles INTEGER := 0;
BEGIN
    -- Verificar que existe el maestro
    IF NOT EXISTS (SELECT 1 FROM persona WHERE codigo = p_codigo) THEN
        p_resultado := json_build_object(
            'exito', false,
            'error', 'Registro maestro no encontrado'
        );
        RETURN;
    END IF;

    -- Actualizar maestro
    UPDATE persona SET
        nombre = (p_maestro->>'nombre')::VARCHAR,
        email = (p_maestro->>'email')::VARCHAR,
        telefono = (p_maestro->>'telefono')::VARCHAR
    WHERE codigo = p_codigo;

    -- Eliminar detalles existentes
    DELETE FROM cliente WHERE fkcodpersona = p_codigo;

    -- Insertar nuevos detalles
    FOR v_detalle IN SELECT * FROM json_array_elements(p_detalles)
    LOOP
        INSERT INTO cliente (
            fkcodpersona,
            id, credito, fkcodempresa
        )
        VALUES (
            p_codigo,
            (v_detalle->>'id')::INTEGER,
            (v_detalle->>'credito')::NUMERIC,
            (v_detalle->>'fkcodempresa')::VARCHAR
        );
        v_cantidad_detalles := v_cantidad_detalles + 1;
    END LOOP;

    -- Asignar resultado exitoso
    p_resultado := json_build_object(
        'exito', true,
        'mensaje', 'Actualización exitosa',
        'cantidad_detalles', v_cantidad_detalles
    );

EXCEPTION WHEN OTHERS THEN
    -- Rollback implícito en procedimiento
    p_resultado := json_build_object(
        'exito', false,
        'error', SQLERRM
    );
END;
$$;


ALTER PROCEDURE public.sp_actualizar_persona_con_cliente(IN p_codigo character varying, IN p_maestro json, IN p_detalles json, INOUT p_resultado json) OWNER TO postgres;

--
-- TOC entry 250 (class 1255 OID 20358)
-- Name: sp_actualizar_persona_con_vendedor(character varying, json, json, json); Type: PROCEDURE; Schema: public; Owner: postgres
--

CREATE PROCEDURE public.sp_actualizar_persona_con_vendedor(IN p_codigo character varying, IN p_maestro json, IN p_detalles json, INOUT p_resultado json DEFAULT NULL::json)
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_detalle JSON;
    v_cantidad_detalles INTEGER := 0;
BEGIN
    -- Verificar que existe el maestro
    IF NOT EXISTS (SELECT 1 FROM persona WHERE codigo = p_codigo) THEN
        p_resultado := json_build_object(
            'exito', false,
            'error', 'Registro maestro no encontrado'
        );
        RETURN;
    END IF;

    -- Actualizar maestro
    UPDATE persona SET
        nombre = (p_maestro->>'nombre')::VARCHAR,
        email = (p_maestro->>'email')::VARCHAR,
        telefono = (p_maestro->>'telefono')::VARCHAR
    WHERE codigo = p_codigo;

    -- Eliminar detalles existentes
    DELETE FROM vendedor WHERE fkcodpersona = p_codigo;

    -- Insertar nuevos detalles
    FOR v_detalle IN SELECT * FROM json_array_elements(p_detalles)
    LOOP
        INSERT INTO vendedor (
            fkcodpersona,
            id, carnet, direccion
        )
        VALUES (
            p_codigo,
            (v_detalle->>'id')::INTEGER,
            (v_detalle->>'carnet')::INTEGER,
            (v_detalle->>'direccion')::VARCHAR
        );
        v_cantidad_detalles := v_cantidad_detalles + 1;
    END LOOP;

    -- Asignar resultado exitoso
    p_resultado := json_build_object(
        'exito', true,
        'mensaje', 'Actualización exitosa',
        'cantidad_detalles', v_cantidad_detalles
    );

EXCEPTION WHEN OTHERS THEN
    -- Rollback implícito en procedimiento
    p_resultado := json_build_object(
        'exito', false,
        'error', SQLERRM
    );
END;
$$;


ALTER PROCEDURE public.sp_actualizar_persona_con_vendedor(IN p_codigo character varying, IN p_maestro json, IN p_detalles json, INOUT p_resultado json) OWNER TO postgres;

--
-- TOC entry 254 (class 1255 OID 20359)
-- Name: sp_actualizar_usuario_con_rol_usuario(character varying, json, json, json); Type: PROCEDURE; Schema: public; Owner: postgres
--

CREATE PROCEDURE public.sp_actualizar_usuario_con_rol_usuario(IN p_email character varying, IN p_maestro json, IN p_detalles json, INOUT p_resultado json DEFAULT NULL::json)
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_detalle JSON;
    v_cantidad_detalles INTEGER := 0;
BEGIN
    -- Verificar que existe el maestro
    IF NOT EXISTS (SELECT 1 FROM usuario WHERE email = p_email) THEN
        p_resultado := json_build_object(
            'exito', false,
            'error', 'Registro maestro no encontrado'
        );
        RETURN;
    END IF;

    -- Actualizar maestro
    UPDATE usuario SET
        contrasena = (p_maestro->>'contrasena')::VARCHAR
    WHERE email = p_email;

    -- Eliminar detalles existentes
    DELETE FROM rol_usuario WHERE fkemail = p_email;

    -- Insertar nuevos detalles
    FOR v_detalle IN SELECT * FROM json_array_elements(p_detalles)
    LOOP
        INSERT INTO rol_usuario (
            fkemail,
            fkidrol
        )
        VALUES (
            p_email,
            (v_detalle->>'fkidrol')::INTEGER
        );
        v_cantidad_detalles := v_cantidad_detalles + 1;
    END LOOP;

    -- Asignar resultado exitoso
    p_resultado := json_build_object(
        'exito', true,
        'mensaje', 'Actualización exitosa',
        'cantidad_detalles', v_cantidad_detalles
    );

EXCEPTION WHEN OTHERS THEN
    -- Rollback implícito en procedimiento
    p_resultado := json_build_object(
        'exito', false,
        'error', SQLERRM
    );
END;
$$;


ALTER PROCEDURE public.sp_actualizar_usuario_con_rol_usuario(IN p_email character varying, IN p_maestro json, IN p_detalles json, INOUT p_resultado json) OWNER TO postgres;

--
-- TOC entry 251 (class 1255 OID 20360)
-- Name: sp_crear_empresa_con_cliente(json, json, json); Type: PROCEDURE; Schema: public; Owner: postgres
--

CREATE PROCEDURE public.sp_crear_empresa_con_cliente(IN p_maestro json, IN p_detalles json, INOUT p_resultado json DEFAULT NULL::json)
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_codigo_nuevo VARCHAR;
    v_detalle JSON;
    v_cantidad_detalles INTEGER := 0;
BEGIN
    -- Insertar maestro
    INSERT INTO empresa (
        codigo, nombre
    )
    VALUES (
        (p_maestro->>'codigo')::VARCHAR,
        (p_maestro->>'nombre')::VARCHAR
    )
    RETURNING codigo INTO v_codigo_nuevo;

    -- Insertar detalles
    FOR v_detalle IN SELECT * FROM json_array_elements(p_detalles)
    LOOP
        INSERT INTO cliente (
            fkcodempresa,
            id, credito, fkcodpersona
        )
        VALUES (
            v_codigo_nuevo,
            (v_detalle->>'id')::INTEGER,
            COALESCE((v_detalle->>'credito')::NUMERIC, 0),
            (v_detalle->>'fkcodpersona')::VARCHAR
        );
        v_cantidad_detalles := v_cantidad_detalles + 1;
    END LOOP;

    -- Asignar resultado exitoso
    p_resultado := json_build_object(
        'exito', true,
        'codigo_maestro', v_codigo_nuevo,
        'cantidad_detalles', v_cantidad_detalles
    );

EXCEPTION WHEN OTHERS THEN
    -- Rollback implícito en procedimiento
    p_resultado := json_build_object(
        'exito', false,
        'error', SQLERRM
    );
END;
$$;


ALTER PROCEDURE public.sp_crear_empresa_con_cliente(IN p_maestro json, IN p_detalles json, INOUT p_resultado json) OWNER TO postgres;

--
-- TOC entry 255 (class 1255 OID 20361)
-- Name: sp_crear_factura_con_productosporfactura(json, json, json); Type: PROCEDURE; Schema: public; Owner: postgres
--

CREATE PROCEDURE public.sp_crear_factura_con_productosporfactura(IN p_maestro json, IN p_detalles json, INOUT p_resultado json DEFAULT NULL::json)
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_numero_nuevo INTEGER;
    v_detalle JSON;
    v_cantidad_detalles INTEGER := 0;
BEGIN
    -- Insertar maestro
    INSERT INTO factura (
        fecha, total, fkidcliente, fkidvendedor
    )
    VALUES (
        COALESCE((p_maestro->>'fecha')::TIMESTAMP, CURRENT_TIMESTAMP),
        COALESCE((p_maestro->>'total')::NUMERIC, 0),
        (p_maestro->>'fkidcliente')::INTEGER,
        (p_maestro->>'fkidvendedor')::INTEGER
    )
    RETURNING numero INTO v_numero_nuevo;

    -- Insertar detalles
    FOR v_detalle IN SELECT * FROM json_array_elements(p_detalles)
    LOOP
        INSERT INTO productosporfactura (
            fknumfactura,
            fkcodproducto, cantidad, subtotal
        )
        VALUES (
            v_numero_nuevo,
            (v_detalle->>'fkcodproducto')::VARCHAR,
            (v_detalle->>'cantidad')::INTEGER,
            COALESCE((v_detalle->>'subtotal')::NUMERIC, 0)
        );
        v_cantidad_detalles := v_cantidad_detalles + 1;
    END LOOP;

    -- Asignar resultado exitoso
    p_resultado := json_build_object(
        'exito', true,
        'numero_maestro', v_numero_nuevo,
        'cantidad_detalles', v_cantidad_detalles
    );

EXCEPTION WHEN OTHERS THEN
    -- Rollback implícito en procedimiento
    p_resultado := json_build_object(
        'exito', false,
        'error', SQLERRM
    );
END;
$$;


ALTER PROCEDURE public.sp_crear_factura_con_productosporfactura(IN p_maestro json, IN p_detalles json, INOUT p_resultado json) OWNER TO postgres;

--
-- TOC entry 252 (class 1255 OID 20362)
-- Name: sp_crear_persona_con_cliente(json, json, json); Type: PROCEDURE; Schema: public; Owner: postgres
--

CREATE PROCEDURE public.sp_crear_persona_con_cliente(IN p_maestro json, IN p_detalles json, INOUT p_resultado json DEFAULT NULL::json)
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_codigo_nuevo VARCHAR;
    v_detalle JSON;
    v_cantidad_detalles INTEGER := 0;
BEGIN
    -- Insertar maestro
    INSERT INTO persona (
        codigo, nombre, email, telefono
    )
    VALUES (
        (p_maestro->>'codigo')::VARCHAR,
        (p_maestro->>'nombre')::VARCHAR,
        (p_maestro->>'email')::VARCHAR,
        (p_maestro->>'telefono')::VARCHAR
    )
    RETURNING codigo INTO v_codigo_nuevo;

    -- Insertar detalles
    FOR v_detalle IN SELECT * FROM json_array_elements(p_detalles)
    LOOP
        INSERT INTO cliente (
            fkcodpersona,
            id, credito, fkcodempresa
        )
        VALUES (
            v_codigo_nuevo,
            (v_detalle->>'id')::INTEGER,
            COALESCE((v_detalle->>'credito')::NUMERIC, 0),
            (v_detalle->>'fkcodempresa')::VARCHAR
        );
        v_cantidad_detalles := v_cantidad_detalles + 1;
    END LOOP;

    -- Asignar resultado exitoso
    p_resultado := json_build_object(
        'exito', true,
        'codigo_maestro', v_codigo_nuevo,
        'cantidad_detalles', v_cantidad_detalles
    );

EXCEPTION WHEN OTHERS THEN
    -- Rollback implícito en procedimiento
    p_resultado := json_build_object(
        'exito', false,
        'error', SQLERRM
    );
END;
$$;


ALTER PROCEDURE public.sp_crear_persona_con_cliente(IN p_maestro json, IN p_detalles json, INOUT p_resultado json) OWNER TO postgres;

--
-- TOC entry 256 (class 1255 OID 20363)
-- Name: sp_crear_persona_con_vendedor(json, json, json); Type: PROCEDURE; Schema: public; Owner: postgres
--

CREATE PROCEDURE public.sp_crear_persona_con_vendedor(IN p_maestro json, IN p_detalles json, INOUT p_resultado json DEFAULT NULL::json)
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_codigo_nuevo VARCHAR;
    v_detalle JSON;
    v_cantidad_detalles INTEGER := 0;
BEGIN
    -- Insertar maestro
    INSERT INTO persona (
        codigo, nombre, email, telefono
    )
    VALUES (
        (p_maestro->>'codigo')::VARCHAR,
        (p_maestro->>'nombre')::VARCHAR,
        (p_maestro->>'email')::VARCHAR,
        (p_maestro->>'telefono')::VARCHAR
    )
    RETURNING codigo INTO v_codigo_nuevo;

    -- Insertar detalles
    FOR v_detalle IN SELECT * FROM json_array_elements(p_detalles)
    LOOP
        INSERT INTO vendedor (
            fkcodpersona,
            id, carnet, direccion
        )
        VALUES (
            v_codigo_nuevo,
            (v_detalle->>'id')::INTEGER,
            (v_detalle->>'carnet')::INTEGER,
            (v_detalle->>'direccion')::VARCHAR
        );
        v_cantidad_detalles := v_cantidad_detalles + 1;
    END LOOP;

    -- Asignar resultado exitoso
    p_resultado := json_build_object(
        'exito', true,
        'codigo_maestro', v_codigo_nuevo,
        'cantidad_detalles', v_cantidad_detalles
    );

EXCEPTION WHEN OTHERS THEN
    -- Rollback implícito en procedimiento
    p_resultado := json_build_object(
        'exito', false,
        'error', SQLERRM
    );
END;
$$;


ALTER PROCEDURE public.sp_crear_persona_con_vendedor(IN p_maestro json, IN p_detalles json, INOUT p_resultado json) OWNER TO postgres;

--
-- TOC entry 253 (class 1255 OID 20364)
-- Name: sp_crear_usuario_con_rol_usuario(json, json, json); Type: PROCEDURE; Schema: public; Owner: postgres
--

CREATE PROCEDURE public.sp_crear_usuario_con_rol_usuario(IN p_maestro json, IN p_detalles json, INOUT p_resultado json DEFAULT NULL::json)
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_email_nuevo VARCHAR;
    v_detalle JSON;
    v_cantidad_detalles INTEGER := 0;
BEGIN
    -- Insertar maestro
    INSERT INTO usuario (
        email, contrasena
    )
    VALUES (
        (p_maestro->>'email')::VARCHAR,
        (p_maestro->>'contrasena')::VARCHAR
    )
    RETURNING email INTO v_email_nuevo;

    -- Insertar detalles
    FOR v_detalle IN SELECT * FROM json_array_elements(p_detalles)
    LOOP
        INSERT INTO rol_usuario (
            fkemail,
            fkidrol
        )
        VALUES (
            v_email_nuevo,
            (v_detalle->>'fkidrol')::INTEGER
        );
        v_cantidad_detalles := v_cantidad_detalles + 1;
    END LOOP;

    -- Asignar resultado exitoso
    p_resultado := json_build_object(
        'exito', true,
        'email_maestro', v_email_nuevo,
        'cantidad_detalles', v_cantidad_detalles
    );

EXCEPTION WHEN OTHERS THEN
    -- Rollback implícito en procedimiento
    p_resultado := json_build_object(
        'exito', false,
        'error', SQLERRM
    );
END;
$$;


ALTER PROCEDURE public.sp_crear_usuario_con_rol_usuario(IN p_maestro json, IN p_detalles json, INOUT p_resultado json) OWNER TO postgres;

--
-- TOC entry 263 (class 1255 OID 30314)
-- Name: sp_eliminar_empresa_con_cliente(character varying, json); Type: PROCEDURE; Schema: public; Owner: postgres
--

CREATE PROCEDURE public.sp_eliminar_empresa_con_cliente(IN p_codigo character varying, INOUT p_resultado json DEFAULT NULL::json)
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_detalles_eliminados INTEGER;
BEGIN
    IF NOT EXISTS (SELECT 1 FROM empresa WHERE codigo = p_codigo) THEN
        p_resultado := json_build_object('exito', false, 'error', 'Registro maestro no encontrado');
        RETURN;
    END IF;
    DELETE FROM cliente WHERE fkcodempresa = p_codigo;
    GET DIAGNOSTICS v_detalles_eliminados = ROW_COUNT;
    DELETE FROM empresa WHERE codigo = p_codigo;
    p_resultado := json_build_object('exito', true, 'mensaje', 'Eliminación exitosa', 'detalles_eliminados', v_detalles_eliminados);
EXCEPTION WHEN OTHERS THEN
    p_resultado := json_build_object('exito', false, 'error', SQLERRM);
END;
$$;


ALTER PROCEDURE public.sp_eliminar_empresa_con_cliente(IN p_codigo character varying, INOUT p_resultado json) OWNER TO postgres;

--
-- TOC entry 257 (class 1255 OID 20366)
-- Name: sp_eliminar_factura_con_productosporfactura(integer, json); Type: PROCEDURE; Schema: public; Owner: postgres
--

CREATE PROCEDURE public.sp_eliminar_factura_con_productosporfactura(IN p_numero integer, INOUT p_resultado json DEFAULT NULL::json)
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_detalles_eliminados INTEGER;
BEGIN
    -- Verificar que existe el maestro
    IF NOT EXISTS (SELECT 1 FROM factura WHERE numero = p_numero) THEN
        p_resultado := json_build_object(
            'exito', false,
            'error', 'Registro maestro no encontrado'
        );
        RETURN;
    END IF;

    -- Eliminar detalles primero
    DELETE FROM productosporfactura WHERE fknumfactura = p_numero;
    GET DIAGNOSTICS v_detalles_eliminados = ROW_COUNT;

    -- Eliminar maestro
    DELETE FROM factura WHERE numero = p_numero;

    -- Asignar resultado exitoso
    p_resultado := json_build_object(
        'exito', true,
        'mensaje', 'Eliminación exitosa',
        'detalles_eliminados', v_detalles_eliminados
    );

EXCEPTION WHEN OTHERS THEN
    -- Rollback implícito en procedimiento
    p_resultado := json_build_object(
        'exito', false,
        'error', SQLERRM
    );
END;
$$;


ALTER PROCEDURE public.sp_eliminar_factura_con_productosporfactura(IN p_numero integer, INOUT p_resultado json) OWNER TO postgres;

--
-- TOC entry 234 (class 1255 OID 30312)
-- Name: sp_eliminar_persona_con_cliente(character varying, json); Type: PROCEDURE; Schema: public; Owner: postgres
--

CREATE PROCEDURE public.sp_eliminar_persona_con_cliente(IN p_codigo character varying, INOUT p_resultado json DEFAULT NULL::json)
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_detalles_eliminados INTEGER;
BEGIN
    IF NOT EXISTS (SELECT 1 FROM persona WHERE codigo = p_codigo) THEN
        p_resultado := json_build_object('exito', false, 'error', 'Registro maestro no encontrado');
        RETURN;
    END IF;
    DELETE FROM cliente WHERE fkcodpersona = p_codigo;
    GET DIAGNOSTICS v_detalles_eliminados = ROW_COUNT;
    DELETE FROM persona WHERE codigo = p_codigo;
    p_resultado := json_build_object('exito', true, 'mensaje', 'Eliminación exitosa', 'detalles_eliminados', v_detalles_eliminados);
EXCEPTION WHEN OTHERS THEN
    p_resultado := json_build_object('exito', false, 'error', SQLERRM);
END;
$$;


ALTER PROCEDURE public.sp_eliminar_persona_con_cliente(IN p_codigo character varying, INOUT p_resultado json) OWNER TO postgres;

--
-- TOC entry 235 (class 1255 OID 30313)
-- Name: sp_eliminar_persona_con_vendedor(character varying, json); Type: PROCEDURE; Schema: public; Owner: postgres
--

CREATE PROCEDURE public.sp_eliminar_persona_con_vendedor(IN p_codigo character varying, INOUT p_resultado json DEFAULT NULL::json)
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_detalles_eliminados INTEGER;
BEGIN
    IF NOT EXISTS (SELECT 1 FROM persona WHERE codigo = p_codigo) THEN
        p_resultado := json_build_object('exito', false, 'error', 'Registro maestro no encontrado');
        RETURN;
    END IF;
    DELETE FROM vendedor WHERE fkcodpersona = p_codigo;
    GET DIAGNOSTICS v_detalles_eliminados = ROW_COUNT;
    DELETE FROM persona WHERE codigo = p_codigo;
    p_resultado := json_build_object('exito', true, 'mensaje', 'Eliminación exitosa', 'detalles_eliminados', v_detalles_eliminados);
EXCEPTION WHEN OTHERS THEN
    p_resultado := json_build_object('exito', false, 'error', SQLERRM);
END;
$$;


ALTER PROCEDURE public.sp_eliminar_persona_con_vendedor(IN p_codigo character varying, INOUT p_resultado json) OWNER TO postgres;

--
-- TOC entry 264 (class 1255 OID 30315)
-- Name: sp_eliminar_usuario_con_rol_usuario(character varying, json); Type: PROCEDURE; Schema: public; Owner: postgres
--

CREATE PROCEDURE public.sp_eliminar_usuario_con_rol_usuario(IN p_email character varying, INOUT p_resultado json DEFAULT NULL::json)
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_detalles_eliminados INTEGER;
BEGIN
    IF NOT EXISTS (SELECT 1 FROM usuario WHERE email = p_email) THEN
        p_resultado := json_build_object('exito', false, 'error', 'Registro maestro no encontrado');
        RETURN;
    END IF;
    DELETE FROM rol_usuario WHERE fkemail = p_email;
    GET DIAGNOSTICS v_detalles_eliminados = ROW_COUNT;
    DELETE FROM usuario WHERE email = p_email;
    p_resultado := json_build_object('exito', true, 'mensaje', 'Eliminación exitosa', 'detalles_eliminados', v_detalles_eliminados);
EXCEPTION WHEN OTHERS THEN
    p_resultado := json_build_object('exito', false, 'error', SQLERRM);
END;
$$;


ALTER PROCEDURE public.sp_eliminar_usuario_con_rol_usuario(IN p_email character varying, INOUT p_resultado json) OWNER TO postgres;

--
-- TOC entry 258 (class 1255 OID 20370)
-- Name: sp_obtener_empresa_con_cliente(character varying, json); Type: PROCEDURE; Schema: public; Owner: postgres
--

CREATE PROCEDURE public.sp_obtener_empresa_con_cliente(IN p_codigo character varying, INOUT p_resultado json DEFAULT NULL::json)
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_maestro JSON;
    v_detalles JSON;
BEGIN
    -- Obtener maestro
    SELECT row_to_json(m) INTO v_maestro
    FROM empresa m
    WHERE m.codigo = p_codigo;

    IF v_maestro IS NULL THEN
        p_resultado := json_build_object(
            'exito', false,
            'error', 'Registro maestro no encontrado'
        );
        RETURN;
    END IF;

    -- Obtener detalles
    SELECT COALESCE(json_agg(row_to_json(d)), '[]'::json) INTO v_detalles
    FROM cliente d
    WHERE d.fkcodempresa = p_codigo;

    -- Asignar resultado combinado
    p_resultado := json_build_object(
        'exito', true,
        'maestro', v_maestro,
        'detalles', v_detalles
    );
END;
$$;


ALTER PROCEDURE public.sp_obtener_empresa_con_cliente(IN p_codigo character varying, INOUT p_resultado json) OWNER TO postgres;

--
-- TOC entry 261 (class 1255 OID 20371)
-- Name: sp_obtener_factura_con_productosporfactura(integer, json); Type: PROCEDURE; Schema: public; Owner: postgres
--

CREATE PROCEDURE public.sp_obtener_factura_con_productosporfactura(IN p_numero integer, INOUT p_resultado json DEFAULT NULL::json)
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_maestro JSON;
    v_detalles JSON;
BEGIN
    -- Obtener maestro
    SELECT row_to_json(m) INTO v_maestro
    FROM factura m
    WHERE m.numero = p_numero;

    IF v_maestro IS NULL THEN
        p_resultado := json_build_object(
            'exito', false,
            'error', 'Registro maestro no encontrado'
        );
        RETURN;
    END IF;

    -- Obtener detalles
    SELECT COALESCE(json_agg(row_to_json(d)), '[]'::json) INTO v_detalles
    FROM productosporfactura d
    WHERE d.fknumfactura = p_numero;

    -- Asignar resultado combinado
    p_resultado := json_build_object(
        'exito', true,
        'maestro', v_maestro,
        'detalles', v_detalles
    );
END;
$$;


ALTER PROCEDURE public.sp_obtener_factura_con_productosporfactura(IN p_numero integer, INOUT p_resultado json) OWNER TO postgres;

--
-- TOC entry 259 (class 1255 OID 20372)
-- Name: sp_obtener_persona_con_cliente(character varying, json); Type: PROCEDURE; Schema: public; Owner: postgres
--

CREATE PROCEDURE public.sp_obtener_persona_con_cliente(IN p_codigo character varying, INOUT p_resultado json DEFAULT NULL::json)
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_maestro JSON;
    v_detalles JSON;
BEGIN
    -- Obtener maestro
    SELECT row_to_json(m) INTO v_maestro
    FROM persona m
    WHERE m.codigo = p_codigo;

    IF v_maestro IS NULL THEN
        p_resultado := json_build_object(
            'exito', false,
            'error', 'Registro maestro no encontrado'
        );
        RETURN;
    END IF;

    -- Obtener detalles
    SELECT COALESCE(json_agg(row_to_json(d)), '[]'::json) INTO v_detalles
    FROM cliente d
    WHERE d.fkcodpersona = p_codigo;

    -- Asignar resultado combinado
    p_resultado := json_build_object(
        'exito', true,
        'maestro', v_maestro,
        'detalles', v_detalles
    );
END;
$$;


ALTER PROCEDURE public.sp_obtener_persona_con_cliente(IN p_codigo character varying, INOUT p_resultado json) OWNER TO postgres;

--
-- TOC entry 262 (class 1255 OID 20373)
-- Name: sp_obtener_persona_con_vendedor(character varying, json); Type: PROCEDURE; Schema: public; Owner: postgres
--

CREATE PROCEDURE public.sp_obtener_persona_con_vendedor(IN p_codigo character varying, INOUT p_resultado json DEFAULT NULL::json)
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_maestro JSON;
    v_detalles JSON;
BEGIN
    -- Obtener maestro
    SELECT row_to_json(m) INTO v_maestro
    FROM persona m
    WHERE m.codigo = p_codigo;

    IF v_maestro IS NULL THEN
        p_resultado := json_build_object(
            'exito', false,
            'error', 'Registro maestro no encontrado'
        );
        RETURN;
    END IF;

    -- Obtener detalles
    SELECT COALESCE(json_agg(row_to_json(d)), '[]'::json) INTO v_detalles
    FROM vendedor d
    WHERE d.fkcodpersona = p_codigo;

    -- Asignar resultado combinado
    p_resultado := json_build_object(
        'exito', true,
        'maestro', v_maestro,
        'detalles', v_detalles
    );
END;
$$;


ALTER PROCEDURE public.sp_obtener_persona_con_vendedor(IN p_codigo character varying, INOUT p_resultado json) OWNER TO postgres;

--
-- TOC entry 260 (class 1255 OID 20374)
-- Name: sp_obtener_usuario_con_rol_usuario(character varying, json); Type: PROCEDURE; Schema: public; Owner: postgres
--

CREATE PROCEDURE public.sp_obtener_usuario_con_rol_usuario(IN p_email character varying, INOUT p_resultado json DEFAULT NULL::json)
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_maestro JSON;
    v_detalles JSON;
BEGIN
    -- Obtener maestro
    SELECT row_to_json(m) INTO v_maestro
    FROM usuario m
    WHERE m.email = p_email;

    IF v_maestro IS NULL THEN
        p_resultado := json_build_object(
            'exito', false,
            'error', 'Registro maestro no encontrado'
        );
        RETURN;
    END IF;

    -- Obtener detalles
    SELECT COALESCE(json_agg(row_to_json(d)), '[]'::json) INTO v_detalles
    FROM rol_usuario d
    WHERE d.fkemail = p_email;

    -- Asignar resultado combinado
    p_resultado := json_build_object(
        'exito', true,
        'maestro', v_maestro,
        'detalles', v_detalles
    );
END;
$$;


ALTER PROCEDURE public.sp_obtener_usuario_con_rol_usuario(IN p_email character varying, INOUT p_resultado json) OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- TOC entry 224 (class 1259 OID 20244)
-- Name: cliente; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.cliente (
    id integer NOT NULL,
    credito numeric(14,2) DEFAULT 0 NOT NULL,
    fkcodpersona character varying(20) NOT NULL,
    fkcodempresa character varying(10),
    CONSTRAINT cliente_credito_check CHECK ((credito >= (0)::numeric))
);


ALTER TABLE public.cliente OWNER TO postgres;

--
-- TOC entry 223 (class 1259 OID 20243)
-- Name: cliente_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.cliente_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.cliente_id_seq OWNER TO postgres;

--
-- TOC entry 5032 (class 0 OID 0)
-- Dependencies: 223
-- Name: cliente_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.cliente_id_seq OWNED BY public.cliente.id;


--
-- TOC entry 218 (class 1259 OID 20219)
-- Name: empresa; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.empresa (
    codigo character varying(10) NOT NULL,
    nombre character varying(200) NOT NULL
);


ALTER TABLE public.empresa OWNER TO postgres;

--
-- TOC entry 231 (class 1259 OID 20316)
-- Name: factura; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.factura (
    numero integer NOT NULL,
    fecha timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    total numeric(14,2) DEFAULT 0 NOT NULL,
    fkidcliente integer NOT NULL,
    fkidvendedor integer NOT NULL,
    CONSTRAINT factura_total_check CHECK ((total >= (0)::numeric))
);


ALTER TABLE public.factura OWNER TO postgres;

--
-- TOC entry 230 (class 1259 OID 20315)
-- Name: factura_numero_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.factura_numero_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.factura_numero_seq OWNER TO postgres;

--
-- TOC entry 5033 (class 0 OID 0)
-- Dependencies: 230
-- Name: factura_numero_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.factura_numero_seq OWNED BY public.factura.numero;


--
-- TOC entry 217 (class 1259 OID 20214)
-- Name: persona; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.persona (
    codigo character varying(20) NOT NULL,
    nombre character varying(100) NOT NULL,
    email character varying(100) NOT NULL,
    telefono character varying(20) NOT NULL
);


ALTER TABLE public.persona OWNER TO postgres;

--
-- TOC entry 229 (class 1259 OID 20308)
-- Name: producto; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.producto (
    codigo character varying(30) NOT NULL,
    nombre character varying(100) NOT NULL,
    stock integer NOT NULL,
    valorunitario numeric(14,2) NOT NULL,
    CONSTRAINT producto_stock_check CHECK ((stock >= 0)),
    CONSTRAINT producto_valorunitario_check CHECK ((valorunitario >= (0)::numeric))
);


ALTER TABLE public.producto OWNER TO postgres;

--
-- TOC entry 232 (class 1259 OID 20335)
-- Name: productosporfactura; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.productosporfactura (
    fknumfactura integer NOT NULL,
    fkcodproducto character varying(30) NOT NULL,
    cantidad integer NOT NULL,
    subtotal numeric(14,2) DEFAULT 0 NOT NULL,
    CONSTRAINT productosporfactura_cantidad_check CHECK ((cantidad > 0)),
    CONSTRAINT productosporfactura_subtotal_check CHECK ((subtotal >= (0)::numeric))
);


ALTER TABLE public.productosporfactura OWNER TO postgres;

--
-- TOC entry 221 (class 1259 OID 20230)
-- Name: rol; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.rol (
    id integer NOT NULL,
    nombre character varying(100) NOT NULL
);


ALTER TABLE public.rol OWNER TO postgres;

--
-- TOC entry 220 (class 1259 OID 20229)
-- Name: rol_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.rol_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.rol_id_seq OWNER TO postgres;

--
-- TOC entry 5034 (class 0 OID 0)
-- Dependencies: 220
-- Name: rol_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.rol_id_seq OWNED BY public.rol.id;


--
-- TOC entry 227 (class 1259 OID 20278)
-- Name: rol_usuario; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.rol_usuario (
    fkemail character varying(100) NOT NULL,
    fkidrol integer NOT NULL
);


ALTER TABLE public.rol_usuario OWNER TO postgres;

--
-- TOC entry 222 (class 1259 OID 20238)
-- Name: ruta; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ruta (
    ruta character varying(100) NOT NULL,
    descripcion character varying(255) NOT NULL
);


ALTER TABLE public.ruta OWNER TO postgres;

--
-- TOC entry 228 (class 1259 OID 20293)
-- Name: rutarol; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.rutarol (
    ruta character varying(100) NOT NULL,
    rol character varying(100) NOT NULL
);


ALTER TABLE public.rutarol OWNER TO postgres;

--
-- TOC entry 219 (class 1259 OID 20224)
-- Name: usuario; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.usuario (
    email character varying(100) NOT NULL,
    contrasena character varying(100) NOT NULL
);


ALTER TABLE public.usuario OWNER TO postgres;

--
-- TOC entry 226 (class 1259 OID 20265)
-- Name: vendedor; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.vendedor (
    id integer NOT NULL,
    carnet integer NOT NULL,
    direccion character varying(100) NOT NULL,
    fkcodpersona character varying(20) NOT NULL
);


ALTER TABLE public.vendedor OWNER TO postgres;

--
-- TOC entry 225 (class 1259 OID 20264)
-- Name: vendedor_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.vendedor_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.vendedor_id_seq OWNER TO postgres;

--
-- TOC entry 5035 (class 0 OID 0)
-- Dependencies: 225
-- Name: vendedor_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.vendedor_id_seq OWNED BY public.vendedor.id;


--
-- TOC entry 4811 (class 2604 OID 20247)
-- Name: cliente id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cliente ALTER COLUMN id SET DEFAULT nextval('public.cliente_id_seq'::regclass);


--
-- TOC entry 4814 (class 2604 OID 20319)
-- Name: factura numero; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.factura ALTER COLUMN numero SET DEFAULT nextval('public.factura_numero_seq'::regclass);


--
-- TOC entry 4810 (class 2604 OID 20233)
-- Name: rol id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.rol ALTER COLUMN id SET DEFAULT nextval('public.rol_id_seq'::regclass);


--
-- TOC entry 4813 (class 2604 OID 20268)
-- Name: vendedor id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.vendedor ALTER COLUMN id SET DEFAULT nextval('public.vendedor_id_seq'::regclass);


--
-- TOC entry 5018 (class 0 OID 20244)
-- Dependencies: 224
-- Data for Name: cliente; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.cliente VALUES (2, 250000.00, 'P003', 'E002');
INSERT INTO public.cliente VALUES (3, 400000.00, 'P005', 'E001');
INSERT INTO public.cliente VALUES (1, 520000.00, 'P001', 'E001');
INSERT INTO public.cliente VALUES (5, 700000.00, 'P006', 'E001');


--
-- TOC entry 5012 (class 0 OID 20219)
-- Dependencies: 218
-- Data for Name: empresa; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.empresa VALUES ('E001', 'Comercial Los Andes S.A.');
INSERT INTO public.empresa VALUES ('E002', 'Distribuciones El Centro S.A.');
INSERT INTO public.empresa VALUES ('E999', 'Empresa Test');


--
-- TOC entry 5025 (class 0 OID 20316)
-- Dependencies: 231
-- Data for Name: factura; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.factura VALUES (1, '2025-12-03 12:57:19.27592', 5000000.00, 1, 1);
INSERT INTO public.factura VALUES (2, '2025-12-03 12:57:19.27592', 1250000.00, 2, 2);
INSERT INTO public.factura VALUES (3, '2025-12-03 12:57:19.27592', 2030000.00, 3, 3);
INSERT INTO public.factura VALUES (4, '2025-12-03 13:04:59.028613', 950000.00, 1, 1);
INSERT INTO public.factura VALUES (5, '2025-12-03 13:05:17.874385', 2740000.00, 2, 2);
INSERT INTO public.factura VALUES (6, '2025-12-03 13:05:35.02846', 4850000.00, 3, 3);


--
-- TOC entry 5011 (class 0 OID 20214)
-- Dependencies: 217
-- Data for Name: persona; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.persona VALUES ('P001', 'Ana Torres', 'ana.torres@correo.com', '3011111111');
INSERT INTO public.persona VALUES ('P002', 'Carlos Pérez', 'carlos.perez@correo.com', '3022222222');
INSERT INTO public.persona VALUES ('P003', 'María Gómez', 'maria.gomez@correo.com', '3033333333');
INSERT INTO public.persona VALUES ('P004', 'Juan Díaz', 'juan.diaz@correo.com', '3044444444');
INSERT INTO public.persona VALUES ('P005', 'Laura Rojas', 'laura.rojas@correo.com', '3055555555');
INSERT INTO public.persona VALUES ('P006', 'Pedro Castillo', 'pedro.castillo@correo.com', '3066666666');


--
-- TOC entry 5023 (class 0 OID 20308)
-- Dependencies: 229
-- Data for Name: producto; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.producto VALUES ('PR006', 'Auriculares Sony WH-CH510', 23, 240000.00);
INSERT INTO public.producto VALUES ('PR007', 'Tablet Samsung Tab A9', 15, 950000.00);
INSERT INTO public.producto VALUES ('PR008', 'Disco Duro Seagate 1TB', 32, 280000.00);
INSERT INTO public.producto VALUES ('PR001', 'Laptop Lenovo IdeaPad', 17, 2500000.00);
INSERT INTO public.producto VALUES ('PR002', 'Monitor Samsung 24"', 27, 800000.00);
INSERT INTO public.producto VALUES ('PR003', 'Teclado Logitech K380', 42, 150000.00);
INSERT INTO public.producto VALUES ('PR004', 'Mouse HP', 55, 90000.00);
INSERT INTO public.producto VALUES ('PR005', 'Impresora Epson EcoTank1', 14, 1100000.00);


--
-- TOC entry 5026 (class 0 OID 20335)
-- Dependencies: 232
-- Data for Name: productosporfactura; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.productosporfactura VALUES (1, 'PR001', 2, 5000000.00);
INSERT INTO public.productosporfactura VALUES (2, 'PR002', 1, 800000.00);
INSERT INTO public.productosporfactura VALUES (2, 'PR003', 3, 450000.00);
INSERT INTO public.productosporfactura VALUES (3, 'PR004', 5, 450000.00);
INSERT INTO public.productosporfactura VALUES (3, 'PR005', 1, 1100000.00);
INSERT INTO public.productosporfactura VALUES (3, 'PR006', 2, 480000.00);
INSERT INTO public.productosporfactura VALUES (4, 'PR007', 1, 950000.00);
INSERT INTO public.productosporfactura VALUES (5, 'PR007', 2, 1900000.00);
INSERT INTO public.productosporfactura VALUES (5, 'PR008', 3, 840000.00);
INSERT INTO public.productosporfactura VALUES (6, 'PR001', 1, 2500000.00);
INSERT INTO public.productosporfactura VALUES (6, 'PR002', 2, 1600000.00);
INSERT INTO public.productosporfactura VALUES (6, 'PR003', 5, 750000.00);


--
-- TOC entry 5015 (class 0 OID 20230)
-- Dependencies: 221
-- Data for Name: rol; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.rol VALUES (1, 'Administrador');
INSERT INTO public.rol VALUES (2, 'Vendedor');
INSERT INTO public.rol VALUES (3, 'Cajero');
INSERT INTO public.rol VALUES (4, 'Contador');
INSERT INTO public.rol VALUES (5, 'Cliente');


--
-- TOC entry 5021 (class 0 OID 20278)
-- Dependencies: 227
-- Data for Name: rol_usuario; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.rol_usuario VALUES ('admin@correo.com', 1);
INSERT INTO public.rol_usuario VALUES ('vendedor1@correo.com', 2);
INSERT INTO public.rol_usuario VALUES ('vendedor1@correo.com', 3);
INSERT INTO public.rol_usuario VALUES ('jefe@correo.com', 1);
INSERT INTO public.rol_usuario VALUES ('jefe@correo.com', 3);
INSERT INTO public.rol_usuario VALUES ('jefe@correo.com', 4);
INSERT INTO public.rol_usuario VALUES ('cliente1@correo.com', 5);
INSERT INTO public.rol_usuario VALUES ('test_encript@correo.com', 1);
INSERT INTO public.rol_usuario VALUES ('nuevo@correo.com', 1);
INSERT INTO public.rol_usuario VALUES ('nuevo@correo.com', 2);
INSERT INTO public.rol_usuario VALUES ('nuevo@correo.com', 3);


--
-- TOC entry 5016 (class 0 OID 20238)
-- Dependencies: 222
-- Data for Name: ruta; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.ruta VALUES ('/home', 'Página principal - Dashboard');
INSERT INTO public.ruta VALUES ('/usuarios', 'Gestión de usuarios');
INSERT INTO public.ruta VALUES ('/facturas', 'Gestión de facturas');
INSERT INTO public.ruta VALUES ('/clientes', 'Gestión de clientes');
INSERT INTO public.ruta VALUES ('/vendedores', 'Gestión de vendedores');
INSERT INTO public.ruta VALUES ('/personas', 'Gestión de personas');
INSERT INTO public.ruta VALUES ('/empresas', 'Gestión de empresas');
INSERT INTO public.ruta VALUES ('/productos', 'Gestión de productos');
INSERT INTO public.ruta VALUES ('/roles', 'Gestión de roles');
INSERT INTO public.ruta VALUES ('/permisos', 'Gestión de permisos (asignación rol-ruta)');
INSERT INTO public.ruta VALUES ('/permisos/crear', 'Crear permiso (POST)');
INSERT INTO public.ruta VALUES ('/permisos/eliminar', 'Eliminar permiso (POST)');
INSERT INTO public.ruta VALUES ('/rutas', 'Gestión de rutas del sistema');
INSERT INTO public.ruta VALUES ('/rutas/crear', 'Crear ruta (POST)');
INSERT INTO public.ruta VALUES ('/rutas/eliminar', 'Eliminar ruta (POST)');


--
-- TOC entry 5022 (class 0 OID 20293)
-- Dependencies: 228
-- Data for Name: rutarol; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.rutarol VALUES ('/home', 'Administrador');
INSERT INTO public.rutarol VALUES ('/usuarios', 'Administrador');
INSERT INTO public.rutarol VALUES ('/facturas', 'Administrador');
INSERT INTO public.rutarol VALUES ('/clientes', 'Administrador');
INSERT INTO public.rutarol VALUES ('/vendedores', 'Administrador');
INSERT INTO public.rutarol VALUES ('/personas', 'Administrador');
INSERT INTO public.rutarol VALUES ('/empresas', 'Administrador');
INSERT INTO public.rutarol VALUES ('/productos', 'Administrador');
INSERT INTO public.rutarol VALUES ('/roles', 'Administrador');
INSERT INTO public.rutarol VALUES ('/permisos', 'Administrador');
INSERT INTO public.rutarol VALUES ('/permisos/crear', 'Administrador');
INSERT INTO public.rutarol VALUES ('/permisos/eliminar', 'Administrador');
INSERT INTO public.rutarol VALUES ('/rutas', 'Administrador');
INSERT INTO public.rutarol VALUES ('/rutas/crear', 'Administrador');
INSERT INTO public.rutarol VALUES ('/rutas/eliminar', 'Administrador');
INSERT INTO public.rutarol VALUES ('/home', 'Vendedor');
INSERT INTO public.rutarol VALUES ('/facturas', 'Vendedor');
INSERT INTO public.rutarol VALUES ('/clientes', 'Vendedor');
INSERT INTO public.rutarol VALUES ('/home', 'Cajero');
INSERT INTO public.rutarol VALUES ('/facturas', 'Cajero');
INSERT INTO public.rutarol VALUES ('/home', 'Contador');
INSERT INTO public.rutarol VALUES ('/clientes', 'Contador');
INSERT INTO public.rutarol VALUES ('/productos', 'Contador');
INSERT INTO public.rutarol VALUES ('/home', 'Cliente');
INSERT INTO public.rutarol VALUES ('/productos', 'Cliente');


--
-- TOC entry 5013 (class 0 OID 20224)
-- Dependencies: 219
-- Data for Name: usuario; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.usuario VALUES ('jefe@correo.com', 'jefe123');
INSERT INTO public.usuario VALUES ('cliente1@correo.com', 'cli123');
INSERT INTO public.usuario VALUES ('admin@correo.com', '$2a$12$3UgI.Eof.FhzsYUWESI9n.qFaqkV2JPhvW3L/1GTKowNJnGaD8F.G');
INSERT INTO public.usuario VALUES ('test_encript@correo.com', '$2a$11$Ci0J2yBltDgQHfjadgkl0OtbcF5pUf97vTq/4Xr0KEU/86l8ybjBe');
INSERT INTO public.usuario VALUES ('nuevo@correo.com', '$2a$11$cmtGBxllwc7MCzpnKVSWuumiOgCaG6PaKWcN1z9N0bjjnkobbFDzO');
INSERT INTO public.usuario VALUES ('vendedor1@correo.com', '$2a$12$Dgog4VaHqMzhliPVJy1BcOMd6.izEGNeRDtZ.O7SPmBLc6UVthVTG');


--
-- TOC entry 5020 (class 0 OID 20265)
-- Dependencies: 226
-- Data for Name: vendedor; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.vendedor VALUES (1, 1001, 'Calle 10 #5-33', 'P002');
INSERT INTO public.vendedor VALUES (2, 1002, 'Carrera 15 #7-20', 'P004');
INSERT INTO public.vendedor VALUES (3, 1003, 'Avenida 30 #18-09', 'P006');


--
-- TOC entry 5036 (class 0 OID 0)
-- Dependencies: 223
-- Name: cliente_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.cliente_id_seq', 5, true);


--
-- TOC entry 5037 (class 0 OID 0)
-- Dependencies: 230
-- Name: factura_numero_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.factura_numero_seq', 6, true);


--
-- TOC entry 5038 (class 0 OID 0)
-- Dependencies: 220
-- Name: rol_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.rol_id_seq', 5, true);


--
-- TOC entry 5039 (class 0 OID 0)
-- Dependencies: 225
-- Name: vendedor_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.vendedor_id_seq', 3, true);


--
-- TOC entry 4837 (class 2606 OID 20253)
-- Name: cliente cliente_fkcodpersona_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cliente
    ADD CONSTRAINT cliente_fkcodpersona_key UNIQUE (fkcodpersona);


--
-- TOC entry 4839 (class 2606 OID 20251)
-- Name: cliente cliente_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cliente
    ADD CONSTRAINT cliente_pkey PRIMARY KEY (id);


--
-- TOC entry 4827 (class 2606 OID 20223)
-- Name: empresa empresa_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.empresa
    ADD CONSTRAINT empresa_pkey PRIMARY KEY (codigo);


--
-- TOC entry 4851 (class 2606 OID 20324)
-- Name: factura factura_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.factura
    ADD CONSTRAINT factura_pkey PRIMARY KEY (numero);


--
-- TOC entry 4825 (class 2606 OID 20218)
-- Name: persona persona_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.persona
    ADD CONSTRAINT persona_pkey PRIMARY KEY (codigo);


--
-- TOC entry 4849 (class 2606 OID 20314)
-- Name: producto producto_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.producto
    ADD CONSTRAINT producto_pkey PRIMARY KEY (codigo);


--
-- TOC entry 4853 (class 2606 OID 20342)
-- Name: productosporfactura productosporfactura_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.productosporfactura
    ADD CONSTRAINT productosporfactura_pkey PRIMARY KEY (fknumfactura, fkcodproducto);


--
-- TOC entry 4831 (class 2606 OID 20237)
-- Name: rol rol_nombre_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.rol
    ADD CONSTRAINT rol_nombre_key UNIQUE (nombre);


--
-- TOC entry 4833 (class 2606 OID 20235)
-- Name: rol rol_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.rol
    ADD CONSTRAINT rol_pkey PRIMARY KEY (id);


--
-- TOC entry 4845 (class 2606 OID 20282)
-- Name: rol_usuario rol_usuario_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.rol_usuario
    ADD CONSTRAINT rol_usuario_pkey PRIMARY KEY (fkemail, fkidrol);


--
-- TOC entry 4835 (class 2606 OID 20242)
-- Name: ruta ruta_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ruta
    ADD CONSTRAINT ruta_pkey PRIMARY KEY (ruta);


--
-- TOC entry 4847 (class 2606 OID 20297)
-- Name: rutarol rutarol_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.rutarol
    ADD CONSTRAINT rutarol_pkey PRIMARY KEY (ruta, rol);


--
-- TOC entry 4829 (class 2606 OID 20228)
-- Name: usuario usuario_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.usuario
    ADD CONSTRAINT usuario_pkey PRIMARY KEY (email);


--
-- TOC entry 4841 (class 2606 OID 20272)
-- Name: vendedor vendedor_fkcodpersona_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.vendedor
    ADD CONSTRAINT vendedor_fkcodpersona_key UNIQUE (fkcodpersona);


--
-- TOC entry 4843 (class 2606 OID 20270)
-- Name: vendedor vendedor_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.vendedor
    ADD CONSTRAINT vendedor_pkey PRIMARY KEY (id);


--
-- TOC entry 4865 (class 2620 OID 20354)
-- Name: productosporfactura trigger_actualizar_totales_y_stock; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trigger_actualizar_totales_y_stock BEFORE INSERT OR DELETE OR UPDATE ON public.productosporfactura FOR EACH ROW EXECUTE FUNCTION public.actualizar_totales_y_stock();


--
-- TOC entry 4854 (class 2606 OID 20259)
-- Name: cliente cliente_fkcodempresa_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cliente
    ADD CONSTRAINT cliente_fkcodempresa_fkey FOREIGN KEY (fkcodempresa) REFERENCES public.empresa(codigo);


--
-- TOC entry 4855 (class 2606 OID 20254)
-- Name: cliente cliente_fkcodpersona_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cliente
    ADD CONSTRAINT cliente_fkcodpersona_fkey FOREIGN KEY (fkcodpersona) REFERENCES public.persona(codigo);


--
-- TOC entry 4861 (class 2606 OID 20325)
-- Name: factura factura_fkidcliente_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.factura
    ADD CONSTRAINT factura_fkidcliente_fkey FOREIGN KEY (fkidcliente) REFERENCES public.cliente(id);


--
-- TOC entry 4862 (class 2606 OID 20330)
-- Name: factura factura_fkidvendedor_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.factura
    ADD CONSTRAINT factura_fkidvendedor_fkey FOREIGN KEY (fkidvendedor) REFERENCES public.vendedor(id);


--
-- TOC entry 4863 (class 2606 OID 20348)
-- Name: productosporfactura productosporfactura_fkcodproducto_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.productosporfactura
    ADD CONSTRAINT productosporfactura_fkcodproducto_fkey FOREIGN KEY (fkcodproducto) REFERENCES public.producto(codigo);


--
-- TOC entry 4864 (class 2606 OID 20343)
-- Name: productosporfactura productosporfactura_fknumfactura_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.productosporfactura
    ADD CONSTRAINT productosporfactura_fknumfactura_fkey FOREIGN KEY (fknumfactura) REFERENCES public.factura(numero) ON DELETE CASCADE;


--
-- TOC entry 4857 (class 2606 OID 20283)
-- Name: rol_usuario rol_usuario_fkemail_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.rol_usuario
    ADD CONSTRAINT rol_usuario_fkemail_fkey FOREIGN KEY (fkemail) REFERENCES public.usuario(email) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 4858 (class 2606 OID 20288)
-- Name: rol_usuario rol_usuario_fkidrol_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.rol_usuario
    ADD CONSTRAINT rol_usuario_fkidrol_fkey FOREIGN KEY (fkidrol) REFERENCES public.rol(id);


--
-- TOC entry 4859 (class 2606 OID 20303)
-- Name: rutarol rutarol_rol_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.rutarol
    ADD CONSTRAINT rutarol_rol_fkey FOREIGN KEY (rol) REFERENCES public.rol(nombre) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 4860 (class 2606 OID 20298)
-- Name: rutarol rutarol_ruta_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.rutarol
    ADD CONSTRAINT rutarol_ruta_fkey FOREIGN KEY (ruta) REFERENCES public.ruta(ruta) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 4856 (class 2606 OID 20273)
-- Name: vendedor vendedor_fkcodpersona_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.vendedor
    ADD CONSTRAINT vendedor_fkcodpersona_fkey FOREIGN KEY (fkcodpersona) REFERENCES public.persona(codigo);


