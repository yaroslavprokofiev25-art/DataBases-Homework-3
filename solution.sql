create table customers (
                           customer_id serial primary key,
                           full_name varchar(100) not null,
                           email varchar(100) unique not null,
                           balance numeric(10,2) default 0
);

create table products (
                          product_id serial primary key,
                          product_name varchar(100) not null,
                          price numeric(10,2) not null,
                          stock_quantity int not null
);

create table orders (
                        order_id serial primary key,
                        customer_id int references customers(customer_id),
                        order_date timestamp default current_timestamp,
                        total_amount numeric(10,2) default 0
);

create table order_items (
                             order_item_id serial primary key,
                             order_id int references orders(order_id),
                             product_id int references products(product_id),
                             quantity int not null,
                             price numeric(10,2) not null
);

create table order_log (
                           log_id serial primary key,
                           order_id int,
                           customer_id int,
                           action varchar(50),
                           log_date timestamp default current_timestamp
);


-- task 1
create or replace function calculate_order_total(p_order_id int)
returns numeric (10, 2)
language plpgsql
as $$
declare
    v_total numeric(10,2);
begin
    select coalesce(sum(quantity * price), 0)
    into v_total
    from order_items
    where order_id = p_order_id;

    return v_total;
end;
$$;
--task 2
create or replace procedure create_order(p_customer_id int)
language plpgsql
as $$
begin
    insert into orders (customer_id, total_amount)
    select p_customer_id, 0
    where exists (
        select 1
        from customers
        where customer_id = p_customer_id
    );
end;
$$;

--task 3
create or replace procedure add_product_to_order(
    p_order_id int,
    p_product_id int,
    p_quantity int
)
language plpgsql
as $$
declare
    v_price numeric;
begin
    if p_quantity <= 0 then
        raise exception 'Quantity must be positive';
    end if;

    select price into v_price
    from products
    where product_id = p_product_id and stock_quantity >= p_quantity;

    if not found then raise exception 'Product not found';
    end if;

    insert into order_items (order_id, product_id, quantity, price)
    values (p_order_id, p_product_id, p_quantity, v_price);

    update products
    set stock_quantity = stock_quantity - p_quantity
    where product_id = p_product_id;
end;
$$;

-- task 4
create or replace function trg_update_order_total()
returns trigger
as $$
declare v_order_int;
begin
    -- firslty determinate which order was affected

end;
$$
