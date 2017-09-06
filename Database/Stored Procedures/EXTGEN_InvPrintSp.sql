USE [KPI_App]
GO

/****** Object:  StoredProcedure [dbo].[InvPrintSp]    Script Date: 09/06/2017 11:23:01 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- Converted from co\invprint.p

/* $Header: /ApplicationDB/Stored Procedures/InvPrintSp.sp 71    3/27/14 4:24a Igui $ */
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
/* $Archive: /ApplicationDB/Stored Procedures/InvPrintSp.sp $
 *
 * SL9.00 71 176536 Igui Thu Mar 27 04:24:22 2014
 * New Extended Tax value seems to be pulling from wrong place
 * issue 176536(RS6307)
 * Add parameter @ExtendedTax to get Extended Tax value from inv_stax.sales_tax directly.
 *
 * SL9.00 70 177392 Igui Wed Mar 26 04:28:31 2014
 * No return address printing on the Order invoice and Contact before Company
 * issue 177392(RS6307)
 * Get BillToAddress(Add1) and ShipToAddress(Add2) from FormatAddressWithContactSp directly.
 *
 * SL9.00 69 171385 Mding2 Fri Dec 27 05:30:01 2013
 * Germany Country Pack - Report layout changes
 * Issue 171385 - Re-write logic for using Alternate Address Report Formatting.
 *
 * SL8.04 68 160398 Cliu Tue Apr 23 03:44:56 2013
 * Reprinting all Credit Memos for a specific date range will reprint all Invoices
 * Issue:160398
 * Modify the restriction from "(@InvCred = 'C')'" to "(@Mode <> 'REPRINT' AND @InvCred = 'C')"
 *
 * SL8.04 67 156737 calagappan Fri Dec 28 17:31:29 2012
 * Invoicing runs were now producing several thousands (close to 70k) of print and reprint requests.
 * Do not reset value of @Mode
 *
 * SL8.04 66 RS5566 Cliu Fri Oct 19 01:52:17 2012
 * Call IsAddonAvailable function (rather than checking for the existence of a CCI table) to determine whether to call the CCI SP.
 * RS5566
 *
 * SL8.04 65 152908 pgross Wed Sep 05 10:46:02 2012
 * Credit Memo with 0 amount appears as Regular Invoice
 * display CREDIT MEMO when processing zero-amount Credit Memos
 *
 * SL8.04 64 RS5200 jzhou Fri Aug 24 02:03:04 2012
 * RS5200:
 * Add parameter '@PrintItemOverview'.
 *
 * SL8.04 63 149080 calagappan Thu Jul 05 17:05:43 2012
 * ReUsed Serial Number does not print on invoice
 * Reset invoice and reference numbers after credit memo is generated
 *
 * SL8.03 62 144061 Mmarsolo Wed Oct 19 13:28:22 2011
 * Invoices always show tax summary footer even when you turn it off on the Tax Parameters form.
 * 144061 - Only show tax footer if prt_tax_footer = 1.
 *
 * SL8.03 61 142284 pgross Wed Sep 07 16:33:28 2011
 * Order Invoicing - Prints "***NON-NEGOTIABLE***" at the bottom of all zero dollar invoices.
 * removed printing of "NON-NEGOTIABLE"
 *
 * SL8.03 60 RS4768 Xliang Fri Jun 03 04:55:32 2011
 * rs4768: add "Print Lot Number" print option.
 *
 * SL8.03 59 129713 calagappan Wed Sep 01 16:18:30 2010
 * Sales Reps Name appears inconsistently on invoices
 * format employee name
 *
 * SL8.02 58 rs4588 Dahn Thu Mar 04 14:37:14 2010
 * rs4588 copyright header changes
 *
 * SL8.01 57 115920 pgross Wed Jan 07 14:03:37 2009
 * When printing a customer order where the ship to address is in a different country on the Order Invoicing Credit Memo form, the invoice printed out has picked up the VAT number of the main invoice address but the country code of the ship to.
 * retrieve Ship To Tax information from TaxIdSp
 *
 * SL8.01 56 115866 calagappan Fri Dec 05 17:59:35 2008
 * When reprinting a customer order invoice on the Order Invoicing/Credit Memo form after changing the tax rate has changed, the tax rate on the reprinted invoice comes up with the new amended tax rate instead of the original tax rate used.
 * Obtain historic tax rates for display.
 *
 * SL8.01 55 114566 calagappan Thu Oct 16 15:01:23 2008
 * When printing a customer order where the ship to address is in a different country on the Order Invoicing Credit Memo form, the invoice printed out has picked up the VAT number of the main invoice address but the country code of the ship to.
 * Print Bill To's concatenated tax registration numbers.
 *
 * SL8.01 54 114054 calagappan Mon Sep 29 17:13:10 2008
 * Tax code labels are not printing properly on the Order Invoicing report.
 * Display tax amount labels from Tax System form.
 *
 * SL8.01 53 114102 calagappan Wed Sep 24 17:42:52 2008
 * Invoice number is set to 0
 * Do not update serial table when reprinting.
 *
 * SL8.01 52 rs3953 Vlitmano Tue Aug 26 17:05:27 2008
 * RS3953 - Changed a Copyright header?
 *
 * SL8.01 51 rs3953 Vlitmano Mon Aug 18 15:26:59 2008
 * Changed a Copyright header information(RS3959)
 *
 * SL8.01 50 RS4088 dgopi Tue May 20 04:54:49 2008
 * Making modifications as per RS4088
 *
 * SL8.01 49 RS4088 dgopi Tue May 20 04:38:56 2008
 * RS4088
 *
 * SL8.01 48 108393 pgross Fri Mar 21 15:12:08 2008
 * Error returned in BGTaskHistory on everyother invoice
 * made changes to work around SQL 64-bit bug
 *
 * SL8.00 47 103488 Mkurian Mon Aug 06 07:15:29 2007
 * Extraneous field with EU set up
 * The value of TTaxRegNum2 is being set only if there exists a tax system 2.
 * issue 103488 
 *
 * SL8.00 46 104006 hcl-kumarup Fri Jul 27 04:30:29 2007
 * Incorrect fax number displaying on invoice if ship to is other than zero
 * Checked-in for issue# 104006
 * Removed fetching of Fax Number for Ship To. As Reports only display Fax Number for Bill To so Fax Number will be fetched for Bill To only.
 *
 * SL8.00 45 RS2968 nkaleel Fri Feb 23 03:11:04 2007
 * changing copyright information
 *
 * SL8.00 44 RS3339 nvennapu Thu Jan 18 06:55:56 2007
 * for RS 3339
 *
 * SL8.00 43 96378 Hcl-ajain Fri Sep 22 01:00:13 2006
 * Order Header notes are printing after the Tax Basis Summary
 * Issue # 96378
 * changed rpt_key string  from 'xxx...' to 'yyy...' in case of tx_type=20
 * changed rpt_key string  from 'xxx...' to 'zzz...' in case of tx_type=21
 *
 * SL8.00 42 RS2968 prahaladarao.hs Tue Jul 11 09:32:30 2006
 * RS 2968, Name change CopyRight Update.
 *
 * SL8.00 41 94783 sarin.s Wed Jun 21 02:35:33 2006
 * GST value and text not printing on invoice
 * 94783
 * Checked for inv_sales_tax & inv_sales_tax2 fields of table #tt_invoice_credit_memo and converted it to zero if null
 *
 * SL8.00 40 92600 hcl-kumarup Thu Mar 02 04:07:50 2006
 * With fix for APAR 101650, a section for Tax Basis Summary is printing on all invoices, regardless of the parameter setting in Tax Parameters
 * Checked-in for issue #92600
 * Avoiding tax summary print when print tax code and print tax footer option is unchchecked in tax parameters form
 *
 * SL8.00 39 92715 sarin.s Wed Mar 01 09:09:51 2006
 * Euro total field prints unconditionally
 * Issue 92715 :-
 * Whatever Changes mentioned in Note 95355 had been implemented.
 *
 * SL8.00 38 92529 hcl-kumarup Wed Feb 15 00:43:02 2006
 * Fix done for issue 91711 needs to be backed out
 * Checked in for Issue# 92529
 * Fix done for issue 91711 has been backed out
 *
 * SL8.00 37 91433 djohnson Tue Jan 31 14:17:54 2006
 * Tax basis amounts not in domestic currency when translated
 * #91433 - tax basis not converted to domestic when translate to domestic
 *   is checked.
 *
 * SL8.00 36 91934 hcl-kumarup Tue Jan 31 06:08:33 2006
 * Tax Basis Summary not displaying Tax Codes on Invoice
 * Checked in for Issue #91934
 * Edited InvPrintSp to print tax code for the item
 *
 * SL8.00 35 92043 pcoate Fri Jan 20 10:52:15 2006
 * Order Invoicing Credit Memo - Progressive Billing
 * Issue 92043 - Print tax footer only when taxparms.prt_tax_footer = 1.
 *
 * SL8.00 34 91818 NThurn Mon Jan 09 10:31:21 2006
 * Inserted standard External Touch Point call.  (RS3177)
 *
 * SL7.05 33 91711 hcl-kumarup Fri Jan 06 01:24:11 2006
 * Fed ID from ship 0 printing on all ship to 1 + invoices
 * Checked in for Issue #91711
 * Made changes in query to get FedID with reference of CO
 *
 * SL7.05 32 91110 hcl-singind Tue Dec 27 02:04:46 2005
 * Issue #: 91110
 * Added "WITH (READUNCOMMITTED)" to co Select Statement.
 *
 * SL7.05 31 88560 hcl-kumarup Tue Nov 08 06:08:55 2005
 * Order Discount type of amount used but % still being applied to invoice print
 * Checked in for Issue #88560
 * Taken the reference of Inv_Hdr.Disc_Amount field instead of calculating through Inv_Hdr.Disc, the % basis in InvPrintSp
 *
 * SL7.05 30 RS2560 Hcl-sharpar Wed Sep 07 07:06:51 2005
 * RS2560
 *
 * SL7.05 29 87535 Hcl-dixichi Wed Jul 13 06:29:22 2005
 * The Tax Footer - Tax Basis summary is no longer printed on invoices/credits/debit memos even though the Print Tax Footer option has been selected on the Tax Parameters.
 * Checked-in for issue 87535
 * Added statement to insert a line in table '#tt_invoice_credit_memo' for Tax Basis Summary section lables.
 *
 * SL7.05 28 87629 Hcl-haldsub Thu Jun 09 06:00:39 2005
 * Undo the changes for RS1757
 * ISSUE 87629
 * Codes for RS 1757 have been reverted back.
 *
 * SL7.05 27 86875 Hcl-sharpar Thu Apr 14 08:45:24 2005
 * DCR for Stub calls needed for French Localization
 * Issue #86875
 * Implemented DCR for Project 1757 Country Pack for France.
 *
 * SL7.05 26 86508 Hcl-sharpar Wed Mar 30 10:17:05 2005
 * Stub calls needed for French Localization
 * Issue 86508
 * Stub processing for French Country Pack
 * RS 1757 - Design Class - InvPrint
 *
 * SL7.04 26 86508 Hcl-sharpar Wed Mar 30 09:32:24 2005
 * Stub calls needed for French Localization
 * Issue 86508
 * Stub processing for French Country Pack
 * RS 1757 - Design Class - InvPrint
 *
 * $NoKeywords: $
 */
CREATE PROCEDURE [dbo].[InvPrintSp] (
   @Progressive                  ListYesNoType = 0,
   @Mode                         NVARCHAR(20)  = 'REPRINT',
   @TPrintInvNum                 InvNumType    = NULL   OUTPUT,
   @TPrintInvSeq                 InvSeqType    = 0      OUTPUT,
   @PrintItemCustomerItem        nvarchar(2)   = 'IC',
   @TransToDomCurr               ListYesNoType = 1,
   @InvCred                      nvarchar(1)   = 'I',
   @PrintSerialNumbers           ListYesNoType = 0,
   @PrintPlanItemMaterials       ListYesNoType = 0,
   @PrintConfigrationDetail      nvarchar(1)   = 'N',
   @PrintEuro                    ListYesNoType = 0,
   @PrintCustomerNotes           ListYesNoType = 0,
   @PrintOrderNotes              ListYesNoType = 0,
   @PrintOrderLineNotes          ListYesNoType = 0,
   @PrintOrderBlanketLineNotes   ListYesNoType = 0,
   @PrintProgressiveBillingNotes ListYesNoType = 0,
   @PrintInternalNotes           ListYesNoType = 0,
   @PrintExternalNotes           ListYesNoType = 0,
   @PrintItemOverview			 ListYesNoType = 0,
   @PrintLineReleaseDescription  ListYesNoType = 0,
   @PrintStandardOrderText       ListYesNoType = 0,
   @PrintBillToNotes             ListYesNoType = 0,
   @Infobar                      InfobarType   = NULL      OUTPUT,
   @PrintDiscountAmt             ListYesNoType = 0,
   @PrintLotNumbers              ListYesNoType = 0
)
AS

   -- Check for existence of Generic External Touch Point routine (this section was generated by SpETPCodeSp and inserted by CallETPs.exe):
   IF OBJECT_ID(N'dbo.EXTGEN_InvPrintSp') IS NOT NULL
   BEGIN
      DECLARE @EXTGEN_SpName sysname
      SET @EXTGEN_SpName = N'dbo.EXTGEN_InvPrintSp'
      -- Invoke the ETP routine, passing in (and out) this routine's parameters:
      DECLARE @EXTGEN_Severity int
      EXEC @EXTGEN_Severity = @EXTGEN_SpName
         @Progressive
         , @Mode
         , @TPrintInvNum OUTPUT
         , @TPrintInvSeq OUTPUT
         , @PrintItemCustomerItem
         , @TransToDomCurr
         , @InvCred
         , @PrintSerialNumbers
         , @PrintPlanItemMaterials
         , @PrintConfigrationDetail
         , @PrintEuro
         , @PrintCustomerNotes
         , @PrintOrderNotes
         , @PrintOrderLineNotes
         , @PrintOrderBlanketLineNotes
         , @PrintProgressiveBillingNotes
         , @PrintInternalNotes
         , @PrintExternalNotes
		 , @PrintItemOverview
         , @PrintLineReleaseDescription
         , @PrintStandardOrderText
         , @PrintBillToNotes
         , @Infobar OUTPUT
         , @PrintDiscountAmt
         , @PrintLotNumbers
 
      -- ETP routine can RETURN 1 to signal that the remainder of this standard routine should now proceed:
      IF @EXTGEN_Severity <> 1
         RETURN @EXTGEN_Severity
   END
   -- End of Generic External Touch Point code.
 
   DECLARE
      @Severity            INT,
      @TSubPrice           AmountType,
      @TDiscCiPrice        AmountType,
      @TTaxRegNum1         WideTextType,
      @TTaxRegNum2         WideTextType,
      @TCustRegNum1        WideTextType,
      @TCustRegNum2        WideTextType,
      @TCustShipToRegNum1  WideTextType,
      @TCustShipToRegNum2  WideTextType,
      @Addr0               NVARCHAR(400), -- Our/Shipper Address
      @ParmsPhone          PhoneType,
      @Addr1               NVARCHAR(400), -- Bill To Address
      @BillToContact       ContactType,
      @Addr2               NVARCHAR(400), -- Ship To Address
      @ShipToContact       ContactType,
      @TSlsman             WideTextType,
      @TCorpCust           CustNumType,
      @TCorpAddress        ListYesNoType,
      @TCurrCode           CurrCodeType,
      @WordNumCurrCode     CurrCodeType,
      @TDescription        DescriptionType,
      @TCoText1            ReportTxtType,
      @TCoText2            ReportTxtType,
      @TCoText3            ReportTxtType,
      @TcAmtSalesTax       AmountType,
      @TcAmtSalesTax2      AmountType,
      @TcAmtTotalPrice     AmountType,
      @TcAmtDisc           AmountType,
      @TcAmtNet            AmountType,
      @TcAmtMiscCharges    AmountType,
      @TcAmtFreight        AmountType,
      @TcAmtPrepaidAmt     AmountType,
      @TcAmtPrice          AmountType,
      @LongCustPo          WideTextType,
      @ShortCustPo         WideTextType,
      @TDiscMask           AmountType,
      @TcAmtNetMask        AmountType,
      @TCurrDesc           DescriptionType,
      @TFaxNum             PhoneType,
      @TEuroTotal          AmountType,
      @TStdDe              AmountType,
      @StdLo               FlagNYType,
      @TEuroUser           FlagNYType,    -- Only for EuroInfoSp
      @TEuroCurr           CurrCodeType,   -- Only for EuroInfoSp
      @AmtTotal            WideTextType,
      @TTotalAmount        AmountType,
      @ArtranDiscAmt       AmountType,
      @ArinvAmount         AmountType,
      @TermsDiscPct        ApDiscType,
      @TermsDiscountAmt    AmountType

   DECLARE
      @TTaxIDLabel1           TaxCodeLabelType,
      @TTaxIDLabel2           TaxCodeLabelType,
      @TCustTaxIDLabel        TaxCodeLabelType,
      @ShipVia                DescriptionType,
      @Terms                  DescriptionType,
      @RptKey                 NCHAR(50),
      @StrInvNum              NVARCHAR(12),
      @BillToRowPointer       RowPointerType,
      @BillToNotesFlag        FlagNyType,
      @ShipToCustRowPointer   RowPointerType,
      @ShipToCustNotesFlag    FlagNyType,
      @CoNotesFlag            FlagNyType,
      @TCorpAddr              ListYesNoType,
      @TEuroExists            ListYesNoType,
      @StrCustSeq             NCHAR(20),
      @TRate                  ExchRateType

   DECLARE
      @CustRowpointer      RowpointerType,
      @CustNum             CustNumType,
      @CustSeq             CustSeqType,
      @TaxCodeLabel        TaxCodeLabelType,
      @TaxSystem           TaxSystemType,
      @TaxCode             TaxCodeType,
      @TaxCodeELabel       TaxCodeLabelType,
      @TaxCodeE            TaxCodeType,
      @TaxRate             TaxRateType,
      @TaxBasis            AmountType,
      @ExtendedTax         AmountType,
      @TaxMode             TaxModeType,
      @TaxItemLabel        TaxCodeLabelType,
      @Rowpointer          RowPointerType

   -- Table Values
   DECLARE
      @ArtranRowpointer       RowPointerType,
      @CfgattrAttrValue       ConfigAttrValueType,
      @CfgattrAttrName        ConfigAttrNameType,
      @CoRowPointer           RowPointerType,
      @CoLcrNum               LcrNumType,
      @CoType                 CoTypeType,
      @CoCoNum                CoNumType,
      @CoIncludeTaxInPrice    ListYesNoType,
      @CoitemRowPointer       RowPointerType,
      @CoitemUM               UMType,
      @CoitemQtyOrdered       QtyUnitNoNegType,
      @CoitemQtyOrderedConv   QtyUnitNoNegType,
      @CoitemStat             CoitemStatusType,
      @CoitemQtyShipped       QtyUnitNoNegType,
      @CoitemItem             ItemType,
      @CoitemCustItem         CustItemType,
      @CoitemCoNum            CoNumType,
      @CoitemCoLine           CoLineType,
      @CoitemCoRelease        CoReleaseType,
      @CoitemShipDate         DateType,
      @CoitemFeatStr          FeatStrType,
      @CoitemCustNum          CustNumType,
      @CoitemCustSeq          CustSeqType,
      @CoShipShipDate         DateType,
      @CustomerRowPointer     RowPointerType,
      @CustomerLcrReqd        ListYesNoType,
      @CustomerLangCode       LangCodeType,
      @CustomerPayType        CustPayTypeType,
      @CustomerDraftPrintFlag ListYesNoType,
      @CustomerCustNum        CustNumType,
      @CustomerCustSeq        CustSeqType,
      @CustaddrRowPointer     RowPointerType,
      @CustaddrCurrCode       CurrCodeType,
      @CustaddrCorpAddress    ListYesNoType,
      @CustaddrCorpCust       CustNumType,
      @CustaddrFaxNum         PhoneType,
      @CustaddrCountry        CountryType,
      @CurrencyRowPointer     RowPointerType,
      @CurrencyDescription    DescriptionType,
      @CurrencyPlaces         DecimalPlacesType,
      @CurrencyCurrCode       CurrCodeType,
      @CurrparmsRowPointer    RowPointerType,
      @CurrparmsCurrCode      CurrCodeType,
      @DoHdrConsigneeContact  ContactType,
      @DoHdrConsigneeName     NameType,
      @DoHdrConsigneeAddr##1  AddressType,
      @DoHdrConsigneeAddr##2  AddressType,
      @DoHdrConsigneeAddr##3  AddressType,
      @DoHdrConsigneeAddr##4  AddressType,
      @DoHdrConsigneeCity     CityType,
      @DoHdrConsigneeState    StateType,
      @DoHdrConsigneeZip      PostalCodeType,
      @DoHdrConsigneeCountry  CountryType,
      @EmployeeRowPointer     RowPointerType,
      @EmployeeName           EmpNameType,
      @InvcLangRowPointer     RowPointerType,
      @InvcLangCoText##1      ReportTxtType,
      @InvcLangCoText##2      ReportTxtType,
      @InvcLangCoText##3      ReportTxtType,
      @InvHdrRowPointer       RowPointerType,
      @InvHdrCoNum            CoNumType,
      @InvHdrInvNum           InvNumType,
      @InvHdrInvSeq           InvSeqType,
      @InvHdrCustNum          CustNumType,
      @InvHdrCustSeq          CustSeqType,
      @InvHdrBillType         BillingTypeType,
      @InvHdrPrice            AmountType,
      @InvHdrCustPo           CustPoType,
      @InvHdrSlsman           SlsmanType,
      @InvHdrQtyPackages      PackagesType,
      @InvHdrInvDate          DateType,
      @InvHdrWeight           WeightType,
      @InvHdrPrepaidAmt       AmountType,
      @InvHdrDisc             OrderDiscType,
      @InvHdrMiscCharges      AmountType,
      @InvHdrFreight          AmountType,
      @InvHdrExchRate         ExchRateType,
      @InvHdrPkgs             PackagesType,
      @InvHdrTaxCode1         TaxCodeType,
      @InvHdrTaxCode2         TaxCodeType,
      @InvHdrTermsCode        TermsCodeType,
      @InvHdrShipCode         ShipCodeType,
      @InvHdrNoteExistsFlag   ListYesNoType,
      @InvItemInvNum          InvNumType,
      @InvItemCoNum           CoNumType,
      @invItemInvLine         InvLineType,
      @InvStaxTaxSystem       TaxSystemType,
      @InvStaxSalesTax        AmountType,
      @NotesRowPointer        RowPointerType,
      @NotesTxt               DescriptionType,
      @ParmsCoText1           ReportTxtType,
      @ParmsCoText2           ReportTxtType,
      @ParmsCoText3           ReportTxtType,
      @ParmsPrtName           ListYesNoType,
      @ParmsSite              SiteType,
      @SerialRowPointer       RowPointerType,
      @SerialSerNum           SerNumType,
      @ShipcodeRowPointer     RowPointerType,
      @ShipcodeShipCode       ShipCodeType,
      @ShipcodeDescription    DescriptionType,
      @ShipLangRowPointer     RowPointerType,
      @ShipLangDescription    DescriptionType,
      @SlsmanRowPointer       RowPointerType,
      @SlsmanOutside          ListYesNoType,
      @SlsmanRefNum           EmpVendNumType,
      @TaxparmsRowPointer     RowPointerType,
      @TaxParmsPrtTaxFooter   ListYesNoType,
      @TaxSystemTaxSystem     TaxSystemType,
      @TaxSystemTaxItemLabel  TaxCodeLabelType,
      @TaxSystemTaxAmtLabel1  TaxCodeLabelType,
      @TaxSystemTaxAmtLabel2  TaxCodeLabelType,
      @TaxcodeTaxCode         TaxCodeType,
      @TaxcodeDescription     DescriptionType,
      @TermsRowPointer        RowPointerType,
      @TermsTermsCode         TermsCodeType,
      @TermsDescription       DescriptionType,
      @TermLangRowPointer     RowPointerType,
      @TermLangDescription    DescriptionType,
      @TtCompConfigId         ConfigIdType,
      @TtCompCompId           ConfigCompIdType,
      @TtCompCompName         ConfigCompNameType,
      @TtCompQty              QtyUnitType,
      @TtCompPrice            CostPrcType,
      @VendaddrRowPointer     RowPointerType,
      @VendaddrName           NameType,
      @XCustomerRowPointer    RowPointerType,
      @XInvItemDoLine         DoLineType,
      @XInvItemDoSeq          DoSeqType,
      @XInvItemCustPo         CustPoType,
      @XInvItemTaxCode1       TaxCodeType,
      @XInvItemTaxCode2       TaxCodeType

   DECLARE
      @ArparmUsePrePrintedForms  ListYesNoType,
      @ArparmLinesPerInv      LinesPerDocType,
      @ArparmLinesPerDM       LinesPerDocType,
      @ArparmLinesPerCM       LinesPerDocType,
      @ApplyToInvNum          InvNumType,
      @Type                   NVARCHAR(1)

-- Fix for Issue # 73460 - when exporting to Word, need CR/LF
   DECLARE @CrLf   NVARCHAR(2)

   DECLARE @usemultiduedates ListYesNoType
   DECLARE @SSSCCIItem1 WideTextType  --SSS CCI

   SET @CrLf = CHAR(13) + CHAR(10)

   -- Init Local values
   SET @Severity           = 0
   SET @TSubPrice          = 0
   SET @TDiscCiPrice       = 0
   SET @Addr0              = NULL
   SET @ParmsPhone         = NULL
   SET @Addr1              = NULL
   SET @BillToContact      = NULL
   SET @Addr2              = NULL
   SET @ShipToContact      = NULL
   SET @TSlsman            = NULL
   SET @TCorpCust          = NULL
   SET @TCorpAddress       = 0

   SET @TCurrCode          = NULL
   SET @WordNumCurrCode    = NULL
   SET @TDescription       = NULL
   SET @TCoText1           = NULL
   SET @TCoText2           = NULL
   SET @TCoText3           = NULL
   SET @TcAmtSalesTax      = 0
   SET @TcAmtSalesTax2     = 0
   SET @TcAmtTotalPrice    = 0
   SET @TcAmtDisc          = 0
   SET @TcAmtNet           = 0
   SET @TcAmtMiscCharges   = 0
   SET @TcAmtFreight       = 0
   SET @TcAmtPrepaidAmt    = 0
   SET @TcAmtPrice         = 0
   SET @LongCustPo         = NULL
   SET @ShortCustPo        = NULL
   SET @TDiscMask          = 0
   SET @TcAmtNetMask       = 0
   SET @AmtTotal           = NULL
   SET @TTotalAmount       = 0

   SET @TCurrDesc          = NULL
   SET @TFaxNum            = NULL
   SET @TEuroTotal         = 0
   SET @TStdDe             = 0
   SET @StdLo              = 0
   SET @TEuroUser          = 0
   SET @TEuroCurr          = NULL
   SET @TTaxIDLabel1       = NULL
   SET @TTaxIDLabel2       = NULL
   SET @TCustTaxIDLabel    = NULL
   SET @ShipVia            = NULL
   SET @Terms              = NULL
   SET @TRate              = 0
   SET @CustNum            = NULL
   SET @CustSeq            = 0
   SET @StrCustSeq         = NULL
   SET @RptKey             = NULL
   SET @StrInvNum          = NULL

   SET @BillToRowPointer       = NULL
   SET @BillToNotesFlag        = 0
   SET @ShipToCustRowPointer   = NULL
   SET @ShipToCustNotesFlag    = 0
   SET @CoNotesFlag            = 0
   SET @TEuroExists            = 0
   SET @TCorpAddr              = 0
   SET @TaxCodeLabel           = NULL
   SET @TaxSystem              = 0
   SET @TaxCode                = NULL
   SET @TaxCodeELabel          = NULL
   SET @TaxCodeE               = NULL
   SET @TaxRate                = 0
   SET @TaxBasis               = 0
   SET @ExtendedTax            = 0
   SET @TaxMode                = NULL
   SET @TaxItemLabel           = NULL
   SET @Rowpointer             = NULL


   IF OBJECT_ID('tempdb..#tt_tax_footer') IS NULL
   BEGIN
      SELECT
         @TaxCodeLabel     AS tax_code_lbl,
         @TaxCode          AS inv_tax_code,
         @TaxCodeELabel    AS tax_code_e_lbl,
         @TaxCodeE         AS tax_code_e,
         @TaxRate          AS tax_rate,
         @TaxBasis         AS tax_basis,
         @ExtendedTax      AS extended_tax,
         @RowPointer       AS rowpointer
      INTO #tt_tax_footer
      WHERE 1=2
   END

   IF OBJECT_ID('tempdb..#tt_invoice_credit_memo') IS NULL
      SELECT *
      INTO #tt_invoice_credit_memo
      FROM dbo.Rpt_OrderInvoicingCreditMemoSp()

   SET @ParmsCoText1 = NULL
   SET @ParmsCoText2 = NULL
   SET @ParmsCoText3 = NULL
   SELECT TOP 1
      @ParmsCoText1 = coparms.co_text_1,
      @ParmsCoText2 = coparms.co_text_2,
      @ParmsCoText3 = coparms.co_text_3
   FROM coparms

   SET @ParmsPrtName     = NULL
   SET @ParmsSite        = NULL
   SET @ParmsPhone       = NULL
   SET @Addr0            = NULL

   SELECT TOP 1
      @ParmsPrtName     = parms.print_name,
      @ParmsSite        = parms.site,
      @ParmsPhone       = ISNULL(parms.phone,'')
   FROM parms

   -- Set up Our Address
   IF @ParmsPrtName = 1
      SET @Addr0 = dbo.DisplayOurAddress() + CASE WHEN @ParmsPhone <> N'' THEN (CHAR(13) + CHAR(10)+ @ParmsPhone) ELSE @ParmsPhone END

   -- GET TAX ID LABELS
   SELECT @TTaxIDLabel1 = ISNULL(tax_system.tax_id_label,'')
   , @TaxSystemTaxAmtLabel1 = ISNULL(tax_system.tax_amt_label,'')
   FROM tax_system
   WHERE tax_system.tax_system = 1

   SELECT @TTaxIDLabel2 = ISNULL(tax_system.tax_id_label,'')
   , @TaxSystemTaxAmtLabel2 = ISNULL(tax_system.tax_amt_label,'')
   FROM tax_system
   WHERE tax_system.tax_system = 2

   SET @TTaxIDLabel1 =  CASE  WHEN @TTaxIDLabel1 <> ''
                              THEN @TTaxIDLabel1 + ':'
                              ELSE @TTaxIDLabel1
                        END

   SET @TTaxIDLabel2 =  CASE  WHEN @TTaxIDLabel2 <> ''
                              THEN @TTaxIDLabel2 + ':'
                              ELSE @TTaxIDLabel2
                        END

   SET @TaxparmsRowPointer = NULL
   SET @TaxParmsPrtTaxFooter = 0

   SELECT
      @TaxparmsRowPointer = taxparms.RowPointer,
      @TaxParmsPrtTaxFooter = CASE WHEN taxparms.prt_tax_footer =1 THEN 1 ELSE 0 END
   FROM taxparms

   IF @TaxparmsRowPointer IS NULL
   BEGIN
      SET @Infobar = NULL
      EXEC @Severity = dbo.MsgAppSp @Infobar OUTPUT
                       , 'E=NoExist0'
                       , '@taxparms'

      GOTO END_PROG
   END

   -- BEGIN_PROG:

   SET @InvHdrRowPointer  = NULL
   SET @InvHdrCoNum       = NULL
   SET @InvHdrInvNum      = '0'
   SET @InvHdrInvSeq      = 0
   SET @InvHdrCustNum     = NULL
   SET @InvHdrCustSeq     = 0
   SET @InvHdrBillType    = NULL
   SET @InvHdrPrice       = 0
   SET @InvHdrCustPo      = NULL
   SET @InvHdrSlsman      = NULL
   SET @InvHdrQtyPackages = 0
   SET @InvHdrInvDate     = NULL
   SET @InvHdrWeight      = 0
   SET @InvHdrPrepaidAmt  = 0
   SET @InvHdrDisc        = 0
   SET @InvHdrMiscCharges = 0
   SET @InvHdrFreight     = 0
   SET @InvHdrExchRate    = 0

   SELECT
      @InvHdrRowPointer  = inv_hdr.RowPointer,
      @InvHdrCoNum       = inv_hdr.co_num,
      @InvHdrInvNum      = inv_hdr.inv_num,
      @InvHdrInvSeq      = inv_hdr.inv_seq,
      @InvHdrCustNum     = inv_hdr.cust_num,
      @InvHdrCustSeq     = inv_hdr.cust_seq,
      @InvHdrBillType    = inv_hdr.bill_type,
      @InvHdrPrice       = inv_hdr.price,
      @InvHdrCustPo      = inv_hdr.cust_po,
      @InvHdrSlsman      = inv_hdr.slsman,
      @InvHdrQtyPackages = inv_hdr.qty_packages,
      @InvHdrInvDate     = inv_hdr.inv_date,
      @InvHdrWeight      = inv_hdr.weight,
      @InvHdrPrepaidAmt  = inv_hdr.prepaid_amt,
      @InvHdrDisc        = inv_hdr.disc,
      @TCAmtDisc         = inv_hdr.disc_amount,
      @InvHdrMiscCharges = inv_hdr.misc_charges,
      @InvHdrFreight     = inv_hdr.freight,
      @InvHdrExchRate    = inv_hdr.exch_rate,
      @InvHdrTaxCode1    = inv_hdr.tax_code1,
      @InvHdrTaxCode2    = inv_hdr.tax_code2,
      @InvHdrTermsCode   = inv_hdr.terms_code,
      @InvHdrShipCode    = inv_hdr.ship_code
   FROM inv_hdr
   WHERE inv_hdr.inv_num = @TPrintInvNum AND
         inv_hdr.inv_seq = 0

   SELECT
      @ArtranDiscAmt     = artran.disc_amt
   FROM  artran
   WHERE artran.cust_num = @InvHdrCustNum AND
         artran.inv_num  = @InvHdrInvNum AND
         artran.inv_seq  = @InvHdrInvSeq

   SELECT
      @ArinvAmount       = arinv.amount
   FROM  arinv
   WHERE arinv.cust_num  = @InvHdrCustNum AND
         arinv.inv_num   = @InvHdrInvNum  AND
         arinv.inv_seq   = @InvHdrInvSeq

   SELECT
      @TermsDiscPct      = terms.disc_pct
   FROM  terms
   WHERE terms.terms_code = @InvHdrTermsCode

   IF @InvHdrRowPointer IS NULL
   BEGIN
      SET @Infobar = NULL
      EXEC @Severity = dbo.MsgAppSp
                           @Infobar OUTPUT,
                           'E=NoExist1',
                           '@inv_hdr',
                           '@inv_hdr.inv_num',
                           @TPrintInvNum
      GOTO END_PROG
   END

   SET @InvHdrPrice        = ISNULL(@InvHdrPrice, 0)
   SET @InvHdrQtyPackages  = ISNULL(@InvHdrQtyPackages, 0)
   SET @InvHdrWeight       = ISNULL(@InvHdrWeight, 0)
   SET @InvHdrPrepaidAmt   = ISNULL(@InvHdrPrepaidAmt, 0)
   SET @InvHdrDisc         = ISNULL(@InvHdrDisc, 0)
   SET @TCAmtDisc          = ISNULL(@TCAmtDisc, 0)	
   SET @InvHdrMiscCharges  = ISNULL(@InvHdrMiscCharges, 0)
   SET @InvHdrFreight      = ISNULL(@InvHdrFreight, 0)
   SET @InvHdrExchRate     = ISNULL(@InvHdrExchRate, 0)

   SET @CoRowPointer       = NULL
   SET @CoLcrNum           = ''
   SET @CoType             = NULL
   SET @CoCoNum            = NULL

   IF  @PrintOrderNotes = 0
      SELECT
         @CoRowPointer  = co.RowPointer,
         @CoLcrNum      = co.lcr_num,
         @CoType        = co.type,
         @CoCoNum       = co.co_num,
         @CoIncludeTaxInPrice = co.include_tax_in_price
      FROM co WITH (READUNCOMMITTED)
      WHERE co.co_num = @InvHdrCoNum
   ELSE  -- Print Customer Order Header Notes
      SELECT
         @CoRowPointer  = co.RowPointer,
         @CoLcrNum      = co.lcr_num,
         @CoType        = co.type,
         @CoCoNum       = co.co_num,
         @CoIncludeTaxInPrice = co.include_tax_in_price,
         @CoNotesFlag   = dbo.ReportNotesExist(
                                 'co',
                                 co.RowPointer,
                                 @PrintInternalNotes,
                                 @PrintExternalNotes,
                                 co.NoteExistsFlag
                           )

      FROM co WITH (READUNCOMMITTED)
      WHERE co.co_num = @InvHdrCoNum

   IF @CoRowPointer IS NULL
   BEGIN
      SET @Infobar = NULL
      EXEC @Severity = dbo.MsgAppSp
                           @Infobar OUTPUT,
                           'E=NoExistForIs1',
                           '@co',
                           '@co.co_num',
                           @InvHdrCoNum,
                           '@inv_hdr',
                           '@inv_hdr.inv_num',
                           @InvHdrInvNum
      GOTO END_PROG
   END

   SET @CustomerRowPointer     = NULL
   SET @CustomerLcrReqd        = 0
   SET @CustomerLangCode       = NULL
   SET @CustomerPayType        = NULL
   SET @CustomerDraftPrintFlag = 0
   SET @CustomerCustNum        = NULL
   SET @CustomerCustSeq        = 0
   SET @TTaxRegNum1            = NULL
   SET @TTaxRegNum2            = NULL
   SET @TCustRegNum1           = NULL
   SET @TCustRegNum2           = NULL
   SET @TCustShipToRegNum1     = NULL
   SET @TCustShipToRegNum2     = NULL

   SELECT
      @CustomerRowPointer     = customer.RowPointer,
      @CustomerLcrReqd        = customer.lcr_reqd,
      @CustomerLangCode       = customer.lang_code,
      @CustomerPayType        = customer.pay_type,
      @CustomerDraftPrintFlag = customer.draft_print_flag,
      @CustomerCustNum        = customer.cust_num,
      @CustomerCustSeq        = customer.cust_seq
   FROM customer
   WHERE customer.cust_num = @InvHdrCustNum
         AND customer.cust_seq = 0

   IF @CustomerRowPointer IS NULL OR
      isnull(@InvHdrCustNum, '') = ''
   BEGIN
      SET @Infobar = NULL
      EXEC @Severity = dbo.MsgAppSp
                           @Infobar OUTPUT,
                           'E=NoExistForIs1',
                           '@customer',
                           '@customer.cust_num',
                           @InvHdrCustNum,
                           '@inv_hdr',
                           '@inv_hdr.inv_num',
                           @InvHdrInvNum
      GOTO END_PROG
   END

   IF @CustomerLcrReqd = 1 AND isnull(@CoLcrNum, '') = ''
   BEGIN
      SET @Infobar = NULL
      EXEC @Severity = dbo.MsgAppSp
                           @Infobar OUTPUT,
                           'W=IsCompare1',
                           '@co.lcr_num',
                           @CoLcrNum,
                           '@co',
                           '@co',
                           @CoCoNum
   END

   SET @CustaddrRowPointer  = NULL
   SET @CustaddrCurrCode    = NULL
   SET @CustaddrCorpAddress = 0
   SET @CustaddrCorpCust    = NULL
   SET @CustaddrFaxNum      = NULL
   SET @CustaddrCountry     = NULL

   SELECT
      @CustaddrRowPointer  = custaddr.RowPointer,
      @CustaddrCurrCode    = custaddr.curr_code,
      @CustaddrCorpAddress = custaddr.corp_address,
      @CustaddrCorpCust    = custaddr.corp_cust,
      @CustaddrFaxNum      = custaddr.fax_num,
      @CustaddrCountry     = custaddr.country
   FROM custaddr
   WHERE custaddr.cust_num = @CustomerCustNum AND
         custaddr.cust_seq = @CustomerCustSeq -- BILL TO

   IF (@CustaddrRowPointer IS NULL)
   BEGIN
      SET @Infobar = NULL
      EXEC @Severity = dbo.MsgAppSp
                           @Infobar OUTPUT,
                           'E=NoExistForIs1',
                           '@custaddr',
                           '@custaddr.cust_num',
                           @InvHdrCustNum,
                           '@inv_hdr',
                           '@inv_hdr.inv_num',
                           @InvHdrInvNum
      GOTO END_PROG
   END

   SET @CurrparmsRowPointer = NULL
   SET @CurrparmsCurrCode = NULL

   SELECT
      @CurrparmsRowPointer = currparms.RowPointer,
      @CurrparmsCurrCode   = currparms.curr_code
   FROM currparms

   IF @CurrparmsRowPointer IS NULL
   BEGIN
      SET @Infobar = NULL
      EXEC @Severity = dbo.MsgAppSp
                           @Infobar OUTPUT,
                           'E=NoExist0',
                           '@currparms'
      GOTO END_PROG
   END

   SET @TCurrCode =  CASE  WHEN @TransToDomCurr = 1
                           THEN @CurrparmsCurrCode
                           ELSE @CustaddrCurrCode
                     END
   SET @WordNumCurrCode = @TCurrCode

   SET @CurrencyRowPointer  = NULL
   SET @CurrencyDescription = NULL
   SET @CurrencyPlaces      = 0

   SELECT
      @CurrencyRowPointer  = currency.RowPointer,
      @CurrencyDescription = currency.description,
      @CurrencyPlaces      = currency.places
   FROM currency
   WHERE currency.curr_code = @TCurrCode

   IF @CurrencyRowPointer IS NULL
   BEGIN
      SET @Infobar = NULL
      EXEC @Severity = dbo.MsgAppSp
                           @Infobar OUTPUT,
                           'E=NoExist1',
                           '@currency',
                           '@currency.curr_code',
                           @TCurrCode
      GOTO END_PROG
   END

   SET @CurrencyPlaces = ISNULL(@CurrencyPlaces, 0)

   SET @TCurrDesc = @TCurrCode + ' ' + @CurrencyDescription

   SET @CurrencyRowPointer  = NULL
   SET @CurrencyDescription = NULL
   SET @CurrencyPlaces      = 0

   SELECT
      @CurrencyRowPointer  = currency.RowPointer,
      @CurrencyDescription = currency.description,
      @CurrencyPlaces      = currency.places
   FROM currency
   WHERE currency.curr_code = @CustaddrCurrCode

   IF @CurrencyRowPointer IS NULL
   BEGIN
      SET @Infobar = NULL
      EXEC @Severity = dbo.MsgAppSp
                           @Infobar OUTPUT,
                           'E=NoExist1',
                           '@currency',
                           '@currency.curr_code',
                           @CustaddrCurrCode
      GOTO END_PROG
   END

   SET @CurrencyPlaces = ISNULL(@CurrencyPlaces, 0)

   IF @PrintDiscountAmt = 1
      IF @Mode = 'REPRINT'
         IF NOT EXISTS (SELECT TOP 1 * FROM arinv
                        WHERE arinv.cust_num = @InvHdrCustNum AND
                        arinv.inv_num = @InvHdrInvNum AND
                        arinv.inv_seq = @InvHdrInvSeq)
            SET @TermsDiscountAmt = ROUND(@ArtranDiscAmt, @CurrencyPlaces)
         ELSE
            SET @TermsDiscountAmt = ROUND(@ArinvAmount * @TermsDiscPct / 100, @CurrencyPlaces)
      ELSE
         SET @TermsDiscountAmt = ROUND(@ArinvAmount * @TermsDiscPct / 100, @CurrencyPlaces)

   EXEC dbo.TaxIdSp
        @pTaxSystem       = 1                      -- TaxSystemType
      , @pTaxCode         = @InvHdrTaxCode1        -- TaxCodeType
      , @pBranchDefined   = 1                      -- ListYesNoType
      , @pCustAddrCountry = @CustaddrCountry       -- CountryType
      , @CustNum          = @InvHdrCustNum         -- CustNumType
      , @rTaxRegNum       = @TTaxRegNum1  OUTPUT   -- TaxRegNumType
      , @rCustRegNum      = @TCustRegNum1 OUTPUT   -- TaxRegNumType
      , @Infobar          = @Infobar      OUTPUT   -- InfobarType
      , @CustSeq = @InvHdrCustSeq
      , @CustShipToRegNum = @TCustShipToRegNum1 OUTPUT

   IF ISNULL(@TTaxIDLabel2, '') <> ''
      EXEC dbo.TaxIdSp
           @pTaxSystem       = 2                      -- TaxSystemType
         , @pTaxCode         = @InvHdrTaxCode2        -- TaxCodeType
         , @pBranchDefined   = 0                      -- ListYesNoType
         , @pCustAddrCountry = @CustaddrCountry       -- CountryType
         , @CustNum          = @InvHdrCustNum         -- CustNumType
         , @rTaxRegNum       = @TTaxRegNum2  OUTPUT   -- TaxRegNumType
         , @rCustRegNum      = @TCustRegNum2 OUTPUT   -- TaxRegNumType
         , @Infobar          = @Infobar      OUTPUT   -- InfobarType
         , @CustSeq = @InvHdrCustSeq
         , @CustShipToRegNum = @TCustShipToRegNum2 OUTPUT

   SET @TCorpAddress = @CustaddrCorpAddress
   SET @TCorpCust    = @CustaddrCorpCust

   SELECT
      @CustRowPointer      = NULL,
      @TCurrCode           = NULL,
      @TFaxNum             = NULL,
      @BillToContact       = NULL,
      @ShipToContact       = NULL,
      @TCorpCust           = NULL,
      @TCorpAddr           = NULL

   -- Bill-to (Begin)
   IF  @PrintBillToNotes   = 0 OR ( @PrintCustomerNotes = 1 and @PrintBillToNotes   = 1 and @InvHdrCustSeq = 0 )
      SELECT
         @TCurrCode           = custaddr.curr_code,
         @TFaxNum             = custaddr.fax_num,
         @BillToContact       = ISNULL(customer.contact##3,''),
         @TCorpCust           = custaddr.corp_cust,
         @TCorpAddr           = custaddr.corp_address
      FROM customer
      JOIN custaddr
         ON custaddr.cust_num = customer.cust_num AND
            custaddr.cust_seq = customer.cust_seq
      LEFT OUTER JOIN country
         ON country.country = custaddr.country
      WHERE customer.cust_num = @InvHdrCustNum AND
            customer.cust_seq = 0
   ELSE  -- Print Customer Master Notes (Bill To)
      SELECT
         @TCurrCode           = custaddr.curr_code,
         @TFaxNum             = custaddr.fax_num,
         @BillToContact       = ISNULL(customer.contact##3,''),
         @TCorpCust           = custaddr.corp_cust,
         @TCorpAddr           = custaddr.corp_address,
         @BillToRowPointer    = customer.RowPointer,
         @BillToNotesFlag     = dbo.ReportNotesExist(
                                       'customer',
                                       customer.RowPointer,
                                       @PrintInternalNotes,
                                       @PrintExternalNotes,
                                       customer.NoteExistsFlag
                                 )
      FROM customer
      JOIN custaddr
         ON custaddr.cust_num = customer.cust_num AND
            custaddr.cust_seq = customer.cust_seq
      LEFT OUTER JOIN country
         ON country.country = custaddr.country
      WHERE customer.cust_num = @InvHdrCustNum AND
            customer.cust_seq = 0
   -- Bill-to (End)

   SET @Addr1 = dbo.FormatAddressWithContactSp(@InvHdrCustNum, 0, @BillToContact)

   -- Ship-To (Begin)
   IF  @PrintCustomerNotes = 0
      SELECT
         @TCurrCode           = custaddr.curr_code,
         @ShipToContact       = ISNULL(customer.contact##2,'')
   FROM customer
      JOIN custaddr
         ON custaddr.cust_num = customer.cust_num AND
            custaddr.cust_seq = customer.cust_seq
      LEFT OUTER JOIN country
         ON country.country   = custaddr.country
      WHERE customer.cust_num = @InvHdrCustNum AND
            customer.cust_seq = @InvHdrCustSeq
   ELSE  -- Ship To Notes
      SELECT
         @TCurrCode              = custaddr.curr_code,
         @ShipToContact          = ISNULL(customer.contact##2,''),
         @ShipToCustRowPointer   = customer.RowPointer,
         @ShipToCustNotesFlag    = dbo.ReportNotesExist(
                                          'customer',
                                          customer.RowPointer,
                                          @PrintInternalNotes,
                                          @PrintExternalNotes,
                                          customer.NoteExistsFlag
                                    )
      FROM customer
      JOIN custaddr
         ON custaddr.cust_num = customer.cust_num AND
            custaddr.cust_seq = customer.cust_seq
      LEFT OUTER JOIN country
         ON country.country = custaddr.country
      WHERE customer.cust_num = @InvHdrCustNum AND
            customer.cust_seq = @InvHdrCustSeq
   -- Ship-To (End)

   SET @Addr2 = dbo.FormatAddressWithContactSp(@InvHdrCustNum, @InvHdrCustSeq, @ShipToContact)

   IF @TCorpAddr = 1
   BEGIN
      SELECT
         @CustRowPointer = NULL

      SELECT
         @TFaxNum          = ISNULL(custaddr.fax_num,''),
         @BillToContact    = ISNULL(customer.contact##3,''),
         @CustRowPointer   = customer.rowpointer
      FROM custaddr
         JOIN customer
            ON customer.cust_num = custaddr.cust_num AND
               customer.cust_seq = custaddr.cust_seq
      WHERE custaddr.cust_num = @TCorpCust AND
            custaddr.cust_seq = 0

      SET @Addr1 = dbo.FormatAddressWithContactSp(@TCorpCust, 0, @BillToContact)
   END

   -- LOOKING FOR MULTI-LINGUAL

   SET @TermsRowPointer  = NULL
   SET @TermsTermsCode   = NULL
   SET @TermsDescription = NULL

   SELECT
      @TermsRowPointer  = terms.RowPointer,
      @TermsTermsCode   = terms.terms_code,
      @TermsDescription = terms.description
   FROM terms
   WHERE terms.terms_code = @InvHdrTermsCode

   IF @TermsRowPointer IS NOT NULL
   BEGIN
      SET @TermLangRowPointer  = NULL
      SET @TermLangDescription = NULL

      SELECT
         @TermLangRowPointer  = term_lang.RowPointer,
         @TermLangDescription = term_lang.description
      FROM term_lang
      WHERE term_lang.terms_code = @TermsTermsCode AND
            term_lang.lang_code = @CustomerLangCode

   END
   SET @ShipcodeRowPointer  = NULL
   SET @ShipcodeShipCode    = NULL
   SET @ShipcodeDescription = NULL

   SELECT
      @ShipcodeRowPointer  = shipcode.RowPointer
      , @ShipcodeShipCode    = shipcode.ship_code
      , @ShipcodeDescription = shipcode.description
   FROM shipcode
   WHERE shipcode.ship_code = @InvHdrShipCode

   IF @ShipcodeRowPointer IS NOT NULL
   BEGIN
      SET @ShipLangRowPointer  = NULL
      SET @ShipLangDescription = NULL

      SELECT
         @ShipLangRowPointer  = ship_lang.RowPointer,
         @ShipLangDescription = ship_lang.description
      FROM ship_lang
      WHERE ship_lang.ship_code = @ShipcodeShipCode
            AND ship_lang.lang_code = @CustomerLangCode

   END


   SET @InvcLangRowPointer    = NULL
   SET @InvcLangCoText##1     = NULL
   SET @InvcLangCoText##2     = NULL
   SET @InvcLangCoText##3     = NULL

   SELECT
      @InvcLangRowPointer    = invc_lang.RowPointer,
      @InvcLangCoText##1     = invc_lang.co_text##1,
      @InvcLangCoText##2     = invc_lang.co_text##2,
      @InvcLangCoText##3     = invc_lang.co_text##3
   FROM invc_lang
   WHERE invc_lang.lang_code = @CustomerLangCode


   SET @TDescription =  -- All caps for Crystal Report selection.
         CASE
               WHEN  @InvHdrBillType = 'N'
               THEN  'ADJUSTMENT'
               WHEN  (@Mode = 'REPRINT' AND @InvHdrPrice < 0) OR
                     (@Mode <> 'REPRINT' AND @InvCred = 'C')
               THEN  'CREDIT MEMO'
               WHEN  @Progressive=1
               THEN  'PROGRESSIVE BILLING'
               WHEN  @CoType = 'R'
               THEN  'REGULAR INVOICE'
               ELSE  'BLANKET INVOICE'
         END

   -- Begin EDI
   IF LEN(RTRIM(@InvHdrCustPo)) > 15
   BEGIN
      SET @ShortCustPo  = ''
      SET @LongCustPo   = dbo.GetLabel ('@co.cust_po') + ':' + @InvHdrCustPo
   END
   ELSE
   BEGIN
      SET @ShortCustPo  = @InvHdrCustPo
      SET @LongCustPo   = ''
   END

   SET @CustNum      =  CASE  WHEN @TCorpAddress = 1
                              THEN @TCorpCust
                              ELSE @InvHdrCustNum
                        END

   SET @StrCustSeq   =  CASE  WHEN  @TCorpAddress = 1
                              THEN  (@InvHdrCustNum +
                                    ' - ' +
                                    CONVERT(NCHAR(9),@InvHdrCustSeq))
                              WHEN @InvHdrCustSeq > 0
                              THEN CONVERT(NCHAR(9),@InvHdrCustSeq)
                              ELSE ' '
                        END

   SET @CustSeq   =  @InvHdrCustSeq

   SET @ShipVia   =  CASE  WHEN @ShipLangRowPointer IS NOT NULL
                           THEN @ShipLangDescription
                           ELSE @ShipcodeDescription
                     END

   SET @Terms     =  CASE  WHEN @TermLangRowPointer IS NOT NULL
                           THEN @TermLangDescription
                           ELSE @TermsDescription
                     END


   IF @PrintStandardOrderText = 1
   BEGIN
       IF @InvcLangRowPointer IS NOT NULL
       BEGIN
          SET @TCoText1     = @InvcLangCoText##1
          SET @TCoText2     = @InvcLangCoText##2
          SET @TCoText3     = @InvcLangCoText##3
       END
       ELSE
       BEGIN
          SET @TCoText1     = @ParmsCoText1
          SET @TCoText2     = @ParmsCoText2
          SET @TCoText3     = @ParmsCoText3
       END
   END

   SET @TSlsman            = @InvHdrSlsman

   SET @SlsmanRowPointer   = NULL
   SET @SlsmanOutside      = 0
   SET @SlsmanRefNum       = NULL

   SELECT
      @SlsmanRowPointer = slsman.RowPointer,
      @SlsmanOutside    = slsman.outside,
      @SlsmanRefNum     = slsman.ref_num
   FROM slsman
   WHERE slsman.slsman = @InvHdrSlsman

   IF @SlsmanRowPointer IS NOT NULL
   BEGIN
      IF @SlsmanOutside = 1
      BEGIN
         SET @VendaddrRowPointer = NULL
         SET @VendaddrName       = NULL

         SELECT
            @VendaddrRowPointer = vendaddr.RowPointer,
            @VendaddrName       = vendaddr.name
         FROM vendaddr
         WHERE vendaddr.vend_num = @SlsmanRefNum

         IF @VendaddrRowPointer IS NOT NULL
            SET @TSlsman = @VendaddrName
      END
      ELSE
      BEGIN
         SET @EmployeeRowPointer = NULL
         SET @EmployeeName       = NULL

         SELECT
            @EmployeeRowPointer = employee.RowPointer,
            @EmployeeName       = dbo.GetEmployeeName(employee.emp_num)
         FROM employee
         WHERE employee.emp_num = @SlsmanRefNum

         IF @EmployeeRowPointer IS NOT NULL
            SET @TSlsman = @EmployeeName
      END
   END

   -- DISPLAY HEADER
   IF @CoLcrNum = ''
      SET @TCustTaxIDLabel = ''

   ELSE
      SET @TCustTaxIDLabel = @TTaxIDLabel2


   -- Tx_type = 1
   SET @StrInvNum = @InvHdrInvNum
   SET @StrInvNum = dbo.LeftPad (@StrInvNum,'0',12)
   SET @RptKey    =  @StrInvNum +
                     '         ' +
                     (CONVERT(NCHAR(10),@InvHdrCoNum)) +
                     '         ' +
                     '01'
   SELECT TOP 1 @ApplyToInvNum  = art.apply_to_inv_num, @Type = type
                                    FROM artran art
                                    WHERE art.inv_num = @InvHdrInvNum and
                                          art.inv_seq = @InvHdrInvSeq
   If @ApplyToInvNum is null
   SELECT TOP 1 @ApplyToInvNum = ari.apply_to_inv_num, @Type = type
                                    FROM arinv ari
                                    WHERE ari.inv_num = @InvHdrInvNum and
                                          ari.inv_seq = @InvHdrInvSeq



   -- Tx_type = 1
   INSERT INTO #tt_invoice_credit_memo (
            tx_type, inv_num, inv_site, inv_date, inv_slsman,
            inv_description, inv_tax_num_lbl1, inv_tax_num1, inv_tax_num_lbl2, inv_tax_num2,
            inv_cust_tax_num_lbl1, inv_cust_tax_num1, inv_cust_shipto_tax_num1, inv_cust_tax_num_lbl2, inv_cust_tax_num2, inv_cust_shipto_tax_num2,
            inv_curr_code, cust_num, inv_cust_seq, inv_str_cust_seq, inv_fax_num,
            co_num, inv_long_cust_po, inv_short_cust_po, inv_pkgs, inv_weight,
            inv_shipvia, inv_terms,/* inv_prepaid_amt,*/ inv_memo_num,
            lcr, OurAddress, BillToAddress, ShipToAddress,
            rpt_key, Apply_To_Inv_Num, type
   )
   VALUES (
            1, @InvHdrInvNum, @ParmsSite, @InvHdrInvDate, @TSlsman,
            @TDescription, @TTaxIDLabel1, @TTaxRegNum1, @TTaxIDLabel2, @TTaxRegNum2,
            @TTaxIDLabel1, @TCustRegNum1, @TCustShipToRegNum1, @TCustTaxIDLabel, @TCustRegNum2, @TCustShipToRegNum2,
            @TCurrDesc, @CustNum, @CustSeq,  @StrCustSeq, @TFaxNum,
            @CoCoNum, @LongCustPo, @ShortCustPo, @InvHdrQtyPackages, @InvHdrWeight,
            @ShipVia, @Terms,/* @InvHdrPrepaidAmt,*/ @InvHdrInvNum,
            @CoLcrNum, @Addr0, @Addr1, @Addr2,
            @RptKey, @ApplyToInvNum, @Type
   )

   EXEC @Severity = dbo.EuroInfoSp
                         0,
                         @TEuroUser    OUTPUT,
                         @TEuroExists  OUTPUT,
                         @TEuroCurr    OUTPUT,
                         @Infobar      OUTPUT,
                         NULL

   -- PROCESSES ALL LINE ITEMS ON THIS ORDER

   EXEC @Severity = dbo.InvPrt2Sp
                         @Progressive,
                         @Mode,
                         @TSubPrice        OUTPUT,
                         @TDiscCiPrice     OUTPUT,    -- Not being used as of 12/02/2002
                         @TPrintInvNum     OUTPUT,
                         @TEuroTotal       OUTPUT,
                         @TransToDomCurr,
                         @PrintItemCustomerItem,
                         @PrintSerialNumbers,
                         @InvCred,
                         @PrintPlanItemMaterials,
                         @PrintConfigrationDetail,
                         @TEuroExists,
                         @PrintOrderLineNotes,
                         @PrintOrderBlanketLineNotes,
                         @PrintProgressiveBillingNotes,
                         @PrintInternalNotes,
                         @PrintExternalNotes,
						 @PrintItemOverview,
                         @PrintLineReleaseDescription,
                         @Infobar,
                         @PrintEuro        OUTPUT,
                         @PrintLotNumbers
   IF @Severity <> 0
      GOTO END_PROG

     select @usemultiduedates = use_multi_due_dates from terms
     where terms_code=@InvHdrTermsCode

     if @usemultiduedates = 1
     begin
          if exists (select 1 from ar_terms_due where
                                   ar_terms_due.cust_num  = @InvHdrCustNum and
                                   ar_terms_due.inv_num   = @InvHdrInvNum  )
          begin
                SET @RptKey =  @StrInvNum +
                  'xxxxxxxxx' +
                  (CONVERT(NCHAR(10),@InvHdrCoNum)) +
                  'xxxxxxxxx' +
                  '17'

               insert into #tt_invoice_credit_memo (tx_type,cust_num, inv_num, use_multi_due_dates,rpt_key)
               values (17,@InvHdrCustNum, @InvHdrInvNum,1,@RptKey)

                 SET @RptKey =  @StrInvNum +
                  'xxxxxxxxx' +
                  (CONVERT(NCHAR(10),@InvHdrCoNum)) +
                  'xxxxxxxxx' +
                  '18'

               insert into #tt_invoice_credit_memo (tx_type, cust_num, inv_num,use_multi_due_dates,
                  multi_due_inv_seq,multi_due_date,multi_due_percent,multi_due_amount,rpt_key)
               select 18, @InvHdrCustNum, @InvHdrInvNum, @usemultiduedates,
                  ar_terms_due.seq,ar_terms_due.due_date, ar_terms_due.terms_percent,ar_terms_due.amount,@RptKey
               from  ar_terms_due
               where
                    ar_terms_due.cust_num  = @InvHdrCustNum and
                    ar_terms_due.inv_num   = @InvHdrInvNum
               order by ar_terms_due.due_date
          end
     end


      IF @CoNotesFlag = 1 OR
         @BillToNotesFlag = 1 OR
         @ShipToCustNotesFlag = 1
      BEGIN
      -- Tx_Type = 19
         SET @RptKey =  @StrInvNum +
                        'xxxxxxxxx' +
                        (CONVERT(NCHAR(10),@InvHdrCoNum)) +
                        'xxxxxxxxx' +
                        '19'

         INSERT INTO #tt_invoice_credit_memo (
               tx_type, inv_num, co_num, rpt_key,
               co_RowPointer, co_NotesFlag, bill_to_RowPointer, bill_to_NotesFlag,
               customer_RowPointer, customer_NotesFlag, Apply_To_Inv_Num
         )
         VALUES (
               19, @InvHdrInvNum, @InvHdrCoNum, @RptKey,
               @CoRowPointer, @CoNotesFlag, @BillToRowPointer, @BillToNotesFlag,
               @ShipToCustRowPointer, @ShipToCustNotesFlag, @ApplyToInvNum
         )
      END

   -- Calculate Footer Values (totals)

   SET @TcAmtSalesTax   = 0
   SET @TcAmtSalesTax2  = 0

   SELECT
	@TcAmtSalesTax2 = SUM(CASE inv_stax.tax_system WHEN 2 THEN ISNULL(inv_stax.sales_tax,0) ELSE 0 END),
	@TcAmtSalesTax  = SUM(CASE inv_stax.tax_system WHEN 0 THEN ISNULL(inv_stax.sales_tax,0) WHEN 1 THEN ISNULL(inv_stax.sales_tax,0) ELSE 0 END)
   FROM inv_stax
   WHERE inv_stax.inv_num = @InvHdrInvNum AND
         inv_stax.inv_seq = @InvHdrInvSeq

    SET @TcAmtSalesTax   = isnull(@TcAmtSalesTax,0)
    SET @TcAmtSalesTax2  = isnull(@TcAmtSalesTax2,0)

   SET @TcAmtDisc          =  ISNULL(ROUND( @TCAmtDisc , @CurrencyPlaces), 0)

    -- Don't remove Sales Tax if CO is set as Price Includes Tax
    SET @TcAmtNet           = @InvHdrPrice
                            - @InvHdrMiscCharges
                            - CASE WHEN @CoIncludeTaxInPrice = 1 THEN 0 ELSE @TcAmtSalesTax  END
                            - CASE WHEN @CoIncludeTaxInPrice = 1 THEN 0 ELSE @TcAmtSalesTax2 END
                            - @InvHdrFreight
                            + @InvHdrPrepaidAmt

   SET @TcAmtTotalPrice    =  @TcAmtNet + @TcAmtDisc

   -- Remove Sales Tax if CO is set as Price Includes Tax
   SET @TcAmtNet           = @TcAmtNet
                           - CASE WHEN @CoIncludeTaxInPrice = 1 THEN @TcAmtSalesTax  ELSE 0 END
                           - CASE WHEN @CoIncludeTaxInPrice = 1 THEN @TcAmtSalesTax2 ELSE 0 END

   SET @TcAmtMiscCharges   =  @InvHdrMiscCharges
   SET @TcAmtFreight       =  @InvHdrFreight
   SET @TcAmtPrepaidAmt    =  @InvHdrPrepaidAmt


   --   run co/taxsum-r.p (inv_hdr.RowPointer)
   IF dbo.IsAddonAvailable('SyteLineCCI') = 1
   BEGIN
      IF OBJECT_ID('dbo.EXTSSSCCIInvPrintSp') IS NOT NULL
      BEGIN
         DECLARE @EXTSSSCCI_SpName sysname

         SET @EXTSSSCCI_SpName = 'dbo.EXTSSSCCIInvPrintSp'
         EXEC @Severity = @EXTSSSCCI_SpName
                          @TPrintInvNum
                        , @InvCred
                        , @CurrencyPlaces
                        , @CurrparmsCurrCode
                        , @TcAmtPrepaidAmt OUTPUT
                        , @SSSCCIItem1     OUTPUT
                        , @Infobar         OUTPUT
         IF @Severity <> 0
            GOTO END_PROG
      END
   END

   IF @TaxParmsPrtTaxFooter = 1
   BEGIN
      DECLARE InvStaxCrs CURSOR LOCAL STATIC FOR
         SELECT
               inv_stax.rowpointer,
               inv_stax.tax_system,
               inv_stax.tax_code,
               ISNULL(inv_stax.tax_code_e,''),
               ISNULL(inv_stax.tax_basis, 0),
               ISNULL(inv_stax.tax_rate, 0),
               ISNULL(inv_stax.sales_tax, 0),
               tax_system.tax_mode,
               ISNULL(tax_system.tax_item_label,''),
               ISNULL(tax_system.tax_code_label,'')
         FROM inv_stax
         JOIN inv_hdr
            ON inv_hdr.inv_num = inv_stax.inv_num AND
               inv_hdr.inv_seq = inv_stax.inv_seq
         LEFT JOIN tax_system
            ON tax_system.tax_system = inv_stax.tax_system
         WHERE inv_stax.inv_num = @InvHdrInvNum AND
               inv_stax.inv_seq = @InvHdrInvSeq

         OPEN InvStaxCrs
            WHILE @Severity = 0 BEGIN
               FETCH InvStaxCrs INTO
                  @RowPointer,
                  @TaxSystem,
                  @TaxCode,
                  @TaxCodeE,
                  @TaxBasis,
                  @TaxRate,
                  @ExtendedTax,
                  @TaxMode,
                  @TaxItemLabel,
                  @TaxCodeLabel

               IF @@FETCH_STATUS <> 0
                  BREAK

               SET @TaxCodeELabel   =  CASE  WHEN @TaxMode = 'A'
                                             THEN @TaxItemLabel
                                             ELSE @TaxCodeLabel
                                       END + ':'
               SET @TaxCodeLabel    =  CASE  WHEN @TaxMode = 'I'
                                             THEN @TaxItemLabel
                                             ELSE @TaxCodeLabel
                                       END + ':'

               --  If translate to domestic currency is requested, convert the
               -- tax basis to the domestic currency.
               IF @TransToDomCurr = 1
               BEGIN
                  SET @TRate = @InvHdrExchRate

                  EXEC @Severity = dbo.CurrCnvtSp
                           @CurrCode      = @CustaddrCurrCode,
                           @FROMDomestic  = 0,
                           @UseBuyRate    = 0,
                           @RoundResult   = 1,
                           @TRate         = @TRate OUTPUT,
                           @Infobar       = @Infobar OUTPUT,
                           @Amount1       = @TaxBasis,
                           @Result1       = @TaxBasis OUTPUT,
                           @Amount2       = @ExtendedTax,
                           @Result2       = @ExtendedTax OUTPUT
               END

               INSERT INTO #tt_tax_footer(
                        tax_code_lbl,
                        inv_tax_code,
                        tax_code_e_lbl,
                        tax_code_e,
                        tax_rate,
                        tax_basis,
                        extended_tax,
                        rowpointer
               )
               VALUES(
                        @TaxCodeLabel,
                        @TaxCode,
                        @TaxCodeELabel,
                        @TaxCodeE,
                        @TaxRate,
                        @TaxBasis,
                        @ExtendedTax,
                        newid()
               )
            END
         CLOSE InvStaxCrs
      DEALLOCATE InvStaxCrs
   END


   SET @TcAmtSalesTax   =  ROUND(@TcAmtSalesTax, @CurrencyPlaces)
   SET @TcAmtSalesTax2  =  ROUND(@TcAmtSalesTax2, @CurrencyPlaces)

   SET @TcAmtPrice      =  @TcAmtNet +
                           @TcAmtSalesTax +
                           @TcAmtSalesTax2 +
                           @TcAmtFreight +
                           @TcAmtMiscCharges -
                           @TcAmtPrepaidAmt

   SET @TDiscMask       = @TcAmtDisc
   SET @TcAmtNetMask    = @TcAmtNet

   IF @TEuroExists = 1
   BEGIN

      EXEC @Severity = dbo.EuroPartSp
                           @CustaddrCurrCode,
                           @StdLo OUTPUT

      IF @StdLo = 1
      BEGIN
         -- Check For Discount
         SET @TEuroTotal = @TEuroTotal - ROUND((@TEuroTotal *
                                                @InvHdrDisc / 100), @CurrencyPlaces)

         -- Misc Charges
         SET @TStdDe       = dbo.EuroCnvt(@TcAmtMiscCharges, @CustaddrCurrCode, 0, 1)
         SET @TEuroTotal   = ROUND (@TEuroTotal + @TStdDe, @CurrencyPlaces)

         -- Freight Charges
         SET @TStdDe       = dbo.EuroCnvt(@TcAmtFreight, @CustaddrCurrCode, 0, 1)
         SET @TEuroTotal   = ROUND (@TEuroTotal  + @TStdDe, @CurrencyPlaces)

         -- Sales Tax
         SET @TStdDe       = dbo.EuroCnvt(@TcAmtSalesTax, @CustaddrCurrCode, 0, 1)
         SET @TEuroTotal   = ROUND (@TEuroTotal + @TStdDe, @CurrencyPlaces)

         -- Sales Tax 2
         SET @TStdDe       = dbo.EuroCnvt(@TcAmtSalesTax2, @CustaddrCurrCode, 0, 1)
         SET @TEuroTotal   = ROUND (@TEuroTotal + @TStdDe, @CurrencyPlaces)

         -- Prepaid Amount
         SET @TStdDe       = dbo.EuroCnvt(@TcAmtPrepaidAmt, @CustaddrCurrCode, 0, 1)
         SET @TEuroTotal   = ROUND (@TEuroTotal - @TStdDe, @CurrencyPlaces)
      END
   END

   IF @TransToDomCurr = 1
   BEGIN
      SET @TRate = @InvHdrExchRate

      EXEC @Severity = dbo.CurrCnvtSp
                           @CurrCode      = @CustaddrCurrCode,
                           @FROMDomestic  = 0,
                           @UseBuyRate    = 0,
                           @RoundResult   = 1,
                           @TRate         = @TRate OUTPUT,
                           @Infobar       = @Infobar OUTPUT,
                           @Amount1       = @TcAmtTotalPrice,
                           @Result1       = @TcAmtTotalPrice OUTPUT,
                           @Amount2       = @TcAmtMiscCharges,
                           @Result2       = @TcAmtMiscCharges OUTPUT,
                           @Amount3       = @TcAmtFreight,
                           @Result3       = @TcAmtFreight OUTPUT,
                           @Amount4       = @TcAmtSalesTax,
                           @Result4       = @TcAmtSalesTax OUTPUT,
                           @Amount5       = @TcAmtSalesTax2,
                           @Result5       = @TcAmtSalesTax2 OUTPUT,
                           @Amount6       = @TcAmtPrepaidAmt,
                           @Result6       = @TcAmtPrepaidAmt OUTPUT,
                           @Amount7       = @TcAmtPrice,
                           @Result7       = @TcAmtPrice OUTPUT,
                           @Amount8       = @TDiscMask,
                           @Result8       = @TDiscMask OUTPUT,
                           @Amount9       = @TcAmtNetMask,
                           @Result9       = @TcAmtNetMask OUTPUT,
                           @Amount10      = @TermsDiscountAmt,
                           @Result10      = @TermsDiscountAmt OUTPUT
      , @Site = @ParmsSite
   END


    -- Tx_type = 20
    SET @RptKey =  @StrInvNum +
                   'yyyyyyyyy' +
                   (CONVERT(NCHAR(10),@InvHdrCoNum)) +
                   'yyyyyyyy' + '1' +
                   '20'

    IF EXISTS (SELECT * FROM #tt_tax_footer)
       INSERT INTO #tt_invoice_credit_memo(tx_type, inv_num, rpt_key)
       VALUES(20, @InvHdrInvNum, @RptKey)

    SET @RptKey =  @StrInvNum +
                   'yyyyyyyyy' +
                   (CONVERT(NCHAR(10),@InvHdrCoNum)) +
                   'yyyyyyyy' + '2' +
                   '20'

    INSERT INTO #tt_invoice_credit_memo (
             tx_type, inv_num, co_num,
             tax_code_lbl, INV_tax_code, tax_code_e_lbl, tax_code_e,
             tax_rate, tax_basis, extended_tax, rpt_key, apply_to_inv_num
    )
    SELECT
             20, @InvHdrInvNum, @InvHdrCoNum,
             #tt_tax_footer.tax_code_lbl, #tt_tax_footer.inv_tax_code,
	     #tt_tax_footer.tax_code_e_lbl, #tt_tax_footer.tax_code_e,
             #tt_tax_footer.tax_rate, #tt_tax_footer.tax_basis, #tt_tax_footer.extended_tax, @RptKey, @ApplyToInvNum
   FROM #tt_tax_footer

   SET @RptKey =  @StrInvNum +
                  'zzzzzzzzz' +
                  (CONVERT(NCHAR(10),@InvHdrCoNum)) +
                  'zzzzzzzzz' +
                  '21'
   EXEC dbo.GetArparmLinesPerDocSp
             @ArparmUsePrePrintedForms OUTPUT,
             @ArparmLinesPerInv OUTPUT,
             @ArparmLinesPerDM OUTPUT,
             @ArparmLinesPerCM OUTPUT

   SET @TTotalAmount = CASE @PrintEuro WHEN 1 THEN @TEuroTotal ELSE @TcAmtPrice END
   IF @ArparmUsePrePrintedForms = 1
   and @TTotalAmount <> 0
   BEGIN
      SET @Infobar = NULL
      EXEC dbo.WordNumSp
      @TTotalAmount,
      @CurrencyPlaces,
      @WordNumCurrCode,
      @AmtTotal OUTPUT,
      @Infobar OUTPUT
   END

   -- Tx_type = 21
   INSERT INTO #tt_invoice_credit_memo(
            tx_type, inv_num, co_num, tax_amt_label1, tax_amt_label2, inv_sale_amt,
            inv_disc_amt, inv_net_amt, inv_co_text1, inv_misc_charges,
            inv_co_text2, inv_freight, inv_co_text3, inv_sales_tax,
            inv_sales_tax2, inv_prepaid_amt,
            inv_total, inv_print_euro, inv_euro_total,
            rpt_key, amt_total, apply_to_inv_num, TermsDiscountAmt, item1  
   )
   VALUES(
            21, @InvHdrInvNum, @InvHdrCoNum, @TaxSystemTaxAmtLabel1, @TaxSystemTaxAmtLabel2, @TcAmtTotalPrice,
            @TDiscMask, @TcAmtNetMask, @TCoText1, @TcAmtMiscCharges,
            @TCoText2, @TcAmtFreight, @TCoText3, @TcAmtSalesTax,
            @TcAmtSalesTax2, @TcAmtPrepaidAmt,
            @TcAmtPrice, @PrintEuro, @TEuroTotal,
            @RptKey, @AmtTotal, @ApplyToInvNum, @TermsDiscountAmt, ISNULL(@SSSCCIItem1,'')
   )

UPDATE #tt_invoice_credit_memo
SET inv_sales_tax = ISNULL(inv_sales_tax,0)

UPDATE #tt_invoice_credit_memo
SET inv_sales_tax2 = ISNULL(inv_sales_tax2,0)

IF EXISTS(SELECT 1 FROM co WITH (READUNCOMMITTED) WHERE co_num = @InvHdrCoNum and include_tax_in_price = 1)
begin
     UPDATE #tt_invoice_credit_memo
     SET include_tax_in_price = 1
     WHERE co_num = @InvHdrCoNum
end
ELSE
begin
     UPDATE #tt_invoice_credit_memo
     SET include_tax_in_price = 0
     WHERE include_tax_in_price is NULL
end

END_PROG:

RETURN @Severity
GO


