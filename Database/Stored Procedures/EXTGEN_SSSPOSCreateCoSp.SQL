USE [KPI2_App]
GO

/****** Object:  StoredProcedure [dbo].[EXTGEN_SSSPOSCreateCoSp]    Script Date: 10/23/2017 16:34:44 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

/***************************************************************************\
* TLC Group, Inc. 
*
* Author: Laurence Ledford
*
* Program Name: dbo.EXTGEN_SSSPOSCreateCoSp
* Program Type: Stored Procedure
* Initial Program Version: SSSPOSCreateCoSp.sp 2
* Initial Date: 10/23/2017
*     Comments: Allow POS Extended Fields to Flow to CO
*
* ID		Date		INI	Description
* ------	----------	---	---------------------------------------- 
* TLCG01	10/23/2017	LKL	Initial Version
*
\***************************************************************************/
CREATE PROCEDURE [dbo].[EXTGEN_SSSPOSCreateCoSp]
 @POSNum          POSMNumType
,@POSMTermsCode   TermsCodeType
,@CurUserCode     UserCodeType
,@ParmSite        SiteType
,@POSMCustNum     CustNumType
,@POSMCustSeq     CustSeqType
,@POSMDisc        FSPctType
,@POSMCustPo      CustPoType
,@POSMRowPointer  RowPointerType
,@POSMTaxCode1    TaxCodeType
,@POSMTaxCode2    TaxCodeType
,@POSMShipCode    ShipCodeType
,@POSMSalesTax    AmountType
,@POSMSalesTax2   AmountType
,@POSMFrtTaxCode1 TaxCodeType
,@POSMFrtTaxCode2 TaxCodeType
,@POSMMscTaxCode1 TaxCodeType
,@POSMMscTaxCode2 TaxCodeType
,@POSMFreight     AmountType
,@POSMMiscCharges AmountType
,@POSMContact     ContactType
,@POSMPhone       PhoneType
,@POSMWhse        WhseType
,@POSMSlsman      SlsmanType
,@POSMEndUserType EndUserTypeType
,@TCoNum          CoNumType   OUTPUT
,@Infobar         InfobarType OUTPUT
AS

 
DECLARE @Severity GenericIntType
,@CoCurWhse       WhseType
,@CoShipCode      ShipCodeType
,@CoTermscode     TermsCodeType
,@POSMPricecode   PriceCodeType
,@CoEndusertype   EndUserTypeType
,@CoSlsman        SlsmanType
,@CoWhse          WhseType
,@CoShipEarly     ListYesNoType
,@CoShipPartial   ListYesNoType
,@CoSonsolidate   ListYesNoType
,@CoSummarize     ListYesNoType
,@CoInvfreq       InvFreqType
,@CoEinvoice      ListYesNoType
,@CoApsPullUp     ListYesNoType
,@CoContact       ContactType
,@CoPhone         PhoneType
,@Cotaxcode1      TaxCodeType
,@Cotaxcode2      TaxCodeType
,@Cotransnat      TransNatType
,@Codelterm       DeltermType
,@Coprocessind    ProcessIndType
,@Couseexchrate   ExchRateType
,@Cocurrcode      CurrCodeType
,@CoRate          ExchrateType
,@CoMiscTaxCode1  TaxCodeType
,@CoFrtTaxCode1   TaxCodeType
,@CoMiscTaxCode2  TaxCodeType
,@CoFrtTaxCode2   TaxCodeType
,@Coconsolidate   ListYesNoType
,@Today           DateType
,@CoRowPointer    RowPointerType
,@CoFinalDestination CountryType -- TLCG01

SET @Severity = 0
SET @Infobar  = ISNULL(@Infobar,'') + NCHAR(13) + NCHAR(10)+ ' Error to Create Co Header. '
SET @Today    = GETDATE()

/** Comment the following for performance, those values will be coming from SSSPOSPosM_PSp
SELECT @POSMCustNum = posm_pos.cust_num
,@POSMCustSeq       = posm_pos.cust_seq
,@POSMDisc          = ISNULL(posm_pos.disc,0)
,@POSMCustPo        = ISNULL(posm_pos.cust_po,'')
,@POSMRowPointer    = posm_pos.RowPointer
,@POSMTaxCode1      = ISNULL(posm_pos.tax_code1,'')
,@POSMTaxCode2      = ISNULL(posm_pos.tax_code2,'')
,@POSMShipCode      = ISNULL(posm_pos.ship_code,'')
,@POSMSalesTax      = ISNULL(posm_pos.sales_tax,0)
,@POSMSalesTax2     = ISNULL(posm_pos.sales_tax_2,0)
,@POSMFrtTaxCode1   = ISNULL(posm_pos.frt_tax_code1,'')
,@POSMFrtTaxCode2   = ISNULL(posm_pos.frt_tax_code2,'')
,@POSMMscTaxCode1   = ISNULL(posm_pos.msc_tax_code1,'')
,@POSMMscTaxCode2   = ISNULL(posm_pos.msc_tax_code2,'')
,@POSMFreight       = ISNULL(posm_pos.freight,0)
,@POSMMiscCharges   = ISNULL(posm_pos.misc_charges,0)
,@POSMContact       = ISNULL(posm_pos.contact,'')
,@POSMPhone         = ISNULL(posm_pos.phone,'')
,@POSMWhse          = ISNULL(posm_pos.whse,'')
FROM posm_pos WITH (NOLOCK)
WHERE posm_pos.posm_num = @POSNum
**/

SELECT TOP 1
 @CoMiscTaxCode1 = ISNULL(misc_tax_code,'')
, @CoFrtTaxCode1 = ISNULL(frt_tax_code,'')
FROM tax_system
WHERE tax_system = 1

SELECT @POSMPriceCode = posm_pos.pricecode
FROM posm_pos
WHERE posm_pos.posm_num = @POSNum

SELECT TOP 1
 @CoMiscTaxCode2 = ISNULL(misc_tax_code,'')
, @CoFrtTaxCode2 = ISNULL(frt_tax_code,'')
FROM tax_system
WHERE tax_system = 2

EXEC @Severity = dbo.SSSPOSGetGeneralInfoSp
    @POSMCustNum
   ,@POSMCustSeq
   ,@CoCurWhse     OUTPUT
   ,@CoShipCode    OUTPUT
   ,NULL  --@Cotermscode   OUTPUT
   ,NULL  --@Copricecode   OUTPUT
   ,@Coendusertype OUTPUT
   ,@Coslsman      OUTPUT
   ,@Cowhse        OUTPUT
   ,@Coshipearly   OUTPUT
   ,@Coshippartial OUTPUT
   ,@Coconsolidate OUTPUT
   ,@Cosummarize   OUTPUT
   ,@Coinvfreq     OUTPUT
   ,@Coeinvoice    OUTPUT
   ,@CoApsPullUp   OUTPUT
   ,@Cocontact     OUTPUT
   ,@Cophone       OUTPUT
   ,@Infobar       OUTPUT

IF @Severity <> 0
   RETURN @Severity


/**
RUN get-cust-curr-code IN h-co-rules  (
   INPUT b-posm-pos.cust-num,
   OUTPUT cCurrCode).
{&handle-rules-error}

IF cCurrCode <> ?  THEN DO:

   ASSIGN
      daOrderDate = tt-co.order-date
      t-rate      = ?.
END.
ELSE
  t-rate = 1.0.


ASSIGN
   tt-co.exch-rate = t-rate.
**/

EXEC @Severity = dbo.SSSPOSGetTaxEcInfoSp
    @POSMCustNum
   ,@POSMCustSeq
   ,@Cotaxcode1    OUTPUT
   ,@Cotaxcode2    OUTPUT
   ,@Cotransnat    OUTPUT
   ,@Codelterm     OUTPUT
   ,@Coprocessind  OUTPUT
   ,@Couseexchrate OUTPUT
   ,@Cocurrcode    OUTPUT
   ,@Infobar       OUTPUT

IF @Severity <> 0
   RETURN @Severity

SET @CoRate = 1.0

EXEC @Severity = dbo.SSSPOSGetNextCoNumSp
   @TCoNum OUTPUT,
   @Infobar OUTPUT

IF @Severity <> 0
   RETURN @Severity

IF ISNULL(@POSMFrtTaxCode1,'') = ''
   SET @POSMFrtTaxCode1 = @CoFrtTaxCode1
IF ISNULL(@POSMFrtTaxCode2,'') = ''
   SET @POSMFrtTaxCode2 = @CoFrtTaxCode2
IF ISNULL(@POSMMscTaxCode1,'') = ''
   SET @POSMMscTaxCode1 = @CoMiscTaxCode1
IF ISNULL(@POSMMscTaxCode2,'') = ''
   SET @POSMMscTaxCode2 = @CoMiscTaxCode2
IF ISNULL(@POSMTaxCode1,'') = ''
   SET @POSMTaxCode1 = @Cotaxcode1
IF ISNULL(@POSMTaxCode2,'')  = ''
   SET @POSMTaxCode2 = @Cotaxcode2
IF ISNULL(@POSMShipCode,'') = ''
   SET @POSMShipCode = @Coshipcode
IF ISNULL(@POSMContact,'') = ''
   SET @POSMContact = @CoContact
IF ISNULL(@POSMPhone,'') = ''
   SET @POSMPhone = @CoPhone
IF ISNULL(@POSMWhse,'') = ''
   SET @POSMWhse = @CoWhse
IF @POSMTaxCode1 = ''
   SET @POSMTaxCode1 = NULL
IF @POSMTaxCode2  = ''
   SET @POSMTaxCode2 = NULL
IF @POSMFrtTaxCode1 = ''
   SET @POSMFrtTaxCode1 = NULL
IF @POSMFrtTaxCode2  = ''
   SET @POSMFrtTaxCode2 = NULL
IF @POSMMscTaxCode1 = ''
   SET @POSMMscTaxCode1 = NULL
IF @POSMMscTaxCode2  = ''
   SET @POSMMscTaxCode2 = NULL
IF @POSMShipCode = ''
   SET @POSMShipCode = NULL

-- START - TLCG01
SELECT @CoFinalDestination = p.Uf_CoFinalDestination FROM posm_pos p WHERE p.posm_num = @POSNum
-- END - TLCG01

/*
 * ASSIGN NEXT CO NUMBER HERE (INSTEAD OF IN THE RULES)
 * BECAUSE OF USING THE POS-PARMS PREFIX
 */

SET @CoRowPointer = NEWID()
INSERT INTO co
(
co_num
,cust_num
,cust_seq
,disc
,cust_po
--,RowPointer
,tax_code1
,tax_code2
,ship_code
,sales_tax
,sales_tax_2
,frt_tax_code1
,frt_tax_code2
,msc_tax_code1
,msc_tax_code2
,freight
,misc_charges
,contact
,phone
,whse
--,ship_code
,terms_code
,pricecode
,end_user_type
,slsman
,ship_early
,ship_partial
,consolidate
,summarize
,inv_freq
,einvoice
,Aps_Pull_Up
,exch_rate
,trans_nat
,delterm
,process_ind
,use_exch_rate
,taken_by
,stat
,type
,order_date
,orig_site
,RowPointer
,Uf_CoFinalDestination -- TLCG01
)
VALUES
(
@TCoNum
,@POSMCustNum
,@POSMCustSeq
,@POSMDisc
,@POSMCustPo
--,@POSMRowPointer
,@POSMTaxCode1
,@POSMTaxCode2
,@POSMShipCode
,@POSMSalesTax
,@POSMSalesTax2
,@POSMFrtTaxCode1
,@POSMFrtTaxCode2
,@POSMMscTaxCode1
,@POSMMscTaxCode2
,@POSMFreight
,@POSMMiscCharges
,@POSMContact
,@POSMPhone
,@POSMWhse
--,@Coshipcode
,@POSMTermsCode
,@POSMpricecode
,@POSMEndUserType
,@POSMSlsman
,@Coshipearly
,@Coshippartial
,@Coconsolidate
,@Cosummarize
,@Coinvfreq
,@Coeinvoice
,@CoApsPullUp
,@CoRate
,@Cotransnat
,@Codelterm
,@Coprocessind
,@Couseexchrate
,@CurUserCode
,'O'
,'R'
,@Today
,@ParmSite
,@CoRowPointer
,@CoFinalDestination -- TLCG01
)

EXEC @Severity = dbo.CopyNotesSp
 'posm_pos'
,@POSMRowPointer
,'co'
,@CoRowPointer

IF @Severity <> 0
   RETURN @Severity

SET @Infobar = NULL
RETURN @Severity
GO


