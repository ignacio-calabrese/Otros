
CREATE TABLE product (
	id                            serial PRIMARY KEY,
	name                          text NOT NULL UNIQUE,
	descrition                    text,
	stock                         integer NOT NULL CHECK (stock >= 0) DEFAULT 0
);

-----------------------------
-- CONSTRUCTOR & DESTRUCTOR
-----------------------------
CREATE OR REPLACE FUNCTION product (
	IN p_name                     text,
	IN p_description              text,
	IN p_stock                    integer
) RETURNS product AS
$$
	INSERT INTO product(name, descrition, stock)
		VALUES(p_name, p_description, p_stock)
	RETURNING *;
$$ LANGUAGE sql VOLATILE STRICT;


CREATE OR REPLACE FUNCTION product_destroy (
	IN p_product                  product
) RETURNS void AS
$$
	DELETE FROM product p WHERE p = p_product;
$$ LANGUAGE sql VOLATILE STRICT;


-----------------------------
-- SEARCH & IDENTIFY
-----------------------------
CREATE OR REPLACE FUNCTION product_identify_by_id (
	IN p_id                       integer
) RETURNS product AS
$$
	SELECT p FROM product p WHERE id = p_id;
$$ LANGUAGE sql STABLE STRICT;


CREATE OR REPLACE FUNCTION product_search_by_name (
	IN p_name                     text DEFAULT '%'
) RETURNS SETOF product AS
$$
	SELECT * FROM product WHERE name ilike p_name || '%' ORDER BY name;
$$ LANGUAGE sql STABLE STRICT;


-----------------------------
-- GETTERS & SETTERS
-----------------------------
CREATE OR REPLACE FUNCTION product_get_id (
	IN p_product                  product
) RETURNS integer AS
$$
	SELECT id(p_product);
$$ LANGUAGE sql STABLE STRICT;


CREATE OR REPLACE FUNCTION product_get_name (
	IN p_product                  product
) RETURNS text AS 
$$
	SELECT name(p_product);
$$ LANGUAGE sql STABLE STRICT;


CREATE OR REPLACE FUNCTION product_get_description (
	IN p_product                  product
) RETURNS text AS 
$$
	SELECT descrition(p_product);
$$ LANGUAGE sql STABLE STRICT;


CREATE OR REPLACE FUNCTION product_get_stock (
	IN p_product                  product
) RETURNS integer AS 
$$
	SELECT stock(p_product);
$$ LANGUAGE sql STABLE STRICT;


CREATE OR REPLACE FUNCTION product_set_name (
	IN p_product                  product,
	IN p_name                     text
) RETURNS void AS
$$
	UPDATE product p SET name = p_name WHERE p = p_product;
$$ LANGUAGE sql VOLATILE STRICT;


CREATE OR REPLACE FUNCTION product_set_description (
	IN p_product                  product,
	IN p_description              text
) RETURNS void AS
$$
	UPDATE product p SET descrition = p_description WHERE p = p_product;
$$ LANGUAGE sql VOLATILE STRICT;


CREATE OR REPLACE FUNCTION product_set_stock (
	IN p_product                  product,
	IN p_stock                    integer
) RETURNS void AS
$$
	UPDATE product p SET stock = p_stock WHERE p = p_product;
$$ LANGUAGE sql VOLATILE STRICT;


CREATE OR REPLACE FUNCTION product_add_to_stock (
	IN p_product                  product,
	IN p_quantity                 integer
) RETURNS void AS $$
BEGIN 
	IF p_quantity <= 0
	THEN 
		RAISE EXCEPTION 'product_add_to_stock ERROR: quantity is <= 0';
	END IF;
	
	UPDATE product p SET p.stock = p.stock + p_quantity
		WHERE p = p_product;
END;
$$ LANGUAGE plpgsql VOLATILE STRICT;


CREATE OR REPLACE FUNCTION product_remove_from_stock (
	IN p_product                  product,
	IN p_quantity                 integer
) RETURNS void AS $$
BEGIN 
	IF p_quantity <= 0
	THEN 
		RAISE EXCEPTION 'product_remove_to_stock ERROR: quantity is <= 0';
	END IF;
	
	IF stock(p_product) < p_quantity
	THEN 
		RAISE EXCEPTION 'product_remove_to_stock ERROR: stock < quantity';
	END IF;
	
	UPDATE product p SET p.stock = p.stock - p_quantity
		WHERE p = p_product;
END;
$$ LANGUAGE plpgsql VOLATILE STRICT;
﻿--------------------------------------------------------------
---Validar y crear
-------------------------------------------------------------
CREATE OR REPLACE FUNCTION webapi_product_validate (
	IN p_product                  jsonb
) RETURNS boolean AS $$
BEGIN 
	--IF NOT p_product ? 'id'
		IF NOT p_product ? 'name'
		OR NOT p_product ? 'description'
		OR NOT p_product ? 'stock'
	THEN
		RETURN FALSE;
	ELSE 
		RETURN TRUE;
	END IF;
END;
$$ LANGUAGE plpgsql IMMUTABLE STRICT;


CREATE OR REPLACE FUNCTION webapi_product_create (
	IN p_product                  jsonb
) RETURNS jsonb AS $$
BEGIN 
	IF NOT webapi_product_validate(p_product)
	THEN 
		RAISE EXCEPTION 'webapi_product_create ERROR: malformed JSON object';
	END IF;
	
	RETURN row_to_json(p)::jsonb FROM product (
		p_product ->> 'name',
		p_product ->> 'description',
		(p_product ->> 'stock')::integer
	) p;
END;
$$ LANGUAGE plpgsql VOLATILE STRICT;

--------------------------------------------------------------
---Validar y borrar
-------------------------------------------------------------

CREATE OR REPLACE FUNCTION webapi_product_validate_destroy (
	IN p_product                  jsonb
) RETURNS boolean AS $$
BEGIN 
	--IF NOT p_product ? 'id'
		IF NOT p_product ? 'name'
		OR NOT p_product ? 'description'
		OR NOT p_product ? 'stock'
	THEN
		RETURN FALSE;
	ELSE 
		RETURN TRUE;
	END IF;
END;
$$ LANGUAGE plpgsql IMMUTABLE STRICT;

CREATE OR REPLACE FUNCTION webapi_product_destroy (
	IN p_product                  jsonb
) RETURNS jsonb AS $$
BEGIN 
	IF NOT webapi_product_validate_destroy(p_product)
	THEN 
		RAISE EXCEPTION 'webapi_product_destroy ERROR: malformed JSON object';
	END IF;
	
	PERFORM product_destroy (
		--(p_product ->> 'id')::integer,
		p_product ->> 'name',
		p_product ->> 'description',
		(p_product ->> 'stock')::integer
	) p;
END;
$$ LANGUAGE plpgsql VOLATILE STRICT;


--------------------------------------------------------------
---Validar atributos
-------------------------------------------------------------

CREATE OR REPLACE FUNCTION webapi_product_validate_id (
	IN p_product                  jsonb
) RETURNS boolean AS $$
BEGIN 
	IF NOT p_product ? 'id'
	THEN
		RETURN FALSE;
	ELSE 
		RETURN TRUE;
	END IF;
END;
$$ LANGUAGE plpgsql IMMUTABLE STRICT;


CREATE OR REPLACE FUNCTION webapi_product_validate_name (
	IN p_product                  jsonb
) RETURNS boolean AS $$
BEGIN 
	IF NOT p_product ? 'name'
	THEN
		RETURN FALSE;
	ELSE 
		RETURN TRUE;
	END IF;
END;
$$ LANGUAGE plpgsql IMMUTABLE STRICT;

CREATE OR REPLACE FUNCTION webapi_product_validate_description (
	IN p_product                  jsonb
) RETURNS boolean AS $$
BEGIN 
	IF NOT p_product ? 'description'
	THEN
		RETURN FALSE;
	ELSE 
		RETURN TRUE;
	END IF;
END;
$$ LANGUAGE plpgsql IMMUTABLE STRICT;

CREATE OR REPLACE FUNCTION webapi_product_validate_stock (
	IN p_product                  jsonb
) RETURNS boolean AS $$
BEGIN 
	IF NOT p_product ? 'stock'
	THEN
		RETURN FALSE;
	ELSE 
		RETURN TRUE;
	END IF;
END;
$$ LANGUAGE plpgsql IMMUTABLE STRICT;


--------------------------------------------------------------
---Validar y SEARCH & IDENTIFY
-------------------------------------------------------------

CREATE OR REPLACE FUNCTION webapi_product_identify_by_id (
	IN p_product                  jsonb
) RETURNS jsonb AS $$
BEGIN 
	IF NOT webapi_product_validate_id(p_product)
	THEN 
		RAISE EXCEPTION 'webapi_product_identify_by_id ERROR: malformed JSON object';
	END IF;
	
	PERFORM product_identify_by_id (
		(p_product ->> 'id')::integer
	) p;
END;
$$ LANGUAGE plpgsql VOLATILE STRICT;

CREATE OR REPLACE FUNCTION webapi_product_search_by_name (
	IN p_product                  jsonb
) RETURNS jsonb AS $$
BEGIN 
	IF NOT webapi_product_validate_name(p_product)
	THEN 
		RAISE EXCEPTION 'webapi_product_search_by_name ERROR: malformed JSON object';
	END IF;
	
	PERFORM product_search_by_name (
		p_product ->> 'name'
	) p;
END;
$$ LANGUAGE plpgsql VOLATILE STRICT;

CREATE OR REPLACE FUNCTION webapi_product_search_by_name(
	IN p_product                  jsonb DEFAULT '{"name":null}'
) RETURNS jsonb AS $$
DECLARE
	v_name                     text;

BEGIN
	IF NOT p_product ? 'name'
	THEN
		RAISE EXCEPTION 'webapi_product_search_by_name EXCEPTION: malformed JSON object';
	END IF;

	v_name := p_product ->> 'name';
	IF v_name IS NULL
	THEN
		v_name := '';
	END IF;

	RETURN array_to_json(array_agg(x)) FROM (SELECT * FROM product_search_by_name(v_name)) x;
END;
$$ LANGUAGE plpgsql STABLE STRICT;

--------------------------------------------------------------
---Validar y  GETTERS & SETTERS
-------------------------------------------------------------

CREATE OR REPLACE FUNCTION webapi_product_get_id (
	IN p_product                  jsonb
) RETURNS jsonb AS $$
BEGIN 
	IF NOT webapi_product_validate_id(p_product)
	THEN 
		RAISE EXCEPTION 'webapi_product_get_id ERROR: malformed JSON object';
	END IF;
	
	PERFORM product__get_id (
		(p_product ->> 'id')::integer
	) p;
END;
$$ LANGUAGE plpgsql VOLATILE STRICT;

CREATE OR REPLACE FUNCTION webapi_product_get_name (
	IN p_product                  jsonb
) RETURNS jsonb AS $$
BEGIN 
	IF NOT webapi_product_validate_name(p_product)
	THEN 
		RAISE EXCEPTION 'webapi_product_get_name ERROR: malformed JSON object';
	END IF;
	
	PERFORM product__get_name (
		p_product ->> 'name'
	) p;
END;
$$ LANGUAGE plpgsql VOLATILE STRICT;

CREATE OR REPLACE FUNCTION webapi_product_get_description (
	IN p_product                  jsonb
) RETURNS jsonb AS $$
BEGIN 
	IF NOT webapi_product_validate_description(p_product)
	THEN 
		RAISE EXCEPTION 'webapi_product_get_description ERROR: malformed JSON object';
	END IF;
	
	PERFORM product__get_description (
		p_product ->> 'description'
	) p;
END;
$$ LANGUAGE plpgsql VOLATILE STRICT;

CREATE OR REPLACE FUNCTION webapi_product_get_stock (
	IN p_product                  jsonb
) RETURNS jsonb AS $$
BEGIN 
	IF NOT webapi_product_validate_stock(p_product)
	THEN 
		RAISE EXCEPTION 'webapi_product_get_stock ERROR: malformed JSON object';
	END IF;
	
	PERFORM product__get_stock (
		(p_product ->> 'stock')::integer
	) p;
END;
$$ LANGUAGE plpgsql VOLATILE STRICT;

