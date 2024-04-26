# 1.	Lấy ra danh sách Book có sắp xếp giảm dần theo Price gồm các cột sau: Id, Name, 	Price, Status, CategoryName, AuthorName, CreatedDate
select b.Id, b.Name, b.Price, b.Status, c.name CategoryName, a.name AuthorName, b.CreatedDate
from book b
         join btth_ss7.author a on a.id = b.authorid
         join btth_ss7.category c on c.id = b.categoryid
order by b.price desc;
# 2.	Lấy ra danh sách Category gồm: Id, Name, TotalProduct, Status (Trong đó cột Status nếu = 0, Ẩn, = 1 là Hiển thị )
select c.id,
       c.name,
       count(b.id) TotalProduct,
       case c.status
           when 0 then 'An'
           when 1 then 'Hien thi'
           end     Status
from category c
         join btth_ss7.book b on c.id = b.categoryid
group by c.id, c.name, c.status;
# 3.	Truy vấn danh sách Customer gồm: Id, Name, Email, Phone, Address, CreatedDate, Gender, BirthDay, Age (Age là cột suy ra từ BirthDay, Gender nếu = 0 là Nam, 1 là Nữ,2 là khác )
select Id,
       Name,
       Email,
       Phone,
       Address,
       CreatedDate,
       Gender,
       BirthDay,
       year(curdate()) - year(birthday) Age
from customer;
# 4.	Truy vấn xóa Author chưa có sách nào
delete
from author
where author.id not in (select book.authorid from book);
# 5.	Cập nhật Cột ToalBook trong bảng Auhor = Tổng số Book của mỗi Author theo Id của Author
update author as a
set a.totalbook = (select count(*) from book where authorid = a.id)
where a.id in (select book.authorid from book);
# 1.	View v_getBookInfo thực hiện lấy ra danh sách các Book được mượn nhiều hơn 3 cuốn
create view v_getBookInfo as
select *
from book b
         join (select bookid, sum(quantity) as book_num
               from ticketdetail
               group by bookid) as count_book on b.id = count_book.bookid
where book_num >= 3;
select *
from v_getBookInfo;
# 2.	View v_getTicketList hiển thị danh sách Ticket gồm: Id, TicketDate, Status, CusName, Email, Phone,TotalAmount (Trong đó TotalAmount là tổng giá trị tiện phải trả, cột Status nếu = 0 thì hiển thị Chưa trả, = 1 Đã trả, = 2 Quá hạn, 3 Đã hủy)
create view v_getTicketList as

select t.Id,
       t.TicketDate,
       c.name                                           CusName,
       c.email                                          Email,
       c.phone                                          Phone,
       sum(rentcost) + sum(deposiprice) TotalAmount,
       case t.status
           when 0 then 'Chua tra'
           when 1 then 'Da tra'
           when 2 then 'Qua han'
           when 3 then 'Da huy'
           end                                          Status
from ticket t
         join btth_ss7.ticketdetail t2 on t.id = t2.ticketid
         join btth_ss7.customer c on c.id = t.customerid
group by c.name, t.TicketDate, t.Status, t.Id, c.email, c.phone;
select *
from v_getTicketList;
# 1.	Thủ tục addBookInfo thực hiện thêm mới Book, khi gọi thủ tục truyền đầy đủ các giá trị của bảng Book ( Trừ cột tự động tăng )
DELIMITER $$
create procedure  addBookInfo(namein varchar(150), statusin tinyint, pricein float, categoryidin int,
                                           authoridin int)
begin
    insert into book(name, status, price, categoryid, authorid)
    values (namein, statusin, pricein, categoryidin, authoridin);
end $$
DELIMITER ;
# a.	Thủ tục getTicketByCustomerId hiển thị danh sách đơn hàng của khách hàng theo Id khách hàng gồm
# : Id, TicketDate, Status, TotalAmount (Trong đó cột Status nếu =0 Chưa trả, = 1  Đã trả, = 2 Quá hạn, 3 đã hủy ),
# Khi gọi thủ tục truyền vào id cuả khách hàng
DELIMITER $$
create procedure  getTicketByCustomerId(cusidin int)
begin
    select t.Id
         , t.TicketDate
         , case t.Status
               when 0 then 'Chua tra'
               when 1 then 'Da tra'
               when 2 then 'Qua han'
               when 3 then 'Da huy'
        end Status
         ,  sum(rentcost) + sum(deposiprice) TotalAmount
    from ticket t
             join btth_ss7.ticketdetail t2 on t.id = t2.ticketid
    where customerid=cusidin
    group by t.Id, t.TicketDate, case t.Status
               when 0 then 'Chua tra'
               when 1 then 'Da tra'
               when 2 then 'Qua han'
               when 3 then 'Da huy'
        end ;
    end $$
        DELIMITER ;
        call getTicketByCustomerId(1);
# 2.	Thủ tục getBookPaginate lấy ra danh sách sản phẩm có phân trang gồm: Id, Name, Price, Sale_price, Khi gọi thủ tuc truyền vào limit và page
DELIMITER $$
create procedure getBookPaginate(limitnum int, pagenum int)
begin
    declare offset_value int;
    set offset_value = pagenum*limitnum;
    select * from book limit offset_value,limitnum;
end $$
DELIMITER ;
call getBookPaginate(5,1);
# 1.	Tạo trigger tr_Check_total_book_author sao cho khi thêm Book nếu Author đang tham chiếu có tổng số sách > 5 thì không cho thêm mưới và thông báo “Tác giả này có số lượng sách đạt tới giới hạn 5 cuốn, vui long chọn tác giả khác”
DELIMITER $$
create trigger tr_Check_total_book_author
    before insert on book
    for each row
    begin
        declare count_book int;
        select count(book.id)into count_book from book where authorid = NEW.authorid;
        if count_book > 5 then
            signal sqlstate '45000'
            set message_text = 'Tác giả này có số lượng sách đạt tới giới hạn 5 cuốn, vui long chọn tác giả khác';
        end if ;
    end $$
    DELIMITER ;
# 2.	Tạo trigger tr_Update_TotalBook khi thêm mới Book thì cập nhật cột TotalBook rong bảng Author = tổng của Book theo AuthorId
DELIMITER $$
create trigger tr_Update_TotalBook
    after insert on book
    for each row
    begin
        declare totalb int ;
        select author.totalbook into  totalb from author where author.id = NEW.authorid;
        update author
        set totalbook =totalb+1 where id = NEW.authorid;
    end $$
    DELIMITER ;


