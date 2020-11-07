
-- 1. Crear nuevo usuario para tener las tablas aisladas en el esquema del usuario

CREATE USER prueba2 IDENTIFIED BY 1234;
GRANT ALL PRIVILEGES TO prueba2;

-- 2. Crear tablas 


CREATE TABLE cliente (
id INT,
rut VARCHAR (10) NOT NULL UNIQUE,
nombre VARCHAR(50) NOT NULL,
direccion VARCHAR (255) NOT NULL,
PRIMARY KEY (id)
);

CREATE TABLE categoria (

id INT,
categoria VARCHAR (20) NOT NULL,
descripcion VARCHAR (255),
PRIMARY KEY (id)
);

CREATE TABLE iva (
tipo NUMBER (4,2),
descripcion VARCHAR (50),
PRIMARY KEY (tipo)
);

CREATE TABLE factura (
numero INT,
cliente_id INT,
fecha DATE NOT NULL,
subtotal NUMBER DEFAULT 0,
total_iva NUMBER DEFAULT 0,
total_monto NUMBER AS (subtotal+total_iva),
PRIMARY KEY (numero),
FOREIGN KEY (cliente_id) REFERENCES cliente(id)
);

CREATE TABLE producto(
id INT,
producto VARCHAR (20) NOT NULL,
descripcion VARCHAR (255),
precio NUMBER CHECK (precio>=0),
tipo_iva NUMBER (4,2),
categoria_id INT,
PRIMARY KEY (id),
FOREIGN KEY (TIPO_IVA) REFERENCES IVA(TIPO)
);

ALTER TABLE producto
	ADD CONSTRAINT fk_iva	
		FOREIGN KEY (categoria_id)
		REFERENCES categoria(id);

CREATE TABLE factura_item (
	id INT,
	producto_id INT,
	factura_numero INT,
	producto_qty INT NOT NULL CHECK (producto_qty>0),
	producto_subtotal NUMBER DEFAULT 0,
	producto_iva NUMBER DEFAULT 0,
	producto_monto NUMBER as (producto_subtotal+producto_iva),
	PRIMARY KEY (id),
	FOREIGN KEY (factura_numero) REFERENCES FACTURA(numero),
	FOREIGN KEY (producto_id) REFERENCES producto(id)
);



-- 3. Cargar datos maestros

-- tipos iva

INSERT INTO iva (tipo,descripcion) VALUES (19,'Tipo general');

-- categorias producto

INSERT INTO categoria (id,categoria) VALUES (1,'Alimentacion');
INSERT INTO categoria (id,categoria) VALUES (2,'Limpieza');
INSERT INTO categoria (id,categoria) VALUES (3,'Electro');

-- productos

INSERT INTO producto (id,producto,precio,tipo_iva,categoria_id) VALUES (1,'Pan de molde',1.00,19,1);
INSERT INTO producto (id,producto,precio,tipo_iva,categoria_id) VALUES (2,'Tomate malla',1.50,19,1);
INSERT INTO producto (id,producto,precio,tipo_iva,categoria_id) VALUES (3,'Cerveza Royal pack',6.00,19,1);
INSERT INTO producto (id,producto,precio,tipo_iva,categoria_id) VALUES (4,'Pollo Filetes 1 kg',5.00,19,1);
INSERT INTO producto (id,producto,precio,tipo_iva,categoria_id) VALUES (5,'Lavalozas 750 ml',1.50,19,2);
INSERT INTO producto (id,producto,precio,tipo_iva,categoria_id) VALUES (6,'Toallas cocina 3pack',2.00,19,2);
INSERT INTO producto (id,producto,precio,tipo_iva,categoria_id) VALUES (7,'Papel higienico 6u',3.00,19,2);
INSERT INTO producto (id,producto,precio,tipo_iva,categoria_id) VALUES (8,'Smartphone ACME20',90.00,19,3);

-- clientes

INSERT INTO cliente (id, rut, nombre,direccion) VALUES (1,'1-9','Juan Chileno','Rue del Percebe 13');
INSERT INTO cliente (id, rut, nombre,direccion) VALUES (2,'2-8','Almudena Grandes','Melancolia 15');
INSERT INTO cliente (id, rut, nombre,direccion) VALUES (3,'3-7','Brad Pitt','Marsella 25');
INSERT INTO cliente (id, rut, nombre,direccion) VALUES (4,'4-6','Donald Trump','Derrota 20');
INSERT INTO cliente (id, rut, nombre,direccion) VALUES (5,'5-5','Rafael Nadal','Triunfo 23');


-- 4. Cargar transacciones


-- factura 1 cliente 1 2 productos

-- a. crear factura

	INSERT INTO factura (numero,cliente_id,fecha) VALUES (1,1,sysdate-10);

-- b. crear items factura
	--- item 1
	
INSERT INTO factura_item(ID ,factura_numero,producto_id,producto_qty) VALUES (1,1,2,2);
	UPDATE 
		(SELECT producto.precio AS price, producto.tipo_iva AS vat, factura_item.* FROM producto JOIN factura_item ON producto.id=factura_item.producto_id WHERE producto.id=2 AND factura_item.factura_numero=1)
		SET producto_subtotal=producto_qty*price;
	UPDATE 
		(SELECT producto.precio AS price, producto.tipo_iva AS vat, factura_item.* FROM producto JOIN factura_item ON producto.id=factura_item.producto_id WHERE producto.id=2 AND factura_item.factura_numero=1)
		SET producto_iva=producto_subtotal*(vat/100);
	-- item 2
INSERT INTO factura_item(ID ,factura_numero,producto_id,producto_qty) VALUES (2,1,3,1);
	UPDATE 
		(SELECT producto.precio AS price, producto.tipo_iva AS vat, factura_item.* FROM producto JOIN factura_item ON producto.id=factura_item.producto_id WHERE producto.id=3 AND factura_item.factura_numero=1)
		SET producto_subtotal=producto_qty*price;
	UPDATE 
		(SELECT producto.precio AS price, producto.tipo_iva AS vat, factura_item.* FROM producto JOIN factura_item ON producto.id=factura_item.producto_id WHERE producto.id=3 AND factura_item.factura_numero=1)
		SET producto_iva=producto_subtotal*(vat/100);
	
-- c. actualizar factura

	UPDATE factura
		SET factura.subtotal =(SELECT g.valsum suma FROM factura f 
		INNER JOIN (SELECT factura_item.factura_numero,sum(producto_subtotal)valsum
			FROM factura_item WHERE factura_numero=1 GROUP BY factura_numero)g
			ON f.numero=g.factura_numero) WHERE factura.numero=1;
		
		
	UPDATE factura
		SET factura.total_iva =(SELECT g.valsum suma FROM factura f 
		INNER JOIN (SELECT factura_item.factura_numero,sum(producto_iva)valsum
			FROM factura_item WHERE factura_numero=1 GROUP BY factura_numero)g
			ON f.numero=g.factura_numero) WHERE factura.numero=1;
		
	
-- factura 2 cliente 1 3 productos

-- a. crear factura

	INSERT INTO factura (numero,cliente_id,fecha) VALUES (2,1,sysdate-9);

-- b. crear items factura
	--- item 1
	
INSERT INTO factura_item(ID ,factura_numero,producto_id,producto_qty) VALUES (3,2,3,3);
	UPDATE 
		(SELECT producto.precio AS price, producto.tipo_iva AS vat, factura_item.* FROM producto JOIN factura_item ON producto.id=factura_item.producto_id WHERE producto.id=3 AND factura_item.factura_numero=2)
		SET producto_subtotal=producto_qty*price;
	UPDATE 
		(SELECT producto.precio AS price, producto.tipo_iva AS vat, factura_item.* FROM producto JOIN factura_item ON producto.id=factura_item.producto_id WHERE producto.id=3 AND factura_item.factura_numero=2)
		SET producto_iva=producto_subtotal*(vat/100);
	-- item 2
INSERT INTO factura_item(ID ,factura_numero,producto_id,producto_qty) VALUES (4,2,4,3);
	UPDATE 
		(SELECT producto.precio AS price, producto.tipo_iva AS vat, factura_item.* FROM producto JOIN factura_item ON producto.id=factura_item.producto_id WHERE producto.id=4 AND factura_item.factura_numero=2)
		SET producto_subtotal=producto_qty*price;
	UPDATE 
		(SELECT producto.precio AS price, producto.tipo_iva AS vat, factura_item.* FROM producto JOIN factura_item ON producto.id=factura_item.producto_id WHERE producto.id=4 AND factura_item.factura_numero=2)
		SET producto_iva=producto_subtotal*(vat/100);

	-- item 3
	
INSERT INTO factura_item(ID ,factura_numero,producto_id,producto_qty) VALUES (5,2,6,1);
	UPDATE 
		(SELECT producto.precio AS price, producto.tipo_iva AS vat, factura_item.* FROM producto JOIN factura_item ON producto.id=factura_item.producto_id WHERE producto.id=6 AND factura_item.factura_numero=2)
		SET producto_subtotal=producto_qty*price;
	UPDATE 
		(SELECT producto.precio AS price, producto.tipo_iva AS vat, factura_item.* FROM producto JOIN factura_item ON producto.id=factura_item.producto_id WHERE producto.id=6 AND factura_item.factura_numero=2)
		SET producto_iva=producto_subtotal*(vat/100);

-- c. actualizar factura

	UPDATE factura
		SET factura.subtotal =(SELECT g.valsum suma FROM factura f 
		INNER JOIN (SELECT factura_item.factura_numero,sum(producto_subtotal)valsum
			FROM factura_item WHERE factura_numero=2 GROUP BY factura_numero)g
			ON f.numero=g.factura_numero) WHERE factura.numero=2;
		
		
	UPDATE factura
		SET factura.total_iva =(SELECT g.valsum suma FROM factura f 
		INNER JOIN (SELECT factura_item.factura_numero,sum(producto_iva)valsum
			FROM factura_item WHERE factura_numero=2 GROUP BY factura_numero)g
			ON f.numero=g.factura_numero) WHERE factura.numero=2;
		
-- factura 3 cliente 2 3 productos
-- a. crear factura

	INSERT INTO factura (numero,cliente_id,fecha) VALUES (3,2,sysdate-8);

-- b. crear items factura
	--- item 1
	
INSERT INTO factura_item(ID ,factura_numero,producto_id,producto_qty) VALUES (6,3,7,2);
	UPDATE 
		(SELECT producto.precio AS price, producto.tipo_iva AS vat, factura_item.* FROM producto JOIN factura_item ON producto.id=factura_item.producto_id WHERE producto.id=7 AND factura_item.factura_numero=3)
		SET producto_subtotal=producto_qty*price;
	UPDATE 
		(SELECT producto.precio AS price, producto.tipo_iva AS vat, factura_item.* FROM producto JOIN factura_item ON producto.id=factura_item.producto_id WHERE producto.id=7 AND factura_item.factura_numero=3)
		SET producto_iva=producto_subtotal*(vat/100);
	-- item 2
INSERT INTO factura_item(ID ,factura_numero,producto_id,producto_qty) VALUES (7,3,3,3);
	UPDATE 
		(SELECT producto.precio AS price, producto.tipo_iva AS vat, factura_item.* FROM producto JOIN factura_item ON producto.id=factura_item.producto_id WHERE producto.id=3 AND factura_item.factura_numero=3)
		SET producto_subtotal=producto_qty*price;
	UPDATE 
		(SELECT producto.precio AS price, producto.tipo_iva AS vat, factura_item.* FROM producto JOIN factura_item ON producto.id=factura_item.producto_id WHERE producto.id=3 AND factura_item.factura_numero=3)
		SET producto_iva=producto_subtotal*(vat/100);

	-- item 3
	
INSERT INTO factura_item(ID ,factura_numero,producto_id,producto_qty) VALUES (8,3,2,2);
	UPDATE 
		(SELECT producto.precio AS price, producto.tipo_iva AS vat, factura_item.* FROM producto JOIN factura_item ON producto.id=factura_item.producto_id WHERE producto.id=2 AND factura_item.factura_numero=3)
		SET producto_subtotal=producto_qty*price;
	UPDATE 
		(SELECT producto.precio AS price, producto.tipo_iva AS vat, factura_item.* FROM producto JOIN factura_item ON producto.id=factura_item.producto_id WHERE producto.id=2 AND factura_item.factura_numero=3)
		SET producto_iva=producto_subtotal*(vat/100);

-- c. actualizar factura

	UPDATE factura
		SET factura.subtotal =(SELECT g.valsum suma FROM factura f 
		INNER JOIN (SELECT factura_item.factura_numero,sum(producto_subtotal)valsum
			FROM factura_item WHERE factura_numero=3 GROUP BY factura_numero)g
			ON f.numero=g.factura_numero) WHERE factura.numero=3;
		
		
	UPDATE factura
		SET factura.total_iva =(SELECT g.valsum suma FROM factura f 
		INNER JOIN (SELECT factura_item.factura_numero,sum(producto_iva)valsum
			FROM factura_item WHERE factura_numero=3 GROUP BY factura_numero)g
			ON f.numero=g.factura_numero) WHERE factura.numero=3;

-- factura 4 cliente 2 2 productos
-- a. crear factura

	INSERT INTO factura (numero,cliente_id,fecha) VALUES (4,2,sysdate-7);

-- b. crear items factura
	--- item 1
	
INSERT INTO factura_item(ID ,factura_numero,producto_id,producto_qty) VALUES (9,4,1,3);
	UPDATE 
		(SELECT producto.precio AS price, producto.tipo_iva AS vat, factura_item.* FROM producto JOIN factura_item ON producto.id=factura_item.producto_id WHERE producto.id=1 AND factura_item.factura_numero=4)
		SET producto_subtotal=producto_qty*price;
	UPDATE 
		(SELECT producto.precio AS price, producto.tipo_iva AS vat, factura_item.* FROM producto JOIN factura_item ON producto.id=factura_item.producto_id WHERE producto.id=1 AND factura_item.factura_numero=4)
		SET producto_iva=producto_subtotal*(vat/100);
	-- item 2
INSERT INTO factura_item(ID ,factura_numero,producto_id,producto_qty) VALUES (10,4,5,2);
	UPDATE 
		(SELECT producto.precio AS price, producto.tipo_iva AS vat, factura_item.* FROM producto JOIN factura_item ON producto.id=factura_item.producto_id WHERE producto.id=5 AND factura_item.factura_numero=4)
		SET producto_subtotal=producto_qty*price;
	UPDATE 
		(SELECT producto.precio AS price, producto.tipo_iva AS vat, factura_item.* FROM producto JOIN factura_item ON producto.id=factura_item.producto_id WHERE producto.id=5 AND factura_item.factura_numero=4)
		SET producto_iva=producto_subtotal*(vat/100);


-- c. actualizar factura

	UPDATE factura
		SET factura.subtotal =(SELECT g.valsum suma FROM factura f 
		INNER JOIN (SELECT factura_item.factura_numero,sum(producto_subtotal)valsum
			FROM factura_item WHERE factura_numero=4 GROUP BY factura_numero)g
			ON f.numero=g.factura_numero) WHERE factura.numero=4;
		
		
	UPDATE factura
		SET factura.total_iva =(SELECT g.valsum suma FROM factura f 
		INNER JOIN (SELECT factura_item.factura_numero,sum(producto_iva)valsum
			FROM factura_item WHERE factura_numero=4 GROUP BY factura_numero)g
			ON f.numero=g.factura_numero) WHERE factura.numero=4;

-- factura 5 cliente 2 3 productos
-- a. crear factura

	INSERT INTO factura (numero,cliente_id,fecha) VALUES (5,2,sysdate-6);

-- b. crear items factura
	--- item 1
	
INSERT INTO factura_item(ID ,factura_numero,producto_id,producto_qty) VALUES (11,5,1,5);
	UPDATE 
		(SELECT producto.precio AS price, producto.tipo_iva AS vat, factura_item.* FROM producto JOIN factura_item ON producto.id=factura_item.producto_id WHERE producto.id=1 AND factura_item.factura_numero=5)
		SET producto_subtotal=producto_qty*price;
	UPDATE 
		(SELECT producto.precio AS price, producto.tipo_iva AS vat, factura_item.* FROM producto JOIN factura_item ON producto.id=factura_item.producto_id WHERE producto.id=1 AND factura_item.factura_numero=5)
		SET producto_iva=producto_subtotal*(vat/100);
	-- item 2
INSERT INTO factura_item(ID ,factura_numero,producto_id,producto_qty) VALUES (12,5,3,12);
	UPDATE 
		(SELECT producto.precio AS price, producto.tipo_iva AS vat, factura_item.* FROM producto JOIN factura_item ON producto.id=factura_item.producto_id WHERE producto.id=3 AND factura_item.factura_numero=5)
		SET producto_subtotal=producto_qty*price;
	UPDATE 
		(SELECT producto.precio AS price, producto.tipo_iva AS vat, factura_item.* FROM producto JOIN factura_item ON producto.id=factura_item.producto_id WHERE producto.id=3 AND factura_item.factura_numero=5)
		SET producto_iva=producto_subtotal*(vat/100);
-- item 3
INSERT INTO factura_item(ID ,factura_numero,producto_id,producto_qty) VALUES (13,5,2,6);
	UPDATE 
		(SELECT producto.precio AS price, producto.tipo_iva AS vat, factura_item.* FROM producto JOIN factura_item ON producto.id=factura_item.producto_id WHERE producto.id=2 AND factura_item.factura_numero=5)
		SET producto_subtotal=producto_qty*price;
	UPDATE 
		(SELECT producto.precio AS price, producto.tipo_iva AS vat, factura_item.* FROM producto JOIN factura_item ON producto.id=factura_item.producto_id WHERE producto.id=2 AND factura_item.factura_numero=5)
		SET producto_iva=producto_subtotal*(vat/100);

-- c. actualizar factura

	UPDATE factura
		SET factura.subtotal =(SELECT g.valsum suma FROM factura f 
		INNER JOIN (SELECT factura_item.factura_numero,sum(producto_subtotal)valsum
			FROM factura_item WHERE factura_numero=5 GROUP BY factura_numero)g
			ON f.numero=g.factura_numero) WHERE factura.numero=5;
		
		
	UPDATE factura
		SET factura.total_iva =(SELECT g.valsum suma FROM factura f 
		INNER JOIN (SELECT factura_item.factura_numero,sum(producto_iva)valsum
			FROM factura_item WHERE factura_numero=5 GROUP BY factura_numero)g
			ON f.numero=g.factura_numero) WHERE factura.numero=5;

-- factura 6 cliente 3 1 producto
-- a. crear factura

	INSERT INTO factura (numero,cliente_id,fecha) VALUES (6,3,sysdate-5);

-- b. crear items factura
	--- item 1
	
INSERT INTO factura_item(ID ,factura_numero,producto_id,producto_qty) VALUES (14,6,3,12);
	UPDATE 
		(SELECT producto.precio AS price, producto.tipo_iva AS vat, factura_item.* FROM producto JOIN factura_item ON producto.id=factura_item.producto_id WHERE producto.id=3 AND factura_item.factura_numero=6)
		SET producto_subtotal=producto_qty*price;
	UPDATE 
		(SELECT producto.precio AS price, producto.tipo_iva AS vat, factura_item.* FROM producto JOIN factura_item ON producto.id=factura_item.producto_id WHERE producto.id=3 AND factura_item.factura_numero=6)
		SET producto_iva=producto_subtotal*(vat/100);

-- c. actualizar factura

	UPDATE factura
		SET factura.subtotal =(SELECT g.valsum suma FROM factura f 
		INNER JOIN (SELECT factura_item.factura_numero,sum(producto_subtotal)valsum
			FROM factura_item WHERE factura_numero=6 GROUP BY factura_numero)g
			ON f.numero=g.factura_numero) WHERE factura.numero=6;
		
		
	UPDATE factura
		SET factura.total_iva =(SELECT g.valsum suma FROM factura f 
		INNER JOIN (SELECT factura_item.factura_numero,sum(producto_iva)valsum
			FROM factura_item WHERE factura_numero=6 GROUP BY factura_numero)g
			ON f.numero=g.factura_numero) WHERE factura.numero=6;

-- factura 7 cliente 4 2 productos

-- a. crear factura

	INSERT INTO factura (numero,cliente_id,fecha) VALUES (7,4,sysdate-5);

-- b. crear items factura
	--- item 1
	
INSERT INTO factura_item(ID ,factura_numero,producto_id,producto_qty) VALUES (15,7,2,3);
	UPDATE 
		(SELECT producto.precio AS price, producto.tipo_iva AS vat, factura_item.* FROM producto JOIN factura_item ON producto.id=factura_item.producto_id WHERE producto.id=2 AND factura_item.factura_numero=7)
		SET producto_subtotal=producto_qty*price;
	UPDATE 
		(SELECT producto.precio AS price, producto.tipo_iva AS vat, factura_item.* FROM producto JOIN factura_item ON producto.id=factura_item.producto_id WHERE producto.id=2 AND factura_item.factura_numero=7)
		SET producto_iva=producto_subtotal*(vat/100);
	-- item 2
INSERT INTO factura_item(ID ,factura_numero,producto_id,producto_qty) VALUES (16,7,4,2);
	UPDATE 
		(SELECT producto.precio AS price, producto.tipo_iva AS vat, factura_item.* FROM producto JOIN factura_item ON producto.id=factura_item.producto_id WHERE producto.id=4 AND factura_item.factura_numero=7)
		SET producto_subtotal=producto_qty*price;
	UPDATE 
		(SELECT producto.precio AS price, producto.tipo_iva AS vat, factura_item.* FROM producto JOIN factura_item ON producto.id=factura_item.producto_id WHERE producto.id=4 AND factura_item.factura_numero=7)
		SET producto_iva=producto_subtotal*(vat/100);


-- c. actualizar factura

	UPDATE factura
		SET factura.subtotal =(SELECT g.valsum suma FROM factura f 
		INNER JOIN (SELECT factura_item.factura_numero,sum(producto_subtotal)valsum
			FROM factura_item WHERE factura_numero=7 GROUP BY factura_numero)g
			ON f.numero=g.factura_numero) WHERE factura.numero=7;
		
		
	UPDATE factura
		SET factura.total_iva =(SELECT g.valsum suma FROM factura f 
		INNER JOIN (SELECT factura_item.factura_numero,sum(producto_iva)valsum
			FROM factura_item WHERE factura_numero=7 GROUP BY factura_numero)g
			ON f.numero=g.factura_numero) WHERE factura.numero=7;
		
-- factura 8 cliente 4 3 productos

		-- a. crear factura

	INSERT INTO factura (numero,cliente_id,fecha) VALUES (8,4,sysdate-4);

-- b. crear items factura
	--- item 1
	
INSERT INTO factura_item(ID ,factura_numero,producto_id,producto_qty) VALUES (17,8,6,5);
	UPDATE 
		(SELECT producto.precio AS price, producto.tipo_iva AS vat, factura_item.* FROM producto JOIN factura_item ON producto.id=factura_item.producto_id WHERE producto.id=6 AND factura_item.factura_numero=8)
		SET producto_subtotal=producto_qty*price;
	UPDATE 
		(SELECT producto.precio AS price, producto.tipo_iva AS vat, factura_item.* FROM producto JOIN factura_item ON producto.id=factura_item.producto_id WHERE producto.id=6 AND factura_item.factura_numero=8)
		SET producto_iva=producto_subtotal*(vat/100);
	-- item 2
INSERT INTO factura_item(ID ,factura_numero,producto_id,producto_qty) VALUES (18,8,3,12);
	UPDATE 
		(SELECT producto.precio AS price, producto.tipo_iva AS vat, factura_item.* FROM producto JOIN factura_item ON producto.id=factura_item.producto_id WHERE producto.id=3 AND factura_item.factura_numero=8)
		SET producto_subtotal=producto_qty*price;
	UPDATE 
		(SELECT producto.precio AS price, producto.tipo_iva AS vat, factura_item.* FROM producto JOIN factura_item ON producto.id=factura_item.producto_id WHERE producto.id=3 AND factura_item.factura_numero=8)
		SET producto_iva=producto_subtotal*(vat/100);
-- item 3
INSERT INTO factura_item(ID ,factura_numero,producto_id,producto_qty) VALUES (19,8,8,1);
	UPDATE 
		(SELECT producto.precio AS price, producto.tipo_iva AS vat, factura_item.* FROM producto JOIN factura_item ON producto.id=factura_item.producto_id WHERE producto.id=8 AND factura_item.factura_numero=8)
		SET producto_subtotal=producto_qty*price;
	UPDATE 
		(SELECT producto.precio AS price, producto.tipo_iva AS vat, factura_item.* FROM producto JOIN factura_item ON producto.id=factura_item.producto_id WHERE producto.id=8 AND factura_item.factura_numero=8)
		SET producto_iva=producto_subtotal*(vat/100);

-- c. actualizar factura

	UPDATE factura
		SET factura.subtotal =(SELECT g.valsum suma FROM factura f 
		INNER JOIN (SELECT factura_item.factura_numero,sum(producto_subtotal)valsum
			FROM factura_item WHERE factura_numero=8 GROUP BY factura_numero)g
			ON f.numero=g.factura_numero) WHERE factura.numero=8;
		
		
	UPDATE factura
		SET factura.total_iva =(SELECT g.valsum suma FROM factura f 
		INNER JOIN (SELECT factura_item.factura_numero,sum(producto_iva)valsum
			FROM factura_item WHERE factura_numero=8 GROUP BY factura_numero)g
			ON f.numero=g.factura_numero) WHERE factura.numero=8;


-- factura 9 cliente 4 4 productos

				-- a. crear factura

	INSERT INTO factura (numero,cliente_id,fecha) VALUES (9,4,sysdate-2);

-- b. crear items factura
	--- item 1
	
INSERT INTO factura_item(ID ,factura_numero,producto_id,producto_qty) VALUES (20,9,1,5);
	UPDATE 
		(SELECT producto.precio AS price, producto.tipo_iva AS vat, factura_item.* FROM producto JOIN factura_item ON producto.id=factura_item.producto_id WHERE producto.id=1 AND factura_item.factura_numero=9)
		SET producto_subtotal=producto_qty*price;
	UPDATE 
		(SELECT producto.precio AS price, producto.tipo_iva AS vat, factura_item.* FROM producto JOIN factura_item ON producto.id=factura_item.producto_id WHERE producto.id=1 AND factura_item.factura_numero=9)
		SET producto_iva=producto_subtotal*(vat/100);
	-- item 2
INSERT INTO factura_item(ID ,factura_numero,producto_id,producto_qty) VALUES (21,9,2,4);
	UPDATE 
		(SELECT producto.precio AS price, producto.tipo_iva AS vat, factura_item.* FROM producto JOIN factura_item ON producto.id=factura_item.producto_id WHERE producto.id=2 AND factura_item.factura_numero=9)
		SET producto_subtotal=producto_qty*price;
	UPDATE 
		(SELECT producto.precio AS price, producto.tipo_iva AS vat, factura_item.* FROM producto JOIN factura_item ON producto.id=factura_item.producto_id WHERE producto.id=2 AND factura_item.factura_numero=9)
		SET producto_iva=producto_subtotal*(vat/100);
-- item 3
INSERT INTO factura_item(ID ,factura_numero,producto_id,producto_qty) VALUES (22,9,3,3);
	UPDATE 
		(SELECT producto.precio AS price, producto.tipo_iva AS vat, factura_item.* FROM producto JOIN factura_item ON producto.id=factura_item.producto_id WHERE producto.id=3 AND factura_item.factura_numero=9)
		SET producto_subtotal=producto_qty*price;
	UPDATE 
		(SELECT producto.precio AS price, producto.tipo_iva AS vat, factura_item.* FROM producto JOIN factura_item ON producto.id=factura_item.producto_id WHERE producto.id=3 AND factura_item.factura_numero=9)
		SET producto_iva=producto_subtotal*(vat/100);
	
-- item 4
INSERT INTO factura_item(ID ,factura_numero,producto_id,producto_qty) VALUES (23,9,4,2);
	UPDATE 
		(SELECT producto.precio AS price, producto.tipo_iva AS vat, factura_item.* FROM producto JOIN factura_item ON producto.id=factura_item.producto_id WHERE producto.id=4 AND factura_item.factura_numero=9)
		SET producto_subtotal=producto_qty*price;
	UPDATE 
		(SELECT producto.precio AS price, producto.tipo_iva AS vat, factura_item.* FROM producto JOIN factura_item ON producto.id=factura_item.producto_id WHERE producto.id=4 AND factura_item.factura_numero=9)
		SET producto_iva=producto_subtotal*(vat/100);	

-- c. actualizar factura

	UPDATE factura
		SET factura.subtotal =(SELECT g.valsum suma FROM factura f 
		INNER JOIN (SELECT factura_item.factura_numero,sum(producto_subtotal)valsum
			FROM factura_item WHERE factura_numero=9 GROUP BY factura_numero)g
			ON f.numero=g.factura_numero) WHERE factura.numero=9;
		
		
	UPDATE factura
		SET factura.total_iva =(SELECT g.valsum suma FROM factura f 
		INNER JOIN (SELECT factura_item.factura_numero,sum(producto_iva)valsum
			FROM factura_item WHERE factura_numero=9 GROUP BY factura_numero)g
			ON f.numero=g.factura_numero) WHERE factura.numero=9;


-- factura 10 cliente 4 1 producto

				-- a. crear factura

	INSERT INTO factura (numero,cliente_id,fecha) VALUES (10,4,sysdate-1);

-- b. crear items factura
	--- item 1
	
INSERT INTO factura_item(ID ,factura_numero,producto_id,producto_qty) VALUES (24,10,7,3);
	UPDATE 
		(SELECT producto.precio AS price, producto.tipo_iva AS vat, factura_item.* FROM producto JOIN factura_item ON producto.id=factura_item.producto_id WHERE producto.id=7 AND factura_item.factura_numero=10)
		SET producto_subtotal=producto_qty*price;
	UPDATE 
		(SELECT producto.precio AS price, producto.tipo_iva AS vat, factura_item.* FROM producto JOIN factura_item ON producto.id=factura_item.producto_id WHERE producto.id=7 AND factura_item.factura_numero=10)
		SET producto_iva=producto_subtotal*(vat/100);
	
-- c. actualizar factura

	UPDATE factura
		SET factura.subtotal =(SELECT g.valsum suma FROM factura f 
		INNER JOIN (SELECT factura_item.factura_numero,sum(producto_subtotal)valsum
			FROM factura_item WHERE factura_numero=10 GROUP BY factura_numero)g
			ON f.numero=g.factura_numero) WHERE factura.numero=10;
		
		
	UPDATE factura
		SET factura.total_iva =(SELECT g.valsum suma FROM factura f 
		INNER JOIN (SELECT factura_item.factura_numero,sum(producto_iva)valsum
			FROM factura_item WHERE factura_numero=10 GROUP BY factura_numero)g
			ON f.numero=g.factura_numero) WHERE factura.numero=10;

-- 5. Realizar consultas


-- cliente que realizó la compra más cara

		SELECT nombre, numero AS fra,fecha, total_monto FROM cliente 
		JOIN 
			(SELECT cliente_id,numero,fecha, total_monto, DENSE_RANK() OVER (ORDER BY total_monto DESC) AS rnk FROM factura)rf  
		ON cliente.id=rf.cliente_id 
		WHERE rf.rnk=1;


	
-- cliente que pagó más de 100 de monto

	SELECT nombre, sm.sumamonto FROM cliente 
		JOIN (SELECT cliente_id, sum (total_monto) AS sumamonto FROM factura GROUP BY cliente_id)sm 
		ON cliente.id=sm.cliente_id
		WHERE sm.sumamonto>100 ORDER BY sm.sumamonto desc;

-- cuantos clientes compraron el producto 6

SELECT COUNT (cliente_id) AS num_clientes 
FROM 
	(SELECT cliente_id ,count(pc.producto)FROM factura 
	JOIN
		(SELECT * FROM factura_item 
		JOIN producto ON factura_item.producto_id=producto.id WHERE producto.id=6)pc 
		ON factura.numero=pc.factura_numero GROUP BY cliente_id);