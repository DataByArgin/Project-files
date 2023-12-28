-- create table
create table Nashville_Housing
(
	UniqueID  integer,
	ParcelID varchar(50),
	LandUse varchar(50),
	PropertyAddress varchar(50),
	SaleDate date,
	SalePrice money,
	LegalReference varchar(50),
	SoldAsVacant varchar(50),
	OwnerName varchar(50),
	OwnerAddress varchar(50),
	Acreage numeric,
	TaxDistrict varchar(50),
	LandValue money,
	BuildingValue money,
	TotalValue money,
	YearBuilt integer,
	Bedrooms integer,
	FullBath integer,
	HalfBath integer
);
-- populate property address data
select t1.parcelid, t1.propertyaddress, t2.parcelid, t2.propertyaddress, coalesce(t1.propertyaddress,t2.propertyaddress)
from Nashville_Housing t1
join Nashville_Housing t2
	on t1.parcelid = t2.parcelid
	and t1.uniqueid <> t2.uniqueid

update Nashville_Housing t1
set propertyaddress = coalesce(t1.propertyaddress,t2.propertyaddress)
from Nashville_Housing t2
where t1.parcelid = t2.parcelid
and t1.uniqueid <> t2.uniqueid
-- Breaking out address into individual columns (Address, City, State)
-- Harder way
select
substring(propertyaddress, 1, position(',' in propertyaddress)-1) as address,
substring(propertyaddress, position(',' in propertyaddress)+1, length(propertyaddress)) as City
from Nashville_Housing

alter table Nashville_Housing
add property_split_address varchar(100)

update Nashville_Housing
set property_split_address = substring(propertyaddress, 1, position(',' in propertyaddress)-1)

alter table Nashville_Housing
add property_split_City varchar(100)

update Nashville_Housing
set property_split_City = substring(propertyaddress, position(',' in propertyaddress)+1, length(propertyaddress))

select * from Nashville_Housing
-- easier way
select
split_part(owneraddress,',',1),
split_part(owneraddress,',',2),
split_part(owneraddress,',',3)
from Nashville_Housing

alter table Nashville_Housing
add owner_split_address varchar(100),
add owner_split_city varchar(100),
add owner_split_state varchar(100);

update Nashville_Housing
set owner_split_address = split_part(owneraddress,',',1);
update Nashville_Housing
set owner_split_city = split_part(owneraddress,',',2);
update Nashville_Housing
set owner_split_state = split_part(owneraddress,',',3);
-- Change Y and N to Yes and No in "Sold as vacant" column
select distinct(soldasvacant), count(soldasvacant)
from Nashville_Housing
group by soldasvacant
order by 2;

select soldasvacant,
case when soldasvacant = 'Y' then 'Yes'
	 when soldasvacant = 'N' then 'No'
	 else soldasvacant
	 end
from Nashville_Housing

update Nashville_Housing
set soldasvacant =
case when soldasvacant = 'Y' then 'Yes'
	 when soldasvacant = 'N' then 'No'
	 else soldasvacant
	 end
-- remove duplicates
with RowNumCTE as(
select *,
	row_number() over
		(
			partition by parcelid,
						 propertyaddress,
						 saleprice,
						 saledate,
						 legalreference
						 order by uniqueid
		)	row_num
from Nashville_Housing
)
select *
from RowNumCTE
where row_num=1
-- delete unused columns
alter table Nashville_Housing
drop column owneraddress;