USE [KPI_App]
GO

/****** Object:  StoredProcedure [dbo].[_KPI_BarCodeParsing]    Script Date: 08/30/2017 15:40:52 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO







CREATE PROCEDURE [dbo].[_KPI_BarCodeParsing] 

( 
  @TransType nvarchar(1) = 'P',
  @Item		ItemType,
  @BarCode nvarchar(100) output ,
  @SerialNum SerNumType  = null output,
  @Lot LotType  = null output,
  @GTIN nvarchar(50) = null output,
  @ExpiryDate nvarchar(50) = null output,
  @Infobar Infobartype = null output,
  @KPIError tinyint = 0 output,
  @PromptMessage Infobartype = null output,
  @PromptButtons nvarchar(200) = null output
)
 
 -- Trans Type
 --'D'(elete Pending trnasactions,
 --'P'(UrchaseOrder Receiving), 
 --'O'(Rder Shipping), 
 --'R'(MA Transaction)
 
as 
-- (01) GTIN, (10) Batch or Lot, (17) Expiration Date & (21) Serial Number.

begin


set  @PromptMessage = null
set  @PromptButtons = null

if @TransType = 'D'
begin
	delete from dbo._KPI_BarCodes where 
	CreatedBy = dbo.UserNameSp()
	and MatlTransNum = 0
	return 0
end


set @KPIError=0

declare @OriginalBarCode nvarchar(70)
declare @OriginalLot nvarchar(20)
declare @OriginalGTIN Nvarchar(40)

Set @OriginalBarCode = @BarCode
set @OriginalLot = @Lot

select @OriginalGTIN = item.UF_GTIN 
from item (nolock) 
where item.item = @Item

if isnull(@BarCode, '') = '' return

-- strip out the GS1 string at the beginning
if @BarCode like 'FN1%' or @BarCode like 'FN0%'
set @barcode = substring (@barcode, 4, len(@barcode) - 3)

if @BarCode like ']C%' or @BarCode like ']D%'  
set @barcode = substring (@barcode, 4, len(@barcode) - 3)


--if @BarCode LIKE '[^a-zA-Z0-9()]%' 
--begin
--        set @SerialNum = null
--		Set @Lot = null
--		Set @ExpiryDate = null
--		set @gtin = null
--        set @infobar = 'Invalid Barcode ' + @BarCode
--        return 16
--end


        set @SerialNum = null
		Set @Lot = null
		Set @ExpiryDate = null
		set @gtin = null

--set @TransType = ISNULL(@TransType, 'P')

declare @IndGTIN integer
declare @IndLot integer
declare @IndSerial integer
declare @IndExpiryDate integer
declare @IndProdDate integer

declare @StartInd as integer
declare @EndInd as integer
set @EndInd = 0 
set @StartInd = 0

select @IndGTIN = 0
select @IndLot = 0
select @IndSerial = 0 
select @IndExpiryDate = 0

select @IndGTIN = CHARINDEX('(01)', @BarCode, 1)
select @IndLot = CHARINDEX('(10)', @BarCode, 1)
select @IndSerial = CHARINDEX('(21)', @BarCode, 1)
select @IndExpiryDate = CHARINDEX('(17)', @BarCode, 1)


--if CHARINDEX('(01)', @BarCode, 1) <> 1 and CHARINDEX('01', @BarCode, 1) <> 1
--begin

---- not a gs1 Barcode return
--	return
--end


-- GTIN
if @IndGTIN = 1 
begin
    
	set @GTIN = SUBSTRING(@BarCode, @IndGTIN + 4, LEN(@BarCode) - @IndGTIN - 3)
	set @EndInd = charindex('(', @GTIN, 1)
	if  @EndInd = 0 set @EndInd = LEN(@GTIN) + 1
    if  @EndInd > 0 set @GTIN = SUBSTRING( @GTIN , 1, @EndInd - 1)
    
   
end    
 
--LOT
if @IndLot > 0 
begin
	set @Lot = SUBSTRING(@BarCode, @IndLot + 4, LEN(@BarCode) - @IndLot - 3)
    set @EndInd = charindex('(', @lot, 1)
    if  @EndInd = 0 set @EndInd = LEN(@lot) + 1
    if  @EndInd > 0 set @lot = SUBSTRING( @lot , 1, @EndInd - 1)
    
end 
--Serial
if @IndSerial > 0 
begin

	set @SerialNum= SUBSTRING(@BarCode,@IndSerial + 4, LEN(@BarCode) - @IndSerial - 3)
    set @EndInd = charindex('(', @SerialNum, 1)
    if @EndInd = 0 set @EndInd = LEN(@SerialNum) + 1
    if  @EndInd > 0 set @SerialNum = SUBSTRING( @SerialNum , 1, @EndInd - 1)
  
end 

--ExpiryDate
 
 if @IndExpiryDate > 0 
 begin
	set @ExpiryDate= SUBSTRING(@BarCode, @IndExpiryDate + 4, LEN(@BarCode) - @IndExpiryDate - 3)
    set @EndInd = charindex('(', @ExpiryDate, 1)
    if  @EndInd = 0 set @EndInd = LEN(@ExpiryDate) + 1
    if  @EndInd > 0 set @ExpiryDate = SUBSTRING(  @ExpiryDate , 1, @EndInd - 1)
  end 

--End of Readable delimiter FN1 ()


------------------------------------------------------------------------------------------------------ 

-- no separators -- Parsing based on Fixed Length Code fields and then variable Length 
-- repeat loop for fixed length attrbutes
-- Special characters in the barcode

declare @delimiter nvarchar(4)
declare @delimLen tinyint

declare @fieldID nvarchar(4)


set @delimiter = '|'
set @delimLen = LEN(@delimiter)

declare @AllVar tinyint -- have we reached the variable part of the Barcode or not
set     @AllVar = 0
declare @CurInd tinyint
declare @CurrentAI nvarchar(4)
declare @CurrentField nvarchar(50)
declare @delimiterRequired int

declare @internalDel nvarchar(10)
declare @internalInd tinyint
declare @FieldLen integer



declare @BarcodeStrings table 
(
ID nvarchar(2),
Value nvarchar(50),
processed tinyint

)
while (1=1)
begin
   set @internalInd = charindex(@delimiter, @BarCode)
   if  @internalInd = 0 break
   if SUBSTRING(@barcode, 1, 2) in (select Fieldid from dbo._KPI_BarCodeApId)
   insert @BarcodeStrings 
   select SUBSTRING(@barcode, 1, 2), SUBSTRING(@barcode, 3, @internalInd -3), 0
   declare @StartNext tinyint
   set @StartNext = @internalInd + @delimLen
   set @BarCode = SUBSTRING(@barcode, @StartNext, LEN(@barcode) - @StartNext + 1)
end

if ISNULL(@barcode, '') <> '' and 
 SUBSTRING(@barcode, 1, 2) in (select Fieldid from dbo._KPI_BarCodeApId)
   insert @BarcodeStrings 
   select SUBSTRING(@barcode, 1, 2), right(@barcode, len(@barcode) - 2), 0

-- We have no F1 delimiters on our custom table now,
-- Need to process if we have fixed length strings that need to be split


while (1=1)
begin
   set @CurrentAI = ''
   set @FieldLen = 0
   set @CurrentField = ''
   
   select 
   @CurrentAI = ID,
   @CurrentField = Value
   from 
   @BarcodeStrings where processed = 0
   if @@ROWCOUNT = 0 or @CurrentAI = '' break
     
   update @BarcodeStrings 
	   set  processed = 1
	   from @BarcodeStrings where ID = @CurrentAI
   
   select 
	@FieldLen = kpi.length from
	dbo._KPI_BarCodeApId kpi (nolock)
	where kpi.FieldId = @CurrentAI
	if @@ROWCOUNT > 0
	begin
	   if @FieldLen = 0 continue-- variable field, nothing to process)
	   if LEN(@CurrentField) <= @FieldLen continue
	   
	   update @BarcodeStrings 
	   set Value = SUBSTRING(value, 1, @FieldLen)
	   from @BarcodeStrings where ID = @CurrentAI
	    
	    insert @BarcodeStrings
	    select 
	     SUBSTRING(@CurrentField,  @FieldLen + 1, 2), 
	     right(@CurrentField,  len(@CurrentField) - @FieldLen - 2),0
 	end 
 end



update @BarcodeStrings
set processed = 0
	   
while (1=1)
begin
    select 
    @CurrentAI = kpi.ID,
    @currentfield = kpi.value
    from @BarcodeStrings kpi where processed = 0
        
    if @@ROWCOUNT = 0 break 
    
    update @BarcodeStrings
    set processed = 1 where 
       ID = @CurrentAI
       
       if @CurrentAI = '21'  set @SerialNum = @CurrentField
       if @CurrentAI = '10'  set @Lot = @CurrentField
       if @CurrentAI = '01'  set @GTIN = @CurrentField
       if @CurrentAI = '17'  set @ExpiryDate = @CurrentField

end
set @BarCode = @OriginalBarCode


if isnull(@SerialNum,'') = '' and @TransType = 'O'
begin
 set @SerialNum =  @BarCode
 set @Lot = ''
end

if isnull(@lot,'') = '' and @TransType <> 'O'
begin
    set @SerialNum = ''
    set @Lot = @BarCode

end


-- Validation Session below
----------------------------------------------------------------------------------------------

declare 
@SerialFound nvarchar(30)

-- Error 1 - Out of Inventory

select @SerialFound = kpi.Serialnum from dbo._KPI_Serials KPI (nolock) 
where SerialNum = isnull(@SerialNum,'') and STAT = 'O' and @TransType = 'O'

if @@ROWCOUNT >0  
begin

    set @KPIError = 1
    set @infobar = 'Serial Number out of Stock  ' + @SerialNum
    set @SerialNum = null
    set @Lot = null
    Set @ExpiryDate = null
    set @GTIN = null
    return 16
end
-- End Error 1 - Out of Inventory

--------------------------------------------------------------------------------------------

 --Error 2: Wrong GTIN - Wrong Item

set @Infobar =null
if isnull(@OriginalGTIN, '') <> '' and ISNULL(@GTIN , '') <> '' and 
@OriginalGTIN <> @GTIN 
begin
    set @KPIError = 2
    set @infobar = 'Wrong GTIN' + 
    CHAR(13) + 'Item GTIN: ' + @GTIN  +
    CHAR(13) + 'Scanned GTIN: ' + @OriginalGTIN
    
    set @SerialNum = null
    set @Lot = null
    Set @ExpiryDate = null
    set @GTIN = null
    return 16

end

 --Error 2: Wrong GTIN - Wrong Item

---------------------------------------------------------------------------------------------

 --Error 3 Wrong Lot OverWrite lot or stop and add a new line 
if ISNULL(@originalLot, '') <> ISNULL(@lot, '') and ISNULL(@originalLot, '') <> '' 
begin      
     set @KPIError = 3
     EXEC  dbo.MsgAskSp @infobar OUTPUT, @PromptButtons OUTPUT
         , 'Q=CmdPerform0NoYes'
         , '@%Create'
         , '@lot'
         
         set 
         @PromptMessage = 'Original Lot was ' + @originalLot + CHAR(13) + 'New Lot is ' + @Lot + Char(13) + 
         'Do you want to update Lot? ' 
         return 0
             
end
-- End Error 3 Wrong Lot change lot or add a new line 

---------------------------------------------------------------------------------------------

-- Error 4 Duplication of serial number

set @infobar = null
select kpi.SerialNum from _KPI_BarCodes kpi 
where 

(kpi.SerialNum = @SerialNum)

													
if @@ROWCOUNT >0  and @TransType = 'O'
begin

    set @KPIError = 4
    set @infobar = 'Duplicate Serial Number  ' + @SerialNum
    set @SerialNum = null
    set @Lot = null
    Set @ExpiryDate = null
    set @GTIN = null
    return 16
end



if isnull(@SerialNum, '') = '' and @TransType = 'O' begin
									set @SerialNum = @BarCode
									set @Lot = ''
								end
return 0

End  














GO


