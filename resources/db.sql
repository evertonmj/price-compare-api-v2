create table users (id serial primary key, name text, email text, created_at timestamp default current_timestamp);

create user pc_api_user identified by 'pc_api_password';

create database pc_api_db owner pc_api_user;

insert into users (name, email)
values (
           'Everton Mendonca Jesus','evertonmj@gmail.com')