USE [KPI_App]
GO

/****** Object:  StoredProcedure [dbo].[_KPI_ApplyLineDiscount]    Script Date: 08/30/2017 15:40:47 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO






CREATE PROCEDURE [dbo].[_KPI_ApplyLineDiscount] 
(
  @CoNum CoNumType,
  @Discount Decimal(10,2) = null
  )
 
as 

set @Discount = ISNULL(@discount, 0)
DECLARE @BinVar varbinary(128);
select @BinVar =  CAST(site AS varbinary(128) )
from parms_mst (NOLOCK)
SET CONTEXT_INFO @BinVar;


declare @CustNum CustNumType
declare @OrderDate datetime

select  @CustNum = co.cust_num from co (nolock) where co.co_num = @CoNum
select  @OrderDate = co.order_date from co (nolock) where co.co_num  = @CoNum

update coitem
set disc = 0
from coitem coi where 
coi.co_num = @CoNum and
coi.stat <> 'C' and
coi.stat <> 'F' 

update coitem
set disc = @Discount from coitem coi where 
coi.co_num = @CoNum and
coi.stat <> 'C' and
coi.stat <> 'F' and
isnull(coi.promotion_code, '') = '' and
coi.price > 0 and
coi.item not in 
(select item from item it (nolock) join famcode fm (nolock) on fm.family_code = it.family_code and
 fm.Uf_ExcludeForDiscount = 1) and
 
 (
 exists(select 1 from itemcustprice icprice (nolock) where icprice.effect_date <= @OrderDate)
 and
 (
 'N/A' in (select top 1 isnull(pricecode, 'N/A') from itemprice ip where ip.item = coi.item
  order by effect_date desc)
  or 
  Not exists (select top 1 isnull(pricecode, 'N/A') from itemprice ip where ip.item = coi.item
  order by effect_date desc)
  )
 )
 








GO


