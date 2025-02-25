--Assignment: Indexes, Functions, Stored Procedures, triggers
--Banking System

--Customers table
create table Customers1(
	customerId int primary key,
	customerName varchar(80),
	email varchar(80),
	phoneNumber varchar(80)
);

create table Accounts1(
accountId int primary key,
customerId int,
accountNumber int,
balance decimal(10,2),
accountType varchar(30)
constraint fk_ci foreign key (customerId) references Customers1(customerId),
);

create table Transactions(
transactionId int primary key,
accountId int,
transactionType varchar(30),
amount decimal(10,2),
transactionDate date,
constraint fk_ai foreign key(accountId) references Accounts1(accountId)
);

create table Audit_Transactions(
auditId int primary key,
accountId int,
amount decimal(10,2),
transactionDate date,
action_done varchar(90)
);

INSERT INTO Customers1 (customerId, customerName, email, phoneNumber) VALUES
(1, 'John Doe', 'john.doe@example.com', '123-456-7890'),
(2, 'Jane Smith', 'jane.smith@example.com', '234-567-8901'),
(3, 'Michael Johnson', 'michael.johnson@example.com', '345-678-9012'),
(4, 'Emily Davis', 'emily.davis@example.com', '456-789-0123'),
(5, 'Daniel Brown', 'daniel.brown@example.com', '567-890-1234'),
(6, 'Sophia Wilson', 'sophia.wilson@example.com', '678-901-2345'),
(7, 'James Taylor', 'james.taylor@example.com', '789-012-3456'),
(8, 'Olivia Anderson', 'olivia.anderson@example.com', '890-123-4567'),
(9, 'William Thomas', 'william.thomas@example.com', '901-234-5678'),
(10, 'Ava Jackson', 'ava.jackson@example.com', '012-345-6789');

INSERT INTO Accounts1 (accountId, customerId, accountNumber, balance, accountType) VALUES
(1, 1, 1001, 1500.00, 'Savings'),
(2, 2, 1002, 2500.00, 'Checking'),
(3, 3, 1003, 3500.00, 'Savings'),
(4, 4, 1004, 4500.00, 'Checking'),
(5, 5, 1005, 5500.00, 'Savings'),
(6, 6, 1006, 6500.00, 'Checking'),
(7, 7, 1007, 7500.00, 'Savings'),
(8, 8, 1008, 8500.00, 'Checking'),
(9, 9, 1009, 9500.00, 'Savings'),
(10, 10, 1010, 10500.00, 'Checking');

INSERT INTO Transactions (transactionId, accountId, transactionType, amount, transactionDate) VALUES
(1, 1, 'Deposit', 500.00, '2025-01-01'),
(2, 2, 'Withdrawal', 200.00, '2025-01-02'),
(3, 3, 'Deposit', 300.00, '2025-01-03'),
(4, 4, 'Withdrawal', 400.00, '2025-01-04'),
(5, 5, 'Deposit', 500.00, '2025-01-05'),
(6, 6, 'Withdrawal', 600.00, '2025-01-06'),
(7, 7, 'Deposit', 700.00, '2025-01-07'),
(8, 8, 'Withdrawal', 800.00, '2025-01-08'),
(9, 9, 'Deposit', 900.00, '2025-01-09'),
(10, 10, 'Withdrawal', 1000.00, '2025-01-10');

truncate  
table Transactions;


--Task 1
--1.
create clustered index idx_cls on Accounts1(accountId);
alter table Accounts1 drop constraint PK__Accounts__F267251EA0C6B774;

--2.
create nonclustered index noncls_idx_cst on Customers1(customerName);

--3.
create index composite_idx on Transactions(transactionDate, amount);

--4.
create unique index unq_idx on Accounts1(accountId);

--Task 2
create function scalar_fn(@accId int)
returns Decimal(10,2)
as
begin
	declare @interest decimal(10,2)
	select @interest=balance*0.05 from Accounts1 where accountId=@accId;
	return @interest;
end;

drop function scalar_fn;

select dbo.scalar_fn(8);

--Task 3
create procedure amtTransactions @fromAccId int, @toAccId int, @amount decimal(10,2)
as
begin
	declare @amtInSender decimal(10,2);
	select @amtInSender=balance from Accounts1 where accountId=@fromAccId;
	if(@amtInSender>@amount)
	begin
		update Accounts1 set balance=balance-@amount where accountId=@fromAccId;
		update Accounts1 set balance=balance+@amount where accountId=@toAccId;
		insert into Transactions(transactionId,accountId,transactionType,amount,transactionDate) values(1, @fromAccId, 'withdrawal', @amount, getdate());
	end;
	else
	begin
		print 'Insufficient balace...cannot proceed';
	end;
end;

drop procedure amtTransactions;

exec amtTransactions 9, 10, 800.00;

select * from Transactions;

--Task 4
create trigger validateTransaction
on Accounts1
instead of update
as
begin
	declare @currBalance decimal(10,2);
	select @currBalance=balance from inserted;
	if(@currBalance<=0)
	begin
		print 'Insufficient funds! Transaction aborted.';
	end;
end;

update Accounts1 set balance=0 where accountId=2;

--Task 5
create trigger afterInserttrgr
on Transactions 
after insert
as 
begin
	INSERT INTO Audit_Transactions(accountId, amount, TransactionDate)
    SELECT accountId, amount, transactionDate
    FROM INSERTED;
	print 'Audit_Transactions table updated for the transaction...';
end;

INSERT INTO Transactions (transactionId, accountId, transactionType, amount, transactionDate) VALUES
(22, 1, 'Deposit', 500.00, '2025-01-01');
