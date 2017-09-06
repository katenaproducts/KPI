USE [KPI_App]
GO

/****** Object:  StoredProcedure [dbo].[_KPI_BarCodeForShipping]    Script Date: 08/30/2017 15:40:50 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO





CREATE PROCEDURE [dbo].[_KPI_BarCodeForShipping] 
(
  @Item ItemType,
  @CoNum CoNumType,
  @CoLine CoLineType,
  @CoRelease CoReleaseType,
  @Qty QtyUnitType,
  @CrReturn int,
  @UserId int,
  @ShipSerial int output,
  @Return int output,
  @NeedToOpenForm int output
  
 )
 
as 

begin

DECLARE @BinVar varbinary(128);
select @BinVar =  CAST(site AS varbinary(128) )
from parms_mst (NOLOCK)
SET CONTEXT_INFO @BinVar;

declare @serCount int
Set @serCount = 0
   set @ShipSerial = 0
   set @NeedToOpenForm = 0
   set @Return = 0
   select @ShipSerial = isnull(item.Uf_SerialShip, 0)    
   from item (nolock) where item.item = @Item 
   
return 0
end



GO


