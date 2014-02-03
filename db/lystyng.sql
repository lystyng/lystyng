drop table if exists `user`;
create table `user` (
  id integer primary key auto_increment,
  username varchar(20) not null,
  name varchar(100) not null,
  email varchar(200) not null,
  password char(64) not null
) ENGINE=INNODB CHARSET=utf8;

drop table if exists `list`;
create table list (
  id integer primary key auto_increment,
  title varchar(200) not null,
  slug varchar(200) not null,
  description text,
  user integer not null,
  foreign key (user) references `user`(id)
) ENGINE=INNODB CHARSET=utf8;

drop table if exists `list_item`;
create table list_item (
  id integer primary key auto_increment,
  title varchar(200) not null,
  description text,
  list integer not null,
  foreign key (list) references list(id)
) ENGINE=INNODB CHARSET=utf8;

