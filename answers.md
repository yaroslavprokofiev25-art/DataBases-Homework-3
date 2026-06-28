
1. What is the difference between a function and a procedure in PostgreSQL?
    Функція завжди повертає значення і виконується в sql запиті. Процедура не повертає значення і викликається не в запиті, а через "call". Процедурою добре підходить для вставок або аптейтів даних
2. Can a trigger be executed manually? Why or why not?
    Ні, бо тригер автоматично запускається у відповідь на якусь певну подію. 
3. What are the advantages and disadvantages of storing business logic inside the database?
    Перевага в тому, що зменшується потік даних між бд та застосунком
    Недолік це мабуть те, що коли занадто багато логіки в середині бд то це може зробити її дуже складною для розуміння і відповідно тестувати та підтримувати також

    
    
## +1 за аналіз запиту

explain analyze
select
    oi.order_id,
    p.product_name,
    oi.quantity,
    oi.price,
    oi.quantity * oi.price as item_total
from order_items oi
join products p on oi.product_id = p.product_id
where oi.order_id = 1;

## Виконання: 

Hash Join  (cost=27.09..41.32 rows=7 width=274) (actual time=0.850..0.855 rows=2.00 loops=1)
  Hash Cond: (p.product_id = oi.product_id)
  Buffers: shared hit=2 dirtied=1
  ->  Seq Scan on products p  (cost=0.00..13.00 rows=300 width=222) (actual time=0.055..0.056 rows=2.00 loops=1)
        Buffers: shared hit=1
  ->  Hash  (cost=27.00..27.00 rows=7 width=28) (actual time=0.675..0.676 rows=2.00 loops=1)
        Buckets: 1024  Batches: 1  Memory Usage: 9kB
        Buffers: shared hit=1 dirtied=1
        ->  Seq Scan on order_items oi  (cost=0.00..27.00 rows=7 width=28) (actual time=0.501..0.503 rows=2.00 loops=1)
              Filter: (order_id = 1)
              Buffers: shared hit=1 dirtied=1
Planning:
  Buffers: shared hit=170
Planning Time: 4.530 ms
Execution Time: 1.380 ms

## Пояснення:

В цьому випадку PostgreSQL використовує Squential Scan на обох таблицях бо індексів на них немає. Для з'єднання використався Hash join, тобто postgre зробив хеш-таблицю з products і порівнює з нею кожен рядок з order_items. Фільтр order_id = 1 працює під час сканування order_items
