--Project for a Hotel Management System
--Part-1:
--1.2.1: Database Design (DDL)

--Customer Table
create table HotelCustomer(
customerId int identity(1,1) primary key,
customerName varchar(80),
email varchar(80),
phone varchar(50),
street VARCHAR(100),
city VARCHAR(50),
customerState VARCHAR(50),
zipCode VARCHAR(10)
);

--Rooms Table
create table HotelRooms(
roomId int primary key,
roomType varchar(70),
pricePerNight decimal(10,2),
roomStatus varchar(20)
);

--Bookings Table
create table HotelBookings(
bookingId int primary key,
customerId int,
roomId int,
checkInDate date,
checkOutDate date,
totalAmount decimal(10,2)
constraint fk_hc foreign key(customerId) references HotelCustomer(customerId),
constraint fk_hr foreign key(roomId) references HotelRooms(roomId),
);

--Paymants Table
create table HotelPayments(
paymantId int primary key,
bookingId int,
paymentDate date,
amount decimal(10,2),
paymentMethod varchar(40),
constraint fk_b foreign key(bookingId) references HotelBookings(bookingId),
);

--Employees Table
CREATE TABLE HotelEmployees (
    employeeId INT PRIMARY KEY,
    empName VARCHAR(70),
    position VARCHAR(40),
    salary DECIMAL(10,2),
    hireDate DATE,
    managerId INT,
    CONSTRAINT fk_selfRef FOREIGN KEY (managerId) REFERENCES HotelEmployees(employeeId)
);

--Services Table 
create table HotelServices(
serviceId int primary key,
serviceName varchar(70),
price decimal(10,2)
);
select * from HotelServices;

--Hotel Branch Table
create table HotelBranches(
branchId int primary key,
branchName varchar(60),
street VARCHAR(100),
city VARCHAR(50),
customerState VARCHAR(50),
zipCode VARCHAR(10)
);

--Services provides for each booking 
create table ServicesForBooking(
serviceId int,
bookingId int,
quantity int,
TotalPrice decimal(10,2),
constraint fk_bs foreign key(bookingId) references HotelBookings(bookingId),
constraint fk_s foreign key(serviceId) references HotelServices(serviceId)
);



--Part-2
--2.Queries using join
--2.2.1.
select c.customerName,b.checkInDate, r.roomType,  b.totalAmount from HotelCustomer c inner join HotelBookings b on c.customerId=b.customerId inner join HotelRooms r on b.roomId=r.roomId;

--2.2.2.
select * from HotelEmployees e inner join HotelEmployees m on e.managerId=m.employeeId;

--2.2.3
select * from HotelRooms where roomId not in (select roomId from HotelBookings);

--3.Subqueries
--2.3.1
select c.customerId,c.customerName from HotelBookings b inner join HotelCustomer c on b.customerId=c.CustomerId  group by c.customerId, c.customerName having count(b.bookingId)>1; 
--using subquery
select distinct customerId from HotelBookings where customerId in(select customerId from HotelBookings group by customerId having count(bookingId)>1);

--2.3.2
select max(totalAmount) from HotelBookings;
--using subquery
select * from HotelBookings where totalAmount=(select max(totalAmount) from HotelBookings);

--4.Views
create view HotelActiveBookings as
select c.customerName, r.roomType, b.checkInDate, b.checkOutdate 
from HotelCustomer c inner join HotelBookings b on c.customerId=b.customerId 
inner join HotelRooms r on b.roomId=r.roomId where r.roomStatus='Occupied';

drop view HotelActiveBookings;

select * from HotelActiveBookings;

--5.Indexing for optimization
create index roomType_idx on HotelRooms(roomType);

create index comp_idx on HotelBookings(checkInDate, checkOutDate);

--6.Stored Proceedures and functions
create procedure RevenueGen @month int
as 
begin
	declare @revenue decimal(10,2);
	select @revenue=sum(totalAmount) from HotelBookings where MONTH(checkInDate)=@month;
	print 'Total revenue :';
	print @revenue;
end;

exec RevenueGen @month=2;

create function noOfDays(@customerId int)
returns int
as
begin
	declare @daysStayed int;
	select @daysStayed=datediff(day, checkInDate, checkOutDate) from HotelBookings where customerId=@customerId;;
	return @daysStayed;
end;

select dbo.noOfDays(6) as DaysStayed;

--7.Triggers
create trigger bookingCancel
on HotelBookings
after delete
as
begin
	update HotelRooms set roomStatus='Available' where roomId in (select roomId from deleted);
	print 'Room status updated';
end;

delete from HotelBookings where BookingId=3;

--trigger on hotel bookings on insert to update room status
create trigger trgr_roomStatusUpdate
on HotelBookings
after insert
as
begin
	update HotelRooms set roomStatus='Occupied' where roomId in (select roomId from inserted);
	print 'Room status updated for booked room!';
end;

drop trigger trgr_roomStatusUpdate;
select * from HotelRooms;
INSERT INTO HotelBookings (bookingId, customerId, roomId, checkInDate, checkOutDate, totalAmount)
VALUES (14, 7, 3, '2025-03-01', '2025-03-03', 500.00);

INSERT INTO HotelBookings (bookingId, customerId, roomId, checkInDate, checkOutDate, totalAmount)
VALUES (16, 7, 1, '2025-03-01', '2025-03-03', 500.00);

--trigger for updating total amount in Bookings table when a service is booked
create trigger bookingSer_trgr
on ServicesForBooking
after insert
as
begin
	declare @payment decimal(10,2);
	declare @qnty int;
	select @payment=(select totalPrice from inserted);
	select @qnty=(select quantity from inserted);
	update HotelBookings set totalAmount=totalAmount+(@payment*@qnty) where bookingId=(select bookingId from inserted);
	print 'Total amount in booking table updated!';
end;

select * from HotelBookings;
select * from ServicesForBooking;
INSERT INTO ServicesForBooking (serviceId, bookingId, quantity, TotalPrice)
VALUES (2, 2, 1, 15.00);
INSERT INTO ServicesForBooking (serviceId, bookingId, quantity, TotalPrice)
VALUES (2, 16, 2, 25);


--Security & privileges

--to see all logins
SELECT name, type_desc, create_date, modify_date
FROM sys.server_principals
WHERE type IN ('S', 'U', 'G');

--user creation
create user HotelAdmin for login test;

--grant access
grant select, update, delete, insert on HotelRooms to HotelAdmin;

--create role
create role HotelManagerNow;
grant select, update, insert, delete on HotelBookings to HotelManager;
grant select, update, insert, delete on HotelPayments to HotelManager;

--Assigning a role to user
alter role HotelManagerNow add member HotelAdmin; 

--execute as HotelAdmin
execute as user='HotelAdmin'
update HotelPayments set amount=8000 where paymantId=1;
revert;

--create role frontDeskStaff
create role frontDeskStaff;
grant select on HotelRooms to frontDeskStaff;


--9. Backup and Restore 
backup database JIBE_Main_Training
to disk='C:\trainingDB.bak'
with format, init, name='full backup of training db';

SELECT name 
FROM sys.databases;

restore database JIBE_Main_Training
from disk='C:\trainingDB.bak'
with replace, recovery;

--10.Full-Text Search
CREATE UNIQUE INDEX ui_roomId ON HotelRooms(roomId);

CREATE FULLTEXT INDEX ON HotelRooms(roomType, roomStatus)
KEY INDEX ui_roomId;

SELECT * 
FROM HotelRooms
WHERE CONTAINS(roomType, 'Suite') AND CONTAINS(roomStatus, 'Available');

create unique index unq_idx_pymt on HotelPayments(paymantId);

create fulltext index on HotelPayments(paymentMethod) key index unq_idx_pymt;

select * from HotelPayments where contains(paymentMethod, 'cash');

select * from HotelCustomer where customerName like 'J%';






INSERT INTO HotelCustomer (customerName, email, phone, street, city, customerState, zipCode)
VALUES ('John Doe', 'john.doe@example.com', '123-456-7890', '123 Elm St', 'Springfield', 'IL', '62701');

INSERT INTO HotelCustomer (customerName, email, phone, street, city, customerState, zipCode)
VALUES ('Jane Smith', 'jane.smith@example.com', '234-567-8901', '456 Oak St', 'Springfield', 'IL', '62702');

INSERT INTO HotelCustomer (customerName, email, phone, street, city, customerState, zipCode)
VALUES ('Alice Johnson', 'alice.johnson@example.com', '345-678-9012', '789 Pine St', 'Chicago', 'IL', '60601');

INSERT INTO HotelCustomer (customerName, email, phone, street, city, customerState, zipCode)
VALUES ('Bob Brown', 'bob.brown@example.com', '456-789-0123', '101 Maple St', 'Chicago', 'IL', '60602');

INSERT INTO HotelCustomer (customerName, email, phone, street, city, customerState, zipCode)
VALUES ('Charlie Davis', 'charlie.davis@example.com', '567-890-1234', '202 Birch St', 'Peoria', 'IL', '61601');

INSERT INTO HotelCustomer (customerName, email, phone, street, city, customerState, zipCode)
VALUES ('Diana Evans', 'diana.evans@example.com', '678-901-2345', '303 Cedar St', 'Peoria', 'IL', '61602');

INSERT INTO HotelCustomer (customerName, email, phone, street, city, customerState, zipCode)
VALUES ('Evan Foster', 'evan.foster@example.com', '789-012-3456', '404 Walnut St', 'Naperville', 'IL', '60540');

INSERT INTO HotelCustomer (customerName, email, phone, street, city, customerState, zipCode)
VALUES ('Fiona Green', 'fiona.green@example.com', '890-123-4567', '505 Chestnut St', 'Naperville', 'IL', '60541');

INSERT INTO HotelCustomer (customerName, email, phone, street, city, customerState, zipCode)
VALUES ('George Harris', 'george.harris@example.com', '901-234-5678', '606 Ash St', 'Evanston', 'IL', '60201');

INSERT INTO HotelCustomer (customerName, email, phone, street, city, customerState, zipCode)
VALUES ('Hannah White', 'hannah.white@example.com', '012-345-6789', '707 Poplar St', 'Evanston', 'IL', '60202');

INSERT INTO HotelRooms (roomId, roomType, pricePerNight, roomStatus)
VALUES (1, 'Single', 75.00, 'Available');

INSERT INTO HotelRooms (roomId, roomType, pricePerNight, roomStatus)
VALUES (2, 'Double', 120.00, 'Occupied');

INSERT INTO HotelRooms (roomId, roomType, pricePerNight, roomStatus)
VALUES (3, 'Suite', 250.00, 'Available');

INSERT INTO HotelRooms (roomId, roomType, pricePerNight, roomStatus)
VALUES (4, 'Single', 75.00, 'Occupied');

INSERT INTO HotelRooms (roomId, roomType, pricePerNight, roomStatus)
VALUES (5, 'Double', 120.00, 'Available');

INSERT INTO HotelRooms (roomId, roomType, pricePerNight, roomStatus)
VALUES (6, 'Suite', 250.00, 'Under Maintenance');

INSERT INTO HotelRooms (roomId, roomType, pricePerNight, roomStatus)
VALUES (7, 'Single', 75.00, 'Available');

INSERT INTO HotelRooms (roomId, roomType, pricePerNight, roomStatus)
VALUES (8, 'Double', 120.00, 'Occupied');

INSERT INTO HotelRooms (roomId, roomType, pricePerNight, roomStatus)
VALUES (9, 'Suite', 250.00, 'Available');

INSERT INTO HotelRooms (roomId, roomType, pricePerNight, roomStatus)
VALUES (10, 'Single', 75.00, 'Occupied');

INSERT INTO HotelRooms (roomId, roomType, pricePerNight, roomStatus)
VALUES (11, 'Single', 111.00, 'Available');

INSERT INTO HotelBookings (bookingId, customerId, roomId, checkInDate, checkOutDate, totalAmount)
VALUES (1, 1, 3, '2025-02-01', '2025-02-05', 1000.00);

INSERT INTO HotelBookings (bookingId, customerId, roomId, checkInDate, checkOutDate, totalAmount)
VALUES (2, 2, 2, '2025-02-10', '2025-02-12', 240.00);

INSERT INTO HotelBookings (bookingId, customerId, roomId, checkInDate, checkOutDate, totalAmount)
VALUES (3, 3, 1, '2025-02-15', '2025-02-16', 75.00);

INSERT INTO HotelBookings (bookingId, customerId, roomId, checkInDate, checkOutDate, totalAmount)
VALUES (4, 4, 4, '2025-02-20', '2025-02-22', 150.00);

INSERT INTO HotelBookings (bookingId, customerId, roomId, checkInDate, checkOutDate, totalAmount)
VALUES (5, 5, 5, '2025-02-25', '2025-02-28', 360.00);

INSERT INTO HotelBookings (bookingId, customerId, roomId, checkInDate, checkOutDate, totalAmount)
VALUES (6, 6, 6, '2025-03-01', '2025-03-03', 500.00);

INSERT INTO HotelBookings (bookingId, customerId, roomId, checkInDate, checkOutDate, totalAmount)
VALUES (7, 7, 7, '2025-03-05', '2025-03-07', 150.00);

INSERT INTO HotelBookings (bookingId, customerId, roomId, checkInDate, checkOutDate, totalAmount)
VALUES (8, 8, 8, '2025-03-10', '2025-03-12', 240.00);

INSERT INTO HotelBookings (bookingId, customerId, roomId, checkInDate, checkOutDate, totalAmount)
VALUES (9, 9, 9, '2025-03-15', '2025-03-18', 750.00);

INSERT INTO HotelBookings (bookingId, customerId, roomId, checkInDate, checkOutDate, totalAmount)
VALUES (10, 10, 10, '2025-03-20', '2025-03-22', 150.00);

INSERT INTO HotelBookings (bookingId, customerId, roomId, checkInDate, checkOutDate, totalAmount)
VALUES (11, 3, 8, '2025-03-29', '2025-03-20', 150.00);

INSERT INTO HotelPayments (paymantId, bookingId, paymentDate, amount, paymentMethod)
VALUES (1, 1, '2025-02-01', 1000.00, 'Credit Card');

INSERT INTO HotelPayments (paymantId, bookingId, paymentDate, amount, paymentMethod)
VALUES (2, 2, '2025-02-10', 240.00, 'Debit Card');

INSERT INTO HotelPayments (paymantId, bookingId, paymentDate, amount, paymentMethod)
VALUES (3, 3, '2025-02-15', 75.00, 'Cash');

INSERT INTO HotelPayments (paymantId, bookingId, paymentDate, amount, paymentMethod)
VALUES (4, 4, '2025-02-20', 150.00, 'Credit Card');

INSERT INTO HotelPayments (paymantId, bookingId, paymentDate, amount, paymentMethod)
VALUES (5, 5, '2025-02-25', 360.00, 'Bank Transfer');

INSERT INTO HotelPayments (paymantId, bookingId, paymentDate, amount, paymentMethod)
VALUES (6, 6, '2025-03-01', 500.00, 'Credit Card');

INSERT INTO HotelPayments (paymantId, bookingId, paymentDate, amount, paymentMethod)
VALUES (7, 7, '2025-03-05', 150.00, 'Cash');

INSERT INTO HotelPayments (paymantId, bookingId, paymentDate, amount, paymentMethod)
VALUES (8, 8, '2025-03-10', 240.00, 'Debit Card');

INSERT INTO HotelPayments (paymantId, bookingId, paymentDate, amount, paymentMethod)
VALUES (9, 9, '2025-03-15', 750.00, 'Credit Card');

INSERT INTO HotelPayments (paymantId, bookingId, paymentDate, amount, paymentMethod)
VALUES (10, 10, '2025-03-20', 150.00, 'Bank Transfer');

INSERT INTO HotelEmployees (employeeId, empName, position, salary, hireDate, managerId)
VALUES (1, 'Alice Johnson', 'General Manager', 85000.00, '2020-01-15', NULL);

INSERT INTO HotelEmployees (employeeId, empName, position, salary, hireDate, managerId)
VALUES (2, 'Bob Smith', 'Assistant Manager', 60000.00, '2021-03-10', 1);

INSERT INTO HotelEmployees (employeeId, empName, position, salary, hireDate, managerId)
VALUES (3, 'Charlie Brown', 'Front Desk Clerk', 35000.00, '2022-05-20', 2);

INSERT INTO HotelEmployees (employeeId, empName, position, salary, hireDate, managerId)
VALUES (4, 'Diana Evans', 'Housekeeping Supervisor', 40000.00, '2019-11-05', 1);

INSERT INTO HotelEmployees (employeeId, empName, position, salary, hireDate, managerId)
VALUES (5, 'Evan Foster', 'Housekeeper', 28000.00, '2023-01-10', 4);

INSERT INTO HotelEmployees (employeeId, empName, position, salary, hireDate, managerId)
VALUES (6, 'Fiona Green', 'Maintenance Supervisor', 45000.00, '2020-07-25', 1);

INSERT INTO HotelEmployees (employeeId, empName, position, salary, hireDate, managerId)
VALUES (7, 'George Harris', 'Maintenance Worker', 32000.00, '2021-09-15', 6);

INSERT INTO HotelEmployees (employeeId, empName, position, salary, hireDate, managerId)
VALUES (8, 'Hannah White', 'Chef', 50000.00, '2018-12-01', 1);

INSERT INTO HotelEmployees (employeeId, empName, position, salary, hireDate, managerId)
VALUES (9, 'Ian Black', 'Waiter', 25000.00, '2022-04-18', 8);

INSERT INTO HotelEmployees (employeeId, empName, position, salary, hireDate, managerId)
VALUES (10, 'Jackie Brown', 'Bartender', 27000.00, '2023-02-20', 8);

INSERT INTO HotelServices (serviceId, serviceName, price)
VALUES (1, 'Room Service', 25.00);

INSERT INTO HotelServices (serviceId, serviceName, price)
VALUES (2, 'Laundry Service', 15.00);

INSERT INTO HotelServices (serviceId, serviceName, price)
VALUES (3, 'Spa Treatment', 100.00);

INSERT INTO HotelServices (serviceId, serviceName, price)
VALUES (4, 'Gym Access', 10.00);

INSERT INTO HotelServices (serviceId, serviceName, price)
VALUES (5, 'Swimming Pool Access', 20.00);

INSERT INTO HotelServices (serviceId, serviceName, price)
VALUES (6, 'Airport Shuttle', 30.00);

INSERT INTO HotelServices (serviceId, serviceName, price)
VALUES (7, 'Breakfast Buffet', 15.00);

INSERT INTO HotelServices (serviceId, serviceName, price)
VALUES (8, 'Parking', 10.00);

INSERT INTO HotelServices (serviceId, serviceName, price)
VALUES (9, 'Wi-Fi', 5.00);

INSERT INTO HotelServices (serviceId, serviceName, price)
VALUES (10, 'Conference Room', 200.00);

INSERT INTO HotelBranches (branchId, branchName, street, city, customerState, zipCode)
VALUES (1, 'Downtown Hotel', '123 Main St', 'Springfield', 'IL', '62701');

INSERT INTO HotelBranches (branchId, branchName, street, city, customerState, zipCode)
VALUES (2, 'Airport Hotel', '456 Airport Rd', 'Chicago', 'IL', '60601');

INSERT INTO HotelBranches (branchId, branchName, street, city, customerState, zipCode)
VALUES (3, 'Beachside Hotel', '789 Ocean Ave', 'Miami', 'FL', '33101');

INSERT INTO HotelBranches (branchId, branchName, street, city, customerState, zipCode)
VALUES (4, 'Mountain Resort', '101 Mountain Rd', 'Denver', 'CO', '80201');

INSERT INTO HotelBranches (branchId, branchName, street, city, customerState, zipCode)
VALUES (5, 'City Center Hotel', '202 Center St', 'New York', 'NY', '10001');

INSERT INTO HotelBranches (branchId, branchName, street, city, customerState, zipCode)
VALUES (6, 'Suburban Hotel', '303 Suburb Ln', 'Dallas', 'TX', '75201');

INSERT INTO HotelBranches (branchId, branchName, street, city, customerState, zipCode)
VALUES (7, 'Lakeside Hotel', '404 Lakeview Dr', 'Orlando', 'FL', '32801');

INSERT INTO HotelBranches (branchId, branchName, street, city, customerState, zipCode)
VALUES (8, 'Historic Hotel', '505 Heritage St', 'Boston', 'MA', '02101');

INSERT INTO HotelBranches (branchId, branchName, street, city, customerState, zipCode)
VALUES (9, 'Business Hotel', '606 Commerce Blvd', 'San Francisco', 'CA', '94101');

INSERT INTO HotelBranches (branchId, branchName, street, city, customerState, zipCode)
VALUES (10, 'Luxury Hotel', '707 Luxury Ln', 'Las Vegas', 'NV', '89101');

INSERT INTO ServicesForBooking (serviceId, bookingId, quantity, TotalPrice)
VALUES (1, 1, 2, 50.00);

INSERT INTO ServicesForBooking (serviceId, bookingId, quantity, TotalPrice)
VALUES (2, 2, 1, 15.00);

INSERT INTO ServicesForBooking (serviceId, bookingId, quantity, TotalPrice)
VALUES (3, 3, 1, 100.00);

INSERT INTO ServicesForBooking (serviceId, bookingId, quantity, TotalPrice)
VALUES (4, 4, 3, 30.00);

INSERT INTO ServicesForBooking (serviceId, bookingId, quantity, TotalPrice)
VALUES (5, 5, 2, 40.00);

INSERT INTO ServicesForBooking (serviceId, bookingId, quantity, TotalPrice)
VALUES (6, 6, 1, 30.00);

INSERT INTO ServicesForBooking (serviceId, bookingId, quantity, TotalPrice)
VALUES (7, 7, 2, 30.00);

INSERT INTO ServicesForBooking (serviceId, bookingId, quantity, TotalPrice)
VALUES (8, 8, 1, 10.00);

INSERT INTO ServicesForBooking (serviceId, bookingId, quantity, TotalPrice)
VALUES (9, 9, 1, 5.00);

INSERT INTO ServicesForBooking (serviceId, bookingId, quantity, TotalPrice)
VALUES (10, 10, 1, 200.00);
