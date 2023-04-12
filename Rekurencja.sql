--Creating database for test

drop table if exists Employees
create table Employees 
(
    employee_id int primary key,
    first_name varchar(50) NOT NULL,
    last_name varchar(50) NOT NULL,
    manager_id int,
);

insert into Employees(employee_id, first_name, last_name, manager_id)
values 
    (1, 'John', 'Doe', NULL),
    (2, 'Jane', 'Smith', 1),
    (3, 'BOb', 'Johnson', 1),
    (4, 'Mary', 'Jones', 2),
    (5, 'Tom', 'DAVIS', 2),
    (6, 'Amy', 'BrowN', 3),
    (7, 'Mike', 'Green', 15),
    (8, 'Samantha', 'White',6),
    (9, ' Alex', 'Black', 4),
    (10, 'David', 'Lee', 5),
    (11, 'Emily ', 'W ang', 7),
    (12, 'Frank', 'Chen', 2),
    (13, 'Grace', ' Kim', 3),
    (14, 'Hannah', 'Nguyen', 13),
    (15, 'Isaac', 'Garcia', 6);


Select *
from Rekurencja.dbo.Employees

--Data Cleanig

Select
first_name,
trim(first_name),
last_name,
replace(last_name,' ','')
From Rekurencja.dbo.Employees

Update Employees
set first_name = trim(first_name)

Update Employees
set last_name = replace(last_name,' ','')

Select
first_name,
upper(substring(first_name,1,1)) + lower(substring(first_name,2,len(first_name)-1)),
last_name,
upper(substring(last_name,1,1)) + lower(substring(last_name,2,len(last_name)-1))
From Rekurencja.dbo.Employees

Update Employees
SET first_name = upper(substring(first_name,1,1)) + lower(substring(first_name,2,len(first_name)-1))

Update Employees
SET last_name = upper(substring(last_name,1,1)) + lower(substring(last_name,2,len(last_name)-1))


Select *
from Rekurencja.dbo.Employees

-- simple recursive

with numbers as
	(
	Select 1 as n
	Union all
	Select n+1
	From numbers where n<15
	)
Select *
From numbers

--all employees under manager

with emp_hierarchy as
(
	Select employee_id, first_name, manager_id, 1 as lvl
	from Rekurencja.dbo.Employees where first_name = 'Bob'
	Union all
	Select rek.employee_id, rek.first_name, rek.manager_id, emp.lvl +1 as lvl
	From emp_hierarchy emp
	join Rekurencja.dbo.Employees rek on emp.employee_id = rek.manager_id
)
select * 
from emp_hierarchy
order by lvl

--all managers over employee

with emp_hierarchy as
(
	Select employee_id, first_name, manager_id, 1 as lvl
	from Rekurencja.dbo.Employees where employee_id = 7
	Union all
	Select rek.employee_id, rek.first_name, rek.manager_id, emp.lvl +1 as lvl
	From emp_hierarchy emp
	join Rekurencja.dbo.Employees rek on emp.manager_id = rek.employee_id
)
select emp2.employee_id, emp2.first_name, rek2.first_name, emp2.lvl
from emp_hierarchy emp2
	join Rekurencja.dbo.Employees rek2 on rek2.employee_id = emp2.manager_id

order by lvl

--hierarchy chain
declare @id int = 1, @max int = max(15)
drop table if exists #hierarchytable
create table #hierarchytable (hierarchy nvarchar(255))
while @id <= @max
Begin
with emp_hierarchy as
(
	Select employee_id, first_name, manager_id
	from Rekurencja.dbo.Employees where employee_id = @id
	Union all
	Select rek.employee_id, rek.first_name, rek.manager_id
	From emp_hierarchy emp
	join Rekurencja.dbo.Employees rek on emp.manager_id = rek.employee_id
)
insert into #hierarchytable
select STRING_AGG(first_name,' -> ') as hierarchy
from emp_hierarchy 
Set @id += 1
End
Select *
from #hierarchytable

Select *from Employees






select * from Rekurencja.dbo.Employees


