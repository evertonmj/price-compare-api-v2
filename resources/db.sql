create table users (id serial primary key, name text, email text, created_at timestamp default current_timestamp);

insert into users (name, email)
values (
           'Everton Mendonca Jesus','evertonmj@gmail.com')