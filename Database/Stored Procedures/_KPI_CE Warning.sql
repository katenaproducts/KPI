USE [KPI_App]
GO

/****** Object:  StoredProcedure [dbo].[_KPI_CE Warning]    Script Date: 08/30/2017 15:40:55 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO





CREATE PROCEDURE [dbo].[_KPI_CE Warning]
(
  @Item ItemType,
  @CoNum CoNumType,
  @Warn tinyint = null output 
  )
 
as 

declare @Warn_Country tinyint
declare @Item_CE tinyint

set @Warn_Country = 0
set  @Item_CE  = 0

select @Warn = 0
select @Warn_Country = isnull(country.Uf_FlagForCE, 0)
from co_mst co (nolock)
join custaddr_mst ca (nolock) on 
	ca.cust_num = co.cust_num and
	ca.cust_seq = co.cust_seq 
	join country_mst country (nolock) on country.country = ca.country 
	where co.co_num = @CoNum

select  @Item_CE = isnull(item.Uf_Itm_CEMarked, 0)
from item_mst item (nolock) where item.item = @item


set @Item_CE = ISNULL(@item_CE , 0)
set @Warn_Country = ISNULL(@Warn_Country,0)

if @Item_CE = 0 and @Warn_Country = 1 set @Warn = 1
else set @Warn = 0


RETURN 0




GO


