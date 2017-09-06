USE [KPI_App]
GO

/****** Object:  StoredProcedure [dbo].[_KPI_CustContractPricing]    Script Date: 08/30/2017 15:40:57 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



-- =============================================
-- Author:		Adnan Faizi
-- Create date: 1/4/2017
-- Description:	Accepts ContractID and updates ItemCust and Item CustPrices Tables based on ProductCodes and Customer Number
-- =============================================
CREATE PROCEDURE [dbo].[_KPI_CustContractPricing]

	@ContractID NVARCHAR(15)	
AS
BEGIN
	DECLARE @sContractBasis AS VARCHAR (10);
	DECLARE @sContractRule AS VARCHAR(10);
    DECLARE @sCustomerID AS VARCHAR(8);
	DECLARE @sFamilyCode AS VARCHAR(10);
	DECLARE @sItem AS VARCHAR (10);
	DECLARE @ItemUoM AS NVARCHAR (3);
	DECLARE @dEffectDate AS DATETIME
	
	SET @dEffectDate = '2016-07-01 00:00:00'
	
	SET NOCOUNT ON;

    /* OUTER CURSOR BEGINS */
	DECLARE ContractPricing CURSOR FOR
	SELECT 
		CM.[ContractBasis], 
		CF.[DiscountRule], 
		CC.[CustomerID],
		CF.[FamilyCode]
	FROM _KPI_ContractMaster CM
	LEFT JOIN _KPI_ContractCustomers CC on CM.[ContractID] = CC.[ContractID] 
	LEFT JOIN _KPI_ContractFamily CF on CM.[ContractID] = CF.[ContractID]
	Where CM.[ContractID] = @ContractID
		
	OPEN ContractPricing	
		-- Get next record from cursor
		FETCH NEXT FROM ContractPricing INTO @sContractBasis, @sContractRule, @sCustomerID, @sFamilyCode
		-- Check if either CustomerID is NULL - No update if it is
		IF (@sCustomerID <> '')
			WHILE (@@FETCH_STATUS = 0)
			BEGIN
				DECLARE FamilyCodeItems CURSOR FOR
				SELECT [Item],
				       [u_m] 
				FROM [ITEM_MST] WHERE [Family_Code] = @sFamilyCode
				OPEN FamilyCodeItems
				FETCH NEXT FROM FamilyCodeItems INTO @sItem, @ItemUoM				
					IF NOT EXISTS (SELECT * FROM ITEMCUST_MST WHERE [cust_num] = @sCustomerID and [item] = @sItem)
						WHILE (@@FETCH_STATUS = 0)
						BEGIN
							-- Insert values in Table 1
							INSERT INTO ITEMCUST_MST ([site_ref], [uf_contractid], [item], [cust_num], [u_m])
							VALUES ('KPI', @ContractID, @sItem, SUBSTRING(@sCustomerID,1,7), @ItemUoM)   			
							-- Insert values in Table 2			
							INSERT INTO ITEMCUSTPRICE_MST ([site_ref], [uf_contractid], [item], [cust_num], [effect_date], [brk_qty##1], [base_code##1], [brk_price##1],[dol_percent##1])
							VALUES ('KPI', @ContractID, @sItem, substring(@sCustomerID,1,7), @dEffectDate, '1', @sContractBasis, @sContractRule, 'P')
							--  next item for the inner loop
							FETCH NEXT FROM familyCodeItems INTO @sItem, @ItemUoM
						END
					ELSE
						FETCH NEXT FROM FamilyCodeItems INTO @sItem, @ItemUoM
				CLOSE FamilyCodeItems;
				DEALLOCATE FamilyCodeItems;						
				-- get the next item for the outer loop
				FETCH NEXT FROM ContractPricing INTO @sContractBasis, @sContractRule, @sCustomerID, @sFamilyCode
			END
	CLOSE ContractPricing;
	DEALLOCATE ContractPricing;
END


GO


