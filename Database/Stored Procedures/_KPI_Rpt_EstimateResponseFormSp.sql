USE [KPI_App]
GO

/****** Object:  StoredProcedure [dbo].[_KPI_Rpt_EstimateResponseFormSp]    Script Date: 08/30/2017 15:41:30 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



/***************************************************************************\
* TLC Group, Inc. 
*
* Author: Laurence Ledford
*
* Program Name: dbo._KPI_Rpt_EstimateResponseFormSp
* Program Type: Stored Procedure
* Initial Program Version: Rpt_EstimateResponseFormSp.sp 71
* Initial Date: 08/10/2017
*     Comments: Add additional data points for the Estimate
*
* ID		Date		INI	Description
* ------	----------	---	---------------------------------------- 
* TLCG01	08/10/2017	LKL	Initial Version
*
\***************************************************************************/
CREATE PROCEDURE [dbo].[_KPI_Rpt_EstimateResponseFormSp] (
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
 --, @TakenBy					TakenByType -- TLCG01

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
 
 --, taken_by					TakenByType -- TLCG01

primary key (CoCoNum, CoitemCoLine, CoitemUM desc, FeatureDisplayStr desc, JobrouteJob, JobrouteSuffix, JobrouteOperNum, seq)
)

SET @EstimateStarting = isnull(@EstimateStarting, dbo.lowcharacter())
SET @EstimateEnding   = isnull(@EstimateEnding, dbo.highcharacter())

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
 --, co.taken_by -- TLCG01
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
--    , @TakenBy -- TLCG01

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
   r.Addr0
 , r.Addr1
 , r.ParmsPhone
 , r.CoCustNum
 , r.CoProspectId
 , r.CoPhone
 , r.CustaddrFaxNum
 , r.CoCoNum
 , r.TermsDescription
 , r.CoOrderDate
 , r.CoCloseDate
 , r.CoSlsman
 , r.CoDisc
 , r.CustaddrCurrCode
 , r.CurrencyDescription
 , r.CoitemQtyOrderedConv
 , r.CoitemCustItem
 , r.CoitemItem
 , r.CoitemCoLine
 , r.CoitemCoRelease
 , r.CoitemUM
 , r.CoitemDisc
 , r.ItemDescription
 , r.ItemOverview
 , r.CoitemCfgDetail
 , r.CfgcompCompName
 , r.CfgcompQty
 , r.CfgcompPrice
 , r.CfgattrName
 , r.CfgattrValue
 , r.TtCompOperNum
 , r.TtCompSequence
 , r.TcCprPrice
 , r.TcAmtLineNet
 , r.CoContact
 , r.CoparmsCoText1
 , r.CoparmsCoText2
 , r.CoparmsCoText3
 , r.TcTotSTotal
 , r.TcTotDiscount
 , r.CoSalesTax
 , r.CoSalesTax2
 , r.CoMiscCharges
 , r.EuroAmount
 , r.TEuroExists
 , r.TcTotTotal
 , r.CoitemNoteExists
 , r.CoitemRowPointer
 , r.CoNoteExists
 , r.CoRowPointer
 , r.CustomerBillToNoteExists
 , r.CustomerBillToRowPointer
 , r.CustomerNoteExists
 , r.CustomerRowPointer
 , r.NumOfTaxSys
 , r.JobrouteJob
 , r.JobrouteSuffix
 , r.JobrouteOperNum
 , r.FeatureDisplayQty
 , r.FeatureDisplayUM
 , r.FeatureDisplayDesc
 , r.FeatureDisplayStr
 , r.AmountFormat
 , r.AmountPlaces
 , r.CostPriceFormat
 , r.CostPricePlaces
 , r.QtyUnitFormat
 , r.QtyUnitPlaces
 , Sur.TotalSurcharge
 , r.Item_Content
 , r.drawing_nbr
 , r.delterm
 , r.end_user
 , r.del_term_desc
 , r.url
 , r.email_addr
 , r.addr2
 , r.due_date
 , r.project_date
 , r.office_addr_footer
 , r.estimate_response_rpt_title
 , r.bank_name 
 , r.bank_transit_num
 , r.bank_acct_no
 
 -- START - TLCG01
 , q1.name CoSlsmanName
 , c.taken_by
 -- END - TLCG01
 
FROM @reportset r
LEFT JOIN (SELECT CoNum,SUM(Surcharge) AS TotalSurcharge FROM @SurchargeTable GROUP BY CoNum) Sur
ON CoCoNum = Sur.CoNum
-- START - TLCG01
LEFT JOIN (
SELECT sls.slsman, CASE WHEN sls.outside = 1 THEN v.name ELSE e.name END name
FROM slsman sls
LEFT JOIN employee e
	ON e.emp_num = sls.ref_num
LEFT JOIN vendaddr v
	ON v.vend_num = sls.ref_num
) q1
	ON q1.slsman = CoSlsman
INNER JOIN co_mst c
	ON c.co_num = CoCoNum
-- END - TLCG01

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


