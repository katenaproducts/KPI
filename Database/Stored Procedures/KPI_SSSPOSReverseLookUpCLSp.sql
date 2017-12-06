USE [KPI2_App]
GO

/****** Object:  StoredProcedure [dbo].[KPI_SSSPOSReverseLookUpCLSp]    Script Date: 12/06/2017 11:56:05 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

/***************************************************************************\
* TLC Group, Inc. 
*
* Author: Laurence Ledford
*
* Program Name: dbo.KPI_SSSPOSReverseLookUpCLSp
* Program Type: Stored Procedure
* Initial Program Version: SSSPOSReverseLookUpCLSp.sp 2
* Initial Date: 12/05/2017
*     Comments: Extension for POS Reverse Lookup
*
* ID		Date		INI	Description
* ------	----------	---	---------------------------------------- 
* TLCG01	12/05/2017	LKL	Initial Version - Add ability to filter on CO #
*
\***************************************************************************/
CREATE PROCEDURE [dbo].[KPI_SSSPOSReverseLookUpCLSp]
 @CustNum    CustNumType
,@CustSeq    CustSeqType
,@SerNum     SerNumType
,@POSNum     POSMNumType
,@CashDrawer POSMDrawerType
,@PartnerID  FSPartnerType
,@UserName   UserNameType
,@CoNum		 CoNumType -- TLCG01
AS
 
DECLARE @OrdType POSMOrdTypeType

SET @POSNum = dbo.ExpandKyByType('POSMNumType', @POSNum)
SET @CustNum = dbo.ExpandKyByType('CustNumType', @CustNum)
SET @CoNum = dbo.ExpandKyByType('CoNumType', @CoNum) -- TLCG01

SELECT @OrdType = order_type
FROM posm_drawer
WHERE drawer = @CashDrawer

SELECT posm_pos.posm_num
,posm_pos.ref_num
,posm_pos.cust_num
,posm_pos.cust_seq
,custaddr.name
,posm_pos.ser_num
FROM posm_pos WITH (NOLOCK)
JOIN custaddr ON posm_pos.cust_num = custaddr.cust_num AND posm_pos.cust_seq =  custaddr.cust_seq
WHERE (posm_pos.cust_num = @CustNum OR @CustNum IS NULL)
AND (posm_pos.cust_seq = @CustSeq OR @CustSeq IS NULL)
AND (posm_pos.ser_num = @SerNum OR @SerNum IS NULL)
AND (posm_pos.posm_num = @POSNum OR @POSNum IS NULL)
AND posm_pos.ref_type = @OrdType
AND LEN(RTRIM(ISNULL(posm_pos.ref_num,''))) <> 0
AND posm_pos.pos_date IS NOT NULL
AND ((posm_pos.ref_num = @CoNum AND posm_pos.ref_type = 'O') OR @CoNum IS NULL)
GO


