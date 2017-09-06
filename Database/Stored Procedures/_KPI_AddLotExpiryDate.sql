USE [KPI_App]
GO

/****** Object:  StoredProcedure [dbo].[_KPI_AddLotExpiryDate]    Script Date: 08/30/2017 15:40:43 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO






CREATE PROCEDURE [dbo].[_KPI_AddLotExpiryDate] 
(
  @Item ItemType,
  @Lot LotType  = null ,
  @ExpiryDate nvarchar(50) = null ,
  @BarCode nvarchar(50) = null
  )
 
as 

DECLARE @BinVar varbinary(128);
select @BinVar =  CAST(site AS varbinary(128) )
from parms_mst (NOLOCK)
SET CONTEXT_INFO @BinVar;



update lot_mst
set 
	Uf_ExpiryDate	= ISNULL(@ExpiryDate, 'N/A'),
    Uf_BarCode		= @BarCode
    
    
where lot = @Lot and item = @Item 
RETURN 0




GO


