/****** Object:  StoredProcedure [dbo].[KPI_GetTaxCodeDefaultFromCustomerSp]    Script Date: 12/06/2017 12:06:38 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


/***************************************************************************\
* TLC Group, Inc. 
*
* Author: Laurence Ledford
*
* Program Name: dbo.KPI_GetTaxCodeDefaultFromCustomerSp
* Program Type: Stored Procedure
* Initial Program Version: N/A
* Initial Date: 09/29/2017
*     Comments: Extend GetTaxCodeDefaultsSp functionality
*
* ID		Date		INI	Description
* ------	----------	---	---------------------------------------- 
* TLCG01	09/29/2017	LKL	Initial Version - Check Customer record for Tax Code before defaulting from Tax System
*
\***************************************************************************/
CREATE PROCEDURE [dbo].[KPI_GetTaxCodeDefaultFromCustomerSp] (
  @CustNum			CustNumType = NULL
, @TaxCode1         TaxCodeType = NULL OUTPUT
, @TaxCode2         TaxCodeType = NULL OUTPUT
, @TaxCodeFound     ListYesNoType = 0 OUTPUT
, @Infobar          InfobarType = NULL OUTPUT
) AS
 
DECLARE
     @Severity             INT

SET @Severity = 0 
SET @Infobar = NULL
SET @TaxCodeFound = 0

IF @TaxCodeFound = 0
   SELECT
		 @TaxCode1 = c.tax_code1
		,@TaxCode2 = c.tax_code2
		,@TaxCodeFound = 1
   FROM customer c
   WHERE cust_num = @CustNum AND cust_seq = 0

-- Taken from GetTaxCodeDefaultsSp
IF @TaxCodeFound = 0
BEGIN
   SELECT @TaxCode1 = def_tax_code
   FROM tax_system
   WHERE tax_system = 1

   SELECT @TaxCode2 = def_tax_code
   FROM tax_system
   WHERE tax_system = 2
END