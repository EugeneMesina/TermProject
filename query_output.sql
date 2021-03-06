-- 1. List the customers. For each customer, indicate which category he or she fall into, and his or her contact information.
SELECT FirstName, LastName, 'Individual' AS 'Customer Type',Phone, Email
From Individual 
inner join Customer using(CustomerID)
UNION
SELECT CorpName AS 'FirstName', 'Corp' AS 'LastName', 'Corporation' AS 'Customer Type',Phone,Email
FROM Corporation
inner join Customer using(CustomerID)
order by LastName asc, FirstName asc;
#VERSION 2
SELECT FirstName, LastName, 'N/A' AS 'Corporation Name','Individual' AS 'Customer Type',Phone, Email
From Individual 
inner join Customer using(CustomerID)
UNION
SELECT 'N/A' AS 'FirstName', 'N/A' AS 'LastName',CorpName AS 'Corporation Name', 'Corporation' AS 'Customer Type',Phone,Email
FROM Corporation
inner join Customer using(CustomerID);

-- 2. For each service visit, list the total cost to the customer for that visit.
(select DateOrdered, Customer.CustomerID, OwnedVehicle.VinNumber, RepairOrderID, ServiceItemID, Service as 'Order Name', Sum(Cost) as 'Cost' from Customer inner join OwnedVehicle using(CustomerID) inner join RepairOrder on
OwnedVehicle.VinNumber = RepairOrder.VinNumbers inner join RepairLine using(RepairOrderID) inner join ServiceItem using(ServiceItemID) inner join 
IndividualService using(ServiceItemID) group by DateOrdered, CustomerID)
union
(select DateOrdered, Customer.CustomerID, OwnedVehicle.VinNumber, RepairOrderID, ServiceItemID, PackageTitle as 'Order Name', Sum(Cost) as 'Cost' from Customer inner join OwnedVehicle using(CustomerID) inner join RepairOrder on
OwnedVehicle.VinNumber = RepairOrder.VinNumbers inner join RepairLine using(RepairOrderID) inner join ServiceItem using(ServiceItemID) inner join 
MaintenancePackage on ServiceItem.ServiceitemID = MaintenancePackage.MaintenancePackageID group by DateOrdered, CustomerID) order by RepairOrderID;

-- 3. List the top three customers in terms of their net spending for the past two years, and the total
-- that they have spent in that period.
select A.Year, CustomerID, Sum(Cost) from 
((select  Year(RepairDate) as 'Year', Customer.CustomerID, Sum(Cost) as 'Cost' from Customer inner join OwnedVehicle using(CustomerID) inner join RepairOrder on
OwnedVehicle.VinNumber = RepairOrder.VinNumbers inner join RepairLine using(RepairOrderID) inner join ServiceItem using(ServiceItemID) inner join 
IndividualService using(ServiceItemID) group by CustomerID )
union
(select Year(RepairDate) as 'Year', Customer.CustomerID,  Sum(Cost) as 'Cost' from Customer inner join OwnedVehicle using(CustomerID) inner join RepairOrder on
OwnedVehicle.VinNumber = RepairOrder.VinNumbers inner join RepairLine using(RepairOrderID) inner join ServiceItem using(ServiceItemID) inner join 
MaintenancePackage on ServiceItem.ServiceitemID = MaintenancePackage.MaintenancePackageID group by CustomerID )) as A group by CustomerID
having (Year(Curdate()) - A.Year) <= 2;
-- Note. Because of the data we choosed in our insert, there will be no result. To confirm this, if you change <= 2 to <= 3, it will give results

-- 4. Find all of the mechanics who have three or more skills.
SELECT EFirstName, ELastName, count(certificateID) AS 'Number of Skills'
FROM Employee	
inner join EmploymentTime using(EmployeeID)
inner join Mechanic on MechanicInstance=EmployeeInstance
inner join TempCertificate using(MechanicInstance)
group by EFirstName, ELastName
HAVING count(CertificateID)>3
order by 'Number of Skills' desc;


-- 5. Find all of the mechanics who have three or more skills in common.
Select DISTINCT M.EF1, M.EL1, M.EF2, M.EL2, count(*) AS 'NUMBER OF SKILLS'
From
	(Select S.EFirstName as'EF1', S.ELastName as'EL1', G.EFirstName as 'EF2',G.ELastName as'EL2'
				  From  (SELECT DISTINCT EFirstName,ELastName,CertificateID,A.EmployeeID FROM Employee A
						inner join EmploymentTime B on A.EmployeeID=B.EmployeeID
						inner join Mechanic C on C.MechanicInstance=B.EmployeeInstance
						inner join TempCertificate D on D.MechanicInstance=C.MechanicInstance) S
						join
						(SELECT DISTINCT EFirstName,ELastName,CertificateID,A.EmployeeID FROM Employee A
						inner join EmploymentTime B on A.EmployeeID=B.EmployeeID
						inner join Mechanic C on C.MechanicInstance=B.EmployeeInstance
						inner join TempCertificate D on D.MechanicInstance=C.MechanicInstance) G
				where S.EmployeeID != G.EmployeeID and S.CertificateID=G.CertificateID) M
                group by M.EF1, M.EL1, M.EF2, M.EL2
                Having count(*)>3
                order by count(*);

-- 6. For each maintenance package, list the total cost of the maintenance package, as well as a list of
-- all of the maintenance items within that package.
select PackageTitle as 'Package Title', MaintenancePackage.cost as 'Package Total Cost', IndividualService.Service as 'Package Part'
from MaintenancePackage inner join ServicePackageLine using(MaintenancePackageID) 
	inner join ServiceItem using(ServiceItemID) 
inner join IndividualService using(ServiceItemID) order by PackageTitle;

-- 7. Find all of those mechanics who have one or more maintenance items that they lacked one or
-- more of the necessary skills.
select MechanicInstance, count(CertificateID) as 'Certificate Count' from Mechanic inner join TempCertificate using(MechanicInstance)
inner join Certificate using(CertificateID) group by MechanicInstance having count(CertificateID) != 
(select count(CertificateNeeded) from IndividualService);

-- 8. List the customers, sorted by the number of loyalty points that they have, from largest to
-- smallest.
select CustomerID, FirstName, LastName, LoyaltyPoints from Individual inner join Customer using(CustomerID) 
inner join Contracted using(CustomerID) inner join SteadyCustomer using(CustomerID) order by LoyaltyPoints desc;

-- 9. The premier customers and the difference between what they have paid in the past year, versus
-- the services that they actually used during that same time. List from the customers with the
-- largest difference to the smallest.
(select  Year(RepairDate) as 'Year',PremiumCustomer.CustomerID,PremiumCustomer.AnnualFee- Sum(Cost) as 'CostDifference' from PremiumCustomer inner join Contracted using (CustomerID) inner join Customer using (CustomerID) inner join OwnedVehicle using(CustomerID) inner join RepairOrder on
OwnedVehicle.VinNumber = RepairOrder.VinNumbers inner join RepairLine using(RepairOrderID) inner join ServiceItem using(ServiceItemID) inner join 
IndividualService using(ServiceItemID)
where year(RepairDate) = (SELECT YEAR(DATE(NOW()-INTERVAL 1 year)))
group by CustomerID 
order by CostDifference ASC)
union
(select  Year(RepairDate) as 'Year',PremiumCustomer.CustomerID,PremiumCustomer.AnnualFee- Sum(Cost) as 'CostDifference' from PremiumCustomer inner join Contracted using (CustomerID) inner join Customer using (CustomerID) inner join OwnedVehicle using(CustomerID) inner join RepairOrder on
OwnedVehicle.VinNumber = RepairOrder.VinNumbers inner join RepairLine using(RepairOrderID) inner join ServiceItem using(ServiceItemID)inner join 
MaintenancePackage on ServiceItem.ServiceitemID = MaintenancePackage.MaintenancePackageID where year(RepairDate) = (SELECT YEAR(DATE(NOW()-INTERVAL 1 year)))
group by CustomerID 
order by CostDifference ASC);
-- 10. Report on the steady customers based on the net profit that we have made from them over the
-- past year, and the dollar amount of that profit, in order from the greatest to the least.
select CustomerID, amountSpent-SUM(Cost), amountSpent
FROM
	(select  Year(RepairDate) as 'Years', Customer.CustomerID, Sum(Cost) as 'Cost' 
	from SteadyCustomer 
	inner join Contracted using (CustomerID)
	inner join Customer using (CustomerID)
	inner join OwnedVehicle using(CustomerID) 
	inner join RepairOrder on OwnedVehicle.VinNumber = RepairOrder.VinNumbers 
	inner join RepairLine using(RepairOrderID) 
	inner join ServiceItem using(ServiceItemID) 
	inner join IndividualService using(ServiceItemID) group by CustomerID,Years
	UNION
	select Year(RepairDate) as 'Years', SteadyCustomer.CustomerID,  Sum(Cost) as 'Cost'
	from SteadyCustomer 
	inner join Contracted using (CustomerID)
	inner join Customer using (CustomerID)
	inner join OwnedVehicle using(CustomerID) 
	inner join RepairOrder on OwnedVehicle.VinNumber = RepairOrder.VinNumbers 
	inner join RepairLine using(RepairOrderID)
	inner join ServiceItem using(ServiceItemID) 
	inner join MaintenancePackage on ServiceItem.ServiceitemID = MaintenancePackage.MaintenancePackageID
	group by CustomerID,Years) B
    inner join SteadyCustomer USING(CustomerID)
	group by CustomerID
    order by amountSpent desc
;
-- 11. List the three suppliers who have supplied us the largest number of parts (not total quantity of
-- parts, but the largest number of distinct parts) over the past year.
SELECT DISTINCT Supplier.SupplierName, count(PartName)
FROM Supplier
inner join PartCatalog using (SupplierName)
group by SupplierName
order by count(PartName) desc
limit 3;
-- 12. List the five suppliers who have supplied us the largest dollar value of parts in the past year.
SELECT DISTINCT SupplierName , cost
From Supplier
inner join PartCatalog using (SupplierName)
order by cost desc
Limit 5;

-- 13. Find the mechanic who is mentoring the most other mechanics. List the skills that the mechanic
-- is passing along to the other mechanics.

Select DISTINCT MechanicID, MentorFirstName,MentorLastName, ServiceType 
from   Mechanic_mentor_v 
inner join TempCertificate on MechanicID= MechanicInstance
inner join Certificate using(CertificateID)
inner join MentorShip on MechanicID=MentorShip.MentorInstance
Where MechanicID =(
			SELECT MechanicID FROM(
				  SELECT MechanicID,MentorFirstName ,MentorLastName,MAX(NumberofMentee) as 'NumberofMentee'
				  FROM (SELECT MechanicID,MentorFirstName, MentorLastName, count(*) as 'NumberofMentee'
						FROM Mechanic_mentor_v
						group by MentorFirstName, MentorLastName)t
			)s
		) and TempCertificate.CertificateID=MentorShip.CertificateID;
	
	
-- 14. Find the three skills that have the fewest mechanics who have those skills.
SELECT ServiceType , count(MechanicInstance)
From Certificate
inner join TempCertificate using (CertificateID)
Group by ServiceType
Having count(MechanicInstance)
order by count(MechanicInstance) asc
limit 3;
-- 15. List the employees who are both service technicians as well as mechanics.
SELECT EFirstName, ELastName, EmployeeID
From Employee
inner join EmploymentTime using (EmployeeID)
inner join Mechanic on EmployeeInstance=MechanicInstance
where EmployeeID in (
		SELECT EmployeeID
		From Employee
		inner join EmploymentTime using (EmployeeID)
		inner join ServiceTechnician on EmployeeInstance=ServiceTechnicianInstance
    );
-- 16. Three additional queries that demonstrate the five additional business rules. Feel free to create
-- additional views to support these queries if you so desire.

#attempted insert of RepairOrder into Holiday
insert into RepairOrder(RepairOrderID,DateOrdered,RepairDate,VinNumbers,ServiceTechnicianInstance )
values(20, '2015-12-31',  '2016-1-1', 13,10);

#attempted insert into repairLine where employee works on something they are not
#qualified for
insert into RepairLine(ServiceitemID,RepairOrderID,MechanicInstance)
value(25,20,1);


#shows loyaltyPoints
Select * From SteadyCustomer;