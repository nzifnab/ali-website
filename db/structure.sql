SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: ar_internal_metadata; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ar_internal_metadata (
    key character varying NOT NULL,
    value character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: corp_stocks; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.corp_stocks (
    id bigint NOT NULL,
    item text,
    item_type text,
    external_sale_price numeric(15,2),
    desired_stock bigint,
    current_stock bigint DEFAULT 0 NOT NULL,
    corp_member_sale_price numeric(15,2),
    buy_price numeric(15,2),
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    sale_valid boolean DEFAULT false NOT NULL,
    purchase_price_metadata jsonb DEFAULT '{}'::jsonb,
    price_updated_on date,
    blueprint_id integer,
    visible boolean DEFAULT true NOT NULL
);


--
-- Name: corp_stocks_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.corp_stocks_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: corp_stocks_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.corp_stocks_id_seq OWNED BY public.corp_stocks.id;


--
-- Name: line_items; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.line_items (
    id bigint NOT NULL,
    corp_stock_id bigint NOT NULL,
    order_id bigint NOT NULL,
    quantity bigint,
    price numeric(15,2),
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    purchase_price_metadata jsonb DEFAULT '{}'::jsonb,
    blueprint_provided boolean DEFAULT false NOT NULL
);


--
-- Name: line_items_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.line_items_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: line_items_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.line_items_id_seq OWNED BY public.line_items.id;


--
-- Name: orders; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.orders (
    id bigint NOT NULL,
    subtotal numeric(15,2),
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    player_name text,
    token text,
    status text DEFAULT 'pending'::text NOT NULL,
    admin_token text,
    corp_member_type text DEFAULT 'external'::text NOT NULL,
    contract_fee bigint DEFAULT 0 NOT NULL,
    setting_data_id bigint,
    tip numeric(15,2)
);


--
-- Name: orders_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.orders_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: orders_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.orders_id_seq OWNED BY public.orders.id;


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.schema_migrations (
    version character varying NOT NULL
);


--
-- Name: setting_data; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.setting_data (
    id bigint NOT NULL,
    settings jsonb,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: setting_data_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.setting_data_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: setting_data_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.setting_data_id_seq OWNED BY public.setting_data.id;


--
-- Name: corp_stocks id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.corp_stocks ALTER COLUMN id SET DEFAULT nextval('public.corp_stocks_id_seq'::regclass);


--
-- Name: line_items id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.line_items ALTER COLUMN id SET DEFAULT nextval('public.line_items_id_seq'::regclass);


--
-- Name: orders id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.orders ALTER COLUMN id SET DEFAULT nextval('public.orders_id_seq'::regclass);


--
-- Name: setting_data id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.setting_data ALTER COLUMN id SET DEFAULT nextval('public.setting_data_id_seq'::regclass);


--
-- Name: ar_internal_metadata ar_internal_metadata_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ar_internal_metadata
    ADD CONSTRAINT ar_internal_metadata_pkey PRIMARY KEY (key);


--
-- Name: corp_stocks corp_stocks_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.corp_stocks
    ADD CONSTRAINT corp_stocks_pkey PRIMARY KEY (id);


--
-- Name: line_items line_items_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.line_items
    ADD CONSTRAINT line_items_pkey PRIMARY KEY (id);


--
-- Name: orders orders_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.orders
    ADD CONSTRAINT orders_pkey PRIMARY KEY (id);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: setting_data setting_data_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.setting_data
    ADD CONSTRAINT setting_data_pkey PRIMARY KEY (id);


--
-- Name: index_line_items_on_corp_stock_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_line_items_on_corp_stock_id ON public.line_items USING btree (corp_stock_id);


--
-- Name: index_line_items_on_order_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_line_items_on_order_id ON public.line_items USING btree (order_id);


--
-- Name: index_orders_on_setting_data_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_orders_on_setting_data_id ON public.orders USING btree (setting_data_id);


--
-- Name: line_items fk_rails_2dc2e5c22c; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.line_items
    ADD CONSTRAINT fk_rails_2dc2e5c22c FOREIGN KEY (order_id) REFERENCES public.orders(id);


--
-- Name: orders fk_rails_4cd4f0feac; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.orders
    ADD CONSTRAINT fk_rails_4cd4f0feac FOREIGN KEY (setting_data_id) REFERENCES public.setting_data(id);


--
-- Name: line_items fk_rails_5019a7cff8; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.line_items
    ADD CONSTRAINT fk_rails_5019a7cff8 FOREIGN KEY (corp_stock_id) REFERENCES public.corp_stocks(id);


--
-- PostgreSQL database dump complete
--

SET search_path TO "$user", public;

INSERT INTO "schema_migrations" (version) VALUES
('20201127213522'),
('20201127225418'),
('20201127225754'),
('20201129165922'),
('20201129181443'),
('20201129222504'),
('20201130031043'),
('20201130040438'),
('20201203093636'),
('20201203093754'),
('20201205111951'),
('20201208072019'),
('20201208080547'),
('20201209023701'),
('20201209201647'),
('20201231213309'),
('20210114040329'),
('20210114094529'),
('20210906224550');


