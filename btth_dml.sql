create schema btth_ss7;
use btth_ss7;
create table if not exists category(
    id int primary key auto_increment,
    name varchar(100) not null ,
    status tinyint default 1, check ( status in (0,1))
);
create table if not exists author(
    id int primary key auto_increment,
    name varchar(100) not null unique ,
    totalbook int default 0
);
create table if not exists book(
    id int primary key auto_increment,
    name varchar(150) not null ,
    status tinyint default 1 check ( status in (0,1) ),
    price float not null check ( price >= 100000 ),
    createddate date default (now()),
    categoryid int not null ,
    authorid int not null
);
create table if not exists customer(
    id int primary key auto_increment,
    name varchar(150) not null ,
    email varchar(150) not null unique check ( email like '%@gmail.com' or '%@facebook.com' or '%@bachkhoaaptech.edu.vn'),
    phone varchar(50) not null unique ,
    address varchar(255),
    createddate date default (now()),
    gender tinyint not null check ( gender in (0,1,2)),
    birthday date not null
);
DELIMITER $$
create trigger if not exists tg_before_insert_customer_createddate
    before insert on customer
    for each row
    begin
     if NEW.createddate < curdate() then
         signal sqlstate '45000'
         set message_text = 'Ngay tao phai lon hon hoac bang ngay hien tai';
     end if ;
    end ;
DELIMITER ;
create table if not exists ticket (
    id int primary key auto_increment,
    customerid int not null ,
    status tinyint default 1 check ( status in (0,1,2,3)),
    ticketdate datetime default (now())
);
create table if not exists ticketdetail(
    ticketid int not null ,
    bookid int not null ,
    quantity int not null check ( quantity >0 ),
    deposiprice float not null ,
    rentcost float not null
);
DELIMITER $$
create trigger if not exists tg_before_insert_ticketdetail_deposiprice
    before insert on ticketdetail
    for each row
    begin
        declare book_price float;
        select book.price into book_price from book where id = NEW.bookid;
        if NEW.deposiprice <> book_price then
            signal sqlstate '45000'
            set message_text = 'Phai bang gia sach';
        end if ;
    end $$
    DELIMITER ;
DELIMITER $$
create trigger tg_before_insert_ticketdetail_rentcost
    before insert on ticketdetail
    for each row
begin
    declare book_price float;
    select book.price into book_price from book where id = NEW.bookid;
    if NEW.rentcost <> book_price*0.1 then
        signal sqlstate '45000'
            set message_text = 'Phai bang 10% gia sach';
    end if ;
end $$
DELIMITER ;
ALTER table book
add constraint fk_book_categoryid foreign key (categoryid) references category(id),
add constraint fk_book_authorid foreign key (authorid) references author(id);
ALTER table ticket
add constraint fk_ticket_customerid foreign key (customerid) references customer(id);
ALTER table ticketdetail
add constraint fk_ticketdetail_ticketid foreign key (ticketid) references ticket(id),
add constraint fk_ticketdetail_bookid foreign key (bookid) references book(id),
add constraint pk_ticketdetail primary key (ticketid,bookid);
INSERT INTO category (name, status)
VALUES ('Fiction', 1),
       ('Science', 1),
       ('History', 1),
       ('Cooking', 1),
       ('Self-Help', 1);
INSERT INTO author (name)
VALUES ('Jane Doe'),
       ('John Smith'),
       ('Emily Brown'),
       ('Michael Johnson'),
       ('Sarah Wilson');
-- Bản ghi dữ liệu phù hợp với các bảng khác, ví dụ:
INSERT INTO book (name, status, price, categoryid, authorid)
VALUES ('The Great Gatsby', 1, 150000, 1, 1),
       ('Cosmos', 1, 180000, 2, 4),
       ('World History', 1, 120000, 3, 2),
       ('Italian Cooking', 1, 200000, 4, 3),
       ('Mindset', 1, 130000, 5, 5),
       ('To Kill a Mockingbird', 1, 140000, 1, 1),
       -- Thêm thêm bản ghi tương tự để đạt số lượng yêu cầu
       ('The Universe in a Nutshell', 1, 160000, 2, 4),
       ('American Revolution', 1, 110000, 3, 2),
       ('Asian Cuisine', 1, 190000, 4, 3),
       ('The Power of Habit', 1, 135000, 5, 5),
       -- Thêm thêm bản ghi tương tự để đạt số lượng yêu cầu
       ('1984', 1, 125000, 1, 1),
       ('A Brief History of Time', 1, 170000, 2, 4),
       ('World War II', 1, 115000, 3, 2),
       ('French Cuisine', 1, 210000, 4, 3),
       ('Atomic Habits', 1, 145000, 5, 5);
INSERT INTO customer (name, email, phone, address, gender, birthday)
VALUES ('Alice Smith', 'alice@gmail.com', '123456789', '123 Main St', 1, '1990-05-15'),
       ('Bob Johnson', 'bob@gmail.com', '987654321', '456 Oak St', 0, '1985-08-20'),
       ('Charlie Brown', 'charlie@facebook.com', '555555555', '789 Elm St', 1, '1988-11-10');
-- Thêm bản ghi vào Bảng Ticket (3 bản ghi)
INSERT INTO ticket (customerid, status, ticketdate)
VALUES (1, 1, curdate()),
       (2, 1, curdate()),
       (3, 1, curdate());

-- Thêm bản ghi vào Bảng TicketDetail cho từng Ticket (mỗi phiếu mượn có ít nhất 2 cuốn sách với số lượng khác nhau)
-- Ticket 1
INSERT INTO ticketdetail (ticketid, bookid, quantity, deposiprice, rentcost)
VALUES (1, 1, 1, 150000, 15000),
       (1, 3, 2, 120000, 12000);

-- Ticket 2
INSERT INTO ticketdetail (ticketid, bookid, quantity, deposiprice, rentcost)
VALUES (2, 2, 3, 180000, 18000),
       (2, 4, 1, 200000, 20000);

-- Ticket 3
INSERT INTO ticketdetail (ticketid, bookid, quantity, deposiprice, rentcost)
VALUES (3, 5, 2, 130000, 13000),
       (3, 6, 1, 140000, 14000);

