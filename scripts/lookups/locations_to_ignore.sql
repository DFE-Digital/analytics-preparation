create table if not exists locations_to_ignore (
	id serial primary key,
	value varchar(64) not null
);


insert into locations_to_ignore(value) values ('ST1 6BD');

create unique index if not exists locations_to_ignore_values on locations_to_ignore(value);
