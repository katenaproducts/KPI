USE [KPI_App]
GO

/****** Object:  StoredProcedure [dbo].[_KPI_RPT_Uninvoiced PackingSlips]    Script Date: 08/30/2017 15:41:32 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO




CREATE PROCEDURE [dbo].[_KPI_RPT_Uninvoiced PackingSlips] 
(
  @CustomerStart CustNumType = null,
  @CustomerEnd CustNumType = null,
  @PackSlipStart tinyint = null,
  @PackSlipEnd tinyint = null,
  @PackDateStart Datetime = null,
  @PackDateEnd Datetime = null,
  @ShipDateStart datetime = null,
  @ShipDateEnd Datetime = null
   )
 
as 

set @CustomerStart = isnull(@CustomerStart, dbo.LowCharacter())
Set @CustomerEnd = ISNULL(@CustomerEnd, dbo.HighCharacter())

set @PackDateStart = ISNULL(@PackDateStart, dbo.LowDate())
set @PackDateEnd = ISNULL(@PackDateEnd, dbo.HighDate())





set @ShipDateStart = ISNULL( @ShipDateStart, dbo.LowDate())
set @ShipDateEnd= ISNULL(@ShipDateEnd, dbo.HighDate()) 

set @PackdateEnd = dbo.DayEndOf(@PackdateEnd )
set @ShipDateEnd = dbo.DayEndOf(@ShipDateEnd)

DECLARE @BinVar varbinary(128);
select @BinVar =  CAST(site AS varbinary(128) )
from parms_mst (NOLOCK)
SET CONTEXT_INFO @BinVar;


select 
co_ship.pack_num as PackNum,
co_ship.co_num as CoNum,
co_ship.co_line as Coline,
co_ship.co_release as CoRelease,
co.order_date as CoOrderDate,
coi.due_date as CoiDueDate,
coi.item as CoiItem,
coi.description as CoiDescription,
coi.qty_ordered_conv as CoiQtyOrderedConv,
co_ship.qty_shipped as QtyShipped,
coi.u_m as CoiUM,
co_ship.qty_returned as QtyReturned,
pck.qty_packed as PckiQtyPacked,
co_ship.qty_invoiced as QtyInvoiced,
co.co_num as CoCustNum,
pck_hdr.pack_date as PckPackDate,
ISNULL(dbo.UomConvQty(
           co_ship.qty_shipped , 
           ISNULL(dbo.Getumcf(Coi.u_m, Coi.item, Co.cust_num, 'C'), 1),
          'From Base')
        , 0) as DerQtyShippedConv,
ISNULL(dbo.UomConvQty(
           co_ship.qty_invoiced, 
            ISNULL(dbo.Getumcf(Coi.u_m, Coi.item, Co.cust_num, 'C'), 1),
          'From Base')
        , 0) as DerQtyInvoicedConv,
(co_ship.qty_shipped + co_ship.qty_returned - co_ship.qty_invoiced) as QtyToBeInvoiced,
case 
	when ca.country <> 'USA' then 0 
	else  ISNULL(pj.Confirmed, 0)
end
as PaceJetProcessed

from co_ship (nolock)
join co (nolock) on co.co_num = co_ship.co_num join custaddr ca on 
ca.cust_num = co.cust_num
join coitem (nolock) coi on 
		coi.co_num = co_ship.co_num and
		coi.co_line = co_ship.co_line
join pck_hdr (nolock) on pck_hdr.pack_num = co_ship.pack_num		
join pckitem pck on pck.pack_num = co_ship.pack_num	and
					pck.co_num =   co_ship.co_num and
					pck.co_line = co_ship.co_line and
		            pck.co_release = co_ship.co_release
		            
 left outer join  dbo.ssspj_shipment_mst	pj on 
 pj.TransactionID = convert(nvarchar(20),pck.pack_num)           
	where co_ship.ship_date >= @ShipDateStart and
	      co_ship.ship_date <= @ShipDateEnd and
	      pck_hdr.pack_date >= @PackDateStart and
	      pck_hdr.pack_date <= @PackDateEnd and
	      co_ship.qty_invoiced < co_ship.qty_shipped



GO


