/* PROYECTO PERSONAL - PRIMERA FASE */

-- ============================================================
-- PROJECT: Customer Intelligence & Loyalty Analytics — Fashion Retail
-- DATABASE: MySQL
-- VERSION: 1.0
-- DESCRIPCIÓN: DDL completo con 8 tablas, constraints y relaciones
-- ============================================================

CREATE DATABASE IF NOT EXISTS fashion_retail_db
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE fashion_retail_db;

-- ============================================================
-- TABLA 1: stores (15 filas)
-- Se crea antes que customers y transactions porque ambas la referencian
-- ============================================================
CREATE TABLE stores (
    store_id       INT            NOT NULL AUTO_INCREMENT,
    store_name     VARCHAR(100)   NOT NULL,
    city           VARCHAR(80)    NOT NULL,
    country        VARCHAR(60)    NOT NULL,
    store_type     ENUM('flagship','corner','outlet','online') NOT NULL,
    opening_date   DATE           NOT NULL,
    size_sqm       DECIMAL(8,2)       NULL COMMENT 'NULL para tiendas online',

    CONSTRAINT pk_stores PRIMARY KEY (store_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


-- ============================================================
-- TABLA 2: customers (150 filas)
-- ============================================================
CREATE TABLE customers (
    customer_id        INT           NOT NULL AUTO_INCREMENT,
    first_name         VARCHAR(60)   NOT NULL,
    last_name          VARCHAR(60)   NOT NULL,
    email 			   VARCHAR(100) NOT NULL UNIQUE,
    gender             ENUM('M','F','Non-binary','Prefer not to say') NOT NULL,
    age                TINYINT UNSIGNED  NOT NULL,
    city               VARCHAR(80)   NOT NULL,
    country            VARCHAR(60)   NOT NULL,
    registration_date  DATE          NOT NULL,
    loyalty_tier       ENUM('Bronze','Silver','Gold') NOT NULL DEFAULT 'Bronze',
    acquisition_channel ENUM('store','online') NOT NULL,
    email_opt_in       TINYINT(1)    NOT NULL DEFAULT 1 COMMENT '1=sí, 0=no',
    preferred_store_id INT           NULL COMMENT 'FK a stores, puede ser NULL',

    CONSTRAINT pk_customers      PRIMARY KEY (customer_id),
    CONSTRAINT fk_cust_store     FOREIGN KEY (preferred_store_id)
                                   REFERENCES stores(store_id)
                                   ON DELETE SET NULL
                                   ON UPDATE CASCADE,
    CONSTRAINT chk_age           CHECK (age BETWEEN 16 AND 100)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


-- ============================================================
-- TABLA 3: products (60 filas)
-- ============================================================
CREATE TABLE products (
    product_id    INT             NOT NULL AUTO_INCREMENT,
    product_name  VARCHAR(150)    NOT NULL,
    category      ENUM('bags','shoes','ready-to-wear','accessories','fragrances') NOT NULL,
    subcategory   VARCHAR(80)         NULL,
    unit_cost     DECIMAL(10,2)   NOT NULL,
    unit_price    DECIMAL(10,2)   NOT NULL,
    brand_line    ENUM('main','diffusion','exclusive') NOT NULL DEFAULT 'main',
    season        VARCHAR(20)         NULL COMMENT 'ej: SS2026, FW2026',

    CONSTRAINT pk_products       PRIMARY KEY (product_id),
    CONSTRAINT chk_price_margin  CHECK (unit_price >= unit_cost)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


-- ============================================================
-- TABLA 4: campaigns (10 filas)
-- Se crea antes que transactions y campaign_responses
-- ============================================================
CREATE TABLE campaigns (
    campaign_id      INT            NOT NULL AUTO_INCREMENT,
    campaign_name    VARCHAR(150)   NOT NULL,
    campaign_type    ENUM('email','sms','event','push','direct mail') NOT NULL,
    start_date       DATE           NOT NULL,
    end_date         DATE           NOT NULL,
    target_segment   VARCHAR(100)       NULL COMMENT 'ej: Bronze, clientes inactivos',
    budget           DECIMAL(12,2)      NULL,
    objective        ENUM('reactivation','upsell','loyalty','acquisition') NOT NULL,

    CONSTRAINT pk_campaigns      PRIMARY KEY (campaign_id),
    CONSTRAINT chk_camp_dates    CHECK (end_date >= start_date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


-- ============================================================
-- TABLA 5: transactions (450 filas)
-- ============================================================
CREATE TABLE transactions (
    transaction_id   INT             NOT NULL AUTO_INCREMENT,
    customer_id      INT             NOT NULL,
    store_id         INT             NOT NULL,
    transaction_date DATETIME        NOT NULL,

    total_amount     DECIMAL(10,2)   NOT NULL
                     COMMENT 'Importe final del ticket después de descuentos',
    discount_applied DECIMAL(10,2)   NOT NULL DEFAULT 0.00,
    payment_method   ENUM('credit_card','debit_card','cash','gift_card','online_payment') NOT NULL,
    channel          ENUM('in-store','online','phone') NOT NULL,
    campaign_id      INT 			 NULL COMMENT 'NULL si la compra no procede de una campaña',

    CONSTRAINT pk_transactions 	 PRIMARY KEY (transaction_id),
    CONSTRAINT fk_trans_cust 	 FOREIGN KEY (customer_id)
								 REFERENCES customers(customer_id)
								 ON DELETE RESTRICT
								 ON UPDATE CASCADE,
    CONSTRAINT fk_trans_store    FOREIGN KEY (store_id)
								 REFERENCES stores(store_id)
								 ON DELETE RESTRICT
								 ON UPDATE CASCADE,
    CONSTRAINT fk_trans_campaign  FOREIGN KEY (campaign_id)
								  REFERENCES campaigns(campaign_id)
								  ON DELETE SET NULL
								  ON UPDATE CASCADE,
    CONSTRAINT chk_total_amount   CHECK (total_amount >= 0),
    CONSTRAINT chk_discount       CHECK (discount_applied BETWEEN 0 AND total_amount)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


-- ============================================================
-- TABLA 6: transaction_items (900 filas)
-- ============================================================
CREATE TABLE transaction_items (
    item_id          INT             NOT NULL AUTO_INCREMENT,
    transaction_id   INT             NOT NULL,
    product_id       INT             NOT NULL,
    quantity         SMALLINT UNSIGNED NOT NULL DEFAULT 1,
    unit_price       DECIMAL(10,2)   NOT NULL COMMENT 'Precio real en el momento de compra',
    line_total       DECIMAL(10,2)   NOT NULL COMMENT 'quantity * unit_price',

    CONSTRAINT pk_transaction_items  PRIMARY KEY (item_id),
    CONSTRAINT fk_items_transaction  FOREIGN KEY (transaction_id)
                                       REFERENCES transactions(transaction_id)
                                       ON DELETE CASCADE
                                       ON UPDATE CASCADE,
    CONSTRAINT fk_items_product      FOREIGN KEY (product_id)
                                       REFERENCES products(product_id)
                                       ON DELETE RESTRICT
                                       ON UPDATE CASCADE,
    CONSTRAINT chk_quantity          CHECK (quantity > 0),
    CONSTRAINT chk_line_total        CHECK (line_total >= 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


-- ============================================================
-- TABLA 7: campaign_responses (200 filas)
-- ============================================================
CREATE TABLE campaign_responses (
    response_id          INT            NOT NULL AUTO_INCREMENT,
    campaign_id          INT            NOT NULL,
    customer_id          INT            NOT NULL,
    sent_date            DATE           NOT NULL,
    opened               TINYINT(1)     NOT NULL DEFAULT 0,
    clicked              TINYINT(1)     NOT NULL DEFAULT 0,
    converted            TINYINT(1)     NOT NULL DEFAULT 0,
    revenue_attributed   DECIMAL(10,2)  NULL COMMENT 'NULL si converted = 0',

    CONSTRAINT pk_campaign_responses PRIMARY KEY (response_id),
    CONSTRAINT fk_resp_campaign      FOREIGN KEY (campaign_id)
                                       REFERENCES campaigns(campaign_id)
                                       ON DELETE CASCADE
                                       ON UPDATE CASCADE,
    CONSTRAINT fk_resp_customer      FOREIGN KEY (customer_id)
                                       REFERENCES customers(customer_id)
                                       ON DELETE CASCADE
                                       ON UPDATE CASCADE,
    -- Un cliente no puede aparecer dos veces en la misma campaña
    CONSTRAINT uq_campaign_customer  UNIQUE (campaign_id, customer_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


-- ============================================================
-- TABLA 8: returns (80 filas)
-- ============================================================
CREATE TABLE returns (
    return_id           INT             NOT NULL AUTO_INCREMENT,
    transaction_id      INT             NOT NULL,
    customer_id         INT             NOT NULL,
    product_id          INT             NOT NULL,
    return_date         DATE            NOT NULL,
    quantity_returned   SMALLINT UNSIGNED  NOT NULL DEFAULT 1,
    refund_amount       DECIMAL(10,2)   NOT NULL,
    return_reason       ENUM('size','defect','preference','gift', 'other') NOT NULL,
    return_channel      ENUM('in-store', 'online') NOT NULL,
    refund_method       ENUM('original_payment', 'store_credit') NOT NULL,

    CONSTRAINT pk_returns        	PRIMARY KEY (return_id),
    CONSTRAINT fk_ret_transaction   FOREIGN KEY (transaction_id)
									REFERENCES transactions(transaction_id)
									ON DELETE RESTRICT
									ON UPDATE CASCADE,
    CONSTRAINT fk_ret_customer      FOREIGN KEY (customer_id)
									REFERENCES customers(customer_id)
									ON DELETE RESTRICT
									ON UPDATE CASCADE,
    CONSTRAINT fk_ret_product       FOREIGN KEY (product_id)
									REFERENCES products(product_id)
									ON DELETE RESTRICT
									ON UPDATE CASCADE,
    CONSTRAINT chk_refund_amount    CHECK (refund_amount >= 0),
    CONSTRAINT chk_qty_returned     CHECK (quantity_returned > 0)

) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


-- ============================================================
-- ÍNDICES adicionales (mejoran performance en JOINs y filtros)
-- ============================================================

-- transactions: filtros frecuentes
CREATE INDEX idx_trans_date        ON transactions (transaction_date);
CREATE INDEX idx_trans_channel     ON transactions (channel);

-- transaction_items: JOINs por transacción y producto
CREATE INDEX idx_items_product     ON transaction_items (product_id);

-- returns: filtros por fecha y razón
CREATE INDEX idx_ret_date          ON returns (return_date);
CREATE INDEX idx_ret_reason        ON returns (return_reason);

-- Índices añadidos como buena práctica para escalabilidad futura.
-- Con el volumen actual del proyecto no son estrictamente necesarios.