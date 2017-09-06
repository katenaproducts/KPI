USE [KPI_App]
GO

/****** Object:  StoredProcedure [dbo].[EXTGEN_ARPayPostCreateTmpSp]    Script Date: 08/30/2017 15:48:02 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


/* $Header: /ApplicationDB/Stored Procedures/ARPayPostCreateTmpSp.sp 29    3/25/15 1:35a Ehe $  */
/*
***************************************************************
*                                                             *
*                           NOTICE                            *
*                                                             *
*   THIS SOFTWARE IS THE PROPERTY OF AND CONTAINS             *
*   CONFIDENTIAL INFORMATION OF INFOR AND/OR ITS AFFILIATES   *
*   OR SUBSIDIARIES AND SHALL NOT BE DISCLOSED WITHOUT PRIOR  *
*   WRITTEN PERMISSION. LICENSED CUSTOMERS MAY COPY AND       *
*   ADAPT THIS SOFTWARE FOR THEIR OWN USE IN ACCORDANCE WITH  *
*   THE TERMS OF THEIR SOFTWARE LICENSE AGREEMENT.            *
*   ALL OTHER RIGHTS RESERVED.                                *
*                                                             *
*   (c) COPYRIGHT 2010 INFOR.  ALL RIGHTS RESERVED.           *
*   THE WORD AND DESIGN MARKS SET FORTH HEREIN ARE            *
*   TRADEMARKS AND/OR REGISTERED TRADEMARKS OF INFOR          *
*   AND/OR ITS AFFILIATES AND SUBSIDIARIES. ALL RIGHTS        *
*   RESERVED.  ALL OTHER TRADEMARKS LISTED HEREIN ARE         *
*   THE PROPERTY OF THEIR RESPECTIVE OWNERS.                  *
*                                                             *
***************************************************************
*/

/* $Archive: /ApplicationDB/Stored Procedures/ARPayPostCreateTmpSp.sp $
 *
 * SL9.00 29 192811 Ehe Wed Mar 25 01:35:25 2015
 * Unable to post a payment
 * 192811 Change the logic of non-check payment.
 *
 * SL9.00 28 192015 pgross Fri Mar 06 16:48:41 2015
 * do not compare deposit_date for non-Checks
 *
 * SL9.00 27 187369 Igui Wed Dec 17 03:26:46 2014
 * Issue for work on RS6959 - Bank Collection A/R
 * RS6959(issue 187369)
 * add logic for '@PType = B(Direct Debit)'
 *
 * SL8.04 26 RS4615 Lliu Wed Dec 19 02:53:55 2012
 * RS4615: Correct the table name to <BaseName> when calling CreateDynamicTableSp.
 *
 * SL8.04 25 151941 pgross Tue Aug 07 13:21:03 2012
 * The second CN Reapplication shows wrong account on payment posting report
 * adjusted how the reapplication flag is set
 *
 * SL8.02 24 130122 pcoate Mon May 10 14:03:42 2010
 * Both Checks and Wires are only being posted for one bank at a time, though they should be posting for any number of banks in one posting
 * Issue 130122 - Changed the sort order of the result set.
 *
 * SL8.02 23 128675 Mewing Tue Apr 27 13:32:58 2010
 * Update Copyright to 2010
 *
 * SL8.02 22 128743 pgross Fri Apr 02 14:20:57 2010
 * Post thru date on report is different from post thru date on form
 * ensure that End Date is at the end of the day
 *
 * SL8.02 21 rs4588 Dahn Thu Mar 04 10:13:51 2010
 * RS4588 Copyright header changes
 *
 * SL8.02 20 rs4588 Dahn Wed Mar 03 17:18:29 2010
 * RS4588 Copyright Header changes
 *
 * SL8.01 19 118679 calagappan Thu May 28 13:29:09 2009
 * Error: "AR Payment exists outside of current accounting period" followed by "You do not have Post Authorization for ( AR Payment Posting)" with when posting process is attempted on AR Payment Posting form.
 * Check "out of date range" permissions on payments that are within the selection criteria.
 *
 * SL8.01 18 rs3953 Vlitmano Tue Aug 26 16:39:13 2008
 * RS3953 - Changed a Copyright header?
 *
 * SL8.01 17 rs3953 Vlitmano Mon Aug 18 15:04:40 2008
 * Changed a Copyright header information(RS3959)
 *
 * SL8.00 16 rs2968 nkaleel Fri Feb 23 00:19:55 2007
 * changing copyright information
 *
 * SL8.00 15 98202 pgross Thu Feb 15 11:14:48 2007
 * Cannot post payment with Days forward/back set to BLANK
 * allow time fence to be NULL
 *
 * SL8.00 14 RS2968 prahaladarao.hs Thu Jul 13 02:35:12 2006
 * RS 2968, Name change CopyRight Update.
 *
 * SL8.00 13 RS2968 prahaladarao.hs Tue Jul 11 03:51:07 2006
 * RS 2968
 * Name change CopyRight Update.
 *
 * SL8.00 12 91818 NThurn Mon Jan 09 09:48:16 2006
 * Inserted standard External Touch Point call.  (RS3177)
 *
 * SL7.05 11 91123 hcl-singnee Mon Dec 12 01:51:19 2005
 * 0129 dbo.ExpandKy() shouldn't be used directly
 * Issue# 91123
 * Now dbo.ExpandKy() function is called only through other ExpandKy* functions.
 *
 * SL7.05 10 84807 Hcl-sharsan Tue Apr 19 15:57:38 2005
 * Wrong cash account printing on report
 * Issue  84807: Provided the logic to set the reapplication
 *
 * SL7.05 9 86222 Hcl-dixichi Fri Apr 01 04:50:49 2005
 * AMP - successive posting results in incorrect data on report
 * Checked-in for issue 86222
 * For Reports:
 * 1. ARAdjustmentPosting
 * 2. ARDraftPosting
 * 3. ARPaymentPosting
 * 4. ARWirePosting
 *
 * SL7.05 8 PRJ1241 Hcl-kumaaja Sun Mar 20 23:22:07 2005
 * Modified for RS1241, included deposit_date field
 *
 * $NoKeywords: $
 _KPI 08/04/2017 Modified to post Ar Payments by user ID
 
 */
CREATE PROCEDURE [dbo].[EXTGEN_ARPayPostCreateTmpSp] (
  @PStartCustNum   CustNumType
, @PEndCustNum     CustNumType
, @PStartBnkCode   BankCodeType
, @PEndBnkCode     BankCodeType
, @StartDate       DateTimeType -- for Type C/W/A this is Receipt Date and for D this is Due Date
, @EndDate         DateTimeType
, @StartChkNum     ArCheckNumType
, @EndChkNum       ArCheckNumType
, @StartCreditMemo InvNumType
, @EndCreditMemo   InvNumType
, @PType           ArpmtTypeType
, @PSessionID      RowPointer
)
AS

   -- Check for existence of Generic External Touch Point routine (this section was generated by SpETPCodeSp and inserted by CallETPs.exe):
   --IF OBJECT_ID(N'dbo.EXTGEN_ARPayPostCreateTmpSp') IS NOT NULL
   --BEGIN
   --   DECLARE @EXTGEN_SpName sysname
   --   SET @EXTGEN_SpName = N'dbo.EXTGEN_ARPayPostCreateTmpSp'
   --   -- Invoke the ETP routine, passing in (and out) this routine's parameters:
   --   EXEC @EXTGEN_SpName
   --      @PStartCustNum
   --      , @PEndCustNum
   --      , @PStartBnkCode
   --      , @PEndBnkCode
   --      , @StartDate
   --      , @EndDate
   --      , @StartChkNum
   --      , @EndChkNum
   --      , @StartCreditMemo
   --      , @EndCreditMemo
   --      , @PType
   --      , @PSessionID
 
   --   -- ETP routine must take over all desired functionality of this standard routine:
   --   RETURN 0
   --END
   -- End of Generic External Touch Point code.
 
 
 -- _KPI - if Customer number starts with KPI_, it means it is user Initials , so we are posting bu User Batch
 
 

 
DECLARE
  @Severity INT
, @Infobar  InfobarType
, @ArpaypostRowPointer   RowPointerType
, @ArpaypostCustNum      CustNumType
, @ArpaypostBankCode     BankCodeType
, @ArpaypostCheckNum     ArCheckNumType
, @ArpaypostType         ArpmtTypeType
, @TEnablePrepaid        FlagNyType
, @IncludeNull           ListYesNoType

, @StartDate1    DateType
, @EndDate1      DateType
, @Voucher      VoucherType
, @VendorNum    VendNumType
, @PeriodValue   INT
, @OutOfPeriod  INT
, @Today DateType

, @ParmsTrxDateBwd         TrxFenceType
, @ParmsTrxDateFwd         TrxFenceType
, @ReApplied               ListYesNoType    --To check whether the payment is reapplication or not

SET @Severity = 0
SET @Infobar = NULL

SET @PStartCustNum = ISNULL(@PStartCustNum , dbo.LowCharacter())
SET @PEndCustNum   = ISNULL(@PEndCustNum , dbo.HighCharacter())




SET @PStartBnkCode = ISNULL(@PStartBnkCode , dbo.LowCharacter())
SET @PEndBnkCode   = ISNULL(@PEndBnkCode , dbo.HighCharacter())
SET @StartDate     = ISNULL(@StartDate, dbo.LowDate())
SET @EndDate       = ISNULL(@EndDate , dbo.HighDate())
SET @StartChkNum   = ISNULL(@StartChkNum , dbo.LowInt())
SET @EndChkNum     = ISNULL(@EndChkNum , dbo.HighInt())


SET @IncludeNull = case when @StartCreditMemo is null then 1 else 0 end
SET @StartCreditMemo = dbo.ExpandKyByType('InvNumType', @StartCreditMemo)
SET @EndCreditMemo = dbo.ExpandKyByType('InvNumType', @EndCreditMemo)
SET @StartCreditMemo = ISNULL(@StartCreditMemo , dbo.LowCharacter())
SET @EndCreditMemo   = ISNULL(@EndCreditMemo , dbo.HighCharacter())

SET @ReApplied = 0
set @Today = dbo.GetSiteDate(GETDATE())


IF @PType in ('C', 'W', 'A')
	INSERT INTO tmp_arpaypost (
	  SessionID
	, cust_num
	, bank_code
	, check_num
	, type,
     credit_memo_num,
     CreatedBy -- -- _KPI post by batch for each user id
	)
	SELECT
	  @PSessionID
	, arpmt.cust_num
	, arpmt.bank_code
	, arpmt.check_num
	, arpmt.type
        , credit_memo_num,
    CreatedBy   -- _KPI post by batch for each user id
	FROM arpmt
	WHERE (arpmt.cust_num BETWEEN @PStartCustNum AND @PEndCustNum )
	      AND arpmt.bank_code BETWEEN @PStartBnkCode AND @PEndBnkCode
	      AND arpmt.check_num BETWEEN @StartChkNum AND @EndChkNum
	      AND arpmt.recpt_date BETWEEN @StartDate AND @EndDate
	      AND ((arpmt.credit_memo_num BETWEEN @StartCreditMemo AND @EndCreditMemo)
                    or (@IncludeNull = 1 and arpmt.credit_memo_num is NULL))
	      AND arpmt.type = @PType
              AND ((arpmt.type = 'C' AND arpmt.deposit_date IS NOT NULL
                    AND arpmt.deposit_date < @Today)
                    OR   (arpmt.type = 'C' AND arpmt.deposit_date IS  NULL) OR arpmt.type <> 'C')
                    
              and CreatedBy = dbo.UserNameSp()  -- _KPI post by batch for each user id

IF @PType IN ('D','B')
begin	
	INSERT INTO tmp_arpaypost (
	  SessionID
	, cust_num
	, bank_code
	, check_num
	, type
        , credit_memo_num
        ,
     CreatedBy -- -- _KPI post by batch for each user id
	)
	SELECT
	  @PSessionID
	, arpmt.cust_num
	, arpmt.bank_code
	, arpmt.check_num
	, arpmt.type
        , credit_memo_num
        , CreatedBy  -- _KPI post by batch for each user id
	FROM arpmt
	WHERE arpmt.cust_num BETWEEN @PStartCustNum AND @PEndCustNum
	      AND arpmt.bank_code BETWEEN @PStartBnkCode AND @PEndBnkCode
	      AND arpmt.check_num BETWEEN @StartChkNum AND @EndChkNum
	      AND ((arpmt.due_date BETWEEN @StartDate AND @EndDate) or arpmt.due_date is null)
	      AND ((arpmt.credit_memo_num BETWEEN @StartCreditMemo AND @EndCreditMemo)
                    or (@IncludeNull = 1 and arpmt.credit_memo_num is NULL))
	      AND arpmt.type = @PType
	           and CreatedBy = dbo.UserNameSp()  -- _KPI post by batch for each user id
END

exec dbo.GetCurPeriodBeginEndDateSp @StartDate1 OUTPUT, @EndDate1 OUTPUT, @Infobar OUTPUT

SELECT
  @ParmsTrxDateBwd = parms.trx_date_bwd
, @ParmsTrxDateFwd = parms.trx_date_fwd
FROM parms with (readuncommitted)

SET @StartDate1 = dbo.MidnightOf(dateadd(day, -@ParmsTrxDateBwd, @StartDate1))
SET @EndDate1 = dbo.DayEndOf(dateadd(day, @ParmsTrxDateFwd, @EndDate1))

IF @PType in ('C', 'W', 'A')
BEGIN
   if exists (SELECT 1
   FROM arpmt
   WHERE arpmt.cust_num BETWEEN @PStartCustNum AND @PEndCustNum
     AND arpmt.bank_code BETWEEN @PStartBnkCode AND @PEndBnkCode
     AND arpmt.check_num BETWEEN @StartChkNum AND @EndChkNum
     AND arpmt.recpt_date BETWEEN @StartDate AND @EndDate
     AND ((arpmt.credit_memo_num BETWEEN @StartCreditMemo AND @EndCreditMemo)
                or (@IncludeNull = 1 and arpmt.credit_memo_num is NULL))
     AND arpmt.type = @PType
     and CreatedBy = dbo.UserNameSp() -- _KPI post by batch for each user id
          AND ((arpmt.type = 'C' AND arpmt.deposit_date IS NOT NULL
                AND arpmt.deposit_date < dbo.GetSiteDate(GETDATE()))OR
              arpmt.deposit_date IS NULL)
      and case when @PType = 'C' and deposit_date is not null then deposit_date else recpt_date end 
      not between @StartDate1 and @EndDate1
      )
   begin
      set @PeriodValue = case when dbo.CanAny('Posting out of Current Period', NULL) = 0 then 2 else 1 end
   end
END
ELSE
IF @PType IN ('D','B')
BEGIN
   if exists (SELECT 1
   FROM arpmt
   WHERE arpmt.cust_num BETWEEN @PStartCustNum AND @PEndCustNum
     AND arpmt.bank_code BETWEEN @PStartBnkCode AND @PEndBnkCode
     AND arpmt.check_num BETWEEN @StartChkNum AND @EndChkNum
     AND ((arpmt.due_date BETWEEN @StartDate AND @EndDate) or arpmt.due_date is null)
     AND ((arpmt.credit_memo_num BETWEEN @StartCreditMemo AND @EndCreditMemo)
                or (@IncludeNull = 1 and arpmt.credit_memo_num is NULL))
     and CreatedBy = dbo.UserNameSp() -- _KPI post by batch for each user id
     AND arpmt.type = @PType
      and recpt_date not between @StartDate1 and @EndDate1
      )
   begin
      set @PeriodValue = case when dbo.CanAny('Posting out of Current Period', NULL) = 0 then 2 else 1 end
   end
END

SET @OutOfPeriod = ISNULL(@PeriodValue, 0)

-- Set the enable_update_prepaid_amt flag

DECLARE PrepaidCrs CURSOR LOCAL STATIC FOR
SELECT
  tmp_arpaypost.RowPointer
, tmp_arpaypost.cust_num
, tmp_arpaypost.bank_code
, tmp_arpaypost.check_num
, tmp_arpaypost.type
FROM tmp_arpaypost
WHERE tmp_arpaypost.SessionId = @PSessionID

OPEN PrepaidCrs
WHILE  @Severity = 0
BEGIN
   FETCH PrepaidCrs INTO
     @ArpaypostRowPointer
   , @ArpaypostCustNum
   , @ArpaypostBankCode
   , @ArpaypostCheckNum
   , @ArpaypostType
   IF @@FETCH_STATUS = -1
      BREAK

  IF EXISTS (SELECT 1
              FROM artran with(readuncommitted)
              WHERE artran.cust_num = @ArpaypostCustNum and
                    ISNULL(artran.apply_to_inv_num, char(1)) = '0' and
                    artran.inv_seq = @ArpaypostCheckNum and
                    artran.check_seq = 0 and
                    CHARINDEX( artran.type, 'CP') <> 0)

      -- this is a re-apply
      SET @TEnablePrepaid = 0
   ELSE

   IF EXISTS (SELECT 1
              FROM arpmtd
              WHERE arpmtd.bank_code = @ArpaypostBankCode and
                    arpmtd.cust_num = @ArpaypostCustNum and
                    arpmtd.type = @ArpaypostType and
                    arpmtd.check_num = @ArpaypostCheckNum and
                    arpmtd.inv_num = '0' and
                    arpmtd.co_num IS NOT NULL and
                    arpmtd.co_num <> ' ')

      SET @TEnablePrepaid = 1
   ELSE
      SET @TEnablePrepaid = 0


  if exists(select 1 from  arpmt
                      join artran with(readuncommitted) on artran.cust_num = arpmt.cust_num
                      AND  artran.inv_seq = arpmt.check_num
                      AND artran.apply_to_inv_num in (artran.inv_num, '0')
                      AND artran.check_seq = 0
                where
                      arpmt.cust_num = @ArpaypostCustNum
                      and arpmt.check_num = @ArpaypostCheckNum
                  )
        UPDATE tmp_arpaypost
        SET reapplication = 1
        WHERE tmp_arpaypost.RowPointer = @ArpaypostRowPointer

   if @TEnablePrepaid = 1
   BEGIN
      UPDATE tmp_arpaypost
         SET enable_update_prepaid_amt = 1
      WHERE tmp_arpaypost.RowPointer = @ArpaypostRowPointer
   END

END
CLOSE      PrepaidCrs
DEALLOCATE PrepaidCrs

-- Create the Snapshot tables for use by the posting report
EXEC @Severity = dbo.CreateDynamicTableSp
                   @pTable  = 'tmp_arpmt'
                 , @Infobar = @Infobar OUTPUT
                 , @pParm1  = @PSessionID
                 , @pParm2  = 'WHERE EXISTS (SELECT * FROM tmp_arpaypost AS tt WHERE tt.SessionID = ''<Parm1>''
                               AND tt.cust_num = <BaseName>.cust_num
                               AND tt.bank_code = <BaseName>.bank_code
                               AND tt.check_num = <BaseName>.check_num
                               AND tt.type = <BaseName>.type)'


EXEC @Severity = dbo.CreateDynamicTableSp
                   @pTable  = 'tmp_arpmtd'
                 , @Infobar = @Infobar OUTPUT
                 , @pParm1  = @PSessionID
                 , @pParm2  = 'WHERE EXISTS (SELECT * FROM tmp_arpaypost AS tt WHERE tt.SessionID = ''<Parm1>''
                               AND tt.cust_num = <BaseName>.cust_num
                               AND tt.bank_code = <BaseName>.bank_code
                               AND tt.check_num = <BaseName>.check_num
                               AND tt.type = <BaseName>.type)'


--  The payments to be posted are returned to the client.
SELECT
  process_selection
, update_prepaid_amt
, enable_update_prepaid_amt
, cust_num
, bank_code
, check_num
, credit_memo_num
, type
, @OutOfPeriod as OutOfPeriod
FROM tmp_arpaypost
WHERE SessionID = @PSessionID
ORDER BY bank_code, type, cust_num, check_num

RETURN @Severity

GO


