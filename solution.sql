drop table if exists order_log;
drop table if exists order_items;
drop table if exists orders;
drop table if exists products;
drop table if exists customers;


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
-- ця функція повертатиме загальну суму замовлень, але якщо воно порожнє то 0
language plpgsql
as $$
begin
    return (
        select coalesce(sum(quantity * price), 0)
        from order_items
        where order_id = p_order_id
    );
end;
$$;

--task 2
create or replace procedure create_order(p_customer_id int)
language plpgsql
    -- ця процедура робить нове замовлення, але якщо клієнта не існує то нічого не зробить
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
create or replace procedure add_product_to_order( -- ця процедура додає товар до замовлення і робить чек кількості
    p_order_id int,
    p_product_id int,
    p_quantity int
)
language plpgsql
as $$

begin
    if p_quantity <= 0 then
        raise exception 'Quantity must be positive';
    end if;
    if not exists (
        select 1 from products
        where product_id = p_product_id and stock_quantity >= p_quantity
    ) then
        raise exception 'Product not found';
    end if;
    insert into order_items (order_id, product_id, quantity, price)
    select p_order_id, p_product_id, p_quantity, price
    from products
    where product_id = p_product_id;
    update products
    set stock_quantity = stock_quantity - p_quantity
    where product_id = p_product_id;
end;
$$;

-- task 4 тут тригер(чи тригерна функція) перераховує загальну суму ордера за допомогою task 1
create or replace function trg_update_order_total() -- спочатку функція з логікою
returns trigger -- ну це відпоівдно вказує що функція буде використовуватись як тригерна
language plpgsql
as $$
begin
    update orders
    set total_amount = calculate_order_total(
                       case when tg_op = 'DELETE' then old.order_id else new.order_id end
                       )
    where order_id = case when tg_op = 'DELETE' then old.order_id else new.order_id end;
    return null;
end;
$$;

drop trigger if exists update_order_total on order_items;
create trigger update_order_total -- потім тригер який її викликає
    -- він спрацьовує після якої-небудь зміни в order_items
after insert or update or delete on order_items
for each row execute function trg_update_order_total();


--task 5
create or replace function trg_log_new_order()
returns trigger
language plpgsql -- ця функція записує лог після створення замовлення
as $$
begin
    insert into order_log (order_id, customer_id, action, log_date)
    values (new.order_id, new.customer_id, 'Order_Created', current_timestamp);

    return new;
end;
$$;

drop trigger if exists log_new_order on orders;
create trigger log_new_order
after insert on orders -- і тут тригер спрацьовує після вставлення в таблицю з ордерами
for each row execute function trg_log_new_order();


--task 6

truncate order_log, order_items, orders, products, customers restart identity cascade;

-- create customers
insert into customers (full_name, email)
values ('Alice', 'alice@mail.com'),
       ('Bob', 'bob@mail.com');

-- create products
insert into products (product_name, price, stock_quantity)
values ('Laptop', 999.99, 10),
       ('Mouse', 25.50, 50);

-- створив ордери через процедуру
call create_order(1);
call create_order(2);

-- додав товари через процедуру
call add_product_to_order(1, 1, 2);
call add_product_to_order(1, 2, 3);

-- перевірив в ордері загальну кількість
select order_id, total_amount from orders;

-- чи правильно зменшився залишок
select product_id, product_name, stock_quantity from products;

-- і чек ордер логу
select * from order_log;
