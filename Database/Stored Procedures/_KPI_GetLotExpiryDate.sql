USE [KPI_App]
GO

/****** Object:  StoredProcedure [dbo].[_KPI_GetLotExpiryDate]    Script Date: 08/30/2017 15:41:05 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO





CREATE PROCEDURE [dbo].[_KPI_GetLotExpiryDate] 
(
  @Item ItemType,
  @Lot LotType  = null ,
  @ExpiryDate nvarchar(50) output ,
  @BarCode nvarchar(50) output
  )
 
as 

DECLARE @BinVar varbinary(128);
select @BinVar =  CAST(site AS varbinary(128) )
from parms_mst (NOLOCK)
SET CONTEXT_INFO @BinVar;

if ISNULL(@Lot, '') = '' or ISNULL(@Item, '') = ''
select 
    @ExpiryDate = 'N/A',
    @BarCode = 'N/A'

select 
    @ExpiryDate = isnull(Uf_ExpiryDate,'N/A'),
    @BarCode = isnull(Uf_BarCode , 'N/A')
    
from lot where lot = @Lot and item = @Item 
RETURN 0



GO


