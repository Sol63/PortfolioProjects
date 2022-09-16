/* CLEANING DATA IN SQL QUERIES */

SELECT * 
FROM PortfolioProjects..NashvilleHousing
order by ParcelID



-- EDIT SALE DATE 

Select SaleDateConverted, convert(Date, SaleDate)
FROM PortfolioProjects..NashvilleHousing

Update NashvilleHousing
SET SaleDate = convert(Date, SaleDate)

Alter Table NashvilleHousing
Add SaleDateConverted Date;

Update NashvilleHousing
SET SaleDateConverted = convert(Date, SaleDate)



-- FILL UP EMPTY PROPERTYADDRESS CELLS

Select *
FROM PortfolioProjects..NashvilleHousing
--where PropertyAddress is null
order by ParcelID

 
Select a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.propertyaddress, b.PropertyAddress)
FROM PortfolioProjects..NashvilleHousing a
join PortfolioProjects..NashvilleHousing b
	on a.ParcelID = b.ParcelID
	and a.[UniqueID ] <> b.[UniqueID ]
where a.PropertyAddress is null

Update a
SET PropertyAddress = ISNULL(a.propertyaddress, b.PropertyAddress)
FROM PortfolioProjects..NashvilleHousing a
join PortfolioProjects..NashvilleHousing b
	on a.ParcelID = b.ParcelID
	and a.[UniqueID ] <> b.[UniqueID ]
where a.PropertyAddress is null



-- BREAKING OUT ADDRESS INTO INDIVIDUAL COLUMNS (ADDRESS, CITY, STATE)

Select PropertyAddress
FROM PortfolioProjects..NashvilleHousing

	-- there is a comma between the address and the city so let's split them

Select
SUBSTRING(Propertyaddress, 1, CHARINDEX(',', propertyaddress)-1) as Address
, SUBSTRING(Propertyaddress, CHARINDEX(',', propertyaddress)+1, LEN(PropertyAddress)) as City 
FROM PortfolioProjects..NashvilleHousing

Alter Table NashvilleHousing
Add PropertySplitAddress nvarchar(255);

Update NashvilleHousing
SET PropertySplitAddress = SUBSTRING(Propertyaddress, 1, CHARINDEX(',', propertyaddress)-1)

Alter Table NashvilleHousing
Add PropertySplitCity nvarchar(255);

Update NashvilleHousing
SET PropertySplitCity = SUBSTRING(Propertyaddress, CHARINDEX(',', propertyaddress)+1, LEN(PropertyAddress))


Select OwnerAddress
FROM PortfolioProjects..NashvilleHousing
-- the owner address is divided in 3 parts par commas so let's split them up

Select 
PARSENAME(REPLACE(owneraddress,',', '.'),3)
, PARSENAME(REPLACE(owneraddress,',', '.'),2)
, PARSENAME(REPLACE(owneraddress,',', '.'),1)
FROM PortfolioProjects..NashvilleHousing

Alter Table NashvilleHousing
Add OwnerSplitAddress nvarchar(255);

Update NashvilleHousing
SET OwnerSplitAddress = PARSENAME(REPLACE(owneraddress,',', '.'),3)

Alter Table NashvilleHousing
Add OwnerSplitCity nvarchar(255);

Update NashvilleHousing
SET OwnerSplitCity = PARSENAME(REPLACE(owneraddress,',', '.'),2)

Alter Table NashvilleHousing
Add OwnerSplitState nvarchar(255);

Update NashvilleHousing
SET OwnerSplitState = PARSENAME(REPLACE(owneraddress,',', '.'),1)



-- in the column 'sold as vacant', the values are either Yes, No, Y or N. Let's group de Yes with the Y and the Nos with the N

Select Distinct(SoldAsVacant), COUNT(SoldAsVacant)
FROM PortfolioProjects..NashvilleHousing
group by SoldAsVacant
order by 2

Select SoldAsVacant
, CASE When SoldAsVacant = 'Y' THEN 'Yes'
		When SoldAsVacant = 'N' THEN 'No'
		ELSE SoldAsVacant
		END
FROM PortfolioProjects..NashvilleHousing


Update NashvilleHousing
SET SoldAsVacant = CASE When SoldAsVacant = 'Y' THEN 'Yes'
		When SoldAsVacant = 'N' THEN 'No'
		ELSE SoldAsVacant
		END



-- Remove the duplicates
	
WITH RowNumCTE AS(
Select *,
	ROW_NUMBER() OVER (
	PARTITION BY	parcelID,
					PropertyAddress,
					SalePrice,
					SaleDate,
					LegalReference
					ORDER by UniqueID
					) row_num

FROM PortfolioProjects..NashvilleHousing
)
DELETE
FROM RowNumCTE
where row_num > 1



-- Delete Unused Columns

ALTER TABLE NashvilleHousing
DROP COLUMN OwnerAddress, TaxDistrict,PropertyAddress

ALTER TABLE NashvilleHousing
DROP COLUMN SaleDate



-- let's check the results :)

Select *
FROM PortfolioProjects..NashvilleHousing
order by parcelID
