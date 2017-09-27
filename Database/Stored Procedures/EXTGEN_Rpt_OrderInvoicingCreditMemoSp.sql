USE [KPI_App]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/* $Header: /ApplicationDB/Stored Procedures/Rpt_OrderInvoicingCreditMemoSp.sp 117   6/05/15 1:39a Cliu $  */
/***************************************************************************\
* TLC Group, Inc. 
*
* Author: Laurence Ledford
*
* Program Name: dbo.EXTGEN_Rpt_OrderInvoicingCreditMemoSp
* Program Type: Stored Procedure
* Initial Program Version: Rpt_OrderInvoicingCreditMemoSp.sp 117
* Initial Date: 08/01/2016
*     Comments: Extend Invoice functionality
*
* ID		Date		INI	Description
* ------	----------	---	---------------------------------------- 
* KPI01		??????????	???	Extend
* N/A		09/26/2017	LKL	Add KPI ID to prior code changes. Add change log to header.
* TLCG01	09/26/2017	LKL	Resolve Lot/SN CRLF issue when printing on invoice.
*
\***************************************************************************/
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

-- START - KPI01

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
	-- START - TLCG01
	--else 'Lot: ' + bc.Lot + + char(10) + char(13) -- TLCG01 - Removed/Replaced with below line
	else ' Lot: ' + bc.Lot -- TLCG01
	-- END - TLCG01
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
	   -- START - TLCG01
	   set  SerialLotString  = CASE
									WHEN (SerialLotString IS NULL OR SerialLotString = '') AND @KPISerialLotString IS NOT NULL THEN @KPISerialLotString
									WHEN SerialLotString IS NOT NULL AND @KPISerialLotString IS NOT NULL THEN SerialLotString + CHAR(13) + CHAR(10) + @KPISerialLotString
									ELSE '' END
		-- END - TLCG01
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

-- END - KPI01

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
