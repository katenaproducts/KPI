USE [KPI_App]
GO

/****** Object:  StoredProcedure [dbo].[EXTGEN_Rpt_OrderInvoicingCreditMemoSp]    Script Date: 08/30/2017 15:48:37 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO




/* $Header: /ApplicationDB/Stored Procedures/Rpt_OrderInvoicingCreditMemoSp.sp 117   6/05/15 1:39a Cliu $  */
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
*   (c) COPYRIGHT 2008 INFOR.  ALL RIGHTS RESERVED.           *
*   THE WORD AND DESIGN MARKS SET FORTH HEREIN ARE            *
*   TRADEMARKS AND/OR REGISTERED TRADEMARKS OF INFOR          *
*   AND/OR ITS AFFILIATES AND SUBSIDIARIES. ALL RIGHTS        *
*   RESERVED.  ALL OTHER TRADEMARKS LISTED HEREIN ARE         *
*   THE PROPERTY OF THEIR RESPECTIVE OWNERS.                  *
*                                                             *
***************************************************************
*/

/* $Archive: /ApplicationDB/Stored Procedures/Rpt_OrderInvoicingCreditMemoSp.sp $
 *
 * SL9.00 117 195626 Cliu Fri Jun 05 01:39:37 2015
 * conversion populated time stamp in inv_hdr_mst.inv_date field - cannot reprint order invoices
 * Issue:195626
 * Use the ApplyDateOffsetSp function to set the ending invoice date to the timestamp of the end of day.
 *
 * SL9.00 116 193210 Ehe Thu Apr 02 04:39:36 2015
 * Simple and Detail report not displaying new Remit To details
 * 193210 Change the logic to output the new 3 column by the end of sp.
 *
 * SL9.00 115 188008 csun Wed Feb 04 03:56:21 2015
 * Issue#188008
 * RS7090,Add 3 new columns for temp table tt_invoice_draft.
 *
 * SL9.00 114 188748 pgross Tue Dec 16 15:10:29 2014
 * summarize surcharges for each individual invoice
 *
 * SL9.00 113 188433 jzhou Wed Dec 10 03:10:53 2014
 * Print Header On All Pages needs to be implemented for Order Invoicing
 * Issue 188433:
 * Add parameter for the Print Header On All Pages option.
 *
 * SL9.00 112 188527 jzhou Tue Dec 09 04:32:46 2014
 * Issues with formatting of Simple and Detail templates
 * Issue 188527:
 * Use new function to get report address.
 *
 * SL9.00 111 187770 Ehe Mon Dec 01 21:01:03 2014
 * RS7081 Coding
 * 187770 Add due_date for the output field.
 *
 * SL9.00 110 187770 Ehe Thu Nov 27 03:01:39 2014
 * RS7081 Coding
 * 187770 Add input parameters and output fields for RS7081.
 *
 * SL9.00 109 183743 Tding Fri Oct 10 21:52:23 2014
 * Order Invoicing Credit Memo report processing fails with error and report is not attached to the email.  The multi-part identifier "customer.lang_code" could not be bound
 * issue 183743, add an alias for table customer.
 *
 * SL9.00 108 176536 Igui Thu Mar 27 04:21:34 2014
 * New Extended Tax value seems to be pulling from wrong place
 * issue 176536(RS6307)
 * add parameter @ExtendedTax.
 *
 * SL9.00 107 177355 Igui Wed Mar 26 01:46:17 2014
 * Reprot OrderInvoicingCreditMemoLaser lists duplicated Line/Rel info.
 * issue 177355(RS5396)
 * add co_release judgement for select statement.
 *
 * SL9.00 106 171399 Cajones Fri Jan 24 15:19:32 2014
 * Errors found in Store Procedures for Mexico Country Pack
 * Issue 171399
 * Added missing t in @PrinCustomerNotes (@PrintCustomerNotes)
 * Added missing s in @PrintLineNotes (@PrintLinesNotes)
 *
 * SL9.00 105 172506 jzhou Tue Dec 24 00:40:01 2013
 * Changes associated with RS6529 Japan Country Pack - Monthly Invoice
 * Issue 172506:
 * Delete parameter @InvoiceType
 * Delete the logic about @InvoiceType
 *
 * SL9.00 104 171385 Ezi Mon Dec 16 05:02:56 2013
 * Germany Country Pack - Report layout changes
 * Issue 171385 - Germany Country Pack - Report layout changes
 *
 * SL9.00 103 171375 Lchen3 Mon Nov 25 01:57:40 2013
 * Invoice does not show Demanding Site PO number when PO- CO Automation is used
 * issue 171375
 * add field demanding site po
 *
 * SL9.00 102 169816 calagappan Mon Oct 28 10:48:18 2013
 * reprint of edi invoice blank if print invoices not checked in edi profile
 * Use customer document and EDI profiles to determine invoices to print
 *
 * SL8.04 101 165732 Igui Thu Aug 22 04:32:08 2013
 * Item content information line should be set a hidden condition when an item is eligible to make references for item content or not.
 * Issue 165732 - order the select columns and format arguments
 *
 * SL8.04 100 165732 Igui Wed Aug 21 03:21:10 2013
 * Item content information line should be set a hidden condition when an item is eligible to make references for item content or not.
 * Issue 165732 - Add output field item_content (1 = the definition of item contents that provide the basis for the calculation of surcharges included with items that are purchased from vendors and sold to customers.)
 *
 * SL8.04 99 164176 Cajones Wed Jul 03 08:03:16 2013
 * update EXTGEN touchpoints
 * Issue 164176
 * Modified Mexican Localizations code to make it more consistent with SyteLine's External Touch Point Standards
 *
 * SL8.04 98 163380 Mzhang4 Sat Jun 08 04:23:59 2013
 * Surcharge value null was added to invoice amount.
 * 163380- if item has no item content set surcharge to 0.
 *
 * SL8.04 97 RS5136 Mzhang4 Wed May 29 05:53:42 2013
 * RS5136- move the DECLARE to the front of the cades.
 *
 * SL8.04 96 RS5136 Mzhang4 Wed May 29 05:18:07 2013
 * RS5136- if cosurcharge is null set it to 0.
 *
 * SL8.04 95 RS5136 Mzhang4 Wed May 29 03:06:17 2013
 * RS5136-add surcharge to the total.
 *
 * SL8.04 94 RS5136 Mzhang4 Fri May 24 05:03:09 2013
 * RS5136- calc surcharge and total amount.
 *
 * SL8.04 93 160920 Jmtao Tue May 21 05:17:47 2013
 * Unable to reprint invoice from Order Invoicing Credit Memo Form
 * 160920 Change str_co_line to co_line
 *
 * SL8.04 92 160920 Jmtao Wed May 15 23:18:27 2013
 * Unable to reprint invoice from Order Invoicing Credit Memo Form
 * 160920 Change the where clause #tt_invoice_credit_memo.str_co_line = coitem.co_line
 * to 
 * substring(#tt_invoice_credit_memo.str_co_line,0,4 = coitem.co_line
 *
 * SL8.04 91 157844 Ddeng Fri Apr 19 01:31:03 2013
 * Order Invoicing Credit Memo To Be Printed Report not printing.
 * Issue 157844: Add the missing parameter pSite to call Rpt_CoDDraftISp. 
 *
 * SL8.04 90 RS5135 Lliu Mon Mar 18 02:22:16 2013
 * RS5135:Add Promotioncode in sp
 *
 * SL8.04 89 RS2775 exia Mon Feb 25 04:45:21 2013
 * RS2775
 *
 * SL8.04 88 RS4615 Azhang Sun Dec 30 22:04:34 2012
 * RS4615: Multi - Add Site within a Site Functionality.
 *
 * SL8.04 87 156737 calagappan Fri Dec 28 17:31:32 2012
 * Do not reset value of @Mode
 *
 * SL8.04 86 RS4615 Jmtao Thu Dec 27 02:57:07 2012
 * RS4615 (Multi - Add Site within a Site Functionality). change tab with 3 spaces
 *
 * SL8.04 85 RS4615 Jmtao Thu Dec 27 02:25:37 2012
 * RS4615 (Multi - Add Site within a Site Functionality). replace tab with 3 spaces, delete enter at the last of the file
 *
 * SL8.04 82 RS5857 Bbai Fri Oct 26 03:20:43 2012
 * RS5857:
 * Add a InvoiceType parm to control the logic.
 *
 * SL8.04 81 154497 Cajones Tue Oct 23 09:41:25 2012
 * Mexican Localizations for Rpt_OrderInvoicingCreditMemoSp
 * Issue 154497
 * Added touchpoint for Mexican Localizations.
 *
 * SL8.04 80 RS5200 jzhou Fri Aug 24 02:13:11 2012
 * RS5200:
 * Add parameter '@PrintItemOverview'.
 *
 * SL8.04 79 149080 calagappan Thu Jul 05 17:05:50 2012
 * ReUsed Serial Number does not print on invoice
 * Reset invoice and reference numbers after credit memo is generated
 *
 * SL8.03 78 148299 pgross Fri May 04 10:35:30 2012
 * EDI Invoices are printing in error if they are printed with non edi invoices
 * always check to see if an EDI customer uses printed invoices
 *
 * SL8.03 77 143279 calagappan Fri Oct 14 14:27:33 2011
 * Invoice using multiple due dates terms with many due dates, print dates out of order
 * Included multiple due date as part of order by clause
 *
 * SL8.03 76 142132 exia Wed Sep 14 22:58:20 2011
 * The draft option is not printing the invoice totals on the report. ,
 * Issue - 142132
 * Purpose: Merge the CoDraft data into this sp.
 * 1. According to Rpt_CoDDraftISp, serial variables have been defined.
 * 2.Relatve serial columns have been added on #tt_invoice_credit_memo create sql statements.
 * 3.Temp table #tt_invoice_draft has been added.
 * 4.Call Rpt_CoDDraftISp to get data and insert into #tt_invoice_draft.Parameter pVoidOrDraf equals D.
 * 5.According to #tt_invoice_draft, #tt_invoice_credit_memo  has been Updated, two tables' relative column is invoice number.
 * 6.Call Rpt_CoDDraftIsp again, the @pVoidOrDraft equals V
 * 7. Update #tt_invoice_credit_memo except last one record.
 *
 * SL8.03 75 RS4768 Xliang Fri Jun 03 04:52:35 2011
 * rs4768: add "Print Lot Number" print option.
 *
 * SL8.03 74 135328 pgross Fri Dec 17 09:42:35 2010
 * Invoice prints in ï¿½Ship Toï¿?Language.
 * get language code from cust_seq=0
 *
 * SL8.03 73 133785 Cajones Wed Nov 17 13:46:18 2010
 * When printing invoices for the first time, on task parameter, the string shows  RBP, REPRINT.
 * Issue 133785
 * Added code to always set the @Mode to REPRINT
 *
 * SL8.03 72 133874 pgross Fri Oct 29 12:16:03 2010
 * Invoice blank for subsidiary corporate customer.
 * retrieve corporate customer information from the bill-to record instead of the ship-to record
 *
 * SL8.03 71 132999 pgross Tue Oct 12 15:23:38 2010
 * Corp customer language not used on invoices
 * use the language of the corporate customer
 *
 * SL8.02 70 rs4588 Dahn Thu Mar 04 16:31:29 2010
 * rs4588 copyright header changes.
 *
 * SL8.01 69 120657 calagappan Thu Jul 16 13:39:45 2009
 * Serial Numbers not printing sequentially on Invoices
 * Include serial number as criteria to order result set.
 *
 * SL8.01 68 115920 pgross Wed Jan 07 13:44:36 2009
 * When printing a customer order where the ship to address is in a different country on the Order Invoicing Credit Memo form, the invoice printed out has picked up the VAT number of the main invoice address but the country code of the ship to.
 * added Ship To Tax information to the output
 *
 * SL8.01 67 114501 calagappan Fri Nov 07 15:51:46 2008
 * When Customer Doc Profile is setup for Order Invoicing/Credit Memo, only the first invoice in  batch will print.
 * Insert/Delete TrackRows only during posting and printing and not during reprint.
 *
 * SL8.01 66 114054 calagappan Mon Sep 29 17:14:27 2008
 * Tax code labels are not printing properly on the Order Invoicing report.
 * Display tax amount labels from Tax System form.
 *
 * SL8.01 65 113787 hpurayil Fri Sep 12 12:09:42 2008
 * Two BODs are sometimes being created for the same Invoice
 * 113787-No more BOD will be generated when Printing Invoice/Credit Memo/Debit Memo. BOD will be generated only at the time of Invoice Posting.
 *
 * SL8.01 64 rs3953 Vlitmano Tue Aug 26 19:02:15 2008
 * RS3953 - Changed a Copyright header?
 *
 * SL8.01 63 113274 pcoate Tue Aug 26 14:25:49 2008
 * Issue 113274 - Added logic to handle multiple inv_hdr rows for the same invoice.
 *
 * SL8.01 62 rs3953 Vlitmano Mon Aug 18 15:38:53 2008
 * Changed a Copyright header information(RS3959)
 *
 * SL8.01 61 109670 Djackson1 Fri Jul 18 09:19:00 2008
 * Invoice XML not being created
 * 109670 BOD initialization Point Change
 *
 * SL8.01 60 108552 pgross Wed Apr 02 14:35:25 2008
 * Syteline 7 requires that you go to the EDI Customer Profile and check the Print Invoice box when reprinting an invoice. This was not required in Syteline 6.
 * allow reprinting of EDI invoices
 *
 * SL8.01 59 108151 ssalahud Sat Mar 29 09:09:48 2008
 * Some fields on the Order Invoicing Credit Memo Report do not adhere to the number format defined on the Language IDs form
 * Issue 108151
 * Corrected quantity and total amount format.
 *
 * SL8.00 58 105954 pgross Fri Sep 28 10:21:15 2007
 * altered how inv_hdr.bill_type is selected
 *
 * SL8.00 57 104346 hcl-kumarup Thu Aug 16 08:51:51 2007
 * Tax only price adjustment invoice printed without totals.
 * Checked-in for issue 104346
 * Modified the "UPDATE #tt_invoice_credit_memo " statement to get currency format and places of the respective customer in case of ADJUSTMENT type invoice
 *
 * SL8.00 56 103041 hcl-kumarup Thu Jul 05 02:52:23 2007
 * The currency format in Order Invoicing Credit Memo report is domestic currency's format, even though the customer of the CO is set foreign currency
 * Checked-in for issue 103041
 * Updated report table by the currency places and currecny format of the respective customer
 *
 * SL8.00 55 101545 hcl-kumarup Thu May 10 05:59:43 2007
 * Duplicate invoices printed with a set of overlapping languages
 * Checked-in for issue 101545
 * Applied NULL to the variable @CustLangCode on if condition
 *
 * SL8.00 54 RS2968 nkaleel Fri Feb 23 04:59:52 2007
 * changing copyright information(RS2968)
 *
 * SL8.00 53 99489 Hcl-ajain Fri Feb 16 08:24:19 2007
 * Invoice prints blank if order is for a Ship To with a different language code.
 * Issue # 99489
 * Controlled the printing of invoice in case of customer language code is different from bill to customer language code.
 *
 * SL8.00 52 97869 Hcl-jainami Thu Feb 15 14:51:50 2007
 * Invoices are printing for customers when edi customer profile does not have the print invoice turned on.
 * Checked-in for issue 97869:
 * Modified the code to honor the EDI Customer Profile settings while processing ANY CO for a EDI Customer and not just for an EDI CO.
 *
 * SL8.00 51 98954 Hcl-ajain Fri Feb 02 07:11:53 2007
 * Invoices are printed in multiple lanugages if Range of Invoices is printed with languages overlapping.
 * Issue 98954
 * Added the condition for landuage code of customer removed by issue 91738.
 *
 * SL8.00 50 RS3339 nvennapu Thu Jan 18 06:59:40 2007
 *
 * SL8.00 49 95829 Hcl-ajain Fri Aug 25 06:05:56 2006
 * Blank Page prints on Reprint of Invoices for History Customer Orders
 * Issue # 95829
 * 1,Inserted row in final result set table to diaply error on the report that order now no longer exists for this invoice.
 *
 * SL8.00 48 95692 hcl-tiwasun Wed Aug 09 07:42:12 2006
 * The description Tax Invoice does not print on the first page of an invoice.
 * Issue# 95692
 * Update the print_tax_invoice field value for tx_type =1 record also.
 *
 * SL8.00 47 RS2968 prahaladarao.hs Wed Jul 12 01:48:15 2006
 * RS 2968, Name change CopyRight Update.
 *
 * SL8.00 46 RS1164 ajith.nair Wed Jun 28 01:52:07 2006
 * RS1164
 * (1) Added new fields [Kit_Component, Kit_Component_Desc, Kit_Qty_Required, Kit_UM, Kit_Flag] in the existing report set table #tt_invoice_credit_memo for Implementing the Kit Item functionality.
 *
 * SL8.00 45 94783 sarin.s Wed Jun 21 05:41:19 2006
 * GST value and text not printing on invoice
 * 94783
 * If field terms_pct of #tt_invoice_credit_memo table is null then,it's updated to zero.
 *
 * SL8.00 44 94783 sarin.s Wed Jun 21 02:31:36 2006
 * GST value and text not printing on invoice
 * 94783
 * Addded columns tax_disc_allow1 and tax_disc_allow2 to table #tt_invoice_credit_memo.
 * Checked for null of terms_pct field of table #tt_invoice_credit_memo using isnull function.
 *
 * SL8.00 43 92398 hcl-kumarup Thu Feb 16 08:01:24 2006
 * Item based tax system - problems with the Invoice
 * Checked in for Issue #92398
 * Added TermsPct field to report set table
 *
 * SL8.00 40 91818 NThurn Mon Jan 09 10:39:03 2006
 * Inserted standard External Touch Point call.  (RS3177)
 *
 * SL8.00 42 91738 Hcl-chantar Wed Jan 18 04:37:37 2006
 * The language code for the Customer Bill To (cust_seq = 0) should be used for Invoices, Credit Memos, and Debit Memos.
 * Issue 91738:
 * Deleted the language code condition in the select statement. Due to this report was printing blank if customer ship-to has language code other than customer bill-to and ship-to <>0.
 *
 * SL7.05 38 RS2560 Hcl-sharpar Wed Sep 07 07:06:53 2005
 * RS2560
 *
 * SL7.05 37 80051 Hcl-sharpar Wed Aug 10 05:45:01 2005
 * Issue #80051
 *
 * SL7.05 36 88460 Hcl-dixichi Sat Aug 06 09:05:22 2005
 * Invoices are being duplicated at printing
 * Checked-in for issue 88460
 * Corrected the NULL handling for the Language Code for the customer.
 *
 * SL7.05 35 87260 hcl-yadaami Mon May 23 08:14:09 2005
 * Blank invoices are being generated if language code is populated
 * Issue #87260
 * Modified to fetch data when there is no language code specified

 * for Ship To = 1.
 *
 * SL7.05 34 87105 Hcl-tayamoh Thu May 19 10:54:58 2005
 * scanning on TrackRows table
 * issue 87105
 *
 * Removed comments from the Dynamic SQL.
 *
 * SL7.05 33 87105 Hcl-tayamoh Wed May 18 14:31:53 2005
 * scanning on TrackRows table
 * Issue 87105
 *
 * SL7.04 32 85101 Grosphi Tue Feb 08 14:13:36 2005
 * Emailing of invoices via setup of Customer Document Profile sends all invoices in invoice run to all customers
 * only process those invoices within the specified range
 *
 * SL7.04 31 85343 Grosphi Tue Feb 01 16:25:04 2005
 * allow for 55 characters in displayed feature string
 *
 * $NoKeywords: $
 */
CREATE PROCEDURE [dbo].[EXTGEN_Rpt_OrderInvoicingCreditMemoSp](
   @pSessionIDChar               NVARCHAR(255)   = NULL,
   @InvType                      NCHAR(3)        = 'RBP',       -- Not needed by this program.  Form Order Invoicing/Credit Memo uses it for stored procedure CO10RSp.
   @Mode                         NVARCHAR(20)    = 'REPRINT',   -- PROCESS
   @StartInvNum                  InvNumType      = NULL,
   @EndInvNum                    InvNumType      = NULL,
   @StartOrderNum                CoNumType       = NULL,
   @EndOrderNum                  CoNumType       = NULL,
   @StartInvDate                 DateType        = NULL,
   @EndInvDate                   DateType        = NULL,
   @StartCustNum                 CustNumType     = NULL,
   @EndCustNum                   CustNumType     = NULL,
   @PrintItemCustomerItem        NVARCHAR(2)     = 'CI',        -- I
   @TransToDomCurr               FlagNyType      = 0,
   @InvCred                      NVARCHAR(1)     = 'I',         -- C
   @PrintSerialNumbers           ListYesNoType   = 1,
   @PrintPlanItemMaterial        ListYesNOTYPE   = 0,
   @PrintConfigurationDetail     NVARCHAR(1)     = 'N',         -- A or N
   @PrintEuro                    ListYesNoType   = 0,
   @PrintCustomerNotes           ListYesNoType   = 1,
   @PrintOrderNotes              ListYesNoType   = 1,
   @PrintOrderLineNotes          ListYesNoType   = 1,
   @PrintOrderBlanketLineNotes   ListYesNoType   = 1,
   @PrintProgressiveBillingNotes ListYesNoType   = 0,
   @PrintInternalNotes           ListYesNoType   = 1,
   @PrintExternalNotes           ListYesNoType   = 1,
   @PrintItemOverview            ListYesNoType   = 0,
   @DisplayHeader                ListYesNoType   = 1,
   @PrintLineReleaseDescription  ListYesNoType   = 1,
   @PrintStandardOrderText       ListYesNoType   = 1,
   @PrintBillToNotes             ListYesNoType   = 1,
   @LangCode                     LangCodeType    = NULL,
   @BGSessionId                  nvarchar(255)   = NULL,
   @PrintDiscountAmt             ListYesNoType   = 0,
   @PrintLotNumbers              ListYesNoType   = 1,
   @pSite                        SiteType        = NULL,
   @CalledFrom                   InfobarType     = NULL, -- can be InvoiceBuilder or NULL           
   @InvoicBuilderProcessID       RowpointerType  = NULL,
   @StartBuilderInvNum           BuilderInvNumType = NULL,
   @EndBuilderInvNum             BuilderInvNumType = NULL,
   @pPrintDrawingNumber          ListYesNoType     = 0,
   @pPrintDeliveryIncoTerms      ListYesNoType     = 0,
   @pPrintTax                    ListYesNoType     = 0,
   @pPrintEUDetails              ListYesNoType     = 0,
   @pPrintCurrCode               ListYesNoType     = 0,
   @pPrintHeaderOnAllPages       ListYesNoType     = 0
) AS
--  Crystal reports has the habit of setting the isolation level to dirty
-- read, so we'll correct that for this routine now.  Transaction management
-- is also not being provided by Crystal, so a transaction is started here.
BEGIN TRANSACTION
SET XACT_ABORT ON

IF dbo.GetIsolationLevel(N'OrderInvoicingCreditMemoDraft') = N'COMMITTED'
   SET TRANSACTION ISOLATION LEVEL READ COMMITTED
ELSE
   SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

-- A session context is created so session variables can be used.
DECLARE
  @RptSessionID RowPointerType,
  @pSessionID   RowPointerType,
  @Infobar     InfobarType

SET @pSessionId = @pSessionIdChar

EXEC dbo.InitSessionContextSp
  @ContextName = 'Rpt_OrderInvoicingCreditMemoSp'
, @SessionID   = @RptSessionID OUTPUT
, @Site        = @pSite

EXEC dbo.CopySessionVariablesSp
  @SessionID = @BGSessionId

DECLARE
   @AmtOldPrice             AmountType,
   @AmtNewPrice             AmountType,
   @AmtProgExtPrice         AmountType,
   @Addr0                   NVARCHAR(400), -- Our/Shipper Address
   @ParmsPhone              PhoneType,
   @Addr1                   NVARCHAR(400), -- Bill To Address
   @BillToContact           ContactType,
   @Addr2                   NVARCHAR(400), -- Ship To Address
   @ShipToContact           ContactType,
   @Addr3                   NVARCHAR(400), -- Drop Ship Address
   @DropShipContact         ContactType,
   @Credit                  FlagNyType,
   @DoNum                   DoNumType,
   @DiscAmt                 AmountType,
   @EuroTotal               AmountType,
   @Freight                 AmountType,
   @MiscCharges             AmountType,
   @NetAmt                  AmountType,
   @Item1                   WideTextType,
   @Item2                   WideTextType,
   @LineRelease             CoLineType,
   @LongCustPo              WideTextType,
   @PrepaidAmt              AmountType,
   @Progressive             ListYesNoType,
   @RptKey                  NCHAR(50),
   @SerialSerNum            SerNumType,
   @StrCustSeq              NCHAR(20),
   @Subtotal                AmountType,
   @Severity                INT,
   @SalesTax                AmountType,
   @SalesTax2               AmountType,
   @SaleAmt                 AmountType,
   @ShipVia                 DescriptionType,
   @ShortCustPo             WideTextType,
   @StrTInvItemCoLine       NCHAR(20),
   @TPrintInvNum            InvNumType,
   @TPrintInvSeq            InvSeqType,
   @TTaxRegNum1             WideTextType,
   @TTaxRegNum2             WideTextType,
   @TCustRegNum1            WideTextType,
   @TCustRegNum2            WideTextType,
   @TCustShipToRegNum1      WideTextType,
   @TCustShipToRegNum2      WideTextType,
   @TSlsman                 WideTextType,
   @TDescription            DescriptionType,
   @TCoText1                ReportTxtType,
   @TCoText2                ReportTxtType,
   @TCoText3                ReportTxtType,
   @TCurrDesc               DescriptionType,
   @TTaxIDLabel1            TaxCodeLabelType,
   @TTaxIDLabel2            TaxCodeLabelType,
   @TCustTaxIDLabel1        TaxCodeLabelType,
   @TCustTaxIDLabel2        TaxCodeLabelType,
   @Total                   AmountType,
   @TaxCodeLabel            TaxCodeLabelType,
   @TaxCode                 TaxCodeType,
   @TaxCodeELabel           TaxCodeLabelType,
   @TaxCodeE                TaxCodeType,
   @TaxRate                 TaxRateType,
   @TaxBasis                AmountType,
   @ExtendedTax             AmountType,
   @TxType                  INT,
   @TInvItemColine          CoLineType,
   @TQtyConv                GenericDecimalType,
   @TQty                    GenericDecimalType,
   @TBack                   GenericDecimalType,
   @TCprPrice               GenericDecimalType,
   @TExtPrice               GenericDecimalType,
   @TItemDesc               DescriptionType,
   @TItemOverview           NVARCHAR(100),
   @TOrdNum                 WideTextType,
   @TLcr                    WideTextType,
   @TDropLabel              WideTextType,
   @TCustomerRowPointer     RowPointerType,
   @TCustomerNotesFlag      FlagNyType,
   @TCoRowPointer           RowPointerType,
   @TCoNotesFlag            FlagNyType,
   @TCoitemRowPointer       RowPointerType,
   @TCoitemNotesFlag        FlagNyType,
   @TCoBlnRowPointer        RowPointerType,
   @TCoBlnNotesFlag         FlagNyType,
   @TProgbillRowPointer     RowPointerType,
   @TProgbillNotesFlag      FlagNyType,
   @TCoitemLineReleaseDes   DescriptionType,
   @CustNum                 CustNumType,
   @CustSeq                 CustSeqType,
   @TFaxNum                 PhoneType,
   @CoCoNum                 CoNumType,
   @InvHdrQtyPackages       PackagesType,
   @TWeight                 WeightType,
   @Terms                   DescriptionType,
   @InvHdrPrepaidAmt        AmountType,
   @CoLcrNum                LcrNumType,
   @TBillToRowPointer       RowPointerType,
   @TBillToNotesFlag        FlagNyType,
   @PackNum1                PackNumType,
   @PackNum2                PackNumType,
   @PackNum3                PackNumType,
   @PackNum4                PackNumType,
   @PackNum5                PackNumType,
   @PackNum6                PackNumType,
   @PackNum7                PackNumType,
   @PackNum8                PackNumType,
   @PrintTaxInv             ListYesNoType,
   @InvItemOrigInv          InvNumType,
   @InvItemReasonText       FormEditorType,
   @TaxSystemArApTaxRate1   TaxRateType,
   @TaxSystemArApTaxRate2   TaxRateType,
   @PriceWithoutTax         GenericDecimalType,
   @IncludeTaxInPrice       ListYesNoType,
   @TaxAmt                  AmountType,
   @TaxAmt_2                AmountType,
   @TermsDiscountAmt        AmountType,
   @KitComponent            ItemType,
   @KitComponentDesc        DescriptionType,
   @KitQtyRequired          QtyUnitType,
   @KitUnitMeasure          UMType,
   @KitFlag                 FlagNyType,
   @LotNum                  LotType

DECLARE
   @CoRowPointer            RowPointerType,
   @CfgattrAttrName         ConfigAttrNameType,
   @CfgattrAttrValue        ConfigAttrValueType,
   @CoitemUM                UMType,
   @CoitemShipDate          DateType,
   @CoShipShipDate          DateType,
   @CustaddrFaxNum          PhoneType,

   @CurrencyDescription     DescriptionType,
   @CurrencyCurrCode        CurrCodeType,
   @DoHdrConsigneeContact   ContactType,
   @DoHdrConsigneeName      NameType,
   @DoHdrConsigneeAddr##1   AddressType,
   @DoHdrConsigneeAddr##2   AddressType,
   @DoHdrConsigneeAddr##3   AddressType,
   @DoHdrConsigneeAddr##4   AddressType,
   @DoHdrConsigneeCity      CityType,
   @DoHdrConsigneeState     StateType,
   @DoHdrConsigneeZip       PostalCodeType,
   @DoHdrConsigneeCountry   CountryType,
   @InvHdrRowPointer        RowPointerType,
   @InvHdrCoNum             CoNumType,
   @InvHdrInvNum            InvNumType,
   @InvHdrInvSeq            InvSeqType,
   @InvHdrBillType          BillingTypeType,
   @InvHdrCustNum           CustNumType,
   @InvHdrCustSeq           CustSeqType,
   @InvHdrInvDate           DateType,
   @InvHdrWeight            WeightType,
   @InvHdrPkgs              PackagesType,
   @InvItemInvNum           InvNumType,
   @InvItemCoNum            CoNumType,
   @InvItemInvLine          InvLineType,
   @InvProSeq               InvProSeqType,
   @InvProDescription       DescriptionType,
   @ParmsSite               SiteType,
   @TaxSystemTaxSystem      TaxSystemType,
   @TaxSystemTaxItemLabel   TaxCodeLabelType,
   @TaxSystemTaxAmtLabel1  TaxCodeLabelType,
   @TaxSystemTaxAmtLabel2  TaxCodeLabelType,
   @TaxcodeTaxCode          TaxCodeType,
   @TaxcodeDescription      DescriptionType,
   @TermsDescription        DescriptionType,
   @TtCompConfigId          ConfigIdType,
   @TtCompCompId            ConfigCompIdType,
   @TtCompCompName          ConfigCompNameType,
   @TtCompQty               QtyUnitType,
   @TtCompPrice             CostPrcType,
   @XInvItemDoLine          DoLineType,
   @XInvItemDoSeq           DoSeqType,
   @XInvItemCustPo          CustPoType,
   @TaxSystem1              TaxSystemType,
   @TaxSystem2              TaxSystemType,
   @TaxMode1                TaxModeType,
   @TaxMode2                TaxModeType,
   @AmtTotal                WideTextType,
   @ApplyToInvNum           InvNumType,
   @Type                    NVARCHAR(1),
   @TermsPct                TaxRateType,
   @TaxDiscAllow1           ListYesNoType,
   @TaxDiscAllow2           ListYesNoType,
   @CustLangCode            LangCodeType,
   @DemandSitePONum         PoNumType

DECLARE
   @TtOrderPickList_CoDConfig_FeatStr     FeatTemplateType,
   @TtOrderPickList_CoDConfig_QtyConv     QtyPerType,
   @TtOrderPickList_CoDConfig_UM          UMType,
   @TtOrderPickList_CoDConfig_Description DescriptionType,
   @TtOrderPickList_RowPointer            RowPointerType,
   @ordererror                            InfoBarType
DECLARE
    @usemultiduedates          ListYesNoType,
    @multidueinvseq            ArInvSeqType,
    @multiduedate              DateType,
    @multiduepercent           TermsPercentType,
    @multidueamount            AmountType,
    @DomPriceFormat            InputMaskType,
    @DomPricePlaces            DecimalPlacesType,
    @DomAmountFormat           InputMaskType,
    @DomAmountPlaces           DecimalPlacesType,
    @QtyUnitFormat             NVARCHAR(60),
    @PlacesQtyUnit             TINYINT

DECLARE
    @TParmsCompany       NameType
  , @TParmsAddr1         AddressType
  , @TParmsAddr2         AddressType
  , @TParmsZip           PostalCodeType
  , @TParmsCity1         CityType
  , @TParmsCity2         CityType
  , @TArinvAmount1       AmountType
  , @TArinvAmount2       Amounttype
  , @TArinvInvDate       DateType
  , @TArinvDueDate       DateType
  , @TCustNum            CustNumType
  , @TInvNum             InvNumType
  , @TBankNumber         BankNumberType
  , @TBranchCode         BranchCodeType
  , @TBankAcctNo1        BankAccountType
  , @TBankAcctNo2        BankAccountType
  , @TBankAddr1          AddressType
  , @TBankAddr2          AddressType
  , @TCustAddrName       NameType
  , @TCustAddrAddr1      AddressType
  , @TCustAddrZip        PostalCodeType
  , @TCustAddrCity       CityType
  , @TCustdrftDraftNum   DraftNumType
  , @tTopCount           INT

DECLARE
    @CoSurcharge              AmountType
  , @InvNum                   InvNumType
  , @URL                      URLType
  , @EmailAddr                EmailType
  , @OfficeAddrFooter         LongAddress


declare @TR table (
  RowPointer uniqueidentifier
)

-- TX_Type on the #tt_invoice_credit_memo temp Table are used to indicate the following:-
--
--     Header Data:-
-- 1 - Header
--
--     Line and Sub-Line Data:-
-- 3 - Lines
-- 4 - Tax Detail
-- 5 - Order Details
-- 6 - LCR Details
-- 7 - Serial Numbers
-- 8 - Line Release/Extended Price
-- 9 - FBOM Records
-- 10 - Line Ship To Address/Drop Ship Address
-- 11 - Config Information
-- 12 - Order Line/Release Notes
-- 13 - Line/Release Description
-- 14 - Packing Slip Numbers
-- 15 - Progressive Billing Invoices
-- 16 - Progressive Billing Notes
-- 17 - Multi Due Date Header
-- 18 - Multi Due Date details
--      Footer Data:-
-- 19 - Customer Order Header and Customer Notes
-- 20 - Tax Footer
-- 21 - Totals Footer
-- 22 - Lot Numbers

SELECT TOP 1 @DomPriceFormat = cst_prc_format, @DomPricePlaces = places_cp,
   @DomAmountFormat = amt_format, @DomAmountPlaces = places
FROM currency WHERE currency.curr_code = (SELECT curr_code FROM currparms)

SET @DomPriceFormat = dbo.FixMaskForCrystal( @DomPriceFormat, dbo.GetWinRegDecGroup() )
SET @DomAmountFormat = dbo.FixMaskForCrystal( @DomAmountFormat, dbo.GetWinRegDecGroup() )

select @QtyUnitFormat = qty_unit_format,
       @PlacesQtyUnit = places_qty_unit
FROM invparms

SELECT
   @URL = parms.url
FROM parms (READUNCOMMITTED)
WHERE parm_key = 0

SELECT
   @EmailAddr = arparms.email_addr
FROM arparms WITH (READUNCOMMITTED)

SET @QtyUnitFormat = dbo.FixMaskForCrystal( @QtyUnitFormat, dbo.GetWinRegDecGroup() )

-- Declare Temp Table for Report
IF OBJECT_ID('tempdb..#tt_invoice_credit_memo') IS NULL
BEGIN
   SELECT
      @TxType                    AS tx_type,                      -- TX=(All)
      @InvItemInvNum             AS inv_num,                      -- Tx=(All)
      @InvHdrInvNum              AS inv_memo_num,                 -- Tx=1
      @InvHdrCustNum             AS cust_num,                     -- Tx=1
      @InvItemCoNum              AS co_num,                       -- Tx=1
      @invItemInvLine            AS inv_line,                     -- Tx=3 (& All Sub-Line Info)
      @ParmsSite                 AS inv_site,                     -- Tx=1
      @InvHdrInvDate             AS inv_date,                     -- Tx=1
      @TSlsman                   AS inv_slsman,                   -- Tx=1
      @TDescription              AS inv_description,              -- Tx=1
      @TTaxIDLabel1              AS inv_tax_num_lbl1,             -- Tx=1
      @TTaxRegNum1               AS inv_tax_num1,                 -- Tx=1
      @TTaxIDLabel2              AS inv_tax_num_lbl2,             -- Tx=1
      @TTaxRegNum2               AS inv_tax_num2,                 -- Tx=1
      @TCustTaxIDLabel1          AS inv_cust_tax_num_lbl1,        -- Tx=1
      @TCustRegNum1              AS inv_cust_tax_num1,            -- Tx=1
      @TCustShipToRegNum1        AS inv_cust_shipto_tax_num1,     -- Tx=1
      @TCustTaxIDLabel2          AS inv_cust_tax_num_lbl2,        -- Tx=1
      @TCustRegNum2              AS inv_cust_tax_num2,            -- Tx=1
      @TCustShipToRegNum2        AS inv_cust_shipto_tax_num2,     -- Tx=1
      @TCurrDesc                 AS inv_curr_code,                -- Tx=1
      @InvHdrCustseq             AS inv_cust_seq,                 -- Tx=1
      @StrCustSeq                AS inv_str_cust_seq,             -- Tx=1
      @CustaddrFaxNum            AS inv_fax_num,                  -- Tx=1
      @LongCustPo                AS inv_long_cust_po,             -- Tx=1
      @ShortCustPo               AS inv_short_cust_po,            -- Tx=1
      @InvHdrPkgs                AS inv_pkgs,                     -- Tx=1
      @InvHdrWeight              AS inv_weight,                   -- Tx=1
      @ShipVia                   AS inv_shipvia,                  -- Tx=1
      @TermsDescription          AS inv_terms,                    -- Tx=1
      @TermsPct                  AS terms_pct,                     -- Tx=1
      @TaxSystemTaxAmtLabel1     AS tax_amt_label1,               -- Tx=21
      @TaxSystemTaxAmtLabel2     AS tax_amt_label2,               -- Tx=21
      @SaleAmt                   AS inv_sale_amt,                 -- Tx=21
      @DiscAmt                   AS inv_disc_amt,                 -- Tx=21
      @NetAmt                    AS inv_net_amt,                  -- Tx=21
      @TCoText1                  AS inv_co_text1,                 -- Tx=21
      @MiscCharges               AS inv_misc_charges,             -- Tx=21
      @TCoText2                  AS inv_co_text2,                 -- Tx=21
      @Freight                   AS inv_freight,                  -- Tx=21
      @TCoText3                  AS inv_co_text3,                 -- Tx=21
      @SalesTax                  AS inv_sales_tax,                -- Tx=21
      @SalesTax2                 AS inv_sales_tax2,               -- Tx=21
      @PrepaidAmt                AS inv_prepaid_amt,              -- Tx=21
      @Total                     AS inv_total,                    -- Tx=21
      @PrintEuro                 AS inv_print_euro,               -- Tx=21
      @EuroTotal                 AS inv_euro_total,               -- Tx=21
      @Addr0                     AS OurAddress,                   -- Tx=1  -- Our/Shipper Address
      @Addr1                     AS BillToAddress,                -- Tx=1  -- Bill To Address
      @Addr2                     AS ShipToAddress,                -- Tx=1  -- Ship To Address
      @Addr3                     AS DropShipAddress,              -- Tx=1  -- Drop Ship Address
      @TaxCodeLabel              AS tax_code_lbl,                 -- Tx=20
      @TaxCode                   AS inv_tax_code,                 -- Tx=20
      @TaxCodeELabel             AS tax_code_e_lbl,               -- Tx=20
      @TaxCodeE                  AS tax_code_e,                   -- Tx=20
      @TaxRate                   AS tax_rate,                     -- Tx=20
      @TaxBasis                  AS tax_basis,                    -- Tx=20
      @ExtendedTax               AS extended_tax,                 
      @CurrencyCurrCode          AS curr_code,                    -- Tx=3
      @CurrencyDescription       AS curr_description,             -- Tx=3
      @TInvItemColine            AS co_line,                      -- Tx=3
      @StrTInvItemColine         AS str_co_line,                  -- Tx=3, 10
      @TQtyConv                  AS qty_conv,                     -- Tx=3
      @TQty                      AS qty,                          -- Tx=3
      @TBack                     AS back,                         -- Tx=3
      @TCprPrice                 AS cpr_price,                    -- Tx=3 (When Not Progressive)
      @TExtPrice                 AS ext_price,                    -- Tx=3 (When Not Progressive)
      @CoShipShipDate            AS ship_dat,                     -- Tx=3
      @DoHdrConsigneeContact     AS contact,                      -- Tx=3
      @DoHdrConsigneeName        AS cosignee_name,                -- Tx=3
      @DoHdrConsigneeAddr##1     AS cosignee_addr1,               -- Tx=3
      @DoHdrConsigneeAddr##2     AS cosignee_addr2,               -- Tx=3
      @DoHdrConsigneeAddr##3     AS cosignee_addr3,               -- Tx=3
      @DoHdrConsigneeAddr##4     AS cosignee_addr4,               -- Tx=3
      @DoHdrConsigneeCity        AS cosignee_city,                -- Tx=3
      @DoHdrConsigneeState       AS cosignee_state,               -- Tx=3
      @DoHdrConsigneeZip         AS cosignee_zip,                 -- Tx=3
      @DoHdrConsigneeCountry     AS cosignee_country,             -- Tx=3
      @AmtOldPrice               AS amt_old_price,                -- Tx=3
      @AmtNewPrice               AS amt_new_price,                -- Tx=3
      @Item1                     AS item1,                        -- Tx=3
      @Item2                     AS item2,                        -- Tx=3
      @TItemDesc                 AS itemDesc,                     -- Tx=3
      @TItemOverview             AS itemOverview,                 -- Tx=3
      @CoitemUm                  AS coitem_u_m,                   -- Tx=3
      @XInvItemDoLine            AS x_inv_item_do_line,           -- Tx=3
      @XInvItemDoSeq             AS x_inv_item_do_seq,            -- Tx=3
      @CoItemShipDate            AS coitem_ship_date,             -- Tx=3
      @XInvItemCustPo            AS x_inv_item_cust_po,           -- Tx=3
      @TaxSystemTaxItemLabel     AS tax_item_label,               -- Tx=4
      @TaxcodeTaxCode            AS tax_code,                     -- Tx=4
      @TaxcodeDescription        AS tax_code_Description,         -- Tx=4
      @TOrdNum                   AS ord_num,                      -- Tx=5
      @TLcr                      AS lcr,                          -- Tx=1,6
      @SerialSerNum              AS ser_num,                      -- Tx=7
      @AmtProgExtPrice           AS amt_prog_ex_price,            -- Tx=8
      @LineRelease               AS line_release,                 -- Tx=?
      @DoNum                     AS do_num,                       -- Tx=8
      @TtCompConfigId            AS config_id,                    -- Tx=11
      @TtCompCompId              AS comp_id,                      -- Tx=11
      @TtCompCompName            AS comp_name,                    -- Tx=11
      @TtCompQty                 AS config_qty,                   -- Tx=11
      @TtCompPrice               AS price,                        -- Tx=11
      @CfgAttrAttrName           AS attr_name,                    -- Tx=11
      @CfgAttrAttrValue          AS attr_value,                   -- Tx=11
      @InvProSeq                 AS inv_pro_seq,                  -- Tx=15
      @InvProDescription         AS inv_pro_description,          -- Tx=15
      @Subtotal                  AS subtotal,                     -- Tx=15
      @Credit                    AS credit,                       -- Tx=15
      @TtOrderPickList_CoDConfig_FeatStr     AS FBOM_feat_Str,    -- Tx=9
      @TtOrderPickList_CoDConfig_QtyConv     AS FBOM_qty_conv,    -- Tx=9
      @TtOrderPickList_CoDConfig_UM          AS FBOM_u_m,         -- Tx=9
      @TtOrderPickList_CoDConfig_Description AS FBOM_Description, -- Tx=9
      @TCustomerRowPointer       AS customer_RowPointer,          -- Tx=19
      @TCustomerNotesFlag        AS customer_NotesFlag,           -- Tx=19
      @TCoRowPointer             AS co_RowPointer,                -- Tx=19
      @TCoNotesFlag              AS co_NotesFlag,                 -- Tx=19
      @TCoitemRowPointer         AS coitem_RowPointer,            -- Tx=12
      @TCoitemNotesFlag          AS coitem_NotesFlag,             -- Tx=12
      @TCoBlnRowPointer          AS co_bln_RowPointer,            -- Tx=12
      @TCoBlnNotesFlag           AS co_bln_NotesFlag,             -- Tx=12
      @TCoitemLineReleaseDes     AS coitem_LineReleaseDes,        -- TX=13
      @TProgbillRowPointer       AS progbill_RowPointer,          -- Tx=16
      @TProgbillNotesFlag        AS progbill_NotesFlag,           -- Tx=16
      @RptKey                    AS rpt_key,                      -- Tx=(All)
      @TBillToRowPointer         AS bill_to_RowPointer,           -- Tx=19
      @TBillToNotesFlag          AS bill_to_NotesFlag,            -- Tx=19
      @PackNum1                  AS pack_num_1,                   -- Tx=14
      @PackNum2                  AS pack_num_2,                   -- Tx=14
      @PackNum3                  AS pack_num_3,                   -- Tx=14
      @PackNum4                  AS pack_num_4,                   -- Tx=14
      @PackNum5                  AS pack_num_5,                   -- Tx=14
      @PackNum6                  AS pack_num_6,                   -- Tx=14
      @PackNum7                  AS pack_num_7,                   -- Tx=14
      @PackNum8                  AS pack_num_8,                   -- Tx=14
      @PrintTaxInv               AS print_tax_invoice,
      @InvItemOrigInv            AS orig_inv_num,
      @InvItemReasonText         AS reason_text,
      @TaxSystemArApTaxRate1     AS tax_system_rate1,
      @TaxSystemArApTaxRate2     AS tax_system_rate2,
      @TaxSystem1                AS tax_system1_enabled,
      @TaxSystem2                AS tax_system2_enabled,
      @TaxMode1                  AS tax_mode1,
      @TaxMode2                  AS tax_mode2,
      @AmtTotal                  AS amt_total,
      @PriceWithoutTax           AS price_without_tax,
      @IncludeTaxInPrice         AS include_tax_in_price,
      @TaxAmt                    AS tax_amt,
      @TaxAmt_2                  AS tax_amt_2,
      @usemultiduedates          AS use_multi_due_dates,
      @multidueinvseq            AS multi_due_inv_seq,
      @multiduedate              AS multi_due_date,
      @multiduepercent           AS multi_due_percent,
      @multidueamount            AS multi_due_amount,
      @ApplyToInvNum             AS apply_to_inv_num,
      @DomPriceFormat            AS Dom_Price_Format,
      @DomPricePlaces            AS Dom_Price_Places,
      @DomAmountFormat           AS Dom_Amount_Format,
      @DomAmountPlaces           AS Dom_Amount_Places,
      @Type                      AS type,
      @TermsDiscountAmt          AS TermsDiscountAmt,
      @TaxDiscAllow1             AS tax_disc_allow1,
      @TaxDiscAllow2             AS tax_disc_allow2,
      @KitComponent              AS Kit_Component,
      @KitComponentDesc          AS Kit_Component_Desc,
      @KitQtyRequired            AS Kit_Qty_Required,
      @KitUnitMeasure            AS Kit_UM,
      @KitFlag                   AS Kit_Flag,
      @ordererror                AS OrderError,
      @QtyUnitFormat             AS qty_unit_format,
      @PlacesQtyUnit             AS places_qty_unit,
      @LotNum                    AS lot_num

    , @TxType                  As t_tx_type                            -- TX=(All)
    , @InvHdrCoNum             AS t_co_num                             -- Tx=(All)
    , @RptKey                  AS t_rpt_key                            -- Tx=(All)
    , @TParmsCompany           AS t_parms_company                      -- Tx=30
    , @TParmsAddr1             AS t_parms_addr1                        -- Tx=30
    , @TParmsAddr2             AS t_parms_addr2                        -- Tx=30
    , @TParmsZip               AS t_parms_zip                          -- Tx=30
    , @TParmsCity1             AS t_parms_city1                        -- Tx=30
    , @TParmsCity2             AS t_parms_city2                        -- Tx=30
    , @TArinvAmount1           AS t_arinv_amount1                      -- Tx=30
    , @TArinvAmount2           AS t_arinv_amount2                      -- Tx=30
    , @TArinvInvDate           AS t_arinv_inv_date                     -- Tx=30
    , @TArinvDueDate           AS t_arinv_due_date                     -- Tx=30
    , @TCustNum                AS t_cust_num                           -- Tx=30
    , @TInvNum                 AS t_inv_num                            -- Tx=30
    , @TBankNumber             AS t_bank_number                        -- Tx=30
    , @TBranchCode             AS t_branch_code                        -- Tx=30
    , @TBankAcctNo1            AS t_bank_acct_no1                      -- Tx=30
    , @TBankAcctNo2            AS t_bank_acct_no2                      -- Tx=30
    , @TBankAddr1              AS t_bank_addr1                         -- Tx=30
    , @TBankAddr2              AS t_bank_addr2                         -- Tx=30
    , @TCustAddrName           AS t_custaddr_name                      -- Tx=30
    , @TCustAddrAddr1          AS t_custaddr_addr1                     -- Tx=30
    , @TCustAddrZip            AS t_custaddr_zip                       -- Tx=30
    , @TCustAddrCity           AS t_custaddr_city                      -- Tx=30
    , @TCustdrftDraftNum       AS t_custdrft_draft_num                 -- Tx=30
    , @DemandSitePONum         AS demand_site_PO
    , @URL                     AS url
    , @EmailAddr               AS email_addr
    , @OfficeAddrFooter        AS office_addr_footer

   INTO #tt_invoice_credit_memo
   WHERE 1=2
END

-- Declare Temp Table for Report
IF OBJECT_ID('tempdb..#tt_invoice_draft') IS NULL
BEGIN
    SELECT
        @TxType                  As tx_type                              -- TX=(All)
      , @InvHdrInvNum            AS inv_num                  -- Tx=(All)
      , @InvHdrCoNum             AS co_num                  -- Tx=(All)
      , @RptKey                  AS rpt_key                              -- Tx=(All)
      , @TParmsCompany           AS t_parms_company                      -- Tx=30
      , @TParmsAddr1             AS t_parms_addr1                        -- Tx=30
      , @TParmsAddr2             AS t_parms_addr2                        -- Tx=30
      , @TParmsZip               AS t_parms_zip                          -- Tx=30
      , @TParmsCity1             AS t_parms_city1                        -- Tx=30
      , @TParmsCity2             AS t_parms_city2                        -- Tx=30
      , @TArinvAmount1           AS t_arinv_amount1                      -- Tx=30
      , @TArinvAmount2           AS t_arinv_amount2                      -- Tx=30
      , @TArinvInvDate           AS t_arinv_inv_date                     -- Tx=30
      , @TArinvDueDate           AS t_arinv_due_date                     -- Tx=30
      , @TCustNum                AS t_cust_num                           -- Tx=30
      , @TInvNum                 AS t_inv_num                            -- Tx=30
      , @TBankNumber             AS t_bank_number                        -- Tx=30
      , @TBranchCode             AS t_branch_code                        -- Tx=30
      , @TBankAcctNo1            AS t_bank_acct_no1                      -- Tx=30
      , @TBankAcctNo2            AS t_bank_acct_no2                      -- Tx=30
      , @TBankAddr1              AS t_bank_addr1                         -- Tx=30
      , @TBankAddr2              AS t_bank_addr2                         -- Tx=30
      , @TCustAddrName           AS t_custaddr_name                      -- Tx=30
      , @TCustAddrAddr1          AS t_custaddr_addr1                     -- Tx=30
      , @TCustAddrZip            AS t_custaddr_zip                       -- Tx=30
      , @TCustAddrCity           AS t_custaddr_city                      -- Tx=30
      , @TCustdrftDraftNum       AS t_custdrft_draft_num                 -- Tx=30
   INTO #tt_invoice_draft
   WHERE 1=2
END


SET @Severity = 0

SET @StartCustNum    = dbo.ExpandKyByType('CustNumType', @StartCustNum)
SET @EndCustNum      = dbo.ExpandKyByType('CustNumType', @EndCustNum)
SET @StartOrderNum   = dbo.ExpandKyByType('CoNumType', @StartOrderNum)
SET @EndOrderNum     = dbo.ExpandKyByType('CoNumType', @EndOrderNum)
SET @StartInvNum     = dbo.ExpandKyByType('InvNumType', @StartInvNum)
SET @EndInvNum       = dbo.ExpandKyByType('InvNumType', @EndInvNum)

EXEC dbo.ApplyDateOffsetSp @Date = @StartInvDate OUTPUT, @Offset = NULL, @IsEndDate = 0
EXEC dbo.ApplyDateOffsetSp @Date = @EndInvDate OUTPUT, @Offset = NULL, @IsEndDate = 1

SET @LangCode = isnull(@LangCode,'')
-- Dynamic SQL is used so that the simplest query will result based on the
-- input range constraints, giving the optimizer the best opportunity to use
-- the best index for the circumstances.  The global cursor is used because
-- it makes the cursor available in this routine after it is created in the
-- dynamic SQL process space.

   -- Check for existence of Generic External Touch Point routine (this section was generated by SpETPCodeSp and inserted by CallETPs.exe):
   --IF OBJECT_ID(N'dbo.EXTGEN_Rpt_OrderInvoicingCreditMemoSp') IS NOT NULL
   --BEGIN
   --   DECLARE @EXTGEN_SpName sysname
   --   SET @EXTGEN_SpName = N'dbo.EXTGEN_Rpt_OrderInvoicingCreditMemoSp'
   --   -- Invoke the ETP routine, passing in (and out) this routine's parameters:
   --   EXEC @EXTGEN_SpName
   --      @pSessionIDChar
   --      , @InvType
   --      , @Mode
   --      , @StartInvNum
   --      , @EndInvNum
   --      , @StartOrderNum
   --      , @EndOrderNum
   --      , @StartInvDate
   --      , @EndInvDate
   --      , @StartCustNum
   --      , @EndCustNum
   --      , @PrintItemCustomerItem
   --      , @TransToDomCurr
   --      , @InvCred
   --      , @PrintSerialNumbers
   --      , @PrintPlanItemMaterial
   --      , @PrintConfigurationDetail
   --      , @PrintEuro
   --      , @PrintCustomerNotes
   --      , @PrintOrderNotes
   --      , @PrintOrderLineNotes
   --      , @PrintOrderBlanketLineNotes
   --      , @PrintProgressiveBillingNotes
   --      , @PrintInternalNotes
   --      , @PrintExternalNotes
   --      , @PrintItemOverview
   --      , @DisplayHeader
   --      , @PrintLineReleaseDescription
   --      , @PrintStandardOrderText
   --      , @PrintBillToNotes
   --      , @LangCode
   --      , @BGSessionId
   --      , @PrintDiscountAmt
   --      , @PrintLotNumbers
   --      , @pSite
   --      , @CalledFrom
   --      , @InvoicBuilderProcessID
   --      , @StartBuilderInvNum
   --      , @EndBuilderInvNum
   --      , @pPrintDrawingNumber
   --      , @pPrintDeliveryIncoTerms
   --      , @pPrintTax
   --      , @pPrintEUDetails
   --      , @pPrintCurrCode
   --      , @pPrintHeaderOnAllPages
   --   IF @@TRANCOUNT > 0
   --      COMMIT TRANSACTION
   --   EXEC dbo.CloseSessionContextSp @SessionID = @RptSessionID
   --   -- ETP routine must take over all desired functionality of this standard routine:
   --   RETURN
   --END
   ---- End of Generic External Touch Point code.

DECLARE
  @SQL LongListType

IF @Mode <> 'REPRINT'
BEGIN
   IF @CalledFrom = 'InvoiceBuilder'
      SET @SQL = 'DECLARE InvHdrCrs CURSOR GLOBAL STATIC FOR
      SELECT
      ih.RowPointer,
      ih.co_num,
      ih.inv_num,
      ih.inv_seq,
      ih.bill_type,
      ih.cust_num,
      ih.cust_seq
      , isnull(corp_customer.lang_code, customer.lang_code)
     FROM inv_hdr ih inner join trackrows tr on ih.rowpointer = tr.rowpointer
      join customer as customer on ih.cust_num = customer.cust_num AND customer.cust_seq = 0
          left outer join custaddr on
             custaddr.cust_num = customer.cust_num
             and custaddr.cust_seq = 0
             and custaddr.corp_address = 1
          left outer join customer as corp_customer on
             corp_customer.cust_num = custaddr.corp_cust
             and corp_customer.cust_seq = 0
        where     tr.SessionID = @pSessionID  And tr.trackedopertype = ''inv_hdr''' +
       dbo.AndSqlWhere ( 'ih' , 'inv_num' , 1 , @StartInvNum , @EndInvNum)   +
       dbo.AndSqlWhere ( 'ih' , 'builder_inv_num' , 1 , @StartBuilderInvNum , @EndBuilderInvNum)   
   ELSE
      SET @SQL = 'DECLARE InvHdrCrs CURSOR GLOBAL STATIC FOR
      SELECT
      ih.RowPointer,
      ih.co_num,
      ih.inv_num,
      ih.inv_seq,
      ih.bill_type,
      ih.cust_num,
      ih.cust_seq
      , isnull(corp_customer.lang_code, customer.lang_code)
     FROM inv_hdr ih inner join trackrows tr on ih.rowpointer = tr.rowpointer
      join customer as customer on ih.cust_num = customer.cust_num AND customer.cust_seq = 0
          left outer join custaddr on
             custaddr.cust_num = customer.cust_num
             and custaddr.cust_seq = 0
             and custaddr.corp_address = 1
          left outer join customer as corp_customer on
             corp_customer.cust_num = custaddr.corp_cust
             and corp_customer.cust_seq = 0
        where     tr.SessionID = @pSessionID  And tr.trackedopertype = ''inv_hdr''' +
       dbo.AndSqlWhere ( 'ih' , 'inv_num' , 1 , @StartInvNum , @EndInvNum)

   EXEC sp_executesql  @SQL,
     N'@LangCode LangCodeType, @pSessionID RowPointerType',
     @LangCode, @pSessionID

END
ELSE
BEGIN
   IF @CalledFrom = 'InvoiceBuilder'
      SET @SQL = 'DECLARE InvHdrCrs CURSOR GLOBAL STATIC FOR
      SELECT
      inv_hdr.RowPointer,
      inv_hdr.co_num,
      inv_hdr.inv_num,
      inv_hdr.inv_seq,
      inv_hdr.bill_type,
      inv_hdr.cust_num,
      inv_hdr.cust_seq
     , isnull(corp_customer.lang_code, customer.lang_code)
     FROM inv_hdr , customer as customer
         left outer join custaddr on
            custaddr.cust_num = customer.cust_num
            and custaddr.cust_seq = 0
            and custaddr.corp_address = 1
         left outer join customer as corp_customer on
            corp_customer.cust_num = custaddr.corp_cust
            and corp_customer.cust_seq = 0
      WHERE inv_hdr.bill_type in (''C'', ''N'', ''P'', ''R'') ' + -- skip A/R, RMA & PROJ inv-hdrs
        dbo.AndSqlWhere ( 'inv_hdr' , 'inv_num' , 1 , @StartInvNum , @EndInvNum) +
        dbo.AndSqlWhere ( 'inv_hdr' , 'inv_date' , 1 , @StartInvDate , @EndInvDate) +
        dbo.AndSqlWhere ( 'inv_hdr' , 'cust_num' , 1 , @StartCustNum , @EndCustNum) +
      ' AND inv_hdr.co_num IS NOT NULL' + -- skip Consolidate Invoices
        dbo.AndSqlWhere ( 'inv_hdr' , 'co_num' , 1 , @StartOrderNum , @EndOrderNum) +
        ' AND inv_hdr.cust_num = customer.cust_num AND customer.cust_seq = 0'+
       dbo.AndSqlWhere ( 'ih' , 'builder_inv_num' , 1 , @StartBuilderInvNum , @EndBuilderInvNum)   
   ELSE
      SET @SQL = 'DECLARE InvHdrCrs CURSOR GLOBAL STATIC FOR
      SELECT
      inv_hdr.RowPointer,
      inv_hdr.co_num,
      inv_hdr.inv_num,
      inv_hdr.inv_seq,
      inv_hdr.bill_type,
      inv_hdr.cust_num,
      inv_hdr.cust_seq
     , isnull(corp_customer.lang_code, customer.lang_code)
     FROM inv_hdr , customer as customer
         left outer join custaddr on
            custaddr.cust_num = customer.cust_num
            and custaddr.cust_seq = 0
            and custaddr.corp_address = 1
         left outer join customer as corp_customer on
            corp_customer.cust_num = custaddr.corp_cust
            and corp_customer.cust_seq = 0
      WHERE inv_hdr.bill_type in (''C'', ''N'', ''P'', ''R'') ' + -- skip A/R, RMA & PROJ inv-hdrs
        dbo.AndSqlWhere ( 'inv_hdr' , 'inv_num' , 1 , @StartInvNum , @EndInvNum) +
        dbo.AndSqlWhere ( 'inv_hdr' , 'inv_date' , 1 , @StartInvDate , @EndInvDate) +
        dbo.AndSqlWhere ( 'inv_hdr' , 'cust_num' , 1 , @StartCustNum , @EndCustNum) +
      ' AND inv_hdr.co_num IS NOT NULL' + -- skip Consolidate Invoices
        dbo.AndSqlWhere ( 'inv_hdr' , 'co_num' , 1 , @StartOrderNum , @EndOrderNum) +
        ' AND inv_hdr.cust_num = customer.cust_num AND customer.cust_seq = 0'

     EXEC sp_executesql  @SQL,
     N'@LangCode LangCodeType, @pSessionID RowPointerType',
     @LangCode, @pSessionID
END

OPEN InvHdrCrs

WHILE @Severity = 0
BEGIN
   FETCH InvHdrCrs INTO
      @InvHdrRowPointer,
      @InvHdrCoNum,
      @InvHdrInvNum,
      @InvHdrInvSeq,
      @InvHdrBillType,
      @InvHdrCustNum,
      @InvHdrCustSeq,
      @CustLangCode

   IF @@FETCH_STATUS = -1
      BREAK

      IF  ISNULL(@CustLangCode,'') <> @LangCode
       CONTINUE

   -- keep track of which trackrows records to delete
   IF @Mode <> 'REPRINT'
      insert into @TR values(@InvHdrRowPointer)

   SET @CoRowPointer = NULL

   SELECT
        @CoRowPointer = co.RowPointer
   FROM co
   WHERE co.co_num = @InvHdrCoNum

   IF @CoRowPointer IS NULL
   BEGIN
      SET @Infobar = NULL
      IF @Mode <> 'REPRINT'
      BEGIN
         EXEC @Severity = dbo.MsgAppSp
                              @Infobar OUTPUT,
                              'E=CmdFailed'

         EXEC @Severity = dbo.MsgAppSp
                              @Infobar OUTPUT,
                              'E=NoExist1',
                              '@co',
                              '@co.co_num',
                              @InvHdrCoNum
      END
      ELSE
         EXEC @Severity = dbo.MsgAppSp
                     @Infobar OUTPUT,
                     'E=NoExistForIs1',
                     '@co',
                     '@co.co_num',
                     @InvHdrCoNum,
                     '@inv_hdr',
                     '@inv_hdr.inv_num',
                     @InvHdrInvNum

      INSERT INTO #tt_invoice_credit_memo ( tx_type,inv_num, inv_memo_num, co_num,ordererror )
      VALUES ( 999,@InvHdrInvNum, @InvHdrInvNum, @InvHdrCoNum,@infobar)

      IF @Severity > 0
      BEGIN
         SET @Severity = 0
         CONTINUE
      END
   END
   ELSE
   BEGIN
      SET @TPrintInvNum = @InvHdrInvNum
      SET @TPrintInvSeq = @InvHdrInvSeq

      SET @Progressive  =  CASE  WHEN @InvHdrBillType = 'P'
                                 THEN 1
                                 ELSE 0
                           END
                           
      EXEC @Severity = dbo.InvPrintSp
                           @Progressive,
                           @Mode,
                           @TPrintInvNum,
                           @TPrintInvSeq,
                           @PrintItemCustomerItem,
                           @TransToDomCurr,
                           @InvCred,
                           @PrintSerialNumbers,
                           @PrintPlanItemMaterial,
                           @PrintConfigurationDetail,
                           @PrintEuro,
                           @PrintCustomerNotes,
                           @PrintOrderNotes,
                           @PrintOrderLineNotes,
                           @PrintOrderBlanketLineNotes,
                           @PrintProgressiveBillingNotes,
                           @PrintInternalNotes,
                           @PrintExternalNotes,
                           @PrintItemOverview,
                           @PrintLineReleaseDescription,
                           @PrintStandardOrderText,
                           @PrintBillToNotes,
                           @Infobar OUTPUT,
                           @PrintDiscountAmt,
                           @PrintLotNumbers

      -- Populate header values into all rows
      SELECT
         @InvHdrInvNum          = inv_num,
         @InvHdrInvDate         = inv_date,
         @TSlsman               = inv_slsman,
         @TDescription          = inv_description,
         @TTaxIDLabel1          = inv_tax_num_lbl1,
         @TTaxRegNum1           = inv_tax_num1,
         @TTaxIDLabel2          = inv_tax_num_lbl2,
         @TTaxRegNum2           = inv_tax_num2,
         @TCustTaxIDLabel1      = inv_cust_tax_num_lbl1,
         @TCustRegNum1          = inv_cust_tax_num1,
         @TCustShipToRegNum1    = inv_cust_shipto_tax_num1,
         @TCustTaxIDLabel2      = inv_cust_tax_num_lbl2,
         @TCustRegNum2          = inv_cust_tax_num2,
         @TCustShipToRegNum2    = inv_cust_shipto_tax_num2,
         @TCurrDesc             = inv_curr_code,
         @CustNum               = cust_num,
         @CustSeq               = inv_cust_seq,
         @StrCustSeq            = inv_str_cust_seq,
         @TFaxNum               = inv_fax_num,
         @CoCoNum               = co_num,
         @LongCustPo            = inv_long_cust_po,
         @ShortCustPo           = inv_short_cust_po,
         @InvHdrQtyPackages     = inv_pkgs,
         @TWeight               = inv_weight,
         @ShipVia               = inv_shipvia,
         @Terms                 = inv_terms,
         @InvHdrInvNum          = inv_memo_num,
         @CoLcrNum              = lcr,
         @Addr0                 = OurAddress,
         @Addr1                 = BillToAddress,
         @Addr2                 = ShipToAddress,
         @PrintTaxInv           = (SELECT coparms.print_tax_invoice
                                   FROM coparms),
         @InvItemOrigInv        = orig_inv_num,
         @TaxSystemArApTaxRate1 = (SELECT tc.tax_rate
                                   FROM taxcode tc,tax_system ts
                                   WHERE ts.arap_tax_code = tc.tax_code and
                                         ts.tax_system = tc.tax_system and
                                         ts.tax_system = '1'),
         @TaxSystemArApTaxRate2 = (SELECT tc.tax_rate
                                   FROM taxcode tc,tax_system ts
                                   WHERE ts.arap_tax_code = tc.tax_code and
                                         ts.tax_system = tc.tax_system and
                                         ts.tax_system = '2'),
         @ApplyToInvNum         =  ISNULL((SELECT TOP 1 art.apply_to_inv_num
                                           FROM artran art
                                           WHERE art.inv_num = @InvHdrInvNum and
                                                 art.inv_seq = @InvHdrInvSeq ),
                                          (SELECT TOP 1 ari.apply_to_inv_num
                                           FROM arinv ari
                                           WHERE ari.inv_num = @InvHdrInvNum and
                                                 ari.inv_seq = @InvHdrInvSeq )),
        @TermsDiscountAmt       = TermsDiscountAmt
      FROM #tt_invoice_credit_memo
      WHERE #tt_invoice_credit_memo.Inv_num = @TPrintInvNum AND
            #tt_invoice_credit_memo.tx_type = 1

      UPDATE #tt_invoice_credit_memo
      SET
         inv_num                = @InvHdrInvNum,
         inv_date               = @InvHdrInvDate,
         inv_slsman             = @TSlsman,
         inv_description        = @TDescription,
         inv_tax_num_lbl1       = @TTaxIDLabel1,
         inv_tax_num1           = @TTaxRegNum1,
         inv_tax_num_lbl2       = @TTaxIDLabel2,
         inv_tax_num2           = @TTaxRegNum2,
         inv_cust_tax_num_lbl1  = @TCustTaxIDLabel1,
         inv_cust_tax_num1      = @TCustRegNum1,
         inv_cust_shipto_tax_num1 = @TCustShipToRegNum1,
         inv_cust_tax_num_lbl2  = @TCustTaxIDLabel2,
         inv_cust_tax_num2      = @TCustRegNum2,
         inv_cust_shipto_tax_num2 = @TCustShipToRegNum2,
         inv_curr_code          = @TCurrDesc,
         cust_num               = @CustNum,
         inv_cust_seq           = @CustSeq,
         inv_str_cust_seq       = @StrCustSeq,
         inv_fax_num            = @TFaxNum,
         co_num                 = @CoCoNum,
         inv_long_cust_po       = @LongCustPo,
         inv_short_cust_po      = @ShortCustPo,
         inv_pkgs               = @InvHdrQtyPackages,
         inv_weight             = @TWeight,
         inv_shipvia            = @ShipVia,
         inv_terms              = @Terms,
         inv_memo_num           = @InvHdrInvNum,
         lcr                    = @CoLcrNum,
         OurAddress             = @Addr0,
         BillToAddress          = @Addr1,
         ShipToAddress          = @Addr2,
         print_tax_invoice      = @PrintTaxInv,
         orig_inv_num           = ISNULL(@InvItemOrigInv,orig_inv_num),
         tax_system_rate1       = @TaxSystemArApTaxRate1,
         tax_system_rate2       = @TaxSystemArApTaxRate2
      WHERE #tt_invoice_credit_memo.Inv_num = @TPrintInvNum AND
            #tt_invoice_credit_memo.tx_type <> 1
   END

   BEGIN
      delete from #tt_invoice_draft
      Insert #tt_invoice_draft
      Exec dbo.Rpt_CoDDraftISp @InvCred = @InvCred ,@pInvHdrInvNum = @InvHdrInvNum,@pInvHdrCoNum = @InvHdrCoNum, @pVoidOrDraft = 'D' , @BGSessionId = @BGSessionId, @pSite = @pSite 
      Update #tt_invoice_credit_memo set
        t_tx_type = Draft.tx_type
      , t_co_num = Draft.co_num
      , t_rpt_key = Draft.rpt_key
      , t_parms_company = Draft.t_parms_company
      , t_parms_addr1 = Draft.t_parms_addr1
      , t_parms_addr2 = Draft.t_parms_addr2
      , t_parms_zip = Draft.t_parms_zip
      , t_parms_city1 = Draft.t_parms_city1
      , t_parms_city2 = Draft.t_parms_city2
      , t_arinv_amount1 = Draft.t_arinv_amount1
      , t_arinv_amount2 = Draft.t_arinv_amount2
      , t_arinv_inv_date = Draft.t_arinv_inv_date
      , t_arinv_due_date = Draft.t_arinv_due_date
      , t_cust_num = Draft.t_cust_num
      , t_inv_num = Draft.t_inv_num
      , t_bank_number = Draft.t_bank_number
      , t_branch_code = Draft.t_branch_code
      , t_bank_acct_no1 = Draft.t_bank_acct_no1
      , t_bank_acct_no2 = Draft.t_bank_acct_no2
      , t_bank_addr1 = Draft.t_bank_addr1
      , t_bank_addr2 = Draft.t_bank_addr2
      , t_custaddr_name = Draft.t_custaddr_name
      , t_custaddr_addr1 = Draft.t_custaddr_addr1
      , t_custaddr_zip = Draft.t_custaddr_zip
      , t_custaddr_city = Draft.t_custaddr_city
      , t_custdrft_draft_num = Draft.t_custdrft_draft_num 
      from #tt_invoice_draft Draft
      where Draft.inv_num = #tt_invoice_credit_memo.inv_num and #tt_invoice_credit_memo.inv_num = @InvHdrInvNum
   END

   BEGIN
      delete from #tt_invoice_draft
      Insert #tt_invoice_draft
      Exec dbo.Rpt_CoDDraftISp @InvCred = @InvCred ,@pInvHdrInvNum = @InvHdrInvNum,@pInvHdrCoNum = @InvHdrCoNum, @pVoidOrDraft = 'V' , @BGSessionId = @BGSessionId, @pSite = @pSite 

     Select  @tTopCount = count(1) from #tt_invoice_credit_memo where #tt_invoice_credit_memo.inv_num = @InvHdrInvNum
     Set @tTopCount= CASE  WHEN @tTopCount <= 0
                              THEN 0
                              ELSE @tTopCount - 1
                        END
     If @tTopCount > 0
     Begin
        Update #tt_invoice_credit_memo set
          t_tx_type = Draft.tx_type
        , t_co_num = Draft.co_num
        , t_rpt_key = Draft.rpt_key
        , t_parms_company = Draft.t_parms_company
        , t_parms_addr1 = Draft.t_parms_addr1
        , t_parms_addr2 = Draft.t_parms_addr2
        , t_parms_zip = Draft.t_parms_zip
        , t_parms_city1 = Draft.t_parms_city1
        , t_parms_city2 = Draft.t_parms_city2
        , t_arinv_amount1 = Draft.t_arinv_amount1
        , t_arinv_amount2 = Draft.t_arinv_amount2
        , t_arinv_inv_date = Draft.t_arinv_inv_date
        , t_arinv_due_date = Draft.t_arinv_due_date
        , t_cust_num = Draft.t_cust_num
        , t_inv_num = Draft.t_inv_num
        , t_bank_number = Draft.t_bank_number
        , t_branch_code = Draft.t_branch_code
        , t_bank_acct_no1 = Draft.t_bank_acct_no1
        , t_bank_acct_no2 = Draft.t_bank_acct_no2
        , t_bank_addr1 = Draft.t_bank_addr1
        , t_bank_addr2 = Draft.t_bank_addr2
        , t_custaddr_name = Draft.t_custaddr_name
        , t_custaddr_addr1 = Draft.t_custaddr_addr1
        , t_custaddr_zip = Draft.t_custaddr_zip
        , t_custaddr_city = Draft.t_custaddr_city
        , t_custdrft_draft_num = Draft.t_custdrft_draft_num
        from #tt_invoice_draft Draft,
        (SELECT TOP (@tTopCount) #tt_invoice_credit_memo.rpt_key as rpt_key,
                  #tt_invoice_credit_memo.ser_num as ser_num,
                  #tt_invoice_credit_memo.ser_num as Kit_Flag,
                  #tt_invoice_credit_memo.inv_num as inv_num
               FROM #tt_invoice_credit_memo
              where #tt_invoice_credit_memo.inv_num = @InvHdrInvNum
            ORDER BY #tt_invoice_credit_memo.rpt_key, #tt_invoice_credit_memo.ser_num, #tt_invoice_credit_memo.Kit_Flag) as memo
        where Draft.inv_num = #tt_invoice_credit_memo.inv_num and Draft.inv_num = memo.inv_num and
            memo.rpt_key = #tt_invoice_credit_memo.rpt_key and #tt_invoice_credit_memo.inv_num = @InvHdrInvNum

      End
   END


END
CLOSE      InvHdrCrs
DEALLOCATE InvHdrCrs

UPDATE #tt_invoice_credit_memo
SET Dom_Price_Format = dbo.FixMaskForCrystal(curr.cst_prc_format, dbo.GetWinRegDecGroup()),
    Dom_Price_Places = curr.places_cp,
    Dom_Amount_Format = dbo.FixMaskForCrystal(curr.amt_format, dbo.GetWinRegDecGroup()),
    Dom_Amount_Places = curr.Places
FROM #tt_invoice_credit_memo
INNER JOIN custaddr AS cust ON #tt_invoice_credit_memo.cust_num = cust.cust_num AND cust.cust_seq = 0
INNER JOIN currency AS curr ON cust.curr_code = curr.curr_code

UPDATE #tt_invoice_credit_memo
SET Dom_Amount_Format = dbo.FixMaskForCrystal(curr.amt_tot_format, dbo.GetWinRegDecGroup())
FROM #tt_invoice_credit_memo
INNER JOIN custaddr AS cust ON #tt_invoice_credit_memo.cust_num = cust.cust_num AND cust.cust_seq = 0
INNER JOIN currency AS curr ON cust.curr_code = curr.curr_code
WHERE #tt_invoice_credit_memo.TX_Type = 21

UPDATE #tt_invoice_credit_memo
SET qty_unit_format = @QtyUnitFormat,
    places_qty_unit = @PlacesQtyUnit,
    url = @URL,
    email_addr = @EmailAddr
    

UPDATE #tt_invoice_credit_memo
SET tax_system1_enabled = tt.Tax_system,tax_mode1 = tt.tax_mode,tax_disc_allow1 = tt.tax_disc_allow
FROM Tax_System tt
WHERE tt.Tax_System =1

UPDATE #tt_invoice_credit_memo
SET tax_system2_enabled = tt.Tax_system,tax_mode2 = tt.tax_mode,tax_disc_allow2 = tt.tax_disc_allow
FROM Tax_System tt
WHERE tt.Tax_System =2

UPDATE #tt_invoice_credit_memo
SET print_tax_invoice = @PrintTaxInv


UPDATE #tt_invoice_credit_memo SET  terms_pct = terms.disc_pct from terms,  inv_hdr, #tt_invoice_credit_memo
where inv_hdr.Terms_code=terms.terms_code and inv_hdr.inv_num=#tt_invoice_credit_memo.inv_num

UPDATE #tt_invoice_credit_memo SET  terms_pct = isnull(terms_pct,0)

UPDATE #tt_invoice_credit_memo 
SET  demand_site_PO = co.demanding_site_po_num 
FROM #tt_invoice_credit_memo 
INNER JOIN co ON #tt_invoice_credit_memo.co_num = co.co_num 
WHERE co.demanding_site_po_num IS NOT NULL AND co.demanding_site IS NOT NULL

-------delete temporary records from TrackRows-----
IF @Mode <> 'REPRINT'
   delete trackrows
   from @TR as tr
   where tr.RowPointer = trackrows.RowPointer
   and trackrows.SessionID = @pSessionID
   and trackrows.trackedopertype = 'inv_hdr'
-----------------

declare ciCrs cursor local static for
select distinct inv_num
from #tt_invoice_credit_memo

open ciCrs

while 1=1
begin
   fetch ciCrs into
     @InvNum
   if @@fetch_status != 0
      break

   set @CoSurcharge = 0
   select @CoSurcharge = SUM(surcharge) FROM inv_item_surcharge WHERE inv_num = @InvNum
   if @CoSurcharge is null
      set @CoSurcharge = 0

   if @CoSurcharge != 0
      UPDATE #tt_invoice_credit_memo
      SET inv_total = inv_total + @CoSurcharge
      FROM #tt_invoice_credit_memo
      WHERE #tt_invoice_credit_memo.inv_num = @InvNum
end
close ciCrs
deallocate ciCrs

-- _KPI - Packing Slip Number
update #tt_invoice_credit_memo
set pack_num_1 = pck.pack_num
from #tt_invoice_credit_memo tt
join pckitem pck on 
	 pck.inv_num = tt.inv_num
 

-------------------------------------------------------


declare @KPI_PackingInfo table
(
InvNum nvarchar(12),
CoNum nvarchar(10),
CoLine integer,
CoRelease integer,
SerialLotString nvarchar(3000)

) 
 
 declare @KPIBC table
(
InvNum nvarchar(12),
CoNum nvarchar(10),
CoLine integer,
CoRelease integer,
BarCode nvarchar(100),
SerialLotString nvarchar(100),
Processed integer
)
insert @KPI_PackingInfo select distinct 
	rs.inv_num, rs.co_num, rs.co_line, 0, ''
	from #tt_invoice_credit_memo rs

insert  @KPIBC 
select 
 bc.InvNum,
 bc.RefNum, 
 bc.RefLine, 
 0, 
 bc.BarCode,
 case 
	when isnull(bc.Lot, '')  = '' then '' 
	else 'Lot: ' + bc.Lot + + char(10) + char(13)
 end
 + case 
	when ISNULL(bc.SerialNum, 'N/A') = 'N/A' then ''
	
	else ' SN: ' + ISNULL(bc.SerialNum, '')
end,
  0
from 
         _KPI_BarCodes bc where bc.InvNum >= @StartInvNum
   AND   bc.invnum <= @EndInvNum


declare @KPISerialLotString nvarchar(100)
declare @KPIInvNum nvarchar(12)
declare @KPICoNum nvarchar(10)
declare @KPICoLine integer
declare @KPIBarcode nvarchar(100)


while (1=1)
begin
	select  
	   @KPISerialLotString = '',
	   @KPIInvNum = '',
	   @KPICoNum = '',
	   @KPICoLine = '',
	   @KPIBarcode = ''
	select 
	   @KPISerialLotString = bc.SerialLotString,
	   @KPIInvNum = bc.InvNum,
	   @KPICoNum = bc.CoNum,
	   @KPICoLine = bc.CoLine,
	   @KPIBarcode = bc.BarCode
	   
	  from @KPIBC bc where Processed = 0
	  
		  
	  if ISNULL(@KPIInvNum,'') = '' break
	  update @KPIBC
	  set Processed = 1 where BarCode = @KPIBarcode
	  
	  update
	   @KPI_PackingInfo
	   set  SerialLotString  = isnull(SerialLotString, '') + ISNULL(@KPISerialLotString, '') + char(10) + char(13)
	   from @KPI_PackingInfo kpi where 
			kpi.InvNum = @KPIInvNum and
			kpi.CoNum = @KPICoNum and
			kpi.CoLine = @KPICoLine and
			kpi.CoRelease = 0
	 
end	 

-----------------------------------------------------------

SELECT isnull(pckinfo.SerialLotString, '') as  SerialLot ,
isnull(co.Uf_LineDisc, 0) as KPIDISC, isnull(coi.disc, 0) as KPILineDisc,
tt.*, coi.promotion_code,@CoSurcharge AS surcharge,it.item_content, dbo.DisplayAddressForReportFooter() AS ParmsSingleLineAddress,it.drawing_nbr,
coi.delterm, coi.ec_code, coi.origin, coi.comm_code, del_term.description, itemcust.end_user, 
isnull(ari.due_date, ar.due_date) as due_date, bank_hdr.name AS t_bank_name , bank_hdr.bank_transit_num AS t_bank_transit_num
,bank_hdr.bank_acct_no AS t_bank_acct_no
FROM #tt_invoice_credit_memo tt
left outer join @KPI_PackingInfo pckinfo on 
			pckinfo.InvNum = tt.inv_num and
			pckinfo.CoNum = tt.co_num and
			pckinfo.CoLine = substring(tt.str_co_line,1,4)
Left Outer join co (nolock)  on co.co_num = tt.co_num
LEFT JOIN item (nolock)AS it ON tt.item1 = it.item
Left join coitem coi (nolock)on tt.co_num = coi.co_num and substring(tt.str_co_line,1,4) = coi.co_line and 
substring(tt.str_co_line,7,4) = coi.co_release
LEFT JOIN itemcust (nolock) ON itemcust.cust_item = coi.cust_item AND itemcust.item = coi.item AND itemcust.cust_num = coi.co_cust_num
LEFT JOIN del_term ON del_term.delterm = coi.delterm
LEFT JOIN arinv ari ON ari.inv_num = tt.inv_num
-- _KPI correct the due date issue
left join artran ar (nolock) on 
		ar.inv_num = tt.inv_num and 
		ar.type = 'I' 
LEFT JOIN customer ON customer.cust_num = tt.cust_num AND customer.cust_seq = 0

--LEFT JOIN bank_hdr ON customer.cust_bank = bank_hdr.bank_code

LEFT JOIN bank_hdr on customer.bank_code = bank_hdr.bank_code
ORDER BY tt.rpt_key, tt.ser_num, tt.Kit_Flag, tt.multi_due_date

COMMIT TRANSACTION
--Added to call Mexican Country Pack program
--IF OBJECT_ID(N'dbo.ZMX_CFDGenSp') IS NOT NULL
--BEGIN
--    SET @EXTGEN_SpName = N'dbo.ZMX_CFDGenSp'
--    EXEC @EXTGEN_SpName    
--         @Progressive                 = @Progressive ,
--         @Mode                        = @Mode ,
--         @PrintItemCustomerItem       = @PrintItemCustomerItem ,
--         @InvCred                     = @InvCred ,
--         @PrintSerialNumbers          = @PrintSerialNumbers ,
--         @PrintPlanItemMaterials      = @PrintPlanItemMaterial ,
--         @PrintConfigurationDetail    = @PrintConfigurationDetail ,
--         @PrintEuro                   = @PrintEuro ,
--         @PrintLineReleaseDescription = @PrintLineReleaseDescription ,
--         @PrintStandardOrderText      = @PrintStandardOrderText ,
--         @PrintDiscountAmt            = @PrintDiscountAmt,
--         @TransToDomCurr              = @TransToDomCurr ,
--         @PrintCustomerNotes          = @PrintCustomerNotes ,
--         @PrintOrderNotes             = @PrintOrderNotes,
--         @PrintLinesNotes             = @PrintOrderLineNotes ,
--         @PrintProgBillNotes          = @PrintProgressiveBillingNotes ,
--         @PrintInternalNotes          = @PrintInternalNotes ,
--         @PrintExternalNotes          = @PrintExternalNotes ,
--         @TableName                   = 'order'
--END

EXEC dbo.CloseSessionContextSp @SessionID = @RptSessionID

RETURN @Severity



GO


