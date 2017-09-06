USE [KPI_App]
GO

/****** Object:  StoredProcedure [dbo].[Rpt_EstimateResponseFormSp]    Script Date: 09/06/2017 10:55:34 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

/* $Header: /ApplicationDB/Stored Procedures/Rpt_EstimateResponseFormSp.sp 71    2/04/15 4:03a csun $  */
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

/* $Archive: /ApplicationDB/Stored Procedures/Rpt_EstimateResponseFormSp.sp $
 *
 * SL9.00 71 188008 csun Wed Feb 04 04:03:29 2015
 * Issue#188008
 * RS7090,Add 3 new columns for report dataset.
 *
 * SL9.00 70 189265 Ehe Tue Jan 06 03:16:29 2015
 * RS7088 Construction
 * 189265 Add new output field estimate_response_rpt_title .
 *
 * SL9.00 69 189265 Ehe Mon Jan 05 01:56:58 2015
 * RS7088 Construction
 * 189265 Change the sp to add new input and output parameters for RS 7088.
 *
 * SL9.00 68 188369 pgross Thu Dec 18 11:32:31 2014
 * Surcharges are created with amounts greater than 2 decimals in both the arinv and arinvd tables.   They are then posted through to A/R and payments cannot be posted against the invoice.
 * ensure that surcharges are rounded with the proper currency
 *
 * SL9.00 67 188369 pgross Thu Dec 18 10:57:05 2014
 * round the extended surcharge amount
 *
 * SL9.00 66 176919 Mding2 Fri Mar 21 03:28:00 2014
 * Fix issue 176919.
 * use parm.key = 0 when read data from parms
 *
 * SL9.00 65 175291 Ezi Fri Feb 14 02:02:02 2014
 * Estimate Response report Alternate address issues
 * Issue 175291 - Create new sub procedure FormatAddressWithContactNameSp for display a contact name.
 *
 * SL9.00 64 171385 jzhou Wed Dec 04 01:12:51 2013
 * Germany Country Pack - Report layout changes
 * Issue 171385:
 * When the value of parms.use_alt_addr_report_formatting is 1, use function GetParmsSingleLineAddressSp to get the value of @Addr0.
 *
 * SL8.04 63 167762 Igui Thu Sep 05 03:51:26 2013
 * Discount is incorrect
 * Issue 167762 - use UDDT LineDiscType for CoitemDisc instead.
 *
 * SL8.04 62 167762 Igui Tue Sep 03 05:22:00 2013
 * Discount is incorrect
 * Issue 167762 - change CoitemDisc data type from Decimal(9, 4) to Decimal(13, 8).
 *
 * SL8.04 61 168057 Jgao1 Mon Sep 02 04:56:03 2013
 * Report not showing any data
 * 168057:  Change INNER JOIN to LEFT JOIN for sucharge
 *
 * SL8.04 60 165732 Ezi Wed Aug 28 22:50:51 2013
 * Item content information line should be set a hidden condition when an item is eligible to make references for item content or not.
 * Issue 165732 - Remove Tab character.
 *
 * SL8.04 59 165732 Shu Fri Aug 23 04:20:25 2013
 * Item content information line should be set a hidden condition when an item is eligible to make references for item content or not.
 * Issue 165732 - Add Item Content field into sp to set a hidden condition for reports when an item is eligible to make references for item content or not. 
 *
 * SL8.04 58 142850 Lpeng Mon Aug 05 02:07:05 2013
 * TRK142850: format BGUser argurment.
 *
 * SL8.04 57 165732 Ezi Thu Jul 25 04:13:52 2013
 * Item content information line should be set a hidden condition when an item is eligible to make references for item content or not.
 * Issue 165732 - Add output field item_content (1 = the definition of item contents that provide the basis for the calculation of surcharges included with items that are purchased from vendors and sold to customers.)
 *
 * SL8.04 56 162919 jzhou Thu Jul 04 04:26:08 2013
 * Code of how to get the value of overview seems not consistent in some sps
 * Issue 162919:
 * Format the codes.
 *
 * SL8.04 55 162919 jzhou Wed Jul 03 04:58:30 2013
 * Issue 162919:
 * To make the codes in SPs which get the value of overview from the item_lang.overview be consistent.
 *
 * SL8.04 54 159127 Dmcwhorter Mon Jul 01 09:45:11 2013
 * Price rounding is incorrect on Customer order lines as it multiplies by qty ordered before rounding
 * RS6172 - Alternate Net Price Calculation.
 *
 * SL8.04 53 142850 Lpeng Tue Jun 18 11:44:42 2013
 * Fix issue 142850: Rename to BGUser
 *
 * SL8.04 51 163425 Azhang Sat Jun 08 01:43:23 2013
 * Some code need wash up for code review
 * 163425: Initialize @Surcharge before calculate Surcharge.
 *
 * SL8.04 50 rs5136 Azhang Mon May 27 03:07:30 2013
 * RS5136: Add surcharge calculation.
 *
 * SL8.04 49 RS5136 Lpeng Wed May 15 04:14:49 2013
 * RS5136:Modify reports
 *
 * SL8.04 48 rs4615 Jsun Thu Dec 27 03:47:33 2012
 * RS4615: Multi - Add Site within a Site Functionality
 *
 * SL8.04 44 149642 Clarsco Mon Oct 01 15:51:47 2012
 * SL does not print BuyDesign Configured Lines on the Estimate Response Form Report if there are no Components with External Print Codes.
 * Fixed Issue 149642
 * For SyteLine Configuration section, add a section of code that checks for no @ConfigSet rows.
 * If none then add a NULL one.
 *
 * SL8.04 43 RS5200 Cliu Wed Aug 22 02:40:07 2012
 * RS5200
 * 1. Add a new parameter "@PrintItemOverview".
 * 2. Add a new output field "ItemOverview" which is got from item_lang.item or  item.item_overview.
 *
 * SL8.03 42 148331 Clarsco Mon Apr 23 16:11:09 2012
 * Estimate Response Form Report Total is incorrect when Estimate includes a Line for a Configured Item.
 * Fixed Issue 148331
 * Config Detail lines 2 and up have zero value for TcAmtLineNet and TcTotDiscount.
 *
 * SL8.03 41 145935 pgross Fri Dec 23 14:30:19 2011
 * use the language of the Prospect
 *
 * SL8.03 40 142634 Mmarsolo Mon Oct 03 09:39:46 2011
 * Item Description not showing on the Estimate Response Form Report and the U/M has no column header.
 * 142634 - Add else condition for multi-lingual item description
 *
 * SL8.03 39 RS4978 EGriffiths Wed Jul 20 11:39:29 2011
 * RS4978 - Corrected DataTypes
 *
 * SL8.03 38 RS4428 Mzhang2 Wed Jul 06 02:39:08 2011
 * RS4428 - Query to CoView or CoItemView to includes historical data.
 *
 * SL8.03 37 137578 Cajones Fri Jun 03 08:17:55 2011
 * The totals are blank for estimate lines containing configured items and the print planning items parameter is selected.
 * Issue 137578
 * - Added code to load the reportset columns AmountFormat and AmountPlaces when creating planning item materials records.
 * - Also added coitemitem to the where statement when reportset amounts are updated so that component items don't get updated with the parent items price.
 *
 * SL8.03 36 RS5123 Cajones Wed Mar 23 10:20:19 2011
 * RS5123 - Added code to retrieve multi-lingual translations for the Terms Description, Item Description and Order Text.
 *
 * SL8.02 35 127839 calagappan Thu Apr 29 11:45:41 2010
 * Estimate Response report rounds unit price to 2 decimals and causes the extended price to be differnet then the order verification report output.
 * obtain user-defined quantity and amount formats and include in output
 *
 * SL8.02 34 rs4588 Dahn Thu Mar 04 16:28:24 2010
 * rs4588 copyright header changes.
 *
 * SL8.01 33 120946 pgross Wed Apr 29 15:54:30 2009
 * The Estimate Response Form does not round prices the same way the Estimate Lines round prices
 * round the net price
 *
 * SL8.01 32 RS4312 DPalmer Tue Jan 13 14:31:24 2009
 * RS4312 - If there is a ProspectId, but not a CustNum, then get the Currency Code from the prospect record.
 *
 * SL8.01 31 rs4312 Dahn Fri Jan 09 09:04:24 2009
 * rs4312 light
 *
 * SL8.01 30 rs3953 Vlitmano Tue Aug 26 18:59:13 2008
 * RS3953 - Changed a Copyright header?
 *
 * SL8.01 29 rs3953 Vlitmano Mon Aug 18 15:37:48 2008
 * Changed a Copyright header information(RS3959)
 *
 * SL8.00 28 RS2968 nkaleel Fri Feb 23 04:50:15 2007
 * changing copyright information(RS2968)
 *
 * SL8.00 27 RS2968 prahaladarao.hs Tue Jul 11 11:17:36 2006
 * RS 2968, Name change CopyRight Update.
 *
 * SL8.00 26 91818 NThurn Mon Jan 09 10:34:15 2006
 * Inserted standard External Touch Point call.  (RS3177)
 *
 * SL7.05 25 91534 Grosphi Tue Dec 27 14:03:34 2005
 * Incorrect discount amount when select "Order Discount Type = Amount"
 * corrected calculation of order-level discount percent
 *
 * SL7.05 24 90344 Hcl-jainami Thu Dec 08 12:58:25 2005
 * Estimate Response Form is not printing for customers with a language code specified
 * Checked-in for issue 90344:
 * Removed the following three unwanted parameters to the SP and related code:
 * @BeginCustNum
 * @EndCustNum
 * @LangCode
 *
 * SL7.05 23 87088 hcl-kansanu Wed May 18 07:48:45 2005
 * Missing header and incorrect pagination with small amount of data on second page
 * Issue No. - 87088
 *
 * Change in Stored Procedure "Rpt_EstimateResponseSP"
 * (Update Header Field of Report "EstimateFormResponse")
 *
 * SL7.05 22 87099 Hcl-jainami Tue May 10 12:24:26 2005
 * Notes on the customer bill-to are not printing on the Estimate Response Form
 * Checked-in for issue 87099:
 * Added code to display Bill To as well as Ship To Notes.
 *
 * SL7.04 22 87099 Hcl-jainami Tue May 10 11:20:46 2005
 * Notes on the customer bill-to are not printing on the Estimate Response Form
 * Checked-in for issue 87099:
 * Added code to display Bill To as well as Ship To Notes.
 *
 * SL7.04 21 85982 Grosphi Fri Feb 18 14:42:50 2005
 * When Entering a Flat Discount  - system is taking that flat amount and calculating the discount percent field.
 * 1)  added an index to @reportset for performance
 * 2)  support flat discount amounts
 *
 * SL7.04 20 85343 Grosphi Tue Feb 01 16:25:00 2005
 * allow for 55 characters in displayed feature string
 *
 * SL7.04 19 84598 Hcl-chauaja Mon Jan 10 04:05:11 2005
 * Reports print singly instead of in groups
 * Issue 84598
 *
 * $NoKeywords: $
 */
CREATE PROCEDURE [dbo].[Rpt_EstimateResponseFormSp] (
   @EstimateText               ListYesNoType = 1
 , @StdOrderText               ListYesNoType = 1
 , @ConfigDetails              NVARCHAR(1)   = 'E'
 , @PrintItemType              NVARCHAR(10)  = NULL
 , @PrintLineReleaseText       ListYesNoType = NULL
 , @PrintBillTo                ListYesNoType = NULL
 , @PrintShipTo                ListYesNoType = NULL
 , @PrintPlanningItemMaterials ListYesNoType = 1
 , @PrintEuroTotal             ListYesNoType = 0
 , @PrintPrice                 ListYesNoType = 0
 , @DisplayHeader              ListYesNoType = 0
 , @EstimateStarting           CoNumType     = NULL
 , @EstimateEnding             CoNumType     = NULL
 , @ShowInternal               FlagNyType    = 1
 , @ShowExternal               FlagNyType    = 1
 , @PrintItemOverview          FlagNyType    = 0
 , @PrintDrawingNumber         ListYesNoType = 0
 , @PrintEndUserItem           ListYesNoType = 0
 , @PrintHeaderOnAllPages      ListYesNoType = 0
 , @PrintDueDate               ListYesNoType = 0
 , @PrintProjectedDate         ListYesNoType = 0
 , @pSite                      SiteType      = NULL
 , @BGUser                     UserNameType  = NULL
) AS
--  Crystal reports has the habit of setting the isolation level to dirty
-- read, so we'll correct that for this routine now.  Transaction management
-- is also not being provided by Crystal, so a transaction is started here.
BEGIN TRANSACTION
SET XACT_ABORT ON

IF dbo.GetIsolationLevel(N'EstimateResponseFormReport') = N'COMMITTED'
   SET TRANSACTION ISOLATION LEVEL READ COMMITTED
ELSE
   SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

-- A session context is created so session variables can be used.
DECLARE
  @RptSessionID RowPointerType

EXEC dbo.InitSessionContextWithUserSp
  @ContextName = 'Rpt_EstimateResponseFormSp'
, @SessionID   = @RptSessionID OUTPUT
, @Site        = @pSite
, @UserName    = @BGUser


DECLARE -- these are all good
   @Severity                          INT
 , @TTermsDescription                 DescriptionType
 , @TEuroTotal                        CostPrcType
 , @TEuroLabel                        LongListType
 , @StdEuroCnvtAmt                    GenericDecimalType
 , @EuroAmount                        GenericDecimalType
 , @Addr0                             NVARCHAR(400)
 , @Addr1                             NVARCHAR(400)
 , @ParmsPhone                        PhoneType
 , @ParmsSite                         SiteType
 , @BillToAddress                     LongAddress
 , @ShipToAddress                     LongAddress
 , @TTextn                            GenericNoType
 , @TcAmtLineNet                      CostPrcType
 , @TcCprPrice                        CostPrcType
 , @TcTotSTotal                       AmtTotType
 , @TcTotTotal                        AmtTotType
 , @TDiscLabel                        LongListType
 , @TcTotDiscount                     CostPrcType
 , @Infobar                           InfobarType
 , @IsEuroCurr                        FlagNyType
 , @TaxParmsNumOfSys                  TaxSystemsType
 , @UseAlternateAddressReportFormat   ListYesNoType

DECLARE -- these are all good
   @ShipcodeRowPointer       RowPointerType
 , @TermsDescription         DescriptionType
 , @CoRowPointer             RowPointerType
 , @CoNoteExistsFlag         FlagNyType
 , @CoCoNum                  CoNumType
 , @CoCustNum                CustNumType
 , @CoProspectId             ProspectIdType
 , @CoCustSeq                CustSeqType
 , @CoPhone                  PhoneType
 , @CoOrderDate              DateType
 , @CoCloseDate              DateType
 , @CoSlsman                 SlsmanType
 , @CoDisc                   decimal(38, 30)--OrderDiscType
 , @CoMiscCharges            AmountType
 , @CoSalesTax               AmountType
 , @CoSalesTax2              AmountType
 , @CoTermsCode              TermsCodeType
 , @CoShipCode               ShipCodeType
 , @CoContact                ContactType
 , @CoitemRowPointer         RowPointerType
 , @CoitemNoteExistsFlag     FlagNyType
 , @CoitemCoNum              CoNumType
 , @CoitemPriceConv          CostPrcType
 , @CoitemDisc               LineDiscType
 , @CoitemQtyOrderedConv     QtyUnitNoNegType
 , @CoitemCustItem           CustItemType
 , @CoitemItem               ItemType
 , @CoitemShipSite           SiteType
 , @CoitemUM                 UMType
 , @CoitemCoLine             CoLineType
 , @CoitemCoRelease          CoReleaseType
 , @CoitemFeatStr            FeatStrType
 , @CoitemConfigId           ConfigIdType
 , @CoparmsCoText1           ReportTxtType
 , @CoparmsCoText2           ReportTxtType
 , @CoparmsCoText3           ReportTxtType
 , @CoParmsUseAltPriceCalc   ListYesNoType
 , @CoText1                  ReportTxtType
 , @CoText2                  ReportTxtType
 , @CoText3                  ReportTxtType
 , @CustomerBillToLangCode   LangCodeType
 , @CustomerBillToRowPointer RowPointerType
 , @CustomerBillToNoteExistsFlag   FlagNyType
 , @CustomerRowPointer       RowPointerType
 , @CustomerNoteExistsFlag   FlagNyType
 , @CustomerCustNum          CustNumType
 , @CustomerCustSeq          CustSeqType
 , @CustaddrRowPointer       RowPointerType
 , @CustaddrFaxNum           PhoneType
 , @CustaddrCurrCode         CurrCodeType
 , @CurrencyRowPointer       RowPointerType
 , @CurrencyDescription      DescriptionType
 , @CurrencyAmountFormat     InputMaskType
 , @CurrencyAmountPlaces     DecimalPlacesType
 , @CurrencyCostPriceFormat  InputMaskType
 , @CurrencyCostPricePlaces  DecimalPlacesType
 , @QtyUnitFormat            InputMaskType
 , @QtyUnitPlaces            DecimalPlacesType
 , @TEuroUser                FlagNyType
 , @TEuroExists              FlagNyType
 , @TBaseEuro                FlagNyType
 , @TEuroCurr                CurrCodeType
 , @LDisc                    DescriptionType
 , @TFaxLabel                DescriptionType
 , @TPhoneLabel              DescriptionType
 , @TBillLabel               DescriptionType
 , @TermLangRowPointer       RowPointerType
 , @TermLangDescription      DescriptionType
 , @InvcLangRowPointer       RowPointerType
 , @InvcLangCoText##1        ReportTxtType
 , @InvcLangCoText##2        ReportTxtType
 , @InvcLangCoText##3        ReportTxtType
 , @ItemLangDescription      DescriptionType
 , @ItemLangRowPointer       RowPointerType
 , @ItemOverview             ProductOverviewType
 , @BankName                 NameType
 , @BankTransitNum           BankTransitNumType
 , @BankAccountNo            BankAccountType

DECLARE -- these are all good
   @TtCompConfigId           ConfigIdType
 , @TtCompCompId             ConfigCompIdType
 , @CfgDetailsFlag           FlagNyType
 , @ConfigSetCount           Int
 , @CompOperNum              OperNumType
 , @CompSequence             JobmatlSequenceType
 , @AttrName                 ConfigAttrNameType

DECLARE -- added for d-config.i stuff
   @JobrouteJob              JobType
 , @JobrouteSuffix           SuffixType
 , @JobrouteOperNum          OperNumType
 , @FeatureDisplayQty        QtyPerType
 , @FeatureDisplayUM         UMType
 , @FeatureDisplayDesc       DescriptionType
 , @FeatureDisplayStr        FeatStrType
 , @ItemDescription          DescriptionType

DECLARE -- added for surcharge
   @ItemContent              FlagNyType
 , @QuantityOrdered          QtyUnitNoNegType
 , @Surcharge                CostPrcType
 , @TotalSurcharge           CostPrcType
 
 DECLARE
    @URL                    URLType
  , @Addr2                  NVARCHAR(400)
  , @EmailAddr              EmailType
  , @OfficeAddrFooter       LongAddress
  , @DrawingNbr             DrawingNbrType
  , @Delterm                DeltermType
  , @Deltermdesc            DescriptionType
  , @DueDate                DateType
  , @ProjectDate            Datetype
  , @EndUser                EndUserType
  , @EstimateResponseRpttitle ReportTitleType

DECLARE @SurchargeTable TABLE (
 CoNum      CoNumType
,CoLine     CoLineType
,CoRelease  CoReleaseType
,CoItem     ItemType
,Surcharge  CostPrcType
)

DECLARE @ConfigSet TABLE (
   CompOperNum      OperNumType
 , CompSequence     JobmatlSequenceType
 , CompCompName     ConfigCompNameType
 , CompQty          QtyUnitType
 , CompPrice        CostPrcType
 , AttrName         ConfigAttrNameType
 , AttrValue        ConfigAttrValueType
)

DECLARE @reportset TABLE (
   Addr0                     NVARCHAR(400)
 , Addr1                     NVARCHAR(400)
 , ParmsPhone                PhoneType
 , CoCustNum                 CustNumType
 , CoProspectId              ProspectIDType
 , CoPhone                   PhoneType
 , CustaddrFaxNum            PhoneType
 , CoCoNum                   CoNumType
 , TermsDescription          DescriptionType
 , CoOrderDate               DateType
 , CoCloseDate               DateType
 , CoSlsman                  SlsmanType
 , CoDisc                    Decimal(9, 4)
 , CustaddrCurrCode          CurrCodeType
 , CurrencyDescription       DescriptionType
 , CoitemQtyOrderedConv      QtyUnitNoNegType
 , CoitemCustItem            CustItemType
 , CoitemItem                ItemType
 , CoitemCoLine              CoLineType
 , CoitemCoRelease           CoReleaseType
 , CoitemUM                  UMType
 , CoitemDisc                LineDiscType
 , ItemDescription           DescriptionType
 , ItemOverview              NVARCHAR(100)

-- Config Details
 , CoitemCfgDetail           tinyint
 , CfgcompCompName           ConfigCompNameType
 , CfgcompQty                QtyUnitType
 , CfgcompPrice              CostPrcType
 , CfgattrName               ConfigAttrNameType
 , CfgattrValue              ConfigAttrValueType
 , TtCompOperNum             NVARCHAR(40)    -- why not int (OperNumType)?
 , TtCompSequence            Decimal(5, 2)   -- why not smallint(JobmatlSequenceType)?

 , TcCprPrice                Decimal(25,10)
 , TcAmtLineNet              Decimal(25,10)
 , CoContact                 ContactType
 , CoparmsCoText1            ReportTxtType
 , CoparmsCoText2            ReportTxtType
 , CoparmsCoText3            ReportTxtType
 , TcTotSTotal               Decimal(25,10)
 , TcTotDiscount             Decimal(25,10)
 , CoSalesTax                AmountType
 , CoSalesTax2               AmountType
 , CoMiscCharges             AmountType
 , EuroAmount                Decimal(25,10)
 , TEuroExists               NVARCHAR(1)
 , TcTotTotal                Decimal(25,10)
 , CoitemNoteExists          NVARCHAR(1)
-- , CoitemRowPointer          NVARCHAR(36)
 , CoitemRowPointer          RowPointerType
 , CoNoteExists              NVARCHAR(1)
-- , CoRowPointer              NVARCHAR(36)
 , CoRowPointer              RowPointerType
 , CustomerBillToNoteExists  NVARCHAR(1)
 , CustomerBillToRowPointer  RowPointerType
 , CustomerNoteExists        NVARCHAR(1)
-- , CustomerRowPointer        NVARCHAR(36)
 , CustomerRowPointer        RowPointerType
 , NumOfTaxSys               NVARCHAR(1)
 , JobrouteJob               JobType
 , JobrouteSuffix            NVARCHAR(4)
 , JobrouteOperNum           NVARCHAR(4)
 , FeatureDisplayQty         QtyPerType
 , FeatureDisplayUM          UMType
 , FeatureDisplayDesc        DescriptionType
 , FeatureDisplayStr         FeatTemplateType
 , AmountFormat              InputMaskType
 , AmountPlaces              DecimalPlacesType
 , CostPriceFormat           InputMaskType
 , CostPricePlaces           DecimalPlacesType
 , QtyUnitFormat             InputMaskType
 , QtyUnitPlaces             DecimalPlacesType
 , seq                       int identity(1, 1)
 , Item_content              ListYesNoType
 , drawing_nbr               DrawingNbrType
 , delterm                   DeltermType
 , end_user                  NameType
 , del_term_desc             DescriptionType
 , url                       URLType
 , email_addr                EmailType
 , addr2                     NVARCHAR(400)
 , due_date                  DateType
 , project_date              DateType
 , office_addr_footer        NVARCHAR(400)
 , estimate_response_rpt_title ReportTitleType
 , bank_name                 NameType      
 , bank_transit_num          BankTransitNumType
 , bank_acct_no              BankAccountType

primary key (CoCoNum, CoitemCoLine, CoitemUM desc, FeatureDisplayStr desc, JobrouteJob, JobrouteSuffix, JobrouteOperNum, seq)
)

SET @EstimateStarting = isnull(@EstimateStarting, dbo.lowcharacter())
SET @EstimateEnding   = isnull(@EstimateEnding, dbo.highcharacter())

   -- Check for existence of Generic External Touch Point routine (this section was generated by SpETPCodeSp and inserted by CallETPs.exe):
   IF OBJECT_ID(N'dbo.EXTGEN_Rpt_EstimateResponseFormSp') IS NOT NULL
   BEGIN
      DECLARE @EXTGEN_SpName sysname
      SET @EXTGEN_SpName = N'dbo.EXTGEN_Rpt_EstimateResponseFormSp'
      -- Invoke the ETP routine, passing in (and out) this routine's parameters:
      EXEC @EXTGEN_SpName
         @EstimateText
         , @StdOrderText
         , @ConfigDetails
         , @PrintItemType
         , @PrintLineReleaseText
         , @PrintBillTo
         , @PrintShipTo
         , @PrintPlanningItemMaterials
         , @PrintEuroTotal
         , @PrintPrice
         , @DisplayHeader
         , @EstimateStarting
         , @EstimateEnding
         , @ShowInternal
         , @ShowExternal
         , @PrintItemOverview
         , @PrintDrawingNumber
         , @PrintEndUserItem
         , @PrintHeaderOnAllPages
         , @PrintDueDate
         , @PrintProjectedDate
         , @pSite
         , @BGUser

      IF @@TRANCOUNT > 0
         COMMIT TRANSACTION
      EXEC dbo.CloseSessionContextSp @SessionID = @RptSessionID
      -- ETP routine must take over all desired functionality of this standard routine:
      RETURN
   END
   -- End of Generic External Touch Point code.

SET @EstimateStarting = dbo.ExpandKyByType('CoNumType', @EstimateStarting)
SET @EstimateEnding = dbo.ExpandKyByType('CoNumType', @EstimateEnding)

SET @Severity       = 0
SET @TTextn         = 0
SET @TcCprPrice     = 0
SET @TEuroExists    = 0
SET @TotalSurcharge = 0
-- get company phone from parms
SELECT
  @ParmsPhone = parms.phone
, @ParmsSite  = parms.site
FROM parms

SELECT
   @URL = parms.url
FROM parms (READUNCOMMITTED)
WHERE parm_key = 0

SELECT
   @EmailAddr = arparms.email_addr
FROM arparms WITH (READUNCOMMITTED)

SELECT
   @EstimateResponseRpttitle = coparms.estimate_response_rpt_title
FROM coparms WITH (READUNCOMMITTED)

SET @OfficeAddrFooter = dbo.DisplayAddressForReportFooter()
--get Use Alternate Address Report Format from parms
SELECT @UseAlternateAddressReportFormat = use_alt_addr_report_formatting FROM parms WITH (readuncommitted) WHERE parm_key = 0

-- get co address from Parms
IF @UseAlternateAddressReportFormat = 0
  EXEC @Addr0 = dbo.DisplayOurAddress
ELSE
  EXEC @Addr0 = dbo.GetParmsSingleLineAddressSp

-- printing standard order text
IF @StdOrderText = 1
   SELECT
      @CoparmsCoText1 = coparms.co_text_1
    , @CoparmsCoText2 = coparms.co_text_2
    , @CoparmsCoText3 = coparms.co_text_3
    , @CoParmsUseAltPriceCalc = coparms.use_alt_price_calc
   FROM coparms

-- get currency code
DECLARE
  @CurrparmsCurrCode CurrCodeType

SELECT
  @CurrparmsCurrCode = currparms.curr_code
FROM currparms

SELECT
  @QtyUnitFormat = qty_unit_format
, @QtyUnitPlaces = places_qty_unit
FROM invparms

SET @QtyUnitFormat = dbo.FixMaskForCrystal( @QtyUnitFormat, dbo.GetWinRegDecGroup() )

-- are we using multiple tax systems?
SET @TaxParmsNumOfSys   = NULL

SELECT
   @TaxParmsNumOfSys      = taxparms.nmbr_of_systems
FROM taxparms

-- get some Euro info
EXEC dbo.EuroInfoSp 0
         ,@TEuroUser OUTPUT
         ,@TEuroExists OUTPUT
         ,@TBaseEuro OUTPUT
         ,@TEuroCurr OUTPUT
         ,@Infobar OUTPUT
, @Site = @ParmsSite

-- init some more stuff
SET @LDisc       = dbo.GetLabel('@citemh.disc')
SET @TFaxLabel   = dbo.GetLabel('@custaddr.fax_num')
SET @TPhoneLabel = dbo.GetLabel('@co.phone')
SET @TBillLabel  = dbo.GetLabel('@customer.cust_num')

--BEGIN -- main procedure
DECLARE co_crs CURSOR LOCAL STATIC FOR
SELECT
   co.RowPointer
 , co.co_num
 , co.cust_num
 , co.prospect_id
 , co.cust_seq
 , co.phone
 , co.order_date
 , co.close_date
 , co.slsman
 , case when co.discount_type = 'P' then co.disc
   else (co.disc_amount * 100.0) / (co.price + co.disc_amount
         - co.sales_tax - co.sales_tax_2 - co.misc_charges - co.freight
         - co.sales_tax_t - co.sales_tax_t2 - co.m_charges_t - co.freight_t)
   end
 , co.misc_charges
 , co.sales_tax
 , co.sales_tax_2
 , co.terms_code
 , co.ship_code
 , co.contact
 , customer.RowPointer
 , coalesce(billtocust.lang_code, prospect.lang_code)
 , billtocust.RowPointer
 , customer.cust_num
 , custaddr.RowPointer
 , custaddr.fax_num
 , terms.description
 , shipcode.RowPointer
 , billto.RowPointer
 , COALESCE(billto.curr_code, prospect.curr_code, @CurrparmsCurrCode)
 , currency.RowPointer
 , currency.description
 , currency.amt_format
 , currency.places
 , currency.cst_prc_format
 , currency.places_cp
 , case when @EstimateText = 1 then dbo.ReportNotesExist('co', co.RowPointer, @ShowInternal, @ShowExternal, co.NoteExistsFlag) else 0 end
 , case when @PrintShipTo = 1 then dbo.ReportNotesExist('customer', customer.RowPointer, @ShowInternal, @ShowExternal, customer.NoteExistsFlag) else 0 end
 , case when @PrintBillTo = 1 then dbo.ReportNotesExist('customer', billtocust.RowPointer, @ShowInternal, @ShowExternal, billtocust.NoteExistsFlag) else 0 end
 , term_lang.RowPointer
 , term_lang.description
 , invc_lang.RowPointer
 , invc_lang.co_text##1
 , invc_lang.co_text##2
 , invc_lang.co_text##3
 , bank_hdr.name       
 , bank_hdr.bank_transit_num
 , customer.bank_acct_no
FROM CoView co
   left outer join customer on
      customer.cust_num = co.cust_num
      and customer.cust_seq = co.cust_seq
   left outer join custaddr on
      custaddr.cust_num = co.cust_num
      and custaddr.cust_seq = co.cust_seq
   left outer join terms on
      terms.terms_code = co.terms_code
   left outer join shipcode on
      shipcode.ship_code = co.ship_code
   left outer join custaddr as billto on
      billto.cust_num = customer.cust_num
      and billto.cust_seq = 0
   left outer join customer as billtocust on
      billtocust.cust_num = customer.cust_num
      and billtocust.cust_seq = 0
   LEFT OUTER JOIN prospect ON
      prospect.prospect_id = co.prospect_id
   left outer join currency on
      currency.curr_code = COALESCE(billto.curr_code, prospect.curr_code, @CurrparmsCurrCode)
   left outer join term_lang on
      term_lang.terms_code = terms.terms_code
      and term_lang.lang_code = coalesce(billtocust.lang_code, prospect.lang_code)
   left outer join invc_lang on
      invc_lang.lang_code = coalesce(billtocust.lang_code, prospect.lang_code)
   left outer join bank_hdr on
      customer.cust_bank = bank_hdr.bank_code
WHERE   co.type = 'E'
  AND co.co_num BETWEEN @EstimateStarting AND @EstimateEnding
OPEN co_crs
WHILE @Severity = 0
BEGIN
   FETCH co_crs INTO
      @CoRowPointer
    , @CoCoNum
    , @CoCustNum
    , @CoProspectId
    , @CoCustSeq
    , @CoPhone
    , @CoOrderDate
    , @CoCloseDate
    , @CoSlsman
    , @CoDisc
    , @CoMiscCharges
    , @CoSalesTax
    , @CoSalesTax2
    , @CoTermsCode
    , @CoShipCode
    , @CoContact
    , @CustomerRowPointer
    , @CustomerBillToLangCode
    , @CustomerBillToRowPointer
    , @CustomerCustNum
    , @CustaddrRowPointer
    , @CustaddrFaxNum
    , @TermsDescription
    , @ShipcodeRowPointer
    , @CustaddrRowPointer
    , @CustaddrCurrCode
    , @CurrencyRowPointer
    , @CurrencyDescription
    , @CurrencyAmountFormat
    , @CurrencyAmountPlaces
    , @CurrencyCostPriceFormat
    , @CurrencyCostPricePlaces
    , @CoNoteExistsFlag
    , @CustomerNoteExistsFlag
    , @CustomerBillToNoteExistsFlag
    , @TermLangRowPointer
    , @TermLangDescription
    , @InvcLangRowPointer
    , @InvcLangCoText##1
    , @InvcLangCoText##2
    , @InvcLangCoText##3
    , @BankName
    , @BankTransitNum
    , @BankAccountNo

   IF @@FETCH_STATUS <> 0
        BREAK

  -- LOOKING FOR MULTI-LINGUAL
   SET @TermsDescription = CASE  WHEN @TermLangRowPointer IS NOT NULL
                                 THEN @TermLangDescription
                                 ELSE @TermsDescription
                           END
   SET @CoText1 = CASE  WHEN @InvcLangRowPointer IS NOT NULL
                        THEN @InvcLangCoText##1
                        ELSE @CoParmsCoText1
                  END
   SET @CoText2 = CASE  WHEN @InvcLangRowPointer IS NOT NULL
                        THEN @InvcLangCoText##2
                        ELSE @CoParmsCoText2
                  END
   SET @CoText3 = CASE  WHEN @InvcLangRowPointer IS NOT NULL
                        THEN @InvcLangCoText##3
                        ELSE @CoParmsCoText3
                  END
   SET @TEuroTotal = 0

   SET @BillToAddress = ''
   SET @ShipToAddress = ''

   -- RS4312: Set addr1 the Prospect Name and address if co.cust_num is NULL
   IF @CoCustNum IS NOT NULL AND @CoCustNum <> ''
      EXEC dbo.FormatAddressWithContactNameSp @CoCustNum
            , @CoCustSeq
            , @BillToAddress OUTPUT
            , @ShipToAddress OUTPUT
            , @Infobar OUTPUT
            , @CoContact
   ELSE
      SET @ShipToAddress = dbo.FormatProspectAddressWithContact (@CoProspectID, @CoContact)

   SET @Addr1 = @ShipToAddress
   SET @Addr2 = @BillToAddress

--                    terms records is not available at the page-top
--                     when more then 1 page per first-of(coitem.co-num)
   IF @ShipcodeRowPointer IS NULL
      SET @TTermsDescription = @TermsDescription

   SET @CurrencyAmountFormat = dbo.FixMaskForCrystal( @CurrencyAmountFormat, dbo.GetWinRegDecGroup() )
   SET @CurrencyCostPriceFormat = dbo.FixMaskForCrystal( @CurrencyCostPriceFormat, dbo.GetWinRegDecGroup() )

   if @CurrparmsCurrCode = @CustaddrCurrCode and @TBaseEuro = 0
      set @IsEuroCurr = 0
   else
      EXEC dbo.EuroPartSp @CustaddrCurrCode, @IsEuroCurr OUTPUT, @Site = @ParmsSite

   DECLARE coitem_crs CURSOR LOCAL STATIC FOR
   SELECT
      coitem.RowPointer
    , coitem.co_num
    , coitem.price_conv
    , coitem.disc
    , coitem.qty_ordered_conv
    , coitem.cust_item
    , coitem.item
    , coitem.ship_site
    , coitem.u_m
    , coitem.co_line
    , coitem.co_release
    , coitem.feat_str
    , coitem.config_id
    , isnull(coitem.description,item.description)
    , case when @PrintLineReleaseText = 1 then dbo.ReportNotesExist('coitem', coitem.RowPointer, @ShowInternal, @ShowExternal, coitem.NoteExistsFlag) else 0 end
    , item_lang.description
    , item_lang.RowPointer
    , CASE WHEN @PrintItemOverview = 1
           THEN ISNULL(LEFT(item_lang.overview, 100), LEFT(item.overview, 100))
           ELSE NULL
      END
    , item.item_content
    , item.drawing_nbr
    , coitem.delterm
    , itemcust.end_user
    , del_term.description
    , coitem.due_date
    , coitem.projected_date
   FROM CoItemView coitem
      LEFT JOIN item ON coitem.item = item.item
      LEFT OUTER JOIN item_lang on item_lang.item = coitem.item
                               and item_lang.lang_code = @CustomerBillToLangCode
      LEFT JOIN itemcust ON itemcust.cust_item = coitem.cust_item AND itemcust.item = coitem.item AND itemcust.cust_num = coitem.co_cust_num
      LEFT JOIN del_term ON del_term.delterm = coitem.delterm
   WHERE coitem.co_num = @CoCoNum
        --break by coitem.co_num ????????????????????;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

   OPEN coitem_crs
   WHILE @Severity = 0
   BEGIN
        FETCH coitem_crs INTO
         @CoitemRowPointer
       , @CoitemCoNum
       , @CoitemPriceConv
       , @CoitemDisc
       , @CoitemQtyOrderedConv
       , @CoitemCustItem
       , @CoitemItem
       , @CoitemShipSite
       , @CoitemUM
       , @CoitemCoLine
       , @CoitemCoRelease
       , @CoitemFeatStr
       , @CoitemConfigId
       , @ItemDescription
       , @CoitemNoteExistsFlag
       , @ItemLangDescription
       , @ItemLangRowPointer
       , @ItemOverview
       , @ItemContent
       , @DrawingNbr
       , @Delterm
       , @EndUser
       , @Deltermdesc
       , @DueDate
       , @ProjectDate

      IF @@FETCH_STATUS <> 0
         BREAK

      SET @TcTotSTotal = 0

   -- LOOKING FOR MULTI-LINGUAL
     SET @ItemDescription =  CASE  WHEN @ItemLangRowPointer IS NOT NULL
                                THEN @ItemLangDescription
                                ELSE @ItemDescription
                        END

-- let's do some calculations
      SET @TcCprPrice   = CASE WHEN @CoParmsUseAltPriceCalc = 1 THEN
                             ROUND(@CoitemPriceConv * (1.0 - @CoitemDisc / 100.0), @CurrencyAmountPlaces)
                          ELSE
                             @CoitemPriceConv * (1.0 - @CoitemDisc / 100.0)
                          END

      SET @TcAmtLineNet = round(@CoitemQtyOrderedConv * @TcCprPrice, @CurrencyAmountPlaces)
      SET @TcTotSTotal  = @TcTotSTotal + @TcAmtLineNet

-- let's do some Euro currency convert if necessary
      IF ((@TEuroExists = 1) and (@CustaddrRowPointer IS NOT NULL))
      BEGIN
         IF @IsEuroCurr = 1 -- Yes
         BEGIN
            EXEC @StdEuroCnvtAmt = dbo.EuroCnvt   @TcAmtLineNet
                                    , @CustaddrCurrCode
                                    , 0
                                    , 1
            SET @TEuroTotal = @TEuroTotal + @StdEuroCnvtAmt
         END
      END

-- Begin SyteLine Configuration
      IF @ConfigDetails <> 'N' AND @CoitemConfigId IS NOT NULL
      BEGIN
         SET @CfgDetailsFlag = 1
         INSERT INTO @ConfigSet (
            CompOperNum
          , CompSequence
          , CompCompName
          , CompQty
          , CompPrice
          , AttrName
          , AttrValue
            )
         SELECT
            CompOperNum
          , CompSequence
          , CompCompName
          , CompQty
          , CompPrice
          , AttrName
          , AttrValue
         FROM dbo.CfgGetConfigValues(@CoitemConfigId, @ConfigDetails)

         IF 0 = (SELECT COUNT(*) FROM @ConfigSet)
         BEGIN
            SET @CfgDetailsFlag = 0
            INSERT INTO @ConfigSet (
               CompOperNum
             , CompSequence
             , CompCompName
             , CompQty
             , CompPrice
             , AttrName
             , AttrValue )
            VALUES (
               NULL
             , NULL
             , NULL
             , NULL
             , NULL
             , NULL
             , NULL )
         END
      END
      ELSE
      BEGIN
         SET @CfgDetailsFlag = 0
         INSERT INTO @ConfigSet (
            CompOperNum
          , CompSequence
          , CompCompName
          , CompQty
          , CompPrice
          , AttrName
          , AttrValue
            )
         VALUES ( NULL, NULL, NULL, NULL, NULL, NULL, NULL )
      END
-- End SyteLine Configuration

--  PRINT FBOM STUFF
      IF @PrintPlanningItemMaterials = 1 AND @CoitemFeatStr IS NOT NULL
      BEGIN
         INSERT INTO @reportset (
              CoCoNum
            , CoitemCoLine
            , CoitemCoRelease
            , CoitemUM
            , JobrouteJob
            , JobrouteSuffix
            , JobrouteOperNum
            , FeatureDisplayQty
            , FeatureDisplayUM
            , FeatureDisplayDesc
            , FeatureDisplayStr
            , AmountFormat
            , AmountPlaces
            )
         SELECT
            @CoCoNum
          , @CoitemCoLine
          , @CoitemCoRelease
          , ''
            , dconfig.JobRouteJob, dconfig.JobrouteSuffix, dconfig.JobrouteOperNum
            , dconfig.FeatureDisplayQty, dconfig.FeatureDisplayUM, dconfig.FeatureDisplayDesc
            , dconfig.FeatureDisplayStr
            , @CurrencyAmountFormat
            , @CurrencyAmountPlaces
            FROM dbo.CoDConfig (
              @CoitemCoNum
            , @CoitemCoLine
            , @CoitemCoRelease
            , @CoitemItem
            , @CoitemShipSite
            , @CoOrderDate
            , @CoitemFeatStr ) as dconfig

         INSERT INTO @reportset (
              CoCoNum
            , CoitemCoLine
            , CoitemCoRelease
            , FeatureDisplayStr
            , CoitemUM
            , JobrouteJob
            , JobrouteSuffix
            , JobrouteOperNum
            , AmountFormat
            , AmountPlaces
            )
         SELECT TOP 1
              CoCoNum
            , CoitemCoLine
            , CoitemCoRelease
            , FeatureDisplayStr
         , ''
         , ''
         , ''
         , ''
         , @CurrencyAmountFormat
         , @CurrencyAmountPlaces
         FROM @reportset
         WHERE CoCoNum = @CoitemCoNum
         AND CoitemCoLine = @CoitemCoLine

         UPDATE @reportset
         SET FeatureDisplayStr = ''
         FROM @reportset
         WHERE CoCoNum = @CoitemCoNum
         AND CoitemCoLine = @CoitemCoLine
         AND FeatureDisplayQty IS NOT NULL

      END

-- let's load some recordset data
--              THIS ORDER HAD LINE ITEMS TO INVOICE
      SET @TcTotTotal = @TcTotSTotal - (@TcTotSTotal * @CoDisc / 100) + (@CoMiscCharges + @CoSalesTax + @CoSalesTax2)
      SET @TcTotDiscount = (@TcTotSTotal * @CoDisc) / (100 * -1)

      IF @TEuroExists = 1
      BEGIN
         IF @IsEuroCurr = 1 --Yes
         BEGIN
 -- Check For Discount
            SET @TEuroTotal = @TEuroTotal - (@TEuroTotal * @CoDisc / 100)

 -- Misc Charges
              EXEC @StdEuroCnvtAmt = dbo.EuroCnvt @CoMiscCharges
                     , @CustaddrCurrCode
                     , 0
                     , 0
            SET @TEuroTotal = @TEuroTotal + @StdEuroCnvtAmt

 -- Sales Tax
            EXEC @StdEuroCnvtAmt = dbo.EuroCnvt   @CoSalesTax
                     , @CustaddrCurrCode
                     , 0
                     , 0

            SET @TEuroTotal = @TEuroTotal + @StdEuroCnvtAmt

 -- Sales Tax 2
            EXEC @StdEuroCnvtAmt = dbo.EuroCnvt   @CoSalesTax2
                     , @CustaddrCurrCode
                     , 0
                     , 0

            SET @TEuroTotal = @TEuroTotal + @StdEuroCnvtAmt
         END -- if @IsEuroCurr is Yes
      END -- if teuroexists

-- printing price
      IF @PrintPrice = 1
      BEGIN
         SET @TEuroLabel = ''
         SET @EuroAmount  = 0

         IF ((@TEuroExists = 1) and (@CustaddrRowPointer IS NOT NULL) and (@PrintEuroTotal = 1))
         BEGIN
            IF @IsEuroCurr = 1 -- yes
            BEGIN
--                SET @TEuroLabel = 'Euro Total'
               SET @TEuroLabel = dbo.GetLabel('@!EuroTotal')
               SET @EuroAmount = @TEuroTotal
            END
         END
      END -- if print price

-- set notes flags on any feature records that were created
      IF @PrintPlanningItemMaterials = 1 AND @CoitemFeatStr IS NOT NULL
      BEGIN
         UPDATE @reportset
         SET
            CoitemNoteExists = @CoitemNoteExistsFlag
          , CoitemRowPointer = @CoitemRowPointer
          , CoNoteExists = @CoNoteExistsFlag
          , CoRowPointer = @CoRowPointer
          , CustomerBillToNoteExists = @CustomerBillToNoteExistsFlag
          , CustomerBillToRowPointer = @CustomerBillToRowPointer
          , CustomerNoteExists = @CustomerNoteExistsFlag
          , CustomerRowPointer = @CustomerRowPointer
          , CoparmsCoText1 = @CoText1
          , CoparmsCoText2 = @CoText2
          , CoparmsCoText3 = @CoText3
         FROM @reportset
         WHERE CoCoNum = @CoitemCoNum
         AND CoitemCoLine = @CoitemCoLine
      END

-- load reportset for return to Crystal
-- check if we are to return price values
      IF @PrintPrice <> 1
      BEGIN
         SET @TcCprPrice = 0
         SET @TcAmtLineNet = 0
         SET @CustaddrCurrCode = ''
         SET @CurrencyDescription = ''

         SET @TcTotSTotal = 0
         SET @TcTotDiscount = 0
         SET @CoSalesTax = 0
         SET @CoSalesTax2 = 0
         SET @CoMiscCharges = 0
       --SET @EuroAmount = 0
         SET @TcTotTotal = 0
      END

      INSERT INTO @reportset (
         Addr0
       , Addr1
       , ParmsPhone
       , CoCustNum
       , CoProspectId
       , CoPhone
       , CustaddrFaxNum
       , CoCoNum
       , TermsDescription
       , CoOrderDate
       , CoCloseDate
       , CoSlsman
       , CoDisc
       , CustaddrCurrCode
       , CurrencyDescription
       , CoitemQtyOrderedConv
       , CoitemCustItem
       , CoitemItem
       , CoitemCoLine
       , CoitemCoRelease
       , CoitemUM
       , CoitemDisc
       , ItemDescription
       , ItemOverview
       , CoitemCfgDetail
       , CfgcompCompName
       , CfgcompQty
       , CfgcompPrice
--          , CfgcompCompId
--          , CfgcompConfigId
       , CfgattrName
       , CfgattrValue
       , TtCompOperNum
       , TtCompSequence
       , TcCprPrice
       , TcAmtLineNet
       , CoparmsCoText1
       , CoparmsCoText2
       , CoparmsCoText3
       , TcTotSTotal
       , CoContact
       , TcTotDiscount
       , CoSalesTax
       , CoSalesTax2
       , CoMiscCharges
       , EuroAmount
       , TEuroExists
       , TcTotTotal
       , CoitemNoteExists
       , CoitemRowPointer
       , CoNoteExists
       , CoRowPointer
       , CustomerBillToNoteExists
       , CustomerBillToRowPointer
       , CustomerNoteExists
       , CustomerRowPointer
       , NumOfTaxSys
       , JobrouteJob
       , JobrouteSuffix
       , JobrouteOperNum
       , FeatureDisplayQty
       , FeatureDisplayUM
       , FeatureDisplayDesc
       , FeatureDisplayStr
       , AmountFormat
       , AmountPlaces
       , CostPriceFormat
       , CostPricePlaces
       , QtyUnitFormat
       , QtyUnitPlaces
       , Item_Content
       , drawing_nbr
       , delterm
       , end_user
       , del_term_desc
       , url
       , email_addr
       , addr2
       , due_date
       , project_date
       , office_addr_footer
       , estimate_response_rpt_title
       , bank_name        
       , bank_transit_num 
       , bank_acct_no     
      )
      SELECT TOP 1
         @Addr0
       , @Addr1
       , @ParmsPhone
       , @CoCustNum
       , @CoProspectId
       , @CoPhone
       , @CustaddrFaxNum
       , @CoCoNum
       , @TermsDescription
       , @CoOrderDate
       , @CoCloseDate
       , @CoSlsman
       , @CoDisc
       , @CustaddrCurrCode
       , @CurrencyDescription
       , @CoitemQtyOrderedConv
       , @CoitemCustItem
       , @CoitemItem
       , @CoitemCoLine
       , @CoitemCoRelease
       , @CoitemUM
       , @CoitemDisc
       , @ItemDescription
       , @ItemOverview
       , @CfgDetailsFlag
       , Config.CompCompName
       , Config.CompQty
       , Config.CompPrice
--          , @TtCompCompId     -- Config.AttrName
--          , @TtCompConfigId   -- Config.AttrValue
       , Config.AttrName
       , Config.AttrValue
       , Config.CompOperNum
       , Config.CompSequence
       , @TcCprPrice
       , @TcAmtLineNet
       , @CoText1
       , @CoText2
       , @CoText3
       , @TcTotSTotal
       , @CoContact
       , @TcTotDiscount
       , @CoSalesTax
       , @CoSalesTax2
       , @CoMiscCharges
       , @EuroAmount
       , @TEuroExists
       , @TcTotTotal
       , @CoitemNoteExistsFlag
       , @CoitemRowPointer
       , @CoNoteExistsFlag
       , @CoRowPointer
       , @CustomerBillToNoteExistsFlag
       , @CustomerBillToRowPointer
       , @CustomerNoteExistsFlag
       , @CustomerRowPointer
       , @TaxParmsNumOfSys
       , isnull(@JobrouteJob, '')
       , isnull(@JobrouteSuffix, '')
       , isnull(@JobrouteOperNum, '')
       , @FeatureDisplayQty
       , @FeatureDisplayUM
       , @FeatureDisplayDesc
       , isnull(@FeatureDisplayStr, '')
       , @CurrencyAmountFormat
       , @CurrencyAmountPlaces
       , @CurrencyCostPriceFormat
       , @CurrencyCostPricePlaces
       , @QtyUnitFormat
       , @QtyUnitPlaces
       , @ItemContent
       , @DrawingNbr
       , @Delterm
       , @EndUser
       , @Deltermdesc
       , @URL
       , @EmailAddr
       , @Addr2
       , @DueDate
       , @ProjectDate
       , @OfficeAddrFooter
       , @EstimateResponseRpttitle
       , @BankName
       , @BankTransitNum
       , @BankAccountNo       
       
      FROM /* coitem
      LEFT OUTER JOIN */ @ConfigSet as Config
      ORDER BY CompOperNum, CompSequence

      SET @ConfigSetCount = NULL
      SELECT @ConfigSetCount = COUNT(*) FROM @ConfigSet

      IF @ConfigSetCount > 1
      BEGIN
         SELECT TOP 1 @CompOperNum = CompOperNum, @AttrName = AttrName, @CompSequence = CompSequence FROM @ConfigSet
            ORDER BY CompOperNum, CompSequence

         DELETE @ConfigSet WHERE @CompOperNum = CompOperNum AND @AttrName  = AttrName

        INSERT INTO @reportset (
          Addr0
         , Addr1
         , ParmsPhone
         , CoCustNum
         , CoProspectId
         , CoPhone
         , CustaddrFaxNum
         , CoCoNum
         , TermsDescription
         , CoOrderDate
         , CoCloseDate
         , CoSlsman
         , CoDisc
         , CustaddrCurrCode
         , CurrencyDescription
         , CoitemQtyOrderedConv
         , CoitemCustItem
         , CoitemItem
         , CoitemCoLine
         , CoitemCoRelease
         , CoitemUM
         , CoitemDisc
         , ItemDescription
         , ItemOverview
         , CoitemCfgDetail
         , CfgcompCompName
         , CfgcompQty
         , CfgcompPrice
   --          , CfgcompCompId
   --          , CfgcompConfigId
         , CfgattrName
         , CfgattrValue
         , TtCompOperNum
         , TtCompSequence
         , TcCprPrice
         , TcAmtLineNet
         , CoparmsCoText1
         , CoparmsCoText2
         , CoparmsCoText3
         , TcTotSTotal
         , CoContact
         , TcTotDiscount
         , CoSalesTax
         , CoSalesTax2
         , CoMiscCharges
         , EuroAmount
         , TEuroExists
         , TcTotTotal
         , CoitemNoteExists
         , CoitemRowPointer
         , CoNoteExists
         , CoRowPointer
         , CustomerBillToNoteExists
         , CustomerBillToRowPointer
         , CustomerNoteExists
         , CustomerRowPointer
         , NumOfTaxSys
         , JobrouteJob
         , JobrouteSuffix
         , JobrouteOperNum
         , FeatureDisplayQty
         , FeatureDisplayUM
         , FeatureDisplayDesc
         , FeatureDisplayStr
         , AmountFormat
         , AmountPlaces
         , CostPriceFormat
         , CostPricePlaces
         , QtyUnitFormat
         , QtyUnitPlaces
         , Item_Content
         , drawing_nbr
         , delterm
         , end_user
         , del_term_desc
         , url
         , email_addr
         , addr2
         , due_date
         , project_date
         , office_addr_footer
         , estimate_response_rpt_title
         , bank_name 
         , bank_transit_num
         , bank_acct_no
        )
        SELECT
          @Addr0
         , @Addr1
         , @ParmsPhone
         , @CoCustNum
         , @CoProspectId
         , @CoPhone
         , @CustaddrFaxNum
         , @CoCoNum
         , @TermsDescription
         , @CoOrderDate
         , @CoCloseDate
         , @CoSlsman
         , @CoDisc
         , @CustaddrCurrCode
         , @CurrencyDescription
         , @CoitemQtyOrderedConv
         , @CoitemCustItem
         , @CoitemItem
         , @CoitemCoLine
         , @CoitemCoRelease
         , @CoitemUM
         , @CoitemDisc
         , @ItemDescription
         , @ItemOverview
         , @CfgDetailsFlag
         , Config.CompCompName
         , Config.CompQty
         , Config.CompPrice
   --          , @TtCompCompId     -- Config.AttrName
   --          , @TtCompConfigId   -- Config.AttrValue
         , Config.AttrName
         , Config.AttrValue
         , Config.CompOperNum
         , Config.CompSequence
         , @TcCprPrice
         , 0
         , @CoText1
         , @CoText2
         , @CoText3
         , @TcTotSTotal
         , @CoContact
         , 0
         , @CoSalesTax
         , @CoSalesTax2
         , @CoMiscCharges
         , @EuroAmount
         , @TEuroExists
         , @TcTotTotal
         , @CoitemNoteExistsFlag
         , @CoitemRowPointer
         , @CoNoteExistsFlag
         , @CoRowPointer
         , @CustomerBillToNoteExistsFlag
         , @CustomerBillToRowPointer
         , @CustomerNoteExistsFlag
         , @CustomerRowPointer
         , @TaxParmsNumOfSys
         , isnull(@JobrouteJob, '')
         , isnull(@JobrouteSuffix, '')
         , isnull(@JobrouteOperNum, '')
         , @FeatureDisplayQty
         , @FeatureDisplayUM
         , @FeatureDisplayDesc
         , isnull(@FeatureDisplayStr, '')
         , @CurrencyAmountFormat
         , @CurrencyAmountPlaces
         , @CurrencyCostPriceFormat
         , @CurrencyCostPricePlaces
         , @QtyUnitFormat
         , @QtyUnitPlaces
         , @ItemContent
         , @DrawingNbr
         , @Delterm
         , @EndUser
         , @Deltermdesc
         , @URL
         , @EmailAddr
         , @Addr2
         , @DueDate
         , @ProjectDate
         , @OfficeAddrFooter
         , @EstimateResponseRpttitle
         , @BankName
         , @BankTransitNum
         , @BankAccountNo
        FROM /* coitem
        LEFT OUTER JOIN */ @ConfigSet as Config
        ORDER BY Config.CompOperNum, Config.CompSequence
    END

   UPDATE @reportset
   SET
   TcCprPrice = @TcCprPrice
   , CoDisc = @CoDisc
   , EuroAmount = @EuroAmount
   , TcTotSTotal = @TcTotSTotal
   , CoSalesTax = @CoSalesTax
   , CoSalesTax2 = @CoSalesTax2
   , CoMiscCharges = @CoMiscCharges
   , TcTotTotal = @TcTotTotal
   , TEuroExists = @TEuroExists
   FROM @reportset
   WHERE CoCoNum = @CoitemCoNum
   AND CoitemCoLine = @CoitemCoLine
   AND CoitemItem = @CoitemItem

      -- Clear TempTable
      DELETE FROM @ConfigSet

-- END -- if last-of(coitem.co-num)
   END -- COITEM Loop
   CLOSE      coitem_crs
   DEALLOCATE coitem_crs -- END COITEM

END -- CO Loop

CLOSE      co_crs
DEALLOCATE co_crs -- END CO-LOOP

DECLARE surcharge_cal_crs CURSOR LOCAL STATIC FOR
SELECT
 RS.CoCoNum
,RS.CoitemCoLine
,RS.CoitemCoRelease
,RS.CoitemItem
,CoOrderDate
,coitem.qty_ordered
,item_content
,AmountPlaces
FROM @ReportSet RS JOIN coitem
ON RS.CoCoNum = coitem.co_num AND RS.CoitemCoLine = coitem.co_line AND RS.CoitemCoRelease = coitem.co_release

OPEN surcharge_cal_crs
WHILE @@ERROR = 0
BEGIN
   FETCH surcharge_cal_crs INTO
    @CoCoNum
   ,@CoitemCoLine
   ,@CoitemCoRelease
   ,@CoitemItem
   ,@CoOrderDate
   ,@QuantityOrdered
   ,@ItemContent
   ,@CurrencyAmountPlaces

   IF @@FETCH_STATUS = -1
      BREAK

   SET @Surcharge   = 0

   IF @ItemContent = 1
   BEGIN
      EXEC @Severity = dbo.GetItemSurchargeSp
          @Item            = @CoitemItem
        , @RefType         = 'E'
        , @RefNum          = @CoCoNum
        , @RefLine         = @CoitemCoLine
        , @RefRelease      = @CoitemCoRelease
        , @InvNum          = NULL
        , @TransDate       = @CoOrderDate
        , @RefItemContent  = NULL
        , @SumSurcharge    = @Surcharge OUTPUT

      IF @Severity <> 0
         BREAK

      SET @TotalSurcharge = round(@Surcharge * @QuantityOrdered, @CurrencyAmountPlaces)

      INSERT INTO @SurchargeTable
      (
        CoNum
      , CoLine
      , CoRelease
      , CoItem
      , Surcharge
      )
      VALUES
      (
        @CoCoNum
      , @CoitemCoLine
      , @CoitemCoRelease
      , @CoitemItem
      , @TotalSurcharge
      )

   END
END

CLOSE surcharge_cal_crs
DEALLOCATE surcharge_cal_crs

-- Select everything from our recordset table for output
SELECT
   Addr0
 , Addr1
 , ParmsPhone
 , CoCustNum
 , CoProspectId
 , CoPhone
 , CustaddrFaxNum
 , CoCoNum
 , TermsDescription
 , CoOrderDate
 , CoCloseDate
 , CoSlsman
 , CoDisc
 , CustaddrCurrCode
 , CurrencyDescription
 , CoitemQtyOrderedConv
 , CoitemCustItem
 , CoitemItem
 , CoitemCoLine
 , CoitemCoRelease
 , CoitemUM
 , CoitemDisc
 , ItemDescription
 , ItemOverview
 , CoitemCfgDetail
 , CfgcompCompName
 , CfgcompQty
 , CfgcompPrice
 , CfgattrName
 , CfgattrValue
 , TtCompOperNum
 , TtCompSequence
 , TcCprPrice
 , TcAmtLineNet
 , CoContact
 , CoparmsCoText1
 , CoparmsCoText2
 , CoparmsCoText3
 , TcTotSTotal
 , TcTotDiscount
 , CoSalesTax
 , CoSalesTax2
 , CoMiscCharges
 , EuroAmount
 , TEuroExists
 , TcTotTotal
 , CoitemNoteExists
 , CoitemRowPointer
 , CoNoteExists
 , CoRowPointer
 , CustomerBillToNoteExists
 , CustomerBillToRowPointer
 , CustomerNoteExists
 , CustomerRowPointer
 , NumOfTaxSys
 , JobrouteJob
 , JobrouteSuffix
 , JobrouteOperNum
 , FeatureDisplayQty
 , FeatureDisplayUM
 , FeatureDisplayDesc
 , FeatureDisplayStr
 , AmountFormat
 , AmountPlaces
 , CostPriceFormat
 , CostPricePlaces
 , QtyUnitFormat
 , QtyUnitPlaces
 , TotalSurcharge
 , Item_Content
 , drawing_nbr
 , delterm
 , end_user
 , del_term_desc
 , url
 , email_addr
 , addr2
 , due_date
 , project_date
 , office_addr_footer
 , estimate_response_rpt_title
 , bank_name 
 , bank_transit_num
 , bank_acct_no
FROM @reportset
LEFT JOIN (SELECT CoNum,SUM(Surcharge) AS TotalSurcharge FROM @SurchargeTable GROUP BY CoNum) Sur
ON CoCoNum = Sur.CoNum

ORDER BY CoCoNum
   , CoitemCoLine
   , CoitemUM DESC  -- Non-feature record first
   , FeatureDisplayStr DESC  -- Feature string second
   , JobrouteJob  -- Feature materials last (in order)
   , JobrouteSuffix
   , JobrouteOperNum

COMMIT TRANSACTION
EXEC dbo.CloseSessionContextSp @SessionID = @RptSessionID
GO


