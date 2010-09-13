create table frames 
(
pkframeID int unsigned not null auto_increment primary key,
labID int unsigned default null,
createdDate timestamp not null default CURRENT_TIMESTAMP,
upc varchar(25) not null default '',
vendorID varchar (10) not null default '',
vendorName varchar(25) not null default '',
model varchar(12) not null default '',
color varchar(12) not null default '',
eye varchar(10) default null,
bridge varchar(10) default null,
a varchar(10) default null,
b varchar(10) default null,
ed varchar(10) default null,
dbl varchar(10) default null,
INDEX (labID)
);