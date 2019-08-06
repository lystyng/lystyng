drop table if exists `user`;
create table `user` (
  id integer primary key auto_increment,
  username varchar(20) not null,
  name varchar(100) not null,
  email varchar(200) not null,
  password char(64) not null,
  verify char(32) null
) ENGINE=INNODB CHARSET=utf8;

drop table if exists `password_reset`;
create table password_reset (
  id integer primary key auto_increment,
  code varchar(255) not null,
  user_id integer not null,
  expires datetime not null default current_timestamp,
  foreign key (user_id) references user(id)
) ENGINE=InnoDB CHARSET=utf8;

delimiter //
create trigger insert_date before insert on password_reset
for each row
begin
  set new.expires = date_add(now(), interval 12 hour);
end;
//
delimiter ;

drop table if exists `friendship`;
create table `friendship` (
  user1 integer not null,
  user2 integer not null,
  primary key (user1, user2),
  foreign key (user1) references `user`(id),
  foreign key (user2) references `user`(id)
) ENGINE=INNODB CHARSET=utf8;

drop table if exists `list`;
create table list (
  id integer primary key auto_increment,
  title varchar(200) not null,
  slug varchar(200) not null,
  description text,
  is_todo boolean,
  privacy enum('private', 'friends', 'public'),
  user integer not null,
  foreign key (user) references `user`(id)
) ENGINE=INNODB CHARSET=utf8;

drop table if exists `tag`;
create table tag (
  id integer primary key auto_increment,
  name varchar(200) not null
) ENGINE=INNODB CHARSET=utf8;

drop table if exists `list_tag`;
create table list_tag (
  id integer primary key auto_increment,
  list integer not null,
  tag integer not null,
  foreign key (list) references list(id),
  foreign key (tag) references tag(id)
) ENGINE=INNODB CHARSET=utf8;

drop table if exists `list_item`;
create table list_item (
  id integer primary key auto_increment,
  title varchar(200) not null,
  description text,
  list integer not null,
  seq_no integer not null,
  foreign key (list) references list(id)
) ENGINE=INNODB CHARSET=utf8;

